################################################################################
#
# libretro-mu
#
# Pinned by commit: the libretro cores are rolling repositories without
# release tags. The libretro build lives in libretroBuildSystem/ and vendors
# its own libretro-common copy in-tree (no submodules). Cores install under
# /usr/lib/libretro, where retroarch's libretro_directory points.
#
################################################################################

LIBRETRO_MU_VERSION = de05588fcb1adca6738dc4cf6a2e6e6c447bf2f2
LIBRETRO_MU_SITE = $(call github,libretro,Mu,$(LIBRETRO_MU_VERSION))
LIBRETRO_MU_LICENSE = CC-BY-NC-3.0
LIBRETRO_MU_LICENSE_FILES = LICENSE

define LIBRETRO_MU_BUILD_CMDS
	$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D)/libretroBuildSystem \
		-f Makefile platform=unix \
		CC="$(TARGET_CC)" CXX="$(TARGET_CXX)" AR="$(TARGET_AR)"
endef

define LIBRETRO_MU_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/libretroBuildSystem/mu_libretro.so \
		$(TARGET_DIR)/usr/lib/libretro/mu_libretro.so
endef

$(eval $(generic-package))
