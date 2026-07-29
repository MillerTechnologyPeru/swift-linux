################################################################################
#
# gnome-control-center
#
################################################################################

GNOME_CONTROL_CENTER_VERSION = 47.7
GNOME_CONTROL_CENTER_SOURCE = gnome-control-center-$(GNOME_CONTROL_CENTER_VERSION).tar.xz
GNOME_CONTROL_CENTER_SITE = https://download.gnome.org/sources/gnome-control-center/47
GNOME_CONTROL_CENTER_LICENSE = GPL-2.0+
GNOME_CONTROL_CENTER_LICENSE_FILES = COPYING
GNOME_CONTROL_CENTER_DEPENDENCIES = host-pkgconf libgtk4 libadwaita accountsservice colord-gtk cups gnome-bluetooth gnome-desktop gnome-online-accounts gnome-settings-daemon gsound libgtop libgudev libnma libpwquality libwacom libxml2 modem-manager network-manager polkit pulseaudio udisks2 upower ibus libkrb5

GNOME_CONTROL_CENTER_CONF_OPTS = -Ddocumentation=false -Dtests=false -Dibus=true -Dsnap=false -Dmalcontent=false

$(eval $(meson-package))
