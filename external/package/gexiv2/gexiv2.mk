################################################################################
#
# gexiv2
#
################################################################################

GEXIV2_VERSION = 0.14.6
GEXIV2_SOURCE = gexiv2-$(GEXIV2_VERSION).tar.xz
GEXIV2_SITE = https://download.gnome.org/sources/gexiv2/0.14
GEXIV2_LICENSE = GPL-2.0+
GEXIV2_LICENSE_FILES = COPYING
GEXIV2_INSTALL_STAGING = YES
GEXIV2_DEPENDENCIES = host-pkgconf exiv2

GEXIV2_CONF_OPTS = -Dpython3=false -Dvapi=false -Dtools=false -Dtests=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
GEXIV2_CONF_OPTS += -Dintrospection=enabled
GEXIV2_DEPENDENCIES += gobject-introspection
else
GEXIV2_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
