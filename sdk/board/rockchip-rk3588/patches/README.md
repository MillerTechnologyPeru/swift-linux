# Rockchip RK3588/RK3588S (4x A76 + 4x A55, Mali-G610) patches

Imported kernel patch set for this family (16 patches),
applied via BR2_GLOBAL_PATCH_DIR and stacked before each device's own
patches/ dir. Source: the upstream handheld distribution's device tree at
https://github.com/ROCKNIX/distribution/tree/main/projects/ROCKNIX/devices/RK3588
(patches/linux); resync from there when bumping.

Target kernel: 6.15.6 - the family fragment pins it; the patches will not
apply to other versions.
