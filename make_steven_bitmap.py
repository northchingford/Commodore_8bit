#!/usr/bin/env python3
"""Generate a C64 multicolor bitmap inspired by the supplied fitness artwork."""

from pathlib import Path
import random

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
WIDTH, HEIGHT = 160, 200
BLACK = (0, 0, 0)
WHITE = (238, 236, 228)
RED = (224, 31, 34)
PALETTE = [
    (0, 0, 0), (255, 255, 255), (136, 0, 0), (170, 255, 238),
    (204, 68, 204), (0, 204, 85), (0, 0, 170), (238, 238, 119),
    (221, 136, 85), (102, 68, 0), (255, 119, 119), (51, 51, 51),
    (119, 119, 119), (170, 255, 102), (0, 136, 255), (187, 187, 187),
]
FONT = "/usr/share/fonts/truetype/liberation/LiberationSans-BoldItalic.ttf"


def fit_text(draw, text, size, max_width):
    font = ImageFont.truetype(FONT, size)
    box = draw.textbbox((0, 0), text, font=font, stroke_width=1)
    layer = Image.new("RGB", (box[2] - box[0] + 4, box[3] - box[1] + 4), BLACK)
    ImageDraw.Draw(layer).text((2 - box[0], 2 - box[1]), text, font=font,
                               fill=WHITE, stroke_width=1, stroke_fill=WHITE)
    if layer.width > max_width:
        layer = layer.resize((max_width, layer.height), Image.Resampling.LANCZOS)
    return layer


def draw_scene():
    image = Image.new("RGB", (WIDTH, HEIGHT), BLACK)
    draw = ImageDraw.Draw(image)

    random.seed(64)
    for _ in range(160):
        x, y = random.randrange(WIDTH), random.randrange(HEIGHT)
        if y < 85 or y > 150:
            draw.point((x, y), fill=(75, 75, 75))

    draw.ellipse((69, 5, 102, 38), fill=(180, 180, 180))
    draw.polygon([(22, 63), (55, 12), (78, 51), (88, 40), (105, 65)], fill=(95, 95, 95))
    draw.polygon([(38, 63), (62, 23), (87, 63)], fill=(185, 185, 185))
    draw.polygon([(55, 38), (62, 23), (69, 39), (65, 36), (62, 31), (59, 38)], fill=WHITE)
    draw.polygon([(78, 62), (96, 36), (117, 64)], fill=(115, 115, 115))
    for x in range(23, 112, 5):
        y = 61 - (x % 4)
        draw.polygon([(x, y + 12), (x + 2, y), (x + 4, y + 12)], fill=(28, 28, 28))

    draw.line([(101, 65), (87, 69), (69, 73), (59, 78), (67, 82), (97, 82)],
              fill=(185, 185, 185), width=5)
    draw.line([(101, 65), (87, 69), (69, 73), (59, 78), (67, 82), (97, 82)],
              fill=BLACK, width=2)

    # Stacked iron plates and the short barbell at the left edge.
    draw.line((4, 63, 54, 63), fill=(190, 190, 190), width=3)
    for box in [(3, 45, 18, 78), (8, 39, 24, 83), (15, 34, 31, 87),
                (25, 37, 40, 84), (36, 43, 48, 79)]:
        draw.ellipse(box, fill=(105, 105, 105), outline=(220, 220, 220), width=2)
        draw.ellipse((box[0] + 4, box[1] + 5, box[2] - 4, box[3] - 5),
                     outline=(35, 35, 35), width=2)

    # Bicycle and rider, placed above the title line.
    draw.ellipse((82, 52, 103, 73), outline=(180, 180, 180), width=2)
    draw.ellipse((109, 52, 130, 73), outline=(180, 180, 180), width=2)
    draw.line([(92, 62), (101, 52), (114, 62), (92, 62), (105, 62), (101, 52),
               (118, 48), (114, 62)], fill=(210, 210, 210), width=2)
    draw.line([(100, 51), (104, 40), (115, 34), (122, 39), (115, 45), (107, 47)],
              fill=RED, width=6)
    draw.line([(115, 36), (121, 27), (127, 24)], fill=(225, 225, 225), width=3)
    draw.ellipse((117, 20, 129, 30), fill=(190, 190, 190), outline=WHITE)
    draw.arc((117, 17, 132, 31), 190, 350, fill=WHITE, width=2)
    draw.line([(112, 44), (117, 54), (113, 60)], fill=(200, 200, 200), width=3)

    # Runner silhouette and ECG streaks.
    draw.line([(130, 50), (136, 43), (141, 48), (138, 57), (133, 62),
               (139, 69), (146, 75)], fill=WHITE, width=4)
    draw.line([(135, 60), (128, 66), (125, 75)], fill=(180, 180, 180), width=3)
    draw.line([(139, 58), (146, 60), (151, 68)], fill=(180, 180, 180), width=3)
    draw.ellipse((135, 34, 144, 44), fill=(20, 20, 20), outline=WHITE, width=2)
    draw.line([(95, 47), (103, 47), (106, 40), (109, 53), (112, 45),
               (118, 45), (121, 39), (124, 52), (128, 46), (135, 46)], fill=RED, width=2)

    # Guitar body and neck on the right.
    guitar = Image.new("RGBA", (54, 84), (0, 0, 0, 0))
    gd = ImageDraw.Draw(guitar)
    gd.line((34, 12, 19, 69), fill=(210, 210, 210, 255), width=7)
    gd.polygon([(34, 51), (41, 52), (42, 63), (37, 68), (42, 74), (37, 81),
                (27, 77), (24, 70), (29, 64), (27, 57)],
               fill=(95, 95, 95, 255), outline=(240, 240, 240, 255))
    gd.ellipse((31, 63, 37, 69), fill=(10, 10, 10, 255), outline=WHITE)
    for sx in range(30, 38, 2):
        gd.line((sx, 13, sx - 13, 68), fill=(230, 230, 230, 255), width=1)
    for y in range(20, 52, 5):
        gd.line((27, y, 36, y + 2), fill=(30, 30, 30, 255), width=1)
    rotated = guitar.rotate(15, resample=Image.Resampling.BICUBIC, expand=True)
    image.paste(rotated, (102, 80), rotated)

    # Crowd silhouettes at the foot of the composition.
    for x in range(7, 156, 8):
        head_y = 160 + (x * 7 % 8)
        draw.ellipse((x, head_y, x + 6, head_y + 7), fill=(18, 18, 18), outline=WHITE)
        draw.polygon([(x - 2, head_y + 17), (x, head_y + 8), (x + 6, head_y + 8),
                      (x + 9, head_y + 18)], fill=(24, 24, 24), outline=(170, 170, 170))
    draw.line([(0, 158), (9, 158), (13, 150), (16, 168), (20, 157),
               (26, 157), (30, 149), (33, 166), (37, 157), (47, 157)], fill=RED, width=2)

    # Large, centered brush-like name treatment.
    title = fit_text(draw, "STEVEN", 35, 148)
    image.paste(title, ((WIDTH - title.width) // 2, 78))
    draw = ImageDraw.Draw(image)
    croucher = fit_text(draw, "CROUCHER", 30, 154)
    red_layer = Image.new("RGB", croucher.size, BLACK)
    mask = croucher.convert("L")
    red_layer.paste(RED, (0, 0, croucher.width, croucher.height), mask)
    image.paste(red_layer, ((WIDTH - red_layer.width) // 2, 111))

    draw = ImageDraw.Draw(image)
    tagline_font = ImageFont.truetype(FONT, 7)
    tagline = "LIFT  .  RIDE  .  RUN  .  ROCK  .  LIVE STRONGER"
    bounds = draw.textbbox((0, 0), tagline, font=tagline_font)
    tagline_image = Image.new("RGB", (bounds[2] - bounds[0], 10), BLACK)
    ImageDraw.Draw(tagline_image).text((0, -bounds[1]), tagline, font=tagline_font, fill=WHITE)
    if tagline_image.width > 154:
        tagline_image = tagline_image.resize((154, 10), Image.Resampling.LANCZOS)
    image.paste(tagline_image, ((WIDTH - tagline_image.width) // 2, 183))
    return image


def color_distance(left, right):
    return sum((a - b) ** 2 for a, b in zip(left, right))


def encode(image):
    bitmap = bytearray()
    cell_colors = bytearray()
    shared = [PALETTE[0], PALETTE[1], PALETTE[2]]
    for cell_y in range(25):
        for cell_x in range(40):
            pixels = [image.getpixel((cell_x * 4 + px, cell_y * 8 + py))
                      for py in range(8) for px in range(4)]
            candidates = range(3, len(PALETTE))
            local_index = min(
                candidates,
                key=lambda candidate: sum(
                    min(color_distance(pixel, base) for base in shared + [PALETTE[candidate]])
                    for pixel in pixels),
            )
            colors = shared + [PALETTE[local_index]]
            cell_colors.append(local_index)
            for row in range(8):
                packed = 0
                for column in range(4):
                    pixel = pixels[row * 4 + column]
                    color_index = min(range(4), key=lambda idx: color_distance(pixel, colors[idx]))
                    packed |= color_index << (6 - column * 2)
                bitmap.append(packed)
    (ROOT / "steven_bitmap.bin").write_bytes(bitmap)
    (ROOT / "steven_colors.bin").write_bytes(cell_colors)
    preview = image.resize((WIDTH * 2, HEIGHT), Image.Resampling.NEAREST)
    preview.save(ROOT / "steven_preview.png")


if __name__ == "__main__":
    encode(draw_scene())