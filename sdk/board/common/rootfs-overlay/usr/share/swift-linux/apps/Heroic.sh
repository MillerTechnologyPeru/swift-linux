#!/bin/sh
# Open Heroic (seeded into /data/apps by S15data on images that ship it).
# --no-sandbox: Electron's setuid chrome-sandbox is not shipped; the app
# is already confined to the session user.
exec /usr/bin/heroic --no-sandbox
