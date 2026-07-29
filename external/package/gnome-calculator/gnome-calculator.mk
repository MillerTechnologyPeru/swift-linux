################################################################################
#
# gnome-calculator
#
################################################################################

GNOME_CALCULATOR_VERSION = 47.3
GNOME_CALCULATOR_SOURCE = gnome-calculator-$(GNOME_CALCULATOR_VERSION).tar.xz
GNOME_CALCULATOR_SITE = https://download.gnome.org/sources/gnome-calculator/47
GNOME_CALCULATOR_LICENSE = GPL-3.0+
GNOME_CALCULATOR_LICENSE_FILES = COPYING
GNOME_CALCULATOR_DEPENDENCIES = host-pkgconf host-vala libgtk4 libadwaita gtksourceview5 libsoup3 libgee mpfr gmp

GNOME_CALCULATOR_CONF_OPTS = -Ddisable-ui=false

$(eval $(meson-package))
