# qualcomm-sm8250 patches

Imported kernel patch set for this family (28 patches), applied via
BR2_GLOBAL_PATCH_DIR and stacked before each device's own patches/ dir.

Target kernel: **7.1.2** - `common.config` pins it, and the patches will not
apply to other versions. Bumping the pin means resyncing all three imported
pieces together, because they are one unit: the config was generated from a
tree with these patches applied, and the device trees only compile against it.

## Provenance

Everything imported for this family comes from the same upstream tree,
https://github.com/ROCKNIX/distribution, and is kept byte-identical to it so a
resync is a straight copy and `diff -r` is the review:

| Here | Upstream |
|---|---|
| `patches/linux/` (28) | `projects/ROCKNIX/devices/SM8250/patches/linux/` |
| `patches-7.0/linux/` (1) | `projects/ROCKNIX/packages/linux/patches/7.0/` |
| `../dts/qcom/` (7) | `projects/ROCKNIX/devices/SM8250/linux/dts/qcom/` |
| `../linux.aarch64.conf` | `projects/ROCKNIX/devices/SM8250/linux/linux.aarch64.conf` |
| `../rootfs-overlay/etc/udev/rules.d/` (3) | `projects/ROCKNIX/devices/SM8250/filesystem/usr/lib/udev/rules.d/` |

`common.config` lists the two patch directories in the order upstream applies
them: the device set, then the 7.0-series fixes.

## What was left out, and why

Upstream also applies its `packages/linux/patches/mainline` set to this device.
Those five patches are not imported: three of them exist only to support the
out-of-tree `rocknix-joypad` driver, which this family does not use
(`ROCKNIX_JOYPAD="no"` upstream, and the driver is not packaged here at all),
and the other two add an RTL8733BU Bluetooth ID and DualSense Edge paddle
reporting - neither reachable on a soldered-QCA-radio SM8250 handheld. Nothing
in `linux.aarch64.conf` depends on them; `CONFIG_INPUT_POLLDEV` is explicitly
off there.

Two of the three 7.0-series patches are likewise skipped: one silences a
warning from upstream's own initramfs (this repo builds `swift-initramfs`
instead) and one fixes a Rust build error in `tools/perf`, which Buildroot does
not build here. Only `0010-msm-resource-cleanup.patch` is kept - it is a set of
DPU display fixes for the 7.x MSM DRM driver, which is exactly what drives the
panel on these devices.
