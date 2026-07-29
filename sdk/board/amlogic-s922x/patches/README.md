# Amlogic S922X / G12B (4x A73 + 2x A53, Mali-G52) patches

Imported kernel patch set for this family (41 patches),
applied via BR2_GLOBAL_PATCH_DIR and stacked before each device's own
patches/ dir. Source: the upstream handheld distribution's device tree at
https://github.com/ROCKNIX/distribution/tree/main/projects/ROCKNIX/devices/S922X
(patches/linux); resync from there when bumping.

Target kernel: 6.16-rc3 snapshot (torvalds 86731a2a651e) - the family fragment pins it; the patches will not
apply to other versions.
