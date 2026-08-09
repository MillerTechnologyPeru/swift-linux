# Acer Chromebook Tab 10 (scarlet)

Rockchip RK3399 Chromebook tablet, Mali-T860 (panfrost). **Definition only** -
not built or verified here. Boots via Depthcharge in developer mode (see
`sdk/board/chromebook-common/README.md`). A real build additionally needs the
device firmware blobs (WiFi/BT/GPU) in the rootfs and any not-yet-mainlined
kernel quirks staged in `sdk/board/chromebook-rk3399/patches/`.

## Names

The same tablet answers to three, which is worth writing down because searching
for the wrong one finds nothing:

| Name      | Where it is used                                       |
|-----------|--------------------------------------------------------|
| `scarlet` | the mainline device trees, and this directory          |
| `dru`     | the ChromeOS device name; postmarketOS's wiki page      |
| D651N     | Acer's model number                                    |

## Two panels, one board

Mainline carries `rk3399-gru-scarlet-inx` and `rk3399-gru-scarlet-kd`, for the
Innolux and Kingdisplay panels. They are the same tablet otherwise, and the
panel is not identifiable from outside the case, so this board builds both and
leaves the choice to Depthcharge at boot rather than splitting into two boards
that a user could not choose between.

## Tablet, not a laptop

No keyboard and no trackpad, which the rest of this tree does not assume
anywhere but is worth knowing before bring-up: the shared session autologs into
sway (see `sdk/board/common/rootfs-overlay`), and a sway session with no
keyboard is only as usable as its on-screen input. The frontend fragments do
not currently ship one - `minimal` gives a terminal that cannot be typed into
on this device. Serial console is the way in during bring-up.

## Prior art

- **postmarketOS** supports it, as part of a family package rather than a
  device of its own: `device-google-gru` covers bob, kevin and scarlet from one
  image, with `deviceinfo_dtb="rockchip/rk3399-gru*"`,
  `deviceinfo_depthcharge_board="gru"` and a generated depthcharge image. Its
  wiki files the tablet under `google-dru`.
- **Cadmium** does not support it. Its RK3399 entry is `gru-kevin`.
