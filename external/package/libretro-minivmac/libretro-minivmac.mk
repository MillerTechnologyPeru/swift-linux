################################################################################
#
# libretro-minivmac
#
# Pinned by commit: the libretro cores are rolling repositories without
# release tags. The repo's one submodule (libretro-common) is vendored as an
# extra download pinned to its own commit, since GitHub tarballs do not
# include submodules. Cores install under /usr/lib/libretro, where
# retroarch's libretro_directory points.
#
################################################################################

LIBRETRO_MINIVMAC_VERSION = 7de54a87e2527eb15b9ec2ac589e041c3d051d49
LIBRETRO_MINIVMAC_SITE = $(call github,libretro,libretro-minivmac,$(LIBRETRO_MINIVMAC_VERSION))
LIBRETRO_MINIVMAC_LICENSE = GPL-2.0
LIBRETRO_MINIVMAC_LICENSE_FILES = COPYING.txt

LIBRETRO_MINIVMAC_COMMON_VERSION = 70ed90c42ddea828f53dd1b984c6443ddb39dbd6
LIBRETRO_MINIVMAC_EXTRA_DOWNLOADS = \
	https://github.com/libretro/libretro-common/archive/$(LIBRETRO_MINIVMAC_COMMON_VERSION)/libretro-common-$(LIBRETRO_MINIVMAC_COMMON_VERSION).tar.gz

define LIBRETRO_MINIVMAC_UNPACK_COMMON
	rm -rf $(@D)/libretro-common
	mkdir -p $(@D)/libretro-common
	$(TAR) --strip-components=1 -xzf \
		$(LIBRETRO_MINIVMAC_DL_DIR)/libretro-common-$(LIBRETRO_MINIVMAC_COMMON_VERSION).tar.gz \
		-C $(@D)/libretro-common
endef
LIBRETRO_MINIVMAC_POST_EXTRACT_HOOKS += LIBRETRO_MINIVMAC_UNPACK_COMMON

define LIBRETRO_MINIVMAC_BUILD_CMDS
	$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) -f Makefile platform=unix \
		CC="$(TARGET_CC)" CXX="$(TARGET_CXX)" AR="$(TARGET_AR)"
endef

define LIBRETRO_MINIVMAC_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/minivmac_libretro.so \
		$(TARGET_DIR)/usr/lib/libretro/minivmac_libretro.so
endef

$(eval $(generic-package))
