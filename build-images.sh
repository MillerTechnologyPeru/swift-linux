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
	"$GENERATE" --arch "$arch" --profile "$profile" -o "$out" >/dev/null || return 1
	if [ "${SKIP_SWIFT:-0}" = "1" ]; then
		sed -i -E '/^BR2_PACKAGE_(SWIFT|LIBSWIFTDISPATCH|SWIFT_FOUNDATION)=y/d' "$out"
	fi
}

# br_build <output-dir> <defconfig-file>  - configure then build one image.
br_build() {
	local out="$1" defconfig="$2"; shift 2
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
	local img_out="$OUTPUT_BASE/$arch-image"
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

	echo "[$arch] building image"
	local i_cfg="$OUTPUT_BASE/$arch-image.defconfig"
	make_defconfig image "$arch" "$i_cfg" || { echo "[$arch] image defconfig failed"; return 1; }
	SWIFT_LINUX_LIB32_ROOT="$lib32_root" br_build "$img_out" "$i_cfg" all \
		|| { echo "[$arch] image build FAILED"; return 1; }

	if [ -f "$img_out/images/disk.img" ]; then
		echo "[$arch] DONE -> $img_out/images/disk.img"
	else
		echo "[$arch] finished but no disk.img"; return 1
	fi
}

# ---- select arches -------------------------------------------------------
arches=("$@")
[ ${#arches[@]} -gt 0 ] || arches=(x86_64 arm64)
[ ${#arches[@]} -eq 1 ] && SINGLE_ARCH=1 || SINGLE_ARCH=0

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
	img="$OUTPUT_BASE/$a-image/images/disk.img"
	[ -f "$img" ] && echo "  $a: $img" || echo "  $a: (not produced)"
done
exit "$rc"
