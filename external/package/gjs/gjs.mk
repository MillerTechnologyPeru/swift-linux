################################################################################
#
# gjs
#
################################################################################

GJS_VERSION = 1.82.3
GJS_SOURCE = gjs-$(GJS_VERSION).tar.xz
GJS_SITE = https://download.gnome.org/sources/gjs/1.82
GJS_LICENSE = MIT, LGPL-2.0+
GJS_LICENSE_FILES = COPYING COPYING.LGPL
GJS_INSTALL_STAGING = YES
GJS_DEPENDENCIES = host-pkgconf mozjs128 gobject-introspection cairo libffi

GJS_CONF_OPTS = \
	-Dinstalled_tests=false \
	-Dskip_dbus_tests=true \
	-Dskip_gtk_tests=true \
	-Dprofiler=disabled \
	-Dreadline=disabled

$(eval $(meson-package))
