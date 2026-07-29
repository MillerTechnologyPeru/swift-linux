################################################################################
#
# vte4
#
################################################################################

VTE4_VERSION = 0.78.6
VTE4_SOURCE = vte-$(VTE4_VERSION).tar.xz
VTE4_SITE = https://download.gnome.org/sources/vte/0.78
VTE4_LICENSE = LGPL-3.0+
VTE4_LICENSE_FILES = COPYING.LGPL3
VTE4_INSTALL_STAGING = YES
VTE4_DEPENDENCIES = host-pkgconf libgtk4 pcre2 lz4

VTE4_CONF_OPTS = -Dgtk3=false -Dgtk4=true -Dvapi=false -Ddocs=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
VTE4_CONF_OPTS += -Dgir=enabled
VTE4_DEPENDENCIES += gobject-introspection
else
VTE4_CONF_OPTS += -Dgir=disabled
endif

$(eval $(meson-package))
