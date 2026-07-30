#!/usr/bin/env python3
"""Run a command on a QEMU guest's serial console and print its output.

    qemu-console.py <serial.sock> <command> [--user U] [--password P] [--timeout S]

The console the launchers expose with QEMU_SERIAL_LOG is a unix socket carrying
an ordinary getty session, so this logs in (only if the guest is asking), runs
one command, and reads until a sentinel it echoes itself. That is enough to
inspect a running system without needing ssh credentials or an expect
dependency; see util/boot-verify.sh.
"""

import argparse
import re
import socket
import sys
import time

ANSI = re.compile(rb"\x1b\[[0-9;?]*[A-Za-z]|\x1b\][^\x07]*\x07|\r")
# The console echoes what we type, so the sentinel is written in a form the
# shell prints whole but that does not match itself on the echoed command line:
# quoting one half keeps the echo from looking like the finished marker.
SENTINEL = "___QC_DONE___"
SENTINEL_ECHO = "___QC_'DONE'___"


def drain(sock, wait=1.0):
    """Read whatever the guest has sent, with the escape sequences stripped."""
    time.sleep(wait)
    out = b""
    while True:
        try:
            chunk = sock.recv(65536)
        except (TimeoutError, socket.timeout, BlockingIOError):
            break
        except OSError:
            break
        if not chunk:
            break
        out += chunk
        if len(out) > 8 * 1024 * 1024:
            break
    return ANSI.sub(b"", out).decode(errors="replace")


def login(sock, user, password):
    """Log in if the console is at a prompt; a live shell is left alone."""
    sock.sendall(b"\n")
    banner = drain(sock, 1.5)
    if "login:" not in banner:
        return banner
    sock.sendall(user.encode() + b"\n")
    prompt = drain(sock, 1.5)
    if "assword" in prompt:
        sock.sendall(password.encode() + b"\n")
        prompt += drain(sock, 2.0)
    return banner + prompt


def run(sock, command, timeout):
    sock.sendall(f"{command}; echo {SENTINEL_ECHO}\n".encode())
    out = ""
    deadline = time.time() + timeout
    while SENTINEL not in out and time.time() < deadline:
        out += drain(sock, 1.0)
    # Keep what the command printed: after the echoed command line, before the
    # sentinel the shell wrote.
    body = out.split(SENTINEL)[0]
    lines = [l for l in body.splitlines() if SENTINEL_ECHO not in l]
    return "\n".join(lines).strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("socket")
    ap.add_argument("command")
    ap.add_argument("--user", default="root")
    ap.add_argument("--password", default="root")
    ap.add_argument("--timeout", type=float, default=30.0)
    args = ap.parse_args()

    sock = socket.socket(socket.AF_UNIX)
    sock.settimeout(5)
    try:
        sock.connect(args.socket)
    except OSError as exc:
        print(f"cannot reach the console at {args.socket}: {exc}", file=sys.stderr)
        return 2

    login(sock, args.user, args.password)
    print(run(sock, args.command, args.timeout))
    return 0


if __name__ == "__main__":
    sys.exit(main())
