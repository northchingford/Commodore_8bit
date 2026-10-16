#!/usr/bin/env python3
"""Generate multicolor bitmap and six REU animation frames for the waterfall demo."""

from itertools import combinations
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent
WIDTH, HEIGHT = 160, 200
ANIM_Y = 72
FRAME_COUNT = 6
BACKGROUND = 14
PALETTE = [
    (0, 0, 0), (255, 255, 255), (129, 51, 56), (117, 206, 200),
    (142, 60, 151), (86, 172, 77), (46, 44, 155), (237, 241, 113),
    (142, 80, 41), (85, 56, 0), (196, 108, 113), (74, 74, 74),
    (123, 123, 123), (169, 255, 159), (112, 109, 235), (178, 178, 178),
]


def draw_scene(frame):
    image = Image.new("RGB", (WIDTH, HEIGHT), PALETTE[BACKGROUND])
    draw = ImageDraw.Draw(image)

    draw.ellipse((119, 8, 145, 34), fill=PALETTE[7], outline=PALETTE[1])
    draw.ellipse((125, 12, 133, 20), fill=PALETTE[1])
    for x, y, width in ((17, 20, 27), (48, 35, 22), (103, 45, 31)):
        draw.ellipse((x, y + 4, x + width, y + 12), fill=PALETTE[1])
        draw.ellipse((x + 5, y, x + 16, y + 14), fill=PALETTE[1])
        draw.ellipse((x + 13, y - 2, x + 23, y + 14), fill=PALETTE[1])
        draw.line((x + 2, y + 12, x + width - 1, y + 12), fill=PALETTE[3], width=2)

    draw.polygon([(0, 92), (0, 70), (22, 55), (42, 61), (59, 48),
                  (77, 61), (94, 52), (119, 70), (143, 58), (159, 68),
                  (159, 99)], fill=PALETTE[5])
    draw.polygon([(0, 86), (24, 66), (38, 71), (58, 55), (76, 69),
                  (96, 59), (117, 76), (139, 65), (159, 76), (159, 102),
                  (0, 104)], fill=PALETTE[13])

    # The cliff frames the narrow upper chute and the wider falling sheet.
    draw.polygon([(0, 78), (28, 66), (52, 71), (64, 63), (68, 78),
                  (65, 108), (58, 137), (0, 145)], fill=PALETTE[12])
    draw.polygon([(101, 70), (122, 64), (159, 77), (159, 147),
                  (112, 139), (104, 112)], fill=PALETTE[11])
    draw.polygon([(0, 84), (27, 73), (48, 76), (62, 69), (63, 78),
                  (52, 96), (44, 119), (0, 137)], fill=PALETTE[15])
    draw.polygon([(107, 77), (123, 72), (159, 84), (159, 137),
                  (117, 127), (109, 107)], fill=PALETTE[12])
    for x, y in ((11, 89), (30, 79), (43, 101), (17, 119), (126, 89),
                 (145, 105), (119, 119), (151, 126), (4, 132)):
        draw.line((x, y, x + 7, y - 3), fill=PALETTE[1], width=1)
        draw.point((x + 2, y + 4), fill=PALETTE[11])

    # Mossy shelves and grass soften the rock edges around the cascade.
    draw.polygon([(0, 69), (15, 65), (29, 69), (42, 65), (56, 70),
                  (64, 67), (65, 74), (45, 77), (27, 73), (0, 80)], fill=PALETTE[5])
    draw.polygon([(101, 70), (111, 66), (126, 70), (139, 67), (159, 74),
                  (159, 82), (137, 76), (121, 78), (107, 75)], fill=PALETTE[13])
    for x in range(4, 62, 8):
        draw.line((x, 70, x - 2, 64), fill=PALETTE[13])
        draw.line((x + 1, 70, x + 4, 65), fill=PALETTE[5])
    for x in range(108, 159, 9):
        draw.line((x, 73, x + 2, 67), fill=PALETTE[5])
        draw.line((x + 2, 73, x + 6, 68), fill=PALETTE[13])

    # Banks, pool and a pale footpath winding through the foreground.
    draw.polygon([(0, 139), (25, 135), (50, 141), (67, 145), (91, 140),
                  (114, 137), (159, 145), (159, 200), (0, 200)], fill=PALETTE[5])
    draw.polygon([(0, 151), (25, 145), (48, 148), (67, 153), (89, 148),
                  (112, 145), (159, 153), (159, 190), (0, 190)], fill=PALETTE[6])
    draw.polygon([(0, 160), (25, 152), (48, 155), (67, 160), (89, 155),
                  (112, 152), (159, 160), (159, 178), (112, 169),
                  (88, 171), (66, 177), (43, 168), (20, 166), (0, 174)],
                 fill=PALETTE[14])
    draw.polygon([(0, 139), (22, 136), (43, 141), (65, 145), (89, 141),
                  (112, 137), (159, 145), (159, 152), (112, 145),
                  (89, 148), (67, 153), (48, 148), (25, 145), (0, 151)],
                 fill=PALETTE[13])
    draw.polygon([(0, 181), (18, 174), (39, 172), (56, 177), (69, 186),
                  (66, 200), (0, 200)], fill=PALETTE[8])
    draw.line([(0, 183), (18, 177), (39, 175), (54, 180), (64, 188)],
              fill=PALETTE[7], width=2)
    for x, y in ((8, 145), (19, 140), (34, 145), (123, 143), (140, 147),
                 (153, 151), (76, 187), (95, 180), (119, 185), (143, 177)):
        draw.line((x, y, x + 1, y - 5), fill=PALETTE[13])
        draw.line((x + 1, y, x + 4, y - 4), fill=PALETTE[5])

    # Falling water and impact foam are redrawn each frame for genuine motion.
    stream_left = 70 + ((frame * 3) % 5) - 2
    stream_right = 99 + ((frame * 2) % 5) - 2
    draw.polygon([(69, 72), (101, 72), (97, 126), (110, 142),
                  (91, 151), (68, 143), (77, 125)], fill=PALETTE[6])
    draw.polygon([(stream_left, 73), (stream_right, 73),
                  (stream_right - 3, 122), (104, 139), (91, 146),
                  (73, 140), (stream_left + 5, 122)], fill=PALETTE[3])
    for index in range(7):
        x = stream_left + 3 + ((index * 5 + frame * (index % 3 + 1)) % 24)
        top = 76 + (index * 7 % 20)
        bottom = 119 + (index * 5 % 20)
        draw.line((x, top, x + (index % 3) - 1, bottom),
                  fill=PALETTE[1] if index % 3 == 0 else PALETTE[14], width=1)
    draw.line((stream_left + 6, 76, stream_left + 5, 120), fill=PALETTE[1])
    draw.line((stream_right - 8, 78, stream_right - 10, 122), fill=PALETTE[13])

    splash_shift = frame % 4
    draw.arc((58 - splash_shift, 129, 110 + splash_shift, 158), 195, 345,
             fill=PALETTE[1], width=2)
    for x, y in ((61, 138), (69, 146), (76, 151), (101, 146),
                 (109, 139), (84 + frame % 3, 132), (73 + frame % 5, 135)):
        draw.point((x, y), fill=PALETTE[1])
        draw.point((x + 1, y - 2), fill=PALETTE[3])

    # Long current bands travel downstream and wrap across the pool.
    for index in range(5):
        y = 156 + index * 4
        x = (frame * 13 + index * 37) % 190 - 30
        length = 28 + (index % 3) * 10
        color = PALETTE[3] if index % 2 else PALETTE[14]
        for wrap in (-190, 0, 190):
            draw.line((x + wrap, y, x + wrap + length, y), fill=color, width=1)
            draw.line((x + wrap + 7, y + 1, x + wrap + length - 5, y + 1),
                      fill=PALETTE[1] if index % 2 else PALETTE[3], width=1)
    return image


def color_distance(left, right):
    return sum((a - b) ** 2 for a, b in zip(left, right))


def encode(frames):
    triples = []
    screen = bytearray()
    colors = bytearray()
    candidates = [tuple(choice) for choice in combinations(
        [index for index in range(16) if index != BACKGROUND], 3)]
    distances = [[color_distance(color, palette_color) for palette_color in PALETTE]
                 for color in PALETTE]

    for cell_y in range(25):
        for cell_x in range(40):
            histogram = {}
            for frame in frames:
                for y in range(cell_y * 8, cell_y * 8 + 8):
                    for x in range(cell_x * 4, cell_x * 4 + 4):
                        color = frame.getpixel((x, y))
                        histogram[color] = histogram.get(color, 0) + 1
            counts = [(PALETTE.index(color), count) for color, count in histogram.items()]
            best = None
            best_error = None
            for triple in candidates:
                available = (BACKGROUND, *triple)
                error = sum(count * min(distances[color][candidate]
                                        for candidate in available)
                            for color, count in counts)
                if best_error is None or error < best_error:
                    best, best_error = triple, error
            triples.append((BACKGROUND, *best))
            screen.append((best[0] << 4) | best[1])
            colors.append(best[2])

    def encode_frame(frame, start_y, end_y, preview=None):
        bitmap = bytearray()
        cell_index = 0
        for cell_y in range(25):
            for cell_x in range(40):
                palette = triples[cell_index]
                cell_index += 1
                for row in range(8):
                    y = cell_y * 8 + row
                    if start_y <= y < end_y:
                        packed = 0
                        for column in range(4):
                            color = PALETTE.index(frame.getpixel((cell_x * 4 + column, y)))
                            nearest = min(range(4), key=lambda index: distances[color][palette[index]])
                            packed |= nearest << (6 - column * 2)
                            if preview is not None:
                                preview.putpixel((cell_x * 4 + column, y), PALETTE[palette[nearest]])
                        bitmap.append(packed)
        return bitmap

    preview = Image.new("RGB", (WIDTH, HEIGHT))
    bitmap = encode_frame(frames[0], 0, HEIGHT, preview)
    animation = bytearray()
    for frame in frames:
        animation.extend(encode_frame(frame, ANIM_Y, HEIGHT))

    assert len(bitmap) == 8000
    assert len(screen) == 1000
    assert len(colors) == 1000
    assert len(animation) == FRAME_COUNT * (HEIGHT - ANIM_Y) * 40
    (ROOT / "waterfall_bitmap.bin").write_bytes(bitmap)
    (ROOT / "waterfall_screen.bin").write_bytes(screen)
    (ROOT / "waterfall_colors.bin").write_bytes(colors)
    (ROOT / "waterfall_reu_frames.bin").write_bytes(animation)
    preview.resize((WIDTH * 2, HEIGHT), Image.Resampling.NEAREST).save(ROOT / "waterfall_preview.png")


if __name__ == "__main__":
    encode([draw_scene(frame) for frame in range(FRAME_COUNT)])