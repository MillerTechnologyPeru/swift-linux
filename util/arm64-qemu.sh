#!/bin/sh
# Boot the Swift Linux A/B UEFI image (disk.img) in QEMU with a graphical
# console for the sway session. Run from the directory containing disk.img (Buildroot's
# output/images/), or pass the image path as $1.
#
# arm64 differences from x86_64: the "virt" machine rather than q35, AAVMF (or
# QEMU_EFI) rather than OVMF, and the serial console is the PL011 UART
# (ttyAMA0), matching the kernel command line in sdk/board/arm64/grub.cfg.
#
# Environment: QEMU_NOGRAPHIC=1 (no window), QEMU_SMP, QEMU_MEM, and - for
# scripted use, see util/boot-verify.sh - QEMU_SERIAL_LOG=<f> to capture the
# serial console to <f> and expose it on a socket (QEMU_SERIAL_SOCK, default
# <f>.sock) plus QEMU_MONITOR_SOCK=<f> for an orderly shutdown.
set -e

IMG="${1:-disk.img}"

# Locate host UEFI firmware for aarch64. Debian ships the CODE/VARS pair in
# /usr/share/AAVMF; other distros use edk2-aarch64, or only a bare QEMU_EFI.fd
# with no variable store alongside it.
AAVMF_CODE=""
AAVMF_VARS_SRC=""
for d in /usr/share/AAVMF /usr/share/edk2/aarch64 /usr/share/qemu-efi-aarch64 /usr/share/qemu; do
	for c in AAVMF_CODE.fd QEMU_EFI-pflash.raw QEMU_EFI.fd; do
		[ -f "$d/$c" ] && AAVMF_CODE="$d/$c" && break
	done
	for v in AAVMF_VARS.fd QEMU_VARS.fd vars-template-pflash.raw; do
		[ -f "$d/$v" ] && AAVMF_VARS_SRC="$d/$v" && break
	done
	[ -n "$AAVMF_CODE" ] && [ -n "$AAVMF_VARS_SRC" ] && break
done

if [ -z "$AAVMF_CODE" ]; then
	echo "aarch64 UEFI firmware not found; install it (e.g. 'qemu-efi-aarch64'/'edk2-aarch64') or edit this script." >&2
	exit 1
fi

# Per-run writable copy of the UEFI variable store. Both pflash devices on the
# virt machine must be exactly 64M, so pad rather than copying as-is: Debian's
# AAVMF pair is already 64M, but a bare QEMU_EFI.fd is 2M and QEMU refuses to
# start with "device requires 67108864 bytes, block backend provides 2097152".
FW_CODE="$(mktemp /tmp/aavmf-code.XXXXXX.fd)"
FW_VARS="$(mktemp /tmp/aavmf-vars.XXXXXX.fd)"
trap 'rm -f "$FW_CODE" "$FW_VARS"' EXIT
dd if=/dev/zero of="$FW_CODE" bs=1M count=64 status=none
dd if="$AAVMF_CODE" of="$FW_CODE" conv=notrunc status=none
dd if=/dev/zero of="$FW_VARS" bs=1M count=64 status=none
[ -n "$AAVMF_VARS_SRC" ] && dd if="$AAVMF_VARS_SRC" of="$FW_VARS" conv=notrunc status=none

# KVM when the host is itself aarch64 and exposes it; emulation otherwise.
if [ -w /dev/kvm ] && [ "$(uname -m)" = "aarch64" ]; then
	ACCEL="-cpu host -enable-kvm"
else
	ACCEL="-cpu max"
fi

# virtio-gpu-gl needs host virglrenderer and a GL-capable display; fall back to
# plain virtio-gpu, and to no display at all when running headless, so the
# image still boots to the serial console.
GPU="-device virtio-gpu-gl-pci"
DISPLAY_OPT="-display gtk,gl=on,show-cursor=on"
# Headless keeps the GL device: the compositor needs a render node, not a
# window, so "no display" and "no GL" are separate choices - dropping GL here
# would boot to a serial console with no session to verify.
if ! qemu-system-aarch64 -device help 2>/dev/null | grep -q virtio-gpu-gl-pci; then
	GPU="-device virtio-gpu-pci"
	DISPLAY_OPT="-display gtk,show-cursor=on"
fi
if [ -n "${QEMU_NOGRAPHIC:-}" ] || [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
	DISPLAY_OPT="-display none"
fi

# Serial console: this terminal with the monitor multiplexed in by default;
# QEMU_SERIAL_LOG moves it to a socket with a logfile, which is what lets a
# script read the boot log and drive the console at the same time.
SERIAL="-serial mon:stdio"
if [ -n "${QEMU_SERIAL_LOG:-}" ]; then
	SERIAL_SOCK="${QEMU_SERIAL_SOCK:-$QEMU_SERIAL_LOG.sock}"
	rm -f "$SERIAL_SOCK"
	SERIAL="-chardev socket,id=ser0,path=$SERIAL_SOCK,server=on,wait=off,logfile=$QEMU_SERIAL_LOG -serial chardev:ser0"
fi
MONITOR=""
if [ -n "${QEMU_MONITOR_SOCK:-}" ]; then
	rm -f "$QEMU_MONITOR_SOCK"
	MONITOR="-monitor unix:$QEMU_MONITOR_SOCK,server,nowait"
fi

# virtio-sound-pci only exists from QEMU 8.2 on; older hosts (Debian 12 ships
# 7.2) abort with "not a valid device model name" rather than ignoring it, so
# leave the guest without a sound device there.
SND="-audiodev none,id=snd0 -device virtio-sound-pci,audiodev=snd0"
qemu-system-aarch64 -device help 2>/dev/null | grep -q virtio-sound-pci || SND=""

exec qemu-system-aarch64 \
	-M virt \
	$ACCEL \
	-smp "${QEMU_SMP:-4}" \
	-m "${QEMU_MEM:-2G}" \
	-drive if=pflash,format=raw,unit=0,readonly=on,file="$FW_CODE" \
	-drive if=pflash,format=raw,unit=1,file="$FW_VARS" \
	-drive file="$IMG",if=none,format=raw,id=hd0 \
	-device virtio-blk-pci,drive=hd0 \
	-netdev user,id=eth0,hostfwd=tcp:127.0.0.1:2222-:22 \
	-device virtio-net-pci,netdev=eth0 \
	$GPU \
	-device virtio-keyboard-pci \
	-device virtio-tablet-pci \
	$SND \
	$DISPLAY_OPT \
	$SERIAL \
	$MONITOR
