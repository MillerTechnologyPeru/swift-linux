################################################################################
#
# gnome-bluetooth
#
################################################################################

GNOME_BLUETOOTH_VERSION = 47.2
GNOME_BLUETOOTH_SOURCE = gnome-bluetooth-$(GNOME_BLUETOOTH_VERSION).tar.xz
GNOME_BLUETOOTH_SITE = https://download.gnome.org/sources/gnome-bluetooth/47
GNOME_BLUETOOTH_LICENSE = LGPL-2.1+
GNOME_BLUETOOTH_LICENSE_FILES = COPYING.LIB
GNOME_BLUETOOTH_INSTALL_STAGING = YES
GNOME_BLUETOOTH_DEPENDENCIES = host-pkgconf libgtk4 libadwaita gsound libnotify libgudev

GNOME_BLUETOOTH_CONF_OPTS = -Dgtk_doc=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
GNOME_BLUETOOTH_CONF_OPTS += -Dintrospection=enabled
GNOME_BLUETOOTH_DEPENDENCIES += gobject-introspection
else
GNOME_BLUETOOTH_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
