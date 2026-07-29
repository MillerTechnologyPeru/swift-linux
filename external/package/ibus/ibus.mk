################################################################################
#
# ibus
#
# The release *dist* tarball (not the tag archive): it carries the
# pregenerated unicode/emoji data and needs no autogen. GTK immodules and
# the standalone UI are off - on GNOME the shell is the UI; the daemon,
# libibus and the dconf backend are what matters.
#
################################################################################

IBUS_VERSION = 1.5.34
IBUS_SITE = https://github.com/ibus/ibus/releases/download/$(IBUS_VERSION)
IBUS_LICENSE = LGPL-2.1+
IBUS_LICENSE_FILES = COPYING
IBUS_INSTALL_STAGING = YES
IBUS_DEPENDENCIES = host-pkgconf libglib2 dconf

IBUS_CONF_OPTS = \
	--disable-gtk2 \
	--disable-gtk3 \
	--disable-gtk4 \
	--disable-xim \
	--disable-ui \
	--disable-setup \
	--disable-wayland \
	--disable-systemd-services \
	--disable-tests \
	--disable-emoji-dict \
	--disable-unicode-dict \
	--disable-python-library \
	--with-python=/bin/false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
IBUS_CONF_OPTS += --enable-introspection
IBUS_DEPENDENCIES += gobject-introspection
else
IBUS_CONF_OPTS += --disable-introspection
endif

$(eval $(autotools-package))
