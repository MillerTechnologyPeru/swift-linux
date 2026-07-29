################################################################################
#
# firmware-rk3588
#
################################################################################

FIRMWARE_RK3588_VERSION = dc92513ebf859d1213c999e44d4a7bf6a1fb04d7
FIRMWARE_RK3588_SITE = $(call github,stvhay,rk3588-firmware,$(FIRMWARE_RK3588_VERSION))
FIRMWARE_RK3588_LICENSE = PROPRIETARY (redistributable binary blobs)
FIRMWARE_RK3588_REDISTRIBUTE = NO

define FIRMWARE_RK3588_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/lib/firmware/rtk_bt
	cp -a $(@D)/rtl8821cs_* $(TARGET_DIR)/lib/firmware/rtk_bt/
endef

$(eval $(generic-package))
