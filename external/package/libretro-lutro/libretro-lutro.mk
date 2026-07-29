################################################################################
#
# libretro-lutro
#
# Pinned by commit: the libretro cores are rolling repositories without
# release tags. Cores install under /usr/lib/libretro, where retroarch's
# libretro_directory points.
#
################################################################################

LIBRETRO_LUTRO_VERSION = 09a134eccad87127ec757503f736d6e4f9d06d4c
LIBRETRO_LUTRO_SITE = $(call github,libretro,libretro-lutro,$(LIBRETRO_LUTRO_VERSION))
LIBRETRO_LUTRO_LICENSE = MIT
LIBRETRO_LUTRO_LICENSE_FILES = LICENSE

# No AR override: the vendored lua's Makefile defines AR as "ar rcu"
# (command plus flags), so replacing it with a bare gcc-ar breaks the
# liblua.a archive step. Static archives are portable, host ar is fine.
define LIBRETRO_LUTRO_BUILD_CMDS
	$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) -f Makefile platform=unix \
		CC="$(TARGET_CC)" CXX="$(TARGET_CXX)"
endef

define LIBRETRO_LUTRO_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/lutro_libretro.so \
		$(TARGET_DIR)/usr/lib/libretro/lutro_libretro.so
endef

$(eval $(generic-package))
