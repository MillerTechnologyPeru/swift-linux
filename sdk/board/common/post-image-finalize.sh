#!/bin/sh
# Shared image finalization: give the disk image a target-qualified name and
# write a checksum manifest, so published artifacts are identifiable and
# verifiable. disk.img is kept (qemu/flash tooling expects it); the named entry
# is a symlink to avoid duplicating a large image.
#   $1 = BINARIES_DIR   $2 = target name (x86_64, arm64, <device>)
set -e
BINARIES_DIR="$1"; TARGET="$2"
[ -n "$BINARIES_DIR" ] && [ -n "$TARGET" ] || { echo "post-image-finalize: missing args" >&2; exit 1; }
cd "$BINARIES_DIR"
[ -f disk.img ] || exit 0
ln -sf disk.img "swift-linux-$TARGET.img"
sha256sum disk.img > SHA256SUMS
echo "post-image: swift-linux-$TARGET.img + SHA256SUMS"
