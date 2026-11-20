################################################################################
#
# rk3566-loader
#
# Assembles the RK3566 boot image the same way upstream's rkhelper does for
# this SoC, from U-Boot's SPL and u-boot.itb and rkbin's DDR init:
#
#   offset 0          idbloader.img  (DDR init as TPL + U-Boot SPL, rksd
#                                     format; the boot ROM loads it)
#   sector 16320      u-boot.itb     (U-Boot proper + BL31 + device tree,
#                                     which the SPL loads from sector 16384
#                                     of the card)
#
# Written at sector 64 of the card, the itb lands at sector 16384 (8 MiB),
# where mainline U-Boot's Rockchip SPL looks for it; the whole file ends well
# before 16 MiB, where the first partition starts (see the family
# genimage.cfg).
#
# U-Boot's own all-in-one u-boot-rockchip.bin is the same layout, but binman
# needs the DDR blob while U-Boot builds, before this package can provide
# it - so the SPL and itb come out of U-Boot, and the packing happens here.
#
################################################################################

# The rkbin commit upstream pins for every Rockchip SoC except RK3588 (the
# same one rk3326-loader uses). Buildroot's rockchip-rkbin pins an older one
# whose RK3566 DDR init is v1.23, not upstream's v1.26.
RK3566_LOADER_VERSION = 3e288fe814e059dd06833495f845cab04ac20a5c
RK3566_LOADER_SITE = $(call github,rockchip-linux,rkbin,$(RK3566_LOADER_VERSION))
RK3566_LOADER_LICENSE = PROPRIETARY
RK3566_LOADER_LICENSE_FILES = LICENSE
RK3566_LOADER_REDISTRIBUTE = NO
RK3566_LOADER_DEPENDENCIES = uboot host-uboot-tools

RK3566_LOADER_INSTALL_IMAGES = YES
RK3566_LOADER_INSTALL_TARGET = NO

# The RK3568 DDR init: the RK3566 is the same die, and upstream uses this blob
# for every RK3566 device.
RK3566_LOADER_DDR = bin/rk35/rk3568_ddr_1560MHz_v1.26.bin

# mkimage takes the SoC as rk3568 for the RK3566 too, as upstream's rkhelper
# rewrites it.
define RK3566_LOADER_BUILD_CMDS
	cd $(@D) && \
	$(HOST_DIR)/bin/mkimage -n rk3568 -T rksd \
		-d $(RK3566_LOADER_DDR):$(BINARIES_DIR)/u-boot-spl.bin \
		-C bzip2 idbloader.img && \
	rm -f rk3566-uboot.bin && \
	dd if=idbloader.img of=rk3566-uboot.bin bs=512 seek=0 conv=notrunc status=none && \
	dd if=$(BINARIES_DIR)/u-boot.itb of=rk3566-uboot.bin bs=512 seek=16320 conv=notrunc status=none
endef

# The BL31 in u-boot.itb comes from TF-A at upstream's commit (see the family
# common.config), which keeps libfdt in a git submodule (contrib/dtc):
#
#   lib/libfdt/libfdt.mk:11: contrib/dtc/libfdt/Makefile.libfdt: No such file
#
# Buildroot's arm-trusted-firmware package has no option to fetch
# submodules; its download reads this variable when it runs, so setting it
# here is enough.
ifeq ($(BR2_PACKAGE_RK3566_LOADER)$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_GIT),yy)
ARM_TRUSTED_FIRMWARE_GIT_SUBMODULES = YES
endif

define RK3566_LOADER_INSTALL_IMAGES_CMDS
	$(INSTALL) -D -m 0644 $(@D)/rk3566-uboot.bin $(BINARIES_DIR)/rk3566-uboot.bin
endef

$(eval $(generic-package))
