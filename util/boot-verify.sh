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
#
# "Unable to create seed directory" used to be here and is not a regression:
# busybox installs its own S01seedrng, which runs long before S15data has
# mounted /data and so cannot write its seed on a read-only root. It fails
# that way on every boot, healthy or not, which is exactly why this tree
# ships S16seedrng to do the job once /data is there. Keeping it in this list
# made a slow boot fail with a line that had nothing to do with the problem.
#
# The /data lines below replace it, and are the real thing: they only appear
# when the data partition did not mount, which takes the RNG seed, the saved
# clock and the sshd host keys down with it.
BAD='sysv-rcs failed to start|failed to start .*ntpd|seatd does not exist|Kernel panic|Entering emergency mode'
BAD="$BAD"'|mount: mounting .* on /data failed'
BAD="$BAD""|can't create directory '/data"

wait_for() {
	pattern="$1"; label="$2"
	deadline=$(( $(date +%s) + TIMEOUT ))
	while :; do
		if [ -f "$SERIAL_LOG" ]; then
			# Known-bad first. With the success pattern tested first, a
			# check whose line was already in the log passed before the
			# bad line was ever looked at, so whether a broken boot was
			# caught came down to which of the two landed in the same
			# two-second poll - the same image passed on virtio and
			# failed on slower USB storage.
			if grep -qE "$BAD" "$SERIAL_LOG" 2>/dev/null; then
				echo "  FAIL  $label - the boot log reports:" >&2
				grep -hoE "$BAD.*" "$SERIAL_LOG" | sort -u | sed 's/^/        /' >&2
				exit 1
			fi
			grep -qE "$pattern" "$SERIAL_LOG" 2>/dev/null && { pass "$label"; return 0; }
		fi
		kill -0 "$QEMU_PID" 2>/dev/null || fail "$label - qemu exited early (see $RUN/qemu.out)"
		[ "$(date +%s)" -lt "$deadline" ] || fail "$label - timed out after ${TIMEOUT}s"
		sleep 2
	done
}

# These match a service STARTING, so the label says that and no more. The
# earlier wording - "RNG seed restored from /data" - claimed an outcome from
# the presence of "S16seedrng" in the log, and duly printed ok on an image
# where the next line was "can't create directory '/data/lib/'". Whether the
# work succeeded is now the BAD list's job, which sees those failures.
echo "boot:"
wait_for 'S15data'                'data partition service ran'
wait_for 'S16seedrng'             'RNG seed service ran'
wait_for 'S16swclock'             'clock service ran'
wait_for 'Welcome to Swift Linux' 'userspace reached a login prompt'

# ---- the session ---------------------------------------------------------
# Give the autologin chain a moment: agetty.tty1 -> autologin -> login -f
# user -> /etc/profile.d/sway.sh -> the session for whichever frontend the
# image ships (gnome-wayland-session, xfce-session or sway-session).
sleep 20

echo "session:"
# Which compositor to expect follows what the image ships, the same way the
# tty1 hook chooses one: GNOME if gnome-session is installed, XFCE if
# startxfce4 is, sway otherwise. Asserting on sway regardless would fail a
# perfectly healthy GNOME image, which is exactly what it used to do.
case "$(guest "if [ -x /usr/bin/gnome-session ]; then echo gnome; elif [ -x /usr/bin/startxfce4 ]; then echo xfce; else echo sway; fi" | tr -d '\r')" in
	*gnome*) SESSION_KIND=gnome ;;
	*xfce*)  SESSION_KIND=xfce ;;
	*)       SESSION_KIND=sway ;;
esac
echo "        frontend: $SESSION_KIND"

# ps -e, not bare ps: tools.config installs procps-ng, whose ps shows only
# the current terminal's processes by default - so the session on tty1 is
# invisible from this serial console and every check below would fail on a
# perfectly good image. (busybox ps ignores -e and lists everything anyway.)
case "$SESSION_KIND" in
gnome)
	# gnome-shell is both compositor and client, so there is no second
	# process to look for the way sway has foot.
	PS_OUT="$(guest "ps -eo user,comm | grep -E 'gnome-shell|gnome-session' | grep -v grep | sort -u")"
	echo "$PS_OUT" | grep -qE '(^|[[:space:]])user[[:space:]]+.*gnome-shell' ||
		fail "gnome-shell is not running as the session user"
	pass "gnome-shell running as the session user, unattended"

	# The shell can run while gnome-session considers the session failed -
	# it puts up "Oh no! Something has gone wrong." over a working shell -
	# so the absence of that is a separate assertion from the process being
	# alive. It was a real regression: mutter built without x11 has its
	# XSMP registration compiled out, so the shell never registered.
	guest "pgrep -f gnome-session-failed >/dev/null && echo FAILED_UP || echo NO_FAIL_DIALOG" |
		grep -q NO_FAIL_DIALOG ||
		fail "gnome-session is showing its failure screen"
	pass "no session failure screen"
	;;
xfce)
	PS_OUT="$(guest "ps -eo user,comm | grep -E 'xfwm4|xfce4-session' | grep -v grep | sort -u")"
	echo "$PS_OUT" | grep -qE '(^|[[:space:]])user[[:space:]]+.*xfwm4' ||
		fail "xfwm4 is not running as the session user"
	pass "xfwm4 running as the session user, unattended"
	;;
*)
	PS_OUT="$(guest "ps -eo user,comm | grep -E 'sway|foot' | grep -v grep | sort -u")"
	# sway owned by the session user is the real assertion: a root-owned sway
	# would mean it came from somewhere other than the tty1 autologin chain.
	echo "$PS_OUT" | grep -qE '(^|[[:space:]])user[[:space:]]+.*sway' || {
		echo "  FAIL  sway is not running as the session user" >&2
		[ -n "$PS_OUT" ] && echo "$PS_OUT" | sed 's/^/        /' >&2
		echo "serial log: $KEPT_LOG" >&2
		exit 1
	}
	pass "sway running as the session user, unattended"
	echo "$PS_OUT" | grep -q foot || fail "foot is not running - sway started no client"
	pass "foot running"

	# The minimal frontend's negations must have reached the image, which is
	# what makes sway's "emulationstation or foot" conditional choose foot.
	if guest "command -v emulationstation >/dev/null && echo ES_PRESENT || echo ES_ABSENT" | grep -q ES_ABSENT; then
		pass "frontend resolved to a terminal (no EmulationStation installed)"
	else
		echo "  note  EmulationStation is installed - this is not a minimal image" >&2
	fi
	;;
esac

# ---- graphics ------------------------------------------------------------
# Discover the Wayland socket rather than assuming a name: a compositor takes
# the next free one, so it is wayland-1 on a system whose runtime dir already
# had one. True of mutter as much as sway.
WL='for s in /tmp/xdg-1000/wayland-[0-9]*; do case "$s" in *.lock) continue;; esac; W=$(basename "$s"); break; done;'
echo "graphics:"
GL_OUT="$(guest "$WL su user -c \"XDG_RUNTIME_DIR=/tmp/xdg-1000 WAYLAND_DISPLAY=\$W eglinfo\" 2>/dev/null | grep -m1 -i 'core profile renderer'")"
echo "$GL_OUT" | grep -qi renderer || fail "no GL renderer reported - is the compositor up?"
echo "$GL_OUT" | sed 's/^/        /'
echo "$GL_OUT" | grep -qiE 'llvmpipe|softpipe' && fail "GL fell back to software rendering"
pass "GL is hardware-accelerated"

# ---- evidence -----------------------------------------------------------
echo "screenshot:"
# grim speaks wlr-screencopy, which wlroots compositors implement and mutter
# does not - it answers "compositor doesn't support the screen capture
# protocol". GNOME's own org.gnome.Shell.Screenshot is no help either: it
# refuses callers it does not recognise, with
# "GDBus.Error:org.freedesktop.DBus.Error.AccessDenied: Screenshot is not
# allowed". So on GNOME there is no way to take one from here, and the
# compositor being up is already established by the GL check above.
#
# Not a failure: a picture is corroboration, not the assertion. Everything
# this script actually verifies has passed by now. To see the desktop, boot
# with a software virtio-vga - no GL scanout - and use QEMU's own screendump,
# which is what the GL path makes impossible ("Error: no surface").
guest "$WL su user -c \"XDG_RUNTIME_DIR=/tmp/xdg-1000 WAYLAND_DISPLAY=\$W grim /tmp/bv.png\" 2>&1; ls -l /tmp/bv.png 2>&1" > "$RUN/shot.txt"
if ! grep -q '/tmp/bv.png$' "$RUN/shot.txt" && grep -qi "screen capture protocol\|not allowed" "$RUN/shot.txt"; then
	echo "        no capture protocol this compositor supports - skipping"
	echo
	echo "PASS - $IMG boots to an interactive session"
	exit 0
fi
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
