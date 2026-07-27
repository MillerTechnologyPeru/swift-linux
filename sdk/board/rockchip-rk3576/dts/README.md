# Out-of-tree device trees (Rockchip RK3576 (A72 + A53, Mali-G52))

Drop *.dts here for devices whose DTS is not in the kernel being built;
Buildroot compiles them via BR2_LINUX_KERNEL_CUSTOM_DTS_PATH. Devices with an
in-kernel DTS just set BR2_LINUX_KERNEL_INTREE_DTS_NAME.
