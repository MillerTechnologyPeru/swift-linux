################################################################################
#
# librest
#
################################################################################

LIBREST_VERSION = 0.9.1
LIBREST_SOURCE = rest-$(LIBREST_VERSION).tar.xz
LIBREST_SITE = https://download.gnome.org/sources/rest/0.9
LIBREST_LICENSE = LGPL-2.1
LIBREST_LICENSE_FILES = COPYING
LIBREST_INSTALL_STAGING = YES
LIBREST_DEPENDENCIES = host-pkgconf libsoup3 json-glib

LIBREST_CONF_OPTS = -Dexamples=false -Dgtk_doc=false -Dtests=false -Dvapi=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
LIBREST_CONF_OPTS += -Dintrospection=enabled
LIBREST_DEPENDENCIES += gobject-introspection
else
LIBREST_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
