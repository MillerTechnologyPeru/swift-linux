################################################################################
#
# gnome-shell
#
################################################################################

GNOME_SHELL_VERSION = 47.10
GNOME_SHELL_SOURCE = gnome-shell-$(GNOME_SHELL_VERSION).tar.xz
GNOME_SHELL_SITE = https://download.gnome.org/sources/gnome-shell/47
GNOME_SHELL_LICENSE = GPL-2.0+
GNOME_SHELL_LICENSE_FILES = COPYING
GNOME_SHELL_DEPENDENCIES = \
	host-pkgconf mutter gjs gnome-desktop gcr4 evolution-data-server \
	ibus polkit libgtk4 gsettings-desktop-schemas host-python3 \
	host-libglib2 network-manager libsecret

GNOME_SHELL_CONF_OPTS = \
	-Dsystemd=false \
	-Dnetworkmanager=true \
	-Dcamera_monitor=false \
	-Dextensions_app=false \
	-Dgtk_doc=false \
	-Dman=false \
	-Dtests=disabled \
	-Dportal_helper=false

$(eval $(meson-package))
