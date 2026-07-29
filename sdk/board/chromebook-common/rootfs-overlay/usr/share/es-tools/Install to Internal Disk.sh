#!/bin/sh
# Install the running system onto the Chromebook's internal storage.
# DESTRUCTIVE - it asks for confirmation first. Needs a terminal, so it
# runs under foot when the session has one.
if command -v foot >/dev/null 2>&1; then
	exec foot -- sh -c 'sudo /usr/bin/chromebook-install; echo; echo "Press enter to close."; read x'
fi
exec sudo /usr/bin/chromebook-install
