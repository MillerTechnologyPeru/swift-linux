################################################################################
#
# libretro-mgba
#
# Pinned by commit: the libretro cores are rolling repositories without
# release tags. mGBA is CMake; BUILD_LIBRETRO builds the core alongside
# nothing else (frontends and tools all off). Cores install under
# /usr/lib/libretro, where retroarch's libretro_directory points.
#
################################################################################

LIBRETRO_MGBA_VERSION = 97c4de34889fc990119f7d9a95167f623f17e27d
LIBRETRO_MGBA_SITE = $(call github,mgba-emu,mgba,$(LIBRETRO_MGBA_VERSION))
LIBRETRO_MGBA_LICENSE = MPL-2.0
LIBRETRO_MGBA_LICENSE_FILES = LICENSE
LIBRETRO_MGBA_DEPENDENCIES = libzip libpng zlib

LIBRETRO_MGBA_CONF_OPTS = \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_LIBRETRO=ON \
	-DSKIP_LIBRARY=ON \
	-DBUILD_QT=OFF \
	-DBUILD_SDL=OFF \
	-DUSE_DISCORD_RPC=OFF \
	-DUSE_SQLITE3=OFF \
	-DUSE_EDITLINE=OFF \
	-DUSE_EPOXY=OFF \
	-DBUILD_GL=OFF \
	-DBUILD_GLES2=OFF \
	-DBUILD_GLES3=OFF

define LIBRETRO_MGBA_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/mgba_libretro.so \
		$(TARGET_DIR)/usr/lib/libretro/mgba_libretro.so
endef

$(eval $(cmake-package))
