################################################################################
#
# epiphany
#
################################################################################

EPIPHANY_VERSION = 47.7
EPIPHANY_SOURCE = epiphany-$(EPIPHANY_VERSION).tar.xz
EPIPHANY_SITE = https://download.gnome.org/sources/epiphany/47
EPIPHANY_LICENSE = GPL-3.0+
EPIPHANY_LICENSE_FILES = COPYING
EPIPHANY_DEPENDENCIES = host-pkgconf libgtk4 libadwaita webkitgtk json-glib libsoup3 gcr4 libportal iso-codes gsettings-desktop-schemas nettle libarchive sqlite

EPIPHANY_CONF_OPTS = -Dunit_tests=disabled -Ddeveloper_mode=false -Dnetwork_tests=disabled

$(eval $(meson-package))
