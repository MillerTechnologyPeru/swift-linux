################################################################################
#
# exo
#
################################################################################

EXO_VERSION = 4.18.0
EXO_SOURCE = exo-$(EXO_VERSION).tar.bz2
EXO_SITE = https://archive.xfce.org/src/xfce/exo/4.18
EXO_LICENSE = GPL-2.0+, LGPL-2.1+ (library)
EXO_LICENSE_FILES = COPYING
EXO_INSTALL_STAGING = YES
EXO_DEPENDENCIES = host-pkgconf libgtk3 libxfce4ui libxfce4util

EXO_CONF_OPTS = --disable-introspection

$(eval $(autotools-package))
