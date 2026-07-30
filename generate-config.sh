#!/usr/bin/env bash
#
# generate-config.sh
#
# Assemble a Buildroot defconfig for Swift Linux from the text config
# fragments in sdk/defconfig. Replaces the former `swift-linux` Swift tool.
#
# Usage:
#   ./generate-config.sh --arch <arch> [--profile <profile>] [--output <path>]
#   ./generate-config.sh --device <device> --profile image [--output <path>]
#   ./generate-config.sh --arch <arch> --profile image --frontend minimal
#
# Arches   (sdk/defconfig/arch/*.config):   armv5 armv6 armv7 arm64 x86_64 i386
# Profiles:                                  sdk (default), app-sdk, image, lib32
# Devices  (sdk/board/<device>/):            self-contained boards (see Makefile
#                                            `make list`)
# Frontends (sdk/defconfig/frontend/*):      image profile only; overrides what
#                                            the board would boot into
#
# Profiles compose the following fragments, in order:
#   sdk       = arch + toolchain + libs + tools + supportdata + swift
#   app-sdk   = arch + toolchain + libs + tools + supportdata + tools-gui
#               + swift + applibs + runtimes
#   image     = arch + toolchain + libs + tools + supportdata + tools-gui
#               + swift + applibs + runtimes + network + audio + daemons
#               + emulation + image
#               + board.config
#                                            (bootable A/B UEFI image)
#   lib32     = arch + toolchain + libs + tools + supportdata + tools-gui + swift
#               + network + audio + daemons
#               + lib32 + applibs [+ lib32-arm]  (32-bit companion userland,
#               mirroring the image's library-bearing fragments; merged into a
#               64-bit image as /usr/lib32)
# Fragments may `include` shared fragments (gpu capabilities, SoC families).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFCONFIG_DIR="$SCRIPT_DIR/sdk/defconfig"

arch=""
profile="sdk"
output="swift_linux_defconfig"

usage() {
    # Print the leading comment header (skipping the shebang), stopping at the
    # first line that is not a comment.
    awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "${BASH_SOURCE[0]}"
    exit "${1:-0}"
}

device=""
frontend=""
frontend_fragment=""
while [ $# -gt 0 ]; do
    case "$1" in
        --arch)     arch="$2";    shift 2 ;;
        --device)   device="$2";  shift 2 ;;
        --frontend) frontend="$2"; shift 2 ;;
        --profile|--configuration) profile="$2"; shift 2 ;;
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
        fragments=(toolchain libs tools supportdata swift) ;;
    app-sdk|appSDK|app_sdk)
        fragments=(toolchain libs tools supportdata tools-gui swift applibs runtimes) ;;
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
        fragments=(toolchain libs tools supportdata tools-gui swift applibs runtimes network audio daemons emulation image) ;;
    lib32)
        # 32-bit companion userland, merged into a 64-bit image as /usr/lib32
        # by sdk/board/common/post-build-lib32.sh. Buildroot has no multilib
        # for Linux targets, so this is a separate build: pair i386 with an
        # x86_64 image, or armv7 with an arm64 image.
        #
        # The companion mirrors every library-bearing fragment of the 64-bit
        # image (swift runtime, network, audio, daemons for nss-mdns, and the
        # app-sdk graphics stack via applibs), so a 32-bit process finds the
        # same libraries its 64-bit counterpart would. Only the image-assembly
        # fragments (kernel, bootloader, init, steam) are omitted - the 64-bit
        # image supplies those, and the merge script copies only lib trees.
        #
        # Graphics drivers are architecture-specific, so each companion ends
        # with its own GPU fragment: a 32-bit process cannot load the 64-bit
        # image's DRI drivers or Vulkan ICDs. The armv7 companion also
        # carries box86 (both live in lib32-arm.config).
        case "$arch" in
            arm*) fragments=(toolchain libs tools supportdata tools-gui swift network audio daemons emulation lib32 applibs lib32-arm) ;;
            *)    fragments=(toolchain libs tools supportdata tools-gui swift network audio daemons emulation lib32 applibs gpu/lib32-x86) ;;
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

# --frontend overrides the frontend the board would otherwise boot, without
# editing the board: the fragment is emitted last, and the alternatives negate
# the default's packages, so the last one wins (see frontend/README.md). Only
# the image profile has a frontend at all.
#
# "none" is not a fragment but the absence of one: it drops the frontend the
# image would otherwise include, leaving the frontend-independent part of the
# image - every library and daemon an image has whatever its user-facing shell.
# That set is what an app bundle can rely on being present on the device, so it
# is the baseline util/make-app-bundle.sh subtracts (see its buildroot mode).
if [ -n "$frontend" ]; then
    if [ "$profile" != "image" ]; then
        echo "Error: --frontend is only valid with --profile image" >&2
        exit 1
    fi
    frontend_fragment="$DEFCONFIG_DIR/frontend/$frontend.config"
    if [ "$frontend" = none ]; then
        frontend_fragment=""
    elif [ ! -f "$frontend_fragment" ]; then
        echo "Error: unknown frontend '$frontend' (no $frontend_fragment)" >&2
        echo "Available frontends: $(cd "$DEFCONFIG_DIR/frontend" && ls *.config | sed 's/\.config//' | tr '\n' ' ')none" >&2
        exit 1
    fi
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
    # After the board, so --frontend beats the board's own choice too.
    [ -n "$frontend_fragment" ] && files+=("$frontend_fragment")
fi


# emit_fragment <file> - print a fragment, expanding any `include <path>`
# directives (path relative to this repo's root) so several boards can share a
# common hardware-family fragment instead of duplicating it. Each included file
# is emitted at most once across the whole defconfig; cycles are broken by the
# same seen-set. A leading `-include` makes the include optional.
declare -A _seen_includes
emit_fragment() {
    local file="$1" line inc opt
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            "include "*|"-include "*)
                opt=0; case "$line" in "-include "*) opt=1 ;; esac
                inc="${line#*include }"
                inc="$SCRIPT_DIR/${inc#/}"
                if [ ! -f "$inc" ]; then
                    [ "$opt" = 1 ] && continue
                    echo "Error: included fragment not found: $inc (from $file)" >&2
                    exit 1
                fi
                if [ -z "${_seen_includes[$inc]:-}" ]; then
                    _seen_includes[$inc]=1
                    emit_fragment "$inc"
                fi
                ;;
            *) printf '%s\n' "$line" ;;
        esac
    done < "$file"
}

# --frontend none: the image's own frontend arrives as an `include` inside
# image.config, so it cannot be dropped by leaving a file out of the list.
# Marking every frontend fragment as already-emitted makes the include a no-op,
# reusing the seen-set that keeps a shared fragment from being emitted twice.
if [ "$frontend" = none ]; then
    for f in "$DEFCONFIG_DIR"/frontend/*.config; do
        _seen_includes["$f"]=1
    done
fi

# Concatenate fragments into the defconfig, separating each with a blank line.
: > "$output"
for f in "${files[@]}"; do
    emit_fragment "$f" >> "$output"
    printf '\n' >> "$output"
done

# Rewrite the placeholders so the generated defconfig is self-contained:
#   @BOARD@       -> sdk/board/<arch> (arch-specific board files)
#   @SWIFT_LINUX@ -> this repo (shared board files, overlays, users table)
# @BOARD@ is substituted first since it expands to a @SWIFT_LINUX@-relative
# path only conceptually; both are rewritten to absolute paths here.
# Written through a temporary file rather than with "sed -i": BSD sed (macOS)
# takes the backup suffix as -i's argument and swallows the expression.
sed -e "s|@BOARD@|${board_dir:-$SCRIPT_DIR/sdk/board/$arch}|g" \
    -e "s|@SWIFT_LINUX@|$SCRIPT_DIR|g" "$output" > "$output.tmp"
mv "$output.tmp" "$output"

# Drop the board's own post-build script from the list when it does not have
# one. Buildroot runs every entry of BR2_ROOTFS_POST_BUILD_SCRIPT and fails the
# build if one is missing, but a board only needs a script when it has work of
# its own to do - three of them do, and the rest would otherwise stop at
# target-finalize with "No such file or directory".
board_post_build="${board_dir:-$SCRIPT_DIR/sdk/board/$arch}/post-build.sh"
if [ ! -f "$board_post_build" ]; then
    sed -e "s| *${board_post_build}||" "$output" > "$output.tmp"
    mv "$output.tmp" "$output"
fi

echo "Generated $profile configuration for ${device:-$arch} at $output"
