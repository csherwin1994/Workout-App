#!/usr/bin/env python3
"""
Generate Volt app icons using only Python stdlib.
Produces PNG files at all required iOS sizes.
Design: Dark (#0A0A0B) background with blue-to-purple gradient Split V mark.
"""
import struct, zlib, math, os

OUT = "Volt/Assets.xcassets/AppIcon.appiconset"

SIZES = [
    ("AppIcon-20@2x.png",  40),
    ("AppIcon-20@3x.png",  60),
    ("AppIcon-29@2x.png",  58),
    ("AppIcon-29@3x.png",  87),
    ("AppIcon-40@2x.png",  80),
    ("AppIcon-40@3x.png",  120),
    ("AppIcon-60@2x.png",  120),
    ("AppIcon-60@3x.png",  180),
    ("AppIcon-1024.png",   1024),
]

def write_png(path, pixels, w, h):
    """pixels: list of (r,g,b,a) tuples, row-major."""
    def chunk(tag, data):
        c = zlib.crc32(tag + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", c)

    raw = b""
    for y in range(h):
        raw += b"\x00"  # filter type None
        for x in range(w):
            r, g, b, a = pixels[y * w + x]
            raw += bytes([r, g, b, a])

    compressed = zlib.compress(raw, 9)
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)  # 8-bit RGBA

    png  = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", ihdr)
    png += chunk(b"IDAT", compressed)
    png += chunk(b"IEND", b"")

    with open(path, "wb") as f:
        f.write(png)

def lerp(a, b, t):
    return a + (b - a) * t

def lerp_color(c1, c2, t):
    return tuple(int(lerp(c1[i], c2[i], t)) for i in range(3))

def generate_icon(size):
    w = h = size
    pixels = []

    # Colours from brand board
    BG     = (10, 10, 11)      # #0A0A0B
    BLUE   = (91, 142, 255)    # #5B8EFF
    PURPLE = (167, 139, 250)   # #A78BFA

    s = size / 100.0  # scale factor

    # Split V mark geometry — a V shape split down the middle
    # with a small gap, creating the premium "Split V" logo
    cx = 50 * s   # centre x
    top_y = 22 * s    # top of V arms
    bot_y = 78 * s    # bottom point of V
    gap = 2.5 * s     # half-gap between the two halves
    arm_w = 7.5 * s   # thickness of each V arm

    # The V is defined by two diagonal strokes meeting at the bottom
    # Left arm: from top-left down to bottom-centre (with gap)
    # Right arm: from top-right down to bottom-centre (with gap)

    # Left arm endpoints
    left_top_outer = (cx - 22 * s, top_y)
    left_top_inner = (cx - 22 * s + arm_w, top_y)
    left_bot_outer = (cx - gap, bot_y)
    left_bot_inner = (cx - gap, bot_y - arm_w * 1.2)

    # Right arm endpoints
    right_top_outer = (cx + 22 * s, top_y)
    right_top_inner = (cx + 22 * s - arm_w, top_y)
    right_bot_outer = (cx + gap, bot_y)
    right_bot_inner = (cx + gap, bot_y - arm_w * 1.2)

    def point_in_parallelogram(px, py, x1, y1, x2, y2, x3, y3, x4, y4):
        """Check if point is inside a quadrilateral defined by 4 vertices (in order)."""
        def cross(ox, oy, ax, ay, bx, by):
            return (ax - ox) * (by - oy) - (ay - oy) * (bx - ox)

        d1 = cross(px, py, x1, y1, x2, y2)
        d2 = cross(px, py, x2, y2, x3, y3)
        d3 = cross(px, py, x3, y3, x4, y4)
        d4 = cross(px, py, x4, y4, x1, y1)

        has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0) or (d4 < 0)
        has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0) or (d4 > 0)

        return not (has_neg and has_pos)

    for y in range(h):
        for x in range(w):
            r, g, b, a = BG[0], BG[1], BG[2], 255

            # Gradient: diagonal from top-left (blue) to bottom-right (purple)
            t = ((x / w) + (y / h)) / 2.0
            grad = lerp_color(BLUE, PURPLE, t)

            on_v = False

            # Left arm of V (quad: top-outer, top-inner, bot-inner, bot-outer)
            if point_in_parallelogram(x, y,
                left_top_outer[0], left_top_outer[1],
                left_top_inner[0], left_top_inner[1],
                left_bot_inner[0], left_bot_inner[1],
                left_bot_outer[0], left_bot_outer[1]):
                on_v = True

            # Right arm of V (quad: top-inner, top-outer, bot-outer, bot-inner)
            if point_in_parallelogram(x, y,
                right_top_inner[0], right_top_inner[1],
                right_top_outer[0], right_top_outer[1],
                right_bot_outer[0], right_bot_outer[1],
                right_bot_inner[0], right_bot_inner[1]):
                on_v = True

            if on_v:
                r, g, b = grad

            pixels.append((r, g, b, a))

    return pixels

def main():
    os.makedirs(OUT, exist_ok=True)
    for filename, size in SIZES:
        path = os.path.join(OUT, filename)
        pixels = generate_icon(size)
        write_png(path, pixels, size, size)
        print(f"  Generated {filename} ({size}x{size})")
    print("Done.")

if __name__ == "__main__":
    main()
