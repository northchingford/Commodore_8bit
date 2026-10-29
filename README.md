# Commodore_8bit
Commodore 8bit code and projects.

## Pong

Build `pongywongy.asm` with `acme -f cbm -o pongywongy.prg pongywongy.asm` and load the PRG on a Commodore 64 or emulator.

Joystick port 2 controls the left paddle; port 1 controls the right paddle. Use up and down to move. The first player to five points wins; press fire on either joystick to start a new game.

## Steven Croucher demo

Generate the multicolor bitmap and assemble the standalone demo:

```sh
python3 make_steven_bitmap.py
acme -f cbm -o steven_demo.prg steven_demo.asm
```

The generator requires Pillow. Load `steven_demo.prg` on a PAL C64 or emulator. It displays a static multicolor bitmap while a three-voice SID tune plays a 12-bar progression five times, then loops at two minutes. The PRG uses `$2000` for bitmap data and `$0400` for screen RAM.

## Waterfall demo

Generate the multicolor scene and 512 KiB REU image, then assemble the demo:

```sh
python3 make_waterfall_assets.py
acme -f cbm -o waterfall_demo.prg waterfall_demo.asm
```

Load `waterfall_demo.prg` on a PAL C64 with a 512 KiB REU, and configure the REU to load `waterfall.reu`. In VICE, enable the REU, select 512 KiB, and set its REU image to `waterfall.reu`. The image contains 102 animation frames (510 KiB); the remaining 2 KiB is unused. Each frame is DMA-copied to bitmap RAM, with SID voice 3 supplying the rushing-water sound. `waterfall_preview.png` shows a representative frame. The `.reu` image is an emulator image; a physical REU needs its RAM populated separately before running this build.

## Space Invaders 128

Build the native C128 80-column VDC game:

```sh
acme -f cbm -o space_invaders_128.prg space_invaders_128.asm
```

Load and run `space_invaders_128.prg` on a Commodore 128 with the 80-column output connected. The game uses custom VDC character RAM for 2x2-cell sprites and the SID for laser and explosion effects. Move with A/D or the cursor keys, fire with Space, and press Space after a win or game over to restart.
