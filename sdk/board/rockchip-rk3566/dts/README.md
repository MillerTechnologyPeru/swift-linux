# Out-of-tree device trees (RK3566)

If a device's DTS is not in the kernel you build, drop `*.dts` here; Buildroot
compiles them via `BR2_LINUX_KERNEL_CUSTOM_DTS_PATH`. Devices whose DTS is
already in the kernel just set `BR2_LINUX_KERNEL_INTREE_DTS_NAME` and need
nothing here.
