################################################################################
#
# libretro-easyrpg
#
# The EasyRPG Player built as a libretro core. This upstream tags releases,
# so the pin is a tag. The libretro build needs the libretro-common
# submodule, vendored here as an extra download pinned to its own commit
# (GitHub tarballs do not include submodules). liblcf is a separate package
# rather than the in-tree build (PLAYER_BUILD_LIBLCF stays off). Cores
# install under /usr/lib/libretro, where retroarch's libretro_directory
# points.
#
################################################################################

LIBRETRO_EASYRPG_VERSION = 0.8.1.1
LIBRETRO_EASYRPG_SITE = $(call github,EasyRPG,Player,$(LIBRETRO_EASYRPG_VERSION))
LIBRETRO_EASYRPG_LICENSE = GPL-3.0
LIBRETRO_EASYRPG_LICENSE_FILES = COPYING
LIBRETRO_EASYRPG_SUPPORTS_IN_SOURCE_BUILD = NO
LIBRETRO_EASYRPG_DEPENDENCIES = liblcf sdl2 zlib fmt libpng freetype mpg123 \
	libvorbis opusfile pixman speexdsp

LIBRETRO_EASYRPG_COMMON_VERSION = 70ed90c42ddea828f53dd1b984c6443ddb39dbd6
LIBRETRO_EASYRPG_EXTRA_DOWNLOADS = \
	https://github.com/libretro/libretro-common/archive/$(LIBRETRO_EASYRPG_COMMON_VERSION)/libretro-common-$(LIBRETRO_EASYRPG_COMMON_VERSION).tar.gz

define LIBRETRO_EASYRPG_UNPACK_COMMON
	rm -rf $(@D)/builds/libretro/libretro-common
	mkdir -p $(@D)/builds/libretro/libretro-common
	$(TAR) --strip-components=1 -xzf \
		$(LIBRETRO_EASYRPG_DL_DIR)/libretro-common-$(LIBRETRO_EASYRPG_COMMON_VERSION).tar.gz \
		-C $(@D)/builds/libretro/libretro-common
endef
LIBRETRO_EASYRPG_POST_EXTRACT_HOOKS += LIBRETRO_EASYRPG_UNPACK_COMMON

LIBRETRO_EASYRPG_CONF_OPTS = \
	-DCMAKE_BUILD_TYPE=Release \
	-DPLAYER_TARGET_PLATFORM=libretro \
	-DBUILD_SHARED_LIBS=ON \
	-DPLAYER_BUILD_LIBLCF=OFF \
	-DPLAYER_ENABLE_TESTS=OFF

define LIBRETRO_EASYRPG_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/buildroot-build/easyrpg_libretro.so \
		$(TARGET_DIR)/usr/lib/libretro/easyrpg_libretro.so
endef

$(eval $(cmake-package))
