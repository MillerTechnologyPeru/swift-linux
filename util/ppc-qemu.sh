#!/bin/sh
# Boot the Swift Linux ppc image (disk.img) on QEMU's mac99 machine, a G4
# Power Mac. Run from the directory containing disk.img and vmlinux
# (Buildroot's output/images/), or pass the image path as $1; the kernel is
# looked for beside it.
#
# The kernel is passed with -kernel, so OpenBIOS only hands over to it and
# never reads the disk. Root is slot A (/dev/sda2).
#
# There is no KVM for ppc on x86 or arm hosts, so this always runs under
# TCG, and mac99 takes one CPU and at most 2 GiB.
#
# Environment (all optional):
#   QEMU_NOGRAPHIC=1    no window. Implied when neither DISPLAY nor
#                       WAYLAND_DISPLAY is set. The compositor still runs:
#                       it draws with pixman into the emulated VGA, which
#                       needs no host GL.
#   QEMU_CPU=<model>    CPU model (default g4; the image needs AltiVec, so a
#                       G3 will not run it)
#   QEMU_MEM=<size>     RAM (default 2G, the machine's maximum)
#   QEMU_APPEND=<args>  extra kernel arguments
#   QEMU_SERIAL_LOG=<f> capture the serial console to <f> and expose it on a
#                       socket (QEMU_SERIAL_SOCK, default <f>.sock) instead of
#                       this terminal, as util/x86_64-qemu.sh does.
#   QEMU_MONITOR_SOCK=<f>  QEMU monitor on a unix socket.
#   QEMU_SNAPSHOT=1     keep all writes in a throwaway overlay.
set -e

IMG="${1:-disk.img}"
KERNEL="${KERNEL_IMAGE:-$(dirname "$IMG")/vmlinux}"
[ -f "$IMG" ] || { echo "no disk image at $IMG" >&2; exit 1; }
[ -f "$KERNEL" ] || { echo "no kernel at $KERNEL (set KERNEL_IMAGE)" >&2; exit 1; }

DISPLAY_OPTS="gtk"
if [ -n "${QEMU_NOGRAPHIC:-}" ] || [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
	DISPLAY_OPTS="none"
fi

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

SNAP=""
[ -n "${QEMU_SNAPSHOT:-}" ] && SNAP=",snapshot=on"

# via=pmu gives the machine the PMU (and its ADB keyboard) and the USB
# controller the tablet sits on. The disk is IDE so that the firmware, once
# it boots the image itself, sees the same device the kernel does. The
# network is the machine's own sungem.
exec qemu-system-ppc \
	-M mac99,via=pmu \
	-cpu "${QEMU_CPU:-g4}" \
	-m "${QEMU_MEM:-2G}" \
	-kernel "$KERNEL" \
	-append "root=/dev/sda2 ro rootwait console=tty0 console=ttyS0 ${QEMU_APPEND:-}" \
	-drive file="$IMG",format=raw,if=ide,index=0$SNAP \
	-netdev user,id=n0,hostfwd=tcp:127.0.0.1:2222-:22 \
	-device sungem,netdev=n0 \
	-device usb-tablet \
	-display "$DISPLAY_OPTS" \
	$SERIAL \
	$MONITOR
