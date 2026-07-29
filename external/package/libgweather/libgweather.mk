################################################################################
#
# libgweather
#
################################################################################

LIBGWEATHER_VERSION = 4.4.4
LIBGWEATHER_SOURCE = libgweather-$(LIBGWEATHER_VERSION).tar.xz
LIBGWEATHER_SITE = https://download.gnome.org/sources/libgweather/4.4
LIBGWEATHER_LICENSE = LGPL-2.1+
LIBGWEATHER_LICENSE_FILES = COPYING
LIBGWEATHER_INSTALL_STAGING = YES
LIBGWEATHER_DEPENDENCIES = host-pkgconf libsoup3 json-glib libxml2 tzdata

LIBGWEATHER_CONF_OPTS = -Dgtk_doc=false -Dtests=false -Dvapi=false -Denable_vala=false

# gnome-shell drives everything through GObject introspection typelibs, so
# build them whenever the config carries gobject-introspection.
ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
LIBGWEATHER_CONF_OPTS += -Dintrospection=enabled
LIBGWEATHER_DEPENDENCIES += gobject-introspection
else
LIBGWEATHER_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
