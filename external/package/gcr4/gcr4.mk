################################################################################
#
# gcr4
#
# Installed as "gcr4" to leave room for Buildroot's gcr (the GTK3-era v3
# line) if it ever gets enabled; the two are parallel-installable.
#
################################################################################

GCR4_VERSION = 4.3.0
GCR4_SOURCE = gcr-$(GCR4_VERSION).tar.xz
GCR4_SITE = https://download.gnome.org/sources/gcr/4.3
GCR4_LICENSE = LGPL-2.1+
GCR4_LICENSE_FILES = COPYING
GCR4_INSTALL_STAGING = YES
GCR4_DEPENDENCIES = host-pkgconf libglib2 p11-kit libgcrypt

GCR4_CONF_OPTS = \
	-Dgtk4=false \
	-Dgtk_doc=false \
	-Dssh_agent=false \
	-Dsystemd=disabled \
	-Dvapi=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
GCR4_CONF_OPTS += -Dintrospection=true
GCR4_DEPENDENCIES += gobject-introspection
else
GCR4_CONF_OPTS += -Dintrospection=false
endif

$(eval $(meson-package))
