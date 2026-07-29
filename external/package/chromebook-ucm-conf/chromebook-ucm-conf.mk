################################################################################
#
# chromebook-ucm-conf
#
# Pinned by commit (the standalone branch carries no tags). Data only,
# rsynced over the stock UCM tree - the stock set must install first.
#
################################################################################

CHROMEBOOK_UCM_CONF_VERSION = 1ace2f5bfc436fdf102ce62a1eccd1faef2aaaac
CHROMEBOOK_UCM_CONF_SITE = $(call github,WeirdTreeThing,alsa-ucm-conf-cros,$(CHROMEBOOK_UCM_CONF_VERSION))
CHROMEBOOK_UCM_CONF_LICENSE = BSD-3-Clause
CHROMEBOOK_UCM_CONF_LICENSE_FILES = LICENSE
CHROMEBOOK_UCM_CONF_DEPENDENCIES = alsa-ucm-conf

define CHROMEBOOK_UCM_CONF_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/share/alsa/ucm2
	rsync -a $(@D)/ucm2/ $(TARGET_DIR)/usr/share/alsa/ucm2/
endef

$(eval $(generic-package))
