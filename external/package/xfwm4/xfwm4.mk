################################################################################
#
# xfwm4
#
################################################################################

XFWM4_VERSION = 4.18.0
XFWM4_SOURCE = xfwm4-$(XFWM4_VERSION).tar.bz2
XFWM4_SITE = https://archive.xfce.org/src/xfce/xfwm4/4.18
XFWM4_LICENSE = GPL-2.0+
XFWM4_LICENSE_FILES = COPYING
XFWM4_INSTALL_STAGING = YES
XFWM4_DEPENDENCIES = host-pkgconf libgtk3 libwnck libxfce4ui libxfce4util xfconf

XFWM4_CONF_OPTS = --disable-introspection

$(eval $(autotools-package))
