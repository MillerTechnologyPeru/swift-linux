################################################################################
#
# miyoo-daemon
#
# Single-file C daemon; upstream's own packaging tracks origin/master, so pin
# the revision explicitly and bump it deliberately. Installed as
# miyoo-daemon, not upstream's bare "daemon", to keep the name meaningful
# next to everything else in /usr/bin.
#
################################################################################

MIYOO_DAEMON_VERSION = 0dae9048c3c7fb36ae47ab141d8f509d9ef7104f
MIYOO_DAEMON_SITE = $(call github,MiyooCFW,daemon,$(MIYOO_DAEMON_VERSION))
MIYOO_DAEMON_LICENSE = GPL-2.0+
MIYOO_DAEMON_LICENSE_FILES = LICENSE

define MIYOO_DAEMON_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) \
		$(@D)/main.c -o $(@D)/miyoo-daemon
endef

define MIYOO_DAEMON_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/miyoo-daemon \
		$(TARGET_DIR)/usr/bin/miyoo-daemon
endef

$(eval $(generic-package))
