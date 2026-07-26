#!/bin/sh
# Board (x86_64/UEFI) post-image: assemble the A/B GPT disk image with
# genimage. Runs with the Buildroot top dir as CWD (like board/pc).
set -e
BOARD_DIR="$(dirname "$0")"

cp "${BOARD_DIR}/genimage.cfg" "${BINARIES_DIR}/genimage.cfg"
support/scripts/genimage.sh -c "${BINARIES_DIR}/genimage.cfg"
