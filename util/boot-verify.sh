#!/bin/sh
# Boot an image in QEMU and check that it reaches an interactive graphical
# session, unattended. Prints one line per check; exits non-zero on the first
# failure, 0 when the image is good.
#
#   util/boot-verify.sh [--arch x86_64|arm64] [--image PATH] [--timeout SECS]
#                       [--screenshot PATH] [--keep]
#
# The checks follow the boot: the data partition mounting, the RNG-seed and
# clock scripts that depend on it, the tty1 autologin service bringing up a
# session with nobody touching a keyboard, that session belonging to the
# unprivileged user, the frontend resolving to a terminal rather than the game
# launcher, and GL being real instead of a silent software fallback. Each one
# has been broken here at some point; a build succeeding says nothing about
# them.
#
# Two constraints shape this:
#   - the guest needs a GL-capable virtio-gpu even with no window, because
#     wlroots wants a render node (the launchers keep it, headless or not);
#   - the screenshot must come from grim inside the guest, because with a GL
#     scanout QEMU's own screendump answers "Error: no surface".
set -eu

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONSOLE="$REPO_DIR/util/qemu-console.py"
ARCH=x86_64
IMG=""
TIMEOUT=300
SHOT=""
KEEP=""

while [ $# -gt 0 ]; do
	case "$1" in
		--arch)       ARCH="$2"; shift 2 ;;
		--image)      IMG="$2"; shift 2 ;;
		--timeout)    TIMEOUT="$2"; shift 2 ;;
		--screenshot) SHOT="$2"; shift 2 ;;
		--keep)       KEEP=1; shift ;;
		-h|--help)    sed -n '2,24p' "$0" | sed 's/^# \?//'; exit 0 ;;
		*) echo "unknown argument: $1" >&2; exit 2 ;;
	esac
done

[ -n "$IMG" ] || IMG="$REPO_DIR/output/$ARCH/images/disk.img"
[ -f "$IMG" ] || { echo "no image at $IMG (build one first)" >&2; exit 2; }
LAUNCHER="$REPO_DIR/util/$ARCH-qemu.sh"
[ -x "$LAUNCHER" ] || { echo "no launcher at $LAUNCHER" >&2; exit 2; }
command -v python3 >/dev/null || { echo "boot-verify needs python3" >&2; exit 2; }

RUN="$(mktemp -d /tmp/boot-verify.XXXXXX)"
SERIAL_LOG="$RUN/serial.log"
SERIAL_SOCK="$RUN/serial.sock"
MONITOR_SOCK="$RUN/monitor.sock"
[ -n "$SHOT" ] || SHOT="$(dirname "$IMG")/boot-verify.png"
KEPT_LOG="$(dirname "$IMG")/boot-verify-serial.log"

QEMU_PID=""
cleanup() {
	if [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null; then
		# Ask through the monitor first; fall back to a signal.
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
fail() { echo "  FAIL  $1" >&2; echo "serial log: $KEPT_LOG" >&2; exit 1; }
# Run one command in the guest (logs in over the serial console if needed).
guest() { python3 "$CONSOLE" "$SERIAL_SOCK" "$1" 2>/dev/null || true; }

echo "booting $IMG ($ARCH, headless, timeout ${TIMEOUT}s)"
QEMU_NOGRAPHIC=1 \
QEMU_SERIAL_LOG="$SERIAL_LOG" \
QEMU_SERIAL_SOCK="$SERIAL_SOCK" \
QEMU_MONITOR_SOCK="$MONITOR_SOCK" \
	"$LAUNCHER" "$IMG" > "$RUN/qemu.out" 2>&1 &
QEMU_PID=$!

# ---- the boot log ---------------------------------------------------------
# Known-bad lines: regressions this tree has actually shipped, so a broken
# boot fails in seconds instead of waiting out the timeout.
BAD='sysv-rcs failed to start|failed to start .*ntpd|Unable to create seed directory|seatd does not exist|Kernel panic|Entering emergency mode'

wait_for() {
	pattern="$1"; label="$2"
	deadline=$(( $(date +%s) + TIMEOUT ))
	while :; do
		if [ -f "$SERIAL_LOG" ]; then
			grep -qE "$pattern" "$SERIAL_LOG" 2>/dev/null && { pass "$label"; return 0; }
			if grep -qE "$BAD" "$SERIAL_LOG" 2>/dev/null; then
				echo "  FAIL  $label - the boot log reports:" >&2
				grep -hoE "$BAD.*" "$SERIAL_LOG" | sort -u | sed 's/^/        /' >&2
				exit 1
			fi
		fi
		kill -0 "$QEMU_PID" 2>/dev/null || fail "$label - qemu exited early (see $RUN/qemu.out)"
		[ "$(date +%s)" -lt "$deadline" ] || fail "$label - timed out after ${TIMEOUT}s"
		sleep 2
	done
}

echo "boot:"
wait_for 'S15data'                'data partition script ran'
wait_for 'S16seedrng'             'RNG seed restored from /data'
wait_for 'S16swclock'             'clock restored from /data'
wait_for 'Welcome to Swift Linux' 'userspace reached a login prompt'

# ---- the session ---------------------------------------------------------
# Give the autologin chain a moment: agetty.tty1 -> autologin -> login -f
# swift -> /etc/profile.d/sway.sh -> sway-session.
sleep 20

echo "session:"
# ps -e, not bare ps: tools.config installs procps-ng, whose ps shows only
# the current terminal's processes by default - so the session on tty1 is
# invisible from this serial console and every check below would fail on a
# perfectly good image. (busybox ps ignores -e and lists everything anyway.)
PS_OUT="$(guest "ps -eo user,comm | grep -E 'sway|foot' | grep -v grep | sort -u")"
# sway owned by the session user is the real assertion: a root-owned sway would
# mean it came from somewhere other than the tty1 autologin chain.
echo "$PS_OUT" | grep -qE '(^|[[:space:]])swift[[:space:]]+.*sway' || {
	echo "  FAIL  sway is not running as the session user" >&2
	[ -n "$PS_OUT" ] && echo "$PS_OUT" | sed 's/^/        /' >&2
	echo "serial log: $KEPT_LOG" >&2
	exit 1
}
pass "sway running as the session user, unattended"
echo "$PS_OUT" | grep -q foot || fail "foot is not running - sway started no client"
pass "foot running"

# The minimal frontend's negations must have reached the image, which is what
# makes sway's "emulationstation or foot" conditional choose foot.
if guest "command -v emulationstation >/dev/null && echo ES_PRESENT || echo ES_ABSENT" | grep -q ES_ABSENT; then
	pass "frontend resolved to a terminal (no EmulationStation installed)"
else
	echo "  note  EmulationStation is installed - this is not a minimal image" >&2
fi

# ---- graphics ------------------------------------------------------------
# Discover the Wayland socket rather than assuming a name: sway takes the next
# free one, so it is wayland-1 on a system whose runtime dir already had one.
WL='for s in /tmp/xdg-1000/wayland-[0-9]*; do case "$s" in *.lock) continue;; esac; W=$(basename "$s"); break; done;'
echo "graphics:"
GL_OUT="$(guest "$WL su swift -c \"XDG_RUNTIME_DIR=/tmp/xdg-1000 WAYLAND_DISPLAY=\$W eglinfo\" 2>/dev/null | grep -m1 -i 'core profile renderer'")"
echo "$GL_OUT" | grep -qi renderer || fail "no GL renderer reported - is the compositor up?"
echo "$GL_OUT" | sed 's/^/        /'
echo "$GL_OUT" | grep -qiE 'llvmpipe|softpipe' && fail "GL fell back to software rendering"
pass "GL is hardware-accelerated"

# ---- evidence -----------------------------------------------------------
echo "screenshot:"
guest "$WL su swift -c \"XDG_RUNTIME_DIR=/tmp/xdg-1000 WAYLAND_DISPLAY=\$W grim /tmp/bv.png\"; ls -l /tmp/bv.png" > "$RUN/shot.txt"
grep -q '/tmp/bv.png' "$RUN/shot.txt" || fail "grim produced no screenshot"
# Out over the serial console - the one channel needing no credentials.
guest "base64 /tmp/bv.png" > "$RUN/shot.b64"
python3 -c 'import base64,sys
raw = "".join(open(sys.argv[1]).read().split())
data = base64.b64decode(raw + "=" * (-len(raw) % 4))
if not data.startswith(b"\x89PNG"):
    sys.exit(1)
open(sys.argv[2], "wb").write(data)
print(f"        {len(data)} bytes")' "$RUN/shot.b64" "$SHOT" || fail "could not decode the screenshot"
pass "screenshot written to $SHOT"

echo
echo "PASS - $IMG boots to an interactive session"
