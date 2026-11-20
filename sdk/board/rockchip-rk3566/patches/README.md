# rockchip-rk3566 patches

Imported kernel and U-Boot patch sets for this family, applied via
BR2_GLOBAL_PATCH_DIR and stacked before each device's own patches/ dir.

Target kernel: **7.2.11** - `common.config` pins it, and the patches will not
apply to other versions. Bumping the pin means resyncing every imported piece
below together, because they are one unit: the config was generated from a
tree with these patches applied, and the device trees only compile against it.

## Provenance

Everything imported for this family comes from the same upstream tree,
https://github.com/ROCKNIX/distribution (branch `next`, last synced at
`21d9dc6`, 2026-11-20), and is kept byte-identical to it - apart from the
refreshed patches below - so a resync is a straight copy and `diff -r` is the
review:

| Here | Upstream |
|---|---|
| `../patches-mainline/linux/` (3) | `projects/ROCKNIX/packages/linux/patches/mainline/` |
| `patches/linux/` (35) | `projects/ROCKNIX/devices/RK3566/patches/linux/` |
| `../patches-mainline-rockchip/linux/` (6) | `projects/ROCKNIX/packages/linux/patches/mainline-rockchip/` |
| `../dts/rockchip/` (4) | `projects/ROCKNIX/devices/RK3566/linux/dts/rockchip/` |
| `../linux.aarch64.conf` | `projects/ROCKNIX/devices/RK3566/linux/linux.aarch64.conf` |
| `patches/uboot/2026.01/*.patch` | `projects/ROCKNIX/devices/RK3566/packages/u-boot-Specific/patches/` |
| `external/package/rk3566-loader` | `projects/ROCKNIX/bootloader/rkhelper` (the RK3566 branch) and `packages/tools/rkbin` (same commit) |

`common.config` lists the patch directories in the order upstream applies them
to RK3566 (`PKG_PATCH_DIRS` in `packages/linux/package.mk`): the mainline set,
the device set, then the Rockchip rk817 charger/battery fixes.

The `mainline` and `mainline-rockchip` sets are, at this sync, identical to
the RK3326 family's copies (`../../rockchip-rk3326/patches-mainline*`). They
are kept separately all the same: the two families pin different kernels and
are resynced independently.

### Refreshed patches

Buildroot applies patches with `patch -F0`, so every context line must match
exactly; upstream's build allows the default fuzz of 2. Eight patches only
apply against 7.2.11 with fuzz, so they are refreshed here: each was applied in
series order with fuzz, and its diff regenerated from the result, keeping
upstream's header. Only context lines and `index` lines change, and the tree
the 44 patches produce is identical either way. Every fuzzed hunk was checked
to land in the node or function it names.

- `../patches-mainline/linux/`: `0005-Bluetooth-btrtl-Add-the-support-for-RTL8733BU`
- `patches/linux/`: `0001-arm64-dts-rockchip-rk356x-add-1992mhz-cpu-opp-with-t`,
  `0002-power-supply-rk817-update-battery-and-charger-name-s`,
  `0008-arm64-dts-rockchip-add-support-for-mali-bifrost-driv`,
  `0015-arm64-dts-rockchip-use-linear-backlight-levels-to-im`,
  `0019-arm64-dts-rockchip-add-system-power-controller-attri`,
  `1001-arm64-dts-rockchip-Add-idle-states-for-rk356x`,
  `1002-arm64-dts-rockchip-Add-spk_amp-regulator-for-Anberni`

On a resync, copy upstream's files over these, and refresh again whichever
still fail `patch -F0 --dry-run` in series order.

`linux.fragment` fills in the two placeholders in the config that upstream's
build substitutes (`@INITRAMFS_SOURCE@`, `@DEVICENAME@`); nothing else is
overridden.

## Bootloader

Upstream builds two U-Boots for RK3566. The X55 gets the "Specific" one:
mainline U-Boot **v2026.01** from the `quartz64-a-rk3566` defconfig, which
runs no board code at boot - the kernel's device tree comes from
`extlinux.conf`. Its two patches (`patches/uboot/2026.01/`) keep a connected
charger from powering the device on, and try the SD card before the eMMC.
Buildroot fetches the release tarball rather than upstream's tag archive; the
two unpack to the same tree, and `uboot.hash` records both.

BL31 is TF-A at upstream's commit `a881364`, platform `rk3568` - newer than
Buildroot's v2.12 releases, and it is what implements the SCMI CPU clock the
mainline RK3566 device trees use. TF-A keeps libfdt in a git submodule now, so
it is fetched with git and submodules (`rk3566-loader.mk` turns that on).

U-Boot builds the SPL and `u-boot.itb` (U-Boot proper, BL31, its device tree).
`rk3566-loader` packs them the way upstream's `rkhelper` does for this SoC,
with rkbin at upstream's commit `3e288fe` (DDR init `rk3568_ddr_1560MHz_v1.26`;
Buildroot's own `rockchip-rkbin` pin only has v1.23): idbloader (DDR init + SPL)
at offset 0, `u-boot.itb` at sector 16320. Written at sector 64 of the card,
the itb lands at sector 16384, where the SPL looks for it
(`CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_SECTOR`), and the whole loader ends at
9.5 MB, before `genimage.cfg` starts the first partition at 16 MiB. U-Boot's
own all-in-one `u-boot-rockchip.bin` is the same layout, but binman would need
the DDR blob during the U-Boot build, so `BINMAN_ALLOW_MISSING=1` lets it skip
that image.

U-Boot keeps no environment (`CONFIG_ENV_IS_NOWHERE`), so nothing is written
into the GPT area.

Differences from upstream, all because this repo builds one image per device
rather than one image per family:

- `boot/extlinux.conf` names this board's device tree directly; upstream's
  "Specific" images do the same with a fixed FDT, its "Generic" ones use an
  FDT directory and board detection.
- The card is GPT, with the partition UUIDs every image here uses (boot,
  root-a, root-b, data), and root is an EROFS slot rather than upstream's
  squashfs-in-FAT.
- Only the X55's U-Boot is built. The family's other boards that upstream
  boots with the "Generic" U-Boot (RGxx3 board code, its own four patches) are
  not set up for it here.

## What was left out, and why

Upstream also applies a `7.2.6` patch set to RK3566. All four are skipped:
`0010-msm-resource-cleanup` and `0013-drm-msm-dpu-fix-inline-rotation` are for
the Qualcomm MSM display driver, `9998-silence-initramfs-unpack-warn` quiets
upstream's own initramfs (this repo builds `swift-initramfs` instead), and
`9999-fix-rust-build-error` fixes `tools/perf`, which Buildroot does not build
here.

Upstream has since dropped four patches the earlier import carried -
`0012-arm64-dts-rockchip-update-powkiddy-x55-dts-to-suppor`,
`0022-nvmem-rockchip-otp-Add-support-for-rk3568-otp`,
`0023-arm64-dts-rockchip-rk3568-Add-otp-device-node` and `0666-cma-region` -
so they are gone here too.

## Verified

Against linux-7.2.11 (sha256 `fd0fc479...fa1e6a4`, the hash upstream pins): all
44 patches apply in the order above with `patch -F0`, as Buildroot runs it,
the config merges with this repo's fragments, and the kernel `Image`, its 256
modules and all 67 RK356x device trees - `rk3566-powkiddy-x55.dtb` and
upstream's extra ones in `../dts/` among them - build with the arm64 cross
toolchain.

TF-A at `a881364` builds `bl31.elf` for `rk3568` (with its SCMI clock driver),
U-Boot v2026.01 with `patches/uboot/2026.01/` builds `quartz64-a-rk3566` into
`spl/u-boot-spl.bin` and a `u-boot.itb` holding U-Boot, BL31 and its device
tree, and the `rk3566-loader` steps turn those and rkbin's DDR init into a
9,507,328-byte loader whose itb sits at the sector the SPL reads
(`CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_SECTOR=0x4000`).

Not yet booted, and not yet built as a whole image.
