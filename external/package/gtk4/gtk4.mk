################################################################################
#
# gtk4
#
# The release tarball ships the pregenerated stylesheet, so no sassc is
# needed; introspection, docs, demos and the gstreamer/cups/vulkan
# integrations are off to match what the image carries.
#
################################################################################

GTK4_VERSION = 4.16.13
GTK4_SOURCE = gtk-$(GTK4_VERSION).tar.xz
GTK4_SITE = https://download.gnome.org/sources/gtk/4.16
GTK4_LICENSE = LGPL-2.1+
GTK4_LICENSE_FILES = COPYING
GTK4_INSTALL_STAGING = YES
GTK4_DEPENDENCIES = \
	host-pkgconf host-libglib2 libglib2 cairo pango gdk-pixbuf \
	graphene libepoxy fontconfig

GTK4_CONF_OPTS = \
	-Dbuild-demos=false \
	-Dbuild-testsuite=false \
	-Dbuild-examples=false \
	-Dbuild-tests=false \
	-Dintrospection=disabled \
	-Ddocumentation=false \
	-Dman-pages=false \
	-Dmedia-gstreamer=disabled \
	-Dprint-cups=disabled \
	-Dvulkan=disabled \
	-Dcloudproviders=disabled \
	-Dcolord=disabled \
	-Dsysprof=disabled

ifeq ($(BR2_PACKAGE_GTK4_WAYLAND),y)
GTK4_CONF_OPTS += -Dwayland-backend=true
GTK4_DEPENDENCIES += wayland wayland-protocols libxkbcommon
else
GTK4_CONF_OPTS += -Dwayland-backend=false
endif

ifeq ($(BR2_PACKAGE_GTK4_X11),y)
GTK4_CONF_OPTS += -Dx11-backend=true
GTK4_DEPENDENCIES += \
	xlib_libX11 xlib_libXext xlib_libXrandr xlib_libXrender \
	xlib_libXi xlib_libXcursor xlib_libXdamage xlib_libXfixes \
	xlib_libXinerama
else
GTK4_CONF_OPTS += -Dx11-backend=false
endif

$(eval $(meson-package))
