"""Embershore world generator (Everwood, Zone 1).
Deterministic: same seed -> same island. Usage: python3 embershore_gen.py <out_dir> [seed=7]
Writes preview map (terrain.jpg), vectors.json (map units) and engine/ (metres): heightmap, masks, features.
Map units: 1200 x 600, 1 unit = 2048/1200 m. Engine: X east, Z south, Y up, origin = north-west corner, sea level Y=0.
"""
import json, math, sys, os
import numpy as np
from scipy import ndimage as ndi
from skimage import measure, graph, draw
from PIL import Image, ImageDraw

OUT = sys.argv[1]
W, H = 1200, 600            # map units; 1 unit = 2048/1200 = 1.707 m
M_PER = 2048 / W
rng = np.random.default_rng(int(sys.argv[2]) if len(sys.argv) > 2 else 7)
Y, X = np.mgrid[0:H, 0:W].astype(float)

def fbm(shape, base, octaves, pers=0.5, seed=None):
    r = np.random.default_rng(seed)
    out = np.zeros(shape); amp = 1.0; tot = 0
    for o in range(octaves):
        cell = base / (2 ** o)
        gh, gw = int(shape[0] / cell) + 4, int(shape[1] / cell) + 4
        g = r.standard_normal((gh, gw))
        z = ndi.zoom(g, (shape[0] / (gh - 3), shape[1] / (gw - 3)), order=3)[:shape[0], :shape[1]]
        out += amp * z; tot += amp; amp *= pers
    out /= tot
    return out / out.std()

def G(cx, cy, sx, sy):
    return np.exp(-(((X - cx) ** 2) / (2 * sx ** 2) + ((Y - cy) ** 2) / (2 * sy ** 2)))

def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)

def seg_ridge(x0, y0, x1, y1, w):
    dx, dy = x1 - x0, y1 - y0; L2 = dx * dx + dy * dy
    t = np.clip(((X - x0) * dx + (Y - y0) * dy) / L2, 0, 1)
    px, py = x0 + t * dx, y0 + t * dy
    return np.exp(-((X - px) ** 2 + (Y - py) ** 2) / (2 * w * w))

# ---------- land mask: superellipse + warped fBm + named features ----------
wx = 15 * fbm((H, W), 240, 4, seed=11); wy = 13 * fbm((H, W), 240, 4, seed=12)
nx = (X + wx - 600) / 548; ny = (Y + wy - 318) / 226
r = (np.abs(nx) ** 2.6 + np.abs(ny) ** 2.6) ** (1 / 2.6)
s = 1 - r + 0.06 * fbm((H, W), 170, 6, 0.58, seed=13)
s -= 0.30 * G(622, 142, 44, 30)         # Hearthstead bay
s -= 0.26 * G(62, 360, 34, 18)          # Bramblemouth estuary
s += 0.30 * G(96, 128, 46, 34)          # West Strait head
s += 0.32 * G(1102, 132, 46, 34)        # Eel Spit root
s += 0.42 * seg_ridge(1096, 136, 1196, 52, 6)   # the spit itself
s -= 0.26 * G(1168, 326, 24, 14)        # Dover mouth
s -= 0.10 * G(330, 112, 50, 22) + 0.09 * G(880, 116, 60, 22)   # northern coves
for (cx, cy) in [(290, 556), (512, 566), (752, 562), (1004, 540), (1126, 470)]:
    s += 0.5 * G(cx, cy, 4.5, 4.5)      # sea stacks off the wave-cut south
s -= 0.6 * (1 - smoothstep(0, 18, np.minimum.reduce([X, Y, W - 1 - X, H - 1 - Y])))
land = s > 0
lab, n = ndi.label(land)
sizes = ndi.sum(land, lab, range(1, n + 1))
keep = np.zeros(n + 1, bool); keep[1:] = sizes > 12
land = keep[lab]
land = ndi.binary_fill_holes(land)
d = ndi.distance_transform_edt(land)
sea_d = ndi.distance_transform_edt(~land)

# ---------- height (metres) before the rim uplift ----------
southW = smoothstep(380, 520, Y)
eastW = smoothstep(820, 1000, X)
h0 = 5 + 8 * (1 - np.exp(-d / 34)) + 2.6 * fbm((H, W), 150, 4, seed=21)
h0 += southW * 40 * np.exp(-((d - 20) / 22) ** 2)                       # wave-cut southern ridge
h0 += 26 * G(1040, 445, 100, 70) * (1 + 0.3 * fbm((H, W), 40, 4, seed=22))   # SE crags
h0 += 21 * G(600, 272, 175, 56)                                         # Mill-Downs
h0 -= 5 * G(545, 425, 115, 68)                                          # Moss-Oaks hollow
h0 -= 5 * np.exp(-((Y - (372 - (X - 650) * 0.06)) / 24) ** 2) * smoothstep(630, 680, X)   # Dover valley
h0 = np.where(land, np.maximum(h0, 0.6), -0.25 * sea_d)

# ---------- rivers: cheapest way downhill on the pre-uplift land ----------
C = 2
hc0 = h0[::C, ::C]
wig = 1 + 0.35 * np.abs(fbm(hc0.shape, 30, 3, seed=31))
rcost = np.where(land[::C, ::C], (1 + np.exp((hc0 - 5) / 3.2)) * wig, 1e6)

def nearest_land(x, y, mind=0.0):
    cand = np.argwhere(land & (d > mind))
    k = np.argmin((cand[:, 1] - x) ** 2 + (cand[:, 0] - y) ** 2)
    return float(cand[k, 1]), float(cand[k, 0])

def route(cost, a, b):
    idx, _ = graph.route_through_array(cost, (int(a[1] // C), int(a[0] // C)),
                                       (int(b[1] // C), int(b[0] // C)), fully_connected=True, geometric=True)
    return [(c * C + C / 2, rr * C + C / 2) for rr, c in idx]

def smooth(p, sig=4.0, step=1.5):
    p = np.array(p, float)
    seg = np.hypot(*np.diff(p, axis=0).T); t = np.concatenate([[0], np.cumsum(seg)])
    n = max(int(t[-1] / step), 4); tt = np.linspace(0, t[-1], n)
    q = np.column_stack([np.interp(tt, t, p[:, 0]), np.interp(tt, t, p[:, 1])])
    a, b = q[0].copy(), q[-1].copy()
    q = ndi.gaussian_filter1d(q, sig, axis=0, mode='nearest'); q[0], q[-1] = a, b
    return q

def meander(p, amp, lam, seed):
    r = np.random.default_rng(seed); p = np.array(p, float)
    seg = np.hypot(*np.diff(p, axis=0).T); t = np.concatenate([[0], np.cumsum(seg)])
    tx = np.gradient(p[:, 0]); ty = np.gradient(p[:, 1]); L = np.hypot(tx, ty) + 1e-9
    nxv, nyv = -ty / L, tx / L
    ph = r.uniform(0, 6.28); lam_t = lam * (1 + 0.35 * np.sin(t / (lam * 2.7) + 1.3))
    off = amp * np.sin(np.cumsum(np.gradient(t) / lam_t) * 6.283 + ph) * np.clip(t / 20, 0, 1) * np.clip((t[-1] - t) / 20, 0, 1)
    return np.column_stack([p[:, 0] + nxv * off, p[:, 1] + nyv * off])

def chaikin(p, n=2):
    p = np.array(p, float)
    for _ in range(n):
        q = np.empty((2 * len(p) - 2, 2))
        q[0::2] = 0.75 * p[:-1] + 0.25 * p[1:]; q[1::2] = 0.25 * p[:-1] + 0.75 * p[1:]
        p = np.vstack([p[:1], q, p[-1:]])
    return p

S1 = (548, 404); S2 = (652, 386)
M1 = nearest_land(30, 360); M2 = nearest_land(1199, 326)
def rpath(pts, seed):
    out = []
    for a, b in zip(pts[:-1], pts[1:]):
        sg = route(rcost, a, b); out += sg if not out else sg[1:]
    return meander(smooth(out, 3.0), 2.6, 46, seed)
bramble = rpath([S1, M1], 1)
dover = rpath([S2, (780, 364), (900, 344), M2], 2)

def dist_to(poly):
    m = np.zeros((H, W), bool)
    for (x0, y0), (x1, y1) in zip(poly[:-1], poly[1:]):
        rr, cc = draw.line(int(round(y0)), int(round(x0)), int(round(y1)), int(round(x1)))
        ok = (rr >= 0) & (rr < H) & (cc >= 0) & (cc < W); m[rr[ok], cc[ok]] = True
    return ndi.distance_transform_edt(~m)

dB = dist_to(bramble); dD = dist_to(dover)
h = h0 - 2.5 * np.exp(-(dB / 3) ** 2) - 3 * np.exp(-(dB / 14) ** 2) - 2.5 * np.exp(-(dD / 3) ** 2)
rim = 24 * G(1000, 332, 130, 46)                       # the rim the Dover cut through
gorge = 1 - np.exp(-(dD / 6) ** 2)
h = h + rim * gorge
h = np.where(land, np.maximum(h, 0.4), h0)

# ---------- paths: cost of walking ----------
hc = h[::C, ::C]; dc = d[::C, ::C] * 1.0
gy, gx = np.gradient(hc, C * M_PER)
slope = np.hypot(gx, gy)
base = (1 + (slope / 0.07) ** 2) * (1 + 0.45 * (fbm(hc.shape, 22, 3, seed=61) + 2.5) / 2.5)
base = np.minimum(base, 120)
base += np.where(dc < 3, 6, 0)
base = np.where(land[::C, ::C], base, 1e6)
dBc = dB[::C, ::C]; dDc = dD[::C, ::C]; rimc = rim[::C, ::C]
base = np.where((dBc < 3.5) | (dDc < 3.5), 1e6, base)
base = np.where((dDc < 9) & (rimc > 6), 1e6, base)

def at_x(poly, x):
    k = np.argmin(np.abs(poly[:, 0] - x)); return poly[k]

vb = at_x(bramble, 255)            # Bramblebridge's stone bridge
db = at_x(dover, 1002)              # Doverslap
def allow(cost, x, y, rx, ry):
    cc0, rr0 = int(x // C), int(y // C)
    cost[max(rr0 - ry, 0):rr0 + ry + 1, max(cc0 - rx, 0):cc0 + rx + 1] = 1.0
allow(base, vb[0], vb[1], 1, 5)
allow(base, db[0], db[1], 1, 10)

coastpref = base.copy()
band = (dc > 4) & (dc < 16) & land[::C, ::C]
coastpref = np.where(band & (coastpref < 1e5), coastpref * 0.5, coastpref)

V = (vb[0] + 2, vb[1] - 16)
OAK = (522, 438)  # replaced below once the Bramble is known
BS = (db[0], db[1] + 15); BN = (db[0], db[1] - 15)
GATE = (db[0] + 22, db[1] - 36)
col = np.where(land[:, 622])[0]; HY = col.min()
HST = (622, HY + 20); QUAY = (622, HY - 2)
MILL = (600, 268)
WS = nearest_land(40, 96, 3); EEL = nearest_land(1196, 46, 1)
EJ = nearest_land(1080, 120, 14)

def path(cost, pts):
    out = []
    for a, b in zip(pts[:-1], pts[1:]):
        seg = route(cost, a, b)
        out += seg if not out else seg[1:]
    return chaikin(smooth(out, 4.5), 2)

VS = (vb[0], vb[1] + 11)
ob = at_x(bramble, 505); OAK = (float(ob[0]), float(ob[1] - 13))
lane = path(base, [VS, V, OAK])
hollow = path(base, [OAK, (760, 420), (895, 392), BS])
bridge = np.array([BS, BN])
gate = path(base, [BN, GATE])
NC1 = nearest_land(880, 96, 16); NC2 = nearest_land(760, 112, 16)
coast = path(coastpref, [GATE, EJ, NC1, NC2, HST])
downs = path(base, [HST, MILL, V])
strait = path(coastpref, [HST, WS])
eel = path(coastpref, [EJ, EEL])
dg = downs[int(len(downs) * 0.08)]
weir = at_x(bramble, 335)

# ---------- final relief: a spring-wood upland, then channels carved so water only runs downhill ----------
h = h + np.where(land, 7.5 * G(590, 400, 240, 115) * np.clip(d / 12, 0, 1), 0)
def carve_monotonic(poly, harr):
    zs = ndi.map_coordinates(harr, [poly[:, 1], poly[:, 0]], order=1, mode='nearest')
    zs = ndi.gaussian_filter1d(zs, 2, mode='nearest')
    bed = np.maximum(np.minimum.accumulate(zs) - 1.0, 0.2)
    mk = np.full(harr.shape, np.inf)
    rr = np.clip(np.round(poly[:, 1]).astype(int), 0, H - 1); cc = np.clip(np.round(poly[:, 0]).astype(int), 0, W - 1)
    np.minimum.at(mk, (rr, cc), bed)
    has = np.isfinite(mk)
    dist_, (ii_, jj_) = ndi.distance_transform_edt(~has, return_indices=True)
    wall = 0.55 + 2.5 * np.clip(rim / 24, 0, 1)          # V-valleys in soft ground, near-vertical walls through the rim
    cap = mk[ii_, jj_] + np.maximum(dist_ - 1.5, 0) * wall
    return np.where(land, np.minimum(harr, cap), harr), bed
h, BED_B = carve_monotonic(bramble, h)
h, BED_D = carve_monotonic(dover, h)

# ---------- raster: tint, hillshade, contours, coast, cliffs, trees ----------
S = 2
hf = ndi.zoom(h, S, order=3) + 0.6 * fbm((H * S, W * S), 30, 4, seed=41) * ndi.zoom(land.astype(float), S, order=1)
landf = ndi.zoom(ndi.gaussian_filter(land.astype(float), 0.8), S, order=1) > 0.5
seadf = ndi.distance_transform_edt(~landf) / S
mf = M_PER / S
gyf, gxf = np.gradient(hf, mf)
az, alt = math.radians(315), math.radians(42)
slp = np.arctan(2.2 * np.hypot(gxf, gyf)); asp = np.arctan2(-gxf, gyf)
shade = np.sin(alt) * np.cos(slp) + np.cos(alt) * np.sin(slp) * np.cos(az - asp)
shade = np.clip(shade, 0, 1)

stops = [(0, (236, 224, 186)), (8, (231, 223, 182)), (16, (223, 214, 165)), (28, (214, 202, 150)),
         (40, (204, 190, 143)), (55, (192, 180, 140)), (70, (186, 176, 146))]
def tint(z):
    out = np.zeros(z.shape + (3,))
    zs = [s_[0] for s_ in stops]
    for ch in range(3):
        out[..., ch] = np.interp(z, zs, [s_[1][ch] for s_ in stops])
    return out
img = tint(hf)
YY, XX = np.mgrid[0:H * S, 0:W * S] / S
wood = ((((XX - 548) / 190) ** 2 + ((YY - 430) / 104) ** 2) < 1 + 0.32 * fbm((H * S, W * S), 60, 4, seed=51)) & (ndi.zoom(d, S, order=1) > 14)
img = np.where(wood[..., None], img * 0.55 + np.array([150, 178, 128]) * 0.45, img)
light = 0.62 + 0.55 * shade
img = img * light[..., None]
sea_col = np.array([205, 217, 211]); deep_col = np.array([170, 192, 192])
t = np.clip(seadf / 110, 0, 1)[..., None]
seaimg = sea_col * (1 - t) + deep_col * t
img = np.where(landf[..., None], img, seaimg)
img = np.clip(img, 0, 255).astype(np.uint8)
base_im = Image.fromarray(img, 'RGB')

U = 4                                         # overlay drawn at 4 px per map unit, then reduced
ov = Image.new('RGBA', (W * U, H * U), (0, 0, 0, 0))
dr = ImageDraw.Draw(ov)
def pl(pts, fill, width):
    dr.line([(float(x) * U, float(y) * U) for x, y in pts], fill=fill, width=width, joint='curve')

for lev, a in [(4, 70), (9, 48), (15, 30), (23, 18)]:
    for c in measure.find_contours(sea_d, lev):
        pl([(p[1], p[0]) for p in c[::2]], (60, 80, 84, a), 3)
for lev in [10, 20, 30, 40, 50, 60]:
    for c in measure.find_contours(np.where(land, h, -5), lev):
        if len(c) > 12:
            pl([(p[1], p[0]) for p in c[::2]], (110, 86, 50, 60 if lev % 20 else 95), 3)
coast_c = measure.find_contours(ndi.gaussian_filter(land.astype(float), 0.8), 0.5)
for c in coast_c:
    pl([(p[1], p[0]) for p in c], (58, 42, 28, 255), 7)
# cliffs: hachures where the land rises fast from the waterline
for c in coast_c:
    for i in range(0, len(c), 3):
        yy, xx = c[i]
        j0, j1 = max(i - 2, 0), min(i + 2, len(c) - 1)
        ty, tx = c[j1][0] - c[j0][0], c[j1][1] - c[j0][1]
        L = math.hypot(tx, ty) or 1
        nx_, ny_ = -ty / L, tx / L
        sx, sy = int(round(xx + nx_ * 3)), int(round(yy + ny_ * 3))
        if not (0 <= sx < W and 0 <= sy < H) or not land[sy, sx]:
            nx_, ny_ = -nx_, -ny_
            sx, sy = int(round(xx + nx_ * 3)), int(round(yy + ny_ * 3))
        if 0 <= sx < W and 0 <= sy < H and land[sy, sx] and h[sy, sx] > 15:
            ln = min(2 + h[sy, sx] / 9, 8)
            pl([(xx, yy), (xx + nx_ * ln, yy + ny_ * ln)], (58, 42, 28, 210), 4)
        elif 0 <= sx < W and 0 <= sy < H and land[sy, sx] and h[sy, sx] < 7 and yy < 330:
            dr.ellipse([(xx + nx_ * 2) * U - 2, (yy + ny_ * 2) * U - 2, (xx + nx_ * 2) * U + 2, (yy + ny_ * 2) * U + 2], fill=(150, 130, 90, 150))
# trees in the Moss-Oaks, drawn back to front
pts = []
for gy_ in np.arange(270, 540, 6.5):
    for gx_ in np.arange(350, 750, 7.0):
        x_ = gx_ + rng.uniform(-2.6, 2.6) + (3 if int(gy_ / 6.5) % 2 else 0); y_ = gy_ + rng.uniform(-2.2, 2.2)
        xi, yi = int(x_ * S), int(y_ * S)
        if 0 <= xi < W * S and 0 <= yi < H * S and wood[yi, xi] and dD[int(y_), int(x_)] > 3 and dB[int(y_), int(x_)] > 3:
            pts.append((x_, y_))
TREES = []
for (x_, y_) in sorted(pts, key=lambda p: p[1]):
    r_ = rng.uniform(2.5, 3.7)
    TREES.append((x_, y_, r_))
    dr.ellipse([(x_ - r_ + 1.2) * U, (y_ - r_ + 1.6) * U, (x_ + r_ + 1.2) * U, (y_ + r_ + 1.6) * U], fill=(60, 80, 50, 70))
    g = int(rng.uniform(118, 146))
    dr.ellipse([(x_ - r_) * U, (y_ - r_) * U, (x_ + r_) * U, (y_ + r_) * U], fill=(g - 22, g + 18, g - 40, 255), outline=(52, 66, 40, 255), width=3)
# orchards and grain strips
ORCH, FIELD = [], []
def patch(cx, cy, ang, nxp, nyp, step, kind):
    ca, sa = math.cos(ang), math.sin(ang)
    for i in range(nxp):
        for j in range(nyp):
            u_, v_ = (i - nxp / 2) * step, (j - nyp / 2) * step
            x_, y_ = cx + u_ * ca - v_ * sa, cy + u_ * sa + v_ * ca
            xi, yi = int(x_), int(y_)
            if not (0 <= xi < W and 0 <= yi < H) or not land[yi, xi] or d[yi, xi] < 6 or dB[yi, xi] < 5 or dD[yi, xi] < 5:
                continue
            if kind == 'orch':
                ORCH.append((x_, y_))
                dr.ellipse([(x_ - 1.9) * U, (y_ - 1.9) * U, (x_ + 1.9) * U, (y_ + 1.9) * U], fill=(150, 150, 70, 255), outline=(70, 70, 30, 255), width=2)
                dr.ellipse([(x_ + 0.3) * U, (y_ - 0.9) * U, (x_ + 1.3) * U, (y_ + 0.1) * U], fill=(196, 104, 40, 255))
            else:
                FIELD.append(((x_ - step * 0.48 * ca, y_ - step * 0.48 * sa), (x_ + step * 0.48 * ca, y_ + step * 0.48 * sa)))
                pl([(x_ - step * 0.48 * ca, y_ - step * 0.48 * sa), (x_ + step * 0.48 * ca, y_ + step * 0.48 * sa)], (176, 146, 70, 200), 3)
for (cx, cy, ang) in [(196, 300, -0.3), (318, 400, 0.2), (150, 390, 0.5)]:
    patch(cx, cy, ang, 7, 5, 7, 'orch')
for (cx, cy, ang) in [(540, 225, -0.35), (690, 250, 0.25), (590, 300, 0.1), (470, 270, -0.15)]:
    for jj in range(6):
        patch(cx + jj * 4.5 * -math.sin(ang), cy + jj * 4.5 * math.cos(ang), ang, 5, 1, 8, 'field')
ov = ov.resize((W * S, H * S), Image.LANCZOS)
final = Image.alpha_composite(base_im.convert('RGBA'), ov).convert('RGB')
final.save(OUT + '/terrain.jpg', quality=90, optimize=True)

# ---------- vector data for the SVG ----------
def dstr(p, tol=0.35):
    p = measure.approximate_polygon(np.array(p), tol)
    return 'M' + ' '.join('%.1f %.1f' % (x, y) for x, y in p)

def profile(segs):
    allp = np.vstack(segs); dist = [0.0]
    for a, b in zip(allp[:-1], allp[1:]):
        dist.append(dist[-1] + math.hypot(*(b - a)) * M_PER)
    hs = [float(h[int(min(max(y, 0), H - 1)), int(min(max(x, 0), W - 1))]) for x, y in allp]
    return dist, hs, allp

segs = [lane, hollow, bridge, gate, coast]
dist, hs, allp = profile(segs)
cut = [0]; n_ = 0
for sg in segs:
    n_ += len(sg); cut.append(n_)
bi0, bi1 = cut[2], cut[3] - 1
deck = max(hs[bi0], hs[bi1]) + 1.5
prof = []
for i, (dd, hh) in enumerate(zip(dist, hs)):
    if bi0 <= i <= bi1:
        hh = deck
    prof.append((dd, hh))
gorge_floor = float(h[int(db[1]), int(db[0])])

def length(p):
    return float(sum(math.hypot(*(b - a)) for a, b in zip(p[:-1], p[1:])) * M_PER)

# First-Quiet sleepers: high ground near the outer south-east cliffs
cand = np.argwhere(land & (h > 36) & (d > 6) & (d < 34) & (X > 930) & (Y > 380))
np.random.default_rng(202).shuffle(cand); sleepers = []
for yy, xx in cand:
    if all((xx - a) ** 2 + (yy - b) ** 2 > 42 ** 2 for a, b in sleepers):
        sleepers.append((int(xx), int(yy)))
    if len(sleepers) == 6:
        break

# Hush line: the outer sea beyond the SE
hush = [c for c in measure.find_contours(sea_d, 34) if len(c) > 40]
hush_pts = []
for c in hush:
    for yy, xx in c:
        if xx > 900 and yy > 360:
            hush_pts.append((xx, yy))
hush_pts.sort(key=lambda p: math.atan2(p[1] - 330, p[0] - 600))

def houses(cx, cy, n, rmin, rmax, avoid, seed):
    hr = np.random.default_rng(seed); out = []; tries = 0
    while len(out) < n and tries < 4000:
        tries += 1
        a = hr.uniform(0, 2 * math.pi); rr = hr.uniform(rmin, rmax)
        x_, y_ = cx + rr * math.cos(a), cy + rr * math.sin(a) * 0.8
        xi, yi = int(x_), int(y_)
        if not (0 <= xi < W and 0 <= yi < H) or not land[yi, xi] or d[yi, xi] < 5:
            continue
        if dB[yi, xi] < 5 or dD[yi, xi] < 5: continue
        if min(np.min(np.hypot(p[:, 0] - x_, p[:, 1] - y_)) for p in avoid) < 4.5: continue
        if any((x_ - a_) ** 2 + (y_ - b_) ** 2 < 10.5 ** 2 for a_, b_ in out): continue
        out.append((round(x_, 1), round(y_, 1)))
    return out

roads = [lane, hollow, gate, coast, downs, strait, eel]
data = dict(
    rivers=dict(bramble=dstr(bramble), dover=dstr(dover)),
    roads=dict(lane=dstr(lane), hollow=dstr(hollow), bridge=dstr(bridge, 0), gate=dstr(gate), coast=dstr(coast),
               downs=dstr(downs), strait=dstr(strait), eel=dstr(eel)),
    lengths_m=dict(lane=length(lane), hollow=length(hollow), gate=length(gate), coast=length(coast), downs=length(downs),
                   strait=length(strait), eel=length(eel), corridor=float(dist[-1]),
                   bramble=length(bramble), dover=length(dover)),
    poi=dict(EJ=EJ, NC1=NC1, NC2=NC2, VS=VS, V=V, vbridge=tuple(vb), OAK=OAK, BS=BS, BN=BN, DB=tuple(db), GATE=GATE, HST=HST, QUAY=QUAY, MILL=MILL, WS=WS,
             EEL=EEL, DG=tuple(dg), WEIR=tuple(weir), S1=S1, S2=S2, M1=M1, M2=M2),
    heights=dict(V=float(h[int(V[1]), int(V[0])]), OAK=float(h[int(OAK[1]), int(OAK[0])]), BS=float(h[int(BS[1]), int(BS[0])]),
                 BN=float(h[int(BN[1]), int(BN[0])]), gorge_floor=gorge_floor, deck=deck,
                 HST=float(h[int(HST[1]), int(HST[0])]), MILL=float(h[MILL[1], MILL[0]]), max=float(h.max())),
    profile=[(round(a, 1), round(b, 1)) for a, b in prof[::3]] + [(round(prof[-1][0], 1), round(prof[-1][1], 1))],
    profile_marks=[round(dist[c_], 1) for c_ in cut[:-1]] + [round(dist[-1], 1)],
    sleepers=sleepers, hush=dstr(hush_pts, 1.5) if hush_pts else '',
    village=houses(V[0], V[1] + 6, 12, 8, 34, roads, 301), hearth=houses(HST[0], HST[1] - 2, 14, 10, 40, roads, 302),
    land_bbox=[int(np.where(land.any(0))[0].min()), int(np.where(land.any(1))[0].min()),
               int(np.where(land.any(0))[0].max()), int(np.where(land.any(1))[0].max())],
    land_km2=float(land.sum() * M_PER * M_PER / 1e6),
)
json.dump(data, open(OUT + '/vectors.json', 'w'), default=float)


# ======================= ENGINE EXPORT (metres) =======================
EXP = os.path.join(OUT, 'engine'); os.makedirs(EXP, exist_ok=True)
WM, HM = 2048, 1024
def m(p): return [round(float(p[0]) * M_PER, 2), round(float(p[1]) * M_PER, 2)]
vi, vj = np.mgrid[0:HM + 1, 0:WM + 1].astype(np.float32)
he = ndi.map_coordinates(hf, [vi / M_PER * S, vj / M_PER * S], order=1, mode='nearest').astype(np.float32)
he = np.maximum(he, -14.0)

def poly_m(p, step=0.5):
    p = np.array(p, float) * M_PER
    seg = np.hypot(*np.diff(p, axis=0).T); t = np.concatenate([[0], np.cumsum(seg)])
    n = max(int(t[-1] / step), 2); tt = np.linspace(0, t[-1], n)
    return np.column_stack([np.interp(tt, t, p[:, 0]), np.interp(tt, t, p[:, 1])]), tt

def sample(arr, pm):
    return ndi.map_coordinates(arr, [pm[:, 1], pm[:, 0]], order=1, mode='nearest')

def dist_raster(polys, shape):
    mk = np.zeros(shape, bool)
    for pm in polys:
        r_ = np.clip(np.round(pm[:, 1]).astype(int), 0, shape[0] - 1); c_ = np.clip(np.round(pm[:, 0]).astype(int), 0, shape[1] - 1)
        mk[r_, c_] = True
    return ndi.distance_transform_edt(~mk)

# rivers: widths grow downstream; water surface = bed + 0.6 m (wade depth 0.4-0.8 m, no swimming)
RIV = {}
for name, poly, w0, w1 in [('bramble', bramble, 3.0, 7.0), ('dover', dover, 3.0, 6.0)]:
    pm, tt = poly_m(poly, 1.0)
    bed = np.array([he[max(int(y) - 2, 0):int(y) + 3, max(int(x) - 2, 0):int(x) + 3].min() for x, y in pm])
    bed = np.minimum.accumulate(bed)          # water only runs downhill (already true of the carved terrain)
    width = w0 + (w1 - w0) * tt / tt[-1]
    RIV[name] = dict(pm=pm, bed=bed, surface=bed + 0.6, width=width)
dRiv = dist_raster([RIV[k]['pm'] for k in RIV], he.shape)

# road beds: cut-and-fill toward a smoothed along-path grade; the Holloway sinks 5 m below its banks
BRIDGE_DECK = float(deck)
ROADS = dict(lane=(lane, 2.5, 'corridor', 1), hollow=(hollow, 2.5, 'corridor', 3), gate=(gate, 2.5, 'corridor', 4),
             coast=(coast, 2.5, 'corridor', 5), downs=(downs, 1.5, 'track', 0), strait=(strait, 1.5, 'track', 0),
             eel=(eel, 1.5, 'track', 0))
roadT = np.full(he.shape, np.nan, np.float32); roadW = np.zeros(he.shape, np.float32)
ROADOUT = {}
for name, (poly, hw, kind, stage) in ROADS.items():
    pm, tt = poly_m(poly, 0.5)
    g = ndi.gaussian_filter1d(sample(he, pm), 16, mode='nearest')
    L = tt[-1]
    if name == 'hollow':
        sink = 5.0 * np.clip(tt / 90, 0, 1) * np.clip((L - 60 - tt) / 90, 0, 1)
        g = g - sink
        g = np.where(tt > L - 40, g + (BRIDGE_DECK - g) * np.clip((tt - (L - 40)) / 40, 0, 1), g)
    if name == 'gate':
        g = np.where(tt < 30, BRIDGE_DECK + (g - BRIDGE_DECK) * np.clip(tt / 30, 0, 1), g)
    r_ = np.clip(np.round(pm[:, 1]).astype(int), 0, HM); c_ = np.clip(np.round(pm[:, 0]).astype(int), 0, WM)
    roadT[r_, c_] = g; roadW[r_, c_] = hw
    ROADOUT[name] = dict(kind=kind, stage=stage, half_width_m=hw, sunk_m=5.0 if name == 'hollow' else 0.0,
                         points=[[round(float(x), 2), round(float(y), 2), round(float(z), 2)] for (x, z), y in zip(pm[::4], g[::4])])
has = ~np.isnan(roadT)
dRoad, (ii, jj) = ndi.distance_transform_edt(~has, return_indices=True)
tgt = roadT[ii, jj]; hwv = roadW[ii, jj]
w = 1 - np.clip((dRoad - hwv) / 6.0, 0, 1)
w *= np.clip((dRiv - 4) / 5, 0, 1)                    # keep river channels open under bridges
w *= (he > 0.3)
he = np.where(w > 0, he * (1 - w) + np.nan_to_num(tgt) * w, he).astype(np.float32)

# Old Quay: a drowned stone platform at -4.5 m, bared when the Ebb drops the sea 6 m
oq = [m((610, 146)), m((636, 158))]
he[int(oq[0][1]):int(oq[1][1]) + 1, int(oq[0][0]):int(oq[1][0]) + 1] = -4.5

he.astype('<f4').tofile(os.path.join(EXP, 'embershore_height_f32.raw'))
u16 = np.clip((he + 20.0) / 120.0 * 65535, 0, 65535).astype(np.uint16)
Image.fromarray(u16).save(os.path.join(EXP, 'embershore_height_u16.png'))

# splat masks at 1 m/px (2048 x 1024), sampled at cell centres
ci, cj = np.mgrid[0:HM, 0:WM].astype(np.float32) + 0.5
def at_cells(arr, scale, order=1):
    return ndi.map_coordinates(arr, [ci * scale, cj * scale], order=order, mode='nearest')
hc_ = at_cells(he, 1.0)
gyc, gxc = np.gradient(hc_)
slope_deg = np.degrees(np.arctan(np.hypot(gxc, gyc)))
landc = hc_ > 0
woodc = at_cells(wood.astype(np.float32), S / M_PER) > 0.5
river_c = at_cells(dRiv, 1.0) < 2.5
seadist_c = ndi.distance_transform_edt(landc)
def save_mask(name, arr):
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8)).save(os.path.join(EXP, name))
save_mask('mask_land.png', landc.astype(float))
save_mask('mask_moss_oaks.png', (woodc & landc).astype(float))
save_mask('mask_road.png', at_cells(np.clip(1 - (dRoad - roadW[ii, jj]) / 2.0, 0, 1), 1.0))
save_mask('mask_river.png', river_c.astype(float))
save_mask('mask_cliff.png', (landc & (slope_deg > 38)).astype(float))
save_mask('mask_beach.png', (landc & (hc_ < 2.2) & (seadist_c < 14) & (slope_deg < 20)).astype(float))
save_mask('mask_rain_shadow_dry.png', np.clip(1 - (ci - 400) / 500, 0, 1) * landc)

def hy(p):
    x, z = m(p); return [x, round(float(he[min(int(round(z)), HM), min(int(round(x)), WM)]), 2), z]

POI = {
 'bramblebridge_start_chimepost': dict(at=hy((252, 451)), kind='chime_post', stage=1, note='village green, south bank; party spawn; checkpoint + card-loadout table'),
 'bramblebridge_stone_bridge': dict(at=hy(vb), kind='stone_arch_bridge', note='single arch over the Bramble; the corridor crosses it north'),
 'bramblebridge_watermill': dict(at=hy((300, 452)), kind='watermill', note='undershot wheel on the mill race; wheel states: turning / stopped (Lv 5) / turning (Root-Sanctum cleared)'),
 'bramble_weir': dict(at=hy(weir), kind='weir', note='feeds the mill race; choked by Elder Oak roots; Root-Sanctum exit'),
 'wrights_yard': dict(at=hy((226, 452)), kind='workshop', note='cooper, bowyer, bark-tanner: Tier 1 wood kit'),
 'cold_smithy': dict(at=hy((276, 456)), kind='smithy', note='forge unlit: no iron until the West Strait reopens'),
 'elder_oak': dict(at=hy((489, 398)), kind='landmark_tree', stage=2, note='north bank of the Bramble above the weir; largest tree on the island'),
 'root_sanctum_entrance': dict(at=hy((514, 437)), kind='dungeon_entrance', stage=7, note='Lv 6 capstone among the Elder Oak roots'),
 'moss_oaks_chimepost': dict(at=hy((434, 384)), kind='chime_post', stage=2),
 'bramble_spring': dict(at=hy(S1), kind='spring'), 'dover_spring': dict(at=hy(S2), kind='spring'),
 'holloway_rim_shoulder': dict(at=hy(hollow[int(len(hollow) * 0.86)]), kind='viewpoint', stage=3, note='highest point of the corridor'),
 'doverslap_bridge_south': dict(at=[*m(BS)[:1], round(BRIDGE_DECK, 2), m(BS)[1]], kind='bridge_end'),
 'doverslap_bridge_north': dict(at=[*m(BN)[:1], round(BRIDGE_DECK, 2), m(BN)[1]], kind='bridge_end'),
 'doverslap_gorge_floor': dict(at=hy(db), kind='gorge_floor', note='river level under the bridge'),
 'doverslap_gatehouse': dict(at=hy(GATE), kind='gatehouse', stage=4),
 'doverslap_chimepost': dict(at=hy((1042, 234)), kind='chime_post', stage=4),
 'eel_junction': dict(at=hy(EJ), kind='junction', stage=5),
 'seal_cove': dict(at=hy(NC1), kind='cove', stage=5, note='corridor reaches sea level; Crown framed across open water'),
 'sunward_cove': dict(at=hy(NC2), kind='cove', stage=5),
 'hearthstead_market': dict(at=hy((623, 186)), kind='market', stage=6),
 'hearthstead_scribe_table': dict(at=hy((589, 193)), kind='scribe_table', stage=6),
 'hearthstead_chimepost': dict(at=hy((662, 176)), kind='chime_post', stage=6),
 'north_quay_pier_root': dict(at=hy(QUAY), kind='pier', note='timber pier 30 m north into the bay; skiff bells'),
 'old_quay_platform': dict(rect_xz=[oq[0], oq[1]], y=-4.5, kind='ebb_reveal', note='under water until world.ebb; then dry'),
 'mill_downs_windmill': dict(at=hy((612, 284)), kind='windmill', note='island silhouette visible from the other isles'),
 'downs_gate': dict(at=hy(dg), kind='one_way_gate', note='opens from the Hearthstead side only'),
 'west_strait_head': dict(at=hy(WS), kind='causeway_head', note='closed until Lv 6; causeway runs WNW to Iron-Ness'),
 'eel_spit_head': dict(at=hy(EEL), kind='causeway_head', note='closed until Lv 6; shingle spit NE to Barrow-Eyot'),
}
FEAT = dict(
  units='metres; X east, Z south, Y up; origin = north-west corner of the 2048 x 1024 m grid; sea level Y = 0; Ebb lowers sea to Y = -6',
  grid=dict(size_m=[WM, HM], chunk_m=128, chunks=[16, 8], heightmap_vertices=[WM + 1, HM + 1], heightmap_spacing_m=1.0,
            files=dict(f32='embershore_height_f32.raw (little-endian float32, row-major, row 0 = north)',
                       u16='embershore_height_u16.png (Y = v/65535*120 - 20)')),
  bridge_deck_y=round(BRIDGE_DECK, 2), poi=POI, roads=ROADOUT,
  bridges=dict(doverslap=dict(south=m(BS), north=m(BN), deck_y=round(BRIDGE_DECK, 2), kind='stone, three arches'),
               bramblebridge=dict(at=m(vb), kind='stone, single arch')),
  rivers={k: dict(points=[[round(float(x), 2), round(float(z), 2), round(float(b), 2), round(float(sf), 2), round(float(wd), 2)]
                          for (x, z), b, sf, wd in list(zip(v['pm'], v['bed'], v['surface'], v['width']))[::3]],
                  columns='x, z, bed_y, surface_y, width') for k, v in RIV.items()},
  mill_race=[m(p) for p in [(334, 425), (322, 446), (306, 451), (290, 446)]],
  root_sanctum_route=[m(p) for p in [(512, 432), (470, 442), (420, 436), (370, 432), (338, 428)]],
  moss_oaks_trees=[[*m((x, z)), round(r * M_PER, 2)] for x, z, r in TREES],
  orchard_trees=[m(p) for p in ORCH], grain_field_rows=[[m(a), m(b)] for a, b in FIELD],
  sea_stacks=[m(p) for p in [(290, 556), (512, 566), (752, 562), (1004, 540), (1126, 470)]],
  bramblebridge_houses=[m(p) for p in data['village']],
  hearthstead_houses=[m(p) for p in data['hearth'] if not any(abs(p[0] - a) < 8 and abs(p[1] - b) < 8 for a, b in [(623, 186), (589, 193), (662, 176)])],
  first_quiet_sleepers=[m(p) for p in sleepers],
  boundary_seal=[m(p) for p in [(1199, 372), (1192, 450), (1162, 505), (1132, 556), (1080, 600)]],
  causeways=dict(west_strait=[m(WS), m((0, 98))], eel_spit=[m(EEL), m((1200, 48))]),
  skiffs=dict(crown_landing=[m((622, 146)), m((622, 0))], salt_road_to_rime_firth=[m((628, 146)), m((790, 0))]),
  doverslap_reveal=dict(trigger=m(db), radius_m=6, duration_s=4.0,
                        look_at=dict(crown=m((660, 0)), rime_firth=m((880, 0)), barrow_eyot=m((1200, 30)))),
  profile_corridor=data['profile'],
)
json.dump(FEAT, open(os.path.join(EXP, 'embershore_features.json'), 'w'), default=float)
CHECK = {k: v['at'] for k, v in POI.items() if 'at' in v}
CHECK['corridor_length_m'] = round(float(dist[-1]), 1); CHECK['height_max'] = round(float(he.max()), 2)
CHECK['bramble_bed_spring_to_mouth'] = [round(float(BED_B[0]), 2), round(float(BED_B[len(BED_B)//2]), 2), round(float(BED_B[-1]), 2)]
CHECK['dover_bed_spring_to_mouth'] = [round(float(BED_D[0]), 2), round(float(BED_D[len(BED_D)//2]), 2), round(float(BED_D[-1]), 2)]
CHECK['rim_shoulder_y_profile'] = round(max(b for a_, b in prof), 2)
print(json.dumps(CHECK, default=float))
