################################################################################
#
# retroarch
#
# RetroArch's ./configure is its own "qb" system, not autoconf: it takes
# --enable/--disable flags and reads CC/CXX/PKG_CONF_PATH from the
# environment, but does not understand --host, so this is a generic-package
# with explicit configure commands rather than an autotools-package.
#
################################################################################

RETROARCH_VERSION = v1.22.2
RETROARCH_SITE = $(call github,libretro,RetroArch,$(RETROARCH_VERSION))
RETROARCH_LICENSE = GPL-3.0+
RETROARCH_LICENSE_FILES = COPYING

RETROARCH_DEPENDENCIES = \
	host-pkgconf zlib freetype alsa-lib libxkbcommon \
	wayland wayland-protocols udev

# Video: Wayland/EGL only - the frontend runs inside the sway session. X11
# is off even though XWayland exists (no reason to take the round trip),
# and KMS/DRM context support stays available for a future direct-DRM mode.
# Audio: ALSA, routed by PipeWire's ALSA plugin; there is no PulseAudio
# daemon (pipewire-pulse only speaks the protocol) and no JACK.
# Input: udev/evdev, the same path the "input" group in users.txt opens up.
RETROARCH_CONF_OPTS = \
	--prefix=/usr \
	--disable-qt \
	--disable-x11 \
	--enable-wayland \
	--enable-egl \
	--enable-kms \
	--enable-udev \
	--enable-alsa \
	--disable-pulse \
	--disable-jack \
	--disable-oss \
	--disable-sdl \
	--disable-sdl2 \
	--disable-ffmpeg \
	--disable-discord \
	--enable-zlib \
	--enable-freetype

# Desktop GL where the board has it, GLES2 otherwise (same split as
# emulationstation).
ifeq ($(BR2_PACKAGE_HAS_LIBGL),y)
RETROARCH_DEPENDENCIES += libgl
RETROARCH_CONF_OPTS += --enable-opengl
else
RETROARCH_DEPENDENCIES += libgles
RETROARCH_CONF_OPTS += --enable-opengles
endif

# Vulkan needs the loader at runtime; the GPU fragments that provide a
# Vulkan driver also select it.
ifeq ($(BR2_PACKAGE_VULKAN_LOADER),y)
RETROARCH_DEPENDENCIES += vulkan-loader vulkan-headers
RETROARCH_CONF_OPTS += --enable-vulkan
else
RETROARCH_CONF_OPTS += --disable-vulkan
endif

# CROSS_COMPILE matters beyond the tool prefix: qb's configure only
# refrains from adding host paths like -L/usr/lib64 (which the toolchain
# wrapper rightly rejects) when it knows it is cross-compiling.
define RETROARCH_CONFIGURE_CMDS
	cd $(@D) && \
		$(TARGET_CONFIGURE_OPTS) \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		PKG_CONF_PATH="$(PKG_CONFIG_HOST_BINARY)" \
		./configure $(RETROARCH_CONF_OPTS)
endef

define RETROARCH_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)
endef

define RETROARCH_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) DESTDIR=$(TARGET_DIR) install
endef

$(eval $(generic-package))
