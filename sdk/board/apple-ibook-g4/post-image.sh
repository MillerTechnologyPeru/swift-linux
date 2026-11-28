#!/bin/sh
# Board (Apple iBook G4) post-image: a USB stick image Open Firmware boots.
#
#   1  Apple_partition_map  the map itself
#   2  bootstrap            HFS: the kernel (zImage.pmac) and ofboot.b, the
#                           CHRP boot script Open Firmware runs, typed tbxi
#                           in the blessed folder
#   3  root                 EROFS read-only rootfs, /dev/sdb3 when booted
#                           from USB with the internal disk as /dev/sda
#
# Open Firmware reads Apple partition maps and HFS, not GPT, so this replaces
# the QEMU board's genimage layout. The boot script passes root=/dev/sdb3: an
# Apple partition map has no partition UUIDs to find it by, and there is no
# initramfs to look it up by label. No A/B slots and no data partition yet.
#
# Boot it with Option held at power-on, or from Open Firmware
# (Cmd-Option-O-F) with:  boot ud:2,\\:tbxi
set -e
BOARD_DIR="$(dirname "$0")"
OUT="${BINARIES_DIR}/disk.img"
KERNEL="${BINARIES_DIR}/zImage.pmac"
ROOTFS="${BINARIES_DIR}/rootfs.erofs"
PARTED="${HOST_DIR}/sbin/parted"
[ -x "$PARTED" ] || PARTED="${HOST_DIR}/bin/parted"

[ -f "$KERNEL" ] && [ -f "$ROOTFS" ] || { echo "post-image: kernel or rootfs missing; skipping"; exit 0; }

MIB=1048576
BOOT_MIB=64
ROOT_MIB=$(( ($(stat -c%s "$ROOTFS") + MIB - 1) / MIB + 16 ))
TOTAL_MIB=$(( 1 + BOOT_MIB + ROOT_MIB + 1 ))

# 1. The HFS boot partition. The hfsutils keep the mounted volume's state in
#    $HOME/.hcwd, so give them a home of their own.
BOOT="${BINARIES_DIR}/bootstrap.hfs"
rm -f "$BOOT"; truncate -s $(( BOOT_MIB * MIB )) "$BOOT"
HOME="${BINARIES_DIR}/.hfs-home"; export HOME; mkdir -p "$HOME"
"${HOST_DIR}/bin/hformat" -l "Swift Linux" "$BOOT" >/dev/null
"${HOST_DIR}/bin/hmount" "$BOOT" >/dev/null
"${HOST_DIR}/bin/hcopy" -r "${BOARD_DIR}/ofboot.b" :ofboot.b
"${HOST_DIR}/bin/hcopy" -r "$KERNEL" :zImage
# Open Firmware boots the file of type tbxi in the blessed folder.
"${HOST_DIR}/bin/hattrib" -t tbxi -c chrp :ofboot.b
"${HOST_DIR}/bin/hattrib" -b :
"${HOST_DIR}/bin/humount" >/dev/null

# 2. The Apple partition map. parted puts the map itself first, so the boot
#    partition is 2 and the root 3; check, since the boot script names 3.
rm -f "$OUT"; truncate -s $(( TOTAL_MIB * MIB )) "$OUT"
"$PARTED" -s "$OUT" mklabel mac
"$PARTED" -s "$OUT" mkpart bootstrap hfs 1MiB $(( 1 + BOOT_MIB ))MiB
"$PARTED" -s "$OUT" set 2 boot on
"$PARTED" -s "$OUT" mkpart root ext2 $(( 1 + BOOT_MIB ))MiB $(( 1 + BOOT_MIB + ROOT_MIB ))MiB
table="$("$PARTED" -s -m "$OUT" unit B print)"
start_of() { echo "$table" | awk -F: -v n="$1" '$1 == n { sub(/B$/, "", $2); print $2 }'; }
name_of() { echo "$table" | awk -F: -v n="$1" '$1 == n { print $6 }'; }
[ "$(name_of 2)" = bootstrap ] && [ "$(name_of 3)" = root ] || {
	echo "post-image: unexpected partition numbering:" >&2; echo "$table" >&2; exit 1; }

# 3. The partitions' contents.
dd if="$BOOT" of="$OUT" bs=512 seek=$(( $(start_of 2) / 512 )) conv=notrunc 2>/dev/null
dd if="$ROOTFS" of="$OUT" bs=512 seek=$(( $(start_of 3) / 512 )) conv=notrunc 2>/dev/null
rm -rf "$BOOT" "$HOME"
echo "post-image: ${OUT} (Apple partition map, Open Firmware boot from USB)"
echo "$table"

sh "${BOARD_DIR}/../common/post-image-finalize.sh" "${BINARIES_DIR}" "ppc"
