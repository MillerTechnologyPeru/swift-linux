################################################################################
#
# broadcom-bt-firmware
#
################################################################################

BROADCOM_BT_FIRMWARE_VERSION = 12.0.1.1105_p4
BROADCOM_BT_FIRMWARE_SITE = $(call github,winterheart,broadcom-bt-firmware,v$(BROADCOM_BT_FIRMWARE_VERSION))
BROADCOM_BT_FIRMWARE_LICENSE = PROPRIETARY (redistributable per included EULA)
BROADCOM_BT_FIRMWARE_LICENSE_FILES = LICENSE.broadcom_bcm20702
BROADCOM_BT_FIRMWARE_REDISTRIBUTE = NO

define BROADCOM_BT_FIRMWARE_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/lib/firmware/brcm
	cp -a $(@D)/brcm/*.hcd $(TARGET_DIR)/lib/firmware/brcm/
endef

$(eval $(generic-package))
