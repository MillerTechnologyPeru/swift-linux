################################################################################
#
# xdg-desktop-portal-gtk
#
################################################################################

XDG_DESKTOP_PORTAL_GTK_VERSION = 1.15.3
XDG_DESKTOP_PORTAL_GTK_SITE = $(call github,flatpak,xdg-desktop-portal-gtk,$(XDG_DESKTOP_PORTAL_GTK_VERSION))
XDG_DESKTOP_PORTAL_GTK_LICENSE = LGPL-2.1+
XDG_DESKTOP_PORTAL_GTK_LICENSE_FILES = COPYING
XDG_DESKTOP_PORTAL_GTK_DEPENDENCIES = \
	host-pkgconf xdg-desktop-portal libgtk3

XDG_DESKTOP_PORTAL_GTK_CONF_OPTS = \
	-Dappchooser=disabled \
	-Dwallpaper=disabled

$(eval $(meson-package))
