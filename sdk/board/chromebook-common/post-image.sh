#!/bin/sh
# Chromebook post-image: pack the kernel + device tree into a signed ChromeOS
# kernel partition and assemble an A/B disk image Depthcharge can boot.
#
# DEFINITION ONLY - not verified on hardware. Layout (sectors), following the
# ChromeOS convention: KERN-A @ 8192, KERN-B @ 73728 (32 MiB each, ChromeOS
# kernel GUID), rootfs from 139264. Slot attributes: A priority 10 / tries 2 /
# successful; B priority 5 / tries 2. Root is found via
# root=PARTUUID=%U/PARTNROFF=N (Depthcharge substitutes %U).
set -e
BOARD_DIR="$(dirname "$0")"
DTS_NAME="$(sed -n 's/^BR2_LINUX_KERNEL_INTREE_DTS_NAME="\(.*\)"$/\1/p' "${BR2_CONFIG}")"
DTB="${BINARIES_DIR}/$(basename "${DTS_NAME}").dtb"
IMG="${BINARIES_DIR}/Image"
OUT="${BINARIES_DIR}/chromebook.img"
KEYS="${HOST_DIR}/share/vboot/devkeys"

[ -f "$IMG" ] && [ -f "$DTB" ] || { echo "post-image: kernel or dtb missing; skipping pack"; exit 0; }

# 1. FIT image (kernel_noload + this device's dtb, compatible from the dtb).
if command -v lz4 >/dev/null 2>&1; then
	lz4 -z --best -f "$IMG" "${BINARIES_DIR}/Image.lz4"; KIMG=Image.lz4; COMP=lz4
else
	gzip -9 -kf "$IMG"; KIMG=Image.gz; COMP=gzip
fi
COMPAT="$("${HOST_DIR}/bin/fdtget" "$DTB" / compatible 2>/dev/null | tr ' ' ',' || true)"
cat > "${BINARIES_DIR}/kernel.its" <<ITS
/dts-v1/;
/ {
	images {
		kernel-1 {
			data = /incbin/("${KIMG}");
			type = "kernel_noload"; arch = "arm64"; os = "linux";
			compression = "${COMP}"; load = <0>; entry = <0>;
		};
		fdt-1 {
			data = /incbin/("$(basename "$DTB")");
			type = "flat_dt"; arch = "arm64"; compression = "none";
			hash-1 { algo = "sha1"; };
		};
	};
	configurations {
		default = "conf-1";
		conf-1 { kernel = "kernel-1"; fdt = "fdt-1"; };
	};
};
ITS
( cd "${BINARIES_DIR}" && "${HOST_DIR}/bin/mkimage" -D "-I dts -O dtb -p 2048" \
	-f kernel.its vmlinux.uimg >/dev/null )

# 2. Sign for both slots (root offset differs: A -> PARTNROFF=2, B -> 1).
dd if=/dev/zero of="${BINARIES_DIR}/bootloader.bin" bs=512 count=1 2>/dev/null
for slot in A B; do
	[ "$slot" = A ] && off=2 || off=1
	echo "console=tty1 rootwait rw root=PARTUUID=%U/PARTNROFF=$off" > "${BINARIES_DIR}/cmdline.$slot"
	"${HOST_DIR}/bin/futility" vbutil_kernel --pack "${BINARIES_DIR}/vmlinux.kpart.$slot" \
		--version 1 --vmlinuz "${BINARIES_DIR}/vmlinux.uimg" --arch arm \
		--keyblock "$KEYS/kernel.keyblock" --signprivate "$KEYS/kernel_data_key.vbprivk" \
		--config "${BINARIES_DIR}/cmdline.$slot" --bootloader "${BINARIES_DIR}/bootloader.bin"
done

# 3. A/B disk: GPT via sgdisk, ChromeOS kernel partitions + attributes via cgpt.
ROOTFS="${BINARIES_DIR}/rootfs.ext4"
ROOT_SECTORS=$(( ($(stat -c%s "$ROOTFS") + 511) / 512 ))
TOTAL=$(( 139264 + ROOT_SECTORS + 2048 ))
rm -f "$OUT"; truncate -s $(( TOTAL * 512 )) "$OUT"
"${HOST_DIR}/sbin/sgdisk" -o "$OUT" >/dev/null
CGPT="${HOST_DIR}/bin/cgpt"
"$CGPT" add -i 1 -t kernel -b 8192  -s 65536 -l KERN-A -S 1 -T 2 -P 10 "$OUT"
"$CGPT" add -i 2 -t kernel -b 73728 -s 65536 -l KERN-B -S 0 -T 2 -P 5  "$OUT"
"$CGPT" add -i 3 -t data   -b 139264 -s "$ROOT_SECTORS" -l ROOT "$OUT"
dd if="${BINARIES_DIR}/vmlinux.kpart.A" of="$OUT" bs=512 seek=8192  conv=notrunc 2>/dev/null
dd if="${BINARIES_DIR}/vmlinux.kpart.B" of="$OUT" bs=512 seek=73728 conv=notrunc 2>/dev/null
dd if="$ROOTFS" of="$OUT" bs=512 seek=139264 conv=notrunc 2>/dev/null
echo "post-image: ${OUT} (Depthcharge A/B, devkey-signed)"
sh "${BOARD_DIR}/../common/post-image-finalize.sh" "${BINARIES_DIR}" \
	"$(basename "$(dirname "${BR2_CONFIG}")")" 2>/dev/null || true
