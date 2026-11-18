################################################################################
#
# rocknix-joypad
#
################################################################################

# The commit ROCKNIX's own packages/linux-drivers/rocknix-joypad pins.
ROCKNIX_JOYPAD_VERSION = ac1be0fa0c4e1f7feb9a900fc428d7ac6014029c
ROCKNIX_JOYPAD_SITE = $(call github,ROCKNIX,rocknix-joypad,$(ROCKNIX_JOYPAD_VERSION))
# Every source file carries SPDX GPL-2.0-or-later; the repository has no
# separate licence file.
ROCKNIX_JOYPAD_LICENSE = GPL-2.0+

# The upstream Makefile keys on DEVICE to pick which drivers to build. It must
# be set: left empty, its first ifeq compares two empty strings, matches, and
# builds only rocknix-joypad.ko, without rocknix-singleadc-joypad.ko, which
# boards like the R36S bind. Any value outside its lists builds both, which is
# what a family of mixed boards wants.
ROCKNIX_JOYPAD_MODULE_MAKE_OPTS = DEVICE=all

$(eval $(kernel-module))
$(eval $(generic-package))
