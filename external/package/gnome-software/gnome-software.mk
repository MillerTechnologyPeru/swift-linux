################################################################################
#
# gnome-software
#
# The 47 series, matching the GNOME 47 stack in this tree. Every backend
# except flatpak is off: there is no packagekit, no snap, no apt and no
# rpm-ostree on this image, and fwupd/webapps/parental-controls pull
# daemons the image does not run.
#
################################################################################

GNOME_SOFTWARE_VERSION_MAJOR = 47
GNOME_SOFTWARE_VERSION = $(GNOME_SOFTWARE_VERSION_MAJOR).3
GNOME_SOFTWARE_SITE = https://download.gnome.org/sources/gnome-software/$(GNOME_SOFTWARE_VERSION_MAJOR)
GNOME_SOFTWARE_SOURCE = gnome-software-$(GNOME_SOFTWARE_VERSION).tar.xz
GNOME_SOFTWARE_LICENSE = GPL-2.0+
GNOME_SOFTWARE_LICENSE_FILES = COPYING
GNOME_SOFTWARE_DEPENDENCIES = libgtk4 libadwaita flatpak appstream libxmlb \
	json-glib libsoup3 gsettings-desktop-schemas iso-codes host-pkgconf

GNOME_SOFTWARE_CONF_OPTS = \
	-Dflatpak=true \
	-Dpackagekit=false \
	-Dfwupd=false \
	-Dmalcontent=false \
	-Drpm_ostree=false \
	-Dapt=false \
	-Dsnap=false \
	-Dgudev=false \
	-Dwebapps=false \
	-Dhardcoded_foss_webapps=false \
	-Dhardcoded_proprietary_webapps=false \
	-Dexternal_appstream=false \
	-Dsysprof=disabled \
	-Dgtk_doc=false \
	-Dman=false \
	-Dpolkit=false \
	-Deos_updater=false \
	-Ddkms=false \
	-Dmogwai=false \
	-Dtests=false

$(eval $(meson-package))
