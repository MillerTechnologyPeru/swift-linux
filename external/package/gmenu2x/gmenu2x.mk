################################################################################
#
# gmenu2x
#
# MiyooCFW's fork. Pinned by commit (the fork does not tag releases); the
# default skin set is a git submodule, hence the git site method.
#
# Upstream builds with per-platform Makefiles that hardcode the MiyooCFW
# cross toolchain at /opt/miyoo and query sdl-config from its sysroot; every
# toolchain-touching variable is overridden on the make command line instead
# (command-line assignments beat the Makefile's := assignments). PLATFORM
# stays "miyoo" so the BittBoy-family key layout and TV-out handling are
# compiled in. COMMIT_HASH is forced because the Makefile shells out to git,
# which fails outside a checkout with submodule stripping.
#
################################################################################

GMENU2X_VERSION = f11610ab4056793686aa6a20d5c5c58a43844410
GMENU2X_SITE = https://github.com/MiyooCFW/gmenu2x.git
GMENU2X_SITE_METHOD = git
GMENU2X_GIT_SUBMODULES = YES
GMENU2X_LICENSE = GPL-2.0
GMENU2X_LICENSE_FILES = COPYING

GMENU2X_DEPENDENCIES = host-pkgconf sdl sdl_image sdl_ttf

# STRIP must be a real strip: the Makefile produces its final binary WITH
# it ("$(STRIP) foo-debug -o foo"), so a no-op like "true" would build
# nothing. OBJDIR defaults to /tmp/gmenu2x - keep objects in the package
# build dir instead.
GMENU2X_MAKE_VARS = \
	CC="$(TARGET_CC)" \
	CXX="$(TARGET_CXX)" \
	STRIP="$(TARGET_CROSS)strip" \
	OBJDIR="$(@D)/.objs" \
	COMMIT_HASH=buildroot \
	SDL_CFLAGS="`$(STAGING_DIR)/usr/bin/sdl-config --cflags`" \
	PKG_LIBS="`$(PKG_CONFIG_HOST_BINARY) --libs sdl SDL_image SDL_ttf`"

define GMENU2X_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) -f Makefile.miyoo \
		$(GMENU2X_MAKE_VARS) dist
endef

# The dist tree is the layout the frontend expects at runtime (skins,
# translations, scripts next to the binary); install it whole and expose
# the binary on PATH.
define GMENU2X_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/share/gmenu2x
	cp -a $(@D)/dist/miyoo/. $(TARGET_DIR)/usr/share/gmenu2x/
	ln -sf ../share/gmenu2x/gmenu2x $(TARGET_DIR)/usr/bin/gmenu2x
endef

$(eval $(generic-package))
