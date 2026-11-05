## Builds the instance scenes from code (Code-First Scene Safety), so nobody
## hand-edits their sub-resources. Re-run after changing anything here:
##   godot --headless --path . --script res://tools/build_levels.gd
##
## - Bramble-Bridge (hub_town.tscn, 07 GDD §1.1): a walled canal village. The
##   spawn green and its fountain in the south; the canal across the middle,
##   crossed by the low stone arch the village is named for (walkable ramps,
##   no jump needed) and turning a watermill; the village square in the north
##   with the Armory & Scribe Desk, the Chime-Shrine, a bakery and pigment
##   racks among stepped-gable houses; and the Raid Portal at the forest gate.
## - The Dover-Slap-Falls Expedition (dungeon_dojo.tscn, 07 GDD §3): Zone 1, the
##   Moss-Oak-Hollow (a walled clearing, a bramble camp, a side alcove with
##   the Wayfarer's Chest) and Rush-Light-Hollow (a lane between earthen banks
##   under root arches and Wind-Lanterns, the Water-Shrine, the imp camp);
##   Zone 2, Dover-Slap-Bridge with its waterfall and paper-mill wheel,
##   and the Dover-Slap Gatehouse with its Co-Op Threshold; Zone 3, a causeway into
##   the Ring of the Cairnsman, six pillars round the boss.
## - The seamless world (everwood_world.tscn, 10_WORLD_ARCHITECTURE.md): the
##   same village and zones as Landblocks, one scene per chunk in
##   deprecated/legacy_maps/bramble_bridge_corridor/landblocks/ (landblock_0_1 the Kindle-Fire, where the party
##   wakes by a campfire, and Honey-Wick along the walled lane north,
##   landblock_0_0 Bramble-Bridge with its Forest Gate open and a south gate,
##   landblock_0_-1 the Moss-Oaks and holloway with a gap in the clearing's
##   south wall under the Moss-Oak Great Arch, landblock_0_-2 the gorge,
##   landblock_0_-3 the Ring), each moved to its world origin
##   (LandblockManifest), plus each one's HLOD proxy (hlod_*.res: its big shapes
##   merged into one vertex-coloured mesh). The world scene itself is only the
##   skeleton and the WorldGridManager, which streams the rest.
## All share the same skeleton (Actors, Telegraphs, Effects, SpawnPoints and
## the split-screen Screens), which LevelBase expects.
##
## Phase 17 (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md): every surface is
## painted in the atelier's crafts (WorldVisualCatalog.craft_for_color), the
## buildings, bridges, trees, lanterns and stations are WorldAssetCatalog kits
## (placed as WorldKitInstance, so the scenes stay small), the water runs in
## storybook_water_stream, Chime-Posts stand at the thresholds and the camps
## carry their Hush-Cracks. Colliders and positions are unchanged.
extends SceneTree

const HUB_PATH: String = "res://deprecated/legacy_maps/hub_town/hub_town.tscn"
const DOJO_PATH: String = "res://src/levels/dungeon_dojo.tscn"
const HUB_SCRIPT: String = "res://deprecated/legacy_maps/hub_town/hub_town.gd"
const DOJO_SCRIPT: String = "res://src/levels/dungeon_dojo.gd"
const WORLD_PATH: String = "res://deprecated/legacy_maps/bramble_bridge_corridor/everwood_world.tscn"
const WORLD_SCRIPT: String = "res://deprecated/legacy_maps/bramble_bridge_corridor/everwood_world.gd"
const GRID_MANAGER_SCRIPT: String = "res://src/world/world_grid_manager.gd"
## The corridor's Landblocks, south to north.
const CORRIDOR_CHUNKS: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, -2), Vector2i(0, -3)]
## HLOD proxies keep shapes at least this big (metres along their longest side).
const HLOD_MIN_SIZE: float = 1.4
## A mesh surface with more vertices than this goes into an HLOD as its bounding box.
const HLOD_DETAILED_VERTICES: int = 400
const PORTAL_SCRIPT: String = "res://src/actors/raid_portal.gd"
const SHRINE_SCRIPT: String = "res://src/actors/chime_shrine.gd"
const WHEEL_SCRIPT: String = "res://src/actors/watermill_wheel.gd"
const DESK_SCRIPT: String = "res://src/actors/scribe_desk.gd"
const SCRIBERY_SCRIPT: String = "res://src/actors/scribery_station.gd"
const CAMP_SCRIPT: String = "res://src/actors/minion_camp.gd"
const SHRINE_WATER_SCRIPT: String = "res://src/actors/water_shrine.gd"
const LANTERN_SCRIPT: String = "res://src/actors/wind_lantern.gd"
const GATE_SCRIPT: String = "res://src/actors/coop_gate.gd"
const CAMPFIRE_SCRIPT: String = "res://src/actors/hearth_campfire.gd"
const GRID_SCRIPT: String = "res://src/ui/split_screen_viewport_grid.gd"
const GRID_SHADER: String = "res://src/levels/greybox_grid.gdshader"

const FLOOR_THICKNESS: float = 1.0
const WALL_HEIGHT: float = 1.2
## Walls this low or lower block bodies but not cameras (ActorBase.LAYER_LOW_SCENERY).
const LOW_WALL_HEIGHT: float = 1.6
const WALL_THICKNESS: float = 1.0
const SPAWN_SPACING: float = 3.0
const SPAWN_PAD_COLORS: Array[Color] = [
	Color(0.32, 0.52, 0.9), Color(0.34, 0.76, 0.46), Color(0.92, 0.5, 0.22), Color(0.7, 0.45, 0.9),
]
const STONE_COLOR: Color = Color(0.58, 0.56, 0.53)
const WALL_COLOR: Color = Color(0.48, 0.47, 0.46)

# The Dover-Slap-Falls Expedition (dungeon_dojo.tscn, 07_EXPEDITION_HUD_AND_ART_GDD.md
# §3). North is -Z: you arrive among Moss-Oak-Hollow in the south, go
# down Rush-Light-Hollow, over Dover-Slap-Bridge, through the Dover-Slap
# Gatehouse and along a causeway into the Ring of the Cairnsman in the north.
const EARTH_COLOR: Color = Color(0.42, 0.33, 0.24)
const TRAIL_COLOR: Color = Color(0.52, 0.43, 0.3)
const DRYSTONE_COLOR: Color = Color(0.56, 0.55, 0.5)
const CLIFF_COLOR: Color = Color(0.42, 0.39, 0.35)
const ROOT_COLOR: Color = Color(0.36, 0.27, 0.18)
const TIMBER_COLOR: Color = Color(0.4, 0.28, 0.17)
const MUSHROOM_COLOR: Color = Color(0.55, 0.9, 0.75)
const DRYSTONE_HEIGHT: float = 1.2
const RAIL_HEIGHT: float = 1.1
const EXIT_PORTAL_COLOR: Color = Color(0.95, 0.8, 0.4)
# Zone 1: Moss-Oak-Hollow clearing (x and z bounds).
const OAKS_MIN: Vector2 = Vector2(-24.0, 46.0)
const OAKS_MAX: Vector2 = Vector2(24.0, 90.0)
const EXPEDITION_SPAWN_Z: float = 82.0
const EXIT_PORTAL_POSITION: Vector3 = Vector3(0.0, 0.0, 87.0)
## A dirt trail winding from the spawn pads to the holloway (decoration).
const TRAIL_POINTS: Array[Vector3] = [Vector3(0.0, 0.0, 85.0), Vector3(-3.0, 0.0, 75.0), Vector3(2.5, 0.0, 64.0),
	Vector3(-1.0, 0.0, 54.0), Vector3(0.0, 0.0, 46.0)]
const OAK_SPOTS: Array[Vector3] = [Vector3(-15.0, 0.0, 84.0), Vector3(14.0, 0.0, 85.0), Vector3(-19.0, 0.0, 72.0), Vector3(-10.0, 0.0, 66.0),
	Vector3(18.0, 0.0, 74.0), Vector3(19.0, 0.0, 57.0), Vector3(-18.0, 0.0, 60.0), Vector3(-12.0, 0.0, 51.0), Vector3(13.0, 0.0, 50.0),
	Vector3(-7.0, 0.0, 78.0), Vector3(9.0, 0.0, 79.0), Vector3(16.0, 0.0, 64.0)]
const CAMP_ONE_POSITION: Vector3 = Vector3(8.0, 0.0, 64.0)
const CAMP_ONE_KINDS: Array[int] = [0, 0, 0]
## In the seamless world the trail from Bramble-Bridge comes in through a gap
## this wide in the clearing's south wall, under the Moss-Oak Great Arch.
const OAKS_SOUTH_GAP: float = 6.0
const GREAT_ARCH_Z: float = 93.0
const GREAT_ARCH_SPAN: float = 5.5
const GREAT_ARCH_HEIGHT: float = 12.0
## The deer-run alcove beyond a gap in the west wall, behind dry-stone walls.
const ALCOVE_MIN: Vector2 = Vector2(-32.0, 50.0)
const ALCOVE_MAX: Vector2 = Vector2(-24.0, 56.0)
const WAYFARER_CHEST_POSITION: Vector3 = Vector3(-29.5, 0.0, 53.0)
# Rush-Light-Hollow: a lane between earthen banks, six feet down.
const HOLLOWAY_HALF_WIDTH: float = 4.0
const HOLLOWAY_DEPTH: float = 1.8
const HOLLOWAY_TOP_Z: float = 46.0
const HOLLOWAY_FLOOR_START_Z: float = 38.0
const HOLLOWAY_FLOOR_END_Z: float = 22.0
const HOLLOWAY_EXIT_Z: float = 14.0
## Guide-posts on climbable ramps (18 GDD §3.2): no taller than 0.6 m, this far apart.
const GUIDE_POST_HEIGHT: float = 0.55
const GUIDE_POST_SPACING: float = 2.0
const BANK_WIDTH: float = 4.0
## Banks stand this far above the ground beside them.
const BANK_LIP: float = 0.8
const ROOT_ARCH_ZS: Array[float] = [41.0, 34.0, 28.5, 23.5]
## Height of the root arches' tops (above the ground, not the lane).
const ROOT_ARCH_APEX: float = 4.2
const WIND_LANTERN_SPOTS: Array[Vector3] = [Vector3(-1.7, 3.3, 41.0), Vector3(1.7, 3.3, 34.0), Vector3(-1.7, 3.3, 28.5), Vector3(1.7, 3.3, 23.5)]
const WATER_SHRINE_POSITION: Vector3 = Vector3(2.7, -1.8, 35.5)
const CAMP_TWO_POSITION: Vector3 = Vector3(-0.5, -1.8, 26.0)
const CAMP_TWO_KINDS: Array[int] = [1, 1, 0, 1]
# Zone 2: Dover-Slap-Bridge and the Dover-Slap Gatehouse.
const CLIFF_HALF_WIDTH: float = 16.0
const SOUTH_CLIFF_Z: Vector2 = Vector2(6.0, 14.0)
const NORTH_CLIFF_Z: Vector2 = Vector2(-24.0, -12.0)
const GORGE_BRIDGE_HALF_WIDTH: float = 3.0
## The bridge's side bays, where the Maker-Seal Plates sit (z range, and how far they reach out).
const BRIDGE_BAY_Z: Vector2 = Vector2(-9.0, -3.0)
const BRIDGE_BAY_DEPTH: float = 3.6
const GORGE_DEPTH: float = 24.0
const GATE_POSITION: Vector3 = Vector3(0.0, 0.0, -16.0)
const GATE_TOWER_SIZE: Vector3 = Vector3(3.6, 7.0, 4.0)
const GATE_WALL_HEIGHT: float = 4.5
const WATERFALL_POSITION: Vector3 = Vector3(12.5, -9.0, -3.0)
const WATERFALL_SIZE: Vector3 = Vector3(5.0, 26.0, 0.5)
const WATERFALL_COLOR: Color = Color(0.72, 0.9, 1.0, 0.6)
const MILLWHEEL_POSITION: Vector3 = Vector3(-10.5, -2.6, -3.0)
const MILLWHEEL_SCALE: float = 1.5
const CHECKPOINT_TWO_Z: float = 10.0
# Zone 3: the Ring of the Cairnsman.
const CAUSEWAY_Z: Vector2 = Vector2(-34.0, -24.0)
const CAUSEWAY_HALF_WIDTH: float = 3.0
const RING_SIZE: float = 40.0
const BOSS_POSITION: Vector3 = Vector3(0.0, 0.0, -54.0)
const PILLAR_COUNT: int = 6
const PILLAR_RING_RADIUS: float = 11.0
const PILLAR_RADIUS: float = 1.1
## Taller than a player (cover) but under the cameras' eye line, so they never wall off a view.
const PILLAR_HEIGHT: float = 3.2
const CHECKPOINT_THREE_Z: float = -28.0
## Checkpoint pads across a 6 m path.
const CHECKPOINT_SPACING: float = 1.5

# Bramble-Bridge (07_EXPEDITION_HUD_AND_ART_GDD.md §1.1). North is -Z: the
# spawn green in the south, the canal across the middle with the bridge over
# it, and the village square and the forest gate in the north. Nothing needs
# a jump: Space is the dodge roll.
const HUB_WIDTH: float = 44.0
const HUB_DEPTH: float = 60.0
const HUB_SPAWN_Z: float = 22.0
## In front of the forest gate, well past the square, so nobody wanders into it.
const RAID_PORTAL_POSITION: Vector3 = Vector3(0.0, 0.0, -25.0)
## In the seamless world the gate is the way on foot, so the portal steps aside.
const WORLD_RAID_PORTAL_POSITION: Vector3 = Vector3(8.5, 0.0, -24.5)
const RAID_PORTAL_COLOR: Color = Color(0.55, 0.5, 1.0)
## The forest gate: an opening in the north wall, framed in timber.
const GATE_WIDTH: float = 6.0
const GATE_HEIGHT: float = 5.0
const GATE_COLOR: Color = Color(0.42, 0.29, 0.18)
## Oaks of Moss-Oak-Hollow beyond the north wall, seen through the gate.
const GATE_TREES: Array[Vector3] = [Vector3(-2.0, 0.0, -34.0), Vector3(3.5, 0.0, -36.5), Vector3(-6.5, 0.0, -38.0), Vector3(8.0, 0.0, -33.5),
	Vector3(0.5, 0.0, -41.0), Vector3(-11.0, 0.0, -34.5)]
const HOUSE_SIZE: Vector3 = Vector3(6.0, 3.6, 5.0)
const HOUSE_SPOTS: Array[Vector3] = [Vector3(-15.0, 0.0, -21.0), Vector3(15.0, 0.0, -21.0), Vector3(-15.0, 0.0, -10.0),
	Vector3(15.0, 0.0, -10.0), Vector3(-15.5, 0.0, 19.0), Vector3(15.5, 0.0, 19.0)]
const HOUSE_COLORS: Array[Color] = [Color(0.78, 0.7, 0.58), Color(0.7, 0.74, 0.66), Color(0.74, 0.66, 0.7), Color(0.68, 0.7, 0.78),
	Color(0.8, 0.66, 0.56), Color(0.66, 0.72, 0.7)]
const ROOF_COLOR: Color = Color(0.55, 0.3, 0.26)
## Stepped gables face the lane and climb above a steep roof (Bruges, Visby).
const GABLE_STEPS: int = 4
const GABLE_STEP_HEIGHT: float = 0.5
const GABLE_THICKNESS: float = 0.3
const ROOF_HEIGHT: float = 1.9
const WINDOW_SIZE: Vector3 = Vector3(0.08, 0.75, 0.6)
const WINDOW_COLOR: Color = Color(1.0, 0.82, 0.5)
## The square's bakery (one of the houses) puffs smoke from its oven chimney.
const BAKERY_HOUSE: int = 2
const SMOKE_COLOR: Color = Color(0.85, 0.83, 0.8, 0.5)
## Drying racks of pigment bundles beside the shrine (saffron, madder, woad, weld, violet).
const PIGMENT_RACK_POSITION: Vector3 = Vector3(11.0, 0.0, -17.5)
## Bramble-Bridge's market row: three pavilions east of the lane on the spawn green (18 GDD §4.3).
const MARKET_ROW_SPOTS: Array[Vector3] = [Vector3(10.5, 0.0, 4.6), Vector3(10.5, 0.0, 8.8), Vector3(10.5, 0.0, 13.0)]
const PIGMENT_COLORS: Array[Color] = [Color(0.95, 0.68, 0.15), Color(0.72, 0.2, 0.18), Color(0.2, 0.32, 0.7), Color(0.75, 0.78, 0.25),
	Color(0.5, 0.3, 0.62)]
## The canal runs east-west across the village. Knee-high stone banks keep
## walkers out of the water everywhere but the bridge.
const CANAL_Z: float = 0.0
const CANAL_WIDTH: float = 3.6
const CANAL_BANK_HEIGHT: float = 0.55
const CANAL_BANK_THICKNESS: float = 0.4
const WATER_COLOR: Color = Color(0.25, 0.5, 0.75)
## Bramble-Bridge itself: a low stone arch over the canal. Each ramp climbs
## BRIDGE_RISE over BRIDGE_RAMP_LENGTH (about 13 degrees, under the 25-degree
## limit), and its walkway is one convex collider, so there's no lip to catch on.
const BRIDGE_WIDTH: float = 4.0
const BRIDGE_RISE: float = 0.9
const BRIDGE_RAMP_LENGTH: float = 3.8
const BRIDGE_CROWN_LENGTH: float = 2.8
const BRIDGE_PARAPET_HEIGHT: float = 0.6
const BRIDGE_PARAPET_THICKNESS: float = 0.2
const BRIDGE_COLOR: Color = Color(0.62, 0.58, 0.52)
## The watermill stands on the north bank, its wheel turning in the canal.
const MILL_POSITION: Vector3 = Vector3(16.5, 0.0, -5.0)
const MILL_SIZE: Vector3 = Vector3(3.6, 3.0, 2.8)
const MILL_COLOR: Color = Color(0.7, 0.62, 0.5)
const WHEEL_HEIGHT: float = 1.1
const FOUNTAIN_RADIUS: float = 2.2
## On the spawn green, off to the side of the lane.
const FOUNTAIN_POSITION: Vector3 = Vector3(-9.0, 0.0, 10.0)
## Lanterns line the lane from the spawn green over the bridge to the gate.
const LANTERN_SPOTS: Array[Vector3] = [
	Vector3(-3.4, 0.0, 16.0), Vector3(3.4, 0.0, 16.0), Vector3(-3.4, 0.0, 8.0), Vector3(3.4, 0.0, 8.0),
	Vector3(-3.4, 0.0, -8.0), Vector3(3.4, 0.0, -8.0), Vector3(-3.4, 0.0, -17.0), Vector3(3.4, 0.0, -17.0),
]
const LANTERN_COLOR: Color = Color(1.0, 0.8, 0.45)
## On the village square: the desk west of the lane, the shrine east of it, both facing the lane.
const DESK_POSITION: Vector3 = Vector3(-7.5, 0.0, -12.0)
const SHRINE_POSITION: Vector3 = Vector3(7.5, 0.0, -12.0)
## The Reed-Light Scribery (14 GDD §6): the square's west side, north of the desk, its counter facing the lane.
const SCRIBERY_POSITION: Vector3 = Vector3(-9.0, 0.0, -19.5)
const OAK_TRUNK_COLOR: Color = Color(0.36, 0.26, 0.18)
const OAK_LEAF_COLOR: Color = Color(0.28, 0.46, 0.25)
const MOSS_COLOR: Color = Color(0.36, 0.5, 0.26)
## Bramble-Bridge's south gate (seamless world only): the commons' lane comes in through it.
const SOUTH_GATE_WIDTH: float = 5.0


# The Kindle-Fire and Honey-Wick, Chunk (0, 1), built in world
# coordinates round LandblockManifest.CAMPFIRE_POSITION and LANE. The party
# wakes round the campfire facing the lane; knee-high dry-stone walls line
# the lane all the way to Bramble-Bridge's south gate.
## The four spawn spots round the fire, just outside its warmth (x, z from its middle).
const BIVOUAC_SPAWNS: Array[Vector2] = [Vector2(2.6, -3.4), Vector2(4.0, -1.2), Vector2(4.0, 1.2), Vector2(2.6, 3.4)]
## Everyone wakes facing up the lane, east-north-east (yaw: 0 faces north).
const BIVOUAC_FACING: float = -1.24
const LANE_WALL_HEIGHT: float = 0.6
const LANE_WALL_THICKNESS: float = 0.45
## Walls stand this far either side of the lane's middle, in pieces about this long.
const LANE_WALL_OFFSET: float = 3.0
const LANE_WALL_PIECE: float = 4.0
## Openings in the lane walls (world x, z): the homestead's path, the two pumpkin patches, the bee-hives.
const LANE_GAPS: Array[Vector2] = [Vector2(61.0, 146.0), Vector2(67.0, 143.0), Vector2(60.0, 161.0), Vector2(67.0, 156.0)]
const LANE_GAP_HALF: float = 1.8
const COBBLE_COLOR: Color = Color(0.6, 0.58, 0.54)
## The village square's flower planters (hub frame).
const PLANTER_SPOTS: Array[Vector3] = [Vector3(-4.5, 0.0, -6.0), Vector3(4.5, 0.0, -6.0), Vector3(-4.5, 0.0, -22.0), Vector3(4.5, 0.0, -22.0)]
## Chime-Posts (17 GDD §4.2): at the Forest Gate (hub frame), Rush-Light-Hollow's
## trailhead and the bramble camp's (expedition frame), and Dover-Slap-Bridge's south approach.
const GATE_POST: Vector3 = Vector3(4.6, 0.0, -27.0)
const HOLLOW_POST: Vector3 = Vector3(5.6, 0.0, 48.5)
const CAMP_POST: Vector3 = Vector3(13.0, 0.0, 69.0)
const BRIDGE_POST: Vector3 = Vector3(5.0, 0.0, 9.5)
const COMMONS_POST: Vector3 = Vector3(49.0, 0.0, 176.0)
## Roof shingles by house, round the village (clay, slate, moss).
const ROOF_TINTS: Array[Color] = [Color(0.62, 0.36, 0.27), Color(0.43, 0.49, 0.55), Color(0.62, 0.36, 0.27), Color(0.4, 0.5, 0.36),
	Color(0.62, 0.36, 0.27), Color(0.43, 0.49, 0.55)]
## The Ring of the Cairnsman's flagstones (§5.2: mid-value so every telegraph pops) and its outer standing stones.
const ARENA_FLOOR_COLOR: Color = Color("#8A8E91")
const OUTER_STONE_RADIUS: float = 17.0
const CHIME_POST_SCRIPT: String = "res://src/actors/chime_post.gd"
## A cobble every so often along the lane, scattered across its middle.
const COBBLE_STEP: float = 0.8
## The bivouac's oak, whose low limb hangs a Wind-Lantern over the lane's start.
const BIVOUAC_OAK: Vector3 = Vector3(41.0, 0.0, 170.5)
const BIVOUAC_LANTERN: Vector3 = Vector3(41.0, 3.5, 176.4)
## The stepped-gable timber homestead west of the lane, its door facing the lane:
## x is its depth (toward the lane), y its height to the eaves, z its length.
const HOMESTEAD_POSITION: Vector3 = Vector3(47.0, 0.0, 146.0)
const HOMESTEAD_SIZE: Vector3 = Vector3(7.0, 3.4, 9.0)
const HOMESTEAD_ROOF_HEIGHT: float = 2.6
const PLASTER_COLOR: Color = Color(0.9, 0.84, 0.7)
const THATCH_COLOR: Color = Color(0.58, 0.44, 0.26)
## The bee-hives: a south-facing convex arc along the east woodline (bowed
## north, each hive's entrance to the south), on stands.
const HIVE_ARC_CENTER: Vector2 = Vector2(86.0, 159.0)
const HIVE_ARC_RADIUS: float = 7.5
const HIVE_COUNT: int = 7
const CEDAR_COLOR: Color = Color(0.72, 0.44, 0.28)
const HIVE_LID_COLOR: Color = Color(0.46, 0.52, 0.46)
## The heirloom pumpkin patches (world rects): Cinderella orange, Jarrahdale
## blue-grey, Lumina white and Rouge vif d'Etampes red.
const PUMPKIN_PATCHES: Array[Rect2] = [Rect2(42.0, 158.0, 13.0, 7.0), Rect2(70.0, 138.0, 11.0, 10.0)]
## Which side of each patch is open to the lane (-1 west, 1 east).
const PUMPKIN_OPEN_SIDES: Array[float] = [1.0, -1.0]
const PUMPKIN_COLORS: Array[Color] = [Color(0.95, 0.55, 0.15), Color(0.55, 0.62, 0.62), Color(0.93, 0.9, 0.82), Color(0.82, 0.3, 0.14)]
const SOIL_COLOR: Color = Color(0.36, 0.26, 0.17)
const VINE_COLOR: Color = Color(0.3, 0.5, 0.22)


var _results: PackedStringArray = PackedStringArray()
var _baked: bool = false


func _initialize() -> void:
	# The HLOD bakes read every kit the moment its landblock is in the tree.
	WorldKitInstance.immediate = true
	_results.append("%s -> %s" % [HUB_PATH, error_string(_save(_build_hub(), HUB_PATH))])
	_results.append("%s -> %s" % [DOJO_PATH, error_string(_save(_build_dojo(), DOJO_PATH))])
	_results.append("%s -> %s" % [WORLD_PATH, error_string(_save(_build_world(), WORLD_PATH))])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LandblockManifest.LANDBLOCK_FOLDER))
	var cartography: Dictionary = {"footprints": [], "cracks": []}
	for chunk: Vector2i in CORRIDOR_CHUNKS:
		var path: String = LandblockManifest.landblock_path(chunk)
		var block: Node3D = _build_landblock(chunk)
		_record_cartography(block, cartography)
		_results.append("%s -> %s" % [path, error_string(_save(block, path))])
	var listing: String = LandblockManifest.LANDBLOCK_FOLDER + CartographyBaker.CARTOGRAPHY_FILE
	_results.append("%s -> %s" % [listing, error_string(_save_cartography(cartography, listing))])


## The HLOD proxies are baked on the first frame, once the tree is running, so
## each Landblock's scripts can build their looks first.
func _process(_delta: float) -> bool:
	if _baked:
		return false
	_baked = true
	for chunk: Vector2i in CORRIDOR_CHUNKS:
		var hlod_path: String = LandblockManifest.hlod_path(chunk)
		_results.append("%s -> %s" % [hlod_path, error_string(_bake_hlod(_build_landblock(chunk), hlod_path))])
	print("build_levels: " + ", ".join(_results))
	quit(0 if not ", ".join(_results).contains("rror") else 1)
	return false


# --- Bramble-Bridge --------------------------------------------------------

func _build_hub() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "HubTown"
	root.set_script(load(HUB_SCRIPT))
	root.add_child(_environment(true))
	root.add_child(_sun())
	_build_town(root, false)
	_add_level_skeleton(root, HUB_SPAWN_Z)
	return root


## The village, its portal, shrine, desk and Scribery, under `root` in the hub's frame.
## In the seamless world the Forest Gate is open (the way out on foot), the
## portal stands aside, and the portal, shrine and desk are Landblock entities.
func _build_town(root: Node3D, world_mode: bool) -> void:
	var town: Node3D = _node3d("Town")
	root.add_child(town)
	# Bevel-edged limestone cobbles (17 GDD §5.2).
	var cobbles: Material = WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.COBBLED_FLAGSTONE, Color(0.74, 0.7, 0.62), false, 0.15)
	town.add_child(_box_body("Floor", Vector3(HUB_WIDTH, FLOOR_THICKNESS, HUB_DEPTH), Vector3(0.0, -FLOOR_THICKNESS * 0.5, 0.0), cobbles))
	_add_hub_walls(town, world_mode)
	_add_forest_gate(town, world_mode)
	if world_mode:
		# The commons' lane, from the south gate to the chunk's edge (the rest is the commons' own).
		town.add_child(_lane_walls("LaneWalls", 0.0, WorldGridConfig.CHUNK_SIZE, LandblockManifest.BRAMBLEBRIDGE_ORIGIN))
		town.add_child(_lane_cobbles("LaneCobbles", 0.0, WorldGridConfig.CHUNK_SIZE, LandblockManifest.BRAMBLEBRIDGE_ORIGIN))
	for index: int in HOUSE_SPOTS.size():
		var variant: StringName = &"SMOKING_BAKERY" if index == BAKERY_HOUSE else (&"REED_LIGHT_SCRIBERY" if index == 0 else &"VILLAGE_COTTAGE")
		town.add_child(_house("House%d" % (index + 1), HOUSE_SPOTS[index], HOUSE_COLORS[index], variant))
	town.add_child(_fountain())
	for index: int in PLANTER_SPOTS.size():
		town.add_child(_planter("Planter%d" % (index + 1), PLANTER_SPOTS[index], index))
	town.add_child(_chime_post("GateChimePost", GATE_POST, "Moss-Oak-Hollow"))
	for index: int in LANTERN_SPOTS.size():
		town.add_child(_lantern("Lantern%d" % (index + 1), LANTERN_SPOTS[index]))
	_add_canal(town)
	_add_bridge(town)
	_add_watermill(town)
	_add_pigment_rack(town)
	_add_market_row(town)
	var portal: Node3D = _portal("RaidPortal", InstanceManager.DUNGEON_DOJO, "Raid: The Dover-Slap-Falls Expedition", RAID_PORTAL_COLOR,
		WORLD_RAID_PORTAL_POSITION if world_mode else RAID_PORTAL_POSITION)
	root.add_child(_entity(portal) if world_mode else portal)
	var shrine: Node3D = Node3D.new()
	shrine.name = "ChimeShrine"
	shrine.set_script(load(SHRINE_SCRIPT))
	shrine.position = SHRINE_POSITION
	# Its front (local -Z) turned to face west, toward the lane.
	shrine.rotation = Vector3(0.0, PI * 0.5, 0.0)
	root.add_child(_entity(shrine) if world_mode else shrine)
	var desk: Node3D = Node3D.new()
	desk.name = "ScribeDesk"
	desk.set_script(load(DESK_SCRIPT))
	desk.position = DESK_POSITION
	# Its front (local -Z) turned to face east, toward the lane.
	desk.rotation = Vector3(0.0, -PI * 0.5, 0.0)
	root.add_child(_entity(desk) if world_mode else desk)
	var scribery: Node3D = _scripted("ReedLightScribery", SCRIBERY_SCRIPT, SCRIBERY_POSITION, {})
	# Its counter (local -Z) turned to face east, toward the lane, like the desk.
	scribery.rotation = Vector3(0.0, -PI * 0.5, 0.0)
	root.add_child(_entity(scribery) if world_mode else scribery)


## The village wall, with the forest gate's opening in the north side and, in
## the seamless world, a south gate where the lane from Honey-Wick comes in.
func _add_hub_walls(parent: Node3D, world_mode: bool) -> void:
	var half_width: float = HUB_WIDTH * 0.5
	var half_depth: float = HUB_DEPTH * 0.5
	var stone: Material = _material(WALL_COLOR)
	if world_mode:
		var south_length: float = half_width - SOUTH_GATE_WIDTH * 0.5
		var timber: Material = _material(GATE_COLOR)
		for side: float in [-1.0, 1.0]:
			var label: String = "West" if side < 0.0 else "East"
			parent.add_child(_low(_box_body("WallSouth%s" % label, Vector3(south_length, WALL_HEIGHT, WALL_THICKNESS),
				Vector3(side * (SOUTH_GATE_WIDTH * 0.5 + south_length * 0.5), WALL_HEIGHT * 0.5, half_depth), stone)))
			parent.add_child(ShapeKit.box("SouthGatePost%s" % label, Vector3(0.45, 3.2, 0.45), Vector3(side * (SOUTH_GATE_WIDTH * 0.5 + 0.2), 1.6, half_depth), timber))
		parent.add_child(ShapeKit.box("SouthGateBeam", Vector3(SOUTH_GATE_WIDTH + 0.9, 0.35, 0.5), Vector3(0.0, 3.3, half_depth), timber))
	else:
		parent.add_child(_low(_box_body("WallSouth", Vector3(HUB_WIDTH, WALL_HEIGHT, WALL_THICKNESS), Vector3(0.0, WALL_HEIGHT * 0.5, half_depth), stone)))
	parent.add_child(_low(_box_body("WallWest", Vector3(WALL_THICKNESS, WALL_HEIGHT, HUB_DEPTH), Vector3(-half_width, WALL_HEIGHT * 0.5, 0.0), stone)))
	parent.add_child(_low(_box_body("WallEast", Vector3(WALL_THICKNESS, WALL_HEIGHT, HUB_DEPTH), Vector3(half_width, WALL_HEIGHT * 0.5, 0.0), stone)))
	var side_length: float = half_width - GATE_WIDTH * 0.5
	for side: float in [-1.0, 1.0]:
		parent.add_child(_low(_box_body("WallNorth%s" % ("West" if side < 0.0 else "East"), Vector3(side_length, WALL_HEIGHT, WALL_THICKNESS),
			Vector3(side * (GATE_WIDTH * 0.5 + side_length * 0.5), WALL_HEIGHT * 0.5, -half_depth), stone)))


## The timber gate out to Moss-Oak-Hollow, behind the Raid Portal: you
## see the oaks through it, but the way out is the portal. In the seamless
## world it stands open and the trail runs on into the Moss-Oaks' Landblock.
func _add_forest_gate(parent: Node3D, world_mode: bool) -> void:
	var half_depth: float = HUB_DEPTH * 0.5
	var gate: Node3D = _node3d("ForestGate")
	gate.position = Vector3(0.0, 0.0, -half_depth)
	parent.add_child(gate)
	var timber: Material = _material(GATE_COLOR)
	for side: float in [-1.0, 1.0]:
		gate.add_child(ShapeKit.box("Post", Vector3(0.6, GATE_HEIGHT, 0.6), Vector3(side * (GATE_WIDTH * 0.5 + 0.3), GATE_HEIGHT * 0.5, 0.0), timber))
		# Open gate leaves, swung outward.
		var leaf: MeshInstance3D = ShapeKit.box("Leaf", Vector3(GATE_WIDTH * 0.5 - 0.2, GATE_HEIGHT - 1.2, 0.18), Vector3(side * (GATE_WIDTH * 0.5 + 0.2), (GATE_HEIGHT - 1.2) * 0.5, -1.4), timber)
		leaf.rotation = Vector3(0.0, side * 1.25, 0.0)
		gate.add_child(leaf)
	gate.add_child(ShapeKit.box("Lintel", Vector3(GATE_WIDTH + 1.8, 0.7, 0.8), Vector3(0.0, GATE_HEIGHT, 0.0), timber))
	var roof_mesh: PrismMesh = PrismMesh.new()
	roof_mesh.size = Vector3(GATE_WIDTH + 2.4, 1.0, 1.6)
	roof_mesh.material = WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.SCALLOP_SHINGLE, WorldAssetCatalog.SHINGLE_MOSS, true, 0.3)
	var roof: MeshInstance3D = MeshInstance3D.new()
	roof.name = "Roof"
	roof.mesh = roof_mesh
	roof.position = Vector3(0.0, GATE_HEIGHT + 0.85, 0.0)
	gate.add_child(roof)
	if not world_mode:
		# Nobody walks out through the gate: the portal is the way.
		var blocker: StaticBody3D = StaticBody3D.new()
		blocker.name = "GateBlocker"
		blocker.collision_layer = ActorBase.LAYER_WORLD
		blocker.collision_mask = 0
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = Vector3(GATE_WIDTH, GATE_HEIGHT, WALL_THICKNESS)
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.name = "Collision"
		collision.shape = shape
		collision.position = Vector3(0.0, GATE_HEIGHT * 0.5, 0.0)
		blocker.add_child(collision)
		gate.add_child(blocker)
	var sign_label: Label3D = Label3D.new()
	sign_label.name = "GateSign"
	sign_label.text = "To Moss-Oak-Hollow"
	sign_label.font_size = 40
	sign_label.outline_size = 10
	sign_label.pixel_size = 0.01
	sign_label.modulate = Color(1.0, 0.92, 0.75)
	# On the roof's gable, well above the Raid Portal's title in front, so the two never overlap on screen.
	sign_label.position = Vector3(0.0, GATE_HEIGHT + 0.6, 0.85)
	gate.add_child(sign_label)
	if world_mode:
		return
	# The edge of the forest beyond the wall.
	var forest: Node3D = _node3d("ForestEdge")
	parent.add_child(forest)
	forest.add_child(ShapeKit.box("Moss", Vector3(HUB_WIDTH * 0.7, 0.1, 16.0), Vector3(0.0, -0.05, -half_depth - 8.0), _material(MOSS_COLOR)))
	for index: int in GATE_TREES.size():
		forest.add_child(_tree("Oak%d" % (index + 1), GATE_TREES[index], 7.0 + float(index % 3), false))


## A stepped-gable house (17 GDD §4.1 kit_house_stepped_gable): its body collides
## as one box; its looks are the kit, with its gable and door toward the lane
## down the village's middle (or turned `door_yaw` from the body's +X).
func _house(house_name: String, where: Vector3, color: Color, variant: StringName = &"VILLAGE_COTTAGE", door_yaw: float = NAN) -> StaticBody3D:
	var house: StaticBody3D = _collider(house_name, HOUSE_SIZE, where + Vector3(0.0, HOUSE_SIZE.y * 0.5, 0.0))
	var yaw: float = door_yaw if not is_nan(door_yaw) else (0.0 if where.x <= 0.0 else PI)
	var roof: Color = ROOF_TINTS[absi(hash(house_name)) % ROOF_TINTS.size()]
	house.add_child(WorldKitInstance.make("Kit", WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE, Vector3(0.0, -HOUSE_SIZE.y * 0.5, 0.0), yaw,
		{&"variant": variant, &"size": HOUSE_SIZE, &"tint": color, &"accent": roof}))
	return house


## A box that only collides (its looks are a kit beside it).
func _collider(body_name: String, size: Vector3, where: Vector3, layer: int = ActorBase.LAYER_WORLD) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = body_name
	body.position = where
	body.collision_layer = layer
	body.collision_mask = 0
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	body.add_child(collision)
	return body


## A Nursery-Rhyme Chime-Post (17 GDD §4.2) singing `place`'s rhyme.
func _chime_post(post_name: String, where: Vector3, place: String) -> Node3D:
	return _scripted(post_name, CHIME_POST_SCRIPT, where, {&"place": place})


## A cobblestone flower planter on the square (knee-high: cameras see past it).
func _planter(planter_name: String, where: Vector3, index: int) -> StaticBody3D:
	var planter: StaticBody3D = _low(_collider(planter_name, Vector3(1.6, 0.6, 1.6), where + Vector3(0.0, 0.3, 0.0)))
	planter.add_child(ShapeKit.box("Stone", Vector3(1.6, 0.6, 1.6), Vector3.ZERO, WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.COBBLED_FLAGSTONE,
		WorldVisualCatalog.FLAGSTONE, false, 0.3)))
	planter.add_child(ShapeKit.box("Soil", Vector3(1.3, 0.06, 1.3), Vector3(0.0, 0.3, 0.0), _material(SOIL_COLOR)))
	for bloom: int in 6:
		var angle: float = TAU * float(bloom) / 6.0 + index
		var color: Color = WorldAssetCatalog.FLOWER_BOX_COLORS[(bloom + index) % WorldAssetCatalog.FLOWER_BOX_COLORS.size()]
		planter.add_child(ShapeKit.sphere("Bloom%d" % bloom, 0.16, Vector3(cos(angle) * 0.38, 0.42, sin(angle) * 0.38), WorldVisualCatalog.painted(color)))
	return planter


## Pigment bundles drying on a timber rack: saffron, madder, woad, weld and violet.
## Bramble-Bridge's market row (18 GDD §4.3): three artisan pavilions on the
## east side of the spawn green, their counters (LowScenery colliders) facing
## west to the lane, on the square's cobbles.
func _add_market_row(parent: Node3D) -> void:
	for index: int in MARKET_ROW_SPOTS.size():
		var stall: StaticBody3D = StaticBody3D.new()
		stall.name = "MarketStall%d" % (index + 1)
		stall.collision_layer = ActorBase.LAYER_LOW_SCENERY
		stall.collision_mask = 0
		stall.position = MARKET_ROW_SPOTS[index]
		# Its front (local -Z) turned to face west, toward the lane.
		stall.rotation = Vector3(0.0, PI * 0.5, 0.0)
		var dye: Color = WorldAssetCatalog.MARKET_DYES[(index + 1) % WorldAssetCatalog.MARKET_DYES.size()]
		stall.add_child(WorldKitInstance.make("Kit", WorldVisualCatalog.KIT_MARKET_PAVILION, Vector3.ZERO, 0.0,
			{&"tint": dye, &"accent": WorldAssetCatalog.MARKET_LINEN, &"seed_value": 20 + index}))
		var shape: CollisionShape3D = CollisionShape3D.new()
		shape.name = "Collision"
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(2.6, 1.0, 0.9)
		shape.shape = box
		shape.position = Vector3(0.0, 0.5, 0.0)
		stall.add_child(shape)
		parent.add_child(stall)


func _add_pigment_rack(parent: Node3D) -> void:
	var rack: Node3D = _node3d("PigmentRack")
	rack.position = PIGMENT_RACK_POSITION
	parent.add_child(rack)
	var timber: Material = _material(GATE_COLOR)
	var span: float = 3.4
	for side: float in [-1.0, 1.0]:
		rack.add_child(ShapeKit.box("Post", Vector3(0.14, 2.4, 0.14), Vector3(side * span * 0.5, 1.2, 0.0), timber))
	rack.add_child(ShapeKit.box("Bar", Vector3(span + 0.3, 0.12, 0.12), Vector3(0.0, 2.35, 0.0), timber))
	for index: int in PIGMENT_COLORS.size():
		var x: float = lerpf(-span * 0.4, span * 0.4, float(index) / (PIGMENT_COLORS.size() - 1))
		rack.add_child(ShapeKit.box("Bundle%d" % index, Vector3(0.32, 0.8, 0.32), Vector3(x, 1.85, 0.0), WorldVisualCatalog.painted(PIGMENT_COLORS[index])))


## The canal across the village and its stone banks, open only where the bridge crosses.
func _add_canal(parent: Node3D) -> void:
	var length: float = HUB_WIDTH - WALL_THICKNESS
	# A lively, foam-streaked canal (17 GDD §3.4), flowing east under the arch.
	parent.add_child(ShapeKit.box("CanalWater", Vector3(length, 0.04, CANAL_WIDTH), Vector3(0.0, 0.03, CANAL_Z), WorldVisualCatalog.water(&"flat", Vector2(0.9, 0.0))))
	# Two wooden skiffs moored against the quay.
	for skiff: Array in [[-12.5, 0.6], [11.0, -0.7]]:
		var hull: Node3D = _node3d("Skiff")
		hull.position = Vector3(skiff[0], 0.08, CANAL_Z + float(skiff[1]))
		hull.rotation = Vector3(0.0, 0.05 * float(skiff[1]), 0.04)
		var plank: Material = WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.HEWN_TIMBER, Color(0.5, 0.34, 0.2))
		hull.add_child(ShapeKit.box("Hull", Vector3(2.6, 0.3, 0.9), Vector3(0.0, 0.15, 0.0), plank))
		for side: float in [-1.0, 1.0]:
			hull.add_child(ShapeKit.box("Gunwale", Vector3(2.7, 0.22, 0.08), Vector3(0.0, 0.38, side * 0.45), plank))
		hull.add_child(ShapeKit.box("Thwart", Vector3(0.18, 0.06, 0.9), Vector3(0.2, 0.32, 0.0), plank))
		parent.add_child(hull)
	var stone: Material = _material(STONE_COLOR)
	var gap: float = BRIDGE_WIDTH * 0.5 + BRIDGE_PARAPET_THICKNESS
	var bank_length: float = length * 0.5 - gap
	for bank: float in [-1.0, 1.0]:
		var bank_z: float = CANAL_Z + bank * (CANAL_WIDTH * 0.5 + CANAL_BANK_THICKNESS * 0.5)
		for side: float in [-1.0, 1.0]:
			parent.add_child(_low(_box_body("CanalBank%s%s" % ["North" if bank < 0.0 else "South", "West" if side < 0.0 else "East"],
				Vector3(bank_length, CANAL_BANK_HEIGHT, CANAL_BANK_THICKNESS),
				Vector3(side * (gap + bank_length * 0.5), CANAL_BANK_HEIGHT * 0.5, bank_z), stone)))


## Bramble-Bridge: a low stone arch. The walkway is one convex collider shaped
## like the arch (ramp, crown, ramp), starting flush with the ground at each
## end, and parapets follow its edges so nobody steps off into the canal.
func _add_bridge(parent: Node3D) -> void:
	var bridge: StaticBody3D = StaticBody3D.new()
	bridge.name = "Bramblebridge"
	bridge.position = Vector3(0.0, 0.0, CANAL_Z)
	bridge.collision_layer = ActorBase.LAYER_WORLD
	bridge.collision_mask = 0
	parent.add_child(bridge)
	var foot: float = BRIDGE_CROWN_LENGTH * 0.5 + BRIDGE_RAMP_LENGTH
	var crown: float = BRIDGE_CROWN_LENGTH * 0.5
	# The arch's side profile as (z, y), going round: the walkway on top, then under the ground.
	var top: PackedVector2Array = PackedVector2Array([Vector2(foot, 0.0), Vector2(crown, BRIDGE_RISE), Vector2(-crown, BRIDGE_RISE), Vector2(-foot, 0.0)])
	var profile: PackedVector2Array = top.duplicate()
	profile.append(Vector2(-foot, -0.4))
	profile.append(Vector2(foot, -0.4))
	var points: PackedVector3Array = PackedVector3Array()
	for side: float in [-1.0, 1.0]:
		for point: Vector2 in profile:
			points.append(Vector3(side * BRIDGE_WIDTH * 0.5, point.y, point.x))
	var shape: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	shape.points = points
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Walkway"
	collision.shape = shape
	bridge.add_child(collision)
	var stone: Material = WorldVisualCatalog.double_sided(WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.COBBLED_FLAGSTONE, BRIDGE_COLOR, false, 0.3))
	var deck: MeshInstance3D = MeshInstance3D.new()
	deck.name = "Deck"
	deck.mesh = _prism_mesh(profile, BRIDGE_WIDTH)
	deck.material_override = stone
	bridge.add_child(deck)
	# The dark arch underneath, showing on both faces above the water.
	var arch_mesh: CylinderMesh = CylinderMesh.new()
	arch_mesh.top_radius = 1.25
	arch_mesh.bottom_radius = 1.25
	arch_mesh.height = BRIDGE_WIDTH + 0.06
	arch_mesh.radial_segments = 24
	arch_mesh.material = _material(Color(0.16, 0.18, 0.2))
	var arch: MeshInstance3D = MeshInstance3D.new()
	arch.name = "Arch"
	arch.mesh = arch_mesh
	arch.position = Vector3(0.0, -0.45, 0.0)
	arch.rotation = Vector3(0.0, 0.0, PI * 0.5)
	bridge.add_child(arch)
	var parapet_stone: Material = _material(BRIDGE_COLOR.darkened(0.1))
	var parapets: StaticBody3D = StaticBody3D.new()
	parapets.name = "Parapets"
	parapets.collision_layer = ActorBase.LAYER_LOW_SCENERY
	parapets.collision_mask = 0
	bridge.add_child(parapets)
	for side: float in [-1.0, 1.0]:
		var x: float = side * (BRIDGE_WIDTH * 0.5 + BRIDGE_PARAPET_THICKNESS * 0.5)
		for index: int in top.size() - 1:
			var from: Vector2 = top[index]
			var to: Vector2 = top[index + 1]
			var length: float = from.distance_to(to)
			var middle: Vector2 = (from + to) * 0.5
			var size: Vector3 = Vector3(BRIDGE_PARAPET_THICKNESS, BRIDGE_PARAPET_HEIGHT + 0.3, length + 0.2)
			var where: Vector3 = Vector3(x, middle.y + BRIDGE_PARAPET_HEIGHT * 0.5 - 0.15, middle.x)
			var tilt: float = atan2(-(to.y - from.y), to.x - from.x)
			var rail_shape: BoxShape3D = BoxShape3D.new()
			rail_shape.size = size
			var rail: CollisionShape3D = CollisionShape3D.new()
			rail.name = "Parapet%s%d" % ["West" if side < 0.0 else "East", index]
			rail.shape = rail_shape
			rail.position = where
			rail.rotation = Vector3(tilt, 0.0, 0.0)
			parapets.add_child(rail)
			var rail_mesh: MeshInstance3D = ShapeKit.box("ParapetMesh", size, where, parapet_stone)
			rail_mesh.rotation = Vector3(tilt, 0.0, 0.0)
			parapets.add_child(rail_mesh)
	var village_sign: Label3D = Label3D.new()
	village_sign.name = "VillageSign"
	village_sign.text = "Bramble-Bridge"
	village_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	village_sign.font_size = 64
	village_sign.outline_size = 12
	village_sign.pixel_size = 0.012
	village_sign.modulate = Color(1.0, 0.92, 0.75)
	village_sign.position = Vector3(0.0, BRIDGE_RISE + 2.6, 0.0)
	bridge.add_child(village_sign)
	# Its dressing (17 GDD §4.1): radiating voussoirs, the Maker-Seal keystone and Wind-Lantern posts at the corners.
	bridge.add_child(WorldKitInstance.make("Dressing", WorldVisualCatalog.KIT_BRIDGE_STONE_ARCH, Vector3.ZERO, 0.0,
		{&"size": Vector3(BRIDGE_WIDTH, 1.25, foot)}))


## A closed prism: a side profile of (z, y) points extruded `width` along X.
func _prism_mesh(profile: PackedVector2Array, width: float) -> ArrayMesh:
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: float = width * 0.5
	var count: int = profile.size()
	for side: float in [-half, half]:
		for index: int in range(1, count - 1):
			for point: Vector2 in [profile[0], profile[index], profile[index + 1]]:
				tool.add_vertex(Vector3(side, point.y, point.x))
	for index: int in count:
		var a: Vector2 = profile[index]
		var b: Vector2 = profile[(index + 1) % count]
		for corner: Vector3 in [Vector3(-half, a.y, a.x), Vector3(half, a.y, a.x), Vector3(half, b.y, b.x),
				Vector3(-half, a.y, a.x), Vector3(half, b.y, b.x), Vector3(-half, b.y, b.x)]:
			tool.add_vertex(corner)
	tool.generate_normals()
	return tool.commit()


## The watermill: a shed on the north bank and its wheel turning in the canal.
func _add_watermill(parent: Node3D) -> void:
	var shed: StaticBody3D = _collider("Watermill", MILL_SIZE, MILL_POSITION + Vector3(0.0, MILL_SIZE.y * 0.5, 0.0))
	# A little stepped-gable mill house, its gable toward the canal.
	shed.add_child(WorldKitInstance.make("Kit", WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE, Vector3(0.0, -MILL_SIZE.y * 0.5, 0.0), -PI * 0.5,
		{&"size": Vector3(MILL_SIZE.z, MILL_SIZE.y, MILL_SIZE.x), &"tint": MILL_COLOR, &"accent": ROOF_TINTS[1]}))
	parent.add_child(shed)
	# The piers and the mill-race flume pouring over the wheel.
	parent.add_child(WorldKitInstance.make("MillRace", WorldVisualCatalog.KIT_WATERMILL_WHEEL, Vector3(MILL_POSITION.x, WHEEL_HEIGHT, CANAL_Z - CANAL_WIDTH * 0.25), 0.0,
		{&"height": WatermillWheel.RADIUS}))
	var wheel: Node3D = Node3D.new()
	wheel.name = "WaterWheel"
	wheel.set_script(load(WHEEL_SCRIPT))
	wheel.position = Vector3(MILL_POSITION.x, WHEEL_HEIGHT, CANAL_Z - CANAL_WIDTH * 0.25)
	# The wheel spins about its own Y axis: point that across the canal (Z), so it turns with the water.
	wheel.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	parent.add_child(wheel)


## A hero tree (17 GDD §4.3 kit, a moss-oak unless told otherwise): roots, a
## trunk forking above 3.2 m and leaf-clouds that sway and fade from sightlines.
## Only the trunk collides.
func _tree(tree_name: String, where: Vector3, height: float, collides: bool, kind: StringName = WorldVisualCatalog.KIT_TREE_MOSS_OAK) -> Node3D:
	var variety: int = absi(hash(tree_name)) % 3
	var tree: Node3D = WorldKitInstance.make(tree_name, kind, where, float(absi(hash(tree_name)) % 628) * 0.01, {&"height": height, &"seed_value": variety})
	if collides:
		var trunk_height: float = height * 0.55
		var trunk_radius: float = 0.22 + height * 0.025
		var body: StaticBody3D = StaticBody3D.new()
		body.name = "TrunkBody"
		body.collision_layer = ActorBase.LAYER_WORLD
		body.collision_mask = 0
		var shape: CylinderShape3D = CylinderShape3D.new()
		shape.radius = trunk_radius
		shape.height = trunk_height
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.name = "Collision"
		collision.shape = shape
		collision.position = Vector3(0.0, trunk_height * 0.5, 0.0)
		body.add_child(collision)
		tree.add_child(body)
	return tree


func _fountain() -> StaticBody3D:
	var fountain: StaticBody3D = StaticBody3D.new()
	fountain.name = "Fountain"
	fountain.position = FOUNTAIN_POSITION
	fountain.collision_layer = ActorBase.LAYER_LOW_SCENERY
	fountain.collision_mask = 0
	var basin_shape: CylinderShape3D = CylinderShape3D.new()
	basin_shape.radius = FOUNTAIN_RADIUS
	basin_shape.height = 0.7
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = basin_shape
	collision.position = Vector3(0.0, 0.35, 0.0)
	fountain.add_child(collision)
	fountain.add_child(ShapeKit.cylinder("Basin", FOUNTAIN_RADIUS, FOUNTAIN_RADIUS, 0.7, Vector3(0.0, 0.35, 0.0), _material(STONE_COLOR), 24))
	fountain.add_child(ShapeKit.cylinder("Water", FOUNTAIN_RADIUS - 0.25, FOUNTAIN_RADIUS - 0.25, 0.05, Vector3(0.0, 0.7, 0.0), WorldVisualCatalog.water(&"shrine"), 24))
	fountain.add_child(ShapeKit.cylinder("Spout", 0.25, 0.45, 1.8, Vector3(0.0, 0.9, 0.0), _material(STONE_COLOR), 24))
	return fountain


## A Wind-Lantern on its post (17 GDD kit_wind_lantern_post).
func _lantern(lantern_name: String, where: Vector3) -> Node3D:
	return WorldKitInstance.make(lantern_name, WorldVisualCatalog.KIT_WIND_LANTERN_POST, where, float(absi(hash(lantern_name)) % 4) * PI * 0.5)


# --- The Dover-Slap-Falls Expedition ---------------------------------------------

func _build_dojo() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "DungeonDojo"
	root.set_script(load(DOJO_SCRIPT))
	root.add_child(_environment(true))
	root.add_child(_sun())
	var world: Node3D = _node3d("Expedition")
	root.add_child(world)
	_build_moss_oaks(world, false)
	_build_holloway(world)
	_build_gorge(world)
	_build_ring(world)
	root.add_child(_boss_spawn())
	var exit: Node3D = _portal("ExitPortal", InstanceManager.HUB_TOWN, "Exit: Bramble-Bridge", EXIT_PORTAL_COLOR, EXIT_PORTAL_POSITION)
	# Home is whichever Bramble-Bridge the party came from (the hub, or the seamless world).
	exit.set(&"goes_home", true)
	root.add_child(exit)
	_add_zone_one_entities(root, false)
	root.add_child(_scripted("CoopGate", GATE_SCRIPT, GATE_POSITION, {&"persist_id": LandblockManifest.SINAYA_GATE}))
	var checkpoints: Node3D = _node3d("Checkpoints")
	root.add_child(checkpoints)
	for checkpoint: Array in [["Zone2", CHECKPOINT_TWO_Z], ["Zone3", CHECKPOINT_THREE_Z]]:
		var marker: Marker3D = Marker3D.new()
		marker.name = checkpoint[0]
		marker.position = Vector3(0.0, 0.0, checkpoint[1])
		checkpoints.add_child(marker)
	_add_level_skeleton(root, EXPEDITION_SPAWN_Z)
	return root


## The Cairnsman's spot, facing south toward the causeway the party comes in by.
func _boss_spawn() -> Marker3D:
	var boss_spawn: Marker3D = Marker3D.new()
	boss_spawn.name = "BossSpawn"
	boss_spawn.position = BOSS_POSITION
	boss_spawn.rotation = Vector3(0.0, PI, 0.0)
	boss_spawn.add_child(_pad("Ring", 2.2, Color(0.35, 0.18, 0.2)))
	return boss_spawn


## Zone 1's camps, Water-Shrine, Wind-Lanterns and the Wayfarer's Chest's spot,
## each with its WorldStateDB id (Landblock entities in the seamless world).
func _add_zone_one_entities(root: Node3D, world_mode: bool) -> void:
	var stateful: Array[Node3D] = [
		_scripted("CampOne", CAMP_SCRIPT, CAMP_ONE_POSITION, {&"camp_name": "Bramble Hush-Crack", &"kinds": CAMP_ONE_KINDS, &"persist_id": LandblockManifest.CAMP_BRAMBLE}),
		_scripted("CampTwo", CAMP_SCRIPT, CAMP_TWO_POSITION, {&"camp_name": "Rush-Light Hush-Crack", &"kinds": CAMP_TWO_KINDS, &"persist_id": LandblockManifest.CAMP_HOLLOWAY}),
		_scripted("WaterShrine", SHRINE_WATER_SCRIPT, WATER_SHRINE_POSITION, {&"persist_id": LandblockManifest.WATER_SHRINE}),
	]
	for node: Node3D in stateful:
		root.add_child(_entity(node) if world_mode else node)
	var lanterns: Node3D = _node3d("WindLanterns")
	root.add_child(lanterns)
	for index: int in WIND_LANTERN_SPOTS.size():
		lanterns.add_child(_scripted("WindLantern%d" % (index + 1), LANTERN_SCRIPT, WIND_LANTERN_SPOTS[index], {}))
	root.add_child(_chime_post("CampChimePost", CAMP_POST, "Moss-Oak-Hollow"))
	root.add_child(_chime_post("HollowChimePost", HOLLOW_POST, "Rush-Light-Hollow"))
	var chest_spot: Marker3D = Marker3D.new()
	chest_spot.name = "WayfarerChestSpot"
	chest_spot.position = WAYFARER_CHEST_POSITION
	root.add_child(_entity(chest_spot) if world_mode else chest_spot)


## Zone 1: a walled clearing of moss-oaks, the first bramble camp, a winding
## trail to the holloway, and the deer-run alcove through the west wall. In the
## seamless world its south wall has a gap for the trail from Bramble-Bridge,
## under the Moss-Oak Great Arch.
func _build_moss_oaks(parent: Node3D, world_mode: bool) -> void:
	var oaks: Node3D = _node3d("MossOaks")
	parent.add_child(oaks)
	var moss: Material = _material(MOSS_COLOR)
	oaks.add_child(_ground("Ground", OAKS_MIN, OAKS_MAX, 0.0, moss))
	var stone: Material = _material(DRYSTONE_COLOR)
	if world_mode:
		var gap: float = OAKS_SOUTH_GAP * 0.5
		oaks.add_child(_wall("WallSouthWest", Vector2(OAKS_MIN.x, OAKS_MAX.y), Vector2(-gap, OAKS_MAX.y), DRYSTONE_HEIGHT, stone))
		oaks.add_child(_wall("WallSouthEast", Vector2(gap, OAKS_MAX.y), Vector2(OAKS_MAX.x, OAKS_MAX.y), DRYSTONE_HEIGHT, stone))
	else:
		oaks.add_child(_wall("WallSouth", Vector2(OAKS_MIN.x, OAKS_MAX.y), Vector2(OAKS_MAX.x, OAKS_MAX.y), DRYSTONE_HEIGHT, stone))
	oaks.add_child(_wall("WallEast", Vector2(OAKS_MAX.x, OAKS_MIN.y), Vector2(OAKS_MAX.x, OAKS_MAX.y), DRYSTONE_HEIGHT, stone))
	oaks.add_child(_wall("WallWestSouth", Vector2(OAKS_MIN.x, ALCOVE_MAX.y), Vector2(OAKS_MIN.x, OAKS_MAX.y), DRYSTONE_HEIGHT, stone))
	oaks.add_child(_wall("WallWestNorth", Vector2(OAKS_MIN.x, OAKS_MIN.y), Vector2(OAKS_MIN.x, ALCOVE_MIN.y), DRYSTONE_HEIGHT, stone))
	oaks.add_child(_wall("WallNorthWest", Vector2(OAKS_MIN.x, OAKS_MIN.y), Vector2(-HOLLOWAY_HALF_WIDTH, OAKS_MIN.y), DRYSTONE_HEIGHT, stone))
	oaks.add_child(_wall("WallNorthEast", Vector2(HOLLOWAY_HALF_WIDTH, OAKS_MIN.y), Vector2(OAKS_MAX.x, OAKS_MIN.y), DRYSTONE_HEIGHT, stone))
	var dirt: Material = _material(TRAIL_COLOR)
	for index: int in TRAIL_POINTS.size() - 1:
		var from: Vector3 = TRAIL_POINTS[index]
		var to: Vector3 = TRAIL_POINTS[index + 1]
		var strip: MeshInstance3D = ShapeKit.box("Trail%d" % index, Vector3(3.0, 0.02, from.distance_to(to) + 1.0), (from + to) * 0.5 + Vector3.UP * 0.01, dirt)
		strip.rotation = Vector3(0.0, atan2(to.x - from.x, to.z - from.z), 0.0)
		oaks.add_child(strip)
	for index: int in OAK_SPOTS.size():
		oaks.add_child(_tree("Oak%d" % (index + 1), OAK_SPOTS[index], 7.5 + float(index % 4) * 0.8, true))
	if world_mode:
		var lead_in: MeshInstance3D = ShapeKit.box("TrailIn", Vector3(3.0, 0.02, OAKS_MAX.y - TRAIL_POINTS[0].z + 1.0),
			Vector3(0.0, 0.01, (OAKS_MAX.y + TRAIL_POINTS[0].z) * 0.5), dirt)
		oaks.add_child(lead_in)
		_add_great_arch(oaks)
	# The alcove: a short deer-run behind dry-stone walls, where the Wayfarer's Chest waits.
	var alcove: Node3D = _node3d("Alcove")
	parent.add_child(alcove)
	alcove.add_child(_ground("Ground", ALCOVE_MIN, ALCOVE_MAX, 0.0, moss))
	alcove.add_child(_wall("WallNorth", Vector2(ALCOVE_MIN.x, ALCOVE_MIN.y), Vector2(ALCOVE_MAX.x, ALCOVE_MIN.y), DRYSTONE_HEIGHT, stone))
	alcove.add_child(_wall("WallSouth", Vector2(ALCOVE_MIN.x, ALCOVE_MAX.y), Vector2(ALCOVE_MAX.x, ALCOVE_MAX.y), DRYSTONE_HEIGHT, stone))
	alcove.add_child(_wall("WallWest", Vector2(ALCOVE_MIN.x, ALCOVE_MIN.y), Vector2(ALCOVE_MIN.x, ALCOVE_MAX.y), DRYSTONE_HEIGHT, stone))
	alcove.add_child(_tree("Oak", Vector3(ALCOVE_MIN.x - 3.0, 0.0, (ALCOVE_MIN.y + ALCOVE_MAX.y) * 0.5), 8.0, false))


## The Moss-Oak Great Arch over the trail into the clearing: two old oaks
## leaning together, their boughs meeting high overhead. Seen from
## Bramble-Bridge's gate, and the Moss-Oaks' HLOD landmark.
func _add_great_arch(parent: Node3D) -> void:
	var arch: Node3D = _node3d("GreatArch")
	parent.add_child(arch)
	var bark: Material = WorldVisualCatalog.craft_for_color(OAK_TRUNK_COLOR, true)
	var leaves: Material = WorldVisualCatalog.foliage(OAK_LEAF_COLOR, GREAT_ARCH_HEIGHT, 0.08, 0.0, true)
	for side: float in [-1.0, 1.0]:
		var foot: Vector3 = Vector3(side * GREAT_ARCH_SPAN, 0.0, GREAT_ARCH_Z)
		var knee: Vector3 = Vector3(side * (GREAT_ARCH_SPAN - 0.8), GREAT_ARCH_HEIGHT * 0.55, GREAT_ARCH_Z + 0.4)
		var crown: Vector3 = Vector3(side * 0.6, GREAT_ARCH_HEIGHT, GREAT_ARCH_Z)
		arch.add_child(_beam("Trunk%s" % ("West" if side < 0.0 else "East"), foot, knee, 0.75, bark))
		arch.add_child(_beam("Bough%s" % ("West" if side < 0.0 else "East"), knee, crown, 0.5, bark))
		var body: StaticBody3D = _box_body("Root%s" % ("West" if side < 0.0 else "East"), Vector3(1.4, 3.0, 1.4), foot + Vector3(0.0, 1.5, 0.0), bark)
		arch.add_child(body)
	for index: int in 5:
		var spread: float = (float(index) - 2.0) * 2.4
		var heap: MeshInstance3D = ShapeKit.sphere("Canopy%d" % index, 2.6 - absf(spread) * 0.12, Vector3(spread, GREAT_ARCH_HEIGHT + 0.8 - absf(spread) * 0.3,
			GREAT_ARCH_Z + (0.6 if index % 2 == 0 else -0.6)), leaves)
		heap.scale = Vector3(1.3, 0.8, 1.1)
		arch.add_child(heap)
	# Dappled light-shafts slanting down through the canopy (17 GDD §6.2).
	var shaft: StandardMaterial3D = StandardMaterial3D.new()
	shaft.albedo_color = Color(1.0, 0.9, 0.62, 0.12)
	shaft.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shaft.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shaft.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	shaft.cull_mode = BaseMaterial3D.CULL_DISABLED
	shaft.disable_receive_shadows = true
	for index: int in 3:
		var beam: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.box("LightShaft%d" % index, Vector3(1.2, GREAT_ARCH_HEIGHT, 0.02),
			Vector3((float(index) - 1.0) * 1.8, GREAT_ARCH_HEIGHT * 0.45, GREAT_ARCH_Z - 2.0 - index * 1.5), shaft))
		beam.rotation = Vector3(0.0, 0.6, -0.42)
		arch.add_child(beam)


## Rush-Light-Hollow: a ramp down into a lane between high earthen banks,
## root arches overhead hung with Wind-Lanterns, and a ramp back up to the gorge.
func _build_holloway(parent: Node3D) -> void:
	var holloway: Node3D = _node3d("Holloway")
	parent.add_child(holloway)
	var earth: Material = _material(EARTH_COLOR)
	var floor_y: float = -HOLLOWAY_DEPTH
	holloway.add_child(_ramp("RampDown", HOLLOWAY_HALF_WIDTH, HOLLOWAY_TOP_Z, 0.0, HOLLOWAY_FLOOR_START_Z, floor_y, earth))
	holloway.add_child(_ground("Lane", Vector2(-HOLLOWAY_HALF_WIDTH, HOLLOWAY_FLOOR_END_Z), Vector2(HOLLOWAY_HALF_WIDTH, HOLLOWAY_FLOOR_START_Z), floor_y, earth))
	holloway.add_child(_ramp("RampUp", HOLLOWAY_HALF_WIDTH, HOLLOWAY_FLOOR_END_Z, floor_y, HOLLOWAY_EXIT_Z, 0.0, earth))
	var bank_height: float = HOLLOWAY_DEPTH + BANK_LIP + 0.6
	var bank_length: float = HOLLOWAY_TOP_Z - HOLLOWAY_EXIT_Z
	var moss: Material = _material(MOSS_COLOR)
	for side: float in [-1.0, 1.0]:
		var center: Vector3 = Vector3(side * (HOLLOWAY_HALF_WIDTH + BANK_WIDTH * 0.5), BANK_LIP - bank_height * 0.5, (HOLLOWAY_TOP_Z + HOLLOWAY_EXIT_Z) * 0.5)
		var bank: StaticBody3D = _low(_box_body("Bank%s" % ("West" if side < 0.0 else "East"), Vector3(BANK_WIDTH, bank_height, bank_length), center, earth))
		bank.add_child(ShapeKit.box("Moss", Vector3(BANK_WIDTH + 0.1, 0.12, bank_length), Vector3(0.0, bank_height * 0.5, 0.0), moss))
		holloway.add_child(bank)
	var roots: Material = WorldVisualCatalog.craft_for_color(ROOT_COLOR, true)
	for index: int in ROOT_ARCH_ZS.size():
		var z: float = ROOT_ARCH_ZS[index]
		var apex: Vector3 = Vector3(0.0, ROOT_ARCH_APEX, z)
		for side: float in [-1.0, 1.0]:
			var foot: Vector3 = Vector3(side * (HOLLOWAY_HALF_WIDTH + 0.3), BANK_LIP, z + side * 0.4)
			var knee: Vector3 = Vector3(side * 2.4, ROOT_ARCH_APEX - 0.5, z - side * 0.3)
			holloway.add_child(_beam("Root%d%s" % [index, "W" if side < 0.0 else "E"], foot, knee, 0.22, roots))
			holloway.add_child(_beam("Bough%d%s" % [index, "W" if side < 0.0 else "E"], knee, apex, 0.16, roots))
	var glow: StandardMaterial3D = _standard(MUSHROOM_COLOR)
	glow.emission_enabled = true
	glow.emission = MUSHROOM_COLOR
	glow.emission_energy_multiplier = 1.6
	for index: int in 10:
		var side: float = -1.0 if index % 2 == 0 else 1.0
		var z: float = lerpf(HOLLOWAY_FLOOR_START_Z - 1.0, HOLLOWAY_FLOOR_END_Z + 1.0, float(index) / 9.0)
		var cap: SphereMesh = SphereMesh.new()
		cap.radius = 0.16
		cap.height = 0.16
		cap.material = glow
		var mushroom: MeshInstance3D = MeshInstance3D.new()
		mushroom.name = "Mushroom%d" % index
		mushroom.mesh = cap
		mushroom.position = Vector3(side * (HOLLOWAY_HALF_WIDTH - 0.25), floor_y + 0.1, z)
		holloway.add_child(mushroom)
	# The slope contract (18 GDD §3.2): both ramps are dressed with half-set log
	# sleepers and bordered by low guide-posts, so a child knows they can climb them.
	var span: float = HOLLOWAY_HALF_WIDTH * 2.0 - 1.4
	var down: Node3D = WorldKitInstance.make("RampDownSleepers", WorldVisualCatalog.KIT_PATH_SLEEPER, Vector3(0.0, floor_y, HOLLOWAY_FLOOR_START_Z), PI,
		{&"size": Vector3(span, HOLLOWAY_DEPTH, HOLLOWAY_TOP_Z - HOLLOWAY_FLOOR_START_Z), &"seed_value": 1})
	holloway.add_child(down)
	var up: Node3D = WorldKitInstance.make("RampUpSleepers", WorldVisualCatalog.KIT_PATH_SLEEPER, Vector3(0.0, floor_y, HOLLOWAY_FLOOR_END_Z), 0.0,
		{&"size": Vector3(span, HOLLOWAY_DEPTH, HOLLOWAY_FLOOR_END_Z - HOLLOWAY_EXIT_Z), &"seed_value": 2})
	holloway.add_child(up)
	for ramp: Vector4 in [Vector4(HOLLOWAY_TOP_Z, 0.0, HOLLOWAY_FLOOR_START_Z, floor_y), Vector4(HOLLOWAY_FLOOR_END_Z, floor_y, HOLLOWAY_EXIT_Z, 0.0)]:
		var posts: int = int(absf(ramp.x - ramp.z) / GUIDE_POST_SPACING) + 1
		for index: int in posts:
			var t: float = float(index) / maxf(1.0, posts - 1)
			for side: float in [-1.0, 1.0]:
				var at: Vector3 = Vector3(side * (HOLLOWAY_HALF_WIDTH - 0.3), lerpf(ramp.y, ramp.w, t), lerpf(ramp.x, ramp.z, t))
				holloway.add_child(_guide_post("GuidePost%d%s%d" % [int(ramp.x), "W" if side < 0.0 else "E", index], at))


## A low wooden guide-post (kit_guide_post, 18 GDD §3.2), its collider on the
## LowScenery layer: it borders a climbable path but never blocks a camera.
func _guide_post(post_name: String, at: Vector3) -> StaticBody3D:
	var post: StaticBody3D = _collider(post_name, Vector3(0.18, GUIDE_POST_HEIGHT, 0.18), at + Vector3(0.0, GUIDE_POST_HEIGHT * 0.5, 0.0),
		ActorBase.LAYER_LOW_SCENERY)
	post.add_child(WorldKitInstance.make("Kit", WorldVisualCatalog.KIT_GUIDE_POST, Vector3(0.0, -GUIDE_POST_HEIGHT * 0.5, 0.0), 0.0,
		{&"height": GUIDE_POST_HEIGHT}))
	return post


## Zone 2: the cliff edges, the timber-and-stone trestle bridge over the
## Dover-Slap-Falls (with side bays for the Maker-Seal Plates), the waterfall and the
## paper-mill wheel, and the Dover-Slap Gatehouse's towers around the CoopGate.
func _build_gorge(parent: Node3D) -> void:
	var gorge: Node3D = _node3d("Gorge")
	parent.add_child(gorge)
	var moss: Material = _material(MOSS_COLOR)
	var stone: Material = _material(DRYSTONE_COLOR)
	var cliff: Material = _material(CLIFF_COLOR)
	var timber: Material = _material(TIMBER_COLOR)
	var w: float = CLIFF_HALF_WIDTH
	gorge.add_child(_ground("SouthCliff", Vector2(-w, SOUTH_CLIFF_Z.x), Vector2(w, SOUTH_CLIFF_Z.y), 0.0, moss))
	gorge.add_child(_ground("NorthCliff", Vector2(-w, NORTH_CLIFF_Z.x), Vector2(w, NORTH_CLIFF_Z.y), 0.0, moss))
	var bank_edge: float = HOLLOWAY_HALF_WIDTH + BANK_WIDTH
	gorge.add_child(_wall("SouthWallWest", Vector2(-w, SOUTH_CLIFF_Z.y), Vector2(-bank_edge, SOUTH_CLIFF_Z.y), DRYSTONE_HEIGHT, stone))
	gorge.add_child(_wall("SouthWallEast", Vector2(bank_edge, SOUTH_CLIFF_Z.y), Vector2(w, SOUTH_CLIFF_Z.y), DRYSTONE_HEIGHT, stone))
	for side: float in [-1.0, 1.0]:
		var label: String = "West" if side < 0.0 else "East"
		gorge.add_child(_wall("SouthSide%s" % label, Vector2(side * w, SOUTH_CLIFF_Z.x), Vector2(side * w, SOUTH_CLIFF_Z.y), DRYSTONE_HEIGHT, stone))
		gorge.add_child(_wall("NorthSide%s" % label, Vector2(side * w, NORTH_CLIFF_Z.x), Vector2(side * w, NORTH_CLIFF_Z.y), DRYSTONE_HEIGHT, stone))
		# Rails along both cliff edges, open only where the bridge lands.
		gorge.add_child(_wall("SouthEdge%s" % label, Vector2(side * (GORGE_BRIDGE_HALF_WIDTH + 0.2), SOUTH_CLIFF_Z.x), Vector2(side * w, SOUTH_CLIFF_Z.x), RAIL_HEIGHT, timber, 0.0, 0.25))
		gorge.add_child(_wall("NorthEdge%s" % label, Vector2(side * (GORGE_BRIDGE_HALF_WIDTH + 0.2), NORTH_CLIFF_Z.y), Vector2(side * w, NORTH_CLIFF_Z.y), RAIL_HEIGHT, timber, 0.0, 0.25))
		gorge.add_child(_wall("NorthEnd%s" % label, Vector2(side * CAUSEWAY_HALF_WIDTH, NORTH_CLIFF_Z.x), Vector2(side * w, NORTH_CLIFF_Z.x), DRYSTONE_HEIGHT, stone))
	# The trestle bridge: a timber deck on stone piers and timber legs, with two side bays.
	var span: float = SOUTH_CLIFF_Z.x - NORTH_CLIFF_Z.y
	var middle_z: float = (SOUTH_CLIFF_Z.x + NORTH_CLIFF_Z.y) * 0.5
	gorge.add_child(_box_body("BridgeDeck", Vector3(GORGE_BRIDGE_HALF_WIDTH * 2.0, 0.4, span), Vector3(0.0, -0.2, middle_z), timber))
	var bay_length: float = BRIDGE_BAY_Z.y - BRIDGE_BAY_Z.x
	var bay_z: float = (BRIDGE_BAY_Z.x + BRIDGE_BAY_Z.y) * 0.5
	for side: float in [-1.0, 1.0]:
		var label: String = "West" if side < 0.0 else "East"
		var rail_x: float = side * (GORGE_BRIDGE_HALF_WIDTH + 0.1)
		var bay_x: float = side * (GORGE_BRIDGE_HALF_WIDTH + BRIDGE_BAY_DEPTH)
		gorge.add_child(_box_body("Bay%s" % label, Vector3(BRIDGE_BAY_DEPTH, 0.4, bay_length), Vector3(side * (GORGE_BRIDGE_HALF_WIDTH + BRIDGE_BAY_DEPTH * 0.5), -0.2, bay_z), timber))
		gorge.add_child(_wall("Rail%sSouth" % label, Vector2(rail_x, BRIDGE_BAY_Z.y), Vector2(rail_x, SOUTH_CLIFF_Z.x), RAIL_HEIGHT, timber, 0.0, 0.2))
		gorge.add_child(_wall("Rail%sNorth" % label, Vector2(rail_x, NORTH_CLIFF_Z.y), Vector2(rail_x, BRIDGE_BAY_Z.x), RAIL_HEIGHT, timber, 0.0, 0.2))
		gorge.add_child(_wall("BayRail%sOuter" % label, Vector2(bay_x, BRIDGE_BAY_Z.x), Vector2(bay_x, BRIDGE_BAY_Z.y), RAIL_HEIGHT, timber, 0.0, 0.2))
		gorge.add_child(_wall("BayRail%sSouth" % label, Vector2(rail_x, BRIDGE_BAY_Z.y), Vector2(bay_x, BRIDGE_BAY_Z.y), RAIL_HEIGHT, timber, 0.0, 0.2))
		gorge.add_child(_wall("BayRail%sNorth" % label, Vector2(rail_x, BRIDGE_BAY_Z.x), Vector2(bay_x, BRIDGE_BAY_Z.x), RAIL_HEIGHT, timber, 0.0, 0.2))
		for z: float in [3.0, -3.0, -9.0]:
			gorge.add_child(ShapeKit.box("Trestle%s%d" % [label, int(z)], Vector3(0.5, GORGE_DEPTH, 0.5), Vector3(side * (GORGE_BRIDGE_HALF_WIDTH - 0.4), -GORGE_DEPTH * 0.5 - 0.4, z), timber))
		var brace: MeshInstance3D = ShapeKit.box("Brace%s" % label, Vector3(0.3, 0.3, span * 0.9), Vector3(side * (GORGE_BRIDGE_HALF_WIDTH - 0.4), -4.0, middle_z), timber)
		brace.rotation = Vector3(0.35, 0.0, 0.0)
		gorge.add_child(brace)
	for end_z: float in [SOUTH_CLIFF_Z.x, NORTH_CLIFF_Z.y]:
		gorge.add_child(ShapeKit.box("Pier%d" % int(end_z), Vector3(GORGE_BRIDGE_HALF_WIDTH * 2.0 + 1.0, GORGE_DEPTH, 2.0), Vector3(0.0, -GORGE_DEPTH * 0.5 - 0.4, end_z), stone))
	# The chasm's rock faces.
	gorge.add_child(ShapeKit.box("FaceSouth", Vector3(w * 2.0, GORGE_DEPTH, 0.6), Vector3(0.0, -GORGE_DEPTH * 0.5, SOUTH_CLIFF_Z.x - 0.3), cliff))
	gorge.add_child(ShapeKit.box("FaceNorth", Vector3(w * 2.0, GORGE_DEPTH, 0.6), Vector3(0.0, -GORGE_DEPTH * 0.5, NORTH_CLIFF_Z.y + 0.3), cliff))
	for side: float in [-1.0, 1.0]:
		gorge.add_child(ShapeKit.box("Face%s" % ("West" if side < 0.0 else "East"), Vector3(0.6, GORGE_DEPTH + 8.0, span), Vector3(side * (w + 0.3), -GORGE_DEPTH * 0.5 + 4.0, middle_z), cliff))
	# The Dover-Slap-Falls: a roaring fall of water down the east side, misting at its foot.
	gorge.add_child(ShapeKit.no_shadow(ShapeKit.box("Waterfall", WATERFALL_SIZE, WATERFALL_POSITION, WorldVisualCatalog.water(&"falls", Vector2(0.0, 1.6)))))
	# The trestle's granite piers and criss-cross timber trusses (17 GDD §4.1).
	gorge.add_child(WorldKitInstance.make("TrestleDressing", WorldVisualCatalog.KIT_BRIDGE_CARPATHIAN_TRESTLE, Vector3(0.0, 0.0, middle_z), 0.0,
		{&"size": Vector3(GORGE_BRIDGE_HALF_WIDTH * 2.0, GORGE_DEPTH, span)}))
	gorge.add_child(_chime_post("BridgeChimePost", BRIDGE_POST, "Dover-Slap-Bridge"))
	gorge.add_child(_mist("FallMist", WATERFALL_POSITION + Vector3(0.0, -WATERFALL_SIZE.y * 0.4, 1.0), Vector3(3.0, 1.0, 2.0)))
	gorge.add_child(_mist("FallSpray", WATERFALL_POSITION + Vector3(-1.0, WATERFALL_SIZE.y * 0.45, 0.8), Vector3(2.5, 0.5, 1.0)))
	var wheel: Node3D = Node3D.new()
	wheel.name = "PaperMillWheel"
	wheel.set_script(load(WHEEL_SCRIPT))
	wheel.position = MILLWHEEL_POSITION
	wheel.rotation = Vector3(0.0, 0.0, PI * 0.5)
	wheel.scale = Vector3.ONE * MILLWHEEL_SCALE
	gorge.add_child(wheel)
	gorge.add_child(WorldKitInstance.make("MillHouse", WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE, MILLWHEEL_POSITION + Vector3(-3.5, -2.0, 0.0), 0.0,
		{&"size": Vector3(4.0, 4.2, 5.0), &"tint": MILL_COLOR, &"accent": ROOF_TINTS[1]}))
	gorge.add_child(WorldKitInstance.make("MillRace", WorldVisualCatalog.KIT_WATERMILL_WHEEL, MILLWHEEL_POSITION, PI * 0.5,
		{&"height": WatermillWheel.RADIUS * MILLWHEEL_SCALE}))
	# The Dover-Slap Gatehouse: two stone towers with carved timber turrets, walls out to the cliff sides.
	var half_gate: float = CoopGate.PORTCULLIS_WIDTH * 0.5
	for side: float in [-1.0, 1.0]:
		var label: String = "West" if side < 0.0 else "East"
		var tower_x: float = side * (half_gate + GATE_TOWER_SIZE.x * 0.5)
		var tower: StaticBody3D = _box_body("Tower%s" % label, GATE_TOWER_SIZE, Vector3(tower_x, GATE_TOWER_SIZE.y * 0.5, GATE_POSITION.z), stone)
		# A carved, shingled spire on each turret (17 GDD §4.1).
		var roof: MeshInstance3D = ShapeKit.cylinder("Turret", 0.0, GATE_TOWER_SIZE.x * 0.62, 4.2, Vector3(0.0, GATE_TOWER_SIZE.y * 0.5 + 2.6, 0.0),
			WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.SCALLOP_SHINGLE, WorldAssetCatalog.SHINGLE_SLATE, true, 0.2), 8)
		tower.add_child(roof)
		tower.add_child(ShapeKit.cylinder("Finial", 0.0, 0.12, 0.8, Vector3(0.0, GATE_TOWER_SIZE.y * 0.5 + 5.0, 0.0),
			WorldVisualCatalog.glowing(WorldVisualCatalog.RIME_GALE, 1.0), 6))
		tower.add_child(ShapeKit.box("Gallery", Vector3(GATE_TOWER_SIZE.x + 0.6, 0.5, GATE_TOWER_SIZE.z + 0.6), Vector3(0.0, GATE_TOWER_SIZE.y * 0.5 + 0.25, 0.0), timber))
		gorge.add_child(tower)
		var wall_from: float = side * (half_gate + GATE_TOWER_SIZE.x)
		gorge.add_child(_wall("GateWall%s" % label, Vector2(wall_from, GATE_POSITION.z), Vector2(side * w, GATE_POSITION.z), GATE_WALL_HEIGHT, stone, 0.0, 1.2))
	gorge.add_child(ShapeKit.box("GateLintel", Vector3(CoopGate.PORTCULLIS_WIDTH + 0.6, 0.6, 0.9), Vector3(0.0, CoopGate.PORTCULLIS_HEIGHT + 0.5, GATE_POSITION.z), timber))
	var gate_sign: Label3D = Label3D.new()
	gate_sign.name = "GateSign"
	gate_sign.text = "Dover-Slap Gatehouse"
	gate_sign.font_size = 52
	gate_sign.outline_size = 10
	gate_sign.pixel_size = 0.01
	gate_sign.modulate = Color(1.0, 0.92, 0.75)
	gate_sign.position = Vector3(0.0, CoopGate.PORTCULLIS_HEIGHT + 1.3, GATE_POSITION.z + 0.6)
	gorge.add_child(gate_sign)


## Zone 3: a mossy causeway into the walled Ring of the Cairnsman, with its
## ring of pillars and the waterfall's spray drifting over the north wall.
func _build_ring(parent: Node3D) -> void:
	var ring: Node3D = _node3d("Ring")
	parent.add_child(ring)
	var stone: Material = _material(DRYSTONE_COLOR)
	ring.add_child(_ground("Causeway", Vector2(-CAUSEWAY_HALF_WIDTH, CAUSEWAY_Z.x), Vector2(CAUSEWAY_HALF_WIDTH, CAUSEWAY_Z.y), 0.0, _material(STONE_COLOR)))
	for side: float in [-1.0, 1.0]:
		ring.add_child(_wall("CausewayWall%s" % ("West" if side < 0.0 else "East"), Vector2(side * (CAUSEWAY_HALF_WIDTH + 0.2), CAUSEWAY_Z.x),
			Vector2(side * (CAUSEWAY_HALF_WIDTH + 0.2), CAUSEWAY_Z.y), 0.9, stone, 0.0, 0.4))
	# Weathered flagstones at a mid-value grey (#8A8E91) so every telegraph pops, clear of clutter (17 GDD §5.2).
	var floor_material: Material = WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.COBBLED_FLAGSTONE, ARENA_FLOOR_COLOR)
	var half: float = RING_SIZE * 0.5
	var south: float = BOSS_POSITION.z + half
	var north: float = BOSS_POSITION.z - half
	ring.add_child(_ground("Floor", Vector2(-half, north), Vector2(half, south), 0.0, floor_material))
	ring.add_child(_wall("WallNorth", Vector2(-half, north), Vector2(half, north), WALL_HEIGHT, stone))
	ring.add_child(_wall("WallWest", Vector2(-half, north), Vector2(-half, south), WALL_HEIGHT, stone))
	ring.add_child(_wall("WallEast", Vector2(half, north), Vector2(half, south), WALL_HEIGHT, stone))
	ring.add_child(_wall("WallSouthWest", Vector2(-half, south), Vector2(-CAUSEWAY_HALF_WIDTH, south), WALL_HEIGHT, stone))
	ring.add_child(_wall("WallSouthEast", Vector2(CAUSEWAY_HALF_WIDTH, south), Vector2(half, south), WALL_HEIGHT, stone))
	for index: int in PILLAR_COUNT:
		var angle: float = TAU * float(index) / PILLAR_COUNT
		var where: Vector3 = BOSS_POSITION + Vector3(cos(angle), 0.0, sin(angle)) * PILLAR_RING_RADIUS
		var pillar: StaticBody3D = _pillar("Pillar%d" % (index + 1), where, _material(STONE_COLOR))
		# Each pillar is a sculpted, Voronoi-cleaved megalith carved with a spiral
		# Maker-Seal (18 GDD §4.3); its plain cylinder goes, its collider stays.
		var plain: Node = pillar.get_node("Mesh")
		pillar.remove_child(plain)
		plain.free()
		pillar.add_child(WorldKitInstance.make("Stone", WorldVisualCatalog.KIT_STANDING_STONE, Vector3(0.0, -PILLAR_HEIGHT * 0.5, 0.0), -angle + PI * 0.5,
			{&"size": Vector3(PILLAR_RADIUS * 2.0, PILLAR_HEIGHT + 0.6, PILLAR_RADIUS * 1.6), &"seed_value": index}))
		ring.add_child(pillar)
		# Six more round the outside, between the pillars (twelve in all).
		var outer_angle: float = angle + PI / PILLAR_COUNT
		var outer: Vector3 = BOSS_POSITION + Vector3(cos(outer_angle), 0.0, sin(outer_angle)) * OUTER_STONE_RADIUS
		if absf(outer.x) > CAUSEWAY_HALF_WIDTH + 2.0 or outer.z < BOSS_POSITION.z:
			var standing: StaticBody3D = _collider("StandingStone%d" % (index + 1), Vector3(1.4, 4.2, 0.9), outer + Vector3(0.0, 2.1, 0.0))
			standing.rotation.y = -outer_angle + PI * 0.5
			standing.add_child(WorldKitInstance.make("Stone", WorldVisualCatalog.KIT_STANDING_STONE, Vector3(0.0, -2.1, 0.0), 0.0,
				{&"seed_value": 40 + index}))
			ring.add_child(standing)
	# Wind-bent highland pines in the corners, and heather banked along the north wall.
	for corner: Vector2 in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
		var spot: Vector3 = BOSS_POSITION + Vector3(corner.x * (half - 2.2), 0.0, corner.y * (half - 2.2))
		ring.add_child(_tree("Pine%s%s" % ["W" if corner.x < 0.0 else "E", "N" if corner.y < 0.0 else "S"], spot, 9.0, true, WorldVisualCatalog.KIT_TREE_HIGHLAND_PINE))
	var heather: Material = WorldVisualCatalog.foliage(Color(0.6, 0.42, 0.64), 1.0, 0.2, 1.0)
	for index: int in 9:
		var x: float = lerpf(-half + 4.0, half - 4.0, float(index) / 8.0)
		ring.add_child(ShapeKit.no_shadow(ShapeKit.stretched(ShapeKit.sphere("Heather%d" % index, 0.7, Vector3(x, 0.15, north + 1.2), heather), Vector3(1.6, 0.5, 1.0))))
	ring.add_child(_mist("Spray", Vector3(0.0, 2.5, north + 1.0), Vector3(half, 1.5, 1.0)))


# --- The seamless world ---------------------------------------------------

## The world scene: just the skeleton (spawning on Bramble-Bridge's green, now
## in Landblock (0, 0)) and the WorldGridManager that streams everything else.
func _build_world() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "EverwoodWorld"
	root.set_script(load(WORLD_SCRIPT))
	root.add_child(_environment(true))
	root.add_child(_sun())
	var grid: Node3D = Node3D.new()
	grid.name = "World"
	grid.set_script(load(GRID_MANAGER_SCRIPT))
	root.add_child(grid)
	_add_level_skeleton(root, HUB_SPAWN_Z, LandblockManifest.BRAMBLEBRIDGE_ORIGIN, false)
	# The party wakes round the Kindle-Fire's campfire, facing up the lane.
	var markers: Array[Node] = root.get_node("SpawnPoints").get_children()
	for index: int in markers.size():
		var marker: Marker3D = markers[index] as Marker3D
		var spot: Vector2 = BIVOUAC_SPAWNS[index]
		marker.position = LandblockManifest.CAMPFIRE_POSITION + Vector3(spot.x, 0.0, spot.y)
		marker.rotation = Vector3(0.0, BIVOUAC_FACING, 0.0)
	return root


## One corridor Landblock's gameplay layer: its zone's content from the classic
## builders, moved to the zone's world origin.
func _build_landblock(chunk: Vector2i) -> Node3D:
	var zone: LandblockManifest.Zone = LandblockManifest.zone_of(chunk)
	var root: Node3D = _node3d("Landblock_%s" % WorldGridConfig.chunk_key(chunk))
	root.position = LandblockManifest.zone_origin(zone)
	root.set_meta(&"chunk", chunk)
	match zone:
		LandblockManifest.Zone.BRAMBLEBRIDGE:
			_build_town(root, true)
		LandblockManifest.Zone.MOSS_OAKS:
			_build_moss_oaks(root, true)
			_build_holloway(root)
			_add_zone_one_entities(root, true)
		LandblockManifest.Zone.GORGE:
			_build_gorge(root)
			root.add_child(_entity(_scripted("CoopGate", GATE_SCRIPT, GATE_POSITION, {&"persist_id": LandblockManifest.SINAYA_GATE})))
		LandblockManifest.Zone.RING:
			_build_ring(root)
			root.add_child(_entity(_boss_spawn()))
		LandblockManifest.Zone.OAKSHIRE_COMMONS:
			_build_oakshire_commons(root)
	return root


# --- The Kindle-Fire and Honey-Wick ---------------------------------------

## Chunk (0, 1), in world coordinates: the campfire where the party wakes, the
## oak and its Wind-Lantern, the walled lane east then north, the homestead,
## the bee-hives and the pumpkin patches.
func _build_oakshire_commons(root: Node3D) -> void:
	var fire: Node3D = _scripted("Campfire", CAMPFIRE_SCRIPT, LandblockManifest.CAMPFIRE_POSITION, {&"persist_id": LandblockManifest.CAMPFIRE})
	root.add_child(_entity(fire))
	var oak: Node3D = _tree("BivouacOak", BIVOUAC_OAK, 9.0, true)
	# Its low limb reaches out over the lane to hold the lantern.
	var limb_start: Vector3 = Vector3(0.0, 3.3, 0.0)
	var limb_end: Vector3 = BIVOUAC_LANTERN - BIVOUAC_OAK + Vector3(0.0, 0.05, 0.0)
	var limb: MeshInstance3D = ShapeKit.cylinder("Limb", 0.1, 0.16, limb_start.distance_to(limb_end) + 0.3, (limb_start + limb_end) * 0.5, _material(OAK_TRUNK_COLOR), 10)
	var along: Vector3 = (limb_end - limb_start).normalized()
	var across: Vector3 = along.cross(Vector3.UP).normalized()
	limb.basis = Basis(across, along, across.cross(along))
	oak.add_child(limb)
	root.add_child(oak)
	root.add_child(_scripted("WindLantern", LANTERN_SCRIPT, BIVOUAC_LANTERN, {}))
	root.add_child(_lane_walls("LaneWalls", WorldGridConfig.CHUNK_SIZE, INF, LandblockManifest.COMMONS_ORIGIN))
	root.add_child(_lane_cobbles("LaneCobbles", WorldGridConfig.CHUNK_SIZE, INF, LandblockManifest.COMMONS_ORIGIN))
	root.add_child(_homestead())
	root.add_child(_bee_hives())
	for index: int in PUMPKIN_PATCHES.size():
		root.add_child(_pumpkin_patch("PumpkinPatch%d" % (index + 1), PUMPKIN_PATCHES[index], index, PUMPKIN_OPEN_SIDES[index]))
	root.add_child(_chime_post("CommonsChimePost", COMMONS_POST, "Honey-Wick"))


## The knee-high dry-stone walls either side of the lane, for the stretch of it
## with world z in [z_min, z_max), placed relative to `origin`. They stand on
## the LowScenery layer (bodies bump into them, cameras see past them), with
## gaps into the yards and a stone post at each bend.
func _lane_walls(walls_name: String, z_min: float, z_max: float, origin: Vector3) -> Node3D:
	var walls: Node3D = _node3d(walls_name)
	var stone: Material = _material(DRYSTONE_COLOR)
	var coping: Material = _material(DRYSTONE_COLOR.darkened(0.15))
	var lane: Array[Vector2] = LandblockManifest.LANE
	var flat_origin: Vector2 = Vector2(origin.x, origin.z)
	var piece_index: int = 0
	for index: int in lane.size() - 1:
		var start: Vector2 = lane[index]
		var finish: Vector2 = lane[index + 1]
		var length: float = start.distance_to(finish)
		var direction: Vector2 = (finish - start) / length
		var side_step: Vector2 = Vector2(-direction.y, direction.x) * LANE_WALL_OFFSET
		var pieces: int = ceili(length / LANE_WALL_PIECE)
		for piece: int in pieces:
			var from: Vector2 = start + direction * length * piece / pieces
			var to: Vector2 = start + direction * length * (piece + 1) / pieces
			var middle_z: float = (from.y + to.y) * 0.5
			if middle_z < z_min or middle_z >= z_max:
				continue
			for side: float in [-1.0, 1.0]:
				var a: Vector2 = from + side_step * side
				var b: Vector2 = to + side_step * side
				var in_gap: bool = false
				for gap: Vector2 in LANE_GAPS:
					in_gap = in_gap or gap.distance_to(Geometry2D.get_closest_point_to_segment(gap, a, b)) < LANE_GAP_HALF
				if in_gap:
					continue
				var wall: StaticBody3D = _wall("LaneWall%d" % piece_index, a - flat_origin, b - flat_origin, LANE_WALL_HEIGHT + 0.1, stone, -0.1, LANE_WALL_THICKNESS)
				wall.add_child(ShapeKit.box("Coping", Vector3(LANE_WALL_THICKNESS + 0.12, 0.08, a.distance_to(b) + LANE_WALL_THICKNESS), Vector3(0.0, (LANE_WALL_HEIGHT + 0.1) * 0.5 + 0.03, 0.0), coping))
				walls.add_child(wall)
				piece_index += 1
	# A stone post on each side of every bend hides the joint.
	for index: int in range(1, lane.size() - 1):
		if lane[index].y < z_min or lane[index].y >= z_max:
			continue
		var before: Vector2 = (lane[index] - lane[index - 1]).normalized()
		var after: Vector2 = (lane[index + 1] - lane[index]).normalized()
		var bend: Vector2 = (before + after).normalized()
		var outward: Vector2 = Vector2(-bend.y, bend.x) * LANE_WALL_OFFSET / maxf(0.5, Vector2(-bend.y, bend.x).dot(Vector2(-before.y, before.x)))
		for side: float in [-1.0, 1.0]:
			var at: Vector2 = lane[index] + outward * side - flat_origin
			walls.add_child(_low(_box_body("LanePost%d%s" % [index, "L" if side > 0.0 else "R"], Vector3(0.7, LANE_WALL_HEIGHT + 0.3, 0.7),
				Vector3(at.x, (LANE_WALL_HEIGHT + 0.3) * 0.5 - 0.1, at.y), stone)))
	return walls


## The lane's cobbles for world z in [z_min, z_max), relative to `origin`:
## flat stones set into the dirt with no colliders, so nothing catches a foot.
func _lane_cobbles(cobbles_name: String, z_min: float, z_max: float, origin: Vector3) -> MultiMeshInstance3D:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1701 + int(z_min)
	var spots: Array[Transform3D] = []
	var colors: PackedColorArray = PackedColorArray()
	var lane: Array[Vector2] = LandblockManifest.LANE
	for index: int in lane.size() - 1:
		var start: Vector2 = lane[index]
		var finish: Vector2 = lane[index + 1]
		var length: float = start.distance_to(finish)
		var direction: Vector2 = (finish - start) / length
		var across: Vector2 = Vector2(-direction.y, direction.x)
		var travelled: float = 0.0
		while travelled < length:
			var middle: Vector2 = start + direction * travelled
			travelled += COBBLE_STEP
			if middle.y < z_min or middle.y >= z_max:
				continue
			for stone: int in 4:
				if rng.randf() > 0.7:
					continue
				var at: Vector2 = middle + across * rng.randf_range(-1.6, 1.6) + direction * rng.randf_range(-0.3, 0.3)
				var size: float = rng.randf_range(0.8, 1.2)
				var basis: Basis = Basis(Vector3.UP, atan2(direction.x, direction.y) + rng.randf_range(-0.4, 0.4)).scaled(Vector3(size, 1.0, size * 0.85))
				spots.append(Transform3D(basis, Vector3(at.x, -0.03, at.y) - origin))
				var shade: float = rng.randf_range(-0.1, 0.1)
				colors.append(COBBLE_COLOR.lightened(shade) if shade > 0.0 else COBBLE_COLOR.darkened(-shade))
	var stone_mesh: BoxMesh = BoxMesh.new()
	stone_mesh.size = Vector3(0.46, 0.08, 0.38)
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = stone_mesh
	multimesh.instance_count = spots.size()
	for index: int in spots.size():
		multimesh.set_instance_transform(index, spots[index])
		multimesh.set_instance_color(index, colors[index])
	var instances: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instances.name = cobbles_name
	instances.multimesh = multimesh
	instances.material_override = LandblockTerrain.material()
	instances.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instances


## Honey-Wick's stepped-gable timber homestead (17 GDD §5.2 kit): lime-wash between
## oak beams, brick stepped gables, a scalloped roof and smoke from its chimney,
## its broad gable and door facing the lane; one box collides.
func _homestead() -> StaticBody3D:
	var size: Vector3 = HOMESTEAD_SIZE
	var house: StaticBody3D = _collider("Homestead", size, HOMESTEAD_POSITION + Vector3(0.0, size.y * 0.5, 0.0))
	house.add_child(WorldKitInstance.make("Kit", WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE, Vector3(0.0, -size.y * 0.5, 0.0), 0.0,
		{&"size": size, &"tint": PLASTER_COLOR, &"accent": ROOF_TINTS[3]}))
	# A cobbled path from the door to the lane.
	var face_x: float = size.x * 0.5 + 0.06
	var eave: float = size.y * 0.5
	for step: int in 7:
		house.add_child(ShapeKit.box("PathStone%d" % step, Vector3(0.7, 0.06, 0.6), Vector3(face_x + 0.8 + step * 1.45, -eave - 0.02, sin(step * 1.3) * 0.25),
			_material(COBBLE_COLOR.darkened(0.05 * (step % 2)))))
	return house


## Seven cedar hives (17 GDD kit_bee_hive) on stands in an arc along the east
## woodline, bowed toward the north with every entrance facing south, and bees about them.
func _bee_hives() -> Node3D:
	var hives: Node3D = _node3d("BeeHives")
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "HiveBodies"
	body.collision_layer = ActorBase.LAYER_LOW_SCENERY
	body.collision_mask = 0
	hives.add_child(body)
	for index: int in HIVE_COUNT:
		var angle: float = lerpf(PI * 0.12, PI * 0.88, float(index) / (HIVE_COUNT - 1))
		var at: Vector3 = Vector3(HIVE_ARC_CENTER.x + cos(angle) * HIVE_ARC_RADIUS, 0.0, HIVE_ARC_CENTER.y - sin(angle) * HIVE_ARC_RADIUS)
		var boxes: int = 2 + index % 2
		hives.add_child(WorldKitInstance.make("Hive%d" % (index + 1), WorldVisualCatalog.KIT_BEE_HIVE, at, 0.0, {&"height": float(boxes)}))
		var top: float = 0.35 + boxes * 0.31
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(0.66, top + 0.1, 0.6)
		shape.shape = box
		shape.position = at + Vector3(0.0, (top + 0.1) * 0.5, 0.0)
		body.add_child(shape)
	hives.add_child(_bees("Bees", Vector3(HIVE_ARC_CENTER.x, 1.0, HIVE_ARC_CENTER.y - HIVE_ARC_RADIUS * 0.6), Vector3(HIVE_ARC_RADIUS, 0.5, HIVE_ARC_RADIUS * 0.5)))
	return hives


## Golden bees looping round their hives.
func _bees(bees_name: String, where: Vector3, extents: Vector3) -> CPUParticles3D:
	var bees: CPUParticles3D = CPUParticles3D.new()
	bees.name = bees_name
	bees.position = where
	bees.amount = 24
	bees.lifetime = 2.5
	bees.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	bees.emission_box_extents = extents
	bees.direction = Vector3(0.0, 0.2, 1.0)
	bees.spread = 180.0
	bees.gravity = Vector3.ZERO
	bees.initial_velocity_min = 0.3
	bees.initial_velocity_max = 0.8
	var bee: SphereMesh = SphereMesh.new()
	bee.radius = 0.03
	bee.height = 0.06
	bee.radial_segments = 4
	bee.rings = 2
	bee.material = WorldVisualCatalog.glowing(Color(0.95, 0.78, 0.2), 0.6)
	bees.mesh = bee
	bees.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return bees


## A patch of tilled soil with ribbed heirloom pumpkins on their vines (17 GDD
## kit_pumpkin_patch), inside knee-high mortared dry-stone walls on the
## LowScenery layer, open on the side toward the lane (`open_side` -1 west, 1 east).
func _pumpkin_patch(patch_name: String, area: Rect2, patch_seed: int, open_side: float = 0.0) -> Node3D:
	var patch: Node3D = _node3d(patch_name)
	patch.position = Vector3(area.get_center().x, 0.0, area.get_center().y)
	patch.add_child(WorldKitInstance.make("Pumpkins", WorldVisualCatalog.KIT_PUMPKIN_PATCH, Vector3.ZERO, 0.0,
		{&"size": Vector3(area.size.x, 0.8, area.size.y), &"seed_value": patch_seed}))
	if open_side == 0.0:
		return patch
	var half: Vector2 = area.size * 0.5 + Vector2(0.5, 0.5)
	var sides: Array[Array] = [[Vector2(-half.x, -half.y), Vector2(half.x, -half.y)], [Vector2(-half.x, half.y), Vector2(half.x, half.y)],
		[Vector2(-open_side * half.x, -half.y), Vector2(-open_side * half.x, half.y)]]
	for index: int in sides.size():
		var from: Vector2 = sides[index][0]
		var to: Vector2 = sides[index][1]
		var length: float = from.distance_to(to)
		var wall: StaticBody3D = _low(_collider("Wall%d" % index, Vector3(0.5, 0.8, length), Vector3((from.x + to.x) * 0.5, 0.4, (from.y + to.y) * 0.5),
			ActorBase.LAYER_LOW_SCENERY))
		wall.rotation.y = atan2(to.x - from.x, to.y - from.y)
		wall.add_child(WorldKitInstance.make("Stones", WorldVisualCatalog.KIT_DRYSTONE_WALL, Vector3(0.0, -0.4, 0.0), PI * 0.5,
			{&"size": Vector3(length, 0.8, 0.5), &"seed_value": index + patch_seed * 3}))
		patch.add_child(wall)
	return patch


## Marks a node as a Landblock entity (bound to WorldStateDB and announced to the level when it streams in).
func _entity(node: Node3D) -> Node3D:
	node.add_to_group(WorldGridManager.ENTITY_GROUP, true)
	return node


## Bakes a Landblock's HLOD proxy: every shape at least HLOD_MIN_SIZE long
## (walls, roofs, towers, trees, the wheel; scripted things built in their
## _ready too) merged into one vertex-coloured mesh in world space. The
## Landblock is put in the tree for a moment so its scripts build their looks.
func _bake_hlod(landblock: Node3D, path: String) -> Error:
	get_root().add_child(landblock)
	var merge: LandblockTerrain.MeshMerge = LandblockTerrain.MeshMerge.new()
	# Kits stand in as their low-poly silhouettes (17 GDD §6.1 Ring 2: merged rooflines, simple crowns).
	var stand_ins: Array[Node] = []
	for node: Node in landblock.find_children("*", "Node3D", true, false):
		var placed: WorldKitInstance = node as WorldKitInstance
		if placed == null or not placed.is_visible_in_tree():
			continue
		var parts: WorldAssetCatalog.Parts = WorldAssetCatalog.Parts.new()
		if not WorldAssetCatalog.hlod_parts(placed.kit_id, placed.options(), parts):
			continue
		stand_ins.append(placed)
		_merge_surfaces(merge, parts.commit(), placed.global_transform)
	for node: Node in landblock.find_children("*", "MeshInstance3D", true, false):
		var shape: MeshInstance3D = node as MeshInstance3D
		if shape.mesh == null or not shape.is_visible_in_tree() or _inside_any(shape, stand_ins):
			continue
		var box: AABB = shape.global_transform * shape.mesh.get_aabb()
		if box.get_longest_axis_size() < HLOD_MIN_SIZE:
			continue
		var primitive: PrimitiveMesh = _low_poly(shape.mesh as PrimitiveMesh)
		if primitive != null:
			merge.add_arrays(primitive.get_mesh_arrays(), shape.global_transform, _hlod_color(shape))
			continue
		# Any other detailed mesh (a station's kit, a wheel): each surface as its bounding box.
		for surface: int in shape.mesh.get_surface_count():
			var arrays: Array = shape.mesh.surface_get_arrays(surface)
			if arrays.is_empty():
				continue
			var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			if points.size() <= HLOD_DETAILED_VERTICES:
				merge.add_arrays(arrays, shape.global_transform, _hlod_color(shape, surface, arrays))
				continue
			var bounds: AABB = AABB(points[0], Vector3.ZERO)
			for point: Vector3 in points:
				bounds = bounds.expand(point)
			var cube: BoxMesh = BoxMesh.new()
			cube.size = bounds.size
			merge.add_arrays(cube.get_mesh_arrays(), shape.global_transform * Transform3D(Basis.IDENTITY, bounds.get_center()), _hlod_color(shape, surface, arrays))
	get_root().remove_child(landblock)
	landblock.free()
	return ResourceSaver.save(merge.commit(), path)


## A stand-in's surfaces into the merge, each in its painted colour.
func _merge_surfaces(merge: LandblockTerrain.MeshMerge, mesh: ArrayMesh, where: Transform3D) -> void:
	for surface: int in mesh.get_surface_count():
		var material: ShaderMaterial = mesh.surface_get_material(surface) as ShaderMaterial
		var tint: Color = material.get_shader_parameter(&"albedo") if material != null else STONE_COLOR
		merge.add_arrays(mesh.surface_get_arrays(surface), where, Color(tint, 1.0))


func _inside_any(node: Node, roots: Array[Node]) -> bool:
	for root: Node in roots:
		if root == node or root.is_ancestor_of(node):
			return true
	return false


## A far-off copy of a round shape: a few sides is plenty at HLOD distance.
func _low_poly(primitive: PrimitiveMesh) -> PrimitiveMesh:
	if primitive == null:
		return null
	var copy: PrimitiveMesh = primitive.duplicate() as PrimitiveMesh
	var sphere: SphereMesh = copy as SphereMesh
	if sphere != null:
		sphere.radial_segments = 8
		sphere.rings = 4
	var cylinder: CylinderMesh = copy as CylinderMesh
	if cylinder != null:
		cylinder.radial_segments = 8
		cylinder.rings = 0
	var capsule: CapsuleMesh = copy as CapsuleMesh
	if capsule != null:
		capsule.radial_segments = 8
		capsule.rings = 2
	var torus: TorusMesh = copy as TorusMesh
	if torus != null:
		torus.rings = 8
		torus.ring_segments = 6
	return copy


## A shape's colour for the HLOD: its material's albedo (times its vertex
## colours, on leaves), a plain material's colour, or stone.
func _hlod_color(shape: MeshInstance3D, surface: int = 0, arrays: Array = []) -> Color:
	var material: Material = shape.material_override
	if material == null:
		var primitive: PrimitiveMesh = shape.mesh as PrimitiveMesh
		material = primitive.material if primitive != null else shape.mesh.surface_get_material(surface)
	var tint: Color = STONE_COLOR
	var cel: ShaderMaterial = material as ShaderMaterial
	var standard: BaseMaterial3D = material as BaseMaterial3D
	if cel != null:
		for parameter: StringName in [&"albedo", &"base_color", &"shallow_color"]:
			var value: Variant = cel.get_shader_parameter(parameter)
			if value is Color:
				tint = Color(value as Color, 1.0)
				break
	elif standard != null:
		tint = Color(standard.albedo_color, 1.0)
	if cel != null and cel.shader == WorldVisualCatalog.FOLIAGE_SHADER and arrays.size() > Mesh.ARRAY_COLOR and arrays[Mesh.ARRAY_COLOR] != null:
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		var sum: Color = Color(0.0, 0.0, 0.0)
		for color: Color in colors:
			sum += color
		if not colors.is_empty():
			tint *= sum / float(colors.size())
	return tint


# --- Expedition helpers ---------------------------------------------------

## A level's scripted node, its exported values set (camps, the shrine, lanterns, the gate).
func _scripted(node_name: String, script_path: String, where: Vector3, values: Dictionary) -> Node3D:
	var node: Node3D = Node3D.new()
	node.name = node_name
	node.set_script(load(script_path))
	node.position = where
	for key: Variant in values:
		node.set(key, values[key])
	return node


## A slab of walkable ground between two XZ corners, its top at `top_y`.
func _ground(ground_name: String, corner_min: Vector2, corner_max: Vector2, top_y: float, material: Material) -> StaticBody3D:
	var size: Vector2 = corner_max - corner_min
	var middle: Vector2 = (corner_min + corner_max) * 0.5
	return _box_body(ground_name, Vector3(size.x, FLOOR_THICKNESS, size.y), Vector3(middle.x, top_y - FLOOR_THICKNESS * 0.5, middle.y), material)


## A wall from one XZ point to another, standing on `base_y`.
func _wall(wall_name: String, from: Vector2, to: Vector2, height: float, material: Material, base_y: float = 0.0, thickness: float = WALL_THICKNESS) -> StaticBody3D:
	var length: float = from.distance_to(to) + thickness
	var middle: Vector2 = (from + to) * 0.5
	var body: StaticBody3D = _box_body(wall_name, Vector3(thickness, height, length), Vector3(middle.x, base_y + height * 0.5, middle.y), material)
	body.rotation = Vector3(0.0, atan2(to.x - from.x, to.y - from.y), 0.0)
	return _low(body) if height <= LOW_WALL_HEIGHT else body


## Makes a body knee-high scenery: bodies bump into it, cameras see past it.
func _low(body: StaticBody3D) -> StaticBody3D:
	body.collision_layer = ActorBase.LAYER_LOW_SCENERY
	return body


## A walkable ramp across the full width (`half_width` each side of x = 0),
## from height `from_y` at `from_z` to `to_y` at `to_z`: one convex collider,
## flush with the ground at both ends.
func _ramp(ramp_name: String, half_width: float, from_z: float, from_y: float, to_z: float, to_y: float, material: Material) -> StaticBody3D:
	var bottom: float = minf(from_y, to_y) - 0.5
	var profile: PackedVector2Array = PackedVector2Array([Vector2(from_z, from_y), Vector2(to_z, to_y), Vector2(to_z, bottom), Vector2(from_z, bottom)])
	var body: StaticBody3D = StaticBody3D.new()
	body.name = ramp_name
	body.collision_layer = ActorBase.LAYER_WORLD
	body.collision_mask = 0
	var points: PackedVector3Array = PackedVector3Array()
	for side: float in [-1.0, 1.0]:
		for point: Vector2 in profile:
			points.append(Vector3(side * half_width, point.y, point.x))
	var shape: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	shape.points = points
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	body.add_child(collision)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "Mesh"
	mesh.mesh = _prism_mesh(profile, half_width * 2.0)
	mesh.material_override = WorldVisualCatalog.double_sided(material)
	body.add_child(mesh)
	return body


## A round beam from one point to another (roots, boughs).
func _beam(beam_name: String, from: Vector3, to: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var beam: MeshInstance3D = ShapeKit.cylinder(beam_name, radius * 0.8, radius, from.distance_to(to), Vector3(0.0, 0.0, 0.0), material, 24)
	var up: Vector3 = (to - from).normalized()
	var side: Vector3 = up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	beam.transform = Transform3D(Basis(side, up, side.cross(up)), (from + to) * 0.5)
	return beam


## Drifting white mist (the waterfall's foot and spray).
func _mist(mist_name: String, where: Vector3, extents: Vector3) -> CPUParticles3D:
	var mist: CPUParticles3D = CPUParticles3D.new()
	mist.name = mist_name
	mist.position = where
	mist.amount = 24
	mist.lifetime = 3.0
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	mist.emission_box_extents = extents
	mist.direction = Vector3.UP
	mist.spread = 40.0
	mist.initial_velocity_min = 0.3
	mist.initial_velocity_max = 0.9
	mist.gravity = Vector3(0.0, 0.2, 0.0)
	mist.scale_amount_min = 1.0
	mist.scale_amount_max = 2.2
	var puff: SphereMesh = SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	var puff_material: StandardMaterial3D = StandardMaterial3D.new()
	puff_material.albedo_color = Color(0.92, 0.97, 1.0, 0.3)
	puff_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = puff_material
	mist.mesh = puff
	return mist


# --- Shared pieces --------------------------------------------------------

## Spawn pads, the runtime folders and the split-screen layer every level has.
func _add_level_skeleton(root: Node3D, spawn_z: float, offset: Vector3 = Vector3.ZERO, pads: bool = true) -> void:
	var spawns: Node3D = _node3d("SpawnPoints")
	root.add_child(spawns)
	for index: int in 4:
		var marker: Marker3D = Marker3D.new()
		marker.name = "Spawn%d" % (index + 1)
		marker.position = offset + Vector3((float(index) - 1.5) * SPAWN_SPACING, 0.0, spawn_z)
		if pads:
			marker.add_child(_pad("Pad", 0.8, SPAWN_PAD_COLORS[index]))
		spawns.add_child(marker)
	root.add_child(_node3d("Actors"))
	root.add_child(_node3d("Telegraphs"))
	root.add_child(_node3d("Effects"))
	var screens: CanvasLayer = CanvasLayer.new()
	screens.name = "Screens"
	root.add_child(screens)
	var grid: Control = Control.new()
	grid.name = "Grid"
	grid.set_script(load(GRID_SCRIPT))
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screens.add_child(grid)
	var banner: Label = Label.new()
	banner.name = "Banner"
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.offset_top = 6.0
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override(&"font_size", 15)
	banner.add_theme_color_override(&"font_outline_color", Color.BLACK)
	banner.add_theme_constant_override(&"outline_size", 6)
	banner.modulate = Color(1.0, 1.0, 1.0, 0.85)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screens.add_child(banner)


func _portal(portal_name: String, target: StringName, title: String, color: Color, where: Vector3) -> Node3D:
	var portal: Node3D = Node3D.new()
	portal.name = portal_name
	portal.set_script(load(PORTAL_SCRIPT))
	portal.set(&"target_instance", target)
	portal.set(&"title", title)
	portal.set(&"portal_color", color)
	portal.position = where
	return portal


## The Wayfarer's map listing (18 GDD §7.1): every building's footprint
## (x, z, width, depth, yaw, road) and every Hush-Crack (its id, where, its
## chunk and its camp's persist id) under a landblock's `root`.
func _record_cartography(root: Node3D, into: Dictionary) -> void:
	for node: Node in root.find_children("*", "", true, false):
		var where: Transform3D = _world_transform(node, root)
		var placed: WorldKitInstance = node as WorldKitInstance
		if placed != null:
			var footprint: PackedFloat32Array = CartographyBaker.footprint_of(placed, where)
			if not footprint.is_empty():
				(into["footprints"] as Array).append(Array(footprint))
			continue
		var crack_id: StringName = &""
		var persist: StringName = &""
		var camp: MinionCamp = node as MinionCamp
		var spawner: MobSpawner = node as MobSpawner
		if camp != null:
			persist = camp.persist_id
			crack_id = persist if persist != &"" else StringName(String(camp.name).to_snake_case())
		elif spawner != null and spawner.has_hush_crack:
			crack_id = StringName(String(spawner.name).to_snake_case())
		if crack_id != &"":
			var chunk: Vector2i = WorldGridConfig.world_to_chunk(where.origin)
			(into["cracks"] as Array).append({"id": String(crack_id), "x": snappedf(where.origin.x, 0.01), "z": snappedf(where.origin.z, 0.01),
				"chunk": [chunk.x, chunk.y], "persist": String(persist)})


## A node's transform in the world, from its landblock `root` down (nothing here is in the tree yet).
func _world_transform(node: Node, root: Node3D) -> Transform3D:
	var where: Transform3D = Transform3D.IDENTITY
	var at: Node = node
	while at != null:
		var spatial: Node3D = at as Node3D
		if spatial != null:
			where = spatial.transform * where
		if at == root:
			break
		at = at.get_parent()
	return where


func _save_cartography(listing: Dictionary, path: String) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	for key: String in ["footprints", "cracks"]:
		(listing[key] as Array).sort_custom(func(a: Variant, b: Variant) -> bool: return var_to_str(a) < var_to_str(b))
	file.store_string(JSON.stringify(listing, "\t"))
	file.close()
	return OK


func _save(root: Node, path: String) -> Error:
	_own_all(root, root)
	var packed: PackedScene = PackedScene.new()
	var error: Error = packed.pack(root)
	if error == OK:
		error = ResourceSaver.save(packed, path)
	root.free()
	return error


func _own_all(node: Node, scene_root: Node) -> void:
	for child: Node in node.get_children():
		child.owner = scene_root
		_own_all(child, scene_root)


func _node3d(node_name: String) -> Node3D:
	var node: Node3D = Node3D.new()
	node.name = node_name
	return node


## Scenery in the storybook look (07 GDD §4.2), crafted by the atelier (17 GDD §3.2):
## the colour says which craft it is (limestone, brick, lime-wash, timber, granite, loam or turf).
func _material(color: Color) -> Material:
	return WorldVisualCatalog.craft_for_color(color)


## For what glows or shines (windows, lanterns, water): a plain material to light up.
func _standard(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material


func _box_body(body_name: String, size: Vector3, where: Vector3, material: Material) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = body_name
	body.position = where
	body.collision_layer = ActorBase.LAYER_WORLD
	body.collision_mask = 0
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	body.add_child(collision)
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = "Mesh"
	visual.mesh = mesh
	body.add_child(visual)
	return body


func _pillar(body_name: String, where: Vector3, material: Material) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = body_name
	body.position = where + Vector3(0.0, PILLAR_HEIGHT * 0.5, 0.0)
	body.collision_layer = ActorBase.LAYER_WORLD
	body.collision_mask = 0
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = PILLAR_RADIUS
	shape.height = PILLAR_HEIGHT
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	body.add_child(collision)
	var visual: MeshInstance3D = ShapeKit.cylinder("Mesh", PILLAR_RADIUS * 0.9, PILLAR_RADIUS, PILLAR_HEIGHT, Vector3(0.0, 0.0, 0.0), material, 24)
	body.add_child(visual)
	return body


func _pad(pad_name: String, radius: float, color: Color) -> MeshInstance3D:
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.04
	disc.radial_segments = 32
	disc.material = WorldVisualCatalog.painted(color)
	var pad: MeshInstance3D = MeshInstance3D.new()
	pad.name = pad_name
	pad.mesh = disc
	pad.position = Vector3(0.0, 0.02, 0.0)
	return pad


## A dim dungeon sky for raids; a bright day for the town.
func _environment(daylight: bool) -> WorldEnvironment:
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	if daylight:
		# A warm, sunlit storybook day (07 GDD §4.2): beyond the walls the world
		# fades to meadow rather than black.
		sky_material.sky_top_color = Color(0.36, 0.56, 0.84)
		sky_material.sky_horizon_color = Color(0.82, 0.84, 0.8)
		sky_material.ground_horizon_color = Color(0.62, 0.66, 0.5)
		sky_material.ground_bottom_color = Color(0.36, 0.42, 0.28)
	else:
		sky_material.sky_top_color = Color(0.16, 0.2, 0.3)
		sky_material.sky_horizon_color = Color(0.45, 0.47, 0.52)
		sky_material.ground_horizon_color = Color(0.3, 0.3, 0.32)
		sky_material.ground_bottom_color = Color(0.12, 0.12, 0.14)
	var sky: Sky = Sky.new()
	sky.sky_material = sky_material
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	if daylight:
		# A steady warm fill, so the bright meadow below the horizon doesn't wash the scene out.
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color(0.62, 0.62, 0.7)
		environment.ambient_light_energy = 0.45
	else:
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		environment.ambient_light_energy = 0.8
	# Filmic keeps the toon bands' sunlit colours rich (ACES washed them out to pastel).
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.6
	if daylight:
		# A light warm haze gives distance and keeps far scenery from competing with the fight.
		environment.fog_enabled = true
		environment.fog_light_color = Color(0.86, 0.84, 0.76)
		environment.fog_density = 0.0035
		environment.fog_sky_affect = 0.15
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = environment
	return world_environment


func _sun() -> DirectionalLight3D:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(35.0), 0.0)
	sun.light_energy = 0.95
	sun.light_color = Color(1.0, 0.93, 0.8)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	return sun
