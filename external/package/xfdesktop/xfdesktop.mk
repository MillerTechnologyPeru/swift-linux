################################################################################
#
# xfdesktop
#
################################################################################

XFDESKTOP_VERSION = 4.18.1
XFDESKTOP_SOURCE = xfdesktop-$(XFDESKTOP_VERSION).tar.bz2
XFDESKTOP_SITE = https://archive.xfce.org/src/xfce/xfdesktop/4.18
XFDESKTOP_LICENSE = GPL-2.0+
XFDESKTOP_LICENSE_FILES = COPYING
XFDESKTOP_INSTALL_STAGING = YES
XFDESKTOP_DEPENDENCIES = host-pkgconf libgtk3 exo garcon libwnck libxfce4ui libxfce4util xfconf

XFDESKTOP_CONF_OPTS = --disable-thunarx

$(eval $(autotools-package))
