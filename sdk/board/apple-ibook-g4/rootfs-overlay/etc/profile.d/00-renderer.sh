# Composite with wlroots' pixman renderer. Mesa carries only softpipe here,
# which is too slow to composite with; the Radeon's r300 driver comes later.
# Named to sort before sway.sh, which execs the session.
export WLR_RENDERER=pixman
