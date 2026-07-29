################################################################################
#
# libgusb
#
################################################################################

LIBGUSB_VERSION = 0.4.9
LIBGUSB_SOURCE = libgusb-$(LIBGUSB_VERSION).tar.gz
LIBGUSB_SITE = $(call github,hughsie,libgusb,$(LIBGUSB_VERSION))
LIBGUSB_LICENSE = LGPL-2.1+
LIBGUSB_LICENSE_FILES = COPYING
LIBGUSB_INSTALL_STAGING = YES
LIBGUSB_DEPENDENCIES = host-pkgconf libusb json-glib

LIBGUSB_CONF_OPTS = -Dtests=false -Ddocs=false -Dvapi=false -Dintrospection=false

$(eval $(meson-package))
