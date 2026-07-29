# Qualcomm SM6115 / Snapdragon 662 (Adreno 610) patches

Imported kernel patch set for this family (54 patches, 4 device trees in ../dts),
applied via BR2_GLOBAL_PATCH_DIR and stacked before each device's own
patches/ dir. Source: the upstream handheld distribution's device tree at
https://github.com/ROCKNIX/distribution/tree/main/projects/ROCKNIX/devices/SM6115
(patches/linux and linux/dts); resync from there when bumping.

Target kernel: 6.15.6 - the family fragment pins it; the patches will not
apply to other versions.
