################################################################################
#
# colord
#
################################################################################

COLORD_VERSION = 1.4.8
COLORD_SOURCE = colord-$(COLORD_VERSION).tar.xz
COLORD_SITE = https://www.freedesktop.org/software/colord/releases
COLORD_LICENSE = GPL-2.0+, LGPL-2.1+ (libraries)
COLORD_LICENSE_FILES = COPYING
COLORD_INSTALL_STAGING = YES
COLORD_DEPENDENCIES = host-pkgconf lcms2 libgudev libgusb sqlite dbus

COLORD_CONF_OPTS = -Dman=false -Ddocs=false -Dbash_completion=false -Dsystemd=false -Dargyllcms_sensor=false -Dsession_example=false -Dtests=false -Dinstalled_tests=false -Dvapi=false -Dprint_profiles=false -Dlibcolordcompat=false -Ddaemon_user=colord

# gnome-shell drives everything through GObject introspection typelibs, so
# build them whenever the config carries gobject-introspection.
ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
COLORD_CONF_OPTS += -Dintrospection=enabled
COLORD_DEPENDENCIES += gobject-introspection
else
COLORD_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
