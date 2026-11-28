################################################################################
#
# hfsutils
#
################################################################################

# The last release, from 1998; Debian keeps its tarball.
HFSUTILS_VERSION = 3.2.6
HFSUTILS_SOURCE = hfsutils_$(HFSUTILS_VERSION).orig.tar.gz
HFSUTILS_SITE = https://deb.debian.org/debian/pool/main/h/hfsutils
HFSUTILS_LICENSE = GPL-2.0+
HFSUTILS_LICENSE_FILES = COPYING

# Only the command-line tools: no Tcl or Tk front ends.
HOST_HFSUTILS_CONF_OPTS = --without-tcl --without-tk

# Code from 1998, which today's compilers reject by default: functions used
# before they are declared, and pointer types it mixes freely.
HOST_HFSUTILS_CONF_ENV = \
	CFLAGS="$(HOST_CFLAGS) -std=gnu89 -Wno-error=implicit-function-declaration -Wno-error=implicit-int -Wno-error=incompatible-pointer-types"

# The tools are one program, hfsutil, which acts on the name it was run by.
# Upstream's install also wants its man page directories to exist already,
# so install the program and the names the images use by hand.
HOST_HFSUTILS_TOOLS = hattrib hcd hcopy hdel hdir hformat hls hmkdir hmount hpwd hrename hrmdir humount hvol

define HOST_HFSUTILS_INSTALL_CMDS
	$(INSTALL) -D -m 0755 $(@D)/hfsutil $(HOST_DIR)/bin/hfsutil
	$(foreach tool,$(HOST_HFSUTILS_TOOLS),
		ln -sf hfsutil $(HOST_DIR)/bin/$(tool))
endef

$(eval $(host-autotools-package))
