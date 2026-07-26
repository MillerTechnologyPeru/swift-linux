################################################################################
#
# swaywm
#
# Sway built against basu rather than libsystemd, so the compositor can be
# used on a system without systemd. Upstream sway supports either provider
# through -Dsd-bus-provider; Buildroot's bundled sway package hardcodes
# libsystemd (and so depends on systemd), which is why this package exists.
#
################################################################################

SWAYWM_VERSION = 1.12
SWAYWM_SOURCE = sway-$(SWAYWM_VERSION).tar.gz
SWAYWM_SITE = https://github.com/swaywm/sway/releases/download/$(SWAYWM_VERSION)
SWAYWM_LICENSE = MIT
SWAYWM_LICENSE_FILES = LICENSE
SWAYWM_DEPENDENCIES = basu host-pkgconf wlroots json-c pcre2 cairo pango

SWAYWM_CONF_OPTS = \
	-Dwerror=false \
	-Dzsh-completions=false \
	-Dfish-completions=false \
	-Dman-pages=disabled \
	-Dsd-bus-provider=basu \
	-Dbash-completions=false \
	-Ddefault-wallpaper=false \
	-Dswaynag=false \
	-Dtray=disabled

ifeq ($(BR2_PACKAGE_GDK_PIXBUF),y)
SWAYWM_CONF_OPTS += -Dgdk-pixbuf=enabled
SWAYWM_DEPENDENCIES += gdk-pixbuf
else
SWAYWM_CONF_OPTS += -Dgdk-pixbuf=disabled
endif

ifeq ($(BR2_PACKAGE_SWAYWM_SWAYBAR),y)
SWAYWM_CONF_OPTS += -Dswaybar=true
else
SWAYWM_CONF_OPTS += -Dswaybar=false
endif

# XWayland: sway has no -Dxwayland meson option; it builds X11 support
# automatically when wlroots provides it and the xcb libraries are present
# (used to run X11 apps such as Steam under sway).
ifeq ($(BR2_PACKAGE_WLROOTS_XWAYLAND),y)
SWAYWM_DEPENDENCIES += xwayland libxcb xcb-util-wm
endif

$(eval $(meson-package))
