################################################################################
#
# xfce4-panel
#
################################################################################

XFCE4_PANEL_VERSION = 4.18.6
XFCE4_PANEL_SOURCE = xfce4-panel-$(XFCE4_PANEL_VERSION).tar.bz2
XFCE4_PANEL_SITE = https://archive.xfce.org/src/xfce/xfce4-panel/4.18
XFCE4_PANEL_LICENSE = GPL-2.0+, LGPL-2.1+ (libraries)
XFCE4_PANEL_LICENSE_FILES = COPYING
XFCE4_PANEL_INSTALL_STAGING = YES
XFCE4_PANEL_DEPENDENCIES = host-pkgconf libgtk3 exo garcon libwnck libxfce4ui libxfce4util xfconf

XFCE4_PANEL_CONF_OPTS = --disable-introspection --disable-vala

$(eval $(autotools-package))
