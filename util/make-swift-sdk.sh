#!/bin/bash
# Package a buildroot-swift target sysroot into a Swift SDK artifactbundle so
# SwiftPM can cross-compile packages for the Swift Linux image:
#
#     swift build --swift-sdk aarch64-unknown-linux-gnu
#
# Two modes:
#   (default)   Local/dev SDK. References the buildroot sysroot in place by
#               absolute path - small and instant, but only works on this
#               machine. Regenerate per machine.
#   --portable  Self-contained SDK. Copies the sysroot and the cross-gcc into
#               the bundle and uses relative paths, so the bundle can be zipped
#               and `swift sdk install`ed on any x86_64 host with a matching
#               Swift toolchain - no buildroot checkout needed (~450 MB).
#
# IMPORTANT: Swift binary .swiftmodule files are locked to the exact compiler
# version that produced them. The host toolchain used for `swift build` must
# match the sysroot's Swift version (this script prints it). Install a matching
# toolchain with e.g. `swiftly install <version>` and select it with
# `swiftly run +<version> swift build ...`.
#
# Usage:
#   util/make-swift-sdk.sh [--arch arm64|x86_64|armv7|i386] [--portable] [--out DIR] [--install]
# Env:
#   OUTPUT_BASE  Buildroot output dir (default: <repo>/output, where the
#                Makefile and build-images.sh put per-target trees)
#   BR_SWIFT     legacy alias for the tree holding output/ (CI points it at the
#                container's /workspaces/buildroot-swift)
set -eu

ARCH="arm64"
OUT=""
DO_INSTALL=0
PORTABLE=0
while [ $# -gt 0 ]; do
	case "$1" in
		--arch) ARCH="$2"; shift 2 ;;
		--out) OUT="$2"; shift 2 ;;
		--portable) PORTABLE=1; shift ;;
		--install) DO_INSTALL=1; shift ;;
		-h|--help) grep '^#' "$0" | sed 's/^# \?//'; exit 0 ;;
		*) echo "unknown arg: $1" >&2; exit 1 ;;
	esac
done

case "$ARCH" in
	arm64|aarch64) TRIPLE_GNU="aarch64-swift-linux-gnu";     TARGET="aarch64-unknown-linux-gnu" ;;
	x86_64|amd64)  TRIPLE_GNU="x86_64-swift-linux-gnu";      TARGET="x86_64-unknown-linux-gnu" ;;
	armv7|arm)     TRIPLE_GNU="arm-swift-linux-gnueabihf";   TARGET="armv7-unknown-linux-gnueabihf" ;;
	i386|i686)     TRIPLE_GNU="i686-swift-linux-gnu";        TARGET="i686-unknown-linux-gnu" ;;
	*) echo "unsupported arch: $ARCH" >&2; exit 1 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BR_SWIFT="${BR_SWIFT:-$SCRIPT_DIR/..}"
OUTPUT_BASE="${OUTPUT_BASE:-$BR_SWIFT/output}"
BR_OUT="$OUTPUT_BASE/$ARCH"
HOST="$BR_OUT/host"
SRC_SYSROOT="$HOST/$TRIPLE_GNU/sysroot"

[ -d "$SRC_SYSROOT/usr/lib/swift/linux" ] || {
	echo "error: no Swift sysroot at $SRC_SYSROOT" >&2
	echo "       build the $ARCH image first (build-images.sh) so the toolchain exists." >&2
	exit 1
}

GCC_VER="$(basename "$(ls -d "$HOST/lib/gcc/$TRIPLE_GNU"/*/ | head -1)")"
SRC_GCC="$HOST/lib/gcc/$TRIPLE_GNU/$GCC_VER"
SRC_CXX_INC="$HOST/$TRIPLE_GNU/include/c++/$GCC_VER"

# Discover the Swift version and the exact target triple that built the stdlib
# (from any .swiftinterface) - the triple is authoritative over the guess above.
IFACE="$(find "$SRC_SYSROOT/usr/lib/swift/linux" -name '*.swiftinterface' | head -1)"
SWIFT_VER="$(sed -n 's|.*swift-\([0-9.]*\)-RELEASE.*|\1|p' "$IFACE" | head -1)"
[ -n "$SWIFT_VER" ] || SWIFT_VER="unknown"
IFACE_TARGET="$(sed -n 's|.*-target \([A-Za-z0-9_-]*\).*|\1|p' "$IFACE" | head -1)"
[ -n "$IFACE_TARGET" ] && TARGET="$IFACE_TARGET"

ID="swift-linux-$ARCH"
OUT="${OUT:-$PWD/$ID.artifactbundle}"
rm -rf "$OUT"; mkdir -p "$OUT/$ID"

if [ "$PORTABLE" = 1 ]; then
	# Copy the sysroot into the bundle and fold the cross-gcc into it under the
	# target triple, so clang auto-detects the GCC install (crt objects, libgcc,
	# libstdc++) from --sysroot alone. All SDK paths are relative to the bundle.
	echo "copying sysroot into bundle (this is the portable copy)..."
	SYS="$OUT/$ID/sysroot"
	# Copy only what a compilation sysroot needs, excluding runtime trees
	# (usr/bin, var, ...) and usr/share. This is not only a size win: ncurses'
	# terminfo database (usr/share/terminfo) contains entries differing only by
	# case (e.g. P4/p4), which cannot extract on a case-insensitive filesystem
	# (macOS/APFS default) - the bundle must not carry it. Excluding at copy
	# time also skips root-owned runtime files (e.g. a dbus launch helper) that
	# a containerized build may have left unreadable.
	#
	# Known remaining case collisions: the kernel's netfilter UAPI headers
	# (xt_CONNMARK.h vs xt_connmark.h, ...). Those extract as a single file on
	# case-insensitive filesystems (silent overwrite) and only matter when
	# building iptables extensions, so they are left in place.
	mkdir -p "$SYS"
	# usr/lib/xtables holds iptables runtime plugins (dlopened, never linked at
	# build time) whose upper/lowercase pairs (libxt_MARK/libxt_mark, ...) also
	# case-collide, so they are excluded too.
	rsync -a \
		--exclude=/usr/share --exclude=/usr/bin --exclude=/usr/sbin \
		--exclude=/usr/libexec --exclude=/usr/games \
		--exclude=/usr/lib/xtables \
		--exclude=/bin --exclude=/sbin --exclude=/var --exclude=/run \
		--exclude=/tmp --exclude=/opt --exclude=/srv --exclude=/media \
		--exclude=/mnt --exclude=/root --exclude=/home --exclude=/boot \
		--exclude=/dev --exclude=/proc --exclude=/sys \
		"$SRC_SYSROOT/" "$SYS/"
	# Re-add the parts of usr/share builds actually consume: pkg-config data
	# and the wayland protocol XMLs (some packages install .pc files to
	# usr/share/pkgconfig; wayland clients generate code from usr/share/wayland*).
	mkdir -p "$SYS/usr/share"
	for keep in pkgconfig wayland wayland-protocols cmake; do
		if [ -d "$SRC_SYSROOT/usr/share/$keep" ]; then
			rsync -a "$SRC_SYSROOT/usr/share/$keep" "$SYS/usr/share/"
		fi
	done
	# GCC install dir clang probes: <sysroot>/usr/lib/gcc/<target-triple>/<ver>
	mkdir -p "$SYS/usr/lib/gcc/$TARGET"
	cp -a "$SRC_GCC" "$SYS/usr/lib/gcc/$TARGET/$GCC_VER"
	# libstdc++ headers, with the triple-specific bits dir named for the target.
	if [ -d "$SRC_CXX_INC" ]; then
		mkdir -p "$SYS/usr/include/c++"
		cp -a "$SRC_CXX_INC" "$SYS/usr/include/c++/$GCC_VER"
		[ -d "$SYS/usr/include/c++/$GCC_VER/$TRIPLE_GNU" ] && \
			ln -sfn "$TRIPLE_GNU" "$SYS/usr/include/c++/$GCC_VER/$TARGET"
	fi
	SDKROOT="sysroot"
	SWIFT_RES="sysroot/usr/lib/swift"
	SWIFT_STATIC_RES="sysroot/usr/lib/swift_static"
	INC="\"sysroot/usr/include\", \"sysroot/usr/include/c++/$GCC_VER\", \"sysroot/usr/include/c++/$GCC_VER/$TARGET\""
	LIB="\"sysroot/usr/lib\", \"sysroot/usr/lib/swift/linux\""
	# No absolute -B needed: clang finds gcc via --sysroot.
	SWIFTC_OPTS='"-use-ld=lld"'
	[ -f "$SYS/SDKSettings.json" ] || printf '{ "DisplayName": "Swift Linux %s", "Version": "%s", "CanonicalName": "%s" }\n' "$ARCH" "$SWIFT_VER" "$TRIPLE_GNU" > "$SYS/SDKSettings.json"
else
	# Local SDK: reference the buildroot tree in place by absolute path.
	SDKROOT="$SRC_SYSROOT"
	SWIFT_RES="$SRC_SYSROOT/usr/lib/swift"
	SWIFT_STATIC_RES="$SRC_SYSROOT/usr/lib/swift_static"
	INC="\"$SRC_SYSROOT/usr/include\", \"$SRC_CXX_INC\", \"$SRC_CXX_INC/$TRIPLE_GNU\""
	LIB="\"$SRC_SYSROOT/usr/lib\", \"$SRC_SYSROOT/usr/lib/swift/linux\", \"$SRC_GCC\""
	SWIFTC_OPTS="\"-use-ld=lld\", \"-Xclang-linker\", \"-B$SRC_GCC\", \"-Xclang-linker\", \"-B$SRC_SYSROOT/usr/lib\", \"-Xclang-linker\", \"--gcc-install-dir=$SRC_GCC\", \"-Xclang-linker\", \"-latomic\""
	[ -f "$SRC_SYSROOT/SDKSettings.json" ] || printf '{ "DisplayName": "Swift Linux %s", "Version": "%s", "CanonicalName": "%s" }\n' "$ARCH" "$SWIFT_VER" "$TRIPLE_GNU" > "$SRC_SYSROOT/SDKSettings.json"
fi

cat > "$OUT/info.json" <<JSON
{
  "schemaVersion": "1.0",
  "artifacts": {
    "$ID": {
      "type": "swiftSDK",
      "version": "$SWIFT_VER",
      "variants": [ { "path": "$ID" } ]
    }
  }
}
JSON

cat > "$OUT/$ID/swift-sdk.json" <<JSON
{
  "schemaVersion": "4.0",
  "targetTriples": {
    "$TARGET": {
      "sdkRootPath": "$SDKROOT",
      "swiftResourcesPath": "$SWIFT_RES",
      "swiftStaticResourcesPath": "$SWIFT_STATIC_RES",
      "includeSearchPaths": [ $INC ],
      "librarySearchPaths": [ $LIB ],
      "toolsetPaths": [ "toolset.json" ]
    }
  }
}
JSON

cat > "$OUT/$ID/toolset.json" <<JSON
{
  "schemaVersion": "1.0",
  "swiftCompiler": { "extraCLIOptions": [ $SWIFTC_OPTS ] },
  "cCompiler":     { "extraCLIOptions": [ "-fPIC" ] },
  "linker":        { "extraCLIOptions": [ "-latomic" ] }
}
JSON

echo "arch        : $ARCH ($TARGET)"
echo "mode        : $([ "$PORTABLE" = 1 ] && echo portable || echo local)"
echo "swift       : $SWIFT_VER   <- host toolchain must match this"
echo "bundle      : $OUT"

if [ "$DO_INSTALL" = 1 ]; then
	swift sdk install "$OUT" 2>&1 | tail -1
fi

echo
echo "Next:"
echo "  swiftly install $SWIFT_VER            # matching host toolchain (once)"
[ "$DO_INSTALL" = 1 ] || echo "  swift sdk install $OUT"
echo "  swiftly run +$SWIFT_VER swift build --swift-sdk $TARGET"
