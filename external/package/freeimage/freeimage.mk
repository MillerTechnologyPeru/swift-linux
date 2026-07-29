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

# Passing CFLAGS/CXXFLAGS on the command line overrides the makefile's "+="
# appends, which would drop every -I path (breaking on "FreeImage.h: No such
# file or directory") and the bundled libraries' defines. The escaped
# $(INCLUDE) stays unexpanded here so FreeImage's own make resolves it, and
# the defines are restated explicitly.
# _byteswap_ulong is an MSVC intrinsic that LibJXR uses without providing a
# GNU fallback; map it to the GCC builtin. LibJXR also calls wcslen without
# including <wchar.h>, which modern GCC treats as an error, so the header is
# force-included everywhere.
# PNG_ARM_NEON_OPT=0: the bundled libpng enables its NEON filter paths on
# aarch64 but FreeImage's source list omits the NEON implementation files,
# leaving png_init_filter_functions_neon undefined at link time in every
# consumer. Harmless off-arm.
FREEIMAGE_DEFINES = -DOPJ_STATIC -DNO_LCMS -DDISABLE_PERF_MEASUREMENT \
	-DPNG_ARM_NEON_OPT=0 \
	-D__ANSI__ -D_byteswap_ulong=__builtin_bswap32 -include wchar.h

FREEIMAGE_MAKE_OPTS = \
	CC="$(TARGET_CC)" \
	CXX="$(TARGET_CXX)" \
	AR="$(TARGET_AR)" \
	CFLAGS="$(TARGET_CFLAGS) -w -fPIC -DPIC $(FREEIMAGE_DEFINES) \$$(INCLUDE)" \
	CXXFLAGS="$(TARGET_CXXFLAGS) -w -fPIC -DPIC -std=gnu++98 -fpermissive $(FREEIMAGE_DEFINES) \$$(INCLUDE)"

define FREEIMAGE_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) -f Makefile.gnu $(FREEIMAGE_MAKE_OPTS)
endef

# Upstream's install target chowns to root:root, which a rootless
# container build cannot do (CI runs as root and never noticed); the
# ownership flags are pointless under fakeroot/rootless either way.
define FREEIMAGE_DROP_INSTALL_OWNERSHIP
	$(SED) 's/ -o root -g root//g' $(@D)/Makefile.gnu $(@D)/Makefile.fip
endef
FREEIMAGE_POST_PATCH_HOOKS += FREEIMAGE_DROP_INSTALL_OWNERSHIP

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
