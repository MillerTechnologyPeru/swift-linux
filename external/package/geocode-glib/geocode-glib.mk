################################################################################
#
# geocode-glib
#
################################################################################

GEOCODE_GLIB_VERSION = 3.26.4
GEOCODE_GLIB_SOURCE = geocode-glib-$(GEOCODE_GLIB_VERSION).tar.xz
GEOCODE_GLIB_SITE = https://download.gnome.org/sources/geocode-glib/3.26
GEOCODE_GLIB_LICENSE = LGPL-2.0+
GEOCODE_GLIB_LICENSE_FILES = COPYING.LIB
GEOCODE_GLIB_INSTALL_STAGING = YES
GEOCODE_GLIB_DEPENDENCIES = host-pkgconf libsoup3 json-glib

GEOCODE_GLIB_CONF_OPTS = -Denable-gtk-doc=false -Denable-installed-tests=false -Dsoup2=false -Denable-introspection=false

$(eval $(meson-package))
