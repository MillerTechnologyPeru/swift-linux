################################################################################
#
# nautilus
#
################################################################################

NAUTILUS_VERSION = 47.6
NAUTILUS_SOURCE = nautilus-$(NAUTILUS_VERSION).tar.xz
NAUTILUS_SITE = https://download.gnome.org/sources/nautilus/47
NAUTILUS_LICENSE = GPL-3.0+
NAUTILUS_LICENSE_FILES = COPYING
NAUTILUS_DEPENDENCIES = host-pkgconf libgtk4 libadwaita gnome-autoar gexiv2 tinysparql gnome-desktop gsettings-desktop-schemas

NAUTILUS_CONF_OPTS = -Ddocs=false -Dtests=none -Dextensions=false -Dselinux=false -Dpackagekit=false

$(eval $(meson-package))
