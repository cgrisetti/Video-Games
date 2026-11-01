## Builds the instance scenes from code (Code-First Scene Safety), so nobody
## hand-edits their sub-resources. Re-run after changing anything here:
##   godot --headless --path . --script res://tools/build_levels.gd
##
## - Bramblebridge (hub_town.tscn, 07 GDD §1.1): a walled canal village. The
##   spawn green and its fountain in the south; the canal across the middle,
##   crossed by the low stone arch the village is named for (walkable ramps,
##   no jump needed) and turning a watermill; the village square in the north
##   with the Armory & Scribe Desk, the Chime-Shrine, a bakery and pigment
##   racks among stepped-gable houses; and the Raid Portal at the forest gate.
## - The Doverslap Expedition (dungeon_dojo.tscn, 07 GDD §3): Zone 1, the
##   Ariundle Moss-Oaks (a walled clearing, a bramble camp, a side alcove with
##   the Wayfarer's Chest) and the Sunken Holloway (a lane between earthen banks
##   under root arches and Wind-Lanterns, the Water-Shrine, the imp camp);
##   Zone 2, the Doverslap Gorge Bridge with its waterfall and paper-mill wheel,
##   and the Sinaya Gatehouse with its Co-Op Threshold; Zone 3, a causeway into
##   the Ring of the Cairnsman, six pillars round the boss.
## Both share the same skeleton (Actors, Telegraphs, Effects, SpawnPoints and
## the split-screen Screens), which LevelBase expects.
extends SceneTree

const HUB_PATH: String = "res://src/levels/hub_town.tscn"
const DOJO_PATH: String = "res://src/levels/dungeon_dojo.tscn"
const HUB_SCRIPT: String = "res://src/levels/hub_town.gd"
const DOJO_SCRIPT: String = "res://src/levels/dungeon_dojo.gd"
const PORTAL_SCRIPT: String = "res://src/actors/raid_portal.gd"
const SHRINE_SCRIPT: String = "res://src/actors/chime_shrine.gd"
const WHEEL_SCRIPT: String = "res://src/actors/watermill_wheel.gd"
const DESK_SCRIPT: String = "res://src/actors/scribe_desk.gd"
const CAMP_SCRIPT: String = "res://src/actors/minion_camp.gd"
const SHRINE_WATER_SCRIPT: String = "res://src/actors/water_shrine.gd"
const LANTERN_SCRIPT: String = "res://src/actors/wind_lantern.gd"
const GATE_SCRIPT: String = "res://src/actors/coop_gate.gd"
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

# The Doverslap Expedition (dungeon_dojo.tscn, 07_EXPEDITION_HUD_AND_ART_GDD.md
# §3). North is -Z: you arrive among the Ariundle Moss-Oaks in the south, go
# down the Sunken Holloway, over the Doverslap Gorge Bridge, through the Sinaya
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
# Zone 1: the Ariundle Moss-Oaks clearing (x and z bounds).
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
## The deer-run alcove beyond a gap in the west wall, behind dry-stone walls.
const ALCOVE_MIN: Vector2 = Vector2(-32.0, 50.0)
const ALCOVE_MAX: Vector2 = Vector2(-24.0, 56.0)
const WAYFARER_CHEST_POSITION: Vector3 = Vector3(-29.5, 0.0, 53.0)
# The Sunken Holloway: a lane between earthen banks, six feet down.
const HOLLOWAY_HALF_WIDTH: float = 4.0
const HOLLOWAY_DEPTH: float = 1.8
const HOLLOWAY_TOP_Z: float = 46.0
const HOLLOWAY_FLOOR_START_Z: float = 38.0
const HOLLOWAY_FLOOR_END_Z: float = 22.0
const HOLLOWAY_EXIT_Z: float = 14.0
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
# Zone 2: the Doverslap Gorge Bridge and the Sinaya Gatehouse.
const CLIFF_HALF_WIDTH: float = 16.0
const SOUTH_CLIFF_Z: Vector2 = Vector2(6.0, 14.0)
const NORTH_CLIFF_Z: Vector2 = Vector2(-24.0, -12.0)
const GORGE_BRIDGE_HALF_WIDTH: float = 3.0
## The bridge's side bays, where the Rune-Plates sit (z range, and how far they reach out).
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
const MILLWHEEL_SCALE: float = 2.3
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

# Bramblebridge (07_EXPEDITION_HUD_AND_ART_GDD.md §1.1). North is -Z: the
# spawn green in the south, the canal across the middle with the bridge over
# it, and the village square and the forest gate in the north. Nothing needs
# a jump: Space is the dodge roll.
const HUB_WIDTH: float = 44.0
const HUB_DEPTH: float = 60.0
const HUB_SPAWN_Z: float = 22.0
## In front of the forest gate, well past the square, so nobody wanders into it.
const RAID_PORTAL_POSITION: Vector3 = Vector3(0.0, 0.0, -25.0)
const RAID_PORTAL_COLOR: Color = Color(0.55, 0.5, 1.0)
## The forest gate: an opening in the north wall, framed in timber.
const GATE_WIDTH: float = 6.0
const GATE_HEIGHT: float = 5.0
const GATE_COLOR: Color = Color(0.42, 0.29, 0.18)
## Oaks of the Ariundle Moss-Oaks beyond the north wall, seen through the gate.
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
const PIGMENT_COLORS: Array[Color] = [Color(0.95, 0.68, 0.15), Color(0.72, 0.2, 0.18), Color(0.2, 0.32, 0.7), Color(0.75, 0.78, 0.25),
	Color(0.5, 0.3, 0.62)]
## The canal runs east-west across the village. Knee-high stone banks keep
## walkers out of the water everywhere but the bridge.
const CANAL_Z: float = 0.0
const CANAL_WIDTH: float = 3.6
const CANAL_BANK_HEIGHT: float = 0.55
const CANAL_BANK_THICKNESS: float = 0.4
const WATER_COLOR: Color = Color(0.25, 0.5, 0.75)
## Bramblebridge itself: a low stone arch over the canal. Each ramp climbs
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
const OAK_TRUNK_COLOR: Color = Color(0.36, 0.26, 0.18)
const OAK_LEAF_COLOR: Color = Color(0.28, 0.46, 0.25)
const MOSS_COLOR: Color = Color(0.36, 0.5, 0.26)


func _initialize() -> void:
	var results: PackedStringArray = PackedStringArray()
	results.append("%s -> %s" % [HUB_PATH, error_string(_save(_build_hub(), HUB_PATH))])
	results.append("%s -> %s" % [DOJO_PATH, error_string(_save(_build_dojo(), DOJO_PATH))])
	print("build_levels: " + ", ".join(results))
	quit(0 if not ", ".join(results).contains("rror") else 1)


# --- Bramblebridge --------------------------------------------------------

func _build_hub() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "HubTown"
	root.set_script(load(HUB_SCRIPT))
	root.add_child(_environment(true))
	root.add_child(_sun())
	var town: Node3D = _node3d("Town")
	root.add_child(town)
	var cobbles: ShaderMaterial = ShaderMaterial.new()
	cobbles.shader = load(GRID_SHADER)
	cobbles.set_shader_parameter(&"base_color", Color(0.55, 0.52, 0.47))
	cobbles.set_shader_parameter(&"minor_color", Color(0.5, 0.47, 0.42))
	cobbles.set_shader_parameter(&"major_color", Color(0.45, 0.42, 0.38))
	town.add_child(_box_body("Floor", Vector3(HUB_WIDTH, FLOOR_THICKNESS, HUB_DEPTH), Vector3(0.0, -FLOOR_THICKNESS * 0.5, 0.0), cobbles))
	_add_hub_walls(town)
	_add_forest_gate(town)
	for index: int in HOUSE_SPOTS.size():
		town.add_child(_house("House%d" % (index + 1), HOUSE_SPOTS[index], HOUSE_COLORS[index], index == BAKERY_HOUSE))
	town.add_child(_fountain())
	for index: int in LANTERN_SPOTS.size():
		town.add_child(_lantern("Lantern%d" % (index + 1), LANTERN_SPOTS[index]))
	_add_canal(town)
	_add_bridge(town)
	_add_watermill(town)
	_add_pigment_rack(town)
	root.add_child(_portal("RaidPortal", InstanceManager.DUNGEON_DOJO, "Raid: The Ring of the Cairnsman", RAID_PORTAL_COLOR, RAID_PORTAL_POSITION))
	var shrine: Node3D = Node3D.new()
	shrine.name = "ChimeShrine"
	shrine.set_script(load(SHRINE_SCRIPT))
	shrine.position = SHRINE_POSITION
	# Its front (local -Z) turned to face west, toward the lane.
	shrine.rotation = Vector3(0.0, PI * 0.5, 0.0)
	root.add_child(shrine)
	var desk: Node3D = Node3D.new()
	desk.name = "ScribeDesk"
	desk.set_script(load(DESK_SCRIPT))
	desk.position = DESK_POSITION
	# Its front (local -Z) turned to face east, toward the lane.
	desk.rotation = Vector3(0.0, -PI * 0.5, 0.0)
	root.add_child(desk)
	_add_level_skeleton(root, HUB_SPAWN_Z)
	return root


## The village wall, with the forest gate's opening in the north side.
func _add_hub_walls(parent: Node3D) -> void:
	var half_width: float = HUB_WIDTH * 0.5
	var half_depth: float = HUB_DEPTH * 0.5
	var stone: Material = _material(WALL_COLOR)
	parent.add_child(_low(_box_body("WallSouth", Vector3(HUB_WIDTH, WALL_HEIGHT, WALL_THICKNESS), Vector3(0.0, WALL_HEIGHT * 0.5, half_depth), stone)))
	parent.add_child(_low(_box_body("WallWest", Vector3(WALL_THICKNESS, WALL_HEIGHT, HUB_DEPTH), Vector3(-half_width, WALL_HEIGHT * 0.5, 0.0), stone)))
	parent.add_child(_low(_box_body("WallEast", Vector3(WALL_THICKNESS, WALL_HEIGHT, HUB_DEPTH), Vector3(half_width, WALL_HEIGHT * 0.5, 0.0), stone)))
	var side_length: float = half_width - GATE_WIDTH * 0.5
	for side: float in [-1.0, 1.0]:
		parent.add_child(_low(_box_body("WallNorth%s" % ("West" if side < 0.0 else "East"), Vector3(side_length, WALL_HEIGHT, WALL_THICKNESS),
			Vector3(side * (GATE_WIDTH * 0.5 + side_length * 0.5), WALL_HEIGHT * 0.5, -half_depth), stone)))


## The timber gate out to the Ariundle Moss-Oaks, behind the Raid Portal: you
## see the oaks through it, but the way out is the portal.
func _add_forest_gate(parent: Node3D) -> void:
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
	roof_mesh.material = _material(ROOF_COLOR)
	var roof: MeshInstance3D = MeshInstance3D.new()
	roof.name = "Roof"
	roof.mesh = roof_mesh
	roof.position = Vector3(0.0, GATE_HEIGHT + 0.85, 0.0)
	gate.add_child(roof)
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
	sign_label.text = "To the Ariundle Moss-Oaks"
	sign_label.font_size = 48
	sign_label.outline_size = 10
	sign_label.pixel_size = 0.01
	sign_label.modulate = Color(1.0, 0.92, 0.75)
	sign_label.position = Vector3(0.0, GATE_HEIGHT - 0.6, 0.45)
	gate.add_child(sign_label)
	# The edge of the forest beyond the wall.
	var forest: Node3D = _node3d("ForestEdge")
	parent.add_child(forest)
	forest.add_child(ShapeKit.box("Moss", Vector3(HUB_WIDTH * 0.7, 0.1, 16.0), Vector3(0.0, -0.05, -half_depth - 8.0), _material(MOSS_COLOR)))
	for index: int in GATE_TREES.size():
		forest.add_child(_tree("Oak%d" % (index + 1), GATE_TREES[index], 7.0 + float(index % 3), false))


func _house(house_name: String, where: Vector3, color: Color, bakery: bool) -> StaticBody3D:
	var house: StaticBody3D = _box_body(house_name, HOUSE_SIZE, where + Vector3(0.0, HOUSE_SIZE.y * 0.5, 0.0), _material(color))
	var eave: float = HOUSE_SIZE.y * 0.5
	# A steep roof whose ridge runs toward the lane...
	var roof_mesh: PrismMesh = PrismMesh.new()
	roof_mesh.size = Vector3(HOUSE_SIZE.z + 0.4, ROOF_HEIGHT, HOUSE_SIZE.x - GABLE_THICKNESS * 2.0)
	roof_mesh.material = _material(ROOF_COLOR)
	var roof: MeshInstance3D = MeshInstance3D.new()
	roof.name = "Roof"
	roof.mesh = roof_mesh
	roof.position = Vector3(0.0, eave + ROOF_HEIGHT * 0.5, 0.0)
	roof.rotation = Vector3(0.0, PI * 0.5, 0.0)
	house.add_child(roof)
	# ...between two stepped gables.
	var gable: Material = _material(color.darkened(0.08))
	for side: float in [-1.0, 1.0]:
		for step: int in GABLE_STEPS:
			var width: float = HOUSE_SIZE.z * (1.0 - float(step) / GABLE_STEPS)
			var block: MeshInstance3D = MeshInstance3D.new()
			block.name = "Gable%s%d" % ["East" if side > 0.0 else "West", step]
			var block_mesh: BoxMesh = BoxMesh.new()
			block_mesh.size = Vector3(GABLE_THICKNESS, GABLE_STEP_HEIGHT, width)
			block_mesh.material = gable
			block.mesh = block_mesh
			block.position = Vector3(side * (HOUSE_SIZE.x * 0.5 - GABLE_THICKNESS * 0.5), eave + GABLE_STEP_HEIGHT * (step + 0.5), 0.0)
			house.add_child(block)
	var door_mesh: BoxMesh = BoxMesh.new()
	door_mesh.size = Vector3(1.1, 2.0, 0.1)
	door_mesh.material = _material(Color(0.35, 0.24, 0.16))
	var door: MeshInstance3D = MeshInstance3D.new()
	door.name = "Door"
	door.mesh = door_mesh
	# Doors face the lane down the middle of the village.
	var toward_middle: float = -signf(where.x)
	door.position = Vector3(toward_middle * (HOUSE_SIZE.x * 0.5 + 0.05), -HOUSE_SIZE.y * 0.5 + 1.0, 0.0)
	door.rotation = Vector3(0.0, PI * 0.5, 0.0)
	house.add_child(door)
	# Warm windows either side of the door and one up in the gable.
	var glass: StandardMaterial3D = _standard(WINDOW_COLOR)
	glass.emission_enabled = true
	glass.emission = WINDOW_COLOR
	glass.emission_energy_multiplier = 0.8
	var face_x: float = toward_middle * (HOUSE_SIZE.x * 0.5 + 0.05)
	var window_spots: Array[Vector3] = [Vector3(face_x, 0.4, -1.5), Vector3(face_x, 0.4, 1.5), Vector3(face_x, eave + 0.75, 0.0)]
	for index: int in window_spots.size():
		var window_mesh: BoxMesh = BoxMesh.new()
		window_mesh.size = WINDOW_SIZE
		window_mesh.material = glass
		var window: MeshInstance3D = MeshInstance3D.new()
		window.name = "Window%d" % index
		window.mesh = window_mesh
		window.position = window_spots[index]
		house.add_child(window)
	if bakery:
		_add_bakery(house, toward_middle)
	return house


## The bakery's brick oven against its lane side, and smoke puffing from the chimney.
func _add_bakery(house: StaticBody3D, toward_middle: float) -> void:
	var brick: Material = _material(Color(0.62, 0.34, 0.26))
	var oven_x: float = toward_middle * (HOUSE_SIZE.x * 0.5 + 0.55)
	house.add_child(ShapeKit.box("Oven", Vector3(1.0, 1.1, 1.4), Vector3(oven_x, -HOUSE_SIZE.y * 0.5 + 0.55, -HOUSE_SIZE.z * 0.25), brick))
	var mouth: StandardMaterial3D = _standard(Color(1.0, 0.55, 0.2))
	mouth.emission_enabled = true
	mouth.emission = Color(1.0, 0.5, 0.15)
	mouth.emission_energy_multiplier = 2.0
	house.add_child(ShapeKit.box("OvenFire", Vector3(0.06, 0.4, 0.6), Vector3(oven_x + toward_middle * 0.5, -HOUSE_SIZE.y * 0.5 + 0.45, -HOUSE_SIZE.z * 0.25), mouth))
	var chimney_top: float = HOUSE_SIZE.y * 0.5 + ROOF_HEIGHT + 0.4
	house.add_child(ShapeKit.box("Chimney", Vector3(0.6, 1.6, 0.6), Vector3(-toward_middle * 1.2, chimney_top - 0.8, -HOUSE_SIZE.z * 0.25), brick))
	var smoke: CPUParticles3D = CPUParticles3D.new()
	smoke.name = "Smoke"
	smoke.position = Vector3(-toward_middle * 1.2, chimney_top + 0.1, -HOUSE_SIZE.z * 0.25)
	smoke.amount = 10
	smoke.lifetime = 3.2
	smoke.direction = Vector3.UP
	smoke.spread = 12.0
	smoke.initial_velocity_min = 0.5
	smoke.initial_velocity_max = 0.8
	smoke.gravity = Vector3(0.25, 0.15, 0.0)
	smoke.scale_amount_min = 0.6
	smoke.scale_amount_max = 1.4
	var puff: SphereMesh = SphereMesh.new()
	puff.radius = 0.28
	puff.height = 0.56
	var puff_material: StandardMaterial3D = StandardMaterial3D.new()
	puff_material.albedo_color = SMOKE_COLOR
	puff_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = puff_material
	smoke.mesh = puff
	house.add_child(smoke)


## Pigment bundles drying on a timber rack: saffron, madder, woad, weld and violet.
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
		rack.add_child(ShapeKit.box("Bundle%d" % index, Vector3(0.32, 0.8, 0.32), Vector3(x, 1.85, 0.0), _material(PIGMENT_COLORS[index])))


## The canal across the village and its stone banks, open only where the bridge crosses.
func _add_canal(parent: Node3D) -> void:
	var length: float = HUB_WIDTH - WALL_THICKNESS
	var water_material: StandardMaterial3D = _standard(WATER_COLOR)
	water_material.roughness = 0.15
	water_material.emission_enabled = true
	water_material.emission = WATER_COLOR.darkened(0.5)
	parent.add_child(ShapeKit.box("CanalWater", Vector3(length, 0.04, CANAL_WIDTH), Vector3(0.0, 0.03, CANAL_Z), water_material))
	var stone: Material = _material(STONE_COLOR)
	var gap: float = BRIDGE_WIDTH * 0.5 + BRIDGE_PARAPET_THICKNESS
	var bank_length: float = length * 0.5 - gap
	for bank: float in [-1.0, 1.0]:
		var bank_z: float = CANAL_Z + bank * (CANAL_WIDTH * 0.5 + CANAL_BANK_THICKNESS * 0.5)
		for side: float in [-1.0, 1.0]:
			parent.add_child(_low(_box_body("CanalBank%s%s" % ["North" if bank < 0.0 else "South", "West" if side < 0.0 else "East"],
				Vector3(bank_length, CANAL_BANK_HEIGHT, CANAL_BANK_THICKNESS),
				Vector3(side * (gap + bank_length * 0.5), CANAL_BANK_HEIGHT * 0.5, bank_z), stone)))


## Bramblebridge: a low stone arch. The walkway is one convex collider shaped
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
	var stone: Material = StorybookMaterial.make(BRIDGE_COLOR, StorybookMaterial.SCENERY_RIM, StorybookMaterial.WARM_RIM, true)
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
	village_sign.text = "Bramblebridge"
	village_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	village_sign.font_size = 64
	village_sign.outline_size = 12
	village_sign.pixel_size = 0.012
	village_sign.modulate = Color(1.0, 0.92, 0.75)
	village_sign.position = Vector3(0.0, BRIDGE_RISE + 2.6, 0.0)
	bridge.add_child(village_sign)


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
	var shed: StaticBody3D = _box_body("Watermill", MILL_SIZE, MILL_POSITION + Vector3(0.0, MILL_SIZE.y * 0.5, 0.0), _material(MILL_COLOR))
	var roof_mesh: PrismMesh = PrismMesh.new()
	roof_mesh.size = Vector3(MILL_SIZE.x + 0.4, 1.4, MILL_SIZE.z + 0.4)
	roof_mesh.material = _material(ROOF_COLOR)
	var roof: MeshInstance3D = MeshInstance3D.new()
	roof.name = "Roof"
	roof.mesh = roof_mesh
	roof.position = Vector3(0.0, MILL_SIZE.y * 0.5 + 0.7, 0.0)
	shed.add_child(roof)
	parent.add_child(shed)
	var wheel: Node3D = Node3D.new()
	wheel.name = "WaterWheel"
	wheel.set_script(load(WHEEL_SCRIPT))
	wheel.position = Vector3(MILL_POSITION.x, WHEEL_HEIGHT, CANAL_Z - CANAL_WIDTH * 0.25)
	# The wheel spins about its own Y axis: point that across the canal (Z), so it turns with the water.
	wheel.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	parent.add_child(wheel)


## A moss-oak: a stout trunk under three heaps of leaves. Only the trunk collides.
func _tree(tree_name: String, where: Vector3, height: float, collides: bool) -> Node3D:
	var tree: Node3D = _node3d(tree_name)
	tree.position = where
	var trunk_height: float = height * 0.55
	var trunk_radius: float = 0.22 + height * 0.025
	tree.add_child(ShapeKit.cylinder("Trunk", trunk_radius * 0.75, trunk_radius, trunk_height, Vector3(0.0, trunk_height * 0.5, 0.0), _material(OAK_TRUNK_COLOR), 24))
	var leaves: Material = _material(OAK_LEAF_COLOR)
	var heaps: Array[Vector3] = [Vector3(0.0, trunk_height + height * 0.12, 0.0), Vector3(height * 0.13, trunk_height + height * 0.28, height * 0.06),
		Vector3(-height * 0.1, trunk_height + height * 0.3, -height * 0.08)]
	for index: int in heaps.size():
		var heap_mesh: SphereMesh = SphereMesh.new()
		heap_mesh.radius = height * (0.27 - 0.04 * index)
		heap_mesh.height = heap_mesh.radius * 1.6
		heap_mesh.material = leaves
		var heap: MeshInstance3D = MeshInstance3D.new()
		heap.name = "Leaves%d" % index
		heap.mesh = heap_mesh
		heap.position = heaps[index]
		tree.add_child(heap)
	if collides:
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
	var water: StandardMaterial3D = _standard(Color(0.35, 0.6, 0.9))
	water.emission_enabled = true
	water.emission = Color(0.2, 0.4, 0.7)
	fountain.add_child(ShapeKit.cylinder("Water", FOUNTAIN_RADIUS - 0.25, FOUNTAIN_RADIUS - 0.25, 0.05, Vector3(0.0, 0.68, 0.0), water, 24))
	fountain.add_child(ShapeKit.cylinder("Spout", 0.25, 0.45, 1.8, Vector3(0.0, 0.9, 0.0), _material(STONE_COLOR), 24))
	return fountain


func _lantern(lantern_name: String, where: Vector3) -> Node3D:
	var post: Node3D = _node3d(lantern_name)
	post.position = where
	post.add_child(ShapeKit.cylinder("Post", 0.08, 0.1, 2.4, Vector3(0.0, 1.2, 0.0), _material(Color(0.25, 0.22, 0.2)), 24))
	var glow: StandardMaterial3D = _standard(LANTERN_COLOR)
	glow.emission_enabled = true
	glow.emission = LANTERN_COLOR
	glow.emission_energy_multiplier = 2.5
	var lamp_mesh: SphereMesh = SphereMesh.new()
	lamp_mesh.radius = 0.22
	lamp_mesh.height = 0.44
	lamp_mesh.material = glow
	var lamp: MeshInstance3D = MeshInstance3D.new()
	lamp.name = "Lamp"
	lamp.mesh = lamp_mesh
	lamp.position = Vector3(0.0, 2.5, 0.0)
	post.add_child(lamp)
	return post


# --- The Doverslap Expedition ---------------------------------------------

func _build_dojo() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "DungeonDojo"
	root.set_script(load(DOJO_SCRIPT))
	root.add_child(_environment(true))
	root.add_child(_sun())
	var world: Node3D = _node3d("Expedition")
	root.add_child(world)
	_build_moss_oaks(world)
	_build_holloway(world)
	_build_gorge(world)
	_build_ring(world)
	var boss_spawn: Marker3D = Marker3D.new()
	boss_spawn.name = "BossSpawn"
	boss_spawn.position = BOSS_POSITION
	# Face south, toward the causeway the party comes in by.
	boss_spawn.rotation = Vector3(0.0, PI, 0.0)
	boss_spawn.add_child(_pad("Ring", 2.2, Color(0.35, 0.18, 0.2)))
	root.add_child(boss_spawn)
	root.add_child(_portal("ExitPortal", InstanceManager.HUB_TOWN, "Exit: Bramblebridge", EXIT_PORTAL_COLOR, EXIT_PORTAL_POSITION))
	root.add_child(_scripted("CampOne", CAMP_SCRIPT, CAMP_ONE_POSITION, {&"camp_name": "Bramble Camp", &"kinds": CAMP_ONE_KINDS}))
	root.add_child(_scripted("CampTwo", CAMP_SCRIPT, CAMP_TWO_POSITION, {&"camp_name": "Holloway Camp", &"kinds": CAMP_TWO_KINDS}))
	root.add_child(_scripted("WaterShrine", SHRINE_WATER_SCRIPT, WATER_SHRINE_POSITION, {}))
	var lanterns: Node3D = _node3d("WindLanterns")
	root.add_child(lanterns)
	for index: int in WIND_LANTERN_SPOTS.size():
		lanterns.add_child(_scripted("WindLantern%d" % (index + 1), LANTERN_SCRIPT, WIND_LANTERN_SPOTS[index], {}))
	var chest_spot: Marker3D = Marker3D.new()
	chest_spot.name = "WayfarerChestSpot"
	chest_spot.position = WAYFARER_CHEST_POSITION
	root.add_child(chest_spot)
	root.add_child(_scripted("CoopGate", GATE_SCRIPT, GATE_POSITION, {}))
	var checkpoints: Node3D = _node3d("Checkpoints")
	root.add_child(checkpoints)
	for checkpoint: Array in [["Zone2", CHECKPOINT_TWO_Z], ["Zone3", CHECKPOINT_THREE_Z]]:
		var marker: Marker3D = Marker3D.new()
		marker.name = checkpoint[0]
		marker.position = Vector3(0.0, 0.0, checkpoint[1])
		checkpoints.add_child(marker)
	_add_level_skeleton(root, EXPEDITION_SPAWN_Z)
	return root


## Zone 1: a walled clearing of moss-oaks, the first bramble camp, a winding
## trail to the holloway, and the deer-run alcove through the west wall.
func _build_moss_oaks(parent: Node3D) -> void:
	var oaks: Node3D = _node3d("MossOaks")
	parent.add_child(oaks)
	var moss: Material = _material(MOSS_COLOR)
	oaks.add_child(_ground("Ground", OAKS_MIN, OAKS_MAX, 0.0, moss))
	var stone: Material = _material(DRYSTONE_COLOR)
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
	# The alcove: a short deer-run behind dry-stone walls, where the Wayfarer's Chest waits.
	var alcove: Node3D = _node3d("Alcove")
	parent.add_child(alcove)
	alcove.add_child(_ground("Ground", ALCOVE_MIN, ALCOVE_MAX, 0.0, moss))
	alcove.add_child(_wall("WallNorth", Vector2(ALCOVE_MIN.x, ALCOVE_MIN.y), Vector2(ALCOVE_MAX.x, ALCOVE_MIN.y), DRYSTONE_HEIGHT, stone))
	alcove.add_child(_wall("WallSouth", Vector2(ALCOVE_MIN.x, ALCOVE_MAX.y), Vector2(ALCOVE_MAX.x, ALCOVE_MAX.y), DRYSTONE_HEIGHT, stone))
	alcove.add_child(_wall("WallWest", Vector2(ALCOVE_MIN.x, ALCOVE_MIN.y), Vector2(ALCOVE_MIN.x, ALCOVE_MAX.y), DRYSTONE_HEIGHT, stone))
	alcove.add_child(_tree("Oak", Vector3(ALCOVE_MIN.x - 3.0, 0.0, (ALCOVE_MIN.y + ALCOVE_MAX.y) * 0.5), 8.0, false))


## The Sunken Holloway: a ramp down into a lane between high earthen banks,
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
	var roots: Material = _material(ROOT_COLOR)
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


## Zone 2: the cliff edges, the timber-and-stone trestle bridge over the
## Doverslap (with side bays for the Rune-Plates), the waterfall and the
## paper-mill wheel, and the Sinaya Gatehouse's towers around the CoopGate.
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
	# The Doverslap: a roaring fall of water down the east side, misting at its foot.
	var fall: StandardMaterial3D = StandardMaterial3D.new()
	fall.albedo_color = WATERFALL_COLOR
	fall.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fall.emission_enabled = true
	fall.emission = Color(0.55, 0.75, 0.9)
	fall.emission_energy_multiplier = 0.6
	gorge.add_child(ShapeKit.box("Waterfall", WATERFALL_SIZE, WATERFALL_POSITION, fall))
	gorge.add_child(_mist("FallMist", WATERFALL_POSITION + Vector3(0.0, -WATERFALL_SIZE.y * 0.4, 1.0), Vector3(3.0, 1.0, 2.0)))
	gorge.add_child(_mist("FallSpray", WATERFALL_POSITION + Vector3(-1.0, WATERFALL_SIZE.y * 0.45, 0.8), Vector3(2.5, 0.5, 1.0)))
	var wheel: Node3D = Node3D.new()
	wheel.name = "PaperMillWheel"
	wheel.set_script(load(WHEEL_SCRIPT))
	wheel.position = MILLWHEEL_POSITION
	wheel.rotation = Vector3(0.0, 0.0, PI * 0.5)
	wheel.scale = Vector3.ONE * MILLWHEEL_SCALE
	gorge.add_child(wheel)
	gorge.add_child(ShapeKit.box("MillHouse", Vector3(4.0, 5.0, 5.0), MILLWHEEL_POSITION + Vector3(-3.5, 0.5, 0.0), _material(MILL_COLOR)))
	# The Sinaya Gatehouse: two stone towers with carved timber turrets, walls out to the cliff sides.
	var half_gate: float = CoopGate.PORTCULLIS_WIDTH * 0.5
	for side: float in [-1.0, 1.0]:
		var label: String = "West" if side < 0.0 else "East"
		var tower_x: float = side * (half_gate + GATE_TOWER_SIZE.x * 0.5)
		var tower: StaticBody3D = _box_body("Tower%s" % label, GATE_TOWER_SIZE, Vector3(tower_x, GATE_TOWER_SIZE.y * 0.5, GATE_POSITION.z), stone)
		var turret: PrismMesh = PrismMesh.new()
		turret.size = Vector3(GATE_TOWER_SIZE.x + 0.8, 2.2, GATE_TOWER_SIZE.z + 0.8)
		turret.material = _material(ROOF_COLOR)
		var roof: MeshInstance3D = MeshInstance3D.new()
		roof.name = "Turret"
		roof.mesh = turret
		roof.position = Vector3(0.0, GATE_TOWER_SIZE.y * 0.5 + 1.6, 0.0)
		tower.add_child(roof)
		tower.add_child(ShapeKit.box("Gallery", Vector3(GATE_TOWER_SIZE.x + 0.6, 0.5, GATE_TOWER_SIZE.z + 0.6), Vector3(0.0, GATE_TOWER_SIZE.y * 0.5 + 0.25, 0.0), timber))
		gorge.add_child(tower)
		var wall_from: float = side * (half_gate + GATE_TOWER_SIZE.x)
		gorge.add_child(_wall("GateWall%s" % label, Vector2(wall_from, GATE_POSITION.z), Vector2(side * w, GATE_POSITION.z), GATE_WALL_HEIGHT, stone, 0.0, 1.2))
	gorge.add_child(ShapeKit.box("GateLintel", Vector3(CoopGate.PORTCULLIS_WIDTH + 0.6, 0.6, 0.9), Vector3(0.0, CoopGate.PORTCULLIS_HEIGHT + 0.5, GATE_POSITION.z), timber))
	var gate_sign: Label3D = Label3D.new()
	gate_sign.name = "GateSign"
	gate_sign.text = "Sinaya Gatehouse"
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
	var moss: Material = _material(MOSS_COLOR)
	var stone: Material = _material(DRYSTONE_COLOR)
	ring.add_child(_ground("Causeway", Vector2(-CAUSEWAY_HALF_WIDTH, CAUSEWAY_Z.x), Vector2(CAUSEWAY_HALF_WIDTH, CAUSEWAY_Z.y), 0.0, _material(STONE_COLOR)))
	for side: float in [-1.0, 1.0]:
		ring.add_child(_wall("CausewayWall%s" % ("West" if side < 0.0 else "East"), Vector2(side * (CAUSEWAY_HALF_WIDTH + 0.2), CAUSEWAY_Z.x),
			Vector2(side * (CAUSEWAY_HALF_WIDTH + 0.2), CAUSEWAY_Z.y), 0.9, stone, 0.0, 0.4))
	var floor_material: ShaderMaterial = ShaderMaterial.new()
	floor_material.shader = load(GRID_SHADER)
	floor_material.set_shader_parameter(&"base_color", Color(0.5, 0.53, 0.45))
	floor_material.set_shader_parameter(&"minor_color", Color(0.46, 0.49, 0.41))
	floor_material.set_shader_parameter(&"major_color", Color(0.4, 0.44, 0.36))
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
		pillar.add_child(ShapeKit.cylinder("Moss", PILLAR_RADIUS * 0.95, PILLAR_RADIUS * 1.02, 0.4, Vector3(0.0, PILLAR_HEIGHT * 0.5 - 0.15, 0.0), moss, 24))
		ring.add_child(pillar)
	ring.add_child(_mist("Spray", Vector3(0.0, 2.5, north + 1.0), Vector3(half, 1.5, 1.0)))


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
	mesh.material_override = StorybookMaterial.double_sided(material)
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
func _add_level_skeleton(root: Node3D, spawn_z: float) -> void:
	var spawns: Node3D = _node3d("SpawnPoints")
	root.add_child(spawns)
	for index: int in 4:
		var marker: Marker3D = Marker3D.new()
		marker.name = "Spawn%d" % (index + 1)
		marker.position = Vector3((float(index) - 1.5) * SPAWN_SPACING, 0.0, spawn_z)
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


## Scenery in the storybook cel look (07 GDD §4.2).
func _material(color: Color) -> Material:
	return StorybookMaterial.make(color)


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
	disc.material = _material(color)
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
