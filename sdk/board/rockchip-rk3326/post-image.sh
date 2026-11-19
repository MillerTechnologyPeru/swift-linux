#!/bin/sh
# Rockchip RK3326 post-image: stage the boot partition (kernel, this board's
# device tree, extlinux.conf, boot.scr) and assemble the SD-card image with
# genimage. Runs with the Buildroot top dir as CWD.
set -e
BOARD_DIR="$(dirname "$0")"

DTS_NAME="$(sed -n 's/^BR2_LINUX_KERNEL_INTREE_DTS_NAME="\(.*\)"$/\1/p' "${BR2_CONFIG}")"
DTB="$(basename "${DTS_NAME}").dtb"
[ -f "${BINARIES_DIR}/${DTB}" ] || { echo "post-image: ${DTB} not built" >&2; exit 1; }

STAGE="${BINARIES_DIR}/rk3326-boot"
rm -rf "${STAGE}"; mkdir -p "${STAGE}/extlinux"
cp "${BINARIES_DIR}/Image" "${BINARIES_DIR}/${DTB}" "${STAGE}/"
sed "s,@DTB@,${DTB}," "${BOARD_DIR}/boot/extlinux.conf" > "${STAGE}/extlinux/extlinux.conf"
"${HOST_DIR}/bin/mkimage" -A arm64 -T script -C none -d "${BOARD_DIR}/boot/boot.cmd" "${STAGE}/boot.scr"

sed "s,@DTB@,${DTB},g" "${BOARD_DIR}/genimage.cfg" > "${BINARIES_DIR}/genimage.cfg"
support/scripts/genimage.sh -c "${BINARIES_DIR}/genimage.cfg"

sh "${BOARD_DIR}/../common/post-image-finalize.sh" "${BINARIES_DIR}" "$(basename "$(dirname "${BR2_CONFIG}")")"
