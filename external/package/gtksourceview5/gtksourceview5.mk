################################################################################
#
# gtksourceview5
#
################################################################################

GTKSOURCEVIEW5_VERSION = 5.14.2
GTKSOURCEVIEW5_SOURCE = gtksourceview-$(GTKSOURCEVIEW5_VERSION).tar.xz
GTKSOURCEVIEW5_SITE = https://download.gnome.org/sources/gtksourceview/5.14
GTKSOURCEVIEW5_LICENSE = LGPL-2.1+
GTKSOURCEVIEW5_LICENSE_FILES = COPYING
GTKSOURCEVIEW5_INSTALL_STAGING = YES
GTKSOURCEVIEW5_DEPENDENCIES = host-pkgconf libgtk4 pcre2

GTKSOURCEVIEW5_CONF_OPTS = -Dgtk_doc=false -Dvapi=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
GTKSOURCEVIEW5_CONF_OPTS += -Dintrospection=enabled
GTKSOURCEVIEW5_DEPENDENCIES += gobject-introspection
else
GTKSOURCEVIEW5_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
