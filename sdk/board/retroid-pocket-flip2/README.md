# Retroid Pocket Flip 2

Board definition for the Retroid Pocket Flip 2 handheld. **Definition only —
this target is not built or verified in this repo.**

The Flip 2 uses the same SoC as the Retroid Pocket 5 (Qualcomm Snapdragon 865
/ SM8250), so everything in [`../retroid-pocket-5/README.md`](../retroid-pocket-5/README.md)
applies. The only board difference here is the device tree.

## Hardware

| | |
|---|---|
| SoC | Qualcomm Snapdragon 865 (SM8250) |
| CPU | Cortex-A77 + A55 (tuned as `cortex-a76.a55`) |
| GPU | Adreno 650 |
| Arch | aarch64 |
| Form factor | clamshell / flip |
| Boot | UEFI (`arm-efi`) → GRUB `bootaa64.efi` |
| Device tree | `qcom/sm8250-retroidpocket-flip2.dts` (+ `sm8250-retroidpocket-common.dtsi`) |

## What a real build needs

Identical to the Retroid Pocket 5: a Qualcomm SM8250 kernel with the SM8250
patch set (retroid-gamepad, ICNA35XX/CH13726A panels, pm8150b, charger,
haptics, compat input syscalls, …), the `sm8250-retroidpocket-flip2.dts`
device tree, and — for Vulkan — a mesa with the freedreno (turnip) Vulkan
driver, which Buildroot 2026.05 does not package. See the Retroid Pocket 5
README for the full list and rationale.

## Generating a defconfig (not a build)

    ./generate-config.sh --device retroid-pocket-flip2 --profile image -o defconfig
