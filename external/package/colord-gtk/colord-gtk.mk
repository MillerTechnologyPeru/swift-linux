################################################################################
#
# colord-gtk
#
################################################################################

COLORD_GTK_VERSION = 0.3.1
COLORD_GTK_SOURCE = colord-gtk-$(COLORD_GTK_VERSION).tar.xz
COLORD_GTK_SITE = https://www.freedesktop.org/software/colord/releases
COLORD_GTK_LICENSE = LGPL-2.1+
COLORD_GTK_LICENSE_FILES = COPYING
COLORD_GTK_INSTALL_STAGING = YES
COLORD_GTK_DEPENDENCIES = host-pkgconf colord libgtk4

COLORD_GTK_CONF_OPTS = -Dgtk3=false -Dgtk4=true -Dman=false -Ddocs=false -Dvapi=false -Dtests=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
COLORD_GTK_CONF_OPTS += -Dintrospection=enabled
COLORD_GTK_DEPENDENCIES += gobject-introspection
else
COLORD_GTK_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
