################################################################################
#
# gnome-settings-daemon
#
# The volume-control helper (gvc, bundled in the tarball) talks libpulse:
# on this image the PulseAudio *client* library is served by
# pipewire-pulse, so the pulseaudio package is needed only for libpulse -
# its daemon stays disabled. Smartcard, cups and network-manager
# integrations off, matching the image.
#
################################################################################

GNOME_SETTINGS_DAEMON_VERSION = 47.2
GNOME_SETTINGS_DAEMON_SOURCE = gnome-settings-daemon-$(GNOME_SETTINGS_DAEMON_VERSION).tar.xz
GNOME_SETTINGS_DAEMON_SITE = https://download.gnome.org/sources/gnome-settings-daemon/47
GNOME_SETTINGS_DAEMON_LICENSE = GPL-2.0+
GNOME_SETTINGS_DAEMON_LICENSE_FILES = COPYING
GNOME_SETTINGS_DAEMON_DEPENDENCIES = \
	host-pkgconf colord libgweather geocode-glib gnome-desktop \
	libnotify libwacom upower polkit pulseaudio elogind \
	gsettings-desktop-schemas

GNOME_SETTINGS_DAEMON_CONF_OPTS = \
	-Dsystemd=false \
	-Dsmartcard=false \
	-Dcups=false \
	-Dnetwork_manager=false \
	-Dusb-protection=false \
	-Drfkill=false \
	-Dwwan=false

$(eval $(meson-package))
