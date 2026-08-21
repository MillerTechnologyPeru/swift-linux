#!/bin/sh
# Generate /etc/ld.so.cache for the target.
#
# The dynamic loader never reads /etc/ld.so.conf. That file is input to
# ldconfig, which scans the directories it names and writes the binary index
# the loader does read, /etc/ld.so.cache. Without the cache the loader falls
# back to DT_RPATH/DT_RUNPATH and a small built-in list - /lib and /usr/lib -
# and every other directory is invisible however many .conf files name it.
#
# post-build-lib32.sh writes /etc/ld.so.conf.d/lib32.conf for the 513 sonames
# it merges into /usr/lib32, and that entry did nothing at all: nothing ran
# ldconfig, so no cache existed. The failure this produces is not "library not
# found" but something more confusing, because the sonames collide - libcairo.so.2
# is present as 64-bit in /usr/lib and as 32-bit in /usr/lib32 - so the loader
# finds the wrong one first and stops:
#
#   wrong ELF class: ELFCLASS64
#
# The rootfs is read-only EROFS for the life of the slot, so this cannot be
# deferred to first boot; it has to be built here. ldconfig -r treats its
# argument as /, which is exactly the cross case.
#
# Runs last of the post-build scripts, after everything that might add a
# .conf file.
set -e
TARGET_DIR="$1"

[ -f "${TARGET_DIR}/etc/ld.so.conf" ] || exit 0

LDCONFIG=""
for cand in /sbin/ldconfig /usr/sbin/ldconfig; do
	[ -x "${cand}" ] && { LDCONFIG="${cand}"; break; }
done
if [ -z "${LDCONFIG}" ]; then
	command -v ldconfig >/dev/null 2>&1 && LDCONFIG=ldconfig
fi
if [ -z "${LDCONFIG}" ]; then
	echo "ld.so.cache: no ldconfig on the build machine, skipping" >&2
	exit 0
fi

# The host's ldconfig writes a cache by reading ELF headers, which is right
# only where it understands the target's. x86_64 covers an i386 target too -
# same reader, and the 32-bit merge above is exactly that case - but an
# aarch64 or arm target cross-built here is not something to guess at, so
# leave those images without a cache rather than with a wrong one.
target_arch=""
if [ -n "${BR2_CONFIG:-}" ] && [ -f "${BR2_CONFIG}" ]; then
	if   grep -q '^BR2_x86_64=y' "${BR2_CONFIG}"; then target_arch=x86_64
	elif grep -q '^BR2_i386=y'   "${BR2_CONFIG}"; then target_arch=i386
	fi
fi
case "$(uname -m):${target_arch}" in
	x86_64:x86_64|x86_64:i386|i?86:i386) ;;
	*)
		echo "ld.so.cache: build machine $(uname -m) cannot index a ${target_arch:-non-x86} target, skipping"
		exit 0
		;;
esac

"${LDCONFIG}" -r "${TARGET_DIR}"
echo "ld.so.cache: indexed $("${LDCONFIG}" -r "${TARGET_DIR}" -p 2>/dev/null | sed -n '1s/[^0-9]*\([0-9]*\).*/\1/p') libraries"
