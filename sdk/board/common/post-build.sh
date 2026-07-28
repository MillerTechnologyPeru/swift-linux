#!/bin/sh
# Shared (arch/board independent) post-build tweaks.
set -e
TARGET_DIR="$1"

# /etc/inittab (busybox pid 1 handing over to OpenRC, tty1 autologin, no rw
# remount of /) is owned by the rootfs overlay now - nothing to edit here.

# The rootfs is mounted read-only, so DHCP cannot rewrite /etc/resolv.conf.
# Point it at the /tmp tmpfs instead.
if [ ! -L "${TARGET_DIR}/etc/resolv.conf" ]; then
	rm -f "${TARGET_DIR}/etc/resolv.conf"
	ln -s /tmp/resolv.conf "${TARGET_DIR}/etc/resolv.conf"
fi

# Remove files from earlier layouts. The rootfs overlay only adds files, so
# anything renamed or replaced would otherwise linger in an incremental build.
rm -f "${TARGET_DIR}/etc/init.d/S05data"
# Pre-OpenRC eudev installed S10udevd; under OpenRC udev is started from the
# sysinit runlevel instead, and a lingering S10udevd would start a second
# udevd from sysv-rcs.
rm -f "${TARGET_DIR}/etc/init.d/S10udevd"
rm -f "${TARGET_DIR}/usr/bin/weston-session" \
      "${TARGET_DIR}/etc/profile.d/weston.sh"
rm -rf "${TARGET_DIR}/etc/xdg/weston"
# Weston was replaced by sway. Buildroot leaves the files of a deselected
# package in an incremental target/, so drop them explicitly.
rm -rf "${TARGET_DIR}"/usr/bin/weston*
rm -rf "${TARGET_DIR}/usr/lib/weston" "${TARGET_DIR}/usr/share/weston"
# libweston-<abi> is a directory, so this must be rm -rf, not rm -f.
rm -rf "${TARGET_DIR}"/usr/lib/libweston*

# Mountpoints for the state that S15data bind-mounts off the data partition.
# The rootfs is read-only, so they have to exist in the image (BlueZ ships
# /var/lib/bluetooth itself, ConnMan does not create its directory).
mkdir -p "${TARGET_DIR}/var/lib/bluetooth" "${TARGET_DIR}/var/lib/connman"
chmod 0700 "${TARGET_DIR}/var/lib/bluetooth"
