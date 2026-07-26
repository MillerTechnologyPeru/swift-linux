#!/bin/sh
# Boot the Swift Linux A/B UEFI image (disk.img) in QEMU with a graphical
# console for Weston. Run from the directory containing disk.img (Buildroot's
# output/images/), or pass the image path as $1.
set -e

IMG="${1:-disk.img}"

# Locate host OVMF firmware (UEFI). Adjust if your distro stores it elsewhere.
OVMF_CODE=""
OVMF_VARS_SRC=""
for d in /usr/share/OVMF /usr/share/edk2/x64 /usr/share/qemu; do
	for c in OVMF_CODE_4M.fd OVMF_CODE.fd; do
		[ -f "$d/$c" ] && OVMF_CODE="$d/$c" && break
	done
	for v in OVMF_VARS_4M.fd OVMF_VARS.fd; do
		[ -f "$d/$v" ] && OVMF_VARS_SRC="$d/$v" && break
	done
	[ -n "$OVMF_CODE" ] && [ -n "$OVMF_VARS_SRC" ] && break
done

if [ -z "$OVMF_CODE" ] || [ -z "$OVMF_VARS_SRC" ]; then
	echo "OVMF firmware not found; install it (e.g. 'ovmf'/'edk2-ovmf') or edit this script." >&2
	exit 1
fi

# Per-run writable copy of the UEFI variable store.
OVMF_VARS="$(mktemp /tmp/ovmf-vars.XXXXXX.fd)"
cp "$OVMF_VARS_SRC" "$OVMF_VARS"
trap 'rm -f "$OVMF_VARS"' EXIT

exec qemu-system-x86_64 \
	-M q35 \
	-cpu qemu64 \
	-smp 2 \
	-m 1G \
	-drive if=pflash,format=raw,unit=0,readonly=on,file="$OVMF_CODE" \
	-drive if=pflash,format=raw,unit=1,file="$OVMF_VARS" \
	-drive file="$IMG",if=none,format=raw,id=hd0 \
	-device virtio-blk-pci,drive=hd0 \
	-netdev user,id=eth0 \
	-device virtio-net-pci,netdev=eth0 \
	-device virtio-gpu-pci \
	-device virtio-keyboard-pci \
	-device virtio-tablet-pci \
	-audiodev none,id=snd0 \
	-device virtio-sound-pci,audiodev=snd0 \
	-serial mon:stdio
