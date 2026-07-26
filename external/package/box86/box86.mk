################################################################################
#
# box86
#
# x86 (32-bit) emulator/translator for 32-bit ARM hosts. ARM_DYNAREC enables
# the just-in-time translator; without it box86 falls back to an interpreter.
#
################################################################################

BOX86_VERSION = 0.3.8
BOX86_SITE = $(call github,ptitSeb,box86,v$(BOX86_VERSION))
BOX86_LICENSE = MIT
BOX86_LICENSE_FILES = LICENSE

BOX86_CONF_OPTS = \
	-DCMAKE_BUILD_TYPE=Release \
	-DARM_DYNAREC=ON

$(eval $(cmake-package))
