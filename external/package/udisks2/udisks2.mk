################################################################################
#
# udisks2
#
################################################################################

UDISKS2_VERSION = 2.10.1
UDISKS2_SOURCE = udisks-$(UDISKS2_VERSION).tar.bz2
UDISKS2_SITE = https://github.com/storaged-project/udisks/releases/download/udisks-$(UDISKS2_VERSION)
UDISKS2_LICENSE = GPL-2.0+, LGPL-2.0+ (libudisks)
UDISKS2_LICENSE_FILES = COPYING
UDISKS2_INSTALL_STAGING = YES
UDISKS2_DEPENDENCIES = host-pkgconf libblockdev libatasmart libgudev polkit acl dbus

UDISKS2_CONF_OPTS = --disable-lvm2 --disable-btrfs --disable-introspection --disable-man --disable-gtk-doc

$(eval $(autotools-package))
