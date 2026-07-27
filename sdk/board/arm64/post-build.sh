#!/bin/sh
# Board (arm64/UEFI) post-build: install the GRUB config and an initial
# grub environment block onto the ESP image tree that grub2 populated.
set -e
BOARD_DIR="$(dirname "$0")"
EFI_BOOT="${BINARIES_DIR}/efi-part/EFI/BOOT"

[ -d "${EFI_BOOT}" ] || exit 0

cp -f "${BOARD_DIR}/grub.cfg" "${EFI_BOOT}/grub.cfg"

# Seed the grub environment so RAUC has A/B state to update. Best-effort:
# if grub-editenv is unavailable, grub.cfg's built-in defaults still boot A.
if [ ! -f "${EFI_BOOT}/grubenv" ] && command -v grub-editenv >/dev/null 2>&1; then
	grub-editenv "${EFI_BOOT}/grubenv" create
	grub-editenv "${EFI_BOOT}/grubenv" set ORDER="A B" A_OK=1 B_OK=1 A_TRY=0 B_TRY=0
fi
