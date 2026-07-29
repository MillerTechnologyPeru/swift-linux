################################################################################
#
# rocknix-abl
#
# Prebuilt signed bootloader ELFs from the upstream release - these are
# vendor-signed images and cannot be rebuilt from source here. One ELF per
# Qualcomm SoC; the whole set is installed and the board's flashing flow
# picks its own.
#
################################################################################

ROCKNIX_ABL_VERSION = 1.1.6
ROCKNIX_ABL_SOURCE = rocknix-abl-v$(ROCKNIX_ABL_VERSION).tar.gz
ROCKNIX_ABL_SITE = https://github.com/ROCKNIX/abl/releases/download/v$(ROCKNIX_ABL_VERSION)
ROCKNIX_ABL_LICENSE = PROPRIETARY (signed bootloader images)
ROCKNIX_ABL_REDISTRIBUTE = NO

define ROCKNIX_ABL_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/share/bootloader/rocknix_abl
	cp $(@D)/abl_signed-*.elf $(TARGET_DIR)/usr/share/bootloader/rocknix_abl/
endef

$(eval $(generic-package))
