#!/usr/bin/env python3
"""
Generate IronLog app icons using only Python stdlib.
Produces PNG files at all required iOS sizes.
Design: Dark (#0A0A0B) rounded-rect background,
        blue-to-purple gradient dumbbell / "IL" mark.
"""
import struct, zlib, math, os

OUT = "IronLog/Assets.xcassets/AppIcon.appiconset"

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
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)  # 8-bit RGB (not RGBA)
    # Use RGBA (color type 6)
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)

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

    # Colours
    BG       = (10, 10, 11)
    BLUE     = (91, 142, 255)
    PURPLE   = (167, 139, 250)
    WHITE    = (255, 255, 255)
    DARK_BG  = (10, 10, 11)

    corner_r = size * 0.22  # iOS icon corner radius ratio

    def in_rounded_rect(x, y, rx, ry, rw, rh, r):
        # Returns True if point (x,y) is inside rounded rect
        if x < rx or x > rx + rw or y < ry or y > ry + rh:
            return False
        # Check corners
        corners = [(rx+r, ry+r), (rx+rw-r, ry+r), (rx+r, ry+rh-r), (rx+rw-r, ry+rh-r)]
        for (cx, cy) in corners:
            if x < cx - r or x > cx + r or y < cy - r or y > cy + r:
                continue
            if (x - cx)**2 + (y - cy)**2 > r**2:
                # Near a corner — check if outside circle
                if x < cx and y < cy:  # top-left corner
                    if (x - (rx+r))**2 + (y - (ry+r))**2 > r**2 and x < rx+r and y < ry+r:
                        return False
                elif x > cx and y < cy:  # top-right corner
                    if (x - (rx+rw-r))**2 + (y - (ry+r))**2 > r**2 and x > rx+rw-r and y < ry+r:
                        return False
                elif x < cx and y > cy:  # bottom-left corner
                    if (x - (rx+r))**2 + (y - (ry+rh-r))**2 > r**2 and x < rx+r and y > ry+rh-r:
                        return False
                elif x > cx and y > cy:  # bottom-right corner
                    if (x - (rx+rw-r))**2 + (y - (ry+rh-r))**2 > r**2 and x > rx+rw-r and y > ry+rh-r:
                        return False
        return True

    def in_circle(x, y, cx, cy, r):
        return (x - cx)**2 + (y - cy)**2 <= r**2

    def in_rect(x, y, rx, ry, rw, rh):
        return rx <= x <= rx + rw and ry <= y <= ry + rh

    # Dumbbell geometry (scaled to size)
    s = size / 100.0  # scale factor

    # Bar
    bar_x1 = 20 * s
    bar_x2 = 80 * s
    bar_y1 = 47 * s
    bar_y2 = 53 * s

    # Left weight plates
    lp_x = 16 * s
    lp_r = 14 * s
    lp_inner_r = 9 * s
    # Right weight plates
    rp_x = 84 * s
    rp_r = 14 * s
    rp_inner_r = 9 * s

    cy = 50 * s  # centre y

    for y in range(h):
        for x in range(w):
            # Background — pure dark
            r, g, b, a = BG[0], BG[1], BG[2], 255

            # Gradient position for icon mark (left=blue, right=purple)
            t = (x / w)
            grad = lerp_color(BLUE, PURPLE, t)

            # Draw dumbbell
            on_dumbbell = False

            # Bar
            if in_rect(x, y, bar_x1, bar_y1, bar_x2 - bar_x1, bar_y2 - bar_y1):
                on_dumbbell = True

            # Left plate (outer circle minus inner hole)
            if in_circle(x, y, lp_x, cy, lp_r) and not in_circle(x, y, lp_x, cy, lp_r * 0.35):
                on_dumbbell = True

            # Right plate
            if in_circle(x, y, rp_x, cy, rp_r) and not in_circle(x, y, rp_x, cy, rp_r * 0.35):
                on_dumbbell = True

            if on_dumbbell:
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
