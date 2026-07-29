################################################################################
#
# totem-pl-parser
#
################################################################################

TOTEM_PL_PARSER_VERSION = 3.26.7
TOTEM_PL_PARSER_SOURCE = totem-pl-parser-$(TOTEM_PL_PARSER_VERSION).tar.xz
TOTEM_PL_PARSER_SITE = https://download.gnome.org/sources/totem-pl-parser/3.26
TOTEM_PL_PARSER_LICENSE = LGPL-2.0+
TOTEM_PL_PARSER_LICENSE_FILES = COPYING.LIB
TOTEM_PL_PARSER_INSTALL_STAGING = YES
TOTEM_PL_PARSER_DEPENDENCIES = host-pkgconf libxml2 libsoup3

TOTEM_PL_PARSER_CONF_OPTS = -Denable-gtk-doc=false

$(eval $(meson-package))
