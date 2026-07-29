################################################################################
#
# gnome-console
#
################################################################################

GNOME_CONSOLE_VERSION = 47.2.1
GNOME_CONSOLE_SOURCE = gnome-console-$(GNOME_CONSOLE_VERSION).tar.xz
GNOME_CONSOLE_SITE = https://download.gnome.org/sources/gnome-console/47
GNOME_CONSOLE_LICENSE = GPL-3.0+
GNOME_CONSOLE_LICENSE_FILES = COPYING
GNOME_CONSOLE_DEPENDENCIES = host-pkgconf libgtk4 libadwaita vte4 libgtop gsettings-desktop-schemas

GNOME_CONSOLE_CONF_OPTS = -Dtests=false

$(eval $(meson-package))
