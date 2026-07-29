################################################################################
#
# garcon
#
################################################################################

GARCON_VERSION = 4.18.2
GARCON_SOURCE = garcon-$(GARCON_VERSION).tar.bz2
GARCON_SITE = https://archive.xfce.org/src/xfce/garcon/4.18
GARCON_LICENSE = GPL-2.0+, LGPL-2.1+ (library)
GARCON_LICENSE_FILES = COPYING
GARCON_INSTALL_STAGING = YES
GARCON_DEPENDENCIES = host-pkgconf libgtk3 libxfce4ui libxfce4util

GARCON_CONF_OPTS = --disable-introspection

$(eval $(autotools-package))
