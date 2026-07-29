################################################################################
#
# xdg-desktop-portal
#
################################################################################

XDG_DESKTOP_PORTAL_VERSION = 1.18.4
XDG_DESKTOP_PORTAL_SITE = $(call github,flatpak,xdg-desktop-portal,$(XDG_DESKTOP_PORTAL_VERSION))
XDG_DESKTOP_PORTAL_LICENSE = LGPL-2.1+
XDG_DESKTOP_PORTAL_LICENSE_FILES = COPYING
XDG_DESKTOP_PORTAL_DEPENDENCIES = \
	host-pkgconf libglib2 json-glib libfuse3 pipewire

XDG_DESKTOP_PORTAL_CONF_OPTS = \
	-Dflatpak-interfaces=disabled \
	-Dgeolocation=disabled \
	-Dsystemd=disabled \
	-Ddocbook-docs=disabled \
	-Dman-pages=disabled \
	-Dtests=disabled

$(eval $(meson-package))
