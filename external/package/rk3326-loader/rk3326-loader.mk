################################################################################
#
# rk3326-loader
#
# Assembles the RK3326 boot image the same way upstream's rkhelper does for
# this SoC, from U-Boot's u-boot-dtb.bin and the rkbin blobs:
#
#   offset 0          idbloader.img  (DDR init + miniloader, rksd format)
#   sector 16320      uboot.img      (u-boot-dtb.bin, loaderimage-packed)
#   sector 24512      trust.img      (BL31)
#
# Written at sector 64 of the card, it ends exactly at 16 MiB, where the
# first partition starts (see the family genimage.cfg).
#
################################################################################

# The rkbin commit upstream pins for RK3326. Buildroot's rockchip-rkbin pins a
# newer one that no longer carries the BL31 v1.37 and DDR v2.12 blobs below.
RK3326_LOADER_VERSION = 3e288fe814e059dd06833495f845cab04ac20a5c
RK3326_LOADER_SITE = $(call github,rockchip-linux,rkbin,$(RK3326_LOADER_VERSION))
RK3326_LOADER_LICENSE = PROPRIETARY
RK3326_LOADER_LICENSE_FILES = LICENSE
RK3326_LOADER_REDISTRIBUTE = NO
RK3326_LOADER_DEPENDENCIES = uboot host-uboot-tools

RK3326_LOADER_INSTALL_IMAGES = YES
RK3326_LOADER_INSTALL_TARGET = NO

RK3326_LOADER_DDR = bin/rk33/rk3326_ddr_333MHz_v2.12.bin
RK3326_LOADER_MINILOADER = bin/rk33/rk3326_miniloader_v1.40.bin
RK3326_LOADER_BL31 = bin/rk33/rk3326_bl31_v1.37.elf

define RK3326_LOADER_BUILD_CMDS
	cd $(@D) && \
	$(HOST_DIR)/bin/mkimage -n px30 -T rksd -d $(RK3326_LOADER_DDR) \
		-C bzip2 idbloader.img && \
	cat $(RK3326_LOADER_MINILOADER) >> idbloader.img && \
	./tools/loaderimage --pack --uboot $(BINARIES_DIR)/u-boot-dtb.bin \
		uboot.img 0x00200000 && \
	printf '%s\n' '[BL30_OPTION]' 'SEC=0' '[BL31_OPTION]' 'SEC=1' \
		'PATH=$(RK3326_LOADER_BL31)' 'ADDR=0x00010000' \
		'[BL32_OPTION]' 'SEC=0' '[BL33_OPTION]' 'SEC=0' \
		'[OUTPUT]' 'PATH=trust.img' > trust.ini && \
	./tools/trust_merger trust.ini && \
	rm -f rk3326-uboot.bin && \
	dd if=idbloader.img of=rk3326-uboot.bin bs=512 seek=0 conv=notrunc status=none && \
	dd if=uboot.img of=rk3326-uboot.bin bs=512 seek=16320 conv=notrunc status=none && \
	dd if=trust.img of=rk3326-uboot.bin bs=512 seek=24512 conv=notrunc status=none
endef

define RK3326_LOADER_INSTALL_IMAGES_CMDS
	$(INSTALL) -D -m 0644 $(@D)/rk3326-uboot.bin $(BINARIES_DIR)/rk3326-uboot.bin
endef

$(eval $(generic-package))
