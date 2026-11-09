## The valley's homes and what stands about them (docs/32_EMBERSHORE_THE_WORKED_LAND.md §7):
## built low out of what the island gives. Fieldstone gathered off the fields,
## lime wash over it, oak weathered to silver, thatch cut from the barley's straw
## or slate off the south cliffs, steep roofs to shed the rain, a stone chimney
## with a hearth under it. These sit beside docs/17's stepped-gable village
## houses (the villages keep theirs); a steading out in the fields is plainer.
##
## Every building stands with its door to +Z and its ridge along X, its floor at
## the origin, on a stone footing that reaches `footing` metres down (so a house
## on a slope is dug into the bank behind and stands on its plinth in front).
## A mesh is built once per shape and shared (WorldAssetCatalog.shared_mesh).
class_name SteadingKit
extends RefCounted

const Craft = ProceduralTextureAtelier.Set

const FIELDSTONE: Color = Color(0.6, 0.58, 0.53)
const FOOTING_STONE: Color = Color(0.52, 0.5, 0.47)
const SILVER_TIMBER: Color = Color(0.56, 0.53, 0.48)
const TARRED: Color = Color(0.2, 0.18, 0.17)
const THATCH_NEW: Color = Color(0.62, 0.54, 0.37)
const THATCH_OLD: Color = Color(0.47, 0.42, 0.33)
const SLATE: Color = Color(0.3, 0.33, 0.37)
const CLAY_TILE: Color = Color(0.6, 0.37, 0.28)
const TURF_ROOF: Color = Color(0.36, 0.5, 0.26)
const STRAW: Color = Color(0.72, 0.62, 0.39)
## Doors and shutters in the market's four heritage dyes (docs/18 §4.3) and plain oak.
const DOOR_DYES: Array[Color] = [Color("#46789C"), Color("#5C8558"), Color("#B85A40"), Color("#D99B38"), Color(0.42, 0.29, 0.18)]
const PLINTH: float = 0.45
## Thatch pitches steeper than slate, and a turf or a byre roof lies lower.
const PITCH_THATCH: float = 50.0
const PITCH_SLATE: float = 44.0
const PITCH_LOW: float = 34.0
## Past this a building shows as its far stand-in (one draw).
const NEAR_RANGE: float = 190.0

## What each look is made of: walls ("lime", "stone", "board", "tarred"), roof ("thatch", "slate", "tile", "turf").
const LOOKS: Dictionary[String, Array] = {
	"thatch_lime": ["lime", "thatch"], "slate_stone": ["stone", "slate"], "slate_lime": ["lime", "slate"],
	"cot_thatch": ["lime", "thatch"], "cot_slate": ["stone", "slate"],
	"barn_board": ["board", "thatch"], "barn_stone": ["stone", "slate"],
	"byre_board": ["board", "thatch"], "byre_stone": ["stone", "slate"],
	"granary": ["board", "tile"], "net_shed": ["tarred", "turf"],
	"ruin_house": ["stone", "none"], "ruin_byre": ["stone", "none"],
}


# --- What a building is --------------------------------------------------------------------------------------

static func wall_height(kind: String) -> float:
	match kind:
		"farmhouse":
			return 3.3
		"barn":
			return 3.7
		"byre", "net_shed":
			return 2.3
		"granary":
			return 3.2
		"ruin":
			return 2.4
	return 2.55


static func pitch_of(kind: String, look: String) -> float:
	var roof: String = String((LOOKS.get(look, ["stone", "slate"]) as Array)[1])
	if kind == "byre" or roof == "turf":
		return PITCH_LOW
	return PITCH_THATCH if roof == "thatch" else PITCH_SLATE


## The ridge's height over the floor.
static func ridge_height(kind: String, look: String, size: Vector2) -> float:
	if kind == "ruin":
		return wall_height(kind) + 1.4
	if kind == "granary":
		return wall_height(kind) + 2.1
	return wall_height(kind) + size.y * 0.5 * tan(deg_to_rad(pitch_of(kind, look)))


## Where the hearth's smoke leaves (in the building's frame), or nothing for a building without a fire.
static func chimneys(kind: String, look: String, size: Vector2) -> Array[Vector3]:
	var tops: Array[Vector3] = []
	if kind != "cottage" and kind != "farmhouse":
		return tops
	var top: float = ridge_height(kind, look, size) + 1.25
	tops.append(Vector3(-(size.x * 0.5 - 0.62), top, 0.0))
	if kind == "farmhouse":
		tops.append(Vector3(size.x * 0.5 - 0.62, top, 0.0))
	return tops


static func mesh(kind: String, look: String, size: Vector2, footing: float, seed_value: int) -> ArrayMesh:
	var variant: int = seed_value % 5
	var key: String = "steading:%s:%s:%.1fx%.1f:%.1f:%d" % [kind, look, size.x, size.y, footing, variant]
	return WorldAssetCatalog.shared_mesh(key, func(parts: WorldAssetCatalog.Parts) -> void: _build(parts, kind, look, size, footing, variant))


static func _build(parts: WorldAssetCatalog.Parts, kind: String, look: String, size: Vector2, footing: float, variant: int) -> void:
	match kind:
		"cottage", "farmhouse":
			_dwelling(parts, kind, look, size, footing, variant)
		"barn":
			_barn(parts, look, size, footing, variant)
		"byre":
			_byre(parts, look, size, footing)
		"granary":
			_granary(parts, size)
		"net_shed":
			_net_shed(parts, size, footing)
		"ruin":
			_ruin(parts, look, size, footing, variant)


## The same building in a handful of plain shapes, for far off (vertex colours, one draw).
static func far_mesh(kind: String, look: String, size: Vector2, footing: float) -> ArrayMesh:
	var into: LandblockTerrain.MeshMerge = CalderaKit.merge()
	var made: Array = LOOKS.get(look, ["stone", "slate"])
	var wall: Color = {"lime": WorldVisualCatalog.LIME_WASH.darkened(0.06), "stone": FIELDSTONE, "board": SILVER_TIMBER, "tarred": TARRED}.get(String(made[0]), FIELDSTONE)
	var roof: Color = {"thatch": THATCH_OLD.lerp(THATCH_NEW, 0.4), "slate": SLATE, "tile": CLAY_TILE, "turf": TURF_ROOF, "none": FIELDSTONE}.get(String(made[1]), SLATE)
	var tall: float = wall_height(kind)
	if kind == "granary":
		CalderaKit.add_box(into, Vector3(0.0, 0.7 + (tall - 0.7) * 0.5, 0.0), Vector3(size.x, tall - 0.7, size.y), wall)
		into.add_cylinder(Vector3(0.0, tall + 1.05, 0.0), 0.0, size.x * 0.78, 2.1, roof, 4)
		return into.commit()
	if kind == "ruin":
		CalderaKit.add_box(into, Vector3(0.0, (tall * 0.6 - footing) * 0.5, -size.y * 0.5 + 0.25), Vector3(size.x, tall * 0.6 + footing, 0.5), wall)
		CalderaKit.add_box(into, Vector3(-size.x * 0.5 + 0.25, (tall + 1.2 - footing) * 0.5, 0.0), Vector3(0.5, tall + 1.2 + footing, size.y), wall)
		return into.commit()
	CalderaKit.add_box(into, Vector3(0.0, (tall - footing) * 0.5, 0.0), Vector3(size.x, tall + footing, size.y), wall)
	var pitch: float = deg_to_rad(pitch_of(kind, look))
	var rise: float = size.y * 0.5 * tan(pitch)
	var prism: PrismMesh = PrismMesh.new()
	prism.size = Vector3(size.y + 0.8, rise + 0.3, size.x + 0.6)
	into.add_arrays(prism.get_mesh_arrays(), Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.0, tall + (rise + 0.3) * 0.5 - 0.15, 0.0)), roof)
	for top: Vector3 in chimneys(kind, look, size):
		CalderaKit.add_box(into, Vector3(top.x, top.y - 1.4, top.z), Vector3(0.9, 2.8, 0.8), FIELDSTONE.darkened(0.08))
	return into.commit()


# --- Materials ---------------------------------------------------------------------------------------------

static func _wall(what: String, high: bool) -> Material:
	match what:
		"lime":
			return WorldVisualCatalog.craft(Craft.LIME_PLASTER, WorldVisualCatalog.LIME_WASH.lerp(FIELDSTONE, 0.12), high)
		"board":
			return WorldVisualCatalog.craft(Craft.HEWN_TIMBER, SILVER_TIMBER, high)
		"tarred":
			return WorldVisualCatalog.craft(Craft.HEWN_TIMBER, TARRED, high)
	return WorldVisualCatalog.craft(Craft.CRAG_GRANITE, FIELDSTONE.lightened(0.06), high, 0.2)


static func _roof(what: String, old: bool) -> Material:
	match what:
		"thatch":
			return WorldVisualCatalog.craft(Craft.HEWN_TIMBER, THATCH_OLD if old else THATCH_NEW.lerp(THATCH_OLD, 0.35), true, 0.22 if old else 0.06)
		"tile":
			return WorldVisualCatalog.craft(Craft.SCALLOP_SHINGLE, CLAY_TILE, true, 0.32)
		"turf":
			return WorldVisualCatalog.craft(Craft.MEADOW_TURF, TURF_ROOF, true)
	return WorldVisualCatalog.craft(Craft.SCALLOP_SHINGLE, SLATE, true, 0.2)


static func _stone() -> Material:
	return WorldVisualCatalog.craft(Craft.CRAG_GRANITE, FIELDSTONE.lightened(0.06), false, 0.22)


static func _stone_high() -> Material:
	return WorldVisualCatalog.craft(Craft.CRAG_GRANITE, FIELDSTONE, true, 0.2)


static func _footing() -> Material:
	return WorldVisualCatalog.craft(Craft.CRAG_GRANITE, FOOTING_STONE, false, 0.5)


static func _timber(tint: Color = WorldVisualCatalog.TIMBER, high: bool = false) -> Material:
	return WorldVisualCatalog.craft(Craft.HEWN_TIMBER, tint, high)


static func _dark() -> Material:
	return WorldVisualCatalog.painted(Color(0.07, 0.06, 0.06))


# --- Shared pieces -------------------------------------------------------------------------------------------

## The walls: a stone footing down to the ground, the wall in two lifts (the upper one fades out of a
## sightline), and the gable filled under the roof (a prism the whole length of the building).
static func _shell(parts: WorldAssetCatalog.Parts, w: float, d: float, tall: float, rise: float, what: String, footing: float) -> void:
	parts.box(Vector3(w + 0.3, footing + PLINTH, d + 0.3), Vector3(0.0, (PLINTH - footing) * 0.5, 0.0), _footing())
	var split: float = minf(2.25, tall)
	parts.box(Vector3(w, split - PLINTH, d), Vector3(0.0, (split + PLINTH) * 0.5, 0.0), _wall(what, false))
	if tall > split:
		parts.box(Vector3(w, tall - split, d), Vector3(0.0, (tall + split) * 0.5, 0.0), _wall(what, true))
	if rise > 0.0:
		parts.prism(Vector3(d, rise, w), Vector3(0.0, tall + rise * 0.5, 0.0), _wall(what, true), Vector3(0.0, PI * 0.5, 0.0))
	WorldAssetCatalog._skirt(parts, Vector2(w + 0.2, d + 0.2), Vector3(0.0, 0.0, 0.0))


## A pitched roof over a `w` by `d` shell: two slopes with eaves and verges, a ridge, and for thatch
## its thick, rounded edges and block-cut ridge.
static func _pitched_roof(parts: WorldAssetCatalog.Parts, w: float, d: float, tall: float, pitch_deg: float, what: String, old: bool) -> void:
	var pitch: float = deg_to_rad(pitch_deg)
	var thatch: bool = what == "thatch" or what == "turf"
	var eave: float = 0.5 if thatch else 0.32
	var verge: float = 0.42 if thatch else 0.22
	var thick: float = 0.34 if thatch else 0.13
	var rise: float = d * 0.5 * tan(pitch)
	var run: float = d * 0.5 + eave
	var slope: float = run / cos(pitch)
	var material: Material = _roof(what, old)
	for z_side: float in [-1.0, 1.0]:
		var middle: Vector3 = Vector3(0.0, tall + rise - run * 0.5 * tan(pitch), z_side * run * 0.5)
		var normal: Vector3 = Vector3(0.0, cos(pitch), z_side * sin(pitch))
		parts.box(Vector3(w + verge * 2.0, thick, slope + 0.1), middle + normal * thick * 0.5, material, Vector3(z_side * pitch, 0.0, 0.0))
		if thatch:
			# The eave's rounded edge, and the ridge's block-cut course lying over the top of the slope.
			var edge: Vector3 = Vector3(0.0, tall + rise - run * tan(pitch), z_side * run)
			parts.cylinder(thick * 0.52, thick * 0.52, w + verge * 2.0, edge + normal * thick * 0.5, material, 8, Vector3(0.0, 0.0, PI * 0.5))
			var cap: Vector3 = Vector3(0.0, tall + rise - 0.3 * tan(pitch), z_side * 0.3)
			parts.box(Vector3(w + verge * 2.0 + 0.06, 0.09, 0.62 / cos(pitch)), cap + normal * (thick + 0.045), _roof(what, false), Vector3(z_side * pitch, 0.0, 0.0))
	if thatch:
		parts.cylinder(0.2, 0.2, w + verge * 2.0 + 0.08, Vector3(0.0, tall + rise + thick * 0.82, 0.0), _roof(what, false), 8, Vector3(0.0, 0.0, PI * 0.5))
	else:
		parts.box(Vector3(w + verge * 2.0, 0.12, 0.3), Vector3(0.0, tall + rise + thick * 0.9, 0.0), WorldVisualCatalog.craft(Craft.COBBLED_FLAGSTONE, FIELDSTONE.darkened(0.1), true))
		# Stone copings up the gables, slate tucked under them.
		for x_side: float in [-1.0, 1.0]:
			for z_side: float in [-1.0, 1.0]:
				var middle: Vector3 = Vector3(x_side * (w * 0.5 + verge - 0.08), tall + rise - (d * 0.5) * 0.5 * tan(pitch), z_side * d * 0.25)
				var normal: Vector3 = Vector3(0.0, cos(pitch), z_side * sin(pitch))
				parts.box(Vector3(0.24, 0.12, d * 0.5 / cos(pitch) + 0.3), middle + normal * (thick + 0.05), _stone_high(), Vector3(z_side * pitch, 0.0, 0.0))


## A stone chimney on the gable wall, through the roof to over the ridge, with its slab and clay pot.
static func _chimney(parts: WorldAssetCatalog.Parts, x: float, tall: float, ridge: float) -> void:
	var top: float = ridge + 0.95
	parts.box(Vector3(0.92, top - tall, 0.82), Vector3(x, (top + tall) * 0.5, 0.0), _stone_high())
	parts.box(Vector3(1.08, 0.1, 0.98), Vector3(x, top + 0.05, 0.0), _stone_high())
	parts.cylinder(0.13, 0.17, 0.36, Vector3(x, top + 0.28, 0.0), WorldVisualCatalog.craft(Craft.STEPPED_BRICK, WorldVisualCatalog.BRICK, true), 8)


## A deep-set window on a wall facing `out` (a unit vector along X or Z): glowing panes, an oak cross,
## a stone lintel and sill, and two shutters in the house's dye folded back against the wall.
static func _window(parts: WorldAssetCatalog.Parts, at: Vector3, out: Vector3, wide: float, tall: float, dye: Color, shutters: bool) -> void:
	var side: Vector3 = Vector3(out.z, 0.0, -out.x)
	var yaw: float = atan2(out.x, out.z)
	var turn: Vector3 = Vector3(0.0, yaw, 0.0)
	parts.box(Vector3(wide, tall, 0.06), at - out * 0.04, WorldVisualCatalog.glowing(WorldAssetCatalog.WINDOW_GLOW, 0.85), turn)
	var oak: Material = _timber(Color(0.36, 0.26, 0.17))
	parts.box(Vector3(0.06, tall, 0.07), at, oak, turn)
	parts.box(Vector3(wide, 0.06, 0.07), at, oak, turn)
	parts.box(Vector3(wide + 0.3, 0.18, 0.2), at + Vector3(0.0, tall * 0.5 + 0.1, 0.0) + out * 0.02, _stone(), turn)
	parts.box(Vector3(wide + 0.22, 0.1, 0.26), at + Vector3(0.0, -tall * 0.5 - 0.05, 0.0) + out * 0.06, _stone(), turn)
	if shutters:
		var paint: Material = WorldVisualCatalog.painted(dye)
		for hand: float in [-1.0, 1.0]:
			parts.box(Vector3(wide * 0.5, tall, 0.05), at + side * hand * (wide * 0.75 + 0.03) + out * 0.03, paint, turn)


## A plank door in the wall facing +Z at `x`: its stone step and lintel, the door in the house's dye, an iron latch.
static func _door(parts: WorldAssetCatalog.Parts, x: float, d: float, dye: Color, wide: float = 1.0, tall: float = 1.9) -> void:
	var z: float = d * 0.5
	parts.box(Vector3(wide, tall, 0.1), Vector3(x, PLINTH * 0.3 + tall * 0.5, z + 0.01), WorldVisualCatalog.painted(dye))
	for plank: int in 3:
		parts.box(Vector3(0.03, tall, 0.11), Vector3(x + (plank - 1) * wide * 0.26, PLINTH * 0.3 + tall * 0.5, z + 0.015), WorldVisualCatalog.painted(dye.darkened(0.25)))
	parts.box(Vector3(wide + 0.44, 0.24, 0.24), Vector3(x, PLINTH * 0.3 + tall + 0.12, z + 0.04), _stone())
	parts.box(Vector3(wide + 0.4, 0.16, 0.7), Vector3(x, 0.07, z + 0.34), _footing())
	parts.box(Vector3(0.06, 0.16, 0.05), Vector3(x + wide * 0.36, PLINTH * 0.3 + tall * 0.5, z + 0.08), WorldVisualCatalog.painted(Color(0.16, 0.16, 0.17)))


## A rose trained up the wall beside the door, and the lantern that is lit there at evening.
static func _door_dressing(parts: WorldAssetCatalog.Parts, x: float, d: float, tall: float, variant: int) -> void:
	var z: float = d * 0.5
	var leaf: Material = WorldVisualCatalog.foliage(Color.WHITE, 3.0, 0.04, 0.0)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7700 + variant
	var hand: float = 1.0 if variant % 2 == 0 else -1.0
	for clump: int in 6:
		var up: float = 0.3 + clump * 0.42
		var along: float = x + hand * (0.85 + 0.1 * sin(clump * 1.7)) - hand * maxf(0.0, up - 1.9) * 0.8
		var at: Vector3 = Vector3(along, minf(up, tall - 0.2), z + 0.1)
		parts.foliage_sphere(at, rng.randf_range(0.24, 0.34), Color(0.14, 0.28, 0.14), Color(0.36, 0.52, 0.24), leaf, Vector3(1.0, 1.0, 0.5))
		var bloom: Color = [Color(0.95, 0.56, 0.66), Color(0.98, 0.95, 0.88), Color(0.86, 0.3, 0.34)][variant % 3]
		parts.add_arrays(WorkedLandKit._dot_arrays(), Transform3D(Basis.from_scale(Vector3.ONE * 0.075), at + Vector3(rng.randf_range(-0.15, 0.15), rng.randf_range(-0.1, 0.15), 0.2)),
			leaf, bloom)
	# The lantern on its bracket.
	var iron: Material = WorldVisualCatalog.painted(Color(0.16, 0.16, 0.17))
	parts.box(Vector3(0.05, 0.05, 0.4), Vector3(x - hand * 0.82, 2.2, z + 0.2), iron)
	parts.box(Vector3(0.18, 0.24, 0.18), Vector3(x - hand * 0.82, 2.02, z + 0.36), WorldVisualCatalog.glowing(WorldVisualCatalog.WARM_HEARTH, 1.3))
	parts.box(Vector3(0.22, 0.04, 0.22), Vector3(x - hand * 0.82, 2.16, z + 0.36), iron)


# --- Dwellings ----------------------------------------------------------------------------------------------

## A valley cottage or a farmhouse: one long room and a loft under a steep roof, the chimney on the
## gable (two on a farmhouse), small shuttered windows, the door a little off the middle. A farmhouse
## adds a slated porch and an outshut under a catslide at the back.
static func _dwelling(parts: WorldAssetCatalog.Parts, kind: String, look: String, size: Vector2, footing: float, variant: int) -> void:
	var made: Array = LOOKS.get(look, ["stone", "slate"])
	var what: String = String(made[0])
	var roof: String = String(made[1])
	var w: float = size.x
	var d: float = size.y
	var tall: float = wall_height(kind)
	var pitch: float = pitch_of(kind, look)
	var rise: float = d * 0.5 * tan(deg_to_rad(pitch))
	var dye: Color = DOOR_DYES[variant % DOOR_DYES.size()]
	_shell(parts, w, d, tall, rise, what, footing)
	_pitched_roof(parts, w, d, tall, pitch, roof, variant % 2 == 0)
	for top: Vector3 in chimneys(kind, look, size):
		_chimney(parts, top.x, tall - 0.4, ridge_height(kind, look, size))
	var door_x: float = -w * 0.12 if variant % 2 == 0 else w * 0.1
	_door(parts, door_x, d, dye)
	_door_dressing(parts, door_x, d, tall, variant)
	var front: float = d * 0.5 + 0.02
	var sill: float = 1.42
	for x: float in [door_x - w * 0.27, door_x + w * 0.3]:
		if absf(x) < w * 0.5 - 0.8:
			_window(parts, Vector3(x, sill, front), Vector3.BACK, 0.72, 0.82, dye, true)
	_window(parts, Vector3(w * 0.2, sill, -front), Vector3.FORWARD, 0.66, 0.74, dye, false)
	# The loft's window in the gable away from the chimney (a farmhouse has its chimneys inside both).
	_window(parts, Vector3(w * 0.5 + 0.02, tall + rise * 0.36, 0.0), Vector3.RIGHT, 0.56, 0.6, dye, false)
	if kind == "farmhouse":
		for x: float in [-w * 0.3, w * 0.34]:
			_window(parts, Vector3(x, tall - 0.42, front), Vector3.BACK, 0.6, 0.56, dye, false)
		# The porch: two oak posts under a little slated gable.
		var oak: Material = _timber()
		for hand: float in [-1.0, 1.0]:
			parts.box(Vector3(0.14, 2.2, 0.14), Vector3(door_x + hand * 0.82, 1.1, front + 1.0), oak)
		parts.prism(Vector3(2.1, 0.7, 1.3), Vector3(door_x, 2.55, front + 0.55), _roof("slate" if roof != "thatch" else "thatch", false), Vector3.ZERO)
		parts.box(Vector3(1.9, 0.12, 0.12), Vector3(door_x, 2.2, front + 1.0), oak)
		# The outshut: the back roof runs on down over the dairy.
		var out: float = 2.2
		var low: float = 1.75
		parts.box(Vector3(w * 0.56 + 0.3, footing + PLINTH, out + 0.2), Vector3(-w * 0.16, (PLINTH - footing) * 0.5, -(d * 0.5 + out * 0.5)), _footing())
		parts.box(Vector3(w * 0.56, low - PLINTH, out), Vector3(-w * 0.16, (low + PLINTH) * 0.5, -(d * 0.5 + out * 0.5)), _wall(what, false))
		var catslide: float = atan2(tall - low + 0.25, out + 0.3)
		parts.box(Vector3(w * 0.56 + 0.5, 0.14 if roof != "thatch" else 0.3, (out + 0.5) / cos(catslide)),
			Vector3(-w * 0.16, (tall + low) * 0.5 + 0.24, -(d * 0.5 + out * 0.5 + 0.05)), _roof(roof, variant % 2 == 0), Vector3(-catslide, 0.0, 0.0))
	# A water butt under the eave.
	var cooper: Material = _timber(Color(0.5, 0.38, 0.26))
	parts.cylinder(0.3, 0.33, 0.9, Vector3(-w * 0.5 + 0.5, 0.45, front + 0.42), cooper, 10)
	parts.cylinder(0.335, 0.335, 0.05, Vector3(-w * 0.5 + 0.5, 0.7, front + 0.42), WorldVisualCatalog.painted(Color(0.2, 0.2, 0.21)), 10)


# --- Farm buildings ---------------------------------------------------------------------------------------------

## The barn: a tall, plain shed on a stone footing, boarded and battened in oak gone silver (or all
## of stone), its great doors in the long side with one leaf standing open, a loft door and hoist
## in the gable, an owl hole over it.
static func _barn(parts: WorldAssetCatalog.Parts, look: String, size: Vector2, footing: float, variant: int) -> void:
	var made: Array = LOOKS.get(look, ["board", "thatch"])
	var what: String = String(made[0])
	var roof: String = String(made[1])
	var w: float = size.x
	var d: float = size.y
	var tall: float = wall_height("barn")
	var pitch: float = pitch_of("barn", look)
	var rise: float = d * 0.5 * tan(deg_to_rad(pitch))
	_shell(parts, w, d, tall, rise, what, footing)
	# A waist-high stone footing shows under a boarded barn.
	if what == "board":
		parts.box(Vector3(w + 0.16, 1.0, d + 0.16), Vector3(0.0, 0.5, 0.0), _stone())
		var batten: Material = _timber(SILVER_TIMBER.darkened(0.16))
		var count: int = int(w / 0.62)
		for index: int in count + 1:
			var x: float = lerpf(-w * 0.5 + 0.05, w * 0.5 - 0.05, float(index) / float(count))
			for z_side: float in [-1.0, 1.0]:
				parts.box(Vector3(0.07, tall - 1.0, 0.04), Vector3(x, 1.0 + (tall - 1.0) * 0.5, z_side * (d * 0.5 + 0.02)), batten)
	_pitched_roof(parts, w, d, tall, pitch, roof, variant % 2 == 1)
	# The great doors: a dark threshing floor behind them, one leaf shut and one swung out.
	var front: float = d * 0.5
	var door_w: float = 3.3
	var door_h: float = 3.1
	var oak: Material = _timber(Color(0.44, 0.34, 0.24))
	parts.box(Vector3(door_w, door_h, 0.1), Vector3(0.0, door_h * 0.5 + 0.06, front + 0.03), _dark())
	parts.box(Vector3(door_w + 0.5, 0.3, 0.3), Vector3(0.0, door_h + 0.2, front + 0.08), oak)
	for hand: float in [-1.0, 1.0]:
		parts.box(Vector3(0.26, door_h + 0.1, 0.26), Vector3(hand * (door_w * 0.5 + 0.13), door_h * 0.5 + 0.05, front + 0.08), oak)
	var leaf: Vector3 = Vector3(door_w * 0.5, door_h - 0.1, 0.09)
	parts.box(leaf, Vector3(-door_w * 0.25, door_h * 0.5 + 0.06, front + 0.1), _timber(SILVER_TIMBER.darkened(0.08)))
	var swing: float = deg_to_rad(68.0)
	var hinge: Vector3 = Vector3(door_w * 0.5, door_h * 0.5 + 0.06, front + 0.1)
	parts.box(leaf, hinge + Vector3(-cos(swing), 0.0, sin(swing)) * leaf.x * 0.5, _timber(SILVER_TIMBER.darkened(0.08)), Vector3(0.0, swing, 0.0))
	for hand: float in [-1.0, 1.0]:
		parts.beam(Vector3(-door_w * 0.25 + hand * leaf.x * 0.45, 0.3, front + 0.16), Vector3(-door_w * 0.25 - hand * leaf.x * 0.45, door_h - 0.3, front + 0.16), 0.08, oak)
	# Straw spilling over the sill.
	var straw: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, STRAW, false, 0.0, true)
	parts.sphere(0.8, Vector3(0.7, 0.05, front + 0.5), straw, Vector3(1.5, 0.3, 1.0), 8)
	# The gable's loft door, hoist beam and owl hole.
	var end: float = w * 0.5 + 0.02
	parts.box(Vector3(0.08, 1.3, 1.0), Vector3(end, tall + 0.2, 0.0), _timber(SILVER_TIMBER.darkened(0.2), true))
	parts.box(Vector3(1.3, 0.16, 0.16), Vector3(end + 0.5, tall + 1.1, 0.0), _timber(Color(0.36, 0.27, 0.19), true))
	parts.cylinder(0.14, 0.14, 0.06, Vector3(end + 0.02, tall + rise * 0.66, 0.0), _dark(), 8, Vector3(0.0, 0.0, PI * 0.5))
	# Slit vents down the back of a stone barn.
	if what == "stone":
		for index: int in 4:
			parts.box(Vector3(0.14, 0.9, 0.06), Vector3(lerpf(-w * 0.36, w * 0.36, float(index) / 3.0), 2.2, -(d * 0.5 + 0.01)), _dark())


## The byre: a low shed open to the yard, its roof on oak posts along the front, a manger along the
## back wall and straw underfoot.
static func _byre(parts: WorldAssetCatalog.Parts, look: String, size: Vector2, footing: float) -> void:
	var made: Array = LOOKS.get(look, ["board", "thatch"])
	var what: String = String(made[0])
	var roof: String = String(made[1])
	var w: float = size.x
	var d: float = size.y
	var tall: float = wall_height("byre")
	var pitch: float = PITCH_LOW
	var rise: float = d * 0.5 * tan(deg_to_rad(pitch))
	parts.box(Vector3(w + 0.3, footing + PLINTH, d + 0.3), Vector3(0.0, (PLINTH - footing) * 0.5, 0.0), _footing())
	parts.box(Vector3(w, tall - PLINTH, 0.4), Vector3(0.0, (tall + PLINTH) * 0.5, -d * 0.5 + 0.2), _wall(what, false))
	for hand: float in [-1.0, 1.0]:
		parts.box(Vector3(0.4, tall - PLINTH, d), Vector3(hand * (w * 0.5 - 0.2), (tall + PLINTH) * 0.5, 0.0), _wall(what, false))
		parts.prism(Vector3(d, rise, 0.4), Vector3(hand * (w * 0.5 - 0.2), tall + rise * 0.5, 0.0), _wall(what, true), Vector3(0.0, PI * 0.5, 0.0))
	var oak: Material = _timber(SILVER_TIMBER.darkened(0.1))
	var bays: int = maxi(2, int(w / 2.6))
	for index: int in bays + 1:
		var x: float = lerpf(-w * 0.5 + 0.3, w * 0.5 - 0.3, float(index) / float(bays))
		parts.box(Vector3(0.2, tall - PLINTH, 0.2), Vector3(x, (tall + PLINTH) * 0.5, d * 0.5 - 0.2), oak)
	parts.box(Vector3(w, 0.2, 0.22), Vector3(0.0, tall - 0.1, d * 0.5 - 0.2), oak)
	_pitched_roof(parts, w, d, tall, pitch, roof, true)
	# Inside: the dark, the manger rail, and the straw.
	parts.box(Vector3(w - 0.8, 0.02, d - 0.6), Vector3(0.0, PLINTH + 0.01, 0.0), WorldVisualCatalog.craft(Craft.HEWN_TIMBER, STRAW.darkened(0.12), false, 0.0, true))
	parts.box(Vector3(w - 1.0, 0.12, 0.12), Vector3(0.0, 1.25, -d * 0.5 + 0.75), oak)
	parts.box(Vector3(w - 1.0, 0.5, 0.5), Vector3(0.0, 0.85, -d * 0.5 + 0.66), _timber(Color(0.4, 0.3, 0.2)))
	parts.sphere(0.7, Vector3(w * 0.28, PLINTH + 0.2, 0.0), WorldVisualCatalog.craft(Craft.HEWN_TIMBER, STRAW, false, 0.0, true), Vector3(1.3, 0.7, 1.0), 8)


## The granary: a boarded box stood up on nine staddle stones out of the rats' reach, under a
## four-sided tiled roof, steps to its door.
static func _granary(parts: WorldAssetCatalog.Parts, size: Vector2) -> void:
	var w: float = size.x
	var d: float = size.y
	var lift: float = 0.75
	var tall: float = wall_height("granary")
	var stone: Material = _stone()
	for column: int in 3:
		for row: int in 3:
			var at: Vector3 = Vector3((column - 1) * (w * 0.5 - 0.35), 0.0, (row - 1) * (d * 0.5 - 0.35))
			parts.cylinder(0.14, 0.24, lift - 0.12, at + Vector3(0.0, (lift - 0.12) * 0.5, 0.0), stone, 6)
			parts.cylinder(0.36, 0.3, 0.12, at + Vector3(0.0, lift - 0.06, 0.0), stone, 8)
	var oak: Material = _timber(Color(0.42, 0.32, 0.22))
	parts.box(Vector3(w + 0.2, 0.2, d + 0.2), Vector3(0.0, lift + 0.1, 0.0), oak)
	parts.box(Vector3(w, tall - lift - 0.2, d), Vector3(0.0, (tall + lift + 0.2) * 0.5, 0.0), _wall("board", true))
	var batten: Material = _timber(SILVER_TIMBER.darkened(0.16), true)
	for index: int in 7:
		var across: float = lerpf(-w * 0.5 + 0.06, w * 0.5 - 0.06, float(index) / 6.0)
		for side: float in [-1.0, 1.0]:
			parts.box(Vector3(0.07, tall - lift - 0.2, 0.04), Vector3(across, (tall + lift + 0.2) * 0.5, side * (d * 0.5 + 0.02)), batten)
			parts.box(Vector3(0.04, tall - lift - 0.2, 0.07), Vector3(side * (w * 0.5 + 0.02), (tall + lift + 0.2) * 0.5, across), batten)
	parts.cylinder(0.0, w * 0.82, 2.1, Vector3(0.0, tall + 1.05, 0.0), _roof("tile", true), 4, Vector3(0.0, PI * 0.25, 0.0))
	parts.sphere(0.14, Vector3(0.0, tall + 2.15, 0.0), stone, Vector3.ONE, 6)
	parts.box(Vector3(0.9, 1.5, 0.08), Vector3(0.0, lift + 0.95, d * 0.5 + 0.03), WorldVisualCatalog.painted(DOOR_DYES[1]))
	for step: int in 3:
		parts.box(Vector3(1.1, 0.07, 0.3), Vector3(0.0, 0.25 + step * 0.25, d * 0.5 + 1.0 - step * 0.3), oak)
	for hand: float in [-1.0, 1.0]:
		parts.beam(Vector3(hand * 0.55, 0.0, d * 0.5 + 1.2), Vector3(hand * 0.55, lift + 0.1, d * 0.5 + 0.2), 0.08, oak)


## A fisher's net shed: tarred boards under a turf roof, a net and its floats drying on the wall, oars leaned in the corner.
static func _net_shed(parts: WorldAssetCatalog.Parts, size: Vector2, footing: float) -> void:
	var w: float = size.x
	var d: float = size.y
	var tall: float = wall_height("net_shed")
	var rise: float = d * 0.5 * tan(deg_to_rad(PITCH_LOW))
	_shell(parts, w, d, tall, rise, "tarred", footing)
	_pitched_roof(parts, w, d, tall, PITCH_LOW, "turf", true)
	_door(parts, -w * 0.2, d, TARRED.lightened(0.12), 0.95, 1.75)
	var front: float = d * 0.5 + 0.04
	parts.box(Vector3(1.9, 1.3, 0.04), Vector3(w * 0.2, 1.3, front), WorldVisualCatalog.painted(Color(0.42, 0.46, 0.4)))
	var floats: Array[Color] = [Color("#B85A40"), Color("#46789C"), Color("#D99B38")]
	for index: int in 5:
		parts.sphere(0.1, Vector3(w * 0.2 - 0.8 + index * 0.4, 1.95, front + 0.06), WorldVisualCatalog.painted(floats[index % 3]), Vector3.ONE, 6)
	var oak: Material = _timber(SILVER_TIMBER)
	for oar: int in 2:
		parts.beam(Vector3(w * 0.5 - 0.3 - oar * 0.18, 0.0, front + 0.5), Vector3(w * 0.5 - 0.22 - oar * 0.1, 2.5, front + 0.06), 0.06, oak)
		parts.box(Vector3(0.16, 0.5, 0.03), Vector3(w * 0.5 - 0.22 - oar * 0.1, 2.6, front + 0.05), oak)


## A steading its people left (the Lens's "flit"): the roof fallen in, the walls down to their lower
## courses but for one gable, a rafter or two still leaning, ivy up the stone and a thorn in the hearth.
static func _ruin(parts: WorldAssetCatalog.Parts, look: String, size: Vector2, footing: float, variant: int) -> void:
	var w: float = size.x
	var d: float = size.y
	var tall: float = wall_height("ruin")
	var stone: Material = WorldVisualCatalog.craft(Craft.COBBLED_FLAGSTONE, FIELDSTONE.darkened(0.1), false, 0.55)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 8800 + variant
	parts.box(Vector3(w + 0.3, footing + 0.3, d + 0.3), Vector3(0.0, (0.3 - footing) * 0.5, 0.0), _footing())
	# The long walls in steps, each stretch broken off at its own height.
	var house: bool = look == "ruin_house"
	for z_side: float in [-1.0, 1.0]:
		if not house and z_side > 0.0:
			continue
		var x: float = -w * 0.5
		while x < w * 0.5 - 0.1:
			var length: float = minf(rng.randf_range(0.9, 1.7), w * 0.5 - x)
			var high: float = rng.randf_range(0.5, tall * (0.95 if z_side < 0.0 else 0.6))
			if house and z_side > 0.0 and absf(x + length * 0.5) < 0.7:
				high = 0.12
			parts.box(Vector3(length, high, 0.5), Vector3(x + length * 0.5, high * 0.5 + 0.1, z_side * (d * 0.5 - 0.25)), stone)
			x += length
	# One gable still stands to its peak, its window an empty eye; the other is a heap.
	var rise: float = 1.9 if house else 1.2
	parts.box(Vector3(0.5, tall, d), Vector3(-w * 0.5 + 0.25, tall * 0.5 + 0.1, 0.0), stone)
	parts.prism(Vector3(d, rise, 0.5), Vector3(-w * 0.5 + 0.25, tall + rise * 0.5 + 0.1, 0.0), stone, Vector3(0.0, PI * 0.5, 0.0))
	parts.box(Vector3(0.52, 0.6, 0.5), Vector3(-w * 0.5 + 0.25, tall + 0.5, 0.0), _dark())
	parts.box(Vector3(0.5, tall * 0.4, d), Vector3(w * 0.5 - 0.25, tall * 0.2 + 0.1, 0.0), stone)
	for fallen: int in 12:
		parts.box(Vector3(rng.randf_range(0.3, 0.6), rng.randf_range(0.16, 0.3), rng.randf_range(0.25, 0.45)),
			Vector3(rng.randf_range(-w * 0.6, w * 0.6), 0.1, rng.randf_range(-d * 0.7, d * 0.7)), stone,
			Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, rng.randf_range(-0.3, 0.3)))
	if house:
		var grey: Material = _timber(Color(0.42, 0.4, 0.37))
		parts.beam(Vector3(-w * 0.5 + 0.4, tall + rise - 0.1, 0.0), Vector3(-w * 0.1, 0.6, d * 0.3), 0.16, grey)
		parts.beam(Vector3(-w * 0.5 + 0.4, tall + rise * 0.6, -d * 0.2), Vector3(w * 0.1, 0.3, -d * 0.1), 0.14, grey)
	var leaf: Material = WorldVisualCatalog.foliage(Color.WHITE, 3.0, 0.05, 0.3)
	for clump: int in 7:
		parts.foliage_sphere(Vector3(-w * 0.5 + 0.1, 0.4 + clump * 0.42, rng.randf_range(-d * 0.4, d * 0.4)), rng.randf_range(0.3, 0.46),
			Color(0.1, 0.22, 0.12), Color(0.28, 0.44, 0.22), leaf, Vector3(0.5, 1.0, 1.0))
	for clump: int in 4:
		parts.foliage_sphere(Vector3(rng.randf_range(-w * 0.3, w * 0.3), 0.5, rng.randf_range(-d * 0.3, d * 0.3)), rng.randf_range(0.5, 0.8),
			Color(0.14, 0.26, 0.14), Color(0.34, 0.48, 0.24), leaf, Vector3(1.2, 0.8, 1.2))


# --- What stands about a yard ------------------------------------------------------------------------------------

## A yard piece's mesh by kind (its foot at the origin, its front to +Z), built once and shared; null for a kind there's none for.
static func prop_mesh(kind: String) -> ArrayMesh:
	if not PROPS.has(kind):
		return null
	return WorldAssetCatalog.shared_mesh("steading_prop:" + kind, func(parts: WorldAssetCatalog.Parts) -> void: _prop(parts, kind))


const PROPS: Array[String] = ["trough", "well", "well_dry", "rick", "cart", "cart_broken", "woodpile", "hives", "washing", "dog_kennel", "timber_stack",
	"saw_horse", "charcoal_clamp", "sacks", "boat", "net_rack", "fish_rack", "lobster_pots", "bench", "plough_left", "ford", "way_stone", "cairn"]


static func _prop(parts: WorldAssetCatalog.Parts, kind: String) -> void:
	var stone: Material = _stone()
	var oak: Material = _timber()
	var silver: Material = _timber(SILVER_TIMBER)
	var straw: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, STRAW, false, 0.0, true)
	var iron: Material = WorldVisualCatalog.painted(Color(0.18, 0.18, 0.19))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = kind.hash() % 100000
	match kind:
		"trough":
			WorkedLandKit._trough(parts)
		"well", "well_dry":
			var dry: bool = kind == "well_dry"
			var ring: Material = WorldVisualCatalog.craft(Craft.COBBLED_FLAGSTONE, FIELDSTONE, false, 0.6 if dry else 0.3)
			parts.cylinder(0.8, 0.86, 0.85, Vector3(0.0, 0.42, 0.0), ring, 12)
			parts.cylinder(0.6, 0.6, 0.04, Vector3(0.0, 0.86, 0.0), _dark() if dry else WorldVisualCatalog.painted(Color(0.14, 0.24, 0.3)), 12)
			parts.box(Vector3(0.14, 2.3, 0.14), Vector3(-0.92, 1.15, 0.0), oak)
			if dry:
				parts.beam(Vector3(0.9, 0.0, 0.3), Vector3(1.6, 0.5, 1.9), 0.14, _timber(Color(0.4, 0.38, 0.35)))
			else:
				parts.box(Vector3(0.14, 2.3, 0.14), Vector3(0.92, 1.15, 0.0), oak)
				parts.cylinder(0.09, 0.09, 1.9, Vector3(0.0, 1.9, 0.0), oak, 8, Vector3(0.0, 0.0, PI * 0.5))
				parts.box(Vector3(0.04, 0.26, 0.3), Vector3(1.04, 1.9, 0.14), iron)
				parts.prism(Vector3(1.5, 0.6, 2.4), Vector3(0.0, 2.6, 0.0), _roof("thatch", false), Vector3(0.0, PI * 0.5, 0.0))
				parts.box(Vector3(0.02, 0.9, 0.02), Vector3(0.1, 1.45, 0.0), WorldVisualCatalog.painted(Color(0.6, 0.52, 0.38)))
				parts.cylinder(0.17, 0.14, 0.3, Vector3(0.1, 0.98, 0.0), _timber(Color(0.5, 0.38, 0.26)), 8)
		"rick":
			# A round rick on its staddle, thatched to shed the rain, a hazel spar at its peak.
			parts.cylinder(2.3, 2.3, 0.3, Vector3(0.0, 0.15, 0.0), stone, 12)
			parts.cylinder(2.25, 2.0, 2.2, Vector3(0.0, 1.4, 0.0), straw, 12)
			parts.cylinder(0.0, 2.5, 2.3, Vector3(0.0, 3.65, 0.0), _roof("thatch", true), 12)
			parts.cylinder(0.03, 0.03, 0.5, Vector3(0.0, 5.0, 0.0), oak, 5)
			parts.sphere(0.5, Vector3(1.9, 0.2, 1.4), straw, Vector3(1.4, 0.5, 1.0), 6)
		"cart", "cart_broken":
			var broken: bool = kind == "cart_broken"
			var body: Material = WorldVisualCatalog.painted(Color("#46789C") if not broken else Color(0.4, 0.42, 0.42))
			var wheel: Material = WorldVisualCatalog.painted(Color("#B85A40") if not broken else Color(0.44, 0.38, 0.34))
			var tilt: Vector3 = Vector3(0.0, 0.0, 0.2 if broken else 0.0)
			parts.box(Vector3(2.5, 0.12, 1.3), Vector3(0.0, 0.92, 0.0), silver, tilt + Vector3(-0.05, 0.0, 0.0))
			for hand: float in [-1.0, 1.0]:
				parts.box(Vector3(2.5, 0.5, 0.06), Vector3(0.0, 1.2, hand * 0.65), body, tilt + Vector3(hand * 0.12, 0.0, 0.0))
			parts.box(Vector3(0.06, 0.5, 1.3), Vector3(-1.25, 1.2, 0.0), body, tilt)
			parts.beam(Vector3(1.2, 0.9, 0.42), Vector3(3.3, 0.16 if not broken else 0.5, 0.42), 0.08, oak)
			parts.beam(Vector3(1.2, 0.9, -0.42), Vector3(3.3, 0.16 if not broken else 0.5, -0.42), 0.08, oak)
			parts.cylinder(0.06, 0.06, 1.7, Vector3(-0.2, 0.7, 0.0), iron, 6, Vector3(PI * 0.5, 0.0, 0.0))
			for hand: float in [-1.0, 1.0]:
				if broken and hand > 0.0:
					# The off wheel lies where it came away.
					parts.torus(0.56, 0.7, Vector3(0.6, 0.1, 1.7), wheel, 14)
					continue
				parts.torus(0.56, 0.7, Vector3(-0.2, 0.7, hand * 0.82), wheel, 14, Vector3(PI * 0.5, 0.0, 0.0))
				for spoke: int in 4:
					var angle: float = PI * float(spoke) / 4.0
					parts.beam(Vector3(-0.2 - cos(angle) * 0.6, 0.7 - sin(angle) * 0.6, hand * 0.82), Vector3(-0.2 + cos(angle) * 0.6, 0.7 + sin(angle) * 0.6, hand * 0.82), 0.05, wheel)
			if not broken:
				parts.sphere(0.7, Vector3(-0.1, 1.2, 0.0), straw, Vector3(1.5, 0.6, 0.8), 8)
		"woodpile":
			var bark: Material = _timber(Color(0.36, 0.28, 0.2))
			var cut: Material = _timber(Color(0.78, 0.64, 0.44))
			for row: int in 3:
				for split: int in 5 - row:
					var at: Vector3 = Vector3((float(split) - (4 - row) * 0.5) * 0.36, 0.17 + row * 0.31, 0.0)
					parts.cylinder(0.16, 0.17, 0.9, at, bark, 5, Vector3(PI * 0.5, 0.0, 0.0))
					parts.cylinder(0.14, 0.14, 0.02, at + Vector3(0.0, 0.0, 0.455), cut, 5, Vector3(PI * 0.5, 0.0, 0.0))
			for hand: float in [-1.0, 1.0]:
				parts.box(Vector3(0.08, 1.3, 0.08), Vector3(hand * 1.0, 0.65, 0.0), oak)
			parts.box(Vector3(2.3, 0.06, 1.2), Vector3(0.0, 1.32, 0.0), silver, Vector3(0.22, 0.0, 0.0))
		"hives":
			# Three cedar hives on a slate bench (docs/17 §4: the valley keeps cedar hives).
			parts.box(Vector3(2.6, 0.1, 0.7), Vector3(0.0, 0.5, 0.0), WorldVisualCatalog.craft(Craft.COBBLED_FLAGSTONE, SLATE, false, 0.2))
			for hand: float in [-1.0, 1.0]:
				parts.box(Vector3(0.3, 0.5, 0.6), Vector3(hand * 1.0, 0.25, 0.0), stone)
			var cedar: Material = _timber(WorldAssetCatalog.CEDAR)
			var lid: Material = WorldVisualCatalog.craft(Craft.SCALLOP_SHINGLE, WorldAssetCatalog.SHINGLE_MOSS, false, 0.3)
			for hive: int in 3:
				var x: float = (hive - 1) * 0.84
				for level: int in 2 + hive % 2:
					parts.box(Vector3(0.54, 0.28, 0.48), Vector3(x, 0.69 + level * 0.29, 0.0), cedar if level % 2 == 0 else _timber(WorldAssetCatalog.CEDAR.darkened(0.18)))
				parts.prism(Vector3(0.7, 0.2, 0.62), Vector3(x, 0.65 + (2 + hive % 2) * 0.29, 0.0), lid)
		"washing":
			for hand: float in [-1.0, 1.0]:
				parts.box(Vector3(0.09, 2.2, 0.09), Vector3(hand * 2.4, 1.1, 0.0), silver)
				parts.box(Vector3(0.7, 0.07, 0.07), Vector3(hand * 2.4, 2.1, 0.0), silver)
			parts.box(Vector3(4.8, 0.02, 0.02), Vector3(0.0, 2.1, 0.0), WorldVisualCatalog.painted(Color(0.7, 0.64, 0.5)))
			var linen: Array[Color] = [WorldAssetCatalog.MARKET_LINEN, Color("#46789C"), WorldAssetCatalog.MARKET_LINEN.darkened(0.08), Color("#B85A40"), WorldAssetCatalog.MARKET_LINEN]
			var cloth: Material = WorldVisualCatalog.foliage(Color.WHITE, 2.2, 0.1, 0.0)
			var x: float = -2.0
			for piece: int in 5:
				var wide: float = [0.9, 0.5, 1.0, 0.44, 0.7][piece]
				var drop: float = [1.1, 0.7, 0.9, 0.6, 1.2][piece]
				# Hung from the line: the cloth's root is its top edge, so the wind lifts its hem.
				parts.blade(Vector3(x + wide * 0.5, 2.1, 0.0), Vector3(x + wide * 0.5, 2.1 - drop, 0.02), wide * 1.5, linen[piece], linen[piece].darkened(0.06), cloth)
				x += wide + 0.12
		"dog_kennel":
			parts.box(Vector3(0.9, 0.7, 1.1), Vector3(0.0, 0.35, 0.0), silver)
			parts.prism(Vector3(1.1, 0.45, 1.3), Vector3(0.0, 0.92, 0.0), _roof("slate", true))
			parts.box(Vector3(0.44, 0.5, 0.04), Vector3(0.0, 0.27, 0.56), _dark())
		"timber_stack":
			var bark: Material = _timber(Color(0.36, 0.28, 0.2))
			var cut: Material = _timber(Color(0.78, 0.64, 0.44))
			for row: int in 3:
				for trunk: int in 4 - row:
					var at: Vector3 = Vector3(0.0, 0.26 + row * 0.44, (float(trunk) - (3 - row) * 0.5) * 0.5)
					parts.cylinder(0.24, 0.26, 4.2, at, bark, 8, Vector3(0.0, 0.0, PI * 0.5))
					for hand: float in [-1.0, 1.0]:
						parts.cylinder(0.22, 0.22, 0.02, at + Vector3(hand * 2.11, 0.0, 0.0), cut, 8, Vector3(0.0, 0.0, PI * 0.5))
			for hand: float in [-1.0, 1.0]:
				parts.box(Vector3(0.1, 1.5, 0.1), Vector3(1.4, 0.75, hand * 1.1), oak)
		"saw_horse":
			for hand: float in [-1.0, 1.0]:
				parts.beam(Vector3(hand * 0.7, 0.0, -0.4), Vector3(hand * 0.7, 1.0, 0.3), 0.09, oak)
				parts.beam(Vector3(hand * 0.7, 0.0, 0.4), Vector3(hand * 0.7, 1.0, -0.3), 0.09, oak)
			parts.cylinder(0.16, 0.18, 2.4, Vector3(0.0, 0.84, 0.0), _timber(Color(0.36, 0.28, 0.2)), 8, Vector3(0.0, 0.0, PI * 0.5))
			parts.box(Vector3(0.03, 0.14, 1.3), Vector3(0.3, 1.0, 0.1), iron, Vector3(0.3, 0.2, 0.0))
		"charcoal_clamp":
			# A charcoal-burner's clamp: a turfed dome over the stacked cordwood, smoking at its crown.
			parts.sphere(1.9, Vector3(0.0, 0.3, 0.0), WorldVisualCatalog.craft(Craft.HOLLOW_LOAM, Color(0.3, 0.26, 0.2)), Vector3(1.0, 0.72, 1.0), 12)
			parts.sphere(1.5, Vector3(0.0, 0.62, 0.0), WorldVisualCatalog.craft(Craft.MEADOW_TURF, TURF_ROOF.darkened(0.15)), Vector3(1.0, 0.7, 1.0), 10)
			parts.cylinder(0.22, 0.3, 0.2, Vector3(0.0, 1.68, 0.0), _dark(), 8)
		"sacks":
			var hessian: Material = WorldVisualCatalog.painted(Color(0.72, 0.62, 0.46))
			for sack: int in 5:
				parts.sphere(0.3, Vector3((sack % 3) * 0.5 - 0.5, 0.28 + (sack / 3) * 0.4, (sack % 2) * 0.3), hessian, Vector3(0.9, 1.15, 0.8), 8)
		"boat":
			# A clinker boat drawn up above the tide: tarred below, a strake in the house's blue.
			# Its hull turned keel-up on chocks for the winter's tarring: the shape a boat is known by from across a cove.
			var tar: Material = WorldVisualCatalog.painted(TARRED.lightened(0.08))
			parts.sphere(1.0, Vector3(0.0, 0.5, 0.0), tar, Vector3(2.35, 0.62, 0.78), 12)
			parts.sphere(1.0, Vector3(0.0, 0.44, 0.0), WorldVisualCatalog.painted(Color("#46789C")), Vector3(2.4, 0.2, 0.82), 12)
			parts.box(Vector3(4.3, 0.1, 0.09), Vector3(0.0, 1.1, 0.0), silver)
			for chock: float in [-1.3, 1.3]:
				parts.box(Vector3(0.22, 0.3, 1.8), Vector3(chock, 0.15, 0.0), oak)
			parts.beam(Vector3(-1.9, 0.0, 1.2), Vector3(1.7, 0.06, 1.3), 0.05, silver)
			parts.box(Vector3(0.5, 0.03, 0.16), Vector3(1.9, 0.07, 1.3), silver)
		"net_rack":
			for hand: float in [-1.0, 1.0]:
				parts.beam(Vector3(hand * 1.6, 0.0, -0.5), Vector3(hand * 1.6, 2.0, 0.0), 0.08, silver)
				parts.beam(Vector3(hand * 1.6, 0.0, 0.5), Vector3(hand * 1.6, 2.0, 0.0), 0.08, silver)
			parts.cylinder(0.05, 0.05, 3.6, Vector3(0.0, 2.0, 0.0), silver, 6, Vector3(0.0, 0.0, PI * 0.5))
			var net: Material = WorldVisualCatalog.foliage(Color.WHITE, 2.0, 0.08, 0.0)
			parts.blade(Vector3(0.0, 2.0, 0.0), Vector3(0.0, 0.3, 0.5), 4.4, Color(0.4, 0.46, 0.4), Color(0.5, 0.54, 0.46), net)
			for cork: int in 6:
				parts.sphere(0.07, Vector3(-1.3 + cork * 0.52, 0.36, 0.5), WorldVisualCatalog.painted(Color(0.72, 0.56, 0.36)), Vector3.ONE, 5)
		"fish_rack":
			for hand: float in [-1.0, 1.0]:
				parts.box(Vector3(0.08, 1.7, 0.08), Vector3(hand * 1.2, 0.85, 0.0), silver)
			for rail: int in 2:
				parts.box(Vector3(2.5, 0.05, 0.05), Vector3(0.0, 1.05 + rail * 0.55, 0.0), silver)
				for fish: int in 7:
					parts.box(Vector3(0.09, 0.34, 0.03), Vector3(-1.0 + fish * 0.33, 0.86 + rail * 0.55, 0.0), WorldVisualCatalog.painted(Color(0.7, 0.72, 0.7)), Vector3(0.0, 0.0, 0.08 * (fish % 3 - 1)))
		"lobster_pots":
			var wicker: Material = _timber(Color(0.56, 0.45, 0.3))
			for pot: int in 3:
				var at: Vector3 = Vector3(pot * 0.72 - 0.7, 0.24, (pot % 2) * 0.4)
				parts.cylinder(0.3, 0.3, 0.7, at, wicker, 8, Vector3(0.0, pot * 0.5, PI * 0.5))
				parts.box(Vector3(0.74, 0.05, 0.66), at - Vector3(0.0, 0.22, 0.0), silver, Vector3(0.0, pot * 0.5, 0.0))
			parts.torus(0.16, 0.26, Vector3(0.9, 0.06, -0.5), WorldVisualCatalog.painted(Color(0.7, 0.64, 0.5)), 10)
		"bench":
			for hand: float in [-1.0, 1.0]:
				parts.box(Vector3(0.12, 0.42, 0.34), Vector3(hand * 0.6, 0.21, 0.0), stone)
			parts.box(Vector3(1.6, 0.07, 0.36), Vector3(0.0, 0.45, 0.0), silver)
		"plough_left":
			# A plough left in the furrow, its share gone to rust, bindweed up the stilts.
			var grey: Material = _timber(Color(0.44, 0.42, 0.39))
			parts.beam(Vector3(-1.2, 0.5, 0.0), Vector3(1.3, 0.4, 0.0), 0.11, grey)
			parts.beam(Vector3(-1.2, 0.5, 0.14), Vector3(-2.1, 1.1, 0.3), 0.07, grey)
			parts.beam(Vector3(-1.2, 0.5, -0.14), Vector3(-2.1, 1.1, -0.3), 0.07, grey)
			parts.box(Vector3(0.7, 0.36, 0.05), Vector3(-0.3, 0.2, 0.06), WorldVisualCatalog.painted(Color(0.46, 0.28, 0.2)), Vector3(0.0, 0.2, 0.3))
			var leaf: Material = WorldVisualCatalog.foliage(Color.WHITE, 1.2, 0.1, 0.3)
			for clump: int in 3:
				parts.foliage_sphere(Vector3(-1.6 + clump * 0.3, 0.6 + clump * 0.14, 0.2), 0.2, Color(0.16, 0.3, 0.16), Color(0.4, 0.56, 0.28), leaf)
		"ford":
			# Stepping stones across the water (they lie along +Z, the way the track runs), a kerb stone on each bank.
			var wet: Material = WorldVisualCatalog.craft(Craft.CRAG_GRANITE, FIELDSTONE.darkened(0.12), false, 0.45)
			for step: int in 9:
				var z: float = (step - 4) * 0.95
				parts.cylinder(rng.randf_range(0.32, 0.42), rng.randf_range(0.36, 0.46), 0.5, Vector3(rng.randf_range(-0.12, 0.12) + 1.4, -0.18, z), wet, 7,
					Vector3(0.0, rng.randf() * TAU, 0.0))
			for hand: float in [-1.0, 1.0]:
				parts.box(Vector3(0.5, 0.7, 0.36), Vector3(2.1, 0.2, hand * 4.6), wet, Vector3(0.0, 0.3 * hand, 0.06))
		"way_stone":
			# A finger-post where a track leaves the road: an oak post and its pointing board.
			parts.box(Vector3(0.14, 2.3, 0.14), Vector3(0.0, 1.15, 0.0), silver)
			parts.box(Vector3(0.06, 0.26, 1.2), Vector3(0.0, 2.0, 0.5), _timber(Color(0.6, 0.5, 0.36)))
			parts.prism(Vector3(0.06, 0.26, 0.2), Vector3(0.0, 2.0, 1.2), _timber(Color(0.6, 0.5, 0.36)), Vector3(PI * 0.5, 0.0, 0.0))
			parts.cylinder(0.3, 0.42, 0.3, Vector3(0.0, 0.12, 0.0), stone, 7)
		"cairn":
			var old: Material = WorldVisualCatalog.craft(Craft.CRAG_GRANITE, FIELDSTONE.darkened(0.1), false, 0.5)
			for course: int in 5:
				var reach: float = 0.95 - course * 0.17
				for rock: int in 6 - course:
					var angle: float = TAU * float(rock) / float(6 - course) + course * 0.6
					parts.sphere(rng.randf_range(0.26, 0.36), Vector3(cos(angle) * reach * 0.6, 0.16 + course * 0.3, sin(angle) * reach * 0.6), old,
						Vector3(1.2, 0.7, 1.0), 6)
			parts.sphere(0.24, Vector3(0.0, 1.66, 0.0), old, Vector3(1.0, 0.8, 1.0), 6)
