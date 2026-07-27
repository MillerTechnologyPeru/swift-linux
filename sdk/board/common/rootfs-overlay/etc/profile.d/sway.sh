# Launch a Sway session on the first VT for the auto-logged-in user.
# Sourced by /etc/profile at login. Only fires on tty1 so serial/ssh logins
# get a normal shell.
if [ "$(tty)" = "/dev/tty1" ] && [ -z "${WAYLAND_DISPLAY}" ]; then
	exec /usr/bin/sway-session
fi
