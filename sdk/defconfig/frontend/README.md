# Frontends

The user-facing shell of an image, one fragment per frontend. The image
profile includes `emulationstation.config` as the default; a board switches
by including a different fragment from its `board.config`:

    include sdk/defconfig/frontend/gmenu2x.config

That works because generate-config emits the board.config after
image.config and later assignments win: each non-default fragment first
negates the default frontend's packages (`# ... is not set`), then enables
its own. A fragment is emitted at most once, so a board include never
duplicates the default.

| Fragment | For | Status |
|---|---|---|
| `emulationstation.config` | GL(ES)-capable gaming devices, the default | working |
| `gmenu2x.config` | armv5 / devices with no OpenGL ES (framebuffer) | definition only |
| `gnome.config` | desktop x86_64/arm64 machines | placeholder: Buildroot has no GNOME session packages |
| `phosh.config` | Android-phone form factors (oneplus-*, xiaomi-*) | placeholder: Buildroot has no phosh/phoc packages |

The placeholders document intent and the packaging work each needs; they
deliberately set nothing a build could half-apply.
