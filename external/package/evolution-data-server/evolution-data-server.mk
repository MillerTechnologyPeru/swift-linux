################################################################################
#
# evolution-data-server
#
# Needs libical built with its GLib bindings (ICAL_GLIB) - see the note in
# the GNOME frontend fragment.
#
################################################################################

EVOLUTION_DATA_SERVER_VERSION = 3.54.3
EVOLUTION_DATA_SERVER_SOURCE = evolution-data-server-$(EVOLUTION_DATA_SERVER_VERSION).tar.xz
EVOLUTION_DATA_SERVER_SITE = https://download.gnome.org/sources/evolution-data-server/3.54
EVOLUTION_DATA_SERVER_LICENSE = LGPL-2.1
EVOLUTION_DATA_SERVER_LICENSE_FILES = COPYING
EVOLUTION_DATA_SERVER_INSTALL_STAGING = YES
EVOLUTION_DATA_SERVER_DEPENDENCIES = \
	host-pkgconf libical libsecret libsoup3 json-glib sqlite icu gcr4

EVOLUTION_DATA_SERVER_CONF_OPTS = \
	-DENABLE_GOA=OFF \
	-DENABLE_EXAMPLES=OFF \
	-DENABLE_TESTS=OFF \
	-DENABLE_GTK=OFF \
	-DENABLE_GTK4=OFF \
	-DENABLE_OAUTH2_WEBKITGTK=OFF \
	-DENABLE_OAUTH2_WEBKITGTK4=OFF \
	-DENABLE_CANBERRA=OFF \
	-DENABLE_WEATHER=OFF \
	-DENABLE_LDAP=OFF \
	-DENABLE_SMIME=OFF \
	-DWITH_LIBDB=OFF \
	-DENABLE_VALA_BINDINGS=OFF \
	-DENABLE_DOT_LOCKING=OFF \
	-DENABLE_GTK_DOC=OFF

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
EVOLUTION_DATA_SERVER_CONF_OPTS += -DENABLE_INTROSPECTION=ON
EVOLUTION_DATA_SERVER_DEPENDENCIES += gobject-introspection
else
EVOLUTION_DATA_SERVER_CONF_OPTS += -DENABLE_INTROSPECTION=OFF
endif

$(eval $(cmake-package))
