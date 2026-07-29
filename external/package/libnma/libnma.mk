################################################################################
#
# libnma
#
################################################################################

LIBNMA_VERSION = 1.10.6
LIBNMA_SOURCE = libnma-$(LIBNMA_VERSION).tar.xz
LIBNMA_SITE = https://download.gnome.org/sources/libnma/1.10
LIBNMA_LICENSE = GPL-2.0+, LGPL-2.1+ (library)
LIBNMA_LICENSE_FILES = COPYING
LIBNMA_INSTALL_STAGING = YES
LIBNMA_DEPENDENCIES = host-pkgconf network-manager libgtk4

LIBNMA_CONF_OPTS = -Dlibnma_gtk4=true -Dgtk_doc=false -Dvapi=false -Dgcr=false -Dmobile_broadband_provider_info=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
LIBNMA_CONF_OPTS += -Dintrospection=enabled
LIBNMA_DEPENDENCIES += gobject-introspection
else
LIBNMA_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
