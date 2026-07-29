################################################################################
#
# xfce4-settings
#
################################################################################

XFCE4_SETTINGS_VERSION = 4.18.6
XFCE4_SETTINGS_SOURCE = xfce4-settings-$(XFCE4_SETTINGS_VERSION).tar.bz2
XFCE4_SETTINGS_SITE = https://archive.xfce.org/src/xfce/xfce4-settings/4.18
XFCE4_SETTINGS_LICENSE = GPL-2.0+
XFCE4_SETTINGS_LICENSE_FILES = COPYING
XFCE4_SETTINGS_INSTALL_STAGING = YES
XFCE4_SETTINGS_DEPENDENCIES = host-pkgconf libgtk3 exo libxfce4ui libxfce4util xfconf

XFCE4_SETTINGS_CONF_OPTS = --disable-introspection --disable-upower --disable-libxklavier

$(eval $(autotools-package))
