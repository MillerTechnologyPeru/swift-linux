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

# The 32-bit dynamic loader name is arch-specific (i386: ld-linux.so.2;
# armv7 hard-float: ld-linux-armhf.so.3), so discover it from the companion
# rootfs rather than hard-coding it.
LDSO=""
for cand in "${LIB32_ROOT}"/lib/ld-linux*.so.* "${LIB32_ROOT}"/lib/ld-*.so.*; do
	[ -e "${cand}" ] && { LDSO=$(basename "${cand}"); break; }
done

echo "lib32: merging 32-bit libraries from ${LIB32_ROOT} (loader ${LDSO:-unknown})"
mkdir -p "${TARGET_DIR}/usr/lib32"

# Copy the whole /lib and /usr/lib trees into /usr/lib32, preserving
# subdirectories so the full app-sdk stack works - Mesa's DRI drivers
# (usr/lib/dri), GBM/EGL backends, gconv modules, and so on - not just the
# top-level .so files. Symlinks are preserved (cp -a).
for d in lib usr/lib; do
	[ -d "${LIB32_ROOT}/${d}" ] || continue
	cp -a "${LIB32_ROOT}/${d}/." "${TARGET_DIR}/usr/lib32/"
done

# Drop development-only artifacts that came along with the libraries.
find "${TARGET_DIR}/usr/lib32" \( -name '*.a' -o -name '*.la' -o -name '*.o' \) -delete 2>/dev/null || true
rm -rf "${TARGET_DIR}/usr/lib32/pkgconfig" "${TARGET_DIR}/usr/lib32/cmake"

# The kernel looks the interpreter up at the exact path recorded in each
# binary's PT_INTERP (/lib/ld-linux.so.2 for x86, /lib/ld-linux-armhf.so.3
# for armv7), so expose the loader there.
if [ -n "${LDSO}" ] && [ -e "${TARGET_DIR}/usr/lib32/${LDSO}" ]; then
	mkdir -p "${TARGET_DIR}/lib"
	ln -sf /usr/lib32/"${LDSO}" "${TARGET_DIR}/lib/${LDSO}"
else
	echo "lib32: warning - loader not found, 32-bit binaries will not start" >&2
fi

# Vulkan ICD manifests for the 32-bit drivers.
#
# The Vulkan loader finds drivers by reading every *.json in
# /usr/share/vulkan/icd.d, and Mesa writes an absolute "library_path" into
# each one. A 32-bit process reads the same directory as a 64-bit one, so
# without a 32-bit variant it tries to dlopen the 64-bit driver and gets
# nothing - the manifests are the reason 32-bit Vulkan fails even when the
# libraries are present.
#
# Emit <name>.lib32.json next to each original, with the path moved to
# /usr/lib32 and library_arch corrected. Two guards: a library_path with no
# '/' is a bare soname, which the loader resolves through the ld.so cache -
# and that cache is architecture-tagged, so a 32-bit process already finds
# the 32-bit library by itself; and a manifest is only written when the
# library it names actually exists in /usr/lib32, so a companion built
# without a given driver does not leave the loader chasing a missing file.
icd_src="${LIB32_ROOT}/usr/share/vulkan/icd.d"
if [ -d "${icd_src}" ]; then
	icd_dst="${TARGET_DIR}/usr/share/vulkan/icd.d"
	mkdir -p "${icd_dst}"
	icd_count=0
	for json in "${icd_src}"/*.json; do
		[ -f "${json}" ] || continue
		# Absolute (or at least path-bearing) library_path only.
		grep -q '"library_path"[^"]*"[^"]*/' "${json}" || continue

		lib=$(sed -n 's/.*"library_path"[^"]*"\([^"]*\)".*/\1/p' "${json}" | head -1)
		libname=$(basename "${lib}")
		[ -e "${TARGET_DIR}/usr/lib32/${libname}" ] || continue

		base=$(basename "${json}" .json)
		sed -e 's#"/usr/lib/#"/usr/lib32/#g' \
		    -e 's#"library_arch"[[:space:]]*:[[:space:]]*"64"#"library_arch": "32"#' \
		    "${json}" > "${icd_dst}/${base}.lib32.json"
		icd_count=$((icd_count + 1))
	done
	[ "${icd_count}" -gt 0 ] && \
		echo "lib32: wrote ${icd_count} 32-bit Vulkan ICD manifest(s)"
fi

# box86 (a 32-bit ARM binary) runs 32-bit x86 programs. When the companion is
# an armv7 userland it is built there; carry it into the 64-bit image so the
# S07binfmt i386 handler can use it (arm64 runs it via aarch32 compat).
if [ -x "${LIB32_ROOT}/usr/bin/box86" ]; then
	cp -a "${LIB32_ROOT}/usr/bin/box86" "${TARGET_DIR}/usr/bin/box86"
	echo "lib32: installed box86 (32-bit x86 emulator)"
fi

# Wine, when the companion built it (i386 only - Buildroot's package is
# x86-specific, which is exactly what the x86_64 pairing provides).
#
# Unlike the libraries above, Wine needs its programs and its data: the
# loader stubs in /usr/bin, and share/wine with the built-in DLLs and the
# fake Windows drive skeleton. Its own libraries came across with the lib
# trees already, and /usr/lib32 is on the search path, so the 32-bit
# binaries resolve them.
if [ -x "${LIB32_ROOT}/usr/bin/wine" ]; then
	for prog in wine wine-preloader wineserver winecfg wineboot \
	            winepath winedbg regedit msiexec notepad; do
		[ -e "${LIB32_ROOT}/usr/bin/${prog}" ] || continue
		cp -a "${LIB32_ROOT}/usr/bin/${prog}" "${TARGET_DIR}/usr/bin/${prog}"
	done
	if [ -d "${LIB32_ROOT}/usr/share/wine" ]; then
		mkdir -p "${TARGET_DIR}/usr/share"
		cp -a "${LIB32_ROOT}/usr/share/wine" "${TARGET_DIR}/usr/share/"
	fi
	echo "lib32: installed wine (32-bit Windows applications)"
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

echo "lib32: installed $(find "${TARGET_DIR}/usr/lib32" -name '*.so*' | wc -l) shared libraries"
