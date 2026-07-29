################################################################################
#
# solarus-engine
#
# Buildroot's solarus package with the Lua dependency hardwired to LuaJIT
# (see Config.in for why). Source, patches and hash mirror the upstream
# Buildroot package at 1.6.5.
#
################################################################################

SOLARUS_ENGINE_VERSION = 1.6.5
SOLARUS_ENGINE_SITE = \
	https://gitlab.com/solarus-games/solarus/-/archive/v$(SOLARUS_ENGINE_VERSION)
SOLARUS_ENGINE_SOURCE = solarus-v$(SOLARUS_ENGINE_VERSION).tar.bz2
SOLARUS_ENGINE_LICENSE = GPL-3.0 (code), CC-BY-SA-4.0 (Solarus logos and icons), \
	CC-BY-SA-3.0 (GUI icons)
SOLARUS_ENGINE_LICENSE_FILES = license.txt
SOLARUS_ENGINE_INSTALL_STAGING = YES

SOLARUS_ENGINE_DEPENDENCIES = glm libmodplug libogg libvorbis openal physfs \
	sdl2 sdl2_image sdl2_ttf luajit

# No launcher GUI (it requires Qt5).
SOLARUS_ENGINE_CONF_OPTS = \
	-DSOLARUS_GUI=OFF \
	-DSOLARUS_TESTS=OFF \
	-DSOLARUS_USE_LUAJIT=ON

ifeq ($(BR2_PACKAGE_HAS_LIBGL),y)
SOLARUS_ENGINE_DEPENDENCIES += libgl
else
SOLARUS_ENGINE_CONF_OPTS += -DSOLARUS_GL_ES=ON
SOLARUS_ENGINE_DEPENDENCIES += libgles
endif

$(eval $(cmake-package))
