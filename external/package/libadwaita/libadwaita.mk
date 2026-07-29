################################################################################
#
# libadwaita
#
# The release tarball ships the pregenerated stylesheet (no sassc needed).
#
################################################################################

LIBADWAITA_VERSION = 1.6.10
LIBADWAITA_SOURCE = libadwaita-$(LIBADWAITA_VERSION).tar.xz
LIBADWAITA_SITE = https://download.gnome.org/sources/libadwaita/1.6
LIBADWAITA_LICENSE = LGPL-2.1+
LIBADWAITA_LICENSE_FILES = COPYING
LIBADWAITA_INSTALL_STAGING = YES
LIBADWAITA_DEPENDENCIES = host-pkgconf gtk4 appstream

LIBADWAITA_CONF_OPTS = \
	-Dexamples=false \
	-Dtests=false \
	-Dintrospection=disabled \
	-Dvapi=false \
	-Dgtk_doc=false

$(eval $(meson-package))
