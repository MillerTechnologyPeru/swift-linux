################################################################################
#
# freeimage
#
# Bitmap format library. Built from its own Makefile rather than autotools or
# CMake, so the cross compiler and flags are passed in explicitly. The bundled
# third-party sources are compiled as-is; -w keeps their warnings out of the
# build log, and the C++14 default of newer GCC needs to be relaxed for them.
#
################################################################################

FREEIMAGE_VERSION = 3.18.0
FREEIMAGE_SOURCE = FreeImage$(subst .,,$(FREEIMAGE_VERSION)).zip
FREEIMAGE_SITE = https://downloads.sourceforge.net/freeimage
FREEIMAGE_LICENSE = GPL-2.0 or FIPL-1.0
FREEIMAGE_LICENSE_FILES = license-gplv2.txt license-fi.txt
FREEIMAGE_INSTALL_STAGING = YES

# The zip unpacks to FreeImage/, not FreeImage-<version>/.
define FREEIMAGE_EXTRACT_CMDS
	$(UNZIP) -q -d $(BUILD_DIR) $(FREEIMAGE_DL_DIR)/$(FREEIMAGE_SOURCE)
	mv $(BUILD_DIR)/FreeImage/* $(@D)/
	rmdir $(BUILD_DIR)/FreeImage
endef

FREEIMAGE_MAKE_OPTS = \
	CC="$(TARGET_CC)" \
	CXX="$(TARGET_CXX)" \
	AR="$(TARGET_AR)" \
	CFLAGS="$(TARGET_CFLAGS) -w -fPIC -DPIC" \
	CXXFLAGS="$(TARGET_CXXFLAGS) -w -fPIC -DPIC -std=gnu++98 -fpermissive"

define FREEIMAGE_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) -f Makefile.gnu $(FREEIMAGE_MAKE_OPTS)
endef

define FREEIMAGE_INSTALL_STAGING_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) -f Makefile.gnu \
		$(FREEIMAGE_MAKE_OPTS) DESTDIR=$(STAGING_DIR) INCDIR=$(STAGING_DIR)/usr/include \
		INSTALLDIR=$(STAGING_DIR)/usr/lib install
endef

define FREEIMAGE_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) -f Makefile.gnu \
		$(FREEIMAGE_MAKE_OPTS) DESTDIR=$(TARGET_DIR) INCDIR=$(TARGET_DIR)/usr/include \
		INSTALLDIR=$(TARGET_DIR)/usr/lib install
endef

$(eval $(generic-package))
