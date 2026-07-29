################################################################################
#
# decibels
#
################################################################################

DECIBELS_VERSION = 48.0
DECIBELS_SOURCE = decibels-$(DECIBELS_VERSION).tar.xz
DECIBELS_SITE = https://download.gnome.org/sources/decibels/48
DECIBELS_LICENSE = GPL-3.0+
DECIBELS_LICENSE_FILES = COPYING
DECIBELS_DEPENDENCIES = host-pkgconf libgtk4 libadwaita gjs gst1-plugins-base gst1-plugins-good

DECIBELS_CONF_OPTS = 

$(eval $(meson-package))
