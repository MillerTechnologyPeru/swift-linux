# Composite with wlroots' pixman renderer. This board has no GPU driver and
# Mesa only carries softpipe, which is far too slow to composite with under
# emulation. Named to sort before sway.sh, which execs the session.
export WLR_RENDERER=pixman
