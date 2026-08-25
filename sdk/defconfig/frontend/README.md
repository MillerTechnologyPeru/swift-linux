# Frontends

The user-facing shell of an image, one fragment per frontend. The image
profile includes `emulationstation.config` as the default; a board switches
by including a different fragment from its `board.config`:

    include sdk/defconfig/frontend/gmenu2x.config

or, without touching the board, per build:

    ./generate-config.sh --arch x86_64 --profile image --frontend minimal
    FRONTEND=minimal ./build-images.sh x86_64

That works because generate-config emits the board.config after
image.config and later assignments win: each non-default fragment first
negates the default frontend's packages (`# ... is not set`), then enables
its own. A fragment is emitted at most once, so a board include never
duplicates the default.

| Fragment | For | Status |
|---|---|---|
| `emulationstation.config` | GL(ES)-capable gaming devices, the default | working |
| `minimal.config` | bring-up: verifying a board boots, and short build cycles | working |
| `gmenu2x.config` | armv5 / devices with no OpenGL ES (framebuffer) | definition only |
| `xfce.config` | desktop use: XFCE on X.org, Chicago95 theme by default | packaged + kconfig-validated, not yet booted |
| `gnome.config` | desktop x86_64/arm64 machines | working: builds, boots to a gdm greeter (no autologin), and logs in to a GL-accelerated GNOME session; `util/boot-verify.sh` checks the whole path |
| `phosh.config` | Android-phone form factors (oneplus-*, xiaomi-*) | placeholder: Buildroot has no phosh/phoc packages |

The placeholders document intent and the packaging work each needs; they
deliberately set nothing a build could half-apply.

`minimal.config` is the odd one out: rather than a shell someone would choose
to use, it is the smallest thing that proves a board works - sway, its bar and
foot, with the game frontend, the emulators and the compatibility layers
unwound. On x86_64 that is 34 fewer packages, and the ones it drops are the
expensive builds (RetroArch and ten cores, QEMU with its system targets, VLC,
Ruffle's Rust toolchain, LOVE, Solarus, the prebuilt Wine). Boot it first, then
build the frontend you actually want.
