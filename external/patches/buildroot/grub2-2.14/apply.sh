#!/bin/sh
# Bump Buildroot's GRUB to 2.14, which is the first release with an EROFS
# filesystem driver.
#
#   ./apply.sh <buildroot>
#
# Why this is not a .patch like its siblings: the change is a version bump
# plus the DELETION of the 74 CVE backport patches Buildroot carries for
# 2.12 (6213 lines of them). Those fixes are all released in 2.14, so on
# 2.14 they no longer apply - and a unified diff removing 74 files with
# their full contents would be unreviewable. Buildroot master made exactly
# this change; grub2.mk and grub2.hash here are its files verbatim, so this
# is a backport of an upstream commit, not a local invention.
#
# The hash is upstream's and matches an independent download of
# https://ftp.gnu.org/gnu/grub/grub-2.14.tar.xz:
#   bc8d3c73535b8838d8c8e2654d73edc4e6ae8c8acdb45d5df5dc9a1547446d43
#
# Idempotent: re-running on an already-bumped tree changes nothing.
set -e

BR="${1:?usage: apply.sh <buildroot>}"
D="$BR/boot/grub2"
[ -f "$D/grub2.mk" ] || { echo "apply.sh: $D/grub2.mk not found - is '$BR' a Buildroot tree?" >&2; exit 1; }

here="$(cd "$(dirname "$0")" && pwd)"

cp "$here/grub2.mk" "$D/grub2.mk"
cp "$here/grub2.hash" "$D/grub2.hash"

# The 2.12 CVE backports; all released in 2.14.
rm -f "$D"/0*.patch

echo "grub2: bumped to $(sed -n 's/^GRUB2_VERSION = //p' "$D/grub2.mk"), 2.12 patch stack removed"
