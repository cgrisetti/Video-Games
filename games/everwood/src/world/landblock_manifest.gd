## The Bramble-Bridge-to-Dover-Slap Corridor (10_WORLD_ARCHITECTURE.md §2): which
## Landblock holds what, and the shape of the land between them.
##
##   Chunk (0, 1)   the Kindle-Fire, where the party wakes round a campfire
##                  on the woodland trailhead, and Honey-Wick (a
##                  stepped-gable homestead, bee-hives and pumpkin patches)
##                  along the walled lane north to Bramble-Bridge's south gate
##   Chunk (0, 0)   Bramble-Bridge: the spawn green, the canal arch, the village
##                  square (Armory & Scribe Desk, Chime-Shrine, bakery,
##                  watermill) and the Northern Forest Gate, now open
##   Chunk (0, -1)  Moss-Oak-Hollow (the Moss-Oak Great Arch, the Bramble
##                  Camp, the alcove's Wayfarer's Chest) and Rush-Light-Hollow
##                  (Wind-Lanterns, the Water-Shrine, the Rush-Light Hush-Crack)
##   Chunk (0, -2)  Dover-Slap-Bridge and the Dover-Slap Gatehouse
##   Chunk (0, -3)  the causeway and the Ring of the Cairnsman
##   the rest       the crags and oak canopy round the corridor
##
## Each zone is the classic level's own content (tools/build_levels.gd builds
## both from the same code) moved to a world origin; terrain trails join them,
## rising from the village to the gorge (3 m) and the Ring (6 m). North is -Z.
class_name LandblockManifest
extends RefCounted

enum Zone { BORDER = -1, BRAMBLEBRIDGE, MOSS_OAKS, GORGE, RING, OAKSHIRE_COMMONS }

const ZONE_NAMES: Array[String] = ["Bramble-Bridge", "Moss-Oak-Hollow", "Dover-Slap-Bridge", "The Ring of the Cairnsman",
	"Honey-Wick"]
const BORDER_NAME: String = "The Tizzi-Wed-Green crags"
const LANDBLOCK_FOLDER: String = "res://data/landblocks/"
## The corridor runs north along this line, the middle of the chunk column x = 0.
const CORRIDOR_X: float = 64.0

## Where each zone's classic origin lands in the world. Bramble-Bridge's north
## gate ends up at z = 2, just inside Chunk (0, 0), so the trail out of it
## crosses the seam into the Moss-Oaks at z = 0.
const BRAMBLEBRIDGE_ORIGIN: Vector3 = Vector3(64.0, 0.0, 32.0)
const MOSS_OAKS_ORIGIN: Vector3 = Vector3(64.0, 0.0, -100.0)
const GORGE_ORIGIN: Vector3 = Vector3(64.0, 3.0, -150.0)
const RING_ORIGIN: Vector3 = Vector3(64.0, 6.0, -240.0)
## Honey-Wick is new, not a classic level, so it's built in world coordinates.
const COMMONS_ORIGIN: Vector3 = Vector3.ZERO
const COMMONS_CHUNK: Vector2i = Vector2i(0, 1)

## Chunks whose state survives a reset of the expedition (the village and the commons).
const PERSISTENT_CHUNKS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1)]

## Ids of the stateful things WorldStateDB remembers (also used by the classic Dojo).
const CAMP_BRAMBLE: StringName = &"camp_bramble"
const CAMP_HOLLOWAY: StringName = &"camp_holloway"
const WATER_SHRINE: StringName = &"shrine_water"
const WAYFARER_CHEST: StringName = &"chest_wayfarer"
const SINAYA_GATE: StringName = &"gate_sinaya"
const CAIRNSMAN: StringName = &"boss_cairnsman"
const CAIRNSMAN_CHEST: StringName = &"chest_cairnsman"
const CAMPFIRE: StringName = &"campfire_bivouac"
## Set once anyone has crossed the canal bridge into Bramble-Bridge's square.
const TOWN_CHECKPOINT: StringName = &"checkpoint_bramblebridge"

## The Kindle-Fire's campfire, where the party wakes, round its south-west
## of the commons. The lane leaves it eastward, bends north through the
## commons and runs straight up to Bramble-Bridge's south gate (world x, z).
const CAMPFIRE_POSITION: Vector3 = Vector3(30.0, 0.0, 178.0)
const LANE: Array[Vector2] = [Vector2(36.0, 178.0), Vector2(48.0, 178.0), Vector2(56.5, 174.5), Vector2(62.0, 167.0), Vector2(64.0, 156.0),
	Vector2(64.0, 62.5)]
## The lane's dirt and cobbles reach this far either side of its middle.
const LANE_HALF_WIDTH: float = 2.4
## Over the bridge and this far north is Bramble-Bridge's square (the bridge's north foot).
const SQUARE_Z: float = 26.5
## Where the party gets back up once the square is reached: on the lane between
## the Scribe Desk and the Chime-Shrine, facing the Forest Gate.
const TOWN_SQUARE_SPAWN: Vector3 = Vector3(64.0, 0.0, 19.0)

## Respawn checkpoints in the world: just inside the Moss-Oaks' south gap, then
## as in the classic Dojo (gorge-local z 10 and ring-local z -28).
const CHECKPOINT_ONE: Vector3 = Vector3(64.0, 0.0, -16.0)
const CHECKPOINT_TWO: Vector3 = Vector3(64.0, 3.0, -140.0)
const CHECKPOINT_THREE: Vector3 = Vector3(64.0, 6.0, -268.0)
## A zone starts once anyone is north of this line (zone 3 also needs the gate open).
const ZONE_TWO_Z: float = -135.0
const ZONE_THREE_Z: float = -167.0
const ZONE_ONE_Z: float = 1.0

## Ground height along the corridor: (world z, height), north-going, eased between.
const BASE_HEIGHTS: Array[Vector2] = [Vector2(600.0, 0.0), Vector2(-86.0, 0.0), Vector2(-136.0, 3.0), Vector2(-174.0, 3.0),
	Vector2(-264.0, 6.0), Vector2(-900.0, 6.0)]
## How far the flat walkable floor reaches west and east of the corridor line:
## (world z, west, east), north-going, linear between. It always encloses each
## zone's walls; beyond it the land rises into crags.
const BAND: Array[Vector3] = [
	Vector3(600.0, 0.0, 0.0), Vector3(212.0, 0.0, 0.0), Vector3(194.0, 46.0, 34.0), Vector3(134.0, 46.0, 34.0), Vector3(112.0, 26.0, 26.0),
	Vector3(104.0, 26.0, 26.0),
	Vector3(-38.0, 26.0, 26.0), Vector3(-41.0, 37.0, 26.0), Vector3(-53.0, 37.0, 26.0), Vector3(-54.6, 26.0, 26.0),
	Vector3(-57.0, 9.0, 9.0), Vector3(-86.0, 9.0, 9.0), Vector3(-89.0, 6.0, 6.0),
	Vector3(-133.0, 6.0, 6.0), Vector3(-135.4, 18.0, 18.0), Vector3(-174.6, 18.0, 18.0), Vector3(-177.0, 5.0, 5.0),
	Vector3(-270.0, 5.0, 5.0), Vector3(-273.4, 22.0, 22.0), Vector3(-314.6, 22.0, 22.0), Vector3(-318.0, 0.0, 0.0),
	Vector3(-900.0, 0.0, 0.0),
]
## Rush-Light-Hollow's cut (world rect: the lane and both ramps, inset from
## the banks' outer edges so the cut hides under them). The ground there
## follows the holloway's own floor (down the south ramp, along the lane, up
## the north ramp) just under it, so it never pokes up through a ramp.
const HOLLOWAY_CUT: Rect2 = Rect2(57.5, -86.0, 13.0, 32.0)
## The holloway's floor along z (as build_levels.gd builds it from the zone's
## HOLLOWAY_* numbers): the south ramp's top and foot, the north ramp's foot and top.
const HOLLOWAY_RAMPS: Array[float] = [-54.0, -62.0, -78.0, -86.0]
const HOLLOWAY_LANE_Y: float = -1.8
const HOLLOWAY_CLEARANCE: float = 0.12
## Dover-Slap-Falls' chasm (world rect, inset from its rock faces) and its floor.
const CHASM_CUT: Rect2 = Rect2(47.7, -161.7, 32.6, 17.4)
const CHASM_BOTTOM: float = -20.5
## The terrain trails players walk between zones: (south z, north z, half width).
## Low dry-stone walls (with colliders) line both sides.
const TRAILS: Array[Vector3] = [Vector3(1.5, -9.5, 26.0), Vector3(-86.0, -136.0, 6.0), Vector3(-174.0, -274.0, 5.0)]
## Each zone's footprint (world rects): no clutter is strewn inside.
const FOOTPRINTS: Array[Rect2] = [Rect2(40.0, 0.5, 48.0, 63.0), Rect2(30.0, -56.0, 60.0, 47.0), Rect2(55.0, -87.0, 18.0, 33.0),
	Rect2(44.0, -176.0, 40.0, 41.0), Rect2(41.0, -316.0, 46.0, 53.0),
	# The commons: the campfire's clearing, the homestead's yard, the two pumpkin patches and the bee-hives.
	Rect2(18.0, 167.0, 26.0, 22.0), Rect2(37.0, 137.0, 22.0, 20.0), Rect2(40.0, 156.0, 17.0, 11.0), Rect2(68.0, 136.0, 15.0, 14.0),
	Rect2(75.0, 146.0, 22.0, 14.0)]


static func zone_of(chunk: Vector2i) -> Zone:
	if chunk == COMMONS_CHUNK:
		return Zone.OAKSHIRE_COMMONS
	if chunk.x == 0 and chunk.y <= 0 and chunk.y >= -3:
		return (-chunk.y) as Zone
	return Zone.BORDER


static func is_corridor(chunk: Vector2i) -> bool:
	return zone_of(chunk) != Zone.BORDER


static func zone_origin(zone: Zone) -> Vector3:
	match zone:
		Zone.BRAMBLEBRIDGE:
			return BRAMBLEBRIDGE_ORIGIN
		Zone.MOSS_OAKS:
			return MOSS_OAKS_ORIGIN
		Zone.GORGE:
			return GORGE_ORIGIN
		Zone.RING:
			return RING_ORIGIN
		Zone.OAKSHIRE_COMMONS:
			return COMMONS_ORIGIN
	return Vector3.ZERO


## What the chunk is called (the telemetry badge, the banner).
static func chunk_name(chunk: Vector2i) -> String:
	var zone: Zone = zone_of(chunk)
	return BORDER_NAME if zone == Zone.BORDER else ZONE_NAMES[zone]


## The chunk's gameplay landblock (Layer 3), generated by tools/build_levels.gd ("" for the crags).
static func landblock_path(chunk: Vector2i) -> String:
	return "%slandblock_%s.tscn" % [LANDBLOCK_FOLDER, WorldGridConfig.chunk_key(chunk)] if is_corridor(chunk) else ""


## The chunk's HLOD proxy mesh, baked from its landblock by tools/build_levels.gd.
static func hlod_path(chunk: Vector2i) -> String:
	return "%shlod_%s.res" % [LANDBLOCK_FOLDER, WorldGridConfig.chunk_key(chunk)] if is_corridor(chunk) else ""


static func is_persistent(chunk: Vector2i) -> bool:
	return PERSISTENT_CHUNKS.has(chunk)


## The corridor floor's height at world z (before the 4 cm sink under zone floors).
static func base_height(z: float) -> float:
	for index: int in BASE_HEIGHTS.size() - 1:
		var south: Vector2 = BASE_HEIGHTS[index]
		var north: Vector2 = BASE_HEIGHTS[index + 1]
		if z <= south.x and z >= north.x:
			return lerpf(south.y, north.y, smoothstep(0.0, 1.0, (south.x - z) / (south.x - north.x)))
	return BASE_HEIGHTS[BASE_HEIGHTS.size() - 1].y if z < 0.0 else BASE_HEIGHTS[0].y


## How far the flat floor reaches from the corridor line at world z, on the west (dx < 0) or east side.
static func band_half_width(z: float, west: bool) -> float:
	for index: int in BAND.size() - 1:
		var south: Vector3 = BAND[index]
		var north: Vector3 = BAND[index + 1]
		if z <= south.x and z >= north.x:
			var t: float = (south.x - z) / (south.x - north.x)
			return lerpf(south.y, north.y, t) if west else lerpf(south.z, north.z, t)
	return 0.0


## The bottom of the pit at (x, z), or INF where nothing is cut.
static func carve_bottom(x: float, z: float) -> float:
	var at: Vector2 = Vector2(x, z)
	if HOLLOWAY_CUT.has_point(at):
		return holloway_floor(z) - HOLLOWAY_CLEARANCE
	if CHASM_CUT.has_point(at):
		return CHASM_BOTTOM
	return INF


## Rush-Light-Hollow's floor height at world z (0 at both ramp tops, the lane between).
static func holloway_floor(z: float) -> float:
	if z >= HOLLOWAY_RAMPS[1]:
		return lerpf(0.0, HOLLOWAY_LANE_Y, clampf((HOLLOWAY_RAMPS[0] - z) / (HOLLOWAY_RAMPS[0] - HOLLOWAY_RAMPS[1]), 0.0, 1.0))
	if z <= HOLLOWAY_RAMPS[2]:
		return lerpf(HOLLOWAY_LANE_Y, 0.0, clampf((HOLLOWAY_RAMPS[2] - z) / (HOLLOWAY_RAMPS[2] - HOLLOWAY_RAMPS[3]), 0.0, 1.0))
	return HOLLOWAY_LANE_Y


## True inside a zone's footprint (no clutter there).
static func in_footprint(x: float, z: float) -> bool:
	for rect: Rect2 in FOOTPRINTS:
		if rect.has_point(Vector2(x, z)):
			return true
	return false


## How far (x, z) is from the middle of the commons' lane.
static func lane_gap(x: float, z: float) -> float:
	var at: Vector2 = Vector2(x, z)
	var nearest: float = INF
	for index: int in LANE.size() - 1:
		nearest = minf(nearest, at.distance_to(Geometry2D.get_closest_point_to_segment(at, LANE[index], LANE[index + 1])))
	return nearest


## The trail (south z, north z, half width) running through world z, or Vector3.ZERO.
static func trail_at(z: float) -> Vector3:
	for trail: Vector3 in TRAILS:
		if z <= trail.x and z >= trail.y:
			return trail
	return Vector3.ZERO


## The Layer 3 ids the world binds to WorldStateDB, and the chunk the classic
## Dojo files each under (its zones match the corridor's chunks).
static func dojo_chunk(entity_id: StringName) -> Vector2i:
	match entity_id:
		SINAYA_GATE:
			return Vector2i(0, -2)
		CAIRNSMAN:
			return Vector2i(0, -3)
	return Vector2i(0, -1)
