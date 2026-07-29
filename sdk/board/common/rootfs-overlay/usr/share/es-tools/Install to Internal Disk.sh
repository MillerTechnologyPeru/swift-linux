#!/bin/sh
# Install the running system onto internal storage (system-install
# detects the boot firmware). DESTRUCTIVE - it asks for confirmation.
# Needs a terminal, so it runs under foot when the session has one.
if command -v foot >/dev/null 2>&1; then
	exec foot -- sh -c 'sudo -n /usr/bin/system-install; echo; echo "Press enter to close."; read x'
fi
exec sudo -n /usr/bin/system-install
