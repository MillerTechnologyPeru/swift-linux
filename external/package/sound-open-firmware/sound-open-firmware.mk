################################################################################
#
# sound-open-firmware
#
################################################################################

SOUND_OPEN_FIRMWARE_VERSION = 2025.12.2
SOUND_OPEN_FIRMWARE_SOURCE = sof-bin-$(SOUND_OPEN_FIRMWARE_VERSION).tar.gz
SOUND_OPEN_FIRMWARE_SITE = https://github.com/thesofproject/sof-bin/releases/download/v$(SOUND_OPEN_FIRMWARE_VERSION)
SOUND_OPEN_FIRMWARE_LICENSE = BSD-3-Clause (firmware), MIT (tools)
SOUND_OPEN_FIRMWARE_LICENSE_FILES = LICENCE.SOF
SOUND_OPEN_FIRMWARE_REDISTRIBUTE = YES

define SOUND_OPEN_FIRMWARE_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/lib/firmware
	rsync -a $(@D)/sof $(@D)/sof-tplg $(TARGET_DIR)/lib/firmware/
endef

$(eval $(generic-package))
