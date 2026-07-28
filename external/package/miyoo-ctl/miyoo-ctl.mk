################################################################################
#
# miyoo-ctl
#
# Single-file C tool; upstream's own packaging tracks origin/master, so pin
# the revision explicitly and bump it deliberately. The binary keeps its
# upstream name (miyooctl) - scripts and the daemon invoke it by that name.
#
################################################################################

MIYOO_CTL_VERSION = 05fc1a79b755a95d54af75082077e12b68895f2a
MIYOO_CTL_SITE = $(call github,MiyooCFW,miyooctl,$(MIYOO_CTL_VERSION))
MIYOO_CTL_LICENSE = GPL-2.0+
MIYOO_CTL_LICENSE_FILES = LICENSE

define MIYOO_CTL_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) \
		$(@D)/main.c -o $(@D)/miyooctl
endef

define MIYOO_CTL_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/miyooctl $(TARGET_DIR)/usr/bin/miyooctl
endef

$(eval $(generic-package))
