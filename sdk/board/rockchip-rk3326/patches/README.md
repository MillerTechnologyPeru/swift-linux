# rockchip-rk3326 patches

Imported kernel and U-Boot patch sets for this family, applied via
BR2_GLOBAL_PATCH_DIR and stacked before each device's own patches/ dir.

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
| `patches/uboot/0001-*.patch` | `projects/ROCKNIX/devices/RK3326/packages/u-boot/patches/` |
| `patches/uboot/0002-add-rk3326-handheld-sources.patch` | `projects/ROCKNIX/devices/RK3326/packages/u-boot/sources/` (generated, see below) |
| `external/package/rk3326-loader` | `projects/ROCKNIX/bootloader/rkhelper` (the RK3326 branch) and `packages/tools/rkbin` (same commit) |

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

## Bootloader

Upstream boots RK3326 with mainline U-Boot **v2025.10** (`common.config` pins
it; the tarball hash matches upstream's) plus its own `rk3326-handheld`
defconfig and device tree sources. Upstream copies those sources over the
U-Boot tree; Buildroot has no such step, so
`patches/uboot/0002-add-rk3326-handheld-sources.patch` carries them as a patch
that creates the four files verbatim. Regenerate it from upstream's `sources/`
directory with `diff -ruN` against an empty tree (the patch's own header says
so).

U-Boot only provides `u-boot-dtb.bin`. `rk3326-loader` packs it the way
upstream's `rkhelper` does for this SoC, from rkbin at upstream's commit
`3e288fe` (DDR 333 MHz v2.12, miniloader v1.40, BL31 v1.37 - Buildroot's own
`rockchip-rkbin` pin no longer has the first and last of those): idbloader at
offset 0, `uboot.img` at sector 16320, `trust.img` at sector 24512. Written at
sector 64 of the card, that ends exactly at 16 MiB, where `genimage.cfg`
starts the first partition.

Differences from upstream, all because this repo builds one image per device
rather than one image per family:

- `boot/boot.cmd` hands straight to `extlinux.conf`, which names this board's
  device tree. Upstream's boot script picks a device tree by reading the
  board-ID ADC; R36S units are not in that table anyway (upstream ships an
  `extlinux.conf.r36s` the user renames).
- The card is GPT, with the partition UUIDs every image here uses (boot,
  root-a, root-b, data), and root is an EROFS slot rather than upstream's
  squashfs-in-FAT. `uboot.fragment` therefore stops U-Boot saving its
  environment at 0x4000, which on GPT is inside the partition entry array.
- Only the default (UART2) U-Boot is built, not upstream's UART5 variant for
  K36 clones, and not the legacy vendor U-Boot of upstream's "a" image.

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

U-Boot v2025.10 with `patches/uboot/` builds `rk3326-handheld` (`all` needs
`BINMAN_ALLOW_MISSING=1`, see `common.config`), and the tree it produces is
identical to upstream's sources overlay. The `rk3326-loader` steps produce a
16,744,448-byte loader, and `post-image.sh` run on it with the real kernel and
device tree yields a card whose sector 64 onwards is that loader byte for byte,
with the GPT entries ending at 17 KiB and the boot partition at 16 MiB holding
`Image`, the device tree, `boot.scr` and `extlinux/extlinux.conf`.

Not yet booted on hardware - see the board READMEs.
