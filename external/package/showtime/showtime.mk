################################################################################
#
# showtime
#
################################################################################

SHOWTIME_VERSION = 48.1
SHOWTIME_SOURCE = showtime-$(SHOWTIME_VERSION).tar.xz
SHOWTIME_SITE = https://download.gnome.org/sources/showtime/48
SHOWTIME_LICENSE = GPL-3.0+
SHOWTIME_LICENSE_FILES = COPYING
SHOWTIME_DEPENDENCIES = host-pkgconf libgtk4 libadwaita python3 python-gobject gst1-plugins-base gst1-plugins-good

SHOWTIME_CONF_OPTS = 

$(eval $(meson-package))
