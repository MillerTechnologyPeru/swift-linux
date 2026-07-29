################################################################################
#
# libwacom
#
################################################################################

LIBWACOM_VERSION = 2.19.1
LIBWACOM_SOURCE = libwacom-$(LIBWACOM_VERSION).tar.gz
LIBWACOM_SITE = $(call github,linuxwacom,libwacom,libwacom-$(LIBWACOM_VERSION))
LIBWACOM_LICENSE = MIT
LIBWACOM_LICENSE_FILES = COPYING
LIBWACOM_INSTALL_STAGING = YES
LIBWACOM_DEPENDENCIES = host-pkgconf libgudev libevdev

LIBWACOM_CONF_OPTS = -Dtests=disabled -Ddocumentation=disabled

$(eval $(meson-package))
