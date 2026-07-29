################################################################################
#
# love
#
# The linux-src release tarball ships a generated configure, so this is a
# plain autotools build. LuaJIT is the supported interpreter (plain Lua
# loses the JIT and some games outright require it).
#
################################################################################

LOVE_VERSION = 11.5
LOVE_SITE = https://github.com/love2d/love/releases/download/$(LOVE_VERSION)
LOVE_SOURCE = love-$(LOVE_VERSION)-linux-src.tar.gz
LOVE_LICENSE = Zlib
LOVE_LICENSE_FILES = license.txt
LOVE_DEPENDENCIES = luajit-embed sdl2 openal freetype libmodplug mpg123 \
	libvorbis libogg libtheora zlib

LOVE_CONF_OPTS = --with-lua=luajit

$(eval $(autotools-package))
