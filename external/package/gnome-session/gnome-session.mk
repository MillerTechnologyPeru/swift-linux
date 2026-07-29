################################################################################
#
# gnome-session
#
# -Dsystemd_session=disable selects the builtin session manager: on a
# systemd-free image the session is started by gnome-session itself
# rather than systemd user units.
#
################################################################################

GNOME_SESSION_VERSION = 47.0.1
GNOME_SESSION_SOURCE = gnome-session-$(GNOME_SESSION_VERSION).tar.xz
GNOME_SESSION_SITE = https://download.gnome.org/sources/gnome-session/47
GNOME_SESSION_LICENSE = GPL-2.0+
GNOME_SESSION_LICENSE_FILES = COPYING
GNOME_SESSION_DEPENDENCIES = \
	host-pkgconf libglib2 upower json-glib elogind \
	gsettings-desktop-schemas gnome-desktop

GNOME_SESSION_CONF_OPTS = \
	-Dsystemd_session=disable \
	-Dsystemd_journal=false \
	-Ddocbook=false \
	-Dman=false

$(eval $(meson-package))
