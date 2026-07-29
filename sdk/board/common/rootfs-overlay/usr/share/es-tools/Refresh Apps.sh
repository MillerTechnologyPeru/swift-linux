#!/bin/sh
# Regenerate the Apps entries for installed flatpak applications (see
# es-flatpak-sync). Run after installing or removing something in the
# App Store.
exec /usr/bin/es-flatpak-sync
