################################################################################
#
# liblcf
#
# Library only, so it installs to staging for the easyrpg core to link
# against. Pinned to the release matching the player.
#
################################################################################

LIBLCF_VERSION = 0.8.1
LIBLCF_SITE = $(call github,EasyRPG,liblcf,$(LIBLCF_VERSION))
LIBLCF_LICENSE = MIT
LIBLCF_LICENSE_FILES = COPYING
LIBLCF_INSTALL_STAGING = YES
# Upstream's cmake refuses in-source builds outright.
LIBLCF_SUPPORTS_IN_SOURCE_BUILD = NO
LIBLCF_DEPENDENCIES = expat icu inih

LIBLCF_CONF_OPTS = \
	-DCMAKE_BUILD_TYPE=Release \
	-DLIBLCF_ENABLE_TOOLS=OFF \
	-DLIBLCF_ENABLE_TESTS=OFF \
	-DLIBLCF_WITH_XML=ON \
	-DLIBLCF_WITH_ICU=ON

$(eval $(cmake-package))
