################################################################################
#
# libnotify
#
################################################################################

LIBNOTIFY_VERSION = 0.8.3
LIBNOTIFY_SOURCE = libnotify-$(LIBNOTIFY_VERSION).tar.xz
LIBNOTIFY_SITE = https://download.gnome.org/sources/libnotify/0.8
LIBNOTIFY_LICENSE = LGPL-2.1+
LIBNOTIFY_LICENSE_FILES = COPYING
LIBNOTIFY_INSTALL_STAGING = YES
LIBNOTIFY_DEPENDENCIES = host-pkgconf libglib2 gdk-pixbuf libgtk3

LIBNOTIFY_CONF_OPTS = \
	-Dtests=false \
	-Dintrospection=disabled \
	-Dman=false \
	-Dgtk_doc=false \
	-Ddocbook_docs=disabled

$(eval $(meson-package))
