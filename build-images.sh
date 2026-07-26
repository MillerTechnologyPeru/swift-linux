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
#   BUILDROOT           Buildroot source tree
#                       (default: <repo>/../buildroot-swift/buildroot)
#   BR2_EXTERNAL_SWIFT  buildroot-swift external
#                       (default: <repo>/../buildroot-swift)
#   OUTPUT_BASE         where per-build output dirs go
#                       (default: $BR2_EXTERNAL_SWIFT/output)
#   SKIP_SWIFT=1        build without the swift package, for hosts that lack
#                       the native Swift toolchain the swift package needs.
#                       The image is otherwise complete.
#   NO_LIB32=1          skip the 32-bit companion (no /usr/lib32, no box86)
#
# Usage: ./build-images.sh [x86_64] [arm64]      (default: both)

set -u

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDROOT="${BUILDROOT:-$REPO_DIR/../buildroot-swift/buildroot}"
BR2_EXTERNAL_SWIFT="${BR2_EXTERNAL_SWIFT:-$REPO_DIR/../buildroot-swift}"
OUTPUT_BASE="${OUTPUT_BASE:-$BR2_EXTERNAL_SWIFT/output}"
EXTERNALS="${BR2_EXTERNAL_SWIFT}:${REPO_DIR}/external"
GENERATE="$REPO_DIR/generate-config.sh"

# arch -> its 32-bit companion arch (empty means "no companion").
companion_of() {
	case "$1" in
		x86_64) echo "i386" ;;
		arm64)  echo "armv7" ;;
		*)      echo "" ;;
	esac
}

die() { echo "build-images: $*" >&2; exit 1; }

[ -d "$BUILDROOT" ]          || die "BUILDROOT not found: $BUILDROOT"
[ -d "$BR2_EXTERNAL_SWIFT" ] || die "buildroot-swift external not found: $BR2_EXTERNAL_SWIFT"
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
	make -C "$BUILDROOT" O="$out" BR2_EXTERNAL="$EXTERNALS" \
		BR2_DEFCONFIG="$defconfig" defconfig >/dev/null || return 1
	# FORCE_UNSAFE_CONFIGURE lets host tools configure as root (CI/containers).
	FORCE_UNSAFE_CONFIGURE=1 make -C "$BUILDROOT" O="$out" BR2_EXTERNAL="$EXTERNALS" "$@"
}

# build_track <arch> - the full lib32-then-image sequence for one architecture.
build_track() {
	local arch="$1"
	local lib32arch; lib32arch="$(companion_of "$arch")"
	local img_out="$OUTPUT_BASE/$arch-image"
	local lib32_root=""

	echo "[$arch] starting"

	if [ -n "$lib32arch" ] && [ "${NO_LIB32:-0}" != "1" ]; then
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
