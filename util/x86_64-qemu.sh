#!/bin/sh
qemu-system-x86_64 \
	-M q35 \
	-cpu qemu64 \
	-smp 2 \
	-m 512M \
	-kernel bzImage \
	-append "rootwait root=/dev/vda console=ttyS0" \
	-netdev user,id=eth0 \
	-device virtio-net-pci,netdev=eth0 \
	-drive file=rootfs.ext2,if=none,format=raw,id=hd0 \
	-device virtio-blk-pci,drive=hd0 \
	-device VGA,vgamem_mb=32 \
	-serial mon:stdio
