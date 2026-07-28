# Launch the graphical session on the first VT for the auto-logged-in user.
# Sourced by /etc/profile at login. Only fires on tty1 so serial/ssh logins
# get a normal shell. The session type follows what the image ships: the
# XFCE frontend (frontend/xfce.config) installs startxfce4, everything
# else uses the sway session.
if [ "$(tty)" = "/dev/tty1" ] && [ -z "${WAYLAND_DISPLAY}" ] && [ -z "${DISPLAY}" ]; then
	if [ -x /usr/bin/startxfce4 ]; then
		exec /usr/bin/xfce-session
	fi
	exec /usr/bin/sway-session
fi
