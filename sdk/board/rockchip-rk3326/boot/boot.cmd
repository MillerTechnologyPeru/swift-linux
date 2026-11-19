# U-Boot boot script, compiled to boot.scr on the boot partition. The
# RK3326 U-Boot only runs boot scripts ("bootmeth order script"), so this is
# the hand-off: load the extlinux.conf next to it, which names the kernel,
# this board's device tree and the command line.
#
# The load addresses keep the kernel (~21 MiB) clear of the device tree and
# any overlays.
setenv kernel_addr_r "0x09000000"
setenv fdtoverlay_addr_r "0x08000000"
sysboot ${devtype} ${devnum}:${distro_bootpart} any 0x100000 /extlinux/extlinux.conf
