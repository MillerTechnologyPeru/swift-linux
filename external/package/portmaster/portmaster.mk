################################################################################
#
# portmaster
#
# The upstream release artifact is a zip that PortMaster unpacks and then
# manages itself (it self-updates and writes alongside the ports it
# installs), so the image ships the zip untouched and the launcher expands
# it onto the data partition on first run. Buildroot has no zip inflater,
# hence the custom extract step - which is what we want anyway: the archive
# must reach the target intact.
#
################################################################################

PORTMASTER_VERSION = 2026.07.28-1212
PORTMASTER_SITE = https://github.com/PortsMaster/PortMaster-GUI/releases/download/$(PORTMASTER_VERSION)
PORTMASTER_SOURCE = PortMaster.zip
PORTMASTER_LICENSE = MIT
PORTMASTER_DEPENDENCIES = bash python3 unzip sdl2 libcurl ca-certificates

define PORTMASTER_EXTRACT_CMDS
	cp $(PORTMASTER_DL_DIR)/$(PORTMASTER_SOURCE) $(@D)/
endef

define PORTMASTER_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/$(PORTMASTER_SOURCE) \
		$(TARGET_DIR)/usr/share/portmaster/PortMaster.zip
	$(INSTALL) -D -m 0755 $(PORTMASTER_PKGDIR)/portmaster \
		$(TARGET_DIR)/usr/bin/portmaster
endef

$(eval $(generic-package))
