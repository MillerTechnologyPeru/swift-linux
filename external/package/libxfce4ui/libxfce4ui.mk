################################################################################
#
# libxfce4ui
#
################################################################################

LIBXFCE4UI_VERSION = 4.18.6
LIBXFCE4UI_SOURCE = libxfce4ui-$(LIBXFCE4UI_VERSION).tar.bz2
LIBXFCE4UI_SITE = https://archive.xfce.org/src/xfce/libxfce4ui/4.18
LIBXFCE4UI_LICENSE = GPL-2.0+, LGPL-2.1+ (library)
LIBXFCE4UI_LICENSE_FILES = COPYING
LIBXFCE4UI_INSTALL_STAGING = YES
LIBXFCE4UI_DEPENDENCIES = host-pkgconf libgtk3 libxfce4util xfconf startup-notification

LIBXFCE4UI_CONF_OPTS = --disable-introspection --disable-vala --disable-gladeui2

$(eval $(autotools-package))
