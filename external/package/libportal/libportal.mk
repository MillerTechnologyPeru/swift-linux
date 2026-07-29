################################################################################
#
# libportal
#
################################################################################

LIBPORTAL_VERSION = 0.9.1
LIBPORTAL_SOURCE = libportal-$(LIBPORTAL_VERSION).tar.xz
LIBPORTAL_SITE = https://github.com/flatpak/libportal/releases/download/$(LIBPORTAL_VERSION)
LIBPORTAL_LICENSE = LGPL-3.0+
LIBPORTAL_LICENSE_FILES = COPYING
LIBPORTAL_INSTALL_STAGING = YES
LIBPORTAL_DEPENDENCIES = host-pkgconf libgtk4 xdg-desktop-portal

LIBPORTAL_CONF_OPTS = -Dbackend-gtk3=disabled -Dbackend-gtk4=enabled -Dbackend-qt5=disabled -Ddocs=false -Dtests=false -Dvapi=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
LIBPORTAL_CONF_OPTS += -Dintrospection=enabled
LIBPORTAL_DEPENDENCIES += gobject-introspection
else
LIBPORTAL_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
