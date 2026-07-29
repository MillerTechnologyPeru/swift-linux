################################################################################
#
# tinysparql
#
################################################################################

TINYSPARQL_VERSION = 3.8.2
TINYSPARQL_SOURCE = tinysparql-$(TINYSPARQL_VERSION).tar.xz
TINYSPARQL_SITE = https://download.gnome.org/sources/tinysparql/3.8
TINYSPARQL_LICENSE = LGPL-2.1+
TINYSPARQL_LICENSE_FILES = COPYING.LGPL
TINYSPARQL_INSTALL_STAGING = YES
TINYSPARQL_DEPENDENCIES = host-pkgconf json-glib libsoup3 sqlite icu

TINYSPARQL_CONF_OPTS = -Dman=false -Ddocs=false -Dtests=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
TINYSPARQL_CONF_OPTS += -Dintrospection=enabled
TINYSPARQL_DEPENDENCIES += gobject-introspection
else
TINYSPARQL_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
