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

# Buildroot's luajit package symlinks /usr/bin/lua to itself; luajit-embed
# (which replaced it, see ports/package/libs/luajit-embed) does not, because
# lua 5.4 owns that name. An incremental target/ keeps the old symlink,
# where it shadows the real interpreter - so drop it and let lua reinstall
# its own binary.
if [ -L "${TARGET_DIR}/usr/bin/lua" ]; then
	rm -f "${TARGET_DIR}/usr/bin/lua"
fi

# Board metadata, Cadmium-style: one sourceable KEY=VALUE file per board
# (see util/gen-boardinfo.py), installed as a full tree so tooling on the
# image can identify any device this distribution supports - the
# installer, and anything that wants to match a running device against
# /proc/device-tree/compatible. /usr/share/boardinfo/current names the
# board this image was BUILT for, recovered from the board overlay path
# in the Buildroot configuration.
BOARDS_SRC="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "${TARGET_DIR}/usr/share/boardinfo"
for bi in "${BOARDS_SRC}"/*/boardinfo; do
	[ -f "${bi}" ] || continue
	bname="$(basename "$(dirname "${bi}")")"
	install -m 0644 "${bi}" "${TARGET_DIR}/usr/share/boardinfo/${bname}"
done
if [ -n "${BR2_CONFIG}" ] && [ -f "${BR2_CONFIG}" ]; then
	cur=$(sed -n 's|.*sdk/board/\([a-z0-9._-]*\)/rootfs-overlay.*|\1|p' "${BR2_CONFIG}" | 		grep -v '^common$' | head -1)
	if [ -n "${cur}" ] && [ -f "${TARGET_DIR}/usr/share/boardinfo/${cur}" ]; then
		ln -sf "${cur}" "${TARGET_DIR}/usr/share/boardinfo/current"
	fi
fi

# Mountpoints for the state that S15data bind-mounts off the data partition.
# The rootfs is read-only, so they have to exist in the image (BlueZ ships
# /var/lib/bluetooth itself; NetworkManager does not create its directory).
mkdir -p "${TARGET_DIR}/var/lib/bluetooth" \
         "${TARGET_DIR}/var/lib/NetworkManager" \
         "${TARGET_DIR}/var/lib/flatpak"
chmod 0700 "${TARGET_DIR}/var/lib/bluetooth" \
           "${TARGET_DIR}/var/lib/NetworkManager"

# PortMaster moved from the Tools group to the seeded Apps entries (the
# app managers live together there); the package no longer installs this,
# but an incremental target/ keeps the old copy.
rm -f "${TARGET_DIR}/usr/share/es-tools/PortMaster.sh"

# Remove files from earlier layouts: ConnMan was replaced by
# NetworkManager, and Buildroot leaves a deselected package's files in an
# incremental target/.
rm -rf "${TARGET_DIR}/var/lib/connman" \
       "${TARGET_DIR}/etc/init.d/S45connman" \
       "${TARGET_DIR}/usr/sbin/connmand" \
       "${TARGET_DIR}/usr/bin/connmanctl"

# OpenRC's mtab service only tries to (re)create the /etc/mtab symlink,
# which the image already ships; on the read-only rootfs the attempt just
# prints "/etc is not writable" at every boot. Drop it from the boot
# runlevel - the symlink is baked in.
rm -f "${TARGET_DIR}/etc/runlevels/boot/mtab"

# OpenRC mounts the unified cgroup2 hierarchy on /sys/fs/cgroup during
# sysinit, so the cgroupfs service Buildroot installs for non-systemd
# inits (S30cgroupfs2, from the podman selection) always fails with
# "Device or resource busy". Redundant here - remove it.
rm -f "${TARGET_DIR}/etc/init.d/S30cgroupfs2"

# OpenRC's seedrng service runs in the boot runlevel, before S15data mounts
# the data partition, so its only writable target does not exist yet and it
# fails with "Unable to create seed directory: Read-only file system" on
# every boot. S16seedrng does the same job afterwards against /data, where
# the seed can actually persist - drop the boot-runlevel copy.
rm -f "${TARGET_DIR}/etc/runlevels/boot/seedrng"
# And the SysV half of the same thing, which the line above does not reach.
# urandom-scripts installs /etc/init.d/S01seedrng; it is not selected any
# more (BR2_PACKAGE_INITSCRIPTS comes with BR2_INIT_BUSYBOX, and this is
# OpenRC), but Buildroot leaves a deselected package's files in an
# incremental target/, and the seeded trees carry one built when it was.
# sysv-rcs then runs it from the default runlevel and it fails exactly as
# the OpenRC service did:
#
#   * Starting /etc/init.d/S01seedrng
#   seedrng: Unable to create seed directory: Read-only file system
#
# Verified in QEMU against the image the nightly published: S01seedrng ran
# and failed, S16seedrng ran afterwards and is the one that matters.
rm -f "${TARGET_DIR}/etc/init.d/S01seedrng"
