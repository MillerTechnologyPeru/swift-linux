################################################################################
#
# gsound
#
################################################################################

GSOUND_VERSION = 1.0.3
GSOUND_SOURCE = gsound-$(GSOUND_VERSION).tar.xz
GSOUND_SITE = https://download.gnome.org/sources/gsound/1.0
GSOUND_LICENSE = LGPL-2.1+
GSOUND_LICENSE_FILES = COPYING
GSOUND_INSTALL_STAGING = YES
GSOUND_DEPENDENCIES = host-pkgconf host-vala libcanberra

GSOUND_CONF_OPTS = 

$(eval $(meson-package))
