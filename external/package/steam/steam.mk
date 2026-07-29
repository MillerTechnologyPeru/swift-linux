################################################################################
#
# steam
#
# Valve's Steam launcher, distributed as a Debian package. The .deb is an ar
# archive whose data.tar.xz holds /usr/bin/steam (a bash bootstrap) and
# /usr/lib/steam. The real client and the Steam Runtime are fetched at first
# launch, so only the launcher is installed here.
#
################################################################################

STEAM_VERSION = 1.0.0.85
STEAM_SOURCE = steam-launcher_$(STEAM_VERSION)_amd64.deb
STEAM_SITE = https://repo.steampowered.com/steam/archive/stable
STEAM_LICENSE = Steam License Agreement (proprietary)
# Proprietary: do not include the source in a redistributed image.
STEAM_REDISTRIBUTE = NO

# Unpack the .deb: extract the ar members, then its data tarball.
define STEAM_EXTRACT_CMDS
	cd $(@D) && ar x $(STEAM_DL_DIR)/$(STEAM_SOURCE)
	$(TAR) -C $(@D) -xf $(@D)/data.tar.xz
	rm -f $(@D)/data.tar.xz $(@D)/control.tar.* $(@D)/debian-binary
endef

define STEAM_INSTALL_TARGET_CMDS
	cp -a $(@D)/usr/bin/steam $(TARGET_DIR)/usr/bin/steam
	cp -a $(@D)/usr/lib/steam $(TARGET_DIR)/usr/lib/steam
	$(INSTALL) -D -m 0755 $(STEAM_PKGDIR)/steam-run \
		$(TARGET_DIR)/usr/bin/steam-run
	$(INSTALL) -D -m 0755 $(STEAM_PKGDIR)/steam-arm64-install \
		$(TARGET_DIR)/usr/bin/steam-arm64-install
endef

$(eval $(generic-package))
