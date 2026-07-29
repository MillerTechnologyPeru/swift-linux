BIOS and firmware files
=======================

Put them in /roms/bios (that is /data/roms/bios - the same place the
"bios" folder appears next to your ROM folders). RetroArch is configured
to look there, so a core finds its file with no further setup.

Files the cores in this image ask for:

  vMac.ROM                    Macintosh (Mini vMac). The ROM of the model
                              you want to emulate - a Mac Plus ROM is the
                              usual choice.

  palmos41-en-m515.rom        Palm OS (Mu). The Palm m515 OS 4.1 ROM.

Everything else here runs without one: NES, SNES, Game Boy/Color, Game
Boy Advance, DOS, RPG Maker, ScummVM and Lutro need no BIOS at all.
PlayStation (PCSX-ReARMed) has a built-in HLE BIOS and works without a
real one, though a genuine SCPH-xxxx image improves compatibility.

None of these files ship with the image: they are copyrighted, and dumping
them from hardware you own is your side of that.

Where saved games go
====================

/data/saves/<system>/ - one folder per system, holding both save files
and save states. /data/saves is also where standalone engines and app
bundles keep their data, each under its own name.
