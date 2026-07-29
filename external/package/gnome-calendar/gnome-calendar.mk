################################################################################
#
# gnome-calendar
#
################################################################################

GNOME_CALENDAR_VERSION = 47.0
GNOME_CALENDAR_SOURCE = gnome-calendar-$(GNOME_CALENDAR_VERSION).tar.xz
GNOME_CALENDAR_SITE = https://download.gnome.org/sources/gnome-calendar/47
GNOME_CALENDAR_LICENSE = GPL-3.0+
GNOME_CALENDAR_LICENSE_FILES = COPYING
GNOME_CALENDAR_DEPENDENCIES = host-pkgconf libgtk4 libadwaita evolution-data-server libgweather geoclue2 libical gsettings-desktop-schemas

GNOME_CALENDAR_CONF_OPTS = -Ddocs=false -Dtests=false

$(eval $(meson-package))
