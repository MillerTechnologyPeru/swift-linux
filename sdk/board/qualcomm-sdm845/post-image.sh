#!/bin/sh
# SDM845 phone post-image: assemble an Android boot.img (gzipped kernel with
# the device tree appended) for fastboot flashing.
#
# DEFINITION ONLY - not verified on hardware. Standard SDM845 layout: page
# size 4096, base 0x0, kernel offset 0x8000. Rootfs is flashed to userdata
# separately (fastboot flash userdata rootfs.erofs / or via recovery).
set -e
DTS_NAME="$(sed -n 's/^BR2_LINUX_KERNEL_INTREE_DTS_NAME="\(.*\)"$/\1/p' "${BR2_CONFIG}")"
DTB="${BINARIES_DIR}/$(basename "${DTS_NAME}").dtb"
IMG="${BINARIES_DIR}/Image"
[ -f "$IMG" ] && [ -f "$DTB" ] || { echo "post-image: kernel or dtb missing; skipping boot.img"; exit 0; }

gzip -9 -c "$IMG" > "${BINARIES_DIR}/Image.gz"
cat "${BINARIES_DIR}/Image.gz" "$DTB" > "${BINARIES_DIR}/Image.gz-dtb"
cat > "${BINARIES_DIR}/bootimg.cfg" <<CFG
bootsize = 0x4000000
pagesize = 0x1000
kerneladdr = 0x8000
ramdiskaddr = 0x1000000
secondaddr = 0xf00000
tagsaddr = 0x100
name =
cmdline = console=tty0 root=PARTLABEL=userdata rw rootwait clk_ignore_unused pd_ignore_unused
CFG
"${HOST_DIR}/bin/abootimg" --create "${BINARIES_DIR}/boot.img" \
	-f "${BINARIES_DIR}/bootimg.cfg" -k "${BINARIES_DIR}/Image.gz-dtb" \
	-r /dev/null 2>/dev/null || \
"${HOST_DIR}/bin/abootimg" --create "${BINARIES_DIR}/boot.img" \
	-f "${BINARIES_DIR}/bootimg.cfg" -k "${BINARIES_DIR}/Image.gz-dtb"
echo "post-image: boot.img ready (fastboot flash boot boot.img)"
