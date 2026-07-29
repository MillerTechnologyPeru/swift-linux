# Rockchip RK3399 (2x A72 + 4x A53, Mali-T860) patches

Imported kernel patch set for this family (8 patches, 1 device trees in ../dts),
applied via BR2_GLOBAL_PATCH_DIR and stacked before each device's own
patches/ dir. Source: the upstream handheld distribution's device tree at
https://github.com/ROCKNIX/distribution/tree/main/projects/ROCKNIX/devices/RK3399
(patches/linux and linux/dts); resync from there when bumping.

Target kernel: 6.15.6 - the family fragment pins it; the patches will not
apply to other versions.
