#!/usr/bin/env bash
#
# build-images.sh - build the Swift Linux A/B UEFI images for x86_64 and arm64
# in parallel. Each image gets its 32-bit companion userland merged in as
# /usr/lib32 (i386 for x86_64; armv7 + box86 for arm64), so within an arch the
# companion is built first, then the image; the two arches run concurrently.
#
# Each arch is one "track" of: generate lib32 defconfig -> build lib32 ->
# generate image defconfig -> build image with the lib32 merge. Tracks run in
# parallel; per-track logs go to $OUTPUT_BASE/<arch>-image.log.
#
# Environment:
#   BUILDROOT           Buildroot source tree (default: <repo>/buildroot,
#                       the buildroot submodule)
#   BR2_EXTERNAL_SWIFT  buildroot-swift external (default: <repo>/swift)
#   BR2_EXTERNAL_PORTS  buildroot-ports external (default: <repo>/ports)
#   OUTPUT_BASE         where per-build output dirs go
#                       (default: <repo>/output)
#   SKIP_SWIFT=1        build without the swift package, for hosts that lack
#                       the native Swift toolchain the swift package needs.
#                       The image is otherwise complete.
#   DEVICE=<name>       build the image for one board (sdk/board/<name>)
#                       instead of the generic UEFI board for the
#                       architecture - its kernel defconfig, device tree and
#                       boot chain. Only valid alongside that board's own
#                       architecture, and only for a single arch at a time.
#                       Output goes to <name>-image rather than <arch>-image.
#   NO_LIB32=1          skip the 32-bit companion (no /usr/lib32, no box86)
#   LIB32_ROOT          use an already-built companion target/ tree instead of
#                       building one (its toolchain lives in another container)
#   DL_DIR              override the Buildroot download dir (default: buildroot's
#                       own $(TOPDIR)/dl, already shared across arches)
#   CCACHE_DIR          compiler cache dir (default: $OUTPUT_BASE/ccache)
#   PARALLEL_BUILD=1    per-package build dirs + parallel top-level build
#   CCACHE=1            enable the compiler cache
#
# Usage: ./build-images.sh [x86_64] [arm64]      (default: both)

set -u

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Buildroot and both BR2_EXTERNAL trees are submodules of this repo; each can
# still be overridden, which is how CI reuses the container's prebuilt copies.
BUILDROOT="${BUILDROOT:-$REPO_DIR/buildroot}"
BR2_EXTERNAL_SWIFT="${BR2_EXTERNAL_SWIFT:-$REPO_DIR/swift}"
BR2_EXTERNAL_PORTS="${BR2_EXTERNAL_PORTS:-$REPO_DIR/ports}"
OUTPUT_BASE="${OUTPUT_BASE:-$REPO_DIR/output}"
EXTERNALS="${BR2_EXTERNAL_SWIFT}:${BR2_EXTERNAL_PORTS}:${REPO_DIR}/external"
GENERATE="$REPO_DIR/generate-config.sh"

# Optional caches. Buildroot's default download dir ($(TOPDIR)/dl) is already
# shared across every per-arch output of the same tree, so DL_DIR is only
# passed when the caller explicitly sets it: overriding it unconditionally
# diverges from a prebuilt output's cached downloads (packages whose stamps say
# "downloaded" then fail to extract from the new, empty dir - this broke the CI
# containers, whose caches were fetched into buildroot/dl).
DL_DIR="${DL_DIR:-}"
CCACHE_DIR="${CCACHE_DIR:-$OUTPUT_BASE/ccache}"
DL_OPT=""
[ -n "$DL_DIR" ] && DL_OPT="BR2_DL_DIR=$DL_DIR"
# Opt-in accelerators (off by default so the container cache-reuse path in CI is
# undisturbed):
#   PARALLEL_BUILD=1  per-package build dirs + a parallel top-level build
#   CCACHE=1          compiler cache in $CCACHE_DIR
BR2_MAKE_OPTS=""
[ "${PARALLEL_BUILD:-0}" = "1" ] && BR2_MAKE_OPTS="-j$(nproc) -l$(nproc)"

# arch -> its 32-bit companion arch (empty means "no companion").
companion_of() {
	case "$1" in
		x86_64) echo "i386" ;;
		arm64)  echo "armv7" ;;
		*)      echo "" ;;
	esac
}

die() { echo "build-images: $*" >&2; exit 1; }

submodule_hint="run: git submodule update --init"
[ -f "$BUILDROOT/Config.in" ]          || die "Buildroot not found: $BUILDROOT ($submodule_hint)"
[ -f "$BR2_EXTERNAL_SWIFT/Config.in" ] || die "buildroot-swift external not found: $BR2_EXTERNAL_SWIFT ($submodule_hint)"
[ -f "$BR2_EXTERNAL_PORTS/Config.in" ] || die "buildroot-ports external not found: $BR2_EXTERNAL_PORTS ($submodule_hint)"
[ -x "$GENERATE" ]          || die "generate-config.sh not found/executable"
mkdir -p "$OUTPUT_BASE"

# make_defconfig <profile> <arch> <output-file>
# Runs generate-config.sh and, when SKIP_SWIFT is set, drops the swift
# packages so the build does not need the native Swift toolchain.
make_defconfig() {
	local profile="$1" arch="$2" out="$3"
	# FRONTEND=<name> swaps the frontend the image boots into (see
	# sdk/defconfig/frontend/); "minimal" is the bring-up session.
	local fe=()
	[ -n "${FRONTEND:-}" ] && [ "$profile" = "image" ] && fe=(--frontend "$FRONTEND")
	# DEVICE=<name> builds for one board in sdk/board/<name> instead of the
	# generic sdk/board/<arch>: its kernel defconfig, device tree and boot
	# chain in place of the UEFI ones. Only the image carries a board - the
	# 32-bit companion is a sysroot and has no hardware in it - so the lib32
	# pass is left alone, and the two share the arch as before.
	local dev=()
	[ -n "${DEVICE:-}" ] && [ "$profile" = "image" ] && dev=(--device "$DEVICE")
	"$GENERATE" --arch "$arch" --profile "$profile" "${fe[@]}" "${dev[@]}" -o "$out" >/dev/null || return 1
	if [ "${SKIP_SWIFT:-0}" = "1" ]; then
		sed -i -E '/^BR2_PACKAGE_(SWIFT|LIBSWIFTDISPATCH|SWIFT_FOUNDATION)=y/d' "$out"
	fi
}

# br_build <output-dir> <defconfig-file>  - configure then build one image.
br_build() {
	local out="$1" defconfig="$2"; shift 2
	# CLEAN_TREE empties the persistent output tree before configuring.
	#
	# For when the tree itself is not to be trusted rather than one package in
	# it: a machine that dies mid-build can leave a package stamped complete
	# with no source directory and its installed files missing, and Buildroot
	# reads the stamp and skips it. That is not visible until something reaches
	# for a file that was never written - libglib2 lost its .gir files that
	# way, and host-libglib2 its typelibs, each surfacing one build later.
	# REBUILD_PKGS repairs a package you can name; this is for when you cannot.
	#
	# The contents go, not the directory: it is a bind mount of the profile,
	# and removing the mount point would take the tree's identity with it.
	if [ -n "${CLEAN_TREE:-}" ] && [ -d "$out" ]; then
		echo "[br_build] wiping $out (CLEAN_TREE)"
		find "$out" -mindepth 1 -maxdepth 1 -exec rm -rf {} + || return 1
	fi
	# Inject opt-in accelerators into the defconfig before configuring, so they
	# take effect without editing tracked fragments.
	[ "${PARALLEL_BUILD:-0}" = "1" ] && \
		printf 'BR2_PER_PACKAGE_DIRECTORIES=y\n' >> "$defconfig"
	[ "${CCACHE:-0}" = "1" ] && \
		printf 'BR2_CCACHE=y\n' >> "$defconfig"
	make -C "$BUILDROOT" O="$out" BR2_EXTERNAL="$EXTERNALS" $DL_OPT \
		BR2_CCACHE_DIR="$CCACHE_DIR" BR2_DEFCONFIG="$defconfig" defconfig >/dev/null || return 1
	# REBUILD_PKGS forces a dirclean of packages that a prebuilt/cached output
	# (e.g. a CI container) may have built with the wrong options - such as the
	# container's OpenSSL, built without engine support that RAUC needs.
	local pkg
	for pkg in ${REBUILD_PKGS:-}; do
		echo "[br_build] forcing rebuild of $pkg"
		make -C "$BUILDROOT" O="$out" BR2_EXTERNAL="$EXTERNALS" $DL_OPT \
			"$pkg-dirclean" >/dev/null || return 1
	done
	# A package that installed under a host path by mistake leaves the
	# output directory mirrored inside staging or target - ibus once put a
	# python override at <staging>/mnt/br/output/x86_64/... - and Buildroot
	# fails any later staging install on the mere existence of that
	# directory. dirclean does not touch it, since it is not in the build
	# dir, so a rebuild meant to fix the path would fail on the leftover of
	# the path it is fixing. Clear it when a rebuild is asked for.
	if [ -n "${REBUILD_PKGS:-}" ]; then
		for stray in "$out"/staging/"$out" "$out"/target/"$out"; do
			if [ -d "$stray" ]; then
				echo "[br_build] removing stray install at $stray"
				rm -rf "$stray"
			fi
		done
	fi
	# Rebuild host-python3 when the tree's copy is missing an optional module
	# the configuration asks for. Buildroot compiles host-python3 with the
	# modules its configuration named at the time and stamps it built; asking
	# for another one later changes the configuration and nothing else, because
	# a package is rebuilt when its sources change, not when the options that
	# shaped it do. The seeded trees make this certain rather than likely - the
	# toolchain release carries a host-python3 built for the toolchain's own
	# configuration, so every tree starts with that one, stamped.
	#
	# mozjs128 selects the curses module, its configure imports it through
	# mach.logging and the vendored blessed, and the build stopped at:
	#
	#   ModuleNotFoundError: No module named 'curses'
	#
	# with BR2_PACKAGE_HOST_PYTHON3_CURSES=y sitting in the .config and an
	# interpreter that had never heard of it.
	#
	# Asking the interpreter is the reliable test: it answers for the binary
	# that will actually run, whatever produced it.
	local py="$out/host/bin/python3" mod opt
	if [ -x "$py" ]; then
		for opt in BZIP2:bz2 XZ:lzma CURSES:curses SSL:ssl; do
			grep -q "^BR2_PACKAGE_HOST_PYTHON3_${opt%%:*}=y" "$out/.config" 2>/dev/null || continue
			mod="${opt##*:}"
			"$py" -c "import $mod" 2>/dev/null && continue
			echo "[br_build] host python3 lacks $mod, which the configuration selects - rebuilding it"
			make -C "$BUILDROOT" O="$out" BR2_EXTERNAL="$EXTERNALS" $DL_OPT \
				host-python3-dirclean >/dev/null || return 1
			break
		done
	fi
	# Re-extract a ports package when its patch set changes. Buildroot applies
	# patches once, at extract time, and stamps the source directory; a patch
	# added or edited afterwards changes nothing. It is the same rule as above
	# - a package is rebuilt when its sources change, not when the thing that
	# shaped it does - and on trees that persist between runs it means a new
	# patch is quietly ignored and the build fails again with the exact error
	# the patch was written to fix. That is what mozjs128's ast.Str fix cost:
	# the tree already had the package extracted and stamped patched, so the
	# new patch would have sat there unapplied.
	#
	# Digest each ports package's patches and keep the result beside the tree.
	# A package whose digest moved gets dircleaned. One with nothing recorded
	# yet is only recorded, never dircleaned, so switching this on does not
	# rebuild all twenty patched packages at once - it only ever acts on a
	# change it actually watched happen.
	#
	# The global patch directory is walked alongside the ports packages. It
	# carries patches for packages that come from Buildroot itself rather than
	# from ports - mesa3d, libical - and those are stamped in exactly the same
	# way, so a patch added there is no more self-applying than one added to a
	# ports package. Watching only ports would have left libical's gir fix
	# unapplied on every tree that already had it extracted.
	local stampdir="$out/.ports-patch-stamps" pdir pname stamp digest prev
	mkdir -p "$stampdir" 2>/dev/null || true
	if [ -d "$stampdir" ]; then
		for pdir in "$BR2_EXTERNAL_PORTS"/package/*/*/ \
			    "$REPO_DIR"/external/patches/packages/*/; do
			# The glob for a directory that does not exist comes back
			# unexpanded; there is nothing to digest in that case.
			[ -d "$pdir" ] || continue
			# No "set --" here: this function passes its own positional
			# parameters to make as the targets to build.
			#
			# Packages with no patches are digested too, as the hash of no
			# input. Skipping them would leave the case that actually happened
			# to gjs undetectable: a package gaining its first patch is
			# indistinguishable from one that never had any, so nothing would
			# be re-extracted and the patch would not be applied.
			pname=$(basename "$pdir")
			# The two directories are separate namespaces, so a package could
			# appear in both and the pair would then overwrite each other's
			# stamp and dirclean on every build. Only the global entries are
			# prefixed: renaming the ports stamps would make every one of them
			# look unrecorded, and an unrecorded stamp is written but never
			# acted on, which would silently skip a ports patch changed in the
			# same commit.
			case $pdir in
			"$REPO_DIR"/external/patches/*) stamp="global--$pname" ;;
			*)                              stamp="$pname" ;;
			esac
			digest=$(cat "$pdir"*.patch 2>/dev/null | sha256sum | cut -d' ' -f1)
			prev=$(cat "$stampdir/$stamp" 2>/dev/null || true)
			if [ -n "$prev" ] && [ "$prev" != "$digest" ]; then
				echo "[br_build] $pname patches changed - re-extracting it"
				make -C "$BUILDROOT" O="$out" BR2_EXTERNAL="$EXTERNALS" $DL_OPT \
					"$pname-dirclean" >/dev/null || return 1
			fi
			printf '%s\n' "$digest" > "$stampdir/$stamp"
		done
	fi
	# Clear the linker configuration the lib32 merge leaves behind, or an
	# incremental build stops before it gets anywhere:
	#
	#   ERROR: we shouldn't have a /etc/ld.so.conf file
	#   make: *** [Makefile:772: target-finalize] Error 1
	#
	# Buildroot refuses both /etc/ld.so.conf and /etc/ld.so.conf.d, and tests
	# for them inside target-finalize - while BR2_ROOTFS_POST_BUILD_SCRIPT runs
	# at the end of that same rule. So post-build-lib32.sh writes the files
	# after the test that forbids them, every build leaves them behind, and the
	# next build over the same tree fails on what the last one wrote.
	#
	# It stayed hidden because br-seed empties the tree whenever the toolchain
	# release changes, and until now every image build happened to follow one.
	# The toolchain is weekly, so the first nightly that seeds no new tree hits
	# this - six nights out of seven, once it starts.
	#
	# Removing them here rather than in a post-build script: those all run
	# after the test, so anything they delete is either recreated by the lib32
	# merge moments later or lost from the image entirely. This is the last
	# point that is still before make.
	rm -f "$out/target/etc/ld.so.conf"
	rm -rf "$out/target/etc/ld.so.conf.d"
	# FORCE_UNSAFE_CONFIGURE lets host tools configure as root (CI/containers).
	FORCE_UNSAFE_CONFIGURE=1 make -C "$BUILDROOT" O="$out" BR2_EXTERNAL="$EXTERNALS" \
		$DL_OPT BR2_CCACHE_DIR="$CCACHE_DIR" $BR2_MAKE_OPTS "$@"
}

# build_track <arch> - the full lib32-then-image sequence for one architecture.
build_track() {
	local arch="$1"
	local lib32arch; lib32arch="$(companion_of "$arch")"
	# When building a single arch, IMAGE_OUTPUT_DIR may point the image build
	# at an existing output dir (e.g. a CI container's cached output/<arch>
	# that already has the cross-toolchain and swift built), so only the
	# remaining packages compile. Ignored when building multiple arches.
	# Keyed on the device when there is one, so a board build and the generic
	# arch build do not land in the same tree. They differ in kernel
	# configuration, device tree and boot chain, and Buildroot would reconfigure
	# over the top rather than start clean - which is how a file from the last
	# build ends up in the next one's image.
	#
	# And keyed on the frontend too, for the same reason one step further out.
	# Buildroot rebuilds a package when its own sources change, not when the
	# configuration that shaped it does, so a tree carries whatever its last
	# build decided. Asking a tree built for "minimal" to produce GNOME gets:
	#
	#   Couldn't find include 'GLib-2.0.gir'
	#   FAILED: [code=1] atk/Atk-1.0.gir
	#
	# because minimal built glib2 without introspection, that glib2 is stamped
	# built, and at-spi2-core needs the .gir files it would have installed.
	# The same hazard runs the other way: GNOME's packages would linger in
	# target/ and ship inside the next "minimal" image.
	#
	# minimal keeps the unsuffixed name so the nightly's warm trees stay warm;
	# every other frontend gets its own, cold the first time and reused after.
	local key="${DEVICE:-$arch}"
	case "${FRONTEND:-}" in
		''|minimal) ;;
		*) key="$key-$FRONTEND" ;;
	esac
	local img_out="$OUTPUT_BASE/$key-image"
	if [ -n "${IMAGE_OUTPUT_DIR:-}" ] && [ "$SINGLE_ARCH" = "1" ]; then
		img_out="$IMAGE_OUTPUT_DIR"
	fi
	local lib32_root=""

	echo "[$arch] starting"

	if [ -n "${LIB32_ROOT:-}" ]; then
		# A companion built elsewhere (CI builds it in the container that has
		# that architecture's cached toolchain, then hands the target tree
		# here); merge it instead of building one.
		lib32_root="$LIB32_ROOT"
		echo "[$arch] using prebuilt lib32 companion: $lib32_root"
	elif [ -n "$lib32arch" ] && [ "${NO_LIB32:-0}" != "1" ]; then
		local l_out="$OUTPUT_BASE/$lib32arch-lib32"
		local l_cfg="$OUTPUT_BASE/$lib32arch-lib32.defconfig"
		echo "[$arch] building $lib32arch lib32 companion"
		make_defconfig lib32 "$lib32arch" "$l_cfg" || { echo "[$arch] lib32 defconfig failed"; return 1; }
		br_build "$l_out" "$l_cfg" all || { echo "[$arch] lib32 build FAILED"; return 1; }
		lib32_root="$l_out/target"
	fi

	echo "[$arch] building image${DEVICE:+ for $DEVICE}"
	local i_cfg="$OUTPUT_BASE/$key-image.defconfig"
	make_defconfig image "$arch" "$i_cfg" || { echo "[$arch] image defconfig failed"; return 1; }
	SWIFT_LINUX_LIB32_ROOT="$lib32_root" br_build "$img_out" "$i_cfg" all \
		|| { echo "[$arch] image build FAILED"; return 1; }

	# Any *.img counts. What the board's boot chain writes is its own
	# business - genimage leaves disk.img on the UEFI boards, the
	# Chromebooks' post-image leaves chromebook.img - and this check has no
	# reason to hold a list of the names. It held one, and the first scarlet
	# build compiled for five hours, produced a signed 6.5 GB chromebook.img
	# and was declared failed for not being called disk.img.
	local produced
	produced=$(find "$img_out/images" -maxdepth 1 -name '*.img' 2>/dev/null | sort | head -1)
	if [ -n "$produced" ]; then
		echo "[$arch] DONE -> $produced"
	else
		echo "[$arch] finished but produced no .img"; return 1
	fi
}

# An exported-but-empty DEVICE is not the same thing as an absent one to
# everything downstream. This script treats the two alike - ${DEVICE:-} is used
# throughout - but a package build sees the raw environment, and CMake's
# if(DEFINED ENV{DEVICE}) is satisfied by an empty string. emulationstation
# guards its board defines that way and then emits
#
#   add_definitions(-D$ENV{DEVICE})
#
# which expands to a bare -D, so gcc takes the following flag as the macro name:
#
#   <command-line>: error: macro names must be identifiers
#
# Make the environment agree with what this script already means.
[ -n "${DEVICE:-}" ] || unset DEVICE

# ---- select arches -------------------------------------------------------
arches=("$@")
[ ${#arches[@]} -gt 0 ] || arches=(x86_64 arm64)
[ ${#arches[@]} -eq 1 ] && SINGLE_ARCH=1 || SINGLE_ARCH=0

# A device names one board, and a board is one architecture, so building two
# arches for it is meaningless - and silently applying it to both would produce
# an x86_64 image claiming to be an arm64 tablet. The arch it belongs to is
# recorded in the board's boardinfo; check it here rather than let the mismatch
# turn up hours later as a kernel that does not match the device tree.
if [ -n "${DEVICE:-}" ]; then
	board_dir="$REPO_DIR/sdk/board/$DEVICE"
	[ -f "$board_dir/board.config" ] || \
		die "unknown device '$DEVICE' (no $board_dir/board.config)"
	# sdk/board/x86_64 and sdk/board/arm64 are the generic UEFI boards the
	# --arch path already uses, not devices, and generate-config.sh leaves
	# them out of the device list it prints for exactly that reason. Passing
	# one as --device produces a defconfig with no architecture selected at
	# all, so kconfig falls back to its first choice - i386 - and the build
	# dies configuring the first target package it reaches:
	#
	#   ac_cv_env_CC_value=.../host/bin/i686-swift-linux-gnu-gcc
	#   configure: error: C compiler cannot create executables
	#
	# in a tree whose only compiler is x86_64-swift-linux-gnu-gcc. Say so
	# here instead, and point at the flag that does what was meant.
	case "$DEVICE" in
		x86_64|arm64|common)
			die "'$DEVICE' is an architecture, not a device - build it with 'build-images.sh $DEVICE' and no DEVICE=" ;;
	esac
	[ "$SINGLE_ARCH" = "1" ] || \
		die "DEVICE=$DEVICE needs exactly one architecture (got: ${arches[*]})"
	board_arch=$(sed -n 's/^ARCH=//p' "$board_dir/boardinfo" 2>/dev/null | head -1)
	if [ -n "$board_arch" ] && [ "$board_arch" != "${arches[0]}" ]; then
		die "device '$DEVICE' is $board_arch, not ${arches[0]}"
	fi
fi

echo "build-images: BUILDROOT=$BUILDROOT"
echo "build-images: externals=$EXTERNALS"
echo "build-images: output=$OUTPUT_BASE  skip_swift=${SKIP_SWIFT:-0}  no_lib32=${NO_LIB32:-0}"
echo "build-images: arches=${arches[*]}"

# ---- run tracks in parallel ---------------------------------------------
declare -A pids
for a in "${arches[@]}"; do
	log="$OUTPUT_BASE/$a-image.log"
	build_track "$a" >"$log" 2>&1 &
	pids[$a]=$!
	echo "build-images: [$a] track pid ${pids[$a]}, log $log"
done

rc=0
for a in "${arches[@]}"; do
	if wait "${pids[$a]}"; then
		echo "build-images: [$a] SUCCEEDED"
	else
		echo "build-images: [$a] FAILED (see $OUTPUT_BASE/$a-image.log)"
		rc=1
	fi
done

echo "build-images: images:"
for a in "${arches[@]}"; do
	key="${DEVICE:-$a}"
	case "${FRONTEND:-}" in ''|minimal) ;; *) key="$key-$FRONTEND" ;; esac
	dir="$OUTPUT_BASE/$key-image/images"
	img=$(find "$dir" -maxdepth 1 -name '*.img' 2>/dev/null | sort | head -1)
	[ -n "$img" ] && echo "  $a: $img" || echo "  $a: (not produced)"
done
exit "$rc"
