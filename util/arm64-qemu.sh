#/bin/sh
qemu-system-aarch64 \
	-M virt \
	-accel hvf \
	-drive format=raw,file=disk.img \

