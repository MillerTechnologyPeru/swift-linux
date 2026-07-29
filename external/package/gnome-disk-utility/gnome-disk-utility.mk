################################################################################
#
# gnome-disk-utility
#
################################################################################

GNOME_DISK_UTILITY_VERSION = 46.1
GNOME_DISK_UTILITY_SOURCE = gnome-disk-utility-$(GNOME_DISK_UTILITY_VERSION).tar.xz
GNOME_DISK_UTILITY_SITE = https://download.gnome.org/sources/gnome-disk-utility/46
GNOME_DISK_UTILITY_LICENSE = GPL-2.0+
GNOME_DISK_UTILITY_LICENSE_FILES = COPYING
GNOME_DISK_UTILITY_DEPENDENCIES = host-pkgconf libgtk4 libadwaita udisks2 libpwquality libsecret libdvdread

GNOME_DISK_UTILITY_CONF_OPTS = -Dman=false

$(eval $(meson-package))
