################################################################################
#
# gnome-autoar
#
################################################################################

GNOME_AUTOAR_VERSION = 0.4.5
GNOME_AUTOAR_SOURCE = gnome-autoar-$(GNOME_AUTOAR_VERSION).tar.xz
GNOME_AUTOAR_SITE = https://download.gnome.org/sources/gnome-autoar/0.4
GNOME_AUTOAR_LICENSE = LGPL-2.1+
GNOME_AUTOAR_LICENSE_FILES = COPYING
GNOME_AUTOAR_INSTALL_STAGING = YES
GNOME_AUTOAR_DEPENDENCIES = host-pkgconf libarchive

GNOME_AUTOAR_CONF_OPTS = -Dgtk=false -Dvapi=false -Dtests=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
GNOME_AUTOAR_CONF_OPTS += -Dintrospection=enabled
GNOME_AUTOAR_DEPENDENCIES += gobject-introspection
else
GNOME_AUTOAR_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
