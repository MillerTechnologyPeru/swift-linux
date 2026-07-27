#!/bin/sh
# Allwinner H700 handheld post-image: stage kernel + device tree + extlinux,
# then assemble the SD-card image with genimage.
#
# DEFINITION ONLY - not build-verified.
set -e
BOARD_DIR="$(dirname "$0")"
DTS_NAME="$(sed -n 's/^BR2_LINUX_KERNEL_INTREE_DTS_NAME="\(.*\)"$/\1/p' "${BR2_CONFIG}")"
DTB="$(basename "${DTS_NAME}").dtb"

BOOT="${BINARIES_DIR}/boot"
rm -rf "${BOOT}"; mkdir -p "${BOOT}/extlinux"
cp "${BINARIES_DIR}/Image" "${BOOT}/Image" 2>/dev/null || true
cp "${BINARIES_DIR}/${DTB}" "${BOOT}/dtb" 2>/dev/null || true
sed "s,/DTB,/dtb," "${BOARD_DIR}/boot/extlinux.conf" > "${BOOT}/extlinux/extlinux.conf"

cp "${BOARD_DIR}/genimage.cfg" "${BINARIES_DIR}/genimage.cfg"
support/scripts/genimage.sh -c "${BINARIES_DIR}/genimage.cfg"
