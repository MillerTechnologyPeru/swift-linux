################################################################################
#
# grim
#
# Screenshot utility for wlroots-based compositors, using wlr-screencopy.
# Buildroot has no grim package, and the compositor itself cannot capture its
# own output - without this there is no way to screenshot the running image
# except from outside the machine (which is not possible when the display is
# a GL scanout on the host GPU).
#
################################################################################

GRIM_VERSION = 1.5.0
GRIM_SOURCE = grim-v$(GRIM_VERSION).tar.gz
GRIM_SITE = https://gitlab.freedesktop.org/emersion/grim/-/archive/v$(GRIM_VERSION)
GRIM_LICENSE = MIT
GRIM_LICENSE_FILES = LICENSE
GRIM_DEPENDENCIES = host-pkgconf host-wayland wayland wayland-protocols libpng pixman

GRIM_CONF_OPTS = -Dman-pages=disabled

ifeq ($(BR2_PACKAGE_JPEG),y)
GRIM_DEPENDENCIES += jpeg
GRIM_CONF_OPTS += -Djpeg=enabled
else
GRIM_CONF_OPTS += -Djpeg=disabled
endif

$(eval $(meson-package))
