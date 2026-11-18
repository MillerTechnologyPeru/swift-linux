# rockchip-rk3326 patches

Imported kernel patch set for this family, applied via BR2_GLOBAL_PATCH_DIR and
stacked before each device's own patches/ dir.

Target kernel: **7.1.2** - `common.config` pins it, and the patches will not
apply to other versions. Bumping the pin means resyncing every imported piece
below together, because they are one unit: the config was generated from a
tree with these patches applied, and the device trees only compile against it.

## Provenance

Everything imported for this family comes from the same upstream tree,
https://github.com/ROCKNIX/distribution (branch `next`, last synced at
`4a9dfdb`, 2026-11-17), and is kept byte-identical to it so a resync is a
straight copy and `diff -r` is the review:

| Here | Upstream |
|---|---|
| `../patches-mainline/linux/` (3) | `projects/ROCKNIX/packages/linux/patches/mainline/` |
| `patches/linux/` (27) | `projects/ROCKNIX/devices/RK3326/patches/linux/` |
| `../patches-mainline-rockchip/linux/` (6) | `projects/ROCKNIX/packages/linux/patches/mainline-rockchip/` |
| `../patches-7.0/linux/` (1) | `projects/ROCKNIX/packages/linux/patches/7.0/` |
| `../dts/rockchip/` (22) | `projects/ROCKNIX/devices/RK3326/linux/dts/rockchip/` |
| `../linux.aarch64.conf` | `projects/ROCKNIX/devices/RK3326/linux/linux.aarch64.conf` |
| `external/package/rocknix-joypad` | `projects/ROCKNIX/packages/linux-drivers/rocknix-joypad` (same commit and hash) |

`common.config` lists the patch directories in the order upstream applies them
to RK3326 (`PKG_PATCH_DIRS` in `packages/linux/package.mk`): the mainline set,
the device set, the Rockchip rk817 charger/battery fixes, then the 7.0-series
fixes.

The device trees now include ROCKNIX's own `rk3326.dtsi`, which replaces the
kernel's copy when Buildroot lays `../dts/` over `arch/arm64/boot/dts/`. That
is how upstream carries its SoC-level changes (OPP table, gmac alias, the
Elida panel include) - the earlier import did the same thing as
`000-rk3326-dts.patch`, which upstream has since dropped, along with
`020-elida-refresh-rates.patch`, `022-usb-role-switch.patch` and
`rk3326-anbernic-rg351m.dtsi`.

`linux.fragment` fills in the two placeholders in the config that ROCKNIX's
build substitutes (`@INITRAMFS_SOURCE@`, `@DEVICENAME@`); nothing else is
overridden.

## What was left out, and why

Three of the four 7.0-series patches are skipped: `0010-msm-resource-cleanup`
is for the Qualcomm MSM display driver, `9998-silence-initramfs-unpack-warn`
quiets upstream's own initramfs (this repo builds `swift-initramfs` instead),
and `9999-fix-rust-build-error` fixes `tools/perf`, which Buildroot does not
build here. `0006` (DualSense Edge paddles) is kept: these devices have a USB
host port, so a DualSense can be plugged in.

## Verified

Against linux-7.1.2 (sha256 `37198c93...0b5883f`, the hash upstream pins): all
37 patches apply in the order above, the config merges with this repo's
fragments, and the kernel `Image`, its modules, every RK3326 board's device
tree and both rocknix-joypad modules (`rocknix-joypad.ko`,
`rocknix-singleadc-joypad.ko`) build with the arm64 cross toolchain.
Not yet booted on hardware, and the bootloader (U-Boot + rkbin) is not yet
resynced - see the board READMEs.
