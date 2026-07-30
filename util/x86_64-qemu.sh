#!/bin/sh
# Boot the Swift Linux A/B UEFI image (disk.img) in QEMU with a graphical
# console for the sway session. Run from the directory containing disk.img (Buildroot's
# output/images/), or pass the image path as $1.
#
# Environment (all optional; the defaults are the interactive behaviour):
#   QEMU_NOGRAPHIC=1    no window - but still a GL-capable virtio-gpu, since
#                       wlroots needs a render node rather than a window, and a
#                       non-GL device would stop the session from starting.
#                       Implied when neither DISPLAY nor WAYLAND_DISPLAY is set.
#   QEMU_SMP=<n>        vCPUs (default 4)
#   QEMU_MEM=<size>     RAM (default 2G)
#   QEMU_SERIAL_LOG=<f> capture the serial console to <f> and expose it on a
#                       socket (QEMU_SERIAL_SOCK, default <f>.sock) instead of
#                       this terminal, so a script can both read the boot log
#                       and drive the console. See util/boot-verify.sh.
#   QEMU_MONITOR_SOCK=<f>  QEMU monitor on a unix socket, so a script can shut
#                       the machine down cleanly instead of killing it.
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

# KVM when the host allows it; falls back to emulation otherwise.
ACCEL="-cpu qemu64"
[ -w /dev/kvm ] && ACCEL="-cpu host -enable-kvm"

# virgl (host GPU acceleration for the guest's GL) needs a QEMU built with
# virglrenderer. Not every host has one - Homebrew's QEMU, for instance, is
# built without it - and asking for virtio-gpu-gl-pci there fails with a bare
# "'virtio-gpu-gl-pci' is not a valid device model name", which does not
# explain itself. Probe for the device and fall back to a plain virtio-gpu,
# saying so: the image still boots and the serial console still works, but a
# GL compositor (sway, and therefore the frontend) will not come up.
GPU="-device virtio-gpu-gl-pci"
DISPLAY_OPTS="gtk,gl=on,show-cursor=on"
# Headless keeps the GL device on purpose: the compositor needs a render node,
# not a window, so "no display" and "no GL" are separate choices - dropping GL
# here would boot to a serial console with no session to verify.
HEADLESS=""
if [ -n "${QEMU_NOGRAPHIC:-}" ] || [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
	HEADLESS=1
	DISPLAY_OPTS="none"
fi
if ! qemu-system-x86_64 -device help 2>/dev/null | grep -q 'virtio-gpu-gl-pci'; then
	echo "warning: this qemu has no virgl (virtio-gpu-gl-pci); falling back to" >&2
	echo "         software virtio-gpu. The image boots, but the sway session" >&2
	echo "         needs GL and will not start. Install a qemu built with" >&2
	echo "         virglrenderer for the graphical frontend." >&2
	# virtio-vga, not virtio-gpu-pci: the plain virtio-gpu has no VGA
	# compatibility, so OVMF and GRUB cannot draw to it and the window
	# just reads "Display output is not active" until (and unless) the
	# guest's DRM driver takes over. virtio-vga renders from firmware
	# onward, which is what you want when you are looking at the window
	# to see what the machine is doing.
	GPU="-device virtio-vga"
	DISPLAY_OPTS="gtk,show-cursor=on"
	[ -n "$HEADLESS" ] && DISPLAY_OPTS="none"
fi

# Serial console. By default it lands on this terminal with the QEMU monitor
# multiplexed in (Ctrl-a c switches). QEMU_SERIAL_LOG moves it to a socket with
# a logfile so a script gets both the boot log and an interactive console -
# "-serial file:" would give the log alone, with nothing to type into.
SERIAL="-serial mon:stdio"
if [ -n "${QEMU_SERIAL_LOG:-}" ]; then
	SERIAL_SOCK="${QEMU_SERIAL_SOCK:-$QEMU_SERIAL_LOG.sock}"
	rm -f "$SERIAL_SOCK"
	SERIAL="-chardev socket,id=ser0,path=$SERIAL_SOCK,server=on,wait=off,logfile=$QEMU_SERIAL_LOG -serial chardev:ser0"
fi

# With the serial console off stdio the monitor needs somewhere to live, and a
# socket is what lets a caller ask for an orderly shutdown.
MONITOR=""
if [ -n "${QEMU_MONITOR_SOCK:-}" ]; then
	rm -f "$QEMU_MONITOR_SOCK"
	MONITOR="-monitor unix:$QEMU_MONITOR_SOCK,server,nowait"
fi

# -vga none is important: without it q35 adds a default VGA adapter, so the
# guest sees two DRM devices (bochs-drm alongside virtio-gpu). The compositor
# can then hand Wayland clients the bochs device, which has no render node, and
# they fail with "failed to get driver name for fd -1" instead of using virgl.
exec qemu-system-x86_64 \
	-M q35 \
	-vga none \
	$ACCEL \
	-smp "${QEMU_SMP:-4}" \
	-m "${QEMU_MEM:-2G}" \
	-drive if=pflash,format=raw,unit=0,readonly=on,file="$OVMF_CODE" \
	-drive if=pflash,format=raw,unit=1,file="$OVMF_VARS" \
	-drive file="$IMG",if=none,format=raw,id=hd0 \
	-device virtio-blk-pci,drive=hd0 \
	-netdev user,id=eth0,hostfwd=tcp:127.0.0.1:2222-:22 \
	-device virtio-net-pci,netdev=eth0 \
	$GPU \
	-device virtio-keyboard-pci \
	-device virtio-tablet-pci \
	-audiodev none,id=snd0 \
	-device virtio-sound-pci,audiodev=snd0 \
	-display "$DISPLAY_OPTS" \
	$SERIAL \
	$MONITOR
