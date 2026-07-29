################################################################################
#
# heroic
#
# Upstream's prebuilt Linux x64 tarball (an Electron application; see
# Config.in for why it is not built from source). Installed whole under
# /usr/lib/heroic with a launcher symlink, the way distro packages of
# Electron apps are laid out.
#
################################################################################

HEROIC_VERSION = 2.22.0
HEROIC_SITE = https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v$(HEROIC_VERSION)
HEROIC_SOURCE = Heroic-$(HEROIC_VERSION)-linux-x64.tar.xz
HEROIC_LICENSE = GPL-3.0 (application), various (bundled Electron/Chromium)

define HEROIC_EXTRACT_CMDS
	mkdir -p $(@D)/dist
	$(XZCAT) $(HEROIC_DL_DIR)/$(HEROIC_SOURCE) | \
		$(TAR) --strip-components=1 -C $(@D)/dist -xf -
endef

define HEROIC_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/lib/heroic
	cp -a $(@D)/dist/. $(TARGET_DIR)/usr/lib/heroic/
	ln -sf ../lib/heroic/heroic $(TARGET_DIR)/usr/bin/heroic
	$(INSTALL) -D -m 0644 $(HEROIC_PKGDIR)/heroic.desktop \
		$(TARGET_DIR)/usr/share/applications/heroic.desktop
endef

$(eval $(generic-package))
