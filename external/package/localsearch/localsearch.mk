################################################################################
#
# localsearch
#
################################################################################

LOCALSEARCH_VERSION = 3.8.2
LOCALSEARCH_SOURCE = localsearch-$(LOCALSEARCH_VERSION).tar.xz
LOCALSEARCH_SITE = https://download.gnome.org/sources/localsearch/3.8
LOCALSEARCH_LICENSE = GPL-2.0+
LOCALSEARCH_LICENSE_FILES = COPYING
LOCALSEARCH_INSTALL_STAGING = YES
LOCALSEARCH_DEPENDENCIES = host-pkgconf tinysparql libseccomp gexiv2

LOCALSEARCH_CONF_OPTS = -Dman=false -Dtests=false -Dbattery_detection=none

$(eval $(meson-package))
