# Retroid Pocket 5

Board definition for the Retroid Pocket 5 handheld. **Definition only — this
target is not built or verified in this repo.**

## Hardware

| | |
|---|---|
| SoC | Qualcomm Snapdragon 865 (SM8250) |
| CPU | 1× Cortex-A77 @ 2.84 GHz + 3× A77 + 4× A55 (tuned as `cortex-a76.a55`) |
| GPU | Adreno 650 |
| Arch | aarch64 |
| Boot | UEFI (`arm-efi`), chainloaded from the Qualcomm/Android bootloader → GRUB `bootaa64.efi` |
| Device tree | `qcom/sm8250-retroidpocket-rp5.dts` (+ `sm8250-retroidpocket-common.dtsi`) |

## What a real build needs (and why it is not built here)

Buildroot 2026.05's mainline kernel and mesa do **not** support this device
out of the box. A working image requires:

1. **A Qualcomm SM8250 kernel**, not Buildroot's default arm64 kernel. The
   SM8250 mainlining effort plus a downstream device patch set is
   needed — roughly 28 patches, including:
   - `retroid-gamepad` — the on-board gamepad input driver
   - `Chipone-ICNA35XX-panel`, `DDIC-CH13726A-panel` — the display panels
   - `pm8150b`, `qcom-spmi-haptics`, `qcom-pm8150b-charger`, `BATTERY_QCOM_FG`
   - `rp5-smooth-brightness-adjustment` — RP5-specific backlight
   - `Enable-64-bit-processes-to-use-compat-input-syscalls` — lets 32-bit
     (armv7/box86) clients read the gamepads
   - `fix-wifi-and-bt-mac`, `set-boot-fanspeed`, `gpu-opp-table`
2. **The device tree** `sm8250-retroidpocket-rp5.dts` and its common `.dtsi`,
   which live in that same downstream kernel tree.
3. **Adreno Vulkan (turnip)** if Vulkan is wanted: Buildroot 2026.05's mesa3d
   has the freedreno *gallium* (GL) driver but no freedreno *Vulkan* driver,
   so a newer/patched mesa is required. `board.config` enables freedreno GL
   only.

Wiring the kernel source/patches/DTS is out of scope for this definition,
which is why the board is provided but not built.

## Software stack (shared with the other aarch64 targets)

Same as the arm64 image: sway (basu, no systemd) + foot, seatd, dbus/BlueZ/
NetworkManager, the A/B UEFI layout, and the emulation stack — box64 for x86_64 and
box86 (from the armv7 lib32 userland) for 32-bit x86, both via `S07binfmt`.
`board.config` here only overrides the SoC/GPU/DTB/console specifics.

## Generating a defconfig (not a build)

    ./generate-config.sh --device retroid-pocket-5 --profile image -o defconfig

This produces a defconfig using this directory's `board.config` in place of an
arch fragment. It will not build to a working image without the kernel/DTS/mesa
pieces above.
