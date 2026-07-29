################################################################################
#
# modemmanager
#
################################################################################

MODEMMANAGER_VERSION = 1.24.2
MODEMMANAGER_SOURCE = ModemManager-$(MODEMMANAGER_VERSION).tar.bz2
MODEMMANAGER_SITE = https://gitlab.freedesktop.org/mobile-broadband/ModemManager/-/archive/$(MODEMMANAGER_VERSION)
MODEMMANAGER_LICENSE = GPL-2.0+, LGPL-2.1+ (libmm-glib)
MODEMMANAGER_LICENSE_FILES = COPYING
MODEMMANAGER_INSTALL_STAGING = YES
MODEMMANAGER_DEPENDENCIES = host-pkgconf libgudev dbus

MODEMMANAGER_CONF_OPTS = -Dmbim=false -Dqmi=false -Dqrtr=false -Dbash_completion=false -Dman=false -Dtests=false -Dexamples=false -Dvapi=false -Dsystemd_suspend_resume=false -Dsystemd_journal=false -Dpowerd_suspend_resume=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
MODEMMANAGER_CONF_OPTS += -Dintrospection=enabled
MODEMMANAGER_DEPENDENCIES += gobject-introspection
else
MODEMMANAGER_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
