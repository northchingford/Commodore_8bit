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
