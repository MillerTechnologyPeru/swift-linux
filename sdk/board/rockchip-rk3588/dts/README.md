# Out-of-tree device trees (Rockchip RK3588/RK3588S (4x A76 + 4x A55, Mali-G610))

Drop *.dts here for devices whose DTS is not in the kernel being built;
Buildroot compiles them via BR2_LINUX_KERNEL_CUSTOM_DTS_PATH. Devices with an
in-kernel DTS just set BR2_LINUX_KERNEL_INTREE_DTS_NAME.
