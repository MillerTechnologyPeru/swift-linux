#!/bin/sh
# Shared (arch/board independent) post-build tweaks:
#   - autologin the default user on tty1, the VT Weston runs on.
set -e
TARGET_DIR="$1"
INITTAB="${TARGET_DIR}/etc/inittab"

[ -f "${INITTAB}" ] || exit 0

# Drop any stock getty on tty1 and any previous autologin entry we added,
# then install our autologin entry (idempotent across rebuilds).
sed -i '\#getty.*tty1#d' "${INITTAB}"
sed -i '\#autologin on tty1#d' "${INITTAB}"

cat >> "${INITTAB}" <<'EOF'

# autologin on tty1
tty1::respawn:/sbin/getty -n -l /usr/bin/autologin -L tty1 0 linux
EOF

# Keep the rootfs read-only: busybox's stock inittab remounts / read-write
# during sysinit, which silently undoes the kernel's "ro" mount.
sed -i '\#mount -o remount,rw /#d' "${INITTAB}"

# The rootfs is mounted read-only, so DHCP cannot rewrite /etc/resolv.conf.
# Point it at the /tmp tmpfs instead.
if [ ! -L "${TARGET_DIR}/etc/resolv.conf" ]; then
	rm -f "${TARGET_DIR}/etc/resolv.conf"
	ln -s /tmp/resolv.conf "${TARGET_DIR}/etc/resolv.conf"
fi

# Remove init scripts from earlier layouts. The rootfs overlay only adds
# files, so a renamed script would otherwise linger in an incremental build.
rm -f "${TARGET_DIR}/etc/init.d/S05data"

# Mountpoints for the state that S15data bind-mounts off the data partition.
# The rootfs is read-only, so they have to exist in the image (BlueZ ships
# /var/lib/bluetooth itself, ConnMan does not create its directory).
mkdir -p "${TARGET_DIR}/var/lib/bluetooth" "${TARGET_DIR}/var/lib/connman"
chmod 0700 "${TARGET_DIR}/var/lib/bluetooth"
