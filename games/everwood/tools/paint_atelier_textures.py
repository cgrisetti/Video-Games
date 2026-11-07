#!/usr/bin/env python3
"""Paints Everwood's eight craft textures by hand-stroke (docs/24_PAINTED_WORLD_PASS.md §3).

Each texture is painted the way a background painter would lay it in gouache:
broad washes first, then thousands of individual strokes, shapes and flecks,
each one a little different, all seamlessly tiling. Every shape is drawn at
2x and its wrapped copies are drawn across the tile's edges, so the result
tiles with no seam. Alongside each albedo it paints a height field (the same
shapes, in grey) and turns that into a normal map, and a roughness map.

Writes res://assets/textures/world/tex_<set>_{albedo,normal,roughness}.png,
which ProceduralTextureAtelier loads in place of its generated maps.

Needs only Python 3 and Pillow. Fixed seeds: the same textures every run.
    python3 tools/paint_atelier_textures.py            # all eight
    python3 tools/paint_atelier_textures.py turf loam  # some
"""
import math
import os
import random
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "textures", "world")
SIZE = 1024          # the saved albedo
NORMAL_SIZE = 512    # the saved normal and roughness maps (detail enough; the game resizes)
SS = 2               # paint at 2x and downsample: smooth, anti-aliased strokes
C = SIZE * SS        # the canvas


def hexc(text, alpha=255):
    text = text.lstrip("#")
    return (int(text[0:2], 16), int(text[2:4], 16), int(text[4:6], 16), alpha)


def jitter(rgba, rnd, amount=14):
    r, g, b, a = rgba
    shift = rnd.randint(-amount, amount)
    return (max(0, min(255, r + shift + rnd.randint(-4, 4))), max(0, min(255, g + shift + rnd.randint(-4, 4))),
            max(0, min(255, b + shift + rnd.randint(-4, 4))), a)


def lighten(rgba, amount):
    r, g, b, a = rgba
    return (min(255, int(r + (255 - r) * amount)), min(255, int(g + (255 - g) * amount)), min(255, int(b + (255 - b) * amount)), a)


def darken(rgba, amount):
    r, g, b, a = rgba
    return (int(r * (1 - amount)), int(g * (1 - amount)), int(b * (1 - amount)), a)


class Canvas:
    """An albedo, a height field and a roughness field, painted together and wrapped at the edges."""

    def __init__(self, base, height=110, rough=225):
        self.albedo = Image.new("RGBA", (C, C), hexc(base))
        self.height = Image.new("L", (C, C), height)
        self.rough = Image.new("L", (C, C), rough)
        self.a = ImageDraw.Draw(self.albedo, "RGBA")
        self.h = ImageDraw.Draw(self.height)
        self.r = ImageDraw.Draw(self.rough)

    def _copies(self, points):
        xs = [p[0] for p in points]
        ys = [p[1] for p in points]
        for dx in (-C, 0, C):
            if max(xs) + dx < 0 or min(xs) + dx > C:
                continue
            for dy in (-C, 0, C):
                if max(ys) + dy < 0 or min(ys) + dy > C:
                    continue
                yield [(x + dx, y + dy) for x, y in points]

    def poly(self, points, color, height=None, rough=None):
        for shifted in self._copies(points):
            self.a.polygon(shifted, fill=color)
            if height is not None:
                self.h.polygon(shifted, fill=height)
            if rough is not None:
                self.r.polygon(shifted, fill=rough)

    def line(self, points, color, width, height=None):
        for shifted in self._copies(points):
            self.a.line(shifted, fill=color, width=width, joint="curve")
            if height is not None:
                self.h.line(shifted, fill=height, width=width)

    def wash(self, blobs, blur):
        """Soft, broad colour washes: blobs on their own layer, blurred (wrapped), laid over."""
        layer = Image.new("RGBA", (C, C), (0, 0, 0, 0))
        draw = ImageDraw.Draw(layer, "RGBA")
        for points, color in blobs:
            for shifted in self._copies(points):
                draw.polygon(shifted, fill=color)
        layer = wrap_blur(layer, blur)
        self.albedo = Image.alpha_composite(self.albedo, layer)
        self.a = ImageDraw.Draw(self.albedo, "RGBA")

    def save(self, name, relief):
        os.makedirs(OUT, exist_ok=True)
        albedo = self.albedo.convert("RGB").resize((SIZE, SIZE), Image.LANCZOS)
        albedo.save(os.path.join(OUT, "tex_%s_albedo.png" % name), optimize=True)
        height = self.height.resize((NORMAL_SIZE * 2, NORMAL_SIZE * 2), Image.LANCZOS)
        normal_map(height, relief).resize((NORMAL_SIZE, NORMAL_SIZE), Image.LANCZOS).save(
            os.path.join(OUT, "tex_%s_normal.png" % name), optimize=True)
        self.rough.resize((NORMAL_SIZE, NORMAL_SIZE), Image.LANCZOS).save(os.path.join(OUT, "tex_%s_roughness.png" % name), optimize=True)
        print("painted", name)


def tile3(image):
    w, h = image.size
    big = Image.new(image.mode, (w * 3, h * 3))
    for i in range(3):
        for j in range(3):
            big.paste(image, (i * w, j * h))
    return big


def wrap_blur(image, radius):
    w, h = image.size
    return tile3(image).filter(ImageFilter.GaussianBlur(radius)).crop((w, h, w * 2, h * 2))


def normal_map(height, relief):
    """Height to a tangent-space normal map (x right, y up), wrapped so it tiles."""
    w, h = height.size
    big = tile3(height).filter(ImageFilter.GaussianBlur(1.2))
    scale = max(0.05, 1.0 / relief)
    gx = big.filter(ImageFilter.Kernel((3, 3), [-1, 0, 1, -2, 0, 2, -1, 0, 1], scale=scale * 8, offset=128))
    gy = big.filter(ImageFilter.Kernel((3, 3), [1, 2, 1, 0, 0, 0, -1, -2, -1], scale=scale * 8, offset=128))
    nx = ImageChops.invert(gx)
    blue = Image.new("L", big.size, 235)
    return Image.merge("RGB", (nx, gy, blue)).crop((w, h, w * 2, h * 2))


def ellipse_points(cx, cy, rx, ry, angle=0.0, n=18, wobble=0.0, rnd=None):
    pts = []
    for k in range(n):
        t = 2 * math.pi * k / n
        f = 1.0 + (rnd.uniform(-wobble, wobble) if rnd else 0.0)
        x = math.cos(t) * rx * f
        y = math.sin(t) * ry * f
        pts.append((cx + x * math.cos(angle) - y * math.sin(angle), cy + x * math.sin(angle) + y * math.cos(angle)))
    return pts


def stroke_points(x, y, angle, length, width, bend=0.0, segments=6):
    """A tapered brush stroke: fat in the middle, pointed at both ends, a little curved."""
    left, right = [], []
    for k in range(segments + 1):
        u = k / segments
        along = (u - 0.5) * length
        off = bend * (u - 0.5) ** 2 * length
        half = width * 0.5 * math.sin(math.pi * u) ** 0.6
        px = x + math.cos(angle) * along - math.sin(angle) * off
        py = y + math.sin(angle) * along + math.cos(angle) * off
        nx, ny = -math.sin(angle), math.cos(angle)
        left.append((px + nx * half, py + ny * half))
        right.append((px - nx * half, py - ny * half))
    return left + right[::-1]


def blade_points(x, y, angle, length, width, bend):
    """A grass blade: wide at its root, a point at its tip."""
    left, right = [], []
    for k in range(6):
        u = k / 5
        off = bend * u * u * length
        half = width * 0.5 * (1.0 - u)
        px = x + math.cos(angle) * u * length - math.sin(angle) * off
        py = y + math.sin(angle) * u * length + math.cos(angle) * off
        nx, ny = -math.sin(angle), math.cos(angle)
        left.append((px + nx * half, py + ny * half))
        right.append((px - nx * half, py - ny * half))
    return left + right[::-1]


def washes(canvas, rnd, colors, count, rmin, rmax, alpha, blur):
    blobs = []
    for _ in range(count):
        color = colors[rnd.randrange(len(colors))]
        blobs.append((ellipse_points(rnd.uniform(0, C), rnd.uniform(0, C), rnd.uniform(rmin, rmax), rnd.uniform(rmin, rmax),
                                     rnd.uniform(0, math.pi), 16, 0.25, rnd), color[:3] + (alpha,)))
    canvas.wash(blobs, blur)


# --- The eight crafts ----------------------------------------------------------------------------

def turf():
    """Meadow turf: washes of yellow-green and blue-green, thousands of grass strokes with sunlit tips, clover, a few flowers."""
    rnd = random.Random(501)
    cv = Canvas("#557F3E", 100, 240)
    washes(cv, rnd, [hexc("#7FA24A"), hexc("#3C6A34"), hexc("#4C7E58"), hexc("#8EA654")], 46, 120, 420, 120, 70)
    greens = [hexc("#4F7C3A"), hexc("#3E6B33"), hexc("#6A9446"), hexc("#7EA552"), hexc("#5B8A48"), hexc("#46755A")]
    for _ in range(16000):
        x, y = rnd.uniform(0, C), rnd.uniform(0, C)
        angle = rnd.uniform(-math.pi, math.pi)
        length = rnd.uniform(26, 70)
        color = jitter(greens[rnd.randrange(len(greens))], rnd, 10)
        cv.poly(blade_points(x, y, angle, length, rnd.uniform(5, 10), rnd.uniform(-0.35, 0.35)), color, rnd.randint(120, 200))
        if rnd.random() < 0.35:
            tip = lighten(color, 0.32)
            cv.poly(blade_points(x + math.cos(angle) * length * 0.55, y + math.sin(angle) * length * 0.55, angle, length * 0.4, 4, 0.1), tip, 210)
    for _ in range(320):
        x, y = rnd.uniform(0, C), rnd.uniform(0, C)
        leaf = jitter(hexc("#5E9447"), rnd, 8)
        for k in range(3):
            a = k * 2.09 + rnd.uniform(-0.3, 0.3)
            cv.poly(ellipse_points(x + math.cos(a) * 9, y + math.sin(a) * 9, 9, 7, a, 10), leaf, 170)
        cv.poly(ellipse_points(x, y, 3, 3, 0, 6), lighten(leaf, 0.3), 180)
    for _ in range(140):
        x, y = rnd.uniform(0, C), rnd.uniform(0, C)
        if rnd.random() < 0.6:
            for k in range(5):
                a = k * 1.2566
                cv.poly(ellipse_points(x + math.cos(a) * 6, y + math.sin(a) * 6, 5, 3, a, 8), (244, 240, 226, 255), 190)
            cv.poly(ellipse_points(x, y, 3.5, 3.5, 0, 8), (238, 190, 52, 255), 200)
        else:
            cv.poly(ellipse_points(x, y, 6, 6, 0, 10), jitter((240, 196, 48, 255), rnd, 10), 190)
    cv.save("meadow_turf", 1.8)


def loam():
    """Hollow loam: peat and earth, fallen oak leaves in amber and rust, twigs and pebbles."""
    rnd = random.Random(502)
    cv = Canvas("#55412F", 90, 235)
    washes(cv, rnd, [hexc("#3F2F22"), hexc("#6B523A"), hexc("#4A3A2C"), hexc("#5E4A30")], 50, 100, 360, 130, 50)
    for _ in range(5000):
        x, y = rnd.uniform(0, C), rnd.uniform(0, C)
        cv.poly(stroke_points(x, y, rnd.uniform(0, math.pi), rnd.uniform(10, 30), rnd.uniform(3, 7)),
                jitter(rnd.choice([hexc("#4A3828"), hexc("#6A523C"), hexc("#3A2B1F")]), rnd, 8), rnd.randint(80, 120))
    for _ in range(300):
        x, y = rnd.uniform(0, C), rnd.uniform(0, C)
        r = rnd.uniform(6, 16)
        stone = jitter(rnd.choice([hexc("#8C8579"), hexc("#7A7166"), hexc("#9C9082")]), rnd, 10)
        cv.poly(ellipse_points(x, y, r, r * rnd.uniform(0.6, 0.9), rnd.uniform(0, 3), 12, 0.15, rnd), stone, 190)
        cv.poly(ellipse_points(x - r * 0.25, y - r * 0.3, r * 0.45, r * 0.3, 0.4, 8), lighten(stone, 0.25), 210)
    for _ in range(180):
        x, y = rnd.uniform(0, C), rnd.uniform(0, C)
        a = rnd.uniform(0, math.pi)
        cv.line([(x, y), (x + math.cos(a) * rnd.uniform(40, 120), y + math.sin(a) * rnd.uniform(40, 120))],
                jitter(hexc("#3D2E22"), rnd, 8), rnd.randint(3, 6), 160)
    leaf_colors = [hexc("#A8692E"), hexc("#8C4A25"), hexc("#B98A3E"), hexc("#6B4A2C"), hexc("#9A7A3A")]
    for _ in range(700):
        x, y = rnd.uniform(0, C), rnd.uniform(0, C)
        a = rnd.uniform(0, 2 * math.pi)
        length = rnd.uniform(34, 62)
        color = jitter(leaf_colors[rnd.randrange(len(leaf_colors))], rnd, 12)
        pts = []
        for k in range(13):
            u = k / 12
            lobe = 1.0 + 0.3 * abs(math.sin(u * math.pi * 3.5))
            w = math.sin(u * math.pi) * length * 0.28 * lobe
            pts.append((u * length, w))
        pts += [(u, -w) for (u, w) in pts[::-1]]
        rotated = [(x + px * math.cos(a) - py * math.sin(a), y + px * math.sin(a) + py * math.cos(a)) for px, py in pts]
        cv.poly(rotated, color, 150)
        cv.line([(x, y), (x + math.cos(a) * length * 0.95, y + math.sin(a) * length * 0.95)], darken(color, 0.3), 2)
    cv.save("hollow_loam", 2.2)


def flagstone():
    """Cobbled flagstone: irregular worn setts, sunlit on one shoulder, cracked, moss and grit in the joints."""
    rnd = random.Random(503)
    cv = Canvas("#7E7462", 40, 245)
    washes(cv, rnd, [hexc("#6E6656"), hexc("#8A7F68"), hexc("#5E6B44")], 40, 60, 200, 140, 18)
    cells = 7
    step = C / cells
    stones = [hexc("#CDC2A8"), hexc("#BFA686"), hexc("#B3A890"), hexc("#D3BC95"), hexc("#A99F8B"), hexc("#C4B28E")]
    for i in range(cells):
        for j in range(cells):
            cx = (i + 0.5 + rnd.uniform(-0.18, 0.18) + (0.5 if j % 2 else 0.0)) * step
            cy = (j + 0.5 + rnd.uniform(-0.15, 0.15)) * step
            rx = step * rnd.uniform(0.5, 0.56)
            ry = step * rnd.uniform(0.48, 0.54)
            a = rnd.uniform(-0.3, 0.3)
            base = jitter(stones[rnd.randrange(len(stones))], rnd, 10)
            # A worn sett: few, uneven sides, its corners knocked round.
            shape = ellipse_points(cx, cy, rx, ry, a, rnd.randint(6, 8), 0.16, rnd)
            shape = [((x + shape[(k + 1) % len(shape)][0]) * 0.5, (y + shape[(k + 1) % len(shape)][1]) * 0.5) for k, (x, y) in enumerate(shape)] + shape
            shape = ellipse_points(cx, cy, rx, ry, a, 14, 0.06, rnd) if rnd.random() < 0.25 else sorted(
                shape, key=lambda p: math.atan2(p[1] - cy, p[0] - cx))
            cv.poly(shape, darken(base, 0.18), 150, 235)
            cv.poly([(cx + (x - cx) * 0.9 - 4, cy + (y - cy) * 0.9 - 4) for x, y in shape], base, 200, 220)
            # The sunlit shoulder and a few worn strokes across the face.
            cv.poly(ellipse_points(cx - rx * 0.3, cy - ry * 0.32, rx * 0.5, ry * 0.32, a - 0.3, 12), lighten(base, 0.16), 215)
            for _ in range(rnd.randint(6, 12)):
                sx, sy = cx + rnd.uniform(-rx, rx) * 0.6, cy + rnd.uniform(-ry, ry) * 0.6
                cv.poly(stroke_points(sx, sy, a + rnd.uniform(-0.4, 0.4), rnd.uniform(30, 80), rnd.uniform(5, 12)),
                        jitter(base, rnd, 14)[:3] + (150,), None)
            if rnd.random() < 0.55:
                x0, y0 = cx + rnd.uniform(-rx, rx) * 0.5, cy + rnd.uniform(-ry, ry) * 0.5
                pts = [(x0, y0)]
                heading = rnd.uniform(0, 2 * math.pi)
                for _ in range(rnd.randint(4, 7)):
                    heading += rnd.uniform(-0.6, 0.6)
                    x0 += math.cos(heading) * rnd.uniform(14, 30)
                    y0 += math.sin(heading) * rnd.uniform(14, 30)
                    pts.append((x0, y0))
                cv.line(pts, darken(base, 0.4), 3, 140)
            for _ in range(rnd.randint(2, 7)):
                t = rnd.uniform(0, 2 * math.pi)
                mx, my = cx + math.cos(t) * rx * 0.95, cy + math.sin(t) * ry * 0.95
                cv.poly(ellipse_points(mx, my, rnd.uniform(6, 14), rnd.uniform(5, 10), t, 9, 0.3, rnd), jitter(hexc("#56783A"), rnd, 12), 130)
    cv.save("cobbled_flagstone", 5.0)


def granite():
    """Crag granite: stratified stone in long strokes, cracks, lichen rosettes and heather in the joints."""
    rnd = random.Random(504)
    cv = Canvas("#767D84", 120, 240)
    washes(cv, rnd, [hexc("#646A72"), hexc("#8B9198"), hexc("#7C7A74"), hexc("#6A7068")], 46, 120, 400, 130, 50)
    greys = [hexc("#71757A"), hexc("#888B8E"), hexc("#606366"), hexc("#999C9C"), hexc("#7D7973")]
    for _ in range(2600):
        x, y = rnd.uniform(0, C), rnd.uniform(0, C)
        a = rnd.uniform(-0.25, 0.25)
        cv.poly(stroke_points(x, y, a, rnd.uniform(80, 340), rnd.uniform(10, 30), rnd.uniform(-0.15, 0.15)),
                jitter(greys[rnd.randrange(len(greys))], rnd, 6)[:3] + (150,), rnd.randint(90, 170))
    for _ in range(70):
        x0, y0 = rnd.uniform(0, C), rnd.uniform(0, C)
        pts = [(x0, y0)]
        for _ in range(rnd.randint(4, 9)):
            x0 += rnd.uniform(20, 70)
            y0 += rnd.uniform(-30, 30)
            pts.append((x0, y0))
        cv.line(pts, (42, 44, 48, 255), rnd.randint(3, 6), 40)
    for _ in range(90):
        x, y = rnd.uniform(0, C), rnd.uniform(0, C)
        color = rnd.choice([hexc("#A3A65E"), hexc("#B8B47A"), hexc("#9FA67A"), hexc("#B98A4A")])
        r = rnd.uniform(6, 22)
        cv.poly(ellipse_points(x, y, r, r * 0.8, rnd.uniform(0, 3), 12, 0.3, rnd), jitter(color, rnd, 10), 150)
        for _ in range(3):
            cv.poly(ellipse_points(x + rnd.uniform(-r, r), y + rnd.uniform(-r, r), r * 0.35, r * 0.3, 0, 8), lighten(color, 0.2), 155)
    for _ in range(40):
        x, y = rnd.uniform(0, C), rnd.uniform(0, C)
        for _ in range(6):
            a = rnd.uniform(-math.pi, 0)
            cv.poly(blade_points(x, y, a, rnd.uniform(14, 30), 5, 0.2), jitter(hexc("#7B587D"), rnd, 12), 150)
    cv.save("crag_granite", 4.0)


def timber():
    """Hewn timber: oak planks with wandering grain, knots, adze scallops, dark gaps and pegs."""
    rnd = random.Random(505)
    cv = Canvas("#3C281A", 30, 230)
    planks = 6
    width = C / planks
    oaks = [hexc("#6E4B2E"), hexc("#7B5535"), hexc("#5E3F27"), hexc("#80603F"), hexc("#694630")]
    for p in range(planks):
        x0 = p * width + 5
        x1 = (p + 1) * width - 5
        base = jitter(oaks[rnd.randrange(len(oaks))], rnd, 8)
        cv.poly([(x0, -10), (x1, -10), (x1, C + 10), (x0, C + 10)], base, 170, 225)
        for _ in range(70):
            gx = rnd.uniform(x0 + 6, x1 - 6)
            gy = rnd.uniform(0, C)
            pts = []
            for k in range(14):
                y = gy + k * 40
                pts.append((gx + math.sin(y * 0.01 + gx) * 6 + rnd.uniform(-1.5, 1.5), y))
            color = darken(base, rnd.uniform(0.1, 0.35)) if rnd.random() < 0.6 else lighten(base, rnd.uniform(0.08, 0.2))
            cv.line(pts, color, rnd.randint(2, 4), 160)
        for _ in range(rnd.randint(1, 2)):
            kx, ky = rnd.uniform(x0 + 30, x1 - 30), rnd.uniform(0, C)
            for ring in range(5, 0, -1):
                cv.poly(ellipse_points(kx, ky, ring * 7, ring * 11, 0, 14), darken(base, 0.1 + ring * 0.05), 150 + ring * 4)
        for _ in range(26):
            ay = rnd.uniform(0, C)
            cv.poly(stroke_points(rnd.uniform(x0 + 20, x1 - 20), ay, math.pi * 0.5 + rnd.uniform(-0.08, 0.08), rnd.uniform(60, 140), rnd.uniform(10, 22)),
                    lighten(base, 0.06)[:3] + (70,), None)
        for py in (rnd.uniform(60, 200), rnd.uniform(C * 0.55, C * 0.7)):
            px = (x0 + x1) * 0.5
            cv.poly(ellipse_points(px, py, 11, 11, 0, 12), (40, 28, 20, 255), 120)
            cv.poly(ellipse_points(px - 3, py - 3, 4, 4, 0, 8), lighten(base, 0.25), 140)
    cv.save("hewn_timber", 3.0)


def brick():
    """Stepped brick: running-bond kiln bricks, each its own fired colour, chipped corners, soot and moss in the joints."""
    rnd = random.Random(506)
    cv = Canvas("#CFC6B4", 40, 240)
    washes(cv, rnd, [hexc("#B8AE9A"), hexc("#9E9584"), hexc("#7E8A5E")], 30, 40, 160, 120, 14)
    rows = 12
    per_row = 5
    rh = C / rows
    bw = C / per_row
    bricks = [hexc("#B85D43"), hexc("#A8533D"), hexc("#C26A4B"), hexc("#B9824F"), hexc("#9C4A36"), hexc("#B36A50")]
    for r in range(rows):
        offset = (bw * 0.5) if r % 2 else 0.0
        for k in range(-1, per_row + 1):
            x0 = k * bw + offset + 7
            x1 = (k + 1) * bw + offset - 7
            y0 = r * rh + 7
            y1 = (r + 1) * rh - 7
            base = jitter(bricks[rnd.randrange(len(bricks))], rnd, 12)
            chip = rnd.uniform(4, 16)
            shape = [(x0 + chip, y0), (x1, y0 + rnd.uniform(0, 4)), (x1 - rnd.uniform(0, 6), y1), (x0, y1 - rnd.uniform(0, 3)), (x0, y0 + chip)]
            cv.poly(shape, base, 190, 220)
            cv.poly([(x0 + 6, y0 + 4), (x1 - 4, y0 + 4), (x1 - 8, y0 + 12), (x0 + 8, y0 + 12)], lighten(base, 0.14), 200)
            for _ in range(10):
                cv.poly(stroke_points(rnd.uniform(x0, x1), rnd.uniform(y0, y1), rnd.uniform(-0.2, 0.2), rnd.uniform(20, 70), rnd.uniform(4, 9)),
                        jitter(base, rnd, 16)[:3] + (140,), None)
            for _ in range(rnd.randint(4, 12)):
                cv.poly(ellipse_points(rnd.uniform(x0, x1), rnd.uniform(y0, y1), 2.5, 2.5, 0, 6), darken(base, 0.35), 160)
    washes(cv, rnd, [(40, 34, 30, 255), (70, 92, 50, 255)], 24, 60, 220, 70, 30)
    cv.save("stepped_brick", 4.0)


def plaster():
    """Lime plaster: warm troweled lime-wash, damp and age stains, hairline cracks, a fallen patch showing the stone beneath."""
    rnd = random.Random(507)
    cv = Canvas("#EEE6D6", 140, 230)
    washes(cv, rnd, [hexc("#F6F0E4"), hexc("#E2D6BE"), hexc("#D8CDB6"), hexc("#E9DDC4")], 60, 80, 300, 150, 40)
    for _ in range(1400):
        x, y = rnd.uniform(0, C), rnd.uniform(0, C)
        cv.poly(stroke_points(x, y, rnd.uniform(-0.6, 0.6), rnd.uniform(60, 180), rnd.uniform(18, 40), rnd.uniform(-0.3, 0.3)),
                jitter(hexc("#ECE3D2"), rnd, 9)[:3] + (110,), rnd.randint(130, 150))
    washes(cv, rnd, [hexc("#B9AE96"), hexc("#A7A08A"), hexc("#8E9A74")], 18, 80, 260, 70, 60)
    for _ in range(26):
        x0, y0 = rnd.uniform(0, C), rnd.uniform(0, C)
        pts = [(x0, y0)]
        for _ in range(rnd.randint(4, 10)):
            x0 += rnd.uniform(-30, 30)
            y0 += rnd.uniform(10, 40)
            pts.append((x0, y0))
        cv.line(pts, (120, 108, 92, 255), 2, 100)
    for _ in range(3):
        cx, cy = rnd.uniform(0, C), rnd.uniform(0, C)
        shape = ellipse_points(cx, cy, rnd.uniform(70, 130), rnd.uniform(50, 100), rnd.uniform(0, 3), 16, 0.35, rnd)
        cv.poly(shape, (150, 136, 116, 255), 90)
        for _ in range(9):
            cv.poly(ellipse_points(cx + rnd.uniform(-60, 60), cy + rnd.uniform(-45, 45), rnd.uniform(14, 26), rnd.uniform(10, 18), 0, 10, 0.2, rnd),
                    jitter(hexc("#A59A86"), rnd, 14), 110)
    cv.save("lime_plaster", 1.4)


def shingle():
    """Scallop shingle: rows of overlapping rounded slates, each its own grey-blue, moss clumps and lichen."""
    rnd = random.Random(508)
    cv = Canvas("#3A4048", 40, 230)
    rows = 10
    per_row = 8
    rh = C / rows
    tw = C / per_row
    slates = [hexc("#6F7E8C"), hexc("#5F6E7C"), hexc("#7E8A94"), hexc("#687480"), hexc("#7A7E86"), hexc("#8A7A6E")]
    for r in range(rows - 1, -2, -1):
        offset = (tw * 0.5) if r % 2 else 0.0
        for k in range(-1, per_row + 1):
            cx = k * tw + offset + tw * 0.5
            top = r * rh - rh * 0.4
            bottom = (r + 1) * rh
            base = jitter(slates[rnd.randrange(len(slates))], rnd, 10)
            pts = [(cx - tw * 0.48, top), (cx + tw * 0.48, top)]
            for s in range(13):
                t = s / 12
                pts.append((cx + math.cos(t * math.pi) * tw * 0.48, bottom - rh * 0.35 + math.sin(t * math.pi) * rh * 0.35))
            cv.poly([(x, y + 10) for x, y in pts], (30, 32, 36, 160), None)
            cv.poly(pts, base, 160, 210)
            cv.poly([(cx - tw * 0.4, bottom - rh * 0.5), (cx + tw * 0.4, bottom - rh * 0.5), (cx + tw * 0.38, bottom - rh * 0.38), (cx - tw * 0.38, bottom - rh * 0.38)],
                    lighten(base, 0.12)[:3] + (150,), 190)
            for _ in range(6):
                cv.poly(stroke_points(rnd.uniform(cx - tw * 0.35, cx + tw * 0.35), rnd.uniform(top + rh * 0.3, bottom - 10), rnd.uniform(1.2, 1.9),
                                      rnd.uniform(20, 50), rnd.uniform(4, 8)), jitter(base, rnd, 14)[:3] + (120,), None)
    for _ in range(110):
        x, y = rnd.uniform(0, C), rnd.uniform(0, C)
        r = rnd.uniform(10, 34)
        moss = jitter(rnd.choice([hexc("#5E7F3E"), hexc("#6E8E44"), hexc("#4A6A36")]), rnd, 10)
        cv.poly(ellipse_points(x, y, r, r * 0.7, rnd.uniform(0, 3), 14, 0.35, rnd), moss, 175)
        cv.poly(ellipse_points(x - r * 0.2, y - r * 0.2, r * 0.45, r * 0.3, 0, 10), lighten(moss, 0.2), 185)
    for _ in range(200):
        cv.poly(ellipse_points(rnd.uniform(0, C), rnd.uniform(0, C), rnd.uniform(3, 8), rnd.uniform(3, 7), 0, 8),
                jitter(rnd.choice([hexc("#C9C27A"), hexc("#B9B48C")]), rnd, 10), 170)
    cv.save("scallop_shingle", 4.5)


SETS = {"flagstone": flagstone, "brick": brick, "plaster": plaster, "timber": timber, "shingle": shingle, "turf": turf, "loam": loam, "granite": granite}

if __name__ == "__main__":
    wanted = sys.argv[1:] or list(SETS.keys())
    for name in wanted:
        SETS[name]()
