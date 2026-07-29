################################################################################
#
# elogind
#
# The logind piece of the GNOME-on-OpenRC plan (see
# sdk/defconfig/frontend/gnome.config): mutter and gnome-shell require an
# org.freedesktop.login1 provider, and elogind is that provider on every
# systemd-free distro that ships GNOME. Versions track systemd's numbering.
#
# cgroup controller: elogind can manage its own cgroup hierarchy; the
# "unified" default matches the cgroupfs-v2 mount this image already does
# for podman.
#
################################################################################

ELOGIND_VERSION = 257.16
ELOGIND_SITE = $(call github,elogind,elogind,v$(ELOGIND_VERSION))
ELOGIND_LICENSE = LGPL-2.1+ (library), GPL-2.0+ (daemon)
ELOGIND_LICENSE_FILES = LICENSES/LGPL-2.1-or-later.txt LICENSES/GPL-2.0-or-later.txt
ELOGIND_INSTALL_STAGING = YES
ELOGIND_DEPENDENCIES = host-pkgconf host-gperf libcap udev dbus

ELOGIND_CONF_OPTS = \
	-Dmode=release \
	-Dcgroup-controller=elogind \
	-Ddefault-hierarchy=unified \
	-Dman=disabled \
	-Dhtml=disabled \
	-Dpam=disabled \
	-Dselinux=disabled \
	-Dacl=disabled \
	-Dsmack=disabled \
	-Dutmp=false \
	-Dbashcompletiondir=no \
	-Dzshcompletiondir=no

$(eval $(meson-package))
