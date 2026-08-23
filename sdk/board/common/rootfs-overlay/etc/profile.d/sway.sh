# Launch the graphical session on the first VT for the auto-logged-in user.
# Sourced by /etc/profile at login. Only fires on tty1 so serial/ssh logins
# get a normal shell. The session type follows what the image ships:
# GNOME (frontend/gnome.config) installs gnome-session, XFCE installs
# startxfce4, everything else uses the sway session.
#
# SESSION_LAUNCHED guards against re-entry, which is not hypothetical:
# GNOME's own /usr/bin/gnome-session re-executes itself through a login
# shell when XDG_SESSION_TYPE is wayland,
#
#   exec bash -c "exec -l '$SHELL' -c '$0 -l $*'"
#
# and a login shell sources this file again. At that point the tty is still
# tty1 and WAYLAND_DISPLAY is still unset - mutter has not started yet - so
# every test below still passes and the session starts itself once more.
# That recursed until the fds ran out:
#
#   bash: warning: shell level (1000) too high, resetting to 1
#   dbus-daemon[3822]: Cannot initialize inotify: Too many open files
#
# The variable is exported, so it survives the exec into the login shell and
# the second pass falls through to an ordinary shell. Distributions do not
# hit this because a display manager starts the session instead of profile.
# A display manager, where one is installed, starts the session itself and
# authenticates the user first. Starting a second one from this hook would
# fight it for the seat, so the hook stands down.
if [ -x /usr/sbin/gdm ]; then
	return 2>/dev/null || true
fi

if [ "$(tty)" = "/dev/tty1" ] && [ -z "${WAYLAND_DISPLAY}" ] && \
   [ -z "${DISPLAY}" ] && [ -z "${SESSION_LAUNCHED:-}" ]; then
	SESSION_LAUNCHED=1
	export SESSION_LAUNCHED
	if [ -x /usr/bin/gnome-session ]; then
		exec /usr/bin/gnome-wayland-session
	fi
	if [ -x /usr/bin/startxfce4 ]; then
		exec /usr/bin/xfce-session
	fi
	exec /usr/bin/sway-session
fi
