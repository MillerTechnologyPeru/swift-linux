################################################################################
#
# libei
#
################################################################################

LIBEI_VERSION = 1.3.0
LIBEI_SOURCE = libei-$(LIBEI_VERSION).tar.gz
LIBEI_SITE = https://gitlab.freedesktop.org/libinput/libei/-/archive/$(LIBEI_VERSION)
LIBEI_LICENSE = MIT
LIBEI_LICENSE_FILES = COPYING
LIBEI_INSTALL_STAGING = YES
LIBEI_DEPENDENCIES = host-pkgconf libevdev host-python3 host-python-jinja2 host-python-attrs

LIBEI_CONF_OPTS = -Dtests=disabled -Ddocumentation=[] -Dliboeffis=enabled

$(eval $(meson-package))
