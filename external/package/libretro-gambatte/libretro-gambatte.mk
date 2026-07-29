################################################################################
#
# libretro-gambatte
#
# Pinned by commit: the libretro cores are rolling repositories without
# release tags. Cores install under /usr/lib/libretro, where retroarch's
# libretro_directory points.
#
################################################################################

LIBRETRO_GAMBATTE_VERSION = 4041d5a6c474d2d01b4cb1e81324b06b51d0147b
LIBRETRO_GAMBATTE_SITE = $(call github,libretro,gambatte-libretro,$(LIBRETRO_GAMBATTE_VERSION))
LIBRETRO_GAMBATTE_LICENSE = GPL-2.0
LIBRETRO_GAMBATTE_LICENSE_FILES = COPYING

define LIBRETRO_GAMBATTE_BUILD_CMDS
	$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) -f Makefile platform=unix \
		CC="$(TARGET_CC)" CXX="$(TARGET_CXX)" AR="$(TARGET_AR)"
endef

define LIBRETRO_GAMBATTE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/gambatte_libretro.so \
		$(TARGET_DIR)/usr/lib/libretro/gambatte_libretro.so
endef

$(eval $(generic-package))
