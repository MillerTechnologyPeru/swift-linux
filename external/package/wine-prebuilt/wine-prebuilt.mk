################################################################################
#
# wine-prebuilt
#
# Upstream's WoW64 build: 64-bit Wine that runs 32-bit Windows programs
# through Windows-side WoW64 rather than 32-bit Unix libraries - which is
# what lets the identical tarball serve x86_64 (native) and aarch64
# (through box64). Installed whole under /usr/wine/prebuilt, the same
# self-contained layout the reference distributions use for their Wine
# variants.
#
################################################################################

WINE_PREBUILT_VERSION = 11.0
WINE_PREBUILT_SITE = https://github.com/Kron4ek/Wine-Builds/releases/download/$(WINE_PREBUILT_VERSION)
WINE_PREBUILT_SOURCE = wine-$(WINE_PREBUILT_VERSION)-amd64-wow64.tar.xz
WINE_PREBUILT_LICENSE = LGPL-2.1+ (prebuilt upstream release)

define WINE_PREBUILT_EXTRACT_CMDS
	mkdir -p $(@D)/dist
	$(XZCAT) $(WINE_PREBUILT_DL_DIR)/$(WINE_PREBUILT_SOURCE) | \
		$(TAR) --strip-components=1 -C $(@D)/dist -xf -
endef

define WINE_PREBUILT_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/wine/prebuilt
	cp -a $(@D)/dist/. $(TARGET_DIR)/usr/wine/prebuilt/
endef

$(eval $(generic-package))
