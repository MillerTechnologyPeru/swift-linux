################################################################################
#
# libretro-fceumm
#
# Pinned by commit: the libretro cores are rolling repositories without
# release tags. Cores install under /usr/lib/libretro, where retroarch's
# libretro_directory points.
#
################################################################################

LIBRETRO_FCEUMM_VERSION = 76f68314ce4213703174108f461c431001dcc204
LIBRETRO_FCEUMM_SITE = $(call github,libretro,libretro-fceumm,$(LIBRETRO_FCEUMM_VERSION))
LIBRETRO_FCEUMM_LICENSE = GPL-2.0+
LIBRETRO_FCEUMM_LICENSE_FILES = Copying

define LIBRETRO_FCEUMM_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) -f Makefile.libretro \
		platform=unix \
		CC="$(TARGET_CC)" CXX="$(TARGET_CXX)" AR="$(TARGET_AR)"
endef

define LIBRETRO_FCEUMM_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/fceumm_libretro.so \
		$(TARGET_DIR)/usr/lib/libretro/fceumm_libretro.so
endef

$(eval $(generic-package))
