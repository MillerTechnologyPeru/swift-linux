#!/usr/bin/env bash
#
# generate-config.sh
#
# Assemble a Buildroot defconfig for Swift Linux from the text config
# fragments in sdk/defconfig. Replaces the former `swift-linux` Swift tool.
#
# Usage:
#   ./generate-config.sh --arch <arch> [--profile <profile>] [--board <board>] [--output <path>]
#
# Arches   (sdk/defconfig/arch/*.config):   armv5 armv6 armv7 arm64 x86_64
# Profiles:                                  sdk (default), app-sdk
# Boards   (sdk/defconfig/board/*.config):   optional overlay, e.g. rpi4, uefi-x86_64
#
# Profiles compose the following fragments, in order:
#   sdk       = arch + toolchain + swift
#   app-sdk   = arch + toolchain + swift + applibs
# A --board overlay, when given, is appended last.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFCONFIG_DIR="$SCRIPT_DIR/sdk/defconfig"

arch=""
profile="sdk"
board=""
output="swift_linux_defconfig"

usage() {
    # Print the leading comment header (skipping the shebang), stopping at the
    # first line that is not a comment.
    awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "${BASH_SOURCE[0]}"
    exit "${1:-0}"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --arch)     arch="$2";    shift 2 ;;
        --profile|--configuration) profile="$2"; shift 2 ;;
        --board)    board="$2";   shift 2 ;;
        --output|-o) output="$2"; shift 2 ;;
        -h|--help)  usage 0 ;;
        *) echo "Unknown argument: $1" >&2; usage 1 ;;
    esac
done

if [ -z "$arch" ]; then
    echo "Error: --arch is required" >&2
    usage 1
fi

arch_fragment="$DEFCONFIG_DIR/arch/$arch.config"
if [ ! -f "$arch_fragment" ]; then
    echo "Error: unknown arch '$arch' (no $arch_fragment)" >&2
    echo "Available arches: $(cd "$DEFCONFIG_DIR/arch" && ls *.config | sed 's/\.config//' | tr '\n' ' ')" >&2
    exit 1
fi

# Select fragments for the requested profile.
case "$profile" in
    sdk)
        fragments=(toolchain swift) ;;
    app-sdk|appSDK|app_sdk)
        fragments=(toolchain swift applibs) ;;
    image)
        # Full bootable A/B UEFI image (Weston + non-root user). x86_64 only:
        # image.config references board files under sdk/board/x86_64.
        if [ "$arch" != "x86_64" ]; then
            echo "Error: the 'image' profile currently targets x86_64 only (got '$arch')" >&2
            exit 1
        fi
        fragments=(toolchain swift network image steam) ;;
    lib32)
        # 32-bit companion userland (libraries only), merged into a 64-bit
        # image as /usr/lib32 by sdk/board/common/post-build-lib32.sh.
        # Buildroot has no multilib for Linux targets, so this is a separate
        # build: pair i386 with an x86_64 image.
        fragments=(toolchain lib32) ;;
    *)
        echo "Error: unknown profile '$profile' (expected: sdk, app-sdk, image, lib32)" >&2
        exit 1 ;;
esac

# Build the ordered list of fragment files: arch first, then profile fragments.
files=("$arch_fragment")
for name in "${fragments[@]}"; do
    files+=("$DEFCONFIG_DIR/$name.config")
done

# Optional board overlay, appended last.
if [ -n "$board" ]; then
    board_fragment="$DEFCONFIG_DIR/board/$board.config"
    if [ ! -f "$board_fragment" ]; then
        echo "Error: unknown board '$board' (no $board_fragment)" >&2
        echo "Available boards: $(cd "$DEFCONFIG_DIR/board" && ls *.config | sed 's/\.config//' | tr '\n' ' ')" >&2
        exit 1
    fi
    files+=("$board_fragment")
fi

# Concatenate fragments into the defconfig, separating each with a blank line.
: > "$output"
for f in "${files[@]}"; do
    cat "$f" >> "$output"
    printf '\n' >> "$output"
done

# Rewrite the @SWIFT_LINUX@ placeholder (used by image.config to point at
# board overlays, users tables and post-build/-image scripts) to this repo's
# absolute path, so the generated defconfig is self-contained.
sed -i "s|@SWIFT_LINUX@|$SCRIPT_DIR|g" "$output"

echo "Generated $profile configuration for $arch${board:+ ($board)} at $output"
