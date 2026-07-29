################################################################################
#
# firmware-armbian
#
# Pinned by commit: the repository is a rolling blob collection with no
# releases. Installed wholesale into /lib/firmware; the kernel loads only
# what the board's devices request, but the image carries the full set -
# size is the price of covering every handheld radio variant with one
# package.
#
################################################################################

FIRMWARE_ARMBIAN_VERSION = 5d4dd2fc8dd4e28ac4c85696b8ab86775babc7c7
FIRMWARE_ARMBIAN_SITE = https://github.com/armbian/firmware
FIRMWARE_ARMBIAN_SITE_METHOD = git
FIRMWARE_ARMBIAN_LICENSE = PROPRIETARY (redistributable binary blobs)
FIRMWARE_ARMBIAN_REDISTRIBUTE = NO

define FIRMWARE_ARMBIAN_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/lib/firmware
	rsync -au --exclude=.git $(@D)/ $(TARGET_DIR)/lib/firmware/
endef

$(eval $(generic-package))
