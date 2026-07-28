################################################################################
#
# thunar
#
################################################################################

THUNAR_VERSION = 4.18.11
THUNAR_SOURCE = thunar-$(THUNAR_VERSION).tar.bz2
THUNAR_SITE = https://archive.xfce.org/src/xfce/thunar/4.18
THUNAR_LICENSE = GPL-2.0+, LGPL-2.1+ (thunarx)
THUNAR_LICENSE_FILES = COPYING
THUNAR_INSTALL_STAGING = YES
THUNAR_DEPENDENCIES = host-pkgconf libgtk3 exo libxfce4ui libxfce4util xfconf gdk-pixbuf

THUNAR_CONF_OPTS = --disable-introspection --disable-gudev --disable-libnotify

$(eval $(autotools-package))
