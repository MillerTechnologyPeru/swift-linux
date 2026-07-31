# Retroid Pocket 5

Board definition for the Retroid Pocket 5 handheld. **Not yet built on
hardware** — the kernel side is wired up (see below), but no SM8250 device has
been booted from this repo.

## Hardware

| | |
|---|---|
| SoC | Qualcomm Snapdragon 865 (SM8250) |
| CPU | 1× Cortex-A77 @ 2.84 GHz + 3× A77 + 4× A55 (tuned as `cortex-a76.a55`) |
| GPU | Adreno 650 |
| Arch | aarch64 |
| Boot | UEFI (`arm-efi`), chainloaded from the Qualcomm/Android bootloader → GRUB `bootaa64.efi` |
| Device tree | `qcom/sm8250-retroidpocket-rp5.dts` (+ `sm8250-retroidpocket-common.dtsi`) |
| Panel | Chipone ICNA35XX / DDIC CH13726A (out-of-tree, in the patch set) |
| Radio | Soldered QCA — ath11k wifi + qca Bluetooth, firmware via `firmware-extra` |

## What the family carries

Buildroot's mainline arm64 kernel does not support this device, so
`sdk/board/qualcomm-sm8250/` supplies the whole kernel side and this board's
`board.config` adds only the device tree name:

- **Kernel 7.1.2**, pinned — the version the config and patches were made for.
- **`linux.aarch64.conf`** — the SM8250 kernel config, imported whole and used
  as `BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE`. It already carries what the image
  profile needs (EFI stub and GPT for the A/B GRUB boot, `CONFIG_COMPAT` so
  32-bit box86 clients can read the gamepads, `binfmt_misc`, squashfs for app
  bundles, cgroups/namespaces/overlayfs for podman); EROFS, f2fs and the
  removable-media filesystems are added on top by the `LINUX_CONFIG_FIXUPS` of
  `image-storage`, `swift-initramfs` and `media-automount`.
- **29 kernel patches** — the gamepad driver, both display panels, PM8150B
  regulators/charger, SPMI haptics, force feedback, RP5 backlight ramping,
  wifi/BT MAC fixup, boot fan speed, GPU OPP table, 32-bit input syscalls for
  box86, and DPU display fixes for the 7.x MSM DRM driver.
- **7 device trees** — this device's, its siblings', and the shared Retroid
  `.dtsi`.
- **udev rules** — gamepad node permissions and `ID_INPUT_JOYSTICK` tagging,
  haptics `uaccess`, and a WCD938x runtime-PM fix for headphone-jack detection.

Provenance and resync instructions:
[`../qualcomm-sm8250/patches/README.md`](../qualcomm-sm8250/patches/README.md).

## What bring-up still needs

1. **A build.** Nothing here has been compiled: the pinned kernel has never
   been fetched and patched in CI, so the patch set is unverified against
   7.1.2 as Buildroot unpacks it.
2. **Adreno Vulkan (turnip).** Buildroot 2026.05's mesa3d has the freedreno
   *gallium* (GL) driver but no freedreno *Vulkan* driver, so Vulkan needs a
   newer or patched mesa. `common.config` includes the freedreno capability
   fragment; only the GL half is real today.
3. **Flashing.** `rocknix-abl` builds the signed abl payloads, but the
   fastboot-side install flow for this device is not scripted here.
4. **Hardware verification** — display, audio routing, gamepad, charging,
   suspend/resume, wifi and Bluetooth all unconfirmed.

## Software stack (shared with the other aarch64 targets)

Same as the arm64 image: sway (basu, no systemd) + EmulationStation, seatd,
dbus/BlueZ/NetworkManager, the A/B UEFI layout, and the emulation stack — box64
for x86_64 and box86 (from the armv7 lib32 userland) for 32-bit x86, both via
`S07binfmt`. `board.config` here only names the device tree; `common.config`
overrides the SoC/GPU/console specifics.

## Generating a defconfig

    ./generate-config.sh --device retroid-pocket-5 --profile image -o defconfig

This produces a defconfig using this directory's `board.config` in place of an
arch fragment.
