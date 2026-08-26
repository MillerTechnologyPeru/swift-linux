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

# virgl (host GPU acceleration for the guest's GL) needs a QEMU built with
# virglrenderer. Probe for the device and fall back to a plain virtio-gpu,
# saying so: the image still boots and the serial console still works, but a
# GL compositor - and therefore the frontend - will not come up.
GPU="-device virtio-gpu-gl-pci"
DISPLAY_OPTS="gtk,gl=on,show-cursor=on"
# Headless keeps the GL device on purpose: the compositor needs a render node,
# not a window, so "no display" and "no GL" are separate choices - dropping GL
# here would boot to a serial console with no session to verify.
#
# That means egl-headless rather than "none". virtio-gpu-gl needs a display
# backend with GL enabled, and "-display none" makes qemu refuse the device
# before the machine ever starts:
#
#   qemu-system-aarch64: -device virtio-gpu-gl-pci: The display backend does
#   not have OpenGL support enabled
#
# which is a launcher that cannot boot an image headless at all - every
# scripted check against an arm64 image failed there, at "qemu exited early",
# with nothing in the serial log to say why. The x86_64 launcher has had the
# egl-headless path for as long as it has had headless support; this one was
# simply never given it.
HEADLESS=""
if [ -n "${QEMU_NOGRAPHIC:-}" ] || [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
	HEADLESS=1
	if qemu-system-aarch64 -display help 2>/dev/null | grep -qw egl-headless; then
		DISPLAY_OPTS="egl-headless"
	else
		echo "warning: this qemu has no egl-headless display; running without a" >&2
		echo "         GPU, so the compositor will not start." >&2
		DISPLAY_OPTS="none"
	fi
fi
if ! qemu-system-aarch64 -device help 2>/dev/null | grep -q virtio-gpu-gl-pci; then
	echo "warning: this qemu has no virgl (virtio-gpu-gl-pci); falling back to" >&2
	echo "         software virtio-gpu. The image boots, but a GL session will" >&2
	echo "         not start. Install a qemu built with virglrenderer for the" >&2
	echo "         graphical frontend." >&2
	# virtio-gpu-pci, not virtio-vga: the virt machine has no VGA at all, and
	# arm64 UEFI draws through this device's GOP.
	GPU="-device virtio-gpu-pci"
	DISPLAY_OPTS="gtk,show-cursor=on"
	# No GL device, so no reason to ask for a GL display backend either.
	[ -n "$HEADLESS" ] && DISPLAY_OPTS="none"
fi
DISPLAY_OPT="-display $DISPLAY_OPTS"

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
	-drive file="$IMG",if=none,format=raw,id=hd0${QEMU_SNAPSHOT:+,snapshot=on} \
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
