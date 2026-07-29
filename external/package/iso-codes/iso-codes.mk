################################################################################
#
# iso-codes
#
################################################################################

ISO_CODES_VERSION = 4.20.1
ISO_CODES_SOURCE = iso-codes_$(ISO_CODES_VERSION).orig.tar.xz
ISO_CODES_SITE = https://deb.debian.org/debian/pool/main/i/iso-codes
ISO_CODES_LICENSE = LGPL-2.1+
ISO_CODES_LICENSE_FILES = COPYING
ISO_CODES_INSTALL_STAGING = YES

$(eval $(autotools-package))
