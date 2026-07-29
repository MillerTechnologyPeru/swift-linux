################################################################################
#
# appstream
#
################################################################################

APPSTREAM_VERSION = 1.0.6
APPSTREAM_SOURCE = AppStream-$(APPSTREAM_VERSION).tar.xz
APPSTREAM_SITE = https://www.freedesktop.org/software/appstream/releases
APPSTREAM_LICENSE = LGPL-2.1+
APPSTREAM_LICENSE_FILES = COPYING
APPSTREAM_INSTALL_STAGING = YES
APPSTREAM_DEPENDENCIES = host-pkgconf libglib2 libxmlb libyaml libcurl

APPSTREAM_CONF_OPTS = \
	-Dstemming=false \
	-Dgir=false \
	-Dapidocs=false \
	-Ddocs=false \
	-Dcompose=false \
	-Dvapi=false \
	-Dsystemd=false \
	-Dsvg-support=false

$(eval $(meson-package))
