################################################################################
#
# libretro-pcsx-rearmed
#
# Pinned by commit: the libretro cores are rolling repositories without
# release tags. Cores install under /usr/lib/libretro, where retroarch's
# libretro_directory points.
#
################################################################################

LIBRETRO_PCSX_REARMED_VERSION = c88070df8e0e84106ecc4b6394860a413a7bc046
LIBRETRO_PCSX_REARMED_SITE = $(call github,libretro,pcsx_rearmed,$(LIBRETRO_PCSX_REARMED_VERSION))
LIBRETRO_PCSX_REARMED_LICENSE = GPL-2.0
LIBRETRO_PCSX_REARMED_LICENSE_FILES = COPYING
LIBRETRO_PCSX_REARMED_DEPENDENCIES = zlib

# Pick the dynarec per architecture: lightrec (vendored under deps/) on
# x86_64, the ari64 recompiler on aarch64; 32-bit ARM gets the classic
# ReARMed backend from platform detection alone.
ifeq ($(BR2_x86_64),y)
LIBRETRO_PCSX_REARMED_EXTRA_OPTS = HAVE_LIGHTREC=1 LIGHTREC_CUSTOM_MAP=0
else ifeq ($(BR2_aarch64),y)
LIBRETRO_PCSX_REARMED_EXTRA_OPTS = DYNAREC=ari64
endif

define LIBRETRO_PCSX_REARMED_BUILD_CMDS
	$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) -f Makefile.libretro \
		platform=unix $(LIBRETRO_PCSX_REARMED_EXTRA_OPTS) \
		CC="$(TARGET_CC)" CXX="$(TARGET_CXX)" AR="$(TARGET_AR)"
endef

define LIBRETRO_PCSX_REARMED_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/pcsx_rearmed_libretro.so \
		$(TARGET_DIR)/usr/lib/libretro/pcsx_rearmed_libretro.so
endef

$(eval $(generic-package))
