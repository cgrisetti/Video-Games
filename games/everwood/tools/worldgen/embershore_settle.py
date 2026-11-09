#!/usr/bin/env python3
"""Embershore's worked land (docs/32_EMBERSHORE_THE_WORKED_LAND.md).

The generator (embershore_gen.py, the Master v2 brief's Appendix A, verbatim)
is the island's one source of truth: its heights, rivers, roads, landmarks,
houses and trees. This script reads what it wrote and lays the *settlement
layer* over it without moving a metre of ground: where the steadings stand and
why, the cart tracks that reach them, the patchwork of small fields and what
grows in each, the hedges and dry-stone walls between them, the trees a valley
like this keeps (hedgerow standards, shelterbelts, riverside alders and
pollards, a dark pine wood on the shaded slope, hilltop clumps), and the small
things people leave about (ricks, stooks, haycocks, troughs, flocks).

Run from games/everwood:

    tools/worldgen/.venv/bin/python tools/worldgen/embershore_settle.py \
        world/embershore/gen/engine world/embershore/settle 7

It writes into the output folder:

    settlement.json     steadings, village plots, tracks, fields, boundaries,
                        trees, props and flocks, in the generator's metres
    mask_landuse.png    what each square metre is used for (LANDUSE ids), 2048 x 1024
    mask_tilth.png      the direction a field is worked in (1..255 = 0..pi; 0 none)
    preview.png         the layer drawn over the hill-shaded island, for people

Frame: the generator's (X east, Z south, origin at the north-west corner, sea
at Y = 0). EmbershoreBuilder moves it to the island's frame with to_local().
The same seed always writes the same files.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage as ndi
from scipy.spatial import cKDTree
from skimage.graph import MCP_Geometric
from skimage.morphology import skeletonize

W, D = 2048, 1024  # metres east-west, north-south (one cell a metre)
ORIGIN = np.array([1024.0, 512.0])  # island frame = generator - ORIGIN

LANDUSE = {
    "wild": 0, "pasture": 1, "hay": 2, "barley": 3, "plough": 4, "roots": 5, "stubble": 6, "fallow": 7,
    "orchard": 8, "yard": 9, "garden": 10, "green": 11, "water_meadow": 12, "common": 13, "verge": 14,
}

# --- Where people settled, and why (island frame; the script picks the best ground near each) ------------
# kind: farm (house, barn, byre, granary), croft (cottage and byre), hillfarm (stone, sheep),
# fisher (cot, net shed, boat), mill (the miller's cot by the windmill), forester (a cot at the
# wood's edge), flitted (a steading its people left: the Lens's "flit")
# style: what its fields are parted with: hedge (the lush south and west), wall (the dry north,
# the uplands and the coast), mixed.
STEADINGS = [
    {"id": "lark_wick", "name": "Lark-Wick", "kind": "farm", "near": (-840, -70), "reach": 110, "style": "hedge", "land": 185},
    {"id": "barley_green", "name": "Barley-Green", "kind": "farm", "near": (-610, -215), "reach": 100, "style": "mixed", "land": 180},
    {"id": "thistle_crossing", "name": "Thistle-Crossing", "kind": "farm", "near": (-330, -235), "reach": 100, "style": "mixed", "land": 175},
    {"id": "clover_hollow", "name": "Clover-Hollow", "kind": "farm", "near": (-330, -95), "reach": 100, "style": "mixed", "land": 170},
    {"id": "plum_wick", "name": "Plum-Wick", "kind": "croft", "near": (-470, -20), "reach": 80, "style": "hedge", "land": 125},
    {"id": "otter_crossing", "name": "Otter-Crossing", "kind": "croft", "near": (-850, 215), "reach": 85, "style": "hedge", "land": 110},
    {"id": "ewe_green", "name": "Ewe-Green", "kind": "farm", "near": (200, -200), "reach": 100, "style": "wall", "land": 175},
    {"id": "kettle_wick", "name": "Kettle-Wick", "kind": "croft", "near": (-130, -150), "reach": 80, "style": "mixed", "land": 125},
    {"id": "sunward_haven", "name": "Sunward-Haven", "kind": "fisher", "near": (310, -280), "reach": 70, "style": "wall", "land": 85},
    {"id": "seal_haven", "name": "Seal-Haven", "kind": "fisher", "near": (500, -235), "reach": 70, "style": "wall", "land": 85},
    {"id": "gorse_wick", "name": "Gorse-Wick", "kind": "hillfarm", "near": (640, -190), "reach": 100, "style": "wall", "land": 175},
    {"id": "eel_wick", "name": "Eel-Wick", "kind": "croft", "near": (850, -240), "reach": 80, "style": "wall", "land": 120},
    {"id": "fallow_hollow", "name": "Fallow-Hollow", "kind": "flitted", "near": (360, 235), "reach": 110, "style": "wall", "land": 140},
    {"id": "miller_green", "name": "Miller's-Green", "kind": "mill", "near": (60, -55), "reach": 60, "style": "wall", "land": 110},
    {"id": "withy_hollow", "name": "Withy-Hollow", "kind": "forester", "near": (-215, 45), "reach": 70, "style": "hedge", "land": 100},
]
# The two villages the generator set down: their tofts are worked from here, and their fields reach this far.
VILLAGES = [
    {"id": "bramblebridge", "name": "Bramblebridge", "at": (-587, 203), "houses": "bramblebridge_houses", "style": "hedge", "land": 235,
     "green": (-593.9, 257.7), "green_reach": 20.0},
    {"id": "hearthstead", "name": "Hearthstead", "at": (39, -195), "houses": "hearthstead_houses", "style": "mixed", "land": 215,
     "green": (39.2, -194.6), "green_reach": 30.0},
]

# What Act I and the corridor already stand on (island frame, radius in metres): fields may lie under
# these, but no boundary, tree, building or prop goes inside (docs/29 §4, docs/27 §6, docs/31 §7).
KEEP_CLEAR = [
    ("spawn", -584.0, 182.0, 22.0), ("orchard_gate", -586.0, 192.0, 14.0), ("alf_gate", -579.0, 188.0, 8.0),
    ("nokes_gate", -596.0, 199.0, 6.0), ("tenar_gate", -590.0, 193.0, 6.0), ("guardian", -588.5, 204.0, 20.0),
    ("green", -593.9, 257.7, 20.0), ("alf_yard", -634.0, 255.0, 8.0), ("wrights_yard", -638.3, 259.4, 14.0),
    ("watermill", -512.0, 259.4, 22.0), ("granary", -500.0, 246.0, 26.0), ("hearth", -515.0, 254.0, 8.0),
    ("hounds_1", -790.0, 90.0, 26.0), ("hounds_2", -560.0, 40.0, 26.0), ("hounds_3", -660.0, 190.0, 26.0),
    ("grove_root", -770.0, 148.0, 26.0), ("grove_leaf", -505.0, 178.0, 26.0), ("grove_flower", -604.0, 73.0, 24.0),
    ("grove_seed", -705.0, 5.0, 26.0), ("weir", -453.4, 212.3, 18.0), ("sanctum_door", -146.8, 233.8, 26.0),
    ("elder_oak", -189.4, 167.2, 34.0), ("stone_bridge", -589.0, 213.3, 24.0), ("market", 39.2, -194.6, 34.0),
    ("pier", 37.55, -247.0, 40.0), ("scribe_table", -18.8, -182.6, 12.0), ("downs_gate", 35.1, -137.6, 16.0),
    ("windmill", 20.5, -27.3, 22.0),
]
# Old ways that are nobody's track: a riverside path to the river's mouth, the orchard walk, a way down to the
# north strand, the drove up onto the downs (island frame: from, to).
FOOTPATHS = [
    {"name": "bramble_bank", "from": (-600, 176), "to": (-948, 138)},
    {"name": "orchard_walk", "from": (-520, 52), "to": (-742, -18)},
    {"name": "strand_way", "from": (-196, -262), "to": (-232, -372)},
    {"name": "downs_drove", "from": (-246, -92), "to": (-150, -22)},
    {"name": "cove_steps", "from": (560, -262), "to": (596, -318)},
]

# The road packs (EmbershoreBuilder.ENCOUNTERS): road, share along it, side.
ENCOUNTERS = [
    ("lane", 0.12, 1.0), ("lane", 0.24, -1.0), ("lane", 0.36, 1.0), ("lane", 0.58, -1.0), ("lane", 0.74, 1.0), ("hollow", 0.1, -1.0),
    ("hollow", 0.42, 1.0), ("hollow", 0.64, -1.0), ("hollow", 0.86, 1.0), ("coast", 0.2, -1.0), ("coast", 0.4, -1.0), ("coast", 0.66, 1.0),
    ("downs", 0.08, -1.0), ("downs", 0.2, 1.0), ("lane", 0.9, 1.0),
]
PACK_CLEAR = 28.0
ROAD_HALF = {"lane": 2.5, "hollow": 2.5, "gate": 2.5, "coast": 2.5, "downs": 1.5, "strait": 1.5, "eel": 1.5}

POI_CLEAR = {
    "chime_post": 9.0, "stone_arch_bridge": 22.0, "watermill": 18.0, "weir": 16.0, "workshop": 14.0, "smithy": 12.0, "landmark_tree": 30.0,
    "dungeon_entrance": 26.0, "spring": 14.0, "viewpoint": 12.0, "bridge_end": 18.0, "gatehouse": 28.0, "junction": 12.0, "cove": 26.0,
    "market": 34.0, "scribe_table": 12.0, "pier": 34.0, "windmill": 22.0, "one_way_gate": 16.0, "causeway_head": 28.0,
}


def to_gen(x: float, z: float) -> np.ndarray:
    return np.array([x + ORIGIN[0], z + ORIGIN[1]])


def smooth_noise(rng: np.random.Generator, wavelength: int) -> np.ndarray:
    small = rng.standard_normal((D // wavelength + 4, W // wavelength + 4))
    big = ndi.zoom(small, wavelength, order=3)[:D, :W]
    return big / (big.std() + 1e-9)


def disc(mask: np.ndarray, x: float, z: float, r: float, value=True) -> None:
    x0, x1 = max(0, int(x - r - 1)), min(W, int(x + r + 2))
    z0, z1 = max(0, int(z - r - 1)), min(D, int(z + r + 2))
    if x0 >= x1 or z0 >= z1:
        return
    zz, xx = np.mgrid[z0:z1, x0:x1]
    inside = (xx + 0.5 - x) ** 2 + (zz + 0.5 - z) ** 2 <= r * r
    mask[z0:z1, x0:x1][inside] = value


def draw_lines(lines: list, width: float) -> np.ndarray:
    image = Image.new("L", (W, D), 0)
    pen = ImageDraw.Draw(image)
    for points in lines:
        flat = [(float(p[0]), float(p[1])) for p in points]
        if len(flat) >= 2:
            pen.line(flat, fill=255, width=max(1, int(round(width))))
    return np.asarray(image) > 0


def fill_polygon(points: np.ndarray) -> np.ndarray:
    image = Image.new("L", (W, D), 0)
    ImageDraw.Draw(image).polygon([(float(p[0]), float(p[1])) for p in points], fill=255)
    return np.asarray(image) > 0


def rdp(points: np.ndarray, tolerance: float) -> np.ndarray:
    if len(points) < 3:
        return points
    keep = np.zeros(len(points), bool)
    keep[0] = keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        a, b = stack.pop()
        if b - a < 2:
            continue
        seg = points[b] - points[a]
        length = np.hypot(*seg)
        rel = points[a + 1:b] - points[a]
        if length < 1e-9:
            dist = np.hypot(rel[:, 0], rel[:, 1])
        else:
            dist = np.abs(rel[:, 0] * seg[1] - rel[:, 1] * seg[0]) / length
        i = int(np.argmax(dist))
        if dist[i] > tolerance:
            keep[a + 1 + i] = True
            stack.append((a, a + 1 + i))
            stack.append((a + 1 + i, b))
    return points[keep]


def chaikin(points: np.ndarray, rounds: int) -> np.ndarray:
    for _ in range(rounds):
        if len(points) < 3:
            return points
        q = points[:-1] * 0.75 + points[1:] * 0.25
        r = points[:-1] * 0.25 + points[1:] * 0.75
        mid = np.empty((len(q) * 2, 2))
        mid[0::2] = q
        mid[1::2] = r
        points = np.vstack([points[:1], mid, points[-1:]])
    return points


def resample(points: np.ndarray, step: float) -> np.ndarray:
    seg = np.hypot(*(points[1:] - points[:-1]).T)
    along = np.concatenate([[0.0], np.cumsum(seg)])
    total = along[-1]
    if total < step:
        return points[[0, -1]]
    count = max(2, int(round(total / step)) + 1)
    at = np.linspace(0.0, total, count)
    return np.stack([np.interp(at, along, points[:, 0]), np.interp(at, along, points[:, 1])], axis=1)


def polyline_length(points: np.ndarray) -> float:
    return float(np.hypot(*(points[1:] - points[:-1]).T).sum())


def unit(v: np.ndarray) -> np.ndarray:
    n = float(np.hypot(v[0], v[1]))
    return v / n if n > 1e-9 else np.array([1.0, 0.0])


class Land:
    """The generator's island as rasters, one cell a metre (row = Z, column = X)."""

    def __init__(self, gen_dir: Path):
        self.features = json.loads((gen_dir / "embershore_features.json").read_text())
        heights = np.fromfile(gen_dir / "embershore_height_f32.raw", dtype="<f4").reshape(D + 1, W + 1)
        self.heights = heights
        self.h = 0.25 * (heights[:-1, :-1] + heights[1:, :-1] + heights[:-1, 1:] + heights[1:, 1:])
        soft = ndi.gaussian_filter(heights, 2.0)
        gz, gx = np.gradient(soft)
        self.gx = gx[:D, :W]
        self.gz = gz[:D, :W]
        self.slope = np.hypot(self.gx, self.gz)
        broad = ndi.gaussian_filter(heights, 6.0)
        bz, bx = np.gradient(broad)
        self.bx = bx[:D, :W]
        self.bz = bz[:D, :W]
        self.tpi = self.h - ndi.uniform_filter(self.h, 81)
        self.mask = {name: np.asarray(Image.open(gen_dir / f"mask_{name}.png").convert("L")) > 127
                     for name in ["land", "moss_oaks", "road", "river", "cliff", "beach", "rain_shadow_dry"]}
        self.dry = ndi.gaussian_filter(np.asarray(Image.open(gen_dir / "mask_rain_shadow_dry.png").convert("L")).astype(np.float32) / 255.0, 20.0)
        self.land = self.mask["land"] & (self.h > 0.6)
        self.coast = ndi.distance_transform_edt(self.land)
        self.river_dist, nearest = ndi.distance_transform_edt(~self.mask["river"], return_indices=True)
        self.above_river = self.h - self.h[nearest[0], nearest[1]]
        self.moss_dist = ndi.distance_transform_edt(~self.mask["moss_oaks"])
        self.cliff = self.mask["cliff"] | (self.slope > 0.5)
        self.cliff_dist = ndi.distance_transform_edt(~self.cliff)
        self.roads = {name: np.array([[p[0], p[2]] for p in road["points"]]) for name, road in self.features["roads"].items()}
        self.rivers = {name: np.array([[p[0], p[1]] for p in river["points"]]) for name, river in self.features["rivers"].items()}

    def at(self, raster: np.ndarray, x: float, z: float):
        return raster[min(D - 1, max(0, int(z))), min(W - 1, max(0, int(x)))]

    def height(self, x: float, z: float) -> float:
        gx = min(W - 1e-3, max(0.0, x))
        gz = min(D - 1e-3, max(0.0, z))
        c, r = int(gx), int(gz)
        fx, fz = gx - c, gz - r
        hm = self.heights
        return float((hm[r, c] * (1 - fx) + hm[r, c + 1] * fx) * (1 - fz) + (hm[r + 1, c] * (1 - fx) + hm[r + 1, c + 1] * fx) * fz)

    def downhill(self, x: float, z: float) -> np.ndarray:
        return -np.array([float(self.at(self.bx, x, z)), float(self.at(self.bz, x, z))])


class Settlement:
    def __init__(self, gen_dir: Path, seed: int):
        self.seed = seed
        self.rng = np.random.default_rng(seed)
        self.land = Land(gen_dir)
        L = self.land
        f = L.features
        # --- What already stands: nothing of the layer goes on or through these -----------------
        self.road_lines = [L.roads[name] for name in L.roads]
        self.road_core = np.zeros((D, W), bool)
        for name, points in L.roads.items():
            self.road_core |= draw_lines([points], (ROAD_HALF.get(name, 2.0) + 2.6) * 2.0)
        self.road_dist = ndi.distance_transform_edt(~draw_lines(self.road_lines, 1.0))
        self.river_core = ndi.binary_dilation(L.mask["river"], iterations=4)
        race = np.array(f.get("mill_race", []))
        route = np.array(f.get("root_sanctum_route", []))
        self.hard = ~L.land | self.road_core | self.river_core | (L.moss_dist < 7.0) | L.cliff | L.mask["beach"]
        if len(race) >= 2:
            self.hard |= draw_lines([race], 8.0)
        self.soft = np.zeros((D, W), bool)
        if len(route) >= 2:
            self.soft |= draw_lines([route], 14.0)
        self.clear_spots: list[tuple[str, float, float, float]] = []
        for name, x, z, r in KEEP_CLEAR:
            g = to_gen(x, z)
            self.clear_spots.append((name, g[0], g[1], r))
        for key, entry in f["poi"].items():
            if "at" in entry:
                self.clear_spots.append((key, entry["at"][0], entry["at"][2], POI_CLEAR.get(entry.get("kind", ""), 10.0)))
        for index, (road, share, side) in enumerate(ENCOUNTERS):
            points = L.roads[road]
            i = min(len(points) - 2, max(1, int(share * (len(points) - 1))))
            along = unit(points[i + 1] - points[i - 1])
            across = np.array([-along[1], along[0]]) * side
            at = points[i] + across * 18.0
            if L.height(at[0], at[1]) < 1.0 or L.at(L.mask["river"], at[0], at[1]):
                at = points[i] - across * 18.0
            self.clear_spots.append((f"pack_{index}", float(at[0]), float(at[1]), PACK_CLEAR))
        for x, z in f.get("first_quiet_sleepers", []):
            self.clear_spots.append(("sleeper", x, z, 14.0))
        for name, x, z, r in self.clear_spots:
            disc(self.soft, x, z, r)
        self.blocked = self.hard | self.soft  # no boundary, tree, building or prop
        self.steadings: list[dict] = []
        self.plots: list[dict] = []
        self.tracks: list[dict] = []
        self.fields: list[dict] = []
        self.boundaries: list[dict] = []
        self.trees: list[list] = []
        self.props: list[dict] = []
        self.flocks: list[dict] = []
        self.wood_mix: list[list] = []
        self.building_mask = np.zeros((D, W), bool)
        self.label = np.zeros((D, W), np.int32)       # field ids (0: none)
        self.use = np.zeros((D, W), np.uint8)         # LANDUSE ids
        self.tilth = np.zeros((D, W), np.uint8)       # row direction
        self.owner = np.zeros((D, W), np.int16)       # which settlement works this ground (index + 1)
        self.settle_points: list[dict] = []           # steadings and villages: at, land, style
        self.tree_grid: dict[tuple[int, int], list] = {}

    # --- 1. Steadings: the best ground near each seed ---------------------------------------------
    def site_score(self) -> np.ndarray:
        L = self.land
        flat = np.clip(1.0 - L.slope / 0.13, 0.0, 1.0)
        down = np.stack([-L.bx, -L.bz])
        steep = np.hypot(down[0], down[1]) + 1e-6
        sun = np.array([0.5, 0.87])  # the sun stands south-south-east: a slope falling that way faces it
        sunny = (down[0] * sun[0] + down[1] * sun[1]) / steep * np.clip(steep / 0.06, 0.0, 1.0)
        road = np.exp(-((self.road_dist - 70.0) / 55.0) ** 2)
        water = np.exp(-((L.river_dist - 90.0) / 110.0) ** 2) * (L.above_river > 2.5)
        shelter = np.exp(-((L.tpi + 1.0) / 3.5) ** 2)
        score = 2.2 * flat + 0.8 * sunny + 1.0 * road + 0.5 * water + 0.6 * shelter
        ok = L.land & ~ndi.binary_dilation(self.blocked, iterations=14) & (L.slope < 0.15) & (L.coast > 30.0) & (L.moss_dist > 26.0) \
            & (L.h > 3.0) & (L.h < 44.0) & (L.cliff_dist > 30.0)
        # A yard needs its whole plot gentle, not one flat metre: the worst slope over a 30 m square counts.
        worst = ndi.maximum_filter(L.slope, 31)
        score -= 6.0 * np.clip(worst - 0.14, 0.0, 1.0)
        score[~ok] = -1e9
        return score

    def place_steadings(self) -> None:
        L = self.land
        score = self.site_score()
        zz, xx = np.mgrid[0:D, 0:W]
        taken: list[np.ndarray] = []
        for spec in STEADINGS:
            centre = to_gen(*spec["near"])
            local = score.copy()
            dist = np.hypot(xx + 0.5 - centre[0], zz + 0.5 - centre[1])
            local[dist > spec["reach"]] = -1e9
            local -= dist / spec["reach"] * 0.6
            for other in taken:
                local[np.hypot(xx + 0.5 - other[0], zz + 0.5 - other[1]) < 130.0] = -1e9
            if spec["kind"] == "fisher":
                local += 1.2 * np.exp(-((L.coast - 45.0) / 25.0) ** 2)
            if spec["kind"] == "forester":
                local += 1.0 * np.exp(-((L.moss_dist - 40.0) / 20.0) ** 2)
            index = int(np.argmax(local))
            if local.flat[index] < -1e8:
                print(f"  no ground for {spec['name']}")
                continue
            at = np.array([index % W + 0.5, index // W + 0.5])
            taken.append(at)
            steading = self.lay_steading(spec, at)
            self.steadings.append(steading)
            self.settle_points.append({"id": spec["id"], "at": at, "land": spec["land"], "style": spec["style"], "kind": spec["kind"]})
        for village in VILLAGES:
            self.settle_points.append({"id": village["id"], "at": to_gen(*village["at"]), "land": village["land"], "style": village["style"], "kind": "village"})

    def lay_steading(self, spec: dict, at: np.ndarray) -> dict:
        """A yard open to the sun with the house at its back and the barn across the weather."""
        L = self.land
        down = L.downhill(at[0], at[1])
        slope = float(np.hypot(*down))
        sun = np.array([0.5, 0.87])
        nearest_road = self.nearest_road_point(at)
        to_road = unit(nearest_road - at)
        front = unit(unit(down) * min(1.0, slope / 0.07) * 1.2 + sun * 0.7 + to_road * 0.5)
        best = None
        for turn in [0.0, 0.35, -0.35, 0.7, -0.7, 1.05, -1.05, 1.57, -1.57, 2.4, -2.4, math.pi]:
            c, s = math.cos(turn), math.sin(turn)
            f = np.array([front[0] * c - front[1] * s, front[0] * s + front[1] * c])
            layout = self.steading_layout(spec, at, f)
            bad = sum(1 for b in layout["buildings"] if not self.footprint_ok(b))
            cost = bad * 10.0 + abs(turn)
            if best is None or cost < best[0]:
                best = (cost, layout)
            if bad == 0:
                break
        layout = best[1]
        layout["buildings"] = [b for b in layout["buildings"] if self.footprint_ok(b)]
        for b in layout["buildings"]:
            self.building_mask |= fill_polygon(self.footprint(b, 1.5))
        return layout

    def steading_layout(self, spec: dict, at: np.ndarray, front: np.ndarray) -> dict:
        right = np.array([-front[1], front[0]])  # to the right of someone standing in the yard, looking out the front
        kind = spec["kind"]
        seed = int(self.rng.integers(1, 9999))
        buildings: list[dict] = []
        props: list[dict] = []

        def b(what: str, offset: tuple[float, float], facing: np.ndarray, size: tuple[float, float], look: str) -> dict:
            centre = at + right * offset[0] + front * offset[1]
            entry = {"kind": what, "at": [round(float(centre[0]), 2), round(float(centre[1]), 2)],
                     "facing": [round(float(facing[0]), 4), round(float(facing[1]), 4)], "size": list(size), "look": look,
                     "seed": seed + len(buildings) * 7}
            buildings.append(entry)
            return entry

        def p(what: str, offset: tuple[float, float], yaw_of: np.ndarray | None = None) -> None:
            centre = at + right * offset[0] + front * offset[1]
            facing = yaw_of if yaw_of is not None else front
            props.append({"kind": what, "at": [round(float(centre[0]), 2), round(float(centre[1]), 2)],
                          "facing": [round(float(facing[0]), 4), round(float(facing[1]), 4)]})

        stone = spec["style"] == "wall"
        if kind == "farm" or kind == "hillfarm":
            b("farmhouse", (0.0, -11.0), front, (11.0, 6.0), "slate_stone" if stone else "thatch_lime")
            b("barn", (-14.5, 1.0), right, (12.0, 6.5), "barn_stone" if stone else "barn_board")
            b("byre", (13.5, 2.0), -right, (9.0, 4.6), "byre_stone" if stone else "byre_board")
            if kind == "farm":
                b("granary", (-8.5, 12.5), -front, (4.2, 4.2), "granary")
            else:
                b("fold", (22.0, -14.0), front, (9.0, 9.0), "fold")
            p("well", (4.0, 1.5))
            p("rick", (-24.0, -3.0))
            p("rick", (-24.5, 5.0))
            p("cart", (7.0, 7.5), right)
            p("trough", (9.0, -1.0), right)
            p("woodpile", (7.0, -8.6), right)
            p("hives", (20.0, -20.0), front)
            p("washing", (-9.0, -19.0), right)
            p("dog_kennel", (-6.6, -6.0), front)
            yard = (30.0, 24.0)
            garden = {"offset": (11.5, -13.0), "size": (10.0, 12.0)}
            orchard = {"offset": (-4.0, -30.0), "size": (26.0, 20.0)}
        elif kind == "croft" or kind == "forester" or kind == "mill":
            b("cottage", (0.0, -8.0), front, (8.4, 5.2), "slate_stone" if stone else "thatch_lime")
            b("byre", (-10.5, 1.5), right, (7.0, 4.4), "byre_stone" if stone else "byre_board")
            p("well", (5.0, 0.0))
            p("woodpile", (5.6, -7.6), right)
            p("rick", (-17.0, -3.0))
            if kind == "forester":
                p("timber_stack", (9.0, 4.0), right)
                p("timber_stack", (10.0, 9.0), front)
                p("saw_horse", (4.0, 6.0), right)
                p("charcoal_clamp", (-14.0, 12.0))
            elif kind == "mill":
                b("granary", (9.5, 3.0), -right, (4.2, 4.2), "granary")
                p("cart", (2.0, 7.0), right)
                p("sacks", (5.0, 4.0))
            else:
                p("cart", (3.0, 6.5), right)
                p("hives", (12.0, -12.0), front)
            p("washing", (-7.0, -14.0), right)
            yard = (22.0, 18.0)
            garden = {"offset": (9.0, -9.0), "size": (8.0, 10.0)}
            orchard = {"offset": (-2.0, -23.0), "size": (18.0, 14.0)}
        elif kind == "fisher":
            b("cottage", (0.0, -7.0), front, (7.6, 5.0), "slate_lime")
            b("net_shed", (-9.5, 2.0), right, (5.6, 3.8), "byre_board")
            p("boat", (7.0, 6.0), right)
            p("net_rack", (2.0, 8.0), right)
            p("net_rack", (-3.0, 9.0), right)
            p("fish_rack", (9.0, -2.0), front)
            p("woodpile", (5.2, -6.8), right)
            p("lobster_pots", (-5.0, 6.0))
            yard = (20.0, 16.0)
            garden = {"offset": (8.5, -8.0), "size": (7.0, 8.0)}
            orchard = None
        else:  # flitted: the house lost its roof, the byre its door, the cart was left where it stood
            b("ruin", (0.0, -8.0), front, (8.4, 5.2), "ruin_house")
            b("ruin", (-11.0, 1.5), right, (7.0, 4.4), "ruin_byre")
            p("cart_broken", (4.0, 6.0), right)
            p("well_dry", (5.0, 0.0))
            p("plough_left", (12.0, 8.0), right)
            yard = (22.0, 18.0)
            garden = {"offset": (9.0, -9.0), "size": (8.0, 10.0)}
            orchard = {"offset": (-2.0, -23.0), "size": (18.0, 14.0)}

        def rect(offset: tuple[float, float], size: tuple[float, float]) -> list:
            c = at + right * offset[0] + front * offset[1]
            hw, hd = size[0] * 0.5, size[1] * 0.5
            corners = [c + right * sx * hw + front * sz * hd for sx, sz in [(-1, -1), (1, -1), (1, 1), (-1, 1)]]
            return [[round(float(q[0]), 2), round(float(q[1]), 2)] for q in corners]

        gate = at + front * (yard[1] * 0.5 + 0.5)
        made = {"id": spec["id"], "name": spec["name"], "kind": kind, "style": spec["style"],
                "at": [round(float(at[0]), 2), round(float(at[1]), 2)], "facing": [round(float(front[0]), 4), round(float(front[1]), 4)],
                "buildings": buildings, "props": props, "yard": rect((0.0, 0.0), yard), "gate": [round(float(gate[0]), 2), round(float(gate[1]), 2)]}
        if garden is not None:
            made["garden"] = rect(garden["offset"], garden["size"])
        if orchard is not None:
            made["orchard"] = rect(orchard["offset"], orchard["size"])
        return made

    def footprint(self, building: dict, grow: float = 0.0) -> np.ndarray:
        c = np.array(building["at"])
        f = np.array(building["facing"])
        r = np.array([-f[1], f[0]])
        hw, hd = building["size"][0] * 0.5 + grow, building["size"][1] * 0.5 + grow
        return np.array([c + r * sx * hw + f * sz * hd for sx, sz in [(-1, -1), (1, -1), (1, 1), (-1, 1)]])

    def footprint_ok(self, building: dict) -> bool:
        L = self.land
        corners = self.footprint(building, 1.0)
        heights = []
        for q in list(corners) + [np.array(building["at"])]:
            if not (2 <= q[0] < W - 2 and 2 <= q[1] < D - 2):
                return False
            if L.at(self.blocked, q[0], q[1]) or not L.at(L.land, q[0], q[1]) or L.at(self.building_mask, q[0], q[1]):
                return False
            heights.append(L.height(q[0], q[1]))
        return max(heights) - min(heights) < (2.6 if building["kind"] in ("barn", "farmhouse") else 2.2)

    def nearest_road_point(self, at: np.ndarray) -> np.ndarray:
        best, best_d = None, 1e9
        for points in self.road_lines:
            d = np.hypot(points[:, 0] - at[0], points[:, 1] - at[1])
            i = int(np.argmin(d))
            if d[i] < best_d:
                best, best_d = points[i], d[i]
        return best

    # --- 2. Village tofts: each of the generator's houses gets a frontage and a garden ---------------
    def place_plots(self) -> None:
        L = self.land
        for village in VILLAGES:
            houses = np.array(L.features[village["houses"]])
            green = to_gen(*village["green"])
            for index, house in enumerate(houses):
                road = self.nearest_road_point(house)
                toward = road - house
                if np.hypot(*toward) > 46.0 or np.hypot(*toward) < 4.0:
                    toward = green - house
                front = unit(toward)
                # Square the frontage to the lane where it runs past: face it across, not at an angle.
                looks = ["gable_clay", "gable_slate", "gable_moss", "cot_thatch", "cot_slate", "gable_clay", "cot_thatch", "gable_slate"]
                look = looks[(index * 3 + (0 if village["id"] == "bramblebridge" else 5)) % len(looks)]
                if index == 0:
                    look = "inn"
                wide = 9.0 if look == "inn" else (7.2 if look.startswith("gable") else 8.0)
                deep = 6.6 if look == "inn" else (6.0 if look.startswith("gable") else 5.2)
                entry = {"kind": "inn" if index == 0 else ("house" if look.startswith("gable") else "cottage"),
                         "at": [round(float(house[0]), 2), round(float(house[1]), 2)], "facing": [round(float(front[0]), 4), round(float(front[1]), 4)],
                         "size": [wide, deep], "look": look, "seed": 20 + index + (0 if village["id"] == "bramblebridge" else 40), "generator_house": index}
                right = np.array([-front[1], front[0]])
                back = house - front * (deep * 0.5 + 8.5)
                hw, hd = 6.5, 8.0
                garden = [back + right * sx * hw + front * sz * hd for sx, sz in [(-1, -1), (1, -1), (1, 1), (-1, 1)]]
                plot = {"village": village["id"], "building": entry,
                        "garden": [[round(float(q[0]), 2), round(float(q[1]), 2)] for q in garden], "props": []}
                side = 1.0 if index % 2 == 0 else -1.0
                for what, offset in [("woodpile", (side * (wide * 0.5 + 0.9), -1.0)), ("bench", (-side * 1.8, deep * 0.5 + 0.9)),
                                     ("hives" if index % 3 == 0 else "washing", (side * 2.0, -(deep * 0.5 + 6.0)))]:
                    c = house + right * offset[0] + front * offset[1]
                    plot["props"].append({"kind": what, "at": [round(float(c[0]), 2), round(float(c[1]), 2)],
                                          "facing": [round(float(right[0]), 4), round(float(right[1]), 4)]})
                self.plots.append(plot)
                self.building_mask |= fill_polygon(self.footprint(entry, 1.5))

    # --- 3. Tracks: the cheapest walk from each yard gate to a road ------------------------------------
    def lay_tracks(self) -> None:
        L = self.land
        cost = 1.0 + 70.0 * L.slope ** 2
        cost[L.mask["moss_oaks"]] += 5.0
        cost[self.river_core] += 30.0
        cost[L.cliff] = 800.0
        cost[~L.land] = 5000.0
        cost[self.soft] += 25.0
        cost[self.building_mask] = 600.0
        on_road = draw_lines(self.road_lines, 3.0)
        cost[on_road] = 0.25
        targets = on_road.copy()
        order = sorted(self.steadings, key=lambda s: float(self.land.at(self.road_dist, *s["at"])))
        for steading in order:
            gate = np.array(steading["gate"])
            # Step out of the yard first, so the track leaves through the gate.
            out = gate + np.array(steading["facing"]) * 6.0
            start = (int(gate[1]), int(gate[0]))
            mcp = MCP_Geometric(cost, fully_connected=True)
            costs, _ = mcp.find_costs([start])
            reach = np.where(targets, costs, np.inf)
            end = np.unravel_index(int(np.argmin(reach)), reach.shape)
            if not np.isfinite(reach[end]):
                continue
            path = np.array(mcp.traceback(end))[:, ::-1].astype(float) + 0.5
            # Snap the far end onto the road or track it joins.
            path = np.vstack([gate[None, :], path[1:]])
            line = rdp(path, 3.0)
            if len(line) > 2:
                line = np.vstack([line[:1], (line[0] + out) * 0.5 if np.hypot(*(line[1] - line[0])) > 10.0 else line[1:2], line[1:]])
            line = self.gentle(self.relax(resample(chaikin(line, 3), 3.0), 12))
            if polyline_length(line) < 8.0:
                continue
            self.tracks.append({"name": steading["id"] + "_track", "to": steading["id"], "half_width": 1.2,
                                "points": [[round(float(p[0]), 2), round(float(p[1]), 2)] for p in line]})
            track = draw_lines([line], 3.0)
            cost[track] = 0.25
            targets |= track
        # The footpaths: from a road or a track to somewhere worth walking to.
        for spec in FOOTPATHS:
            a, b = to_gen(*spec["from"]), to_gen(*spec["to"])
            mcp = MCP_Geometric(cost, fully_connected=True)
            costs, _ = mcp.find_costs([(int(a[1]), int(a[0]))])
            # The cheapest cell to reach within 30 m of where the path is going.
            z0, z1, x0, x1 = max(0, int(b[1]) - 30), min(D, int(b[1]) + 31), max(0, int(b[0]) - 30), min(W, int(b[0]) + 31)
            window = costs[z0:z1, x0:x1]
            best = np.unravel_index(int(np.argmin(window)), window.shape)
            end = (z0 + int(best[0]), x0 + int(best[1]))
            if not np.isfinite(costs[end]) or costs[end] > 4000.0:
                print(f"  no way for {spec['name']}")
                continue
            path = np.array(mcp.traceback(end))[:, ::-1].astype(float) + 0.5
            line = self.gentle(self.relax(resample(chaikin(rdp(path, 3.0), 3), 3.0), 14))
            self.tracks.append({"name": spec["name"], "to": "", "half_width": 0.9,
                                "points": [[round(float(q[0]), 2), round(float(q[1]), 2)] for q in line]})
            cost[draw_lines([line], 3.0)] = 0.25
        # Where a way wades the river: a ford of stepping stones.
        for track in self.tracks:
            points = np.array(track["points"])
            wet = [bool(L.at(L.mask["river"], q[0], q[1])) for q in points]
            i = 0
            while i < len(points):
                if wet[i]:
                    j = i
                    while j + 1 < len(points) and wet[j + 1]:
                        j += 1
                    mid = (points[i] + points[j]) * 0.5
                    way = unit(points[min(len(points) - 1, j + 1)] - points[max(0, i - 1)])
                    self.props.append({"kind": "ford", "at": [round(float(mid[0]), 2), round(float(mid[1]), 2)],
                                       "facing": [round(float(way[0]), 4), round(float(way[1]), 4)]})
                    i = j + 1
                else:
                    i += 1
        # Each track's bed, and the green way either side of it.
        self.track_core = np.zeros((D, W), bool)
        for track in self.tracks:
            self.track_core |= draw_lines([np.array(track["points"])], (1.2 + 1.8) * 2.0)
        self.hard |= self.track_core
        self.blocked |= self.track_core

    @staticmethod
    def relax(points: np.ndarray, passes: int) -> np.ndarray:
        for _ in range(passes):
            if len(points) < 3:
                break
            points = np.vstack([points[:1], points[:-2] * 0.25 + points[1:-1] * 0.5 + points[2:] * 0.25, points[-1:]])
        return points

    @staticmethod
    def bends(points: np.ndarray) -> np.ndarray:
        """The turn at each inner point, in degrees."""
        a, b = points[1:-1] - points[:-2], points[2:] - points[1:-1]
        return np.abs(np.degrees(np.arctan2(a[:, 0] * b[:, 1] - a[:, 1] * b[:, 0], (a * b).sum(axis=1))))

    @staticmethod
    def gentle(points: np.ndarray, limit: float = 13.0) -> np.ndarray:
        """Eased until no turn between 3 m steps is sharper than `limit` degrees (a cart's turning circle), ends kept."""
        line = resample(points, 3.0)
        for _ in range(400):
            if len(line) < 3 or float(Settlement.bends(line).max()) <= limit:
                break
            line = resample(Settlement.relax(line, 2), 3.0)
        return line

    @staticmethod
    def as_laid(points: np.ndarray) -> np.ndarray:
        """The line as the engine lays it (IslandBuilder._lay_road for a road laid as drawn): rounded twice, a point every 3 m."""
        line = chaikin(points, 2)
        out = [line[0]]
        carried = 0.0
        for a, b in zip(line[:-1], line[1:]):
            length = float(np.hypot(*(b - a)))
            along = 3.0 - carried
            while along < length:
                out.append(a + (b - a) * (along / length))
                along += 3.0
            carried = length - (along - 3.0)
        if np.hypot(*(out[-1] - line[-1])) > 0.5:
            out.append(line[-1])
        else:
            out[-1] = line[-1]
        return np.array(out)

    # --- 4. Fields ---------------------------------------------------------------------------------
    def lay_fields(self) -> None:
        L = self.land
        rng = self.rng
        zz, xx = np.mgrid[0:D, 0:W]
        # Who works each piece of ground: the nearest settlement whose land reaches it.
        reach = np.full((D, W), 9.0, np.float32)
        owner = np.zeros((D, W), np.int16)
        for index, point in enumerate(self.settle_points):
            d = np.hypot(xx + 0.5 - point["at"][0], zz + 0.5 - point["at"][1]) / point["land"]
            closer = d < reach
            reach[closer] = d[closer]
            owner[closer] = index + 1
        ragged = 1.0 + 0.24 * smooth_noise(rng, 80)
        worked = (reach * ragged) < 0.94
        # A valley this size also keeps its fields out of each other's way: the river, the wood and the cliffs part them.
        cultivable = worked & ~self.hard & (L.slope < 0.25) & (L.h > 2.2) & (L.h < 36.0) & (L.cliff_dist > 9.0) & (L.coast > 7.0)
        cultivable = ndi.binary_opening(cultivable, iterations=3)
        cultivable = ndi.binary_closing(cultivable, iterations=2) & ~self.hard
        parts, count = ndi.label(cultivable)
        sizes = ndi.sum(cultivable, parts, index=np.arange(1, count + 1))
        for part, size in enumerate(sizes, start=1):
            if size < 900:
                cultivable[parts == part] = False
        self.owner = np.where(cultivable, owner, 0).astype(np.int16)
        # Steading and village closes first: yards, gardens and orchards are their own parcels.
        next_id = 1
        closes: dict[int, dict] = {}
        for steading in self.steadings:
            for what, use in [("yard", "yard"), ("garden", "garden"), ("orchard", "orchard")]:
                if what not in steading:
                    continue
                area = fill_polygon(np.array(steading[what])) & ~self.hard & L.land
                if what != "yard":
                    area &= ~fill_polygon(np.array(steading["yard"]))
                if area.sum() < 20:
                    continue
                self.label[area] = next_id
                front = np.array(steading["facing"])
                closes[next_id] = {"use": "fallow" if steading["kind"] == "flitted" and what != "yard" else use, "steading": steading["id"],
                                   "row": [float(-front[1]), float(front[0])], "close": what}
                next_id += 1
        # The generator's own orchards (Lee-Shore Orchards' three blocks) and its grain strips are parcels too.
        grove = np.zeros((D, W), bool)
        for tree in L.features.get("orchard_trees", []):
            disc(grove, tree[0], tree[1], 8.0)
        grove = ndi.binary_closing(grove, iterations=7) & ~self.hard & L.land & (self.label == 0)
        parts, count = ndi.label(grove)
        for part in range(1, count + 1):
            area = parts == part
            if area.sum() < 400:
                continue
            self.label[area] = next_id
            closes[next_id] = {"use": "orchard", "steading": "bramblebridge", "row": [1.0, 0.0], "close": "grove"}
            next_id += 1
        strips = np.array(L.features.get("grain_field_rows", []))
        if len(strips):
            mids = strips.mean(axis=1)
            groups: list[list[int]] = []
            for index, mid in enumerate(mids):
                for group in groups:
                    if min(np.hypot(*(mids[other] - mid)) for other in group) < 22.0:
                        group.append(index)
                        break
                else:
                    groups.append([index])
            for n, group in enumerate(groups):
                area = ndi.binary_dilation(draw_lines([strips[i] for i in group], 5.0), iterations=1)
                area = ndi.binary_closing(area, iterations=6) & ~self.hard & L.land & (self.label == 0)
                if area.sum() < 300:
                    continue
                row = unit(strips[group[0]][1] - strips[group[0]][0])
                self.label[area] = next_id
                closes[next_id] = {"use": "barley" if n % 3 else "stubble", "steading": "miller_green", "row": [float(row[0]), float(row[1])], "close": "strips"}
                next_id += 1
        for plot in self.plots:
            area = fill_polygon(np.array(plot["garden"])) & ~self.hard & L.land & (self.label == 0) & ~self.soft
            if area.sum() < 30:
                continue
            self.label[area] = next_id
            front = np.array(plot["building"]["facing"])
            closes[next_id] = {"use": "garden", "steading": plot["village"], "row": [float(front[0]), float(front[1])], "close": "toft"}
            plot["field"] = next_id
            next_id += 1
        # The open fields: seeds closer together near a home (small closes), wider apart further out.
        home = np.full((D, W), 1e9, np.float32)
        for point in self.settle_points:
            home = np.minimum(home, np.hypot(xx + 0.5 - point["at"][0], zz + 0.5 - point["at"][1]))
        free = cultivable & (self.label == 0)
        cells = np.argwhere(free)
        rng.shuffle(cells)
        seeds: list[np.ndarray] = []
        radii: list[float] = []
        grid: dict[tuple[int, int], list[int]] = {}
        for z, x in cells[:60000]:
            r = float(np.clip(13.0 + 0.12 * home[z, x], 17.0, 38.0))
            key = (int(x // 48), int(z // 48))
            clash = False
            for gx in (key[0] - 1, key[0], key[0] + 1):
                for gz in (key[1] - 1, key[1], key[1] + 1):
                    for other in grid.get((gx, gz), []):
                        gap = math.hypot(seeds[other][0] - x, seeds[other][1] - z)
                        if gap < 0.5 * (r + radii[other]) * 1.9:
                            clash = True
                            break
                    if clash:
                        break
                if clash:
                    break
            if clash:
                continue
            grid.setdefault(key, []).append(len(seeds))
            seeds.append(np.array([x + 0.5, z + 0.5]))
            radii.append(r)
        seeds_xy = np.array(seeds)
        # Fields lie along the slope's contour (a plough turns the furrow along the hill, not down it).
        tangents = np.array([unit(np.array([-L.at(L.bz, s[0], s[1]), L.at(L.bx, s[0], s[1])])) for s in seeds_xy])
        tree = cKDTree(seeds_xy)
        warp_x = smooth_noise(rng, 44) * 5.0
        warp_z = smooth_noise(rng, 44) * 5.0
        where = np.argwhere(free)
        query = np.stack([where[:, 1] + 0.5 + warp_x[where[:, 0], where[:, 1]], where[:, 0] + 0.5 + warp_z[where[:, 0], where[:, 1]]], axis=1)
        _, near = tree.query(query, k=min(6, len(seeds_xy)))
        stretch = 1.5
        best = np.full(len(query), 1e18)
        pick = np.zeros(len(query), np.int64)
        for k in range(near.shape[1]):
            cand = near[:, k]
            delta = query - seeds_xy[cand]
            t = tangents[cand]
            along = delta[:, 0] * t[:, 0] + delta[:, 1] * t[:, 1]
            across = -delta[:, 0] * t[:, 1] + delta[:, 1] * t[:, 0]
            dist = (along / stretch) ** 2 + (across * stretch) ** 2
            better = dist < best
            best[better] = dist[better]
            pick[better] = cand[better]
        self.label[where[:, 0], where[:, 1]] = pick + next_id
        first_open = next_id
        next_id += len(seeds_xy)
        # A field is one piece: stray fragments go back to the waste (they make good spinneys).
        for field in range(first_open, next_id):
            area = self.label == field
            if not area.any():
                continue
            parts, count = ndi.label(area)
            if count > 1:
                sizes = ndi.sum(area, parts, index=np.arange(1, count + 1))
                keep = int(np.argmax(sizes)) + 1
                self.label[area & (parts != keep)] = 0
            if (self.label == field).sum() < 450:
                self.label[self.label == field] = 0
        self.closes = closes
        self.first_open = first_open
        self.field_count = next_id

    def use_fields(self) -> None:
        """What each field grows: by its slope, its damp, its soil and its neighbours (no two alike side by side)."""
        L = self.land
        rng = self.rng
        ids = [i for i in range(1, self.field_count) if (self.label == i).any()]
        index_of = {field: n for n, field in enumerate(ids)}
        objects = ndi.find_objects(self.label)
        # Neighbours: fields whose cells touch within 6 m (a hedge and its verge lie between).
        grown = ndi.grey_dilation(self.label, size=(9, 9))
        shrunk = -ndi.grey_dilation(-np.where(self.label > 0, self.label, 10**9), size=(9, 9))
        neighbours: dict[int, set[int]] = {field: set() for field in ids}
        both = (self.label > 0)
        for a, b in [(self.label[both], grown[both]), (self.label[both], shrunk[both])]:
            pairs = np.unique(np.stack([a, b], axis=1), axis=0)
            for p, q in pairs:
                if p != q and p in neighbours and q in neighbours:
                    neighbours[int(p)].add(int(q))
                    neighbours[int(q)].add(int(p))
        flitted = {s["id"] for s in self.steadings if s["kind"] == "flitted"}
        point_kind = {n + 1: p for n, p in enumerate(self.settle_points)}
        chosen: dict[int, str] = {}
        order = sorted(ids, key=lambda i: (i >= self.first_open, i))
        for field in order:
            box = objects[field - 1]
            area = self.label[box] == field
            cells = int(area.sum())
            slope = float(L.slope[box][area].mean())
            height = float(L.h[box][area].mean())
            dry = float(L.dry[box][area].mean())
            wet = float((L.river_dist[box][area] < 40.0).mean()) > 0.45 and float(L.above_river[box][area].mean()) < 9.0
            zc, xc = ndi.center_of_mass(area)
            centroid = np.array([box[1].start + xc + 0.5, box[0].start + zc + 0.5])
            owners = self.owner[box][area]
            owner = int(np.bincount(owners[owners > 0]).argmax()) if (owners > 0).any() else 0
            point = point_kind.get(owner)
            entry = {"id": field, "area": cells, "centroid": [round(float(centroid[0]), 1), round(float(centroid[1]), 1)],
                     "steading": point["id"] if point else "", "slope": round(slope, 3)}
            if field in self.closes:
                close = self.closes[field]
                entry.update({"use": close["use"], "row": close["row"], "close": close["close"], "steading": close["steading"]})
                chosen[field] = close["use"]
                self.fields.append(entry)
                continue
            # The field's long way (its cells' principal axis), turned to the contour on a slope.
            zs, xs = np.nonzero(area)
            spread = np.cov(np.stack([xs, zs]).astype(float))
            values, vectors = np.linalg.eigh(spread)
            long_way = unit(vectors[:, int(np.argmax(values))])
            if slope > 0.09:
                long_way = unit(np.array([-float(L.bz[box][area].mean()), float(L.bx[box][area].mean())]))
            entry["row"] = [round(float(long_way[0]), 4), round(float(long_way[1]), 4)]
            if point and point["id"] in flitted:
                use = "fallow"
            elif wet:
                use = "water_meadow"
            elif slope > 0.2 or height > 38.0:
                use = "pasture"
            else:
                south = 1.0 - dry
                hill = point is not None and point["kind"] in ("hillfarm", "fisher")
                weights = {
                    "pasture": 0.26 + (0.25 if hill else 0.0) + 0.5 * max(0.0, slope - 0.1) * 10.0,
                    "hay": 0.12 + 0.14 * south,
                    "barley": 0.2 + 0.12 * dry - (0.12 if hill else 0.0),
                    "plough": 0.11 + 0.05 * south,
                    "roots": 0.07 + 0.08 * south,
                    "stubble": 0.1 + 0.06 * dry,
                    "fallow": 0.05,
                }
                if slope > 0.13:
                    for crop in ("barley", "plough", "roots", "stubble"):
                        weights[crop] *= 0.35
                taken = [chosen[n] for n in neighbours[field] if n in chosen]
                for crop in set(taken):
                    if crop in weights:
                        weights[crop] *= 0.22 if crop != "pasture" else 0.6
                names = list(weights)
                share = np.array([max(1e-4, weights[n]) for n in names])
                use = names[int(rng.choice(len(names), p=share / share.sum()))]
            entry["use"] = use
            chosen[field] = use
            self.fields.append(entry)
        # Paint the use and the working direction; a green baulk is left along every edge.
        inner = ndi.minimum_filter(self.label, size=5) == ndi.maximum_filter(self.label, size=5)
        for entry in self.fields:
            field = entry["id"]
            box = objects[field - 1]
            area = self.label[box] == field
            use = entry["use"]
            self.use[box][area] = LANDUSE[use]
            row = np.array(entry["row"])
            angle = math.atan2(row[1], row[0]) % math.pi
            self.tilth[box][area] = 1 + int(round(angle / math.pi * 253.0))
        crop = np.isin(self.use, [LANDUSE[n] for n in ("barley", "plough", "roots", "stubble", "garden")])
        self.use[crop & ~inner] = LANDUSE["verge"]
        # The village greens and the rough common between the fields and the wild.
        for village in VILLAGES:
            green = np.zeros((D, W), bool)
            centre = to_gen(*village["green"])
            disc(green, centre[0], centre[1], village["green_reach"])
            green &= L.land & ~self.road_core & (self.label == 0)
            self.use[green] = LANDUSE["green"]
        zz, xx = np.mgrid[0:D, 0:W]
        near = np.zeros((D, W), bool)
        for point in self.settle_points:
            near |= np.hypot(xx + 0.5 - point["at"][0], zz + 0.5 - point["at"][1]) < point["land"] * 1.35
        common = near & L.land & (self.label == 0) & (self.use == 0) & ~L.mask["moss_oaks"] & ~L.cliff & ~L.mask["beach"] & (L.slope < 0.42)
        self.use[common] = LANDUSE["common"]

    # --- 5. Boundaries: the lines between fields, as hedges and walls ---------------------------------
    def lay_boundaries(self) -> None:
        L = self.land
        lab = self.label
        edge = np.zeros((D, W), bool)
        for shift in [(0, 1), (1, 0)]:
            a = lab[: D - shift[0], : W - shift[1]]
            b = lab[shift[0]:, shift[1]:]
            differ = (a != b) & ((a > 0) | (b > 0))
            edge[: D - shift[0], : W - shift[1]] |= differ
            edge[shift[0]:, shift[1]:] |= differ
        # No fence along the water (stock drink there), none on the cliff's lip, and none through what Act I stands on.
        edge &= ~ndi.binary_dilation(self.river_core, iterations=3)
        edge &= L.cliff_dist > 5.0
        edge &= ~self.soft
        edge &= L.land
        yard_ids = {field for field, close in self.closes.items() if close["close"] == "yard"}
        skeleton = skeletonize(ndi.binary_closing(edge, iterations=1))
        lines = self.trace(skeleton)
        style_of = {n + 1: p["style"] for n, p in enumerate(self.settle_points)}
        kind_of = {n + 1: p["kind"] for n, p in enumerate(self.settle_points)}
        use_of = {entry["id"]: entry["use"] for entry in self.fields}
        close_of = {field: close["close"] for field, close in self.closes.items()}
        rng = self.rng
        for raw in lines:
            if len(raw) < 6:
                continue
            line = raw.astype(float) + 0.5
            if len(line) > 6:
                kernel = np.ones(5) / 5.0
                body = np.stack([np.convolve(line[:, 0], kernel, mode="valid"), np.convolve(line[:, 1], kernel, mode="valid")], axis=1)
                line = np.vstack([line[:1], body, line[-1:]])
            line = rdp(line, 0.9)
            length = polyline_length(line)
            if length < 7.0:
                continue
            # What lies either side, sampled 3 m off the middle.
            mid = self.point_along(line, length * 0.5)
            normal = self.normal_along(line, length * 0.5)
            sides = [int(L.at(lab, *(mid + normal * 3.0))), int(L.at(lab, *(mid - normal * 3.0)))]
            owners = [int(L.at(self.owner, *(mid + normal * s))) for s in (4.0, -4.0)]
            owner = next((o for o in owners if o > 0), 0)
            style = style_of.get(owner, "hedge")
            by_road = bool(L.at(self.road_core, *(mid + normal * 4.0)) or L.at(self.road_core, *(mid - normal * 4.0))
                           or L.at(self.track_core, *(mid + normal * 3.5)) or L.at(self.track_core, *(mid - normal * 3.5)))
            closes = [close_of.get(s, "") for s in sides]
            uses = [use_of.get(s, "") for s in sides]
            flitted = kind_of.get(owner) == "flitted"
            if "yard" in closes:
                kind = "wall"
            elif "toft" in closes:
                kind = ["hurdle", "wall", "hedge", "fence"][int(rng.integers(0, 4))] if style != "wall" else ["wall", "wall", "hurdle"][int(rng.integers(0, 3))]
            elif "garden" in closes:
                kind = "hurdle"
            elif "orchard" in closes or "grove" in closes:
                kind = "hedge" if style != "wall" else "wall"
            elif "strips" in closes:
                kind = "wall" if by_road else "none"
            elif style == "wall":
                kind = "wall"
            elif style == "hedge":
                kind = "hedge"
            else:
                dry = float(L.at(L.dry, *mid))
                kind = "wall" if rng.random() < 0.12 + 0.5 * dry else "hedge"
            if kind == "hedge" and "pasture" in uses and close_of.get(sides[0], "") == "" and rng.random() < 0.12:
                kind = "fence"
            # Two tilled fields side by side need no fence between them: a green baulk parts them, or a line of trees.
            tilled = ("barley", "plough", "roots", "stubble", "hay", "fallow")
            if closes == ["", ""] and uses[0] in tilled and uses[1] in tilled and not by_road:
                roll = rng.random()
                if roll < 0.5:
                    kind = "baulk"
                elif roll < 0.62:
                    kind = "tree_line"
            if flitted and kind == "wall":
                kind = "wall_tumbled"
            if kind == "none":
                continue
            gaps: list[list] = []
            if kind in ("baulk", "tree_line"):
                self.boundaries.append({"kind": kind, "by_road": False, "length": round(length, 1),
                                        "points": [[round(float(p[0]), 2), round(float(p[1]), 2)] for p in line], "gaps": []})
                continue
            solid = kind in ("wall", "fence", "hurdle")
            if by_road and length > 22.0 and "toft" not in closes and "garden" not in closes:
                at = length * float(rng.uniform(0.3, 0.7))
                gaps.append([round(at - 1.8, 1), round(at + 1.8, 1), "gate"])
            elif "yard" in closes:
                # The yard's gateway faces the track (its gate point); the wall stops either side of it.
                pass
            elif length > 28.0 and (solid or rng.random() < 0.6):
                at = length * float(rng.uniform(0.25, 0.75))
                gaps.append([round(at - 1.7, 1), round(at + 1.7, 1), "gate" if rng.random() < 0.5 else "gap"])
            if solid:
                # A wall is never a cage: a way through at least every 55 m.
                reach = 55.0
                spots = np.arange(reach * 0.5, length, reach)
                for at in spots:
                    if all(abs(at - (g[0] + g[1]) * 0.5) > 20.0 for g in gaps) and 4.0 < at < length - 4.0:
                        gaps.append([round(float(at) - 1.5, 1), round(float(at) + 1.5, 1), "stile" if kind == "wall" and rng.random() < 0.5 else "gap"])
            if solid:
                # However the gateways fell, the longest stretch between two of them is halved until none is over the reach.
                for _ in range(40):
                    gaps.sort()
                    edges = [0.0] + [x for g in gaps for x in (g[0], g[1])] + [length]
                    stretches = [(edges[i + 1] - edges[i], edges[i]) for i in range(0, len(edges), 2)]
                    longest, start = max(stretches)
                    if longest <= 55.0:
                        break
                    at = start + longest * 0.5
                    gaps.append([round(at - 1.5, 1), round(at + 1.5, 1), "stile" if kind == "wall" and rng.random() < 0.5 else "gap"])
            gaps.sort()
            self.boundaries.append({"kind": kind, "by_road": by_road, "length": round(length, 1),
                                    "points": [[round(float(p[0]), 2), round(float(p[1]), 2)] for p in line], "gaps": gaps})
        # Each yard's wall opens at its gate.
        for steading in self.steadings:
            gate = np.array(steading["gate"])
            best = None
            for boundary in self.boundaries:
                points = np.array(boundary["points"])
                s, d = self.project(points, gate)
                if d < 4.0 and (best is None or d < best[0]):
                    best = (d, boundary, s)
            if best is not None:
                best[1]["gaps"].append([round(best[2] - 2.0, 1), round(best[2] + 2.0, 1), "gate"])
                best[1]["gaps"].sort()

    @staticmethod
    def point_along(line: np.ndarray, s: float) -> np.ndarray:
        seg = np.hypot(*(line[1:] - line[:-1]).T)
        along = np.concatenate([[0.0], np.cumsum(seg)])
        return np.array([np.interp(s, along, line[:, 0]), np.interp(s, along, line[:, 1])])

    @staticmethod
    def normal_along(line: np.ndarray, s: float) -> np.ndarray:
        a = Settlement.point_along(line, max(0.0, s - 2.0))
        b = Settlement.point_along(line, s + 2.0)
        t = unit(b - a)
        return np.array([-t[1], t[0]])

    @staticmethod
    def project(line: np.ndarray, at: np.ndarray) -> tuple[float, float]:
        """Arc length of the closest point on the line, and its distance."""
        best_s, best_d, run = 0.0, 1e9, 0.0
        for a, b in zip(line[:-1], line[1:]):
            seg = b - a
            length = float(np.hypot(*seg))
            if length < 1e-9:
                continue
            t = float(np.clip(((at - a) @ seg) / (length * length), 0.0, 1.0))
            d = float(np.hypot(*(a + seg * t - at)))
            if d < best_d:
                best_d, best_s = d, run + t * length
            run += length
        return best_s, best_d

    @staticmethod
    def trace(skeleton: np.ndarray) -> list[np.ndarray]:
        """A one-cell-wide skeleton as polylines (x, z) between its junctions and ends."""
        cells = {(int(z), int(x)) for z, x in np.argwhere(skeleton)}
        steps = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]

        def around(cell):
            return [(cell[0] + dz, cell[1] + dx) for dz, dx in steps if (cell[0] + dz, cell[1] + dx) in cells]

        degree = {cell: len(around(cell)) for cell in cells}
        nodes = {cell for cell, n in degree.items() if n != 2}
        seen: set[tuple] = set()
        lines: list[np.ndarray] = []
        for node in nodes:
            for nxt in around(node):
                if (node, nxt) in seen:
                    continue
                path = [node, nxt]
                seen.add((node, nxt))
                prev, cur = node, nxt
                while cur not in nodes:
                    options = [c for c in around(cur) if c != prev]
                    if not options:
                        break
                    # Prefer going straight on (a diagonal skeleton can show two ways).
                    options.sort(key=lambda c: abs(c[0] - cur[0]) + abs(c[1] - cur[1]))
                    prev, cur = cur, options[0]
                    path.append(cur)
                seen.add((cur, prev))
                lines.append(np.array([[c[1], c[0]] for c in path]))
        visited = {tuple(p[::-1]) for line in lines for p in line.tolist()}
        for cell in cells:
            if cell in visited or cell in nodes:
                continue
            path = [cell]
            visited.add(cell)
            prev, cur = None, cell
            while True:
                options = [c for c in around(cur) if c != prev and c not in visited]
                if not options:
                    break
                prev, cur = cur, options[0]
                visited.add(cur)
                path.append(cur)
            if len(path) > 8:
                lines.append(np.array([[c[1], c[0]] for c in path]))
        return lines

    # --- 6. Trees ------------------------------------------------------------------------------------
    def tree_ok(self, x: float, z: float, gap: float, wild: bool = False) -> bool:
        L = self.land
        if not (4 <= x < W - 4 and 4 <= z < D - 4):
            return False
        if not L.at(L.land, x, z) or L.height(x, z) < 1.2 or L.at(self.building_mask, x, z):
            return False
        if L.at(self.soft, x, z) or L.at(self.road_core, x, z) or L.at(self.track_core, x, z) or L.at(L.mask["river"], x, z):
            return False
        if not wild and L.at(L.mask["moss_oaks"], x, z):
            return False
        if L.at(L.slope, x, z) > 0.62:
            return False
        key = (int(x // 16), int(z // 16))
        for gx in (key[0] - 1, key[0], key[0] + 1):
            for gz in (key[1] - 1, key[1], key[1] + 1):
                for ox, oz in self.tree_grid.get((gx, gz), []):
                    if (ox - x) ** 2 + (oz - z) ** 2 < gap * gap:
                        return False
        return True

    def add_tree(self, x: float, z: float, species: str, scale: float, gap: float = 5.0, wild: bool = False) -> bool:
        if not self.tree_ok(x, z, gap, wild):
            return False
        self.trees.append([round(float(x), 2), round(float(z), 2), species, round(float(scale), 2)])
        self.tree_grid.setdefault((int(x // 16), int(z // 16)), []).append((x, z))
        return True

    # Each holding keeps a few kinds of tree, not one of everything: its hedgerow standards, its shelterbelt and its
    # fruit are its own, so the island's variety is from one valley to the next (and a landblock draws few kinds).
    HEDGE_TREES = [["oak", "ash", "hawthorn"], ["elm", "hawthorn", "oak"], ["beech", "oak", "holly"], ["ash", "hawthorn", "elm"], ["oak", "hawthorn", "beech"]]
    WALL_TREES = [["hawthorn", "rowan"], ["rowan", "ash"], ["hawthorn", "ash"], ["hawthorn", "birch"]]
    BELTS = [["beech", "oak"], ["elm", "chestnut"], ["oak", "ash"], ["beech", "elm"], ["chestnut", "oak"]]
    STONE_BELTS = [["pine", "ash"], ["rowan", "pine"], ["beech", "pine"], ["ash", "rowan"]]
    FRUIT = ["plum", "pear", "apple", "plum", "pear"]

    def plant(self) -> None:
        L = self.land
        rng = self.rng
        # The generator's trees keep their ground.
        for tree in L.features.get("orchard_trees", []):
            self.tree_grid.setdefault((int(tree[0] // 16), int(tree[1] // 16)), []).append((tree[0], tree[1]))
        # Steadings: an orchard close, a shelterbelt across the weather (it comes from the south-west), a tree by the gate.
        wind = unit(np.array([-0.75, 0.66]))  # where the weather comes from
        for number, steading in enumerate(self.steadings):
            at = np.array(steading["at"])
            flitted = steading["kind"] == "flitted"
            if "orchard" in steading:
                corners = np.array(steading["orchard"])
                a, b, d = corners[0], corners[1], corners[3]
                across, deep = np.hypot(*(b - a)), np.hypot(*(d - a))
                kinds = [self.FRUIT[number % len(self.FRUIT)]] if not flitted else ["apple"]
                for i in range(int(across // 6.0)):
                    for j in range(int(deep // 6.0)):
                        if flitted and rng.random() < 0.5:
                            continue
                        spot = a + (b - a) * ((i + 0.5) * 6.0 / across) + (d - a) * ((j + 0.5) * 6.0 / deep) + rng.normal(0.0, 0.5, 2)
                        self.add_tree(spot[0], spot[1], kinds[(i + j * 2 + int(at[0])) % len(kinds)], rng.uniform(0.82, 1.08), 4.4)
            belt = {"farm": 13, "hillfarm": 8, "croft": 7, "forester": 5, "mill": 4, "fisher": 2, "flitted": 5}[steading["kind"]]
            stone = steading["style"] == "wall"
            mix = self.STONE_BELTS[number % len(self.STONE_BELTS)] if stone else self.BELTS[number % len(self.BELTS)]
            for n in range(belt):
                for attempt in range(8):
                    spread = rng.uniform(-1.25, 1.25)
                    c, s = math.cos(spread), math.sin(spread)
                    way = np.array([wind[0] * c - wind[1] * s, wind[0] * s + wind[1] * c])
                    spot = at + way * rng.uniform(26.0, 40.0)
                    species = mix[int(rng.integers(0, len(mix)))]
                    if self.add_tree(spot[0], spot[1], species, rng.uniform(0.85, 1.25), 6.5):
                        break
            gate = np.array(steading["gate"]) + np.array([-steading["facing"][1], steading["facing"][0]]) * 5.5
            self.add_tree(gate[0], gate[1], mix[0] if mix[0] != "pine" else mix[1], 1.2, 6.0)
        # Village trees: one great tree by each green, fruit in the tofts.
        for village in VILLAGES:
            green = to_gen(*village["green"])
            for attempt in range(40):
                angle = rng.uniform(0.0, math.tau)
                spot = green + np.array([math.cos(angle), math.sin(angle)]) * rng.uniform(village["green_reach"] + 4.0, village["green_reach"] + 14.0)
                if self.add_tree(spot[0], spot[1], "chestnut", 1.55, 12.0):
                    break
        for plot in self.plots:
            garden = np.array(plot["garden"])
            centre = garden.mean(axis=0)
            for n in range(2):
                spot = centre + rng.normal(0.0, 3.0, 2)
                self.add_tree(spot[0], spot[1], "plum" if plot["village"] == "bramblebridge" else "pear", rng.uniform(0.75, 0.95), 4.5)
        # Hedgerow standards and the thorn by the wall.
        for boundary in self.boundaries:
            line = np.array(boundary["points"])
            length = boundary["length"]
            kind = boundary["kind"]
            if kind in ("hurdle", "baulk"):
                continue
            if kind == "tree_line":
                species = str(rng.choice(["poplar", "poplar", "ash"]))
                for s in np.arange(4.0, length - 3.0, 8.5):
                    spot = self.point_along(line, float(s))
                    self.add_tree(spot[0], spot[1], species, rng.uniform(0.9, 1.1), 5.0)
                continue
            mean_gap = 34.0 if kind == "hedge" else 95.0
            mid = self.point_along(line, length * 0.5)
            holding = max(int(L.at(self.owner, *(mid + [3.0, 0.0]))), int(L.at(self.owner, *(mid - [3.0, 0.0]))), int(L.at(self.owner, *(mid + [0.0, 3.0]))),
                          int(L.at(self.owner, *(mid - [0.0, 3.0]))))
            kinds = self.HEDGE_TREES[holding % len(self.HEDGE_TREES)] if kind == "hedge" else self.WALL_TREES[holding % len(self.WALL_TREES)]
            s = float(rng.uniform(6.0, mean_gap))
            while s < length - 4.0:
                if not any(g[0] - 3.0 < s < g[1] + 3.0 for g in boundary["gaps"]):
                    spot = self.point_along(line, s)
                    self.add_tree(spot[0], spot[1], str(rng.choice(kinds)), rng.uniform(0.8, 1.2), 7.0)
                s += float(rng.uniform(0.45, 1.7)) * mean_gap
        # Along the water: alders and pollard willows on the Bramble, alders and birch on the Dover.
        for name, points in L.rivers.items():
            line = resample(points, 4.0)
            for i in range(2, len(line) - 2):
                if rng.random() > 0.3:
                    continue
                t = unit(line[i + 1] - line[i - 1])
                n = np.array([-t[1], t[0]]) * (1.0 if rng.random() < 0.5 else -1.0)
                spot = line[i] + n * rng.uniform(5.5, 10.0)
                if L.at(L.mask["moss_oaks"], *spot) or L.above_river[int(spot[1]), int(spot[0])] > 3.5 or L.height(*spot) < 1.5:
                    continue
                low = L.height(*spot) < 9.0
                species = rng.choice(["pollard", "alder", "pollard"]) if name == "bramble" and low else rng.choice(["alder", "birch", "alder"])
                self.add_tree(spot[0], spot[1], str(species), rng.uniform(0.85, 1.15), 7.5)
        # A line of poplars where a road runs straight beside open fields (the valley's line-trees).
        self.plant_line("strait", 0.34, 0.47, "poplar", 9.0, 5.6)
        self.plant_line("coast", 0.86, 0.95, "poplar", 9.0, 5.6)
        # The Sunken Holloway runs under its own trees: oak, ash, hazel and holly on the lips of its banks.
        hollow = resample(L.roads["hollow"], 1.0)
        for i in range(int(len(hollow) * 0.18), int(len(hollow) * 0.86), 10):
            t = unit(hollow[min(len(hollow) - 1, i + 2)] - hollow[max(0, i - 2)])
            n = np.array([-t[1], t[0]])
            for side in (1.0, -1.0):
                if rng.random() < 0.55:
                    spot = hollow[i] + n * side * rng.uniform(7.5, 11.0) + t * rng.uniform(-2.0, 2.0)
                    self.add_tree(spot[0], spot[1], str(rng.choice(["oak", "ash", "holly", "oak"])), rng.uniform(0.85, 1.2), 5.5)
        # The dark wood: pines on steep ground that faces away from the sun, thinning uphill into birch and rowan.
        down_x, down_z = -L.bx, -L.bz
        steep = np.hypot(down_x, down_z)
        shade = (down_x * -0.5 + down_z * -0.87) / (steep + 1e-6)  # +1: the slope falls to the north-north-west
        fir = smooth_noise(rng, 70)
        pine_ground = L.land & (L.slope > 0.14) & (L.slope < 0.55) & (shade > 0.15) & (L.h > 12.0) & ~L.mask["moss_oaks"] & (self.label == 0) \
            & (L.coast > 14.0) & (fir > 0.3)
        pine_ground = ndi.binary_opening(pine_ground, iterations=3)
        cells = np.argwhere(pine_ground)
        rng.shuffle(cells)
        planted = 0
        for z, x in cells[:40000]:
            if planted >= 560:
                break
            deep = fir[z, x] > 0.55
            species = "pine" if (deep or rng.random() < 0.75) else ("birch" if rng.random() < 0.6 else "rowan")
            if self.add_tree(x + 0.5, z + 0.5, species, rng.uniform(0.8, 1.3), 5.4 if deep else 7.5):
                planted += 1
        # Birch, rowan and thorn on the rough upland between the fields and the crags.
        fringe = L.land & (L.h > 22.0) & (L.slope > 0.1) & (L.slope < 0.45) & (self.label == 0) & ~L.mask["moss_oaks"] & ~pine_ground & (L.coast > 12.0)
        cells = np.argwhere(fringe)
        rng.shuffle(cells)
        planted = 0
        for z, x in cells[:5000]:
            if planted >= 190:
                break
            species = str(rng.choice(["birch", "rowan", "birch"]))
            if self.add_tree(x + 0.5, z + 0.5, species, rng.uniform(0.75, 1.15), 15.0):
                planted += 1
        # Spinneys in the waste corners the fields left, and round-topped clumps on the knolls.
        waste = (self.use == LANDUSE["common"]) & (L.slope < 0.36)
        parts, count = ndi.label(ndi.binary_opening(waste, iterations=2))
        sizes = ndi.sum(waste, parts, index=np.arange(1, count + 1))
        spots = []
        for part, size in enumerate(sizes, start=1):
            if 250 <= size <= 5200:
                zc, xc = ndi.center_of_mass(parts == part)
                spots.append((size, xc, zc))
        spots.sort(reverse=True)
        for n, (size, xc, zc) in enumerate(spots[:26]):
            kinds = [["oak", "hawthorn"], ["beech", "holly"], ["elm", "ash"], ["oak", "birch"]][n % 4]
            wanted = int(np.clip(size / 120.0, 3, 11))
            for tries in range(wanted * 6):
                if wanted <= 0:
                    break
                spot = np.array([xc, zc]) + rng.normal(0.0, math.sqrt(size) * 0.28, 2)
                if 0 <= int(spot[1]) < D and 0 <= int(spot[0]) < W and parts[int(spot[1]), int(spot[0])] > 0:
                    if self.add_tree(spot[0], spot[1], str(rng.choice(kinds)), rng.uniform(0.8, 1.25), 5.5):
                        wanted -= 1
        knolls = (L.tpi > 3.2) & L.land & (L.slope < 0.2) & ~L.mask["moss_oaks"] & (L.h > 20.0) & (L.coast > 30.0) & (self.label == 0)
        parts, count = ndi.label(knolls)
        sizes = ndi.sum(knolls, parts, index=np.arange(1, count + 1))
        best = sorted([(size, part) for part, size in enumerate(sizes, start=1) if size > 300], reverse=True)[:7]
        for size, part in best:
            zc, xc = ndi.center_of_mass(parts == part)
            for n in range(7):
                angle = rng.uniform(0.0, math.tau)
                spot = np.array([xc, zc]) + np.array([math.cos(angle), math.sin(angle)]) * rng.uniform(0.0, 9.0)
                self.add_tree(spot[0], spot[1], "beech" if n < 5 else "pine", rng.uniform(1.0, 1.3), 5.0)
        # A lone tree out in a pasture (stock stand under it at noon).
        for entry in self.fields:
            if entry["use"] in ("pasture", "water_meadow") and entry["area"] > 2600 and rng.random() < 0.55:
                spot = np.array(entry["centroid"]) + rng.normal(0.0, 6.0, 2)
                self.add_tree(spot[0], spot[1], "oak" if entry["id"] % 3 else "chestnut", rng.uniform(1.15, 1.45), 12.0)
        # Yews by the old stones on the First-Quiet crags.
        for x, z in L.features.get("first_quiet_sleepers", [])[:4]:
            angle = rng.uniform(0.0, math.tau)
            self.trees.append([round(x + math.cos(angle) * 17.0, 2), round(z + math.sin(angle) * 17.0, 2), "yew", round(float(rng.uniform(0.9, 1.2)), 2)])
        # The Moss-Oaks are an oakwood, not a plantation: its smallest trees are birch, rowan and holly.
        # Only along its edge, where the light gets in, and only its smaller trees: the wood's heart stays oak.
        oaks = L.features.get("moss_oaks_trees", [])
        radii = np.array([t[2] for t in oaks])
        middling = float(np.median(radii))
        for index, tree in enumerate(oaks):
            x, z = tree[0], tree[1]
            if float(L.at(self.wood_depth, x, z)) > 16.0 or tree[2] > middling:
                continue
            pick = (index * 2654435761) % 100
            if pick < 46:
                self.wood_mix.append([index, "birch" if pick < 24 else ("rowan" if pick < 36 else "holly")])

    def plant_line(self, road: str, start: float, end: float, species: str, step: float, off: float) -> None:
        points = self.land.roads[road]
        line = resample(points, 1.0)
        a, b = int(start * len(line)), int(end * len(line))
        for i in range(a, b, int(step)):
            if 1 <= i < len(line) - 1:
                t = unit(line[i + 1] - line[i - 1])
                n = np.array([-t[1], t[0]])
                for side in (1.0, -1.0):
                    spot = line[i] + n * side * off
                    self.add_tree(spot[0], spot[1], species, float(self.rng.uniform(0.9, 1.1)), 5.0)

    # --- 7. The small things: what the fields and the stock leave about --------------------------------
    def furnish(self) -> None:
        L = self.land
        rng = self.rng
        objects = ndi.find_objects(self.label)
        inner_dist = ndi.distance_transform_edt(self.label > 0)
        edge_dist = np.zeros((D, W), np.float32)
        for entry in self.fields:
            field = entry["id"]
            box = objects[field - 1]
            grow = (slice(max(0, box[0].start - 2), min(D, box[0].stop + 2)), slice(max(0, box[1].start - 2), min(W, box[1].stop + 2)))
            area = self.label[grow] == field
            edge_dist[grow] = np.maximum(edge_dist[grow], ndi.distance_transform_edt(area) * area)
        self.edge_dist = edge_dist

        def spot_ok(x: float, z: float, field: int, margin: float) -> bool:
            if not (2 <= x < W - 2 and 2 <= z < D - 2):
                return False
            return int(L.at(self.label, x, z)) == field and float(L.at(edge_dist, x, z)) > margin and not L.at(self.soft, x, z) \
                and not L.at(self.building_mask, x, z)

        def rows(entry: dict, across: float, along: float, margin: float, keep: float) -> list[np.ndarray]:
            field = entry["id"]
            box = objects[field - 1]
            row = np.array(entry["row"])
            side = np.array([-row[1], row[0]])
            centre = np.array(entry["centroid"])
            span = max(box[0].stop - box[0].start, box[1].stop - box[1].start) * 0.75
            found = []
            for i in np.arange(-span, span, across):
                for j in np.arange(-span, span, along):
                    spot = centre + side * i + row * (j + (across * 0.5 if int(i / across) % 2 else 0.0)) + rng.normal(0.0, 0.35, 2)
                    if spot_ok(spot[0], spot[1], field, margin) and rng.random() < keep:
                        found.append(spot)
            return found

        for entry in self.fields:
            use = entry["use"]
            field = entry["id"]
            row = entry["row"]
            if use == "hay" and rng.random() < 0.6:
                entry["mown"] = True
                for spot in rows(entry, 9.0, 8.0, 3.5, 0.82):
                    self.props.append({"kind": "haycock", "at": [round(float(spot[0]), 2), round(float(spot[1]), 2)], "facing": row})
            elif use == "stubble":
                for spot in rows(entry, 8.0, 6.5, 3.0, 0.86):
                    self.props.append({"kind": "stook", "at": [round(float(spot[0]), 2), round(float(spot[1]), 2)], "facing": row})
            elif use == "roots":
                for spot in rows(entry, 2.4, 3.1, 2.4, 0.9):
                    self.props.append({"kind": "crop_row", "at": [round(float(spot[0]), 2), round(float(spot[1]), 2)], "facing": row})
            elif use == "garden":
                bean = True
                for spot in rows(entry, 1.5, 3.0, 1.2, 0.92):
                    self.props.append({"kind": "bean_row" if bean and rng.random() < 0.22 else "crop_row",
                                       "at": [round(float(spot[0]), 2), round(float(spot[1]), 2)], "facing": row})
            elif use == "fallow":
                for n in range(int(entry["area"] / 260.0)):
                    box = objects[field - 1]
                    spot = np.array([rng.uniform(box[1].start, box[1].stop), rng.uniform(box[0].start, box[0].stop)])
                    if spot_ok(spot[0], spot[1], field, 1.0):
                        self.props.append({"kind": "bramble", "at": [round(float(spot[0]), 2), round(float(spot[1]), 2)], "facing": row})
            if use in ("barley", "roots") and entry["area"] > 1500 and rng.random() < 0.5:
                spot = np.array(entry["centroid"]) + rng.normal(0.0, 4.0, 2)
                if spot_ok(spot[0], spot[1], field, 3.0):
                    self.props.append({"kind": "scarecrow", "at": [round(float(spot[0]), 2), round(float(spot[1]), 2)], "facing": row})
            if use in ("pasture", "water_meadow") and entry["area"] > 1400:
                owner = next((p for p in self.settle_points if p["id"] == entry["steading"]), None)
                hill = owner is not None and (owner["kind"] in ("hillfarm", "fisher") or owner["style"] == "wall")
                if rng.random() < 0.5:
                    kind = "sheep" if (hill or rng.random() < 0.45) and use == "pasture" else "cattle"
                    count = int(np.clip(entry["area"] / (330.0 if kind == "sheep" else 620.0), 3, 11 if kind == "sheep" else 6))
                    reach = float(np.clip(math.sqrt(entry["area"]) * 0.36, 10.0, 30.0))
                    centre = np.array(entry["centroid"])
                    if spot_ok(centre[0], centre[1], field, 4.0):
                        self.flocks.append({"kind": kind, "count": count, "at": [round(float(centre[0]), 2), round(float(centre[1]), 2)],
                                            "reach": round(reach, 1), "field": field})
                        box = objects[field - 1]
                        for attempt in range(30):
                            spot = np.array([rng.uniform(box[1].start, box[1].stop), rng.uniform(box[0].start, box[0].stop)])
                            if int(L.at(self.label, *spot)) == field and 1.6 < float(L.at(edge_dist, *spot)) < 4.0 and not L.at(self.soft, *spot):
                                self.props.append({"kind": "trough", "at": [round(float(spot[0]), 2), round(float(spot[1]), 2)], "facing": row})
                                break
        # Yard fowl at every lived-in steading, geese at the farms.
        for steading in self.steadings:
            if steading["kind"] == "flitted":
                continue
            at = np.array(steading["at"])
            self.flocks.append({"kind": "hens", "count": 7 if steading["kind"] == "farm" else 4, "at": [round(float(at[0]), 2), round(float(at[1]), 2)],
                                "reach": 8.0, "field": 0})
            if steading["kind"] in ("farm", "hillfarm"):
                front = np.array(steading["facing"])
                goose = at + front * 16.0
                self.flocks.append({"kind": "geese", "count": 5, "at": [round(float(goose[0]), 2), round(float(goose[1]), 2)], "reach": 7.0, "field": 0})
        for village in VILLAGES:
            green = to_gen(*village["green"])
            off = green + np.array([14.0, -9.0])
            self.flocks.append({"kind": "geese", "count": 4, "at": [round(float(off[0]), 2), round(float(off[1]), 2)], "reach": 6.0, "field": 0})
            self.flocks.append({"kind": "hens", "count": 5, "at": [round(float(green[0] - 16.0), 2), round(float(green[1] - 12.0), 2)], "reach": 7.0, "field": 0})
        # Each village's well and a bench or two, on free ground by its green.
        self.village_props: list[dict] = []
        for village in VILLAGES:
            green = to_gen(*village["green"])
            wanted = ["well", "bench", "bench", "cart"]
            for attempt in range(400):
                if not wanted:
                    break
                angle = rng.uniform(0.0, math.tau)
                spot = green + np.array([math.cos(angle), math.sin(angle)]) * rng.uniform(village["green_reach"] + 3.0, village["green_reach"] + 16.0)
                if L.at(self.blocked, *spot) or L.at(self.building_mask, *spot) or int(L.at(self.label, *spot)) != 0 or float(L.at(L.slope, *spot)) > 0.12:
                    continue
                if any(np.hypot(*(spot - np.array(other["at"]))) < 6.0 for other in self.village_props):
                    continue
                if any(np.hypot(spot[0] - tx, spot[1] - tz) < 4.0 for tx, tz, _, _ in self.trees):
                    continue
                toward = unit(green - spot)
                self.village_props.append({"kind": wanted.pop(0), "at": [round(float(spot[0]), 2), round(float(spot[1]), 2)],
                                           "facing": [round(float(toward[0]), 4), round(float(toward[1]), 4)], "village": village["id"]})
        # Boundary stones where a track leaves a road, and a guide stone at each steading's gate.
        for track in self.tracks:
            if track["to"] == "":
                continue
            points = np.array(track["points"])
            end = points[-1]
            back = points[-3] if len(points) > 3 else points[0]
            t = unit(end - back)
            side = np.array([-t[1], t[0]])
            spot = end - t * 5.0 + side * 3.2
            if not L.at(self.soft, *spot):
                self.props.append({"kind": "way_stone", "at": [round(float(spot[0]), 2), round(float(spot[1]), 2)], "facing": [float(t[0]), float(t[1])],
                                   "name": next(s["name"] for s in self.steadings if s["id"] == track["to"])})
        # Sheepfolds and cairns on the common: old stone the hill keeps.
        common = (self.use == LANDUSE["common"]) & (L.slope < 0.2) & (L.h > 24.0) & ~self.soft
        cells = np.argwhere(common)
        rng.shuffle(cells)
        placed: list[np.ndarray] = []
        for z, x in cells[:4000]:
            spot = np.array([x + 0.5, z + 0.5])
            if len(placed) >= 5:
                break
            if all(np.hypot(*(spot - other)) > 160.0 for other in placed) and float(L.at(self.road_dist, *spot)) > 25.0:
                placed.append(spot)
                self.props.append({"kind": "fold_ruin" if len(placed) % 2 else "cairn", "at": [round(float(spot[0]), 2), round(float(spot[1]), 2)], "facing": [1.0, 0.0]})

    # --- Writing ---------------------------------------------------------------------------------------
    def write(self, out_dir: Path) -> None:
        out_dir.mkdir(parents=True, exist_ok=True)
        Image.fromarray(self.use, "L").save(out_dir / "mask_landuse.png")
        Image.fromarray(self.tilth, "L").save(out_dir / "mask_tilth.png")
        (out_dir / ".gdignore").write_text("")
        data = {
            "units": "metres; X east, Z south, Y up; origin = north-west corner of the 2048 x 1024 m grid (the generator's frame)",
            "seed": self.seed,
            "landuse": LANDUSE,
            "steadings": self.steadings,
            "village_plots": self.plots,
            "tracks": self.tracks,
            "fields": self.fields,
            "boundaries": self.boundaries,
            "trees": self.trees,
            "props": self.props,
            "flocks": self.flocks,
            "village_props": self.village_props,
            "wood_mix": self.wood_mix,
        }
        (out_dir / "settlement.json").write_text(json.dumps(data, separators=(",", ":")))
        self.preview(out_dir / "preview.png")

    def preview(self, path: Path) -> None:
        L = self.land
        colours = {
            0: (0.62, 0.7, 0.5), 1: (0.45, 0.68, 0.36), 2: (0.6, 0.76, 0.4), 3: (0.86, 0.76, 0.36), 4: (0.5, 0.36, 0.26), 5: (0.42, 0.5, 0.3),
            6: (0.8, 0.72, 0.5), 7: (0.6, 0.6, 0.46), 8: (0.5, 0.7, 0.42), 9: (0.66, 0.56, 0.44), 10: (0.4, 0.44, 0.28), 11: (0.56, 0.78, 0.44),
            12: (0.34, 0.6, 0.34), 13: (0.56, 0.66, 0.44), 14: (0.5, 0.66, 0.4),
        }
        rgb = np.zeros((D, W, 3), np.float32)
        for use, colour in colours.items():
            rgb[self.use == use] = colour
        shade = np.clip((-L.gx * -0.5 + -L.gz * -0.5 + 0.707) / np.sqrt(L.gx ** 2 + L.gz ** 2 + 1.0), 0.0, 1.0)
        rgb *= (0.6 + 0.55 * shade)[..., None]
        rgb[L.mask["moss_oaks"]] = rgb[L.mask["moss_oaks"]] * 0.55 + np.array([0.12, 0.34, 0.14]) * 0.45
        rgb[~L.land] = (0.6, 0.74, 0.84)
        rgb[L.mask["beach"]] = (0.9, 0.85, 0.66)
        rgb[L.mask["river"]] = (0.25, 0.5, 0.86)
        rgb[L.mask["road"]] = (0.5, 0.34, 0.2)
        scale = 2
        image = Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8)).resize((W * scale, D * scale), Image.NEAREST)
        pen = ImageDraw.Draw(image)

        def pts(points):
            return [(float(p[0]) * scale, float(p[1]) * scale) for p in points]

        for track in self.tracks:
            pen.line(pts(track["points"]), fill=(150, 110, 70), width=3)
        tint = {"hedge": (24, 92, 30), "wall": (96, 96, 104), "wall_tumbled": (150, 140, 150), "fence": (120, 80, 40), "hurdle": (170, 120, 60)}
        for boundary in self.boundaries:
            if boundary["kind"] not in tint:
                continue
            line = np.array(boundary["points"])
            pen.line(pts(line), fill=tint[boundary["kind"]], width=2)
            for g in boundary["gaps"]:
                a = self.point_along(line, max(0.0, g[0]))
                b = self.point_along(line, min(boundary["length"], g[1]))
                pen.line(pts([a, b]), fill=(255, 230, 120) if g[2] == "gate" else (255, 255, 255), width=3)
        tree_tint = {"oak": (30, 110, 40), "ash": (90, 150, 70), "beech": (120, 140, 40), "elm": (50, 130, 80), "chestnut": (70, 160, 50),
                     "birch": (190, 210, 150), "poplar": (150, 190, 60), "hawthorn": (235, 235, 225), "alder": (40, 90, 60), "willow": (150, 180, 90),
                     "pollard": (170, 190, 110), "pine": (14, 60, 44), "rowan": (200, 90, 60), "plum": (150, 90, 170), "pear": (200, 200, 90),
                     "apple": (220, 120, 70), "yew": (10, 40, 30), "holly": (20, 70, 30), "hazel": (120, 150, 60)}
        for x, z, species, size in self.trees:
            r = 2.2 * size * (1.5 if species in ("oak", "beech", "chestnut", "elm") else 1.0)
            pen.ellipse([x * scale - r, z * scale - r, x * scale + r, z * scale + r], fill=tree_tint.get(species, (0, 0, 0)))
        for x, z in L.features["orchard_trees"]:
            pen.ellipse([x * scale - 2, z * scale - 2, x * scale + 2, z * scale + 2], fill=(220, 120, 70))
        for steading in self.steadings:
            for b in steading["buildings"]:
                pen.polygon(pts(self.footprint(b)), fill=(150, 50, 40), outline=(0, 0, 0))
        for plot in self.plots:
            pen.polygon(pts(self.footprint(plot["building"])), fill=(190, 60, 50), outline=(0, 0, 0))
        marks = {"haycock": (240, 220, 120), "stook": (220, 190, 90), "scarecrow": (255, 0, 0), "trough": (60, 60, 200), "way_stone": (255, 255, 255),
                 "fold_ruin": (200, 200, 220), "cairn": (220, 220, 240), "bramble": (110, 60, 110)}
        for prop in self.props:
            if prop["kind"] in marks:
                x, z = prop["at"]
                pen.rectangle([x * scale - 1, z * scale - 1, x * scale + 1, z * scale + 1], fill=marks[prop["kind"]])
        for flock in self.flocks:
            x, z = flock["at"]
            tintf = {"sheep": (255, 255, 255), "cattle": (120, 60, 30), "hens": (255, 170, 60), "geese": (230, 230, 255)}[flock["kind"]]
            for n in range(flock["count"]):
                a = n * 2.4
                rr = 3 + n * 1.5
                pen.ellipse([x * scale + math.cos(a) * rr - 2, z * scale + math.sin(a) * rr - 2, x * scale + math.cos(a) * rr + 2, z * scale + math.sin(a) * rr + 2],
                            fill=tintf, outline=(0, 0, 0))
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 22)
        except OSError:
            font = ImageFont.load_default()
        for steading in self.steadings:
            x, z = steading["at"]
            pen.text((x * scale + 12, z * scale - 34), steading["name"], fill=(20, 10, 0), font=font, stroke_width=3, stroke_fill=(255, 250, 235))
        for name, x, z, r in self.clear_spots:
            pen.ellipse([(x - r) * scale, (z - r) * scale, (x + r) * scale, (z + r) * scale], outline=(200, 0, 200))
        image.save(path)

    def report(self) -> None:
        by_use: dict[str, int] = {}
        area: dict[str, int] = {}
        for entry in self.fields:
            by_use[entry["use"]] = by_use.get(entry["use"], 0) + 1
            area[entry["use"]] = area.get(entry["use"], 0) + entry["area"]
        kinds: dict[str, float] = {}
        for boundary in self.boundaries:
            kinds[boundary["kind"]] = kinds.get(boundary["kind"], 0.0) + boundary["length"]
        species: dict[str, int] = {}
        for tree in self.trees:
            species[tree[2]] = species.get(tree[2], 0) + 1
        props: dict[str, int] = {}
        for prop in self.props:
            props[prop["kind"]] = props.get(prop["kind"], 0) + 1
        flocks: dict[str, int] = {}
        for flock in self.flocks:
            flocks[flock["kind"]] = flocks.get(flock["kind"], 0) + flock["count"]
        print(f"steadings {len(self.steadings)} ({sum(len(s['buildings']) for s in self.steadings)} buildings), village plots {len(self.plots)}, tracks {len(self.tracks)}"
              f" ({sum(polyline_length(np.array(t['points'])) for t in self.tracks):.0f} m)")
        print(f"fields {len(self.fields)}: " + ", ".join(f"{k} {v} ({area[k] / 1e4:.1f} ha)" for k, v in sorted(by_use.items())))
        print("boundaries: " + ", ".join(f"{k} {v:.0f} m" for k, v in sorted(kinds.items())) + f"; gaps {sum(len(b['gaps']) for b in self.boundaries)}")
        print(f"trees {len(self.trees)}: " + ", ".join(f"{k} {v}" for k, v in sorted(species.items())) + f"; wood mix {len(self.wood_mix)}")
        print("props: " + ", ".join(f"{k} {v}" for k, v in sorted(props.items())))
        print("stock: " + ", ".join(f"{k} {v}" for k, v in sorted(flocks.items())))
        worst = 0.0
        for track in self.tracks:
            laid = self.as_laid(np.array(track["points"]))
            if len(laid) < 3:
                continue
            a, b = laid[1:-1] - laid[:-2], laid[2:] - laid[1:-1]
            long_enough = (np.hypot(a[:, 0], a[:, 1]) > 0.5) & (np.hypot(b[:, 0], b[:, 1]) > 0.5)
            turn = self.bends(laid)[long_enough]
            worst = max(worst, float(turn.max()) if len(turn) else 0.0)
        print(f"tracks: sharpest bend between 3 m steps, as the engine lays them, {worst:.1f} degrees (the roads' limit is 30)")

    def run(self) -> None:
        L = self.land
        self.wood_depth = ndi.distance_transform_edt(L.mask["moss_oaks"])
        self.place_steadings()
        self.place_plots()
        self.lay_tracks()
        self.lay_fields()
        self.use_fields()
        self.lay_boundaries()
        self.plant()
        self.furnish()


def main() -> None:
    gen_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "world/embershore/gen/engine")
    out_dir = Path(sys.argv[2] if len(sys.argv) > 2 else "world/embershore/settle")
    seed = int(sys.argv[3]) if len(sys.argv) > 3 else 7
    settlement = Settlement(gen_dir, seed)
    settlement.run()
    settlement.write(out_dir)
    settlement.report()


if __name__ == "__main__":
    main()
