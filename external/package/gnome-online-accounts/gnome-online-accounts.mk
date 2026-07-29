################################################################################
#
# gnome-online-accounts
#
################################################################################

GNOME_ONLINE_ACCOUNTS_VERSION = 3.52.10
GNOME_ONLINE_ACCOUNTS_SOURCE = gnome-online-accounts-$(GNOME_ONLINE_ACCOUNTS_VERSION).tar.xz
GNOME_ONLINE_ACCOUNTS_SITE = https://download.gnome.org/sources/gnome-online-accounts/3.52
GNOME_ONLINE_ACCOUNTS_LICENSE = LGPL-2.0+
GNOME_ONLINE_ACCOUNTS_LICENSE_FILES = COPYING
GNOME_ONLINE_ACCOUNTS_INSTALL_STAGING = YES
GNOME_ONLINE_ACCOUNTS_DEPENDENCIES = host-pkgconf libgtk4 libadwaita webkitgtk librest json-glib libsecret gcr4

GNOME_ONLINE_ACCOUNTS_CONF_OPTS = -Dgoabackend=true -Ddocumentation=false -Dman=false -Dvapi=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
GNOME_ONLINE_ACCOUNTS_CONF_OPTS += -Dintrospection=enabled
GNOME_ONLINE_ACCOUNTS_DEPENDENCIES += gobject-introspection
else
GNOME_ONLINE_ACCOUNTS_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
