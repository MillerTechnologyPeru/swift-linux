#!/bin/sh
# Rockchip RK3566 handheld post-image: stage kernel + device tree + extlinux
# onto a boot dir, then assemble the SD-card image with genimage.
#
# DEFINITION ONLY - not build-verified. The device tree name comes from the
# board's BR2_LINUX_KERNEL_INTREE_DTS_NAME; a real build must have that DTS.
set -e
BOARD_DIR="$(dirname "$0")"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"

DTS_NAME="$(sed -n 's/^BR2_LINUX_KERNEL_INTREE_DTS_NAME="\(.*\)"$/\1/p' "${BR2_CONFIG}")"
DTB="$(basename "${DTS_NAME}").dtb"

BOOT="${BINARIES_DIR}/boot"
rm -rf "${BOOT}"; mkdir -p "${BOOT}/extlinux"
cp "${BINARIES_DIR}/Image" "${BOOT}/Image" 2>/dev/null || true
cp "${BINARIES_DIR}/${DTB}" "${BOOT}/dtb" 2>/dev/null || true
sed "s,/DTB,/dtb," "${BOARD_DIR}/boot/extlinux.conf" > "${BOOT}/extlinux/extlinux.conf"

cp "${GENIMAGE_CFG}" "${BINARIES_DIR}/genimage.cfg"
support/scripts/genimage.sh -c "${BINARIES_DIR}/genimage.cfg"
sh "${BOARD_DIR}/../common/post-image-finalize.sh" "${BINARIES_DIR}" "$(basename "${BR2_CONFIG%/.config}")" 2>/dev/null || true
