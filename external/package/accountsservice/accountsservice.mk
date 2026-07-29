################################################################################
#
# accountsservice
#
################################################################################

ACCOUNTSSERVICE_VERSION = 23.13.9
ACCOUNTSSERVICE_SOURCE = accountsservice-$(ACCOUNTSSERVICE_VERSION).tar.xz
ACCOUNTSSERVICE_SITE = https://www.freedesktop.org/software/accountsservice
ACCOUNTSSERVICE_LICENSE = GPL-3.0+
ACCOUNTSSERVICE_LICENSE_FILES = COPYING
ACCOUNTSSERVICE_INSTALL_STAGING = YES
ACCOUNTSSERVICE_DEPENDENCIES = host-pkgconf polkit dbus elogind

ACCOUNTSSERVICE_CONF_OPTS = -Dsystemd=false -Delogind=true -Dadmin_group=wheel -Ddocbook=false -Dgtk_doc=false -Dvapi=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
ACCOUNTSSERVICE_CONF_OPTS += -Dintrospection=enabled
ACCOUNTSSERVICE_DEPENDENCIES += gobject-introspection
else
ACCOUNTSSERVICE_CONF_OPTS += -Dintrospection=disabled
endif

$(eval $(meson-package))
