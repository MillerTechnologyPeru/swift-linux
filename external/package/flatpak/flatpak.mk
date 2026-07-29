################################################################################
#
# flatpak
#
# Built against the system bubblewrap and xdg-dbus-proxy instead of the
# bundled copies (system_bubblewrap/system_dbus_proxy), and without the
# polkit system helper: installations are either per-user or done as root,
# which is how an appliance image administers itself anyway.
#
################################################################################

FLATPAK_VERSION = 1.18.0
FLATPAK_SITE = https://github.com/flatpak/flatpak/releases/download/$(FLATPAK_VERSION)
FLATPAK_SOURCE = flatpak-$(FLATPAK_VERSION).tar.xz
FLATPAK_LICENSE = LGPL-2.1+
FLATPAK_LICENSE_FILES = COPYING
FLATPAK_INSTALL_STAGING = YES
FLATPAK_DEPENDENCIES = libostree bubblewrap xdg-dbus-proxy json-glib \
	appstream libxmlb libfuse3 libgpgme libseccomp zstd libcurl dbus \
	host-pkgconf

# profile_dir is where the XDG_DATA_DIRS snippet lands that makes desktop
# environments see exported .desktop files and icons; /etc/profile.d is
# also the upstream default (empty resolves to sysconfdir/profile.d), but
# the desktop integration is load-bearing enough to pin explicitly.
FLATPAK_CONF_OPTS = \
	-Dprofile_dir=/etc/profile.d \
	-Dsystem_bubblewrap=bwrap \
	-Dsystem_dbus_proxy=xdg-dbus-proxy \
	-Dsystem_helper=disabled \
	-Dselinux_module=disabled \
	-Dmalcontent=disabled \
	-Ddconf=disabled \
	-Dseccomp=enabled \
	-Dlibzstd=enabled \
	-Dxauth=disabled \
	-Dwayland_security_context=disabled \
	-Dsystemd=disabled \
	-Dgir=disabled \
	-Dgtkdoc=disabled \
	-Dman=disabled \
	-Ddocbook_docs=disabled \
	-Dtests=false \
	-Dinstalled_tests=false

$(eval $(meson-package))
