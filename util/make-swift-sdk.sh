#!/bin/bash
# Package a buildroot-swift target sysroot into a Swift SDK artifactbundle so
# SwiftPM can cross-compile packages for the Swift Linux image:
#
#     swift build --swift-sdk aarch64-unknown-linux-gnu
#
# The generated SDK references the sysroot in place (by absolute path) rather
# than copying it, so it is a local/dev SDK - regenerate it on each machine.
#
# IMPORTANT: Swift binary .swiftmodule files are locked to the exact compiler
# version that produced them. The host toolchain used for `swift build` must
# match the sysroot's Swift version (this script prints it). Install a matching
# toolchain with e.g. `swiftly install <version>` and select it with
# `swiftly run +<version> swift build ...`.
#
# Usage:
#   util/make-swift-sdk.sh [--arch arm64|x86_64] [--out DIR] [--install]
# Env:
#   BR_SWIFT   buildroot-swift checkout (default: ../buildroot-swift)
set -eu

ARCH="arm64"
OUT=""
DO_INSTALL=0
while [ $# -gt 0 ]; do
	case "$1" in
		--arch) ARCH="$2"; shift 2 ;;
		--out) OUT="$2"; shift 2 ;;
		--install) DO_INSTALL=1; shift ;;
		-h|--help) grep '^#' "$0" | sed 's/^# \?//'; exit 0 ;;
		*) echo "unknown arg: $1" >&2; exit 1 ;;
	esac
done

case "$ARCH" in
	arm64|aarch64) TRIPLE_GNU="aarch64-swift-linux-gnu"; TARGET="aarch64-unknown-linux-gnu" ;;
	x86_64|amd64)  TRIPLE_GNU="x86_64-swift-linux-gnu";  TARGET="x86_64-unknown-linux-gnu" ;;
	*) echo "unsupported arch: $ARCH" >&2; exit 1 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BR_SWIFT="${BR_SWIFT:-$SCRIPT_DIR/../../buildroot-swift}"
BR_OUT="$BR_SWIFT/output/$ARCH"
HOST="$BR_OUT/host"
SYSROOT="$HOST/$TRIPLE_GNU/sysroot"

[ -d "$SYSROOT/usr/lib/swift/linux" ] || {
	echo "error: no Swift sysroot at $SYSROOT" >&2
	echo "       build the $ARCH image first (build-images.sh) so the toolchain exists." >&2
	exit 1
}

GCC_VER="$(basename "$(ls -d "$HOST/lib/gcc/$TRIPLE_GNU"/*/ | head -1)")"
GCC_INSTALL="$HOST/lib/gcc/$TRIPLE_GNU/$GCC_VER"
CXX_INC="$HOST/$TRIPLE_GNU/include/c++/$GCC_VER"

# Discover the Swift version that built the stdlib (from any .swiftinterface).
IFACE="$(find "$SYSROOT/usr/lib/swift/linux" -name '*.swiftinterface' | head -1)"
SWIFT_VER="$(sed -n 's|.*swift-\([0-9.]*\)-RELEASE.*|\1|p' "$IFACE" | head -1)"
[ -n "$SWIFT_VER" ] || SWIFT_VER="unknown"

ID="swift-linux-$ARCH"
OUT="${OUT:-$PWD/$ID.artifactbundle}"
rm -rf "$OUT"; mkdir -p "$OUT/$ID"

# Optional metadata SwiftPM looks for at the SDK root; silences a warning.
[ -f "$SYSROOT/SDKSettings.json" ] || cat > "$SYSROOT/SDKSettings.json" <<JSON
{ "DisplayName": "Swift Linux $ARCH", "Version": "$SWIFT_VER", "CanonicalName": "$TRIPLE_GNU" }
JSON

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
      "sdkRootPath": "$SYSROOT",
      "swiftResourcesPath": "$SYSROOT/usr/lib/swift",
      "swiftStaticResourcesPath": "$SYSROOT/usr/lib/swift_static",
      "includeSearchPaths": [
        "$SYSROOT/usr/include",
        "$CXX_INC",
        "$CXX_INC/$TRIPLE_GNU"
      ],
      "librarySearchPaths": [
        "$SYSROOT/usr/lib",
        "$SYSROOT/usr/lib/swift/linux",
        "$GCC_INSTALL"
      ],
      "toolsetPaths": [ "toolset.json" ]
    }
  }
}
JSON

cat > "$OUT/$ID/toolset.json" <<JSON
{
  "schemaVersion": "1.0",
  "swiftCompiler": { "extraCLIOptions": [
    "-use-ld=lld",
    "-Xclang-linker", "-B$GCC_INSTALL",
    "-Xclang-linker", "-B$SYSROOT/usr/lib",
    "-Xclang-linker", "--gcc-install-dir=$GCC_INSTALL",
    "-Xclang-linker", "-latomic"
  ] },
  "cCompiler":     { "extraCLIOptions": [ "-fPIC", "--gcc-install-dir=$GCC_INSTALL" ] },
  "cxxCompiler":   { "extraCLIOptions": [ "--gcc-install-dir=$GCC_INSTALL" ] },
  "linker":        { "extraCLIOptions": [ "-latomic" ] }
}
JSON

echo "arch        : $ARCH ($TARGET)"
echo "sysroot     : $SYSROOT"
echo "swift       : $SWIFT_VER   <- host toolchain must match this"
echo "bundle      : $OUT"

if [ "$DO_INSTALL" = 1 ]; then
	swift sdk install "$OUT" 2>&1 | tail -1
fi

echo
echo "Next:"
echo "  swiftly install $SWIFT_VER            # matching host toolchain (once)"
echo "  swift sdk install $OUT"
echo "  swiftly run +$SWIFT_VER swift build --swift-sdk $TARGET"
