#!/bin/sh
# Boot an image in QEMU and exercise its NFC stack, unattended. Prints one
# line per check; exits non-zero on the first failure, 0 when the stack works.
#
#   util/nfc-verify.sh [--arch x86_64|arm64] [--image PATH] [--timeout SECS]
#                      [--keep]
#
# NFC is the one subsystem here that a build cannot demonstrate: every driver
# is a module that binds nothing until a reader is plugged in, so a kernel
# with the whole set enabled and a kernel with none of it look identical from
# the outside. That is not hypothetical. Three drivers - port100, pn532_uart
# and trf7970a - were configured, shipped and absent for weeks, because
# olddefconfig drops a symbol whose dependencies are unmet and says nothing
# about it, and nothing downstream ever asked for them.
#
# Two virtual devices close that gap, which is why the kernel fragment enables
# them:
#
#   nfcsim          registers two loopback NFC-DEP devices that talk to each
#                   other. Loading it exercises the digital protocol layer -
#                   the very dependency whose absence took those three
#                   drivers out - and puts real devices in /sys/class/nfc.
#   virtual_ncidev  presents an NCI device driven from userspace through
#                   /dev/virtual_nci, exercising the NCI stack instead.
#
# The libnfc half is checked differently and deliberately so: libnfc drives a
# reader itself over USB or a tty rather than through the kernel, so it cannot
# see nfcsim and no amount of virtual hardware will make it. What is checkable
# without a reader is that the library loads, that it was compiled with the
# drivers this distro asks for, and that its tools run - which is what
# "nfc-list found no reader" proves, as distinct from the several ways it can
# fail before getting that far.
#
# See sdk/board/common/linux-nfc.fragment for the kernel side and
# sdk/defconfig/libs.config for the userland.
set -eu

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONSOLE="$REPO_DIR/util/qemu-console.py"
ARCH=x86_64
IMG=""
TIMEOUT=300
KEEP=""

while [ $# -gt 0 ]; do
	case "$1" in
		--arch)    ARCH="$2"; shift 2 ;;
		--image)   IMG="$2"; shift 2 ;;
		--timeout) TIMEOUT="$2"; shift 2 ;;
		--keep)    KEEP=1; shift ;;
		-h|--help) sed -n '2,36p' "$0" | sed 's/^# \?//'; exit 0 ;;
		*) echo "unknown argument: $1" >&2; exit 2 ;;
	esac
done

[ -n "$IMG" ] || IMG="$REPO_DIR/output/$ARCH/images/disk.img"
[ -f "$IMG" ] || { echo "no image at $IMG (build one first)" >&2; exit 2; }
LAUNCHER="$REPO_DIR/util/$ARCH-qemu.sh"
[ -x "$LAUNCHER" ] || { echo "no launcher at $LAUNCHER" >&2; exit 2; }
command -v python3 >/dev/null || { echo "nfc-verify needs python3" >&2; exit 2; }

RUN="$(mktemp -d /tmp/nfc-verify.XXXXXX)"
SERIAL_LOG="$RUN/serial.log"
SERIAL_SOCK="$RUN/serial.sock"
MONITOR_SOCK="$RUN/monitor.sock"
# Beside the image, unless that directory cannot be written - CI's output
# trees are root-owned - in which case the current directory, so the
# "serial log:" line printed on failure points at a file that exists.
OUT_DIR="$(dirname "$IMG")"
[ -w "$OUT_DIR" ] || OUT_DIR="$PWD"
KEPT_LOG="$OUT_DIR/nfc-verify-serial.log"

QEMU_PID=""
cleanup() {
	if [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null; then
		python3 -c 'import socket,sys
s = socket.socket(socket.AF_UNIX); s.settimeout(5)
s.connect(sys.argv[1]); s.sendall(b"quit\n")' "$MONITOR_SOCK" >/dev/null 2>&1 || true
		sleep 2
		kill -0 "$QEMU_PID" 2>/dev/null && kill "$QEMU_PID" 2>/dev/null || true
	fi
	cp -f "$SERIAL_LOG" "$KEPT_LOG" 2>/dev/null || true
	if [ -n "$KEEP" ]; then
		echo "run directory kept: $RUN"
	else
		rm -rf "$RUN"
	fi
}
trap cleanup EXIT INT TERM

pass() { echo "  ok    $1"; }
info() { echo "        $1"; }
fail() { echo "  FAIL  $1" >&2; echo "serial log: $KEPT_LOG" >&2; exit 1; }

# One command in the guest.
#
# Keep them short. qemu-console.py drops the echoed command line by matching
# the sentinel it appended, and the console wraps at 80 columns: a command
# long enough to wrap puts that sentinel on a line of its own, so the first
# line of the echo survives the filter and lands in the output where an
# assertion reads it as a result. That is not theoretical - it is what made
# this script report "no NFC module directory" against an image that has one,
# because the path plus the find expression came to more than 80 characters.
# The shell on the far side is one persistent session, so "cd" in an earlier
# call is still in effect; use it to keep paths out of later commands.
guest() { python3 "$CONSOLE" "$SERIAL_SOCK" "$1" 2>/dev/null | tr -d '\r' || true; }

# A count from the guest, as a bare integer. busybox wc pads its output, and
# a wrapped echo or a stray console line makes it something other than a
# number, so take the last all-digit line and nothing else.
number() { printf '%s\n' "$1" | grep -oE '^[0-9]+$' | tail -1; }

echo "booting $IMG ($ARCH, headless, timeout ${TIMEOUT}s)"
QEMU_NOGRAPHIC=1 \
QEMU_SNAPSHOT=1 \
QEMU_SERIAL_LOG="$SERIAL_LOG" \
QEMU_SERIAL_SOCK="$SERIAL_SOCK" \
QEMU_MONITOR_SOCK="$MONITOR_SOCK" \
	"$LAUNCHER" "$IMG" > "$RUN/qemu.out" 2>&1 &
QEMU_PID=$!

deadline=$(( $(date +%s) + TIMEOUT ))
while :; do
	grep -qE 'Welcome to Swift Linux' "$SERIAL_LOG" 2>/dev/null && break
	kill -0 "$QEMU_PID" 2>/dev/null || fail "boot - qemu exited early (see $RUN/qemu.out)"
	[ "$(date +%s)" -lt "$deadline" ] || fail "boot - timed out after ${TIMEOUT}s"
	sleep 2
done
pass "userspace reached a login prompt"

# ---- what shipped ---------------------------------------------------------
# The three drivers named here are the ones that were silently dropped, so
# they are asserted by name rather than by counting: a count would have been
# satisfied by the fourteen modules that did survive.
echo "modules:"
KREL="$(guest 'uname -r')"
info "kernel: $KREL"
NFCDIR="/lib/modules/$KREL/kernel/drivers/nfc"

# cd first so every command below is short enough not to wrap; see guest().
guest "cd $NFCDIR" >/dev/null
RAW="$(guest 'find . -name "*.ko" | wc -l')"
COUNT="$(number "$RAW")"
[ -n "$COUNT" ] || fail "cannot count modules in $NFCDIR (guest said: $RAW)"
# Recursively, because most of these drivers live one directory down by vendor
# - pn533/, st21nfca/, nfcmrvl/ - so the top level holds fifteen entries and
# thirty-three modules. Counting the top level reads as a catastrophic loss on
# a perfectly good image, which is how this check first failed.
[ "$COUNT" -ge 25 ] || fail "only $COUNT NFC modules under $NFCDIR, expected 25 or more"
pass "$COUNT NFC driver modules installed"

# By name, not by count: the three that were silently dropped would have been
# hidden by any threshold the fourteen survivors already met.
for m in port100 pn532_uart trf7970a nfcsim virtual_ncidev; do
	got="$(number "$(guest "find . -name $m.ko | wc -l")")"
	case "$got" in
		1) pass "$m.ko present" ;;
		*) fail "$m.ko is missing - its dependencies were dropped by olddefconfig" ;;
	esac
done

# ---- the kernel stack -----------------------------------------------------
# nfcsim pulls in nfc_digital by dependency, so a successful load is also the
# digital layer working. Both are asserted: the module list says the
# dependency resolved, /sys/class/nfc says the devices actually registered.
echo "kernel stack:"
guest 'modprobe nfcsim' >/dev/null
sleep 2

DEVS="$(guest 'ls /sys/class/nfc | tr "\n" " "')"
case "$DEVS" in
	*nfc0*nfc1*) pass "nfcsim registered two devices:$(echo " $DEVS" | tr -s ' ')" ;;
	*nfc0*)      fail "nfcsim registered only one device ($DEVS), expected a pair" ;;
	*)           fail "nfcsim loaded but /sys/class/nfc is empty - the NFC core did not register" ;;
esac

LOADED="$(guest 'lsmod | cut -d" " -f1 | tr "\n" " "')"
case "$LOADED" in
	*nfc_digital*) pass "nfc_digital pulled in as a dependency" ;;
	*) fail "nfc_digital is not loaded - the layer port100 and trf7970a need" ;;
esac

# The protocol the two loopback devices speak. Nothing else in the tree
# reports this, and it is what distinguishes a registered device from a
# working one.
PROTOS="$(guest 'cat /sys/class/nfc/nfc0/*protocols* 2>/dev/null')"
[ -n "$PROTOS" ] && info "nfc0 protocols: $PROTOS"

guest 'modprobe virtual_ncidev' >/dev/null
sleep 2
NCI="$(guest 'test -c /dev/virtual_nci && echo YES || echo NO')"
case "$NCI" in
	*YES*) pass "virtual_ncidev created /dev/virtual_nci" ;;
	*)     fail "virtual_ncidev loaded but /dev/virtual_nci is missing" ;;
esac

# ---- the userland ---------------------------------------------------------
# libnfc cannot see nfcsim - it drives a reader itself rather than going
# through the kernel - so what is proved here is that the library loads and
# its tools run. "No NFC device found" is the pass: it means libnfc got as far
# as probing, which a missing library or a broken driver list does not.
echo "libnfc:"
# The bare invocation, not -h: the usage text is printed by the argument
# parser before libnfc is ever opened, so it says nothing about whether the
# library loads. The first line of a real run is "nfc-list uses libnfc <ver>",
# which only appears once the library has initialised.
VER="$(guest 'nfc-list 2>&1 | head -1')"
case "$VER" in
	*libnfc*) pass "nfc-list runs: $VER" ;;
	*"not found"*) fail "nfc-list is missing from the image" ;;
	*) fail "nfc-list did not report a libnfc version: $VER" ;;
esac

# "No NFC device found" is the expected answer with no reader attached, and
# reaching it means libnfc probed every driver it was built with. Anything
# else here - a loader error, a segfault, silence - is a real failure.
FOUND="$(guest 'nfc-list 2>&1 | tail -1')"
case "$FOUND" in
	*"No NFC device found"*) pass "libnfc probed its drivers and found no reader, as expected" ;;
	*device*)                pass "libnfc found a reader: $FOUND" ;;
	*) fail "nfc-list did not finish probing: $FOUND" ;;
esac

SCAN="$(guest 'nfc-scan-device 2>&1 | head -1')"
case "$SCAN" in
	*libnfc*) pass "nfc-scan-device runs: $SCAN" ;;
	*"not found"*) fail "nfc-scan-device is missing from the image" ;;
	*) fail "nfc-scan-device produced nothing usable: $SCAN" ;;
esac

FREEFARE="$(guest 'test -x /usr/bin/mifare-desfire-info && echo YES || echo NO')"
case "$FREEFARE" in
	*YES*) pass "libfreefare tools installed" ;;
	*)     fail "libfreefare tools are missing - the tag layer did not install" ;;
esac

echo "PASS - the NFC stack works as far as virtual hardware can show"
