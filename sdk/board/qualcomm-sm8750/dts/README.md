# Out-of-tree device trees (Qualcomm SM8750 / Snapdragon 8 Elite (Adreno 830))

Nothing here yet. Drop a device tree in `qcom/` for any device whose DTS is
not in the kernel being built; Buildroot copies this directory over
`arch/arm64/boot/dts/` via `BR2_LINUX_KERNEL_CUSTOM_DTS_DIR` and compiles every
`.dts` it finds.

They must sit in the `qcom/` vendor subdirectory, not at the top level: since
6.12 the kernel's device tree makefiles build DTBs under their vendor path, so a
board names its device tree as `qcom/<name>` in
`BR2_LINUX_KERNEL_INTREE_DTS_NAME`.

Devices whose DTS *is* in the kernel just set that variable and add nothing here.
