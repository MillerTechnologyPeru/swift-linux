################################################################################
#
# dconf
#
################################################################################

DCONF_VERSION = 0.40.0
DCONF_SOURCE = dconf-$(DCONF_VERSION).tar.xz
DCONF_SITE = https://download.gnome.org/sources/dconf/0.40
DCONF_LICENSE = LGPL-2.1+
DCONF_LICENSE_FILES = COPYING
DCONF_INSTALL_STAGING = YES
DCONF_DEPENDENCIES = host-pkgconf libglib2

DCONF_CONF_OPTS = \
	-Dbash_completion=false \
	-Dman=false \
	-Dvapi=false

$(eval $(meson-package))
