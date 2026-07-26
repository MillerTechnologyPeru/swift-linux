#!/bin/sh
# Merge a 32-bit userland into the 64-bit image as /usr/lib32.
#
# Buildroot builds a single architecture per build, so the 32-bit libraries
# come from a SECOND build (see the "lib32" profile in generate-config.sh).
# Point SWIFT_LINUX_LIB32_ROOT at that build's target/ directory:
#
#   SWIFT_LINUX_LIB32_ROOT=/path/to/output-i386/target make ...
#
# Without it this script does nothing, so the 64-bit image still builds.
set -e
TARGET_DIR="$1"
LIB32_ROOT="${SWIFT_LINUX_LIB32_ROOT}"

[ -n "${LIB32_ROOT}" ] || exit 0

if [ ! -d "${LIB32_ROOT}" ]; then
	echo "lib32: SWIFT_LINUX_LIB32_ROOT=${LIB32_ROOT} does not exist" >&2
	exit 1
fi

# The 32-bit loader. i386 uses ld-linux.so.2; arm hard-float would use
# ld-linux-armhf.so.3.
LDSO="ld-linux.so.2"

echo "lib32: merging 32-bit libraries from ${LIB32_ROOT}"
mkdir -p "${TARGET_DIR}/usr/lib32"

# Copy the shared libraries only - not binaries, headers or config. Dangling
# symlinks are expected (they point at 32-bit paths) so preserve them as-is.
for d in lib usr/lib; do
	[ -d "${LIB32_ROOT}/${d}" ] || continue
	find "${LIB32_ROOT}/${d}" -maxdepth 1 \( -name '*.so' -o -name '*.so.*' \) \
		-exec cp -a {} "${TARGET_DIR}/usr/lib32/" \;
done

# The kernel looks the interpreter up at the exact path recorded in each
# binary's PT_INTERP, which for 32-bit x86 is /lib/ld-linux.so.2.
if [ -e "${TARGET_DIR}/usr/lib32/${LDSO}" ]; then
	mkdir -p "${TARGET_DIR}/lib"
	ln -sf /usr/lib32/"${LDSO}" "${TARGET_DIR}/lib/${LDSO}"
else
	echo "lib32: warning - ${LDSO} not found, 32-bit binaries will not start" >&2
fi

# Teach the dynamic loader about /usr/lib32. The rootfs is read-only at
# runtime, so the cache has to be generated here at build time; ldconfig -r
# treats the given directory as /.
mkdir -p "${TARGET_DIR}/etc/ld.so.conf.d"
echo "/usr/lib32" > "${TARGET_DIR}/etc/ld.so.conf.d/lib32.conf"
if [ ! -f "${TARGET_DIR}/etc/ld.so.conf" ]; then
	echo "include /etc/ld.so.conf.d/*.conf" > "${TARGET_DIR}/etc/ld.so.conf"
elif ! grep -q "ld.so.conf.d" "${TARGET_DIR}/etc/ld.so.conf"; then
	echo "include /etc/ld.so.conf.d/*.conf" >> "${TARGET_DIR}/etc/ld.so.conf"
fi

# ldd from the 32-bit build, so 32-bit binaries can be inspected on target.
if [ -x "${LIB32_ROOT}/usr/bin/ldd" ]; then
	cp -a "${LIB32_ROOT}/usr/bin/ldd" "${TARGET_DIR}/usr/bin/ldd32"
fi

echo "lib32: installed $(find "${TARGET_DIR}/usr/lib32" -maxdepth 1 -name '*.so*' | wc -l) libraries"
