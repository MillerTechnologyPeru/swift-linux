################################################################################
#
# libgtop
#
################################################################################

LIBGTOP_VERSION = 2.41.3
LIBGTOP_SOURCE = libgtop-$(LIBGTOP_VERSION).tar.xz
LIBGTOP_SITE = https://download.gnome.org/sources/libgtop/2.41
LIBGTOP_LICENSE = GPL-2.0+
LIBGTOP_LICENSE_FILES = COPYING
LIBGTOP_INSTALL_STAGING = YES
LIBGTOP_DEPENDENCIES = host-pkgconf libglib2

LIBGTOP_CONF_OPTS = --disable-introspection

$(eval $(autotools-package))
