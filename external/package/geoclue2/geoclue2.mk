################################################################################
#
# geoclue2
#
################################################################################

GEOCLUE2_VERSION = 2.7.2
GEOCLUE2_SOURCE = geoclue-$(GEOCLUE2_VERSION).tar.bz2
GEOCLUE2_SITE = https://gitlab.freedesktop.org/geoclue/geoclue/-/archive/$(GEOCLUE2_VERSION)
GEOCLUE2_LICENSE = LGPL-2.1+
GEOCLUE2_LICENSE_FILES = COPYING.LIB
GEOCLUE2_INSTALL_STAGING = YES
GEOCLUE2_DEPENDENCIES = host-pkgconf json-glib libsoup3

GEOCLUE2_CONF_OPTS = -D3g-source=false -Dcdma-source=false -Dmodem-gps-source=false -Dnmea-source=false -Ddemo-agent=false -Dgtk-doc=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
GEOCLUE2_CONF_OPTS += -Dintrospection=enabled
GEOCLUE2_DEPENDENCIES += gobject-introspection
else
GEOCLUE2_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
