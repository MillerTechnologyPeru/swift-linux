################################################################################
#
# luajit-embed
#
# Buildroot's luajit sources, built as a plain library instead of as the
# system Lua interpreter. Two lines of that package are what make it
# exclusive with lua, and both are dropped here:
#
#   LUAJIT_PROVIDES = luainterpreter     - the virtual-package claim whose
#                                          duplicate trips luajit.mk's
#                                          "only one provider" check
#   ln -fs luajit .../usr/bin/lua        - the symlink that would collide
#                                          with lua's own binary
#
# Everything else (version, hash, build flags) tracks the Buildroot
# package; keep them in step when bumping Buildroot.
#
################################################################################

LUAJIT_EMBED_VERSION = 871db2c84ecefd70a850e03a6c340214a81739f0
LUAJIT_EMBED_SITE = $(call github,LuaJIT,LuaJIT,$(LUAJIT_EMBED_VERSION))
LUAJIT_EMBED_LICENSE = MIT
LUAJIT_EMBED_LICENSE_FILES = COPYRIGHT
LUAJIT_EMBED_INSTALL_STAGING = YES

# The luajit build needs a host compiler of the same bitness as the
# target: on a 32-bit target pass -m32 so a 64-bit build machine still
# produces a matching host part.
ifeq ($(BR2_ARCH_IS_64),y)
LUAJIT_EMBED_HOST_CC = $(HOSTCC)
else
LUAJIT_EMBED_HOST_CC = $(HOSTCC) -m32
LUAJIT_EMBED_XCFLAGS += -DLUAJIT_DISABLE_GC64
endif

# TARGET_CONFIGURE_OPTS is unusable here: luajit's build system uses its
# own variable names.
define LUAJIT_EMBED_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) PREFIX="/usr" \
		STATIC_CC="$(TARGET_CC)" \
		DYNAMIC_CC="$(TARGET_CC) -fPIC" \
		TARGET_LD="$(TARGET_CC)" \
		TARGET_AR="$(TARGET_AR) rcus" \
		TARGET_STRIP=true \
		TARGET_CFLAGS="$(TARGET_CFLAGS)" \
		TARGET_LDFLAGS="$(TARGET_LDFLAGS)" \
		HOST_CC="$(LUAJIT_EMBED_HOST_CC)" \
		HOST_CFLAGS="$(HOST_CFLAGS)" \
		HOST_LDFLAGS="$(HOST_LDFLAGS)" \
		BUILDMODE=dynamic \
		XCFLAGS="$(LUAJIT_EMBED_XCFLAGS)" \
		-C $(@D) amalg
endef

define LUAJIT_EMBED_INSTALL_STAGING_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) PREFIX="/usr" DESTDIR="$(STAGING_DIR)" \
		LDCONFIG=true -C $(@D) install
endef

define LUAJIT_EMBED_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) PREFIX="/usr" DESTDIR="$(TARGET_DIR)" \
		LDCONFIG=true -C $(@D) install
endef

$(eval $(generic-package))
