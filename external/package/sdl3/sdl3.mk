################################################################################
#
# sdl3
#
# Buildroot ships SDL2 only, so SDL3 is provided here. Unlike SDL2, which
# uses autotools, SDL3 is built with CMake.
#
################################################################################

SDL3_VERSION = 3.4.12
SDL3_SOURCE = SDL3-$(SDL3_VERSION).tar.gz
SDL3_SITE = https://github.com/libsdl-org/SDL/releases/download/release-$(SDL3_VERSION)
SDL3_LICENSE = Zlib
SDL3_LICENSE_FILES = LICENSE.txt
SDL3_CPE_ID_VENDOR = libsdl
SDL3_CPE_ID_PRODUCT = simple_directmedia_layer
SDL3_INSTALL_STAGING = YES
SDL3_DEPENDENCIES = host-pkgconf

SDL3_CONF_OPTS = \
	-DSDL_SHARED=ON \
	-DSDL_STATIC=OFF \
	-DSDL_EXAMPLES=OFF \
	-DSDL_RPI=OFF \
	-DSDL_OSS=OFF \
	-DSDL_JACK=OFF \
	-DSDL_SNDIO=OFF \
	-DSDL_PIPEWIRE=OFF \
	-DSDL_PULSEAUDIO=OFF \
	-DSDL_VULKAN=OFF \
	-DSDL_OFFSCREEN=OFF

ifeq ($(BR2_PACKAGE_SDL3_TESTS),y)
SDL3_CONF_OPTS += -DSDL_TESTS=ON
else
SDL3_CONF_OPTS += -DSDL_TESTS=OFF
endif

ifeq ($(BR2_PACKAGE_SDL3_WAYLAND),y)
SDL3_CONF_OPTS += -DSDL_WAYLAND=ON
SDL3_DEPENDENCIES += wayland wayland-protocols libxkbcommon
# libdecor draws client-side decorations; only enable it when available.
ifeq ($(BR2_PACKAGE_LIBDECOR),y)
SDL3_CONF_OPTS += -DSDL_WAYLAND_LIBDECOR=ON
SDL3_DEPENDENCIES += libdecor
else
SDL3_CONF_OPTS += -DSDL_WAYLAND_LIBDECOR=OFF
endif
else
SDL3_CONF_OPTS += -DSDL_WAYLAND=OFF
endif

ifeq ($(BR2_PACKAGE_SDL3_KMSDRM),y)
SDL3_CONF_OPTS += -DSDL_KMSDRM=ON
SDL3_DEPENDENCIES += libdrm libgbm libegl
else
SDL3_CONF_OPTS += -DSDL_KMSDRM=OFF
endif

ifeq ($(BR2_PACKAGE_SDL3_X11),y)
SDL3_CONF_OPTS += -DSDL_X11=ON
SDL3_DEPENDENCIES += xlib_libX11 xlib_libXext
else
SDL3_CONF_OPTS += -DSDL_X11=OFF
endif

ifeq ($(BR2_PACKAGE_SDL3_OPENGLES),y)
SDL3_CONF_OPTS += -DSDL_OPENGLES=ON
SDL3_DEPENDENCIES += libgles
else
SDL3_CONF_OPTS += -DSDL_OPENGLES=OFF
endif

ifeq ($(BR2_PACKAGE_SDL3_OPENGL),y)
SDL3_CONF_OPTS += -DSDL_OPENGL=ON
SDL3_DEPENDENCIES += libgl
else
SDL3_CONF_OPTS += -DSDL_OPENGL=OFF
endif

ifeq ($(BR2_PACKAGE_SDL3_ALSA),y)
SDL3_CONF_OPTS += -DSDL_ALSA=ON -DSDL_ALSA_SHARED=OFF
SDL3_DEPENDENCIES += alsa-lib
else
SDL3_CONF_OPTS += -DSDL_ALSA=OFF
endif

ifeq ($(BR2_PACKAGE_HAS_UDEV),y)
SDL3_CONF_OPTS += -DSDL_LIBUDEV=ON
SDL3_DEPENDENCIES += udev
else
SDL3_CONF_OPTS += -DSDL_LIBUDEV=OFF
endif

ifeq ($(BR2_PACKAGE_DBUS),y)
SDL3_CONF_OPTS += -DSDL_DBUS=ON
SDL3_DEPENDENCIES += dbus
else
SDL3_CONF_OPTS += -DSDL_DBUS=OFF
endif

$(eval $(cmake-package))
