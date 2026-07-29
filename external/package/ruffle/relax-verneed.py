#!/usr/bin/env python3
"""Drop an ELF binary's requirement on a glibc symbol-version.

    relax-verneed.py <elf> <version>   e.g. relax-verneed.py ruffle GLIBC_2.39

The dynamic loader refuses to start a binary whose .gnu.version_r names a
version the installed libc does not define - even when the only symbols
carrying that version are weak references the program can live without
(glibc's ld.so checks the version table before it looks at a single symbol).

This rewrites the requirement instead of deleting it, which keeps every
offset in the file intact:

  * the Vernaux entry for <version> is aliased to another version already
    required from the same library (hash and name copied from a sibling
    entry), so the loader's version check finds a definition and passes;
  * every .gnu.version slot that tagged a symbol with <version> is reset
    to index 1 (*global*, unversioned), so those symbols resolve - or, if
    weak and absent, null out - without any version constraint.

Refuses to touch a non-weak symbol: a strong reference genuinely needs the
newer libc, and masking the version would only trade a clear loader error
for a crash.
"""

import struct
import sys

SHT_GNU_VERSYM = 0x6FFFFFFF
SHT_GNU_VERNEED = 0x6FFFFFFE
SHT_DYNSYM = 11


def fail(msg):
    sys.exit(f"relax-verneed: {msg}")


def cstr(blob, off):
    return blob[off:blob.index(b"\0", off)]


def main():
    if len(sys.argv) != 3:
        fail(f"usage: {sys.argv[0]} <elf> <version>")
    path, target = sys.argv[1], sys.argv[2].encode()

    with open(path, "rb") as f:
        data = bytearray(f.read())

    if data[:4] != b"\x7fELF" or data[4] != 2 or data[5] != 1:
        fail(f"{path}: not a little-endian ELF64 file")

    e_shoff, = struct.unpack_from("<Q", data, 0x28)
    e_shentsize, e_shnum = struct.unpack_from("<HH", data, 0x3A)

    sections = []
    for i in range(e_shnum):
        off = e_shoff + i * e_shentsize
        sh_type, = struct.unpack_from("<I", data, off + 4)
        sh_offset, sh_size = struct.unpack_from("<QQ", data, off + 24)
        sh_link, = struct.unpack_from("<I", data, off + 40)
        sections.append((sh_type, sh_offset, sh_size, sh_link))

    verneed = next((s for s in sections if s[0] == SHT_GNU_VERNEED), None)
    versym = next((s for s in sections if s[0] == SHT_GNU_VERSYM), None)
    dynsym = next((s for s in sections if s[0] == SHT_DYNSYM), None)
    if not (verneed and versym and dynsym):
        fail(f"{path}: missing version sections")
    strtab_off = sections[verneed[3]][1]

    # Walk .gnu.version_r: alias every <target> aux to a sibling version
    # required from the same library.
    aliased_indices = []
    vn_off = verneed[1]
    while True:
        vn_cnt, = struct.unpack_from("<H", data, vn_off + 2)
        vn_aux, vn_next = struct.unpack_from("<II", data, vn_off + 8)

        auxes = []  # (file offset, hash, other, name offset, name)
        aux_off = vn_off + vn_aux
        for _ in range(vn_cnt):
            vna_hash, _fl, vna_other, vna_name, vna_next = struct.unpack_from(
                "<IHHII", data, aux_off)
            auxes.append((aux_off, vna_hash, vna_other, vna_name,
                          cstr(data, strtab_off + vna_name)))
            aux_off += vna_next

        for off, _h, other, _n, name in auxes:
            if name != target:
                continue
            donor = next((a for a in auxes if a[4] != target), None)
            if donor is None:
                fail(f"{path}: no other version to alias {target.decode()} to")
            struct.pack_into("<I", data, off, donor[1])       # vna_hash
            struct.pack_into("<I", data, off + 8, donor[3])   # vna_name
            aliased_indices.append(other)

        if vn_next == 0:
            break
        vn_off += vn_next

    if not aliased_indices:
        fail(f"{path}: no version requirement {target.decode()} found")

    # Reset the .gnu.version index of every symbol that carried <target>.
    sym_count = versym[2] // 2
    cleared = 0
    for i in range(sym_count):
        idx, = struct.unpack_from("<H", data, versym[1] + i * 2)
        if (idx & 0x7FFF) not in aliased_indices:
            continue
        st_info = data[dynsym[1] + i * 24 + 4]
        if (st_info >> 4) != 2:  # STB_WEAK
            name_off, = struct.unpack_from("<I", data, dynsym[1] + i * 24)
            sym = cstr(data, sections[dynsym[3]][1] + name_off).decode()
            fail(f"{path}: {sym} needs {target.decode()} non-weakly")
        struct.pack_into("<H", data, versym[1] + i * 2, 1)
        cleared += 1

    with open(path, "wb") as f:
        f.write(data)
    print(f"{path}: {target.decode()} aliased, "
          f"{cleared} weak symbol(s) unversioned")


if __name__ == "__main__":
    main()
