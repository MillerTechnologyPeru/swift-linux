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

device=""
while [ $# -gt 0 ]; do
    case "$1" in
        --arch)     arch="$2";    shift 2 ;;
        --device)   device="$2";  shift 2 ;;
        --profile|--configuration) profile="$2"; shift 2 ;;
        --board)    board="$2";   shift 2 ;;
        --output|-o) output="$2"; shift 2 ;;
        -h|--help)  usage 0 ;;
        *) echo "Unknown argument: $1" >&2; usage 1 ;;
    esac
done

# A --device selects a device board directory (sdk/board/<device>) whose
# board.config is self-contained (it selects its own architecture), so --arch
# is neither required nor used. --device is only meaningful for the image
# profile. Without it, --arch drives an arch fragment as usual.
if [ -n "$device" ]; then
    board_dir="$SCRIPT_DIR/sdk/board/$device"
    if [ ! -f "$board_dir/board.config" ]; then
        echo "Error: unknown device '$device' (no $board_dir/board.config)" >&2
        echo "Available devices: $(cd "$SCRIPT_DIR/sdk/board" && for d in */board.config; do case "$d" in x86_64/*|arm64/*) ;; *) echo "${d%/board.config}";; esac; done | tr '\n' ' ')" >&2
        exit 1
    fi
    arch_fragment=""
else
    if [ -z "$arch" ]; then
        echo "Error: --arch (or --device) is required" >&2
        usage 1
    fi
    arch_fragment="$DEFCONFIG_DIR/arch/$arch.config"
    if [ ! -f "$arch_fragment" ]; then
        echo "Error: unknown arch '$arch' (no $arch_fragment)" >&2
        echo "Available arches: $(cd "$DEFCONFIG_DIR/arch" && ls *.config | sed 's/\.config//' | tr '\n' ' ')" >&2
        exit 1
    fi
fi

# Select fragments for the requested profile.
case "$profile" in
    sdk)
        fragments=(toolchain swift) ;;
    app-sdk|appSDK|app_sdk)
        fragments=(toolchain swift applibs) ;;
    image)
        # Full bootable A/B UEFI image (sway + non-root user). The board dir
        # is sdk/board/<device> when --device is given, else sdk/board/<arch>.
        if [ -z "$device" ]; then
            board_dir="$SCRIPT_DIR/sdk/board/$arch"
            if [ ! -f "$board_dir/board.config" ]; then
                echo "Error: the 'image' profile has no board support for '$arch'" >&2
                echo "Available arches: $(cd "$SCRIPT_DIR/sdk/board" && for d in */board.config; do case "$d" in x86_64/*|arm64/*) echo "${d%/board.config}";; esac; done | tr '\n' ' ')" >&2
                echo "Available devices (use --device): $(cd "$SCRIPT_DIR/sdk/board" && for d in */board.config; do case "$d" in x86_64/*|arm64/*|common/*) ;; *) echo "${d%/board.config}";; esac; done | tr '\n' ' ')" >&2
                exit 1
            fi
        fi
        fragments=(toolchain swift network audio daemons image steam) ;;
    lib32)
        # 32-bit companion userland, merged into a 64-bit image as /usr/lib32
        # by sdk/board/common/post-build-lib32.sh. Buildroot has no multilib
        # for Linux targets, so this is a separate build: pair i386 with an
        # x86_64 image, or armv7 with an arm64 image.
        #
        # applibs gives the 32-bit userland the full app-sdk graphics/audio
        # stack (Wayland, X11, Mesa, SDL, Cairo, ALSA, ...) so 32-bit GUI apps
        # and games can run. The armv7 companion also carries box86.
        case "$arch" in
            arm*) fragments=(toolchain lib32 applibs lib32-arm) ;;
            *)    fragments=(toolchain lib32 applibs) ;;
        esac ;;
    *)
        echo "Error: unknown profile '$profile' (expected: sdk, app-sdk, image, lib32)" >&2
        exit 1 ;;
esac

# --device is only meaningful for the image profile.
if [ -n "$device" ] && [ "$profile" != "image" ]; then
    echo "Error: --device is only valid with --profile image" >&2
    exit 1
fi

# Build the ordered list of fragment files. With --device the board.config is
# self-contained (it selects the architecture), so there is no arch fragment;
# otherwise the arch fragment comes first.
files=()
[ -n "$arch_fragment" ] && files+=("$arch_fragment")
for name in "${fragments[@]}"; do
    files+=("$DEFCONFIG_DIR/$name.config")
done

# The image profile appends the board.config (kernel defconfig, GRUB EFI
# target, serial port; for a device also the arch selection) after the
# generic image.config.
if [ "$profile" = "image" ]; then
    files+=("$board_dir/board.config")
fi

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

# Rewrite the placeholders so the generated defconfig is self-contained:
#   @BOARD@       -> sdk/board/<arch> (arch-specific board files)
#   @SWIFT_LINUX@ -> this repo (shared board files, overlays, users table)
# @BOARD@ is substituted first since it expands to a @SWIFT_LINUX@-relative
# path only conceptually; both are rewritten to absolute paths here.
sed -i "s|@BOARD@|${board_dir:-$SCRIPT_DIR/sdk/board/$arch}|g" "$output"
sed -i "s|@SWIFT_LINUX@|$SCRIPT_DIR|g" "$output"

echo "Generated $profile configuration for ${device:-$arch}${board:+ ($board)} at $output"
