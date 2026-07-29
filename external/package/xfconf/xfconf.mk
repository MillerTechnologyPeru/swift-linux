################################################################################
#
# xfconf
#
################################################################################

XFCONF_VERSION = 4.18.3
XFCONF_SOURCE = xfconf-$(XFCONF_VERSION).tar.bz2
XFCONF_SITE = https://archive.xfce.org/src/xfce/xfconf/4.18
XFCONF_LICENSE = GPL-2.0+, LGPL-2.1+ (library)
XFCONF_LICENSE_FILES = COPYING
XFCONF_INSTALL_STAGING = YES
XFCONF_DEPENDENCIES = host-pkgconf libxfce4util dbus

XFCONF_CONF_OPTS = --disable-introspection --disable-vala

$(eval $(autotools-package))
