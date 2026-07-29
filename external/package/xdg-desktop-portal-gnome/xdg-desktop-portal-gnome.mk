################################################################################
#
# xdg-desktop-portal-gnome
#
################################################################################

XDG_DESKTOP_PORTAL_GNOME_VERSION = 47.3
XDG_DESKTOP_PORTAL_GNOME_SOURCE = xdg-desktop-portal-gnome-$(XDG_DESKTOP_PORTAL_GNOME_VERSION).tar.xz
XDG_DESKTOP_PORTAL_GNOME_SITE = https://download.gnome.org/sources/xdg-desktop-portal-gnome/47
XDG_DESKTOP_PORTAL_GNOME_LICENSE = LGPL-2.1+
XDG_DESKTOP_PORTAL_GNOME_LICENSE_FILES = COPYING
XDG_DESKTOP_PORTAL_GNOME_DEPENDENCIES = \
	host-pkgconf xdg-desktop-portal libgtk4 libadwaita gnome-desktop \
	gsettings-desktop-schemas

$(eval $(meson-package))
