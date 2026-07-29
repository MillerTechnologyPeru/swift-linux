################################################################################
#
# lutris
#
# A Python/GTK application: the setuptools build installs the package and
# data files, nothing compiles. The tree also carries a meson build; the
# python-package infrastructure is the smaller hammer and produces the
# same site-packages layout.
#
################################################################################

LUTRIS_VERSION = 0.5.22
LUTRIS_SITE = $(call github,lutris,lutris,v$(LUTRIS_VERSION))
LUTRIS_SETUP_TYPE = setuptools
LUTRIS_LICENSE = GPL-3.0+
LUTRIS_LICENSE_FILES = LICENSE

$(eval $(python-package))
