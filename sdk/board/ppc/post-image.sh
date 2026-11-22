#!/bin/sh
# Board (ppc/QEMU mac99) post-image: assemble the A/B disk image with
# genimage. The kernel stays beside it as images/vmlinux for QEMU's -kernel.
# Runs with the Buildroot top dir as CWD.
set -e
BOARD_DIR="$(dirname "$0")"

cp "${BOARD_DIR}/genimage.cfg" "${BINARIES_DIR}/genimage.cfg"
support/scripts/genimage.sh -c "${BINARIES_DIR}/genimage.cfg"

# Name the artifact per target and write SHA256SUMS.
sh "${BOARD_DIR}/../common/post-image-finalize.sh" "${BINARIES_DIR}" "ppc"
