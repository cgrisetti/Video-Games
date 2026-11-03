## Builds Oakshire Vale from code (12_WORLD_OAKSHIRE_VALE_GDD.md,
## 13_STARTING_ZONE_ENCOUNTER_DESIGN.md; Code-First Scene Safety). Re-run after
## changing OakshireValeLayout or anything here:
##   godot --headless --path . --script res://tools/build_oakshire_vale.gd
##
## It bakes the vale's ground (OakshireValeLayout's field and colours every
## 2 m: data/landblocks/oakshire_vale/field.res) and its horizon (horizon.res:
## the whole zone in under 4,000 triangles, sitting just under the real ground,
## with the hero trees standing on it), writes the level's shell
## (scenes/worlds/oakshire_vale.tscn: the sky and sun, the WorldGridManager on
## the vale's layout, the horizon and the skeleton LevelBase expects), and one
## landblock per chunk with anything in it (landblock_X_Z.tscn, everything at
## its world position), with an HLOD proxy for the ones with buildings:
##   Oakshire-Wick on the central saddle: ten gabled houses round a green
##     and its fountain, fourteen market stalls and their vendors, a quest hub,
##     Hearth-Guard sentries at the road ends and villagers about their day
##   the Bridge-Warden's stone span and its sentries, and the watermill
##   Wayfarer-Green (the spawn and the Wayfarer's Arch home) and the four
##     petal camps, each with tents, a fire, a sentry and a three-quest hub,
##     and the orchard by Pippin-Green camp
##   the four portal aprons in the rim crags, each sealed by its Sign
##   the six families' spawners in their territories, the sheep and foxes, and
##     the Crag-Back Cairn-Drake's round of the High Road
## 68 friendly folk: 18 quest givers, 14 vendors, 16 guards and 20 villagers.
extends "res://tools/build_levels.gd"

const OAKSHIRE_PATH: String = "res://scenes/worlds/oakshire_vale.tscn"
const OAKSHIRE_SCRIPT: String = "res://src/levels/oakshire_vale.gd"
const NPC_SCRIPT: String = "res://src/actors/townsfolk_npc.gd"
const APRON_SCRIPT: String = "res://src/actors/portal_apron.gd"
const SPAWNER_SCRIPT: String = "res://src/actors/mob_spawner.gd"
const FLOCK_SCRIPT: String = "res://src/actors/ambient_flock.gd"
## The horizon: a vertex every this many metres, each the lowest ground within
## HORIZON_REACH (sampled every HORIZON_PROBE m) less HORIZON_SINK, so it never
## pokes through the real ground.
const HORIZON_STEP: float = 48.0
const HORIZON_REACH: float = 48.0
const HORIZON_PROBE: float = 6.0
const HORIZON_SINK: float = 1.0
const HOUSE_RADIUS: float = 48.0
const STALL_RADIUS: float = 25.0
const STALL_COLORS: Array[Color] = [Color(0.78, 0.3, 0.26), Color(0.32, 0.5, 0.78), Color(0.9, 0.72, 0.3), Color(0.42, 0.62, 0.36),
	Color(0.62, 0.42, 0.72)]
const VALE_HOUSE_COLORS: Array[Color] = [Color(0.93, 0.88, 0.76), Color(0.88, 0.78, 0.62), Color(0.8, 0.84, 0.88), Color(0.92, 0.82, 0.7)]
const TENT_COLOR: Color = Color(0.82, 0.74, 0.58)
const FIRE_COLOR: Color = Color(1.0, 0.62, 0.22)
const BRIDGE_STONE: Color = Color(0.6, 0.58, 0.54)
const FRUIT_COLOR: Color = Color(0.86, 0.22, 0.18)
## The Bridge-Warden's span: its flat middle and each ramp (metres along the road), its deck height over the water.
const SPAN_MIDDLE: float = 7.0
const SPAN_RAMP: float = 8.0
const SPAN_DECK: float = 2.6
const SPAN_WIDTH: float = 6.0
const TOWNSFOLK_TOTALS: Dictionary = {"quest_givers": 18, "vendors": 14, "guards": 16, "villagers": 20}

## Each hub's three quest givers: name, title, their quest.
const QUEST_HUBS: Dictionary = {
	"Wayfarer-Green": [["Tamsin Hale", "Green-Warden", "Lanterns on the High Road"], ["Joss Brindle", "Pedlar", "Strays in the Meadow"],
		["Wren Ashby", "Wayfarer Scout", "First Steps on the Trail"]],
	"Oakshire-Wick": [["Godric Marlow", "Village Reeve", "The Bridge-Warden's Charge"], ["Maude Penrose", "Hearthwife", "Cider-Hobs at the Orchard Gate"],
		["Ellery Thorne", "Scribe of the Tor", "Signs on the Scribe's Tor"]],
	"Pippin-Green": [["Hob Applegarth", "Orchard-Keeper", "Bristle-Hobs in the Cider Rows"], ["Nell Quince", "Cellarer", "The Trapdoor Under the Old Pear"],
		["Ida Combe", "Beekeeper", "Old Tusk-Hob's Wallow"]],
	"Quarry-Wick": [["Bram Stonely", "Quarry-Master", "Iron-Men on the Terraces"], ["Pip Cutler", "Spoil-Heap Lookout", "Shots from the Spoil-Heaps"],
		["Odo Pennyfeather", "Mine-Clerk", "The Iron-Kettle Lamps"]],
	"Bramble-Hollow": [["Rowan Fell", "Woodwarden", "Bark That Will Not Split"], ["Sorrel Dunmore", "Herbwife", "Spore-Puffs in the Hollows"],
		["Alder Mossgrave", "Druid-Scribe", "The Petrified Oak's Song"]],
	"Nine-Stones-Crossing": [["Cuthbert Knoll", "Bell-Ringer", "The Tarnished Chimes"], ["Edith Barrowe", "Stone-Warden", "Spriggans Beyond the Mounds"],
		["Felix Wynn", "Lantern-Scribe", "The Star-Barrow Seal"]],
}
## The village's fourteen vendors: name, title, wares (TownsfolkNPC.Wares), what light does.
const VENDORS: Array = [
	["Hilda Forde", "Falchion Smith", 1, "browse Falchions"], ["Garth Holloway", "Broad-Axe Smith", 1, "browse Broad-Axes"],
	["Elspeth Rowe", "Way-Staff Carver", 1, "browse Rowan Way-Staves"], ["Tobias Yewdale", "Bowyer", 1, "browse Yew Longbows"],
	["Agnes Linley", "Linen Weaver", 2, "try on a Hearth-Linen Coat"], ["Wat Fleecewell", "Wool-Mantle Weaver", 2, "try on a Hedgerow Wool-Mantle"],
	["Osric Ironside", "Ring-Coat Smith", 2, "try on an Iron-Wood Ring-Coat"], ["Mabel Fennick", "Apothecary", 3, "drink a mending tonic"],
	["Quentin Sage", "Herbalist", 3, "drink a mending tonic"], ["Lettice Hart", "Hedge-Doctor", 3, "drink a mending tonic"],
	["Ambrose Coyne", "Chime-Vault Keeper", 4, "open the Chime-Vault"], ["Philippa Ledger", "Chime-Vault Clerk", 4, "open the Chime-Vault"],
	["Isolde Marsh", "Calling Tutor", 5, "change your Calling"], ["Benedict Ashcombe", "Calling Respec Tutor", 5, "change your Calling"],
]
const GUARD_NAMES: Array[String] = ["Aldous", "Brynn", "Cedric", "Dunstan", "Elfrida", "Fenwick", "Gwen", "Harold", "Ivo", "Juliana", "Kenelm", "Leofric",
	"Mildred", "Norbert", "Osgar", "Petra"]
const VILLAGER_NAMES: Array[String] = ["Agatha", "Bartle", "Cissy", "Dob", "Emmet", "Florrie", "Gil", "Hettie", "Ned", "Ottilie", "Perkin", "Rosamund",
	"Simkin", "Tibby", "Ulric", "Wilmot", "Yolande", "Abel", "Bess", "Col"]

var _vale: OakshireValeLayout
var _roots: Dictionary[Vector2i, Node3D] = {}
var _counts: Dictionary[String, int] = {}
var _guard_index: int = 0
var _villager_index: int = 0


func _initialize() -> void:
	var folder: String = ProjectSettings.globalize_path(OakshireValeLayout.LANDBLOCK_FOLDER)
	DirAccess.make_dir_recursive_absolute(folder)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/worlds/"))
	for file: String in DirAccess.get_files_at(folder):
		if file.begins_with("landblock_") or file.begins_with("hlod_"):
			DirAccess.remove_absolute(folder.path_join(file))
	var procedural: OakshireValeLayout = OakshireValeLayout.new(false)
	WorldGridConfig.layout = procedural
	_results.append("%s -> %s" % [OakshireValeLayout.FIELD_PATH, error_string(_bake_field(procedural))])
	# From here on everything reads the baked field, as the game does.
	_vale = OakshireValeLayout.new(true)
	WorldGridConfig.layout = _vale
	_results.append("%s -> %s" % [OakshireValeLayout.HORIZON_PATH, error_string(_bake_horizon())])
	_results.append("%s -> %s" % [OAKSHIRE_PATH, error_string(_save(_build_shell(), OAKSHIRE_PATH))])
	_build_landblocks()
	for chunk: Vector2i in _roots:
		var path: String = "%slandblock_%s.tscn" % [OakshireValeLayout.LANDBLOCK_FOLDER, WorldGridConfig.chunk_key(chunk)]
		var error: Error = _save(_roots[chunk], path)
		if error != OK:
			_results.append("%s -> %s" % [path, error_string(error)])
	_results.append("%d landblocks" % _roots.size())
	_results.append("townsfolk %s" % str(_counts))
	_roots.clear()


## The HLOD proxies, once the tree runs (each landblock's scripts build their looks first).
func _process(_delta: float) -> bool:
	if _baked:
		return false
	_baked = true
	_counts.clear()
	_guard_index = 0
	_villager_index = 0
	_build_landblocks()
	var baked: int = 0
	for chunk: Vector2i in _roots:
		var root: Node3D = _roots[chunk]
		if not root.has_meta(&"buildings"):
			root.free()
			continue
		var path: String = "%shlod_%s.res" % [OakshireValeLayout.LANDBLOCK_FOLDER, WorldGridConfig.chunk_key(chunk)]
		var error: Error = _bake_hlod(root, path)
		if error != OK:
			_results.append("%s -> %s" % [path, error_string(error)])
		baked += 1
	_roots.clear()
	_results.append("%d HLOD proxies" % baked)
	print("build_oakshire_vale: " + ", ".join(_results))
	quit(0 if not ", ".join(_results).contains("rror") else 1)
	return false


# --- The ground --------------------------------------------------------------------

func _bake_field(layout: OakshireValeLayout) -> Error:
	var side: int = int(OakshireValeLayout.SIZE / OakshireValeLayout.FIELD_STEP) + 1
	var field: OakshireValeField = OakshireValeField.new()
	field.side = side
	field.heights.resize(side * side)
	field.colors.resize(side * side * 3)
	for row: int in side:
		var z: float = row * OakshireValeLayout.FIELD_STEP
		for column: int in side:
			var x: float = column * OakshireValeLayout.FIELD_STEP
			var height: float = layout.field_height(x, z)
			var color: Color = layout.field_color(x, z, height)
			var at: int = row * side + column
			field.heights[at] = height
			field.colors[at * 3] = color.r8
			field.colors[at * 3 + 1] = color.g8
			field.colors[at * 3 + 2] = color.b8
	return ResourceSaver.save(field, OakshireValeLayout.FIELD_PATH, ResourceSaver.FLAG_COMPRESS)


## The whole zone as one low mesh for the distant hills (12 GDD §4: under 4,000 triangles).
func _bake_horizon() -> Error:
	var cells: int = int(OakshireValeLayout.SIZE / HORIZON_STEP)
	var side: int = cells + 1
	var vertices: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	for row: int in side:
		for column: int in side:
			var x: float = column * HORIZON_STEP
			var z: float = row * HORIZON_STEP
			var lowest: float = INF
			var probe_z: float = z - HORIZON_REACH
			while probe_z <= z + HORIZON_REACH:
				var probe_x: float = x - HORIZON_REACH
				while probe_x <= x + HORIZON_REACH:
					lowest = minf(lowest, _vale.sample_height(probe_x, probe_z))
					probe_x += HORIZON_PROBE
				probe_z += HORIZON_PROBE
			vertices.append(Vector3(x, lowest - HORIZON_SINK, z))
			colors.append(_vale.surface_color(x, z, lowest))
	var indices: PackedInt32Array = PackedInt32Array()
	for row: int in cells:
		for column: int in cells:
			var a: int = row * side + column
			indices.append_array(PackedInt32Array([a, a + 1, a + side, a + 1, a + side + 1, a + side]))
	var normals: PackedVector3Array = PackedVector3Array()
	normals.resize(vertices.size())
	for row: int in side:
		for column: int in side:
			var at: int = row * side + column
			var left: float = vertices[row * side + maxi(column - 1, 0)].y
			var right: float = vertices[row * side + mini(column + 1, cells)].y
			var up: float = vertices[maxi(row - 1, 0) * side + column].y
			var down: float = vertices[mini(row + 1, cells) * side + column].y
			normals[at] = Vector3(left - right, HORIZON_STEP * 2.0, up - down).normalized()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# The hero trees on it, a few sides each: the landmarks seen from across the vale.
	var trees: LandblockTerrain.MeshMerge = LandblockTerrain.MeshMerge.new()
	for tree: Dictionary in _vale.hero_trees():
		var at: Vector3 = tree["position"]
		var height: float = tree["height"]
		var crown: float = tree["crown"]
		trees.add_cylinder(at + Vector3(0.0, height * 0.31, 0.0), float(tree["radius"]) * 0.8, float(tree["radius"]) * 1.2, height * 0.62, OakshireValeLayout.TRUNK_COLOR, 5)
		if not tree["petrified"]:
			trees.add_cylinder(at + Vector3(0.0, height * 0.62 + crown * 0.6, 0.0), crown * 0.2, crown * 1.1, crown * 1.6, OakshireValeLayout.CANOPY_COLOR, 6)
	var tree_mesh: ArrayMesh = trees.commit()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, tree_mesh.surface_get_arrays(0))
	return ResourceSaver.save(mesh, OakshireValeLayout.HORIZON_PATH)


func _build_shell() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "OakshireVale"
	root.set_script(load(OAKSHIRE_SCRIPT))
	root.add_child(_environment(true))
	root.add_child(_sun())
	var grid: Node3D = Node3D.new()
	grid.name = "World"
	grid.set_script(load(GRID_MANAGER_SCRIPT))
	grid.set(&"layout_id", OakshireValeLayout.LAYOUT_ID)
	root.add_child(grid)
	var horizon: MeshInstance3D = MeshInstance3D.new()
	horizon.name = "Horizon"
	horizon.mesh = load(OakshireValeLayout.HORIZON_PATH) as ArrayMesh
	horizon.material_override = LandblockTerrain.material()
	horizon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(horizon)
	var glade: Vector3 = _vale.camp_center(OakshireValeLayout.Petal.GLADE)
	_add_level_skeleton(root, 0.0, glade + Vector3(0.0, 0.05, -4.0))
	return root


# --- Landblocks ----------------------------------------------------------------------

func _build_landblocks() -> void:
	_roots.clear()
	_add_village()
	_add_bridge_span()
	_add_mill()
	for petal: int in _vale.petal_count():
		_add_camp(petal)
	_add_orchard()
	_add_aprons()
	_add_spawners()
	_add_flocks()


## Puts a node at its world position in the landblock of the chunk it stands in.
func _put(node: Node3D, at: Vector3, building: bool = false) -> Node3D:
	var chunk: Vector2i = WorldGridConfig.world_to_chunk(at)
	if not _roots.has(chunk):
		var root: Node3D = _node3d("Landblock_%s" % WorldGridConfig.chunk_key(chunk))
		root.set_meta(&"chunk", chunk)
		_roots[chunk] = root
	if building:
		_roots[chunk].set_meta(&"buildings", true)
	node.position = at
	_roots[chunk].add_child(node)
	return node


func _ground_at(at: Vector3) -> Vector3:
	return Vector3(at.x, _vale.sample_height(at.x, at.z), at.z)


func _facing(from: Vector3, toward: Vector3) -> float:
	var direction: Vector3 = toward - from
	return atan2(-direction.x, -direction.z)


func _around(center: Vector3, bearing_degrees: float, radius: float) -> Vector3:
	var theta: float = deg_to_rad(bearing_degrees)
	return _ground_at(center + Vector3(sin(theta), 0.0, -cos(theta)) * radius)


# --- Oakshire-Wick ------------------------------------------------------------------

func _add_village() -> void:
	var center: Vector3 = _ground_at(Vector3(OakshireValeLayout.CENTER.x, 0.0, OakshireValeLayout.CENTER.y))
	var fountain: StaticBody3D = _fountain()
	_put(fountain, center, true)
	var exits: Array[float] = OakshireValeLayout.PETAL_BEARINGS
	var gaps: Array[float] = []
	for index: int in exits.size():
		gaps.append(exits[index])
	# Ten houses, two in each gap between the road ends, facing the green.
	var house_index: int = 0
	for index: int in gaps.size():
		var start: float = gaps[index]
		for third: float in [1.0 / 3.0, 2.0 / 3.0]:
			var bearing_degrees: float = start + 72.0 * third
			var spot: Vector3 = _around(center, bearing_degrees, HOUSE_RADIUS)
			var house: StaticBody3D = _house("House%d" % house_index, Vector3.ZERO, VALE_HOUSE_COLORS[house_index % VALE_HOUSE_COLORS.size()], false)
			_put(house, spot, true)
			house.position.y += HOUSE_SIZE.y * 0.5
			house.rotation.y = _facing(spot, center)
			house_index += 1
	# Fourteen market stalls round the green (three in each gap, two in the last), each with its vendor behind it.
	var vendor_index: int = 0
	for index: int in gaps.size():
		var stalls: int = 2 if index == gaps.size() - 1 else 3
		for slot: int in stalls:
			var bearing_degrees: float = gaps[index] + 72.0 * (slot + 1.0) / (stalls + 1.0)
			var spot: Vector3 = _around(center, bearing_degrees, STALL_RADIUS)
			_put(_stall("Stall%d" % vendor_index, STALL_COLORS[vendor_index % STALL_COLORS.size()], _facing(spot, center)), spot, true)
			var entry: Array = VENDORS[vendor_index]
			var behind: Vector3 = _around(center, bearing_degrees, STALL_RADIUS + 1.6)
			_npc(TownsfolkNPC.Role.VENDOR, entry[0], entry[1], "Oakshire-Wick", PackedStringArray(), entry[2], entry[3], behind, _facing(behind, center),
				PackedVector3Array(), STALL_COLORS[vendor_index % STALL_COLORS.size()].darkened(0.2), Color(0.86, 0.8, 0.66))
			vendor_index += 1
	_add_quest_hub("Oakshire-Wick", center, 7.0, 150.0)
	# Hearth-Guard sentries at each road's end and three round the green.
	for index: int in exits.size():
		var post: Vector3 = _around(center, exits[index] + 6.0, OakshireValeLayout.VILLAGE_RADIUS - 3.0)
		_guard("Hearth-Guard", post, _facing(center, post))
	for bearing_degrees: float in [0.0, 112.0 + 36.0, 256.0 + 36.0]:
		var post: Vector3 = _around(center, bearing_degrees, 36.0)
		_guard("Hearth-Guard", post, _facing(center, post))
	# Twelve villagers strolling round the green.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1203
	for index: int in 12:
		var home: Vector3 = _around(center, rng.randf() * 360.0, rng.randf_range(10.0, 38.0))
		var route: PackedVector3Array = PackedVector3Array()
		for stop: int in rng.randi_range(2, 3):
			route.append(_around(center, rng.randf() * 360.0, rng.randf_range(10.0, 40.0)))
		_villager(home, route)


func _stall(stall_name: String, color: Color, yaw: float) -> StaticBody3D:
	var stall: StaticBody3D = StaticBody3D.new()
	stall.name = stall_name
	stall.collision_layer = ActorBase.LAYER_LOW_SCENERY
	stall.collision_mask = 0
	stall.rotation.y = yaw
	var wood: Material = _material(Color(0.5, 0.36, 0.22))
	stall.add_child(ShapeKit.box("Counter", Vector3(2.6, 1.0, 0.9), Vector3(0.0, 0.5, 0.0), wood))
	for corner: Vector2 in [Vector2(-1.25, -0.4), Vector2(1.25, -0.4), Vector2(-1.25, 0.9), Vector2(1.25, 0.9)]:
		stall.add_child(ShapeKit.cylinder("Post", 0.06, 0.06, 2.6, Vector3(corner.x, 1.3, corner.y), wood, 6))
	var canopy: MeshInstance3D = ShapeKit.box("Canopy", Vector3(2.9, 0.12, 1.8), Vector3(0.0, 2.6, 0.25), _material(color))
	canopy.rotation.x = 0.18
	stall.add_child(canopy)
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Collision"
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(2.6, 1.0, 0.9)
	shape.shape = box
	shape.position = Vector3(0.0, 0.5, 0.0)
	stall.add_child(shape)
	return stall


func _add_quest_hub(hub: String, center: Vector3, radius: float, first_bearing: float) -> void:
	var givers: Array = QUEST_HUBS[hub]
	for index: int in givers.size():
		var entry: Array = givers[index]
		var spot: Vector3 = _around(center, first_bearing + index * 40.0, radius)
		_npc(TownsfolkNPC.Role.QUEST_GIVER, entry[0], entry[1], hub, PackedStringArray([entry[2]]), TownsfolkNPC.Wares.NONE, "", spot, _facing(center, spot),
			PackedVector3Array(), Color(0.42, 0.32, 0.56), Color(0.86, 0.7, 0.32))


func _guard(title: String, at: Vector3, yaw: float) -> void:
	var name_index: int = _guard_index % GUARD_NAMES.size()
	_guard_index += 1
	var warden: bool = title == "Bridge-Warden"
	_npc(TownsfolkNPC.Role.GUARD, GUARD_NAMES[name_index], title, "", PackedStringArray(), TownsfolkNPC.Wares.NONE, "", at, yaw, PackedVector3Array(),
		Color(0.32, 0.46, 0.72) if warden else Color(0.62, 0.3, 0.22), Color(0.86, 0.66, 0.3))


func _villager(home: Vector3, route: PackedVector3Array) -> void:
	var name_index: int = _villager_index % VILLAGER_NAMES.size()
	_villager_index += 1
	var hue: float = fposmod(name_index * 0.137, 1.0)
	_npc(TownsfolkNPC.Role.VILLAGER, VILLAGER_NAMES[name_index], "", "", PackedStringArray(), TownsfolkNPC.Wares.NONE, "", home, 0.0, route,
		Color.from_hsv(hue, 0.35, 0.7), Color.from_hsv(fposmod(hue + 0.4, 1.0), 0.3, 0.5))


func _npc(role: TownsfolkNPC.Role, npc_name: String, title: String, hub: String, quests: PackedStringArray, wares: int, note: String, at: Vector3,
		yaw: float, route: PackedVector3Array, body: Color, accent: Color) -> void:
	var npc: Node3D = _scripted("%s_%s" % [TownsfolkNPC.Role.keys()[role].to_pascal_case(), npc_name.replace(" ", "")], NPC_SCRIPT, Vector3.ZERO, {
		&"role": role, &"npc_name": npc_name, &"title": title, &"hub": hub, &"quests": quests, &"wares": wares, &"wares_note": note,
		&"route": route, &"body_color": body, &"accent_color": accent, &"npc_seed": hash(npc_name) % 997})
	npc.rotation.y = yaw
	_put(_entity(npc), at)
	var key: String = ["quest_givers", "vendors", "guards", "villagers"][role]
	_counts[key] = _counts.get(key, 0) + 1


# --- The Bridge-Warden's span and the mill -------------------------------------------------

## A stone span over the river where the Glade road crosses it: a flat middle
## over the water and a ramp at each end, low parapets, and an arch beneath.
func _add_bridge_span() -> void:
	var frame: Transform3D = _vale.bridge_transform()
	var span: Node3D = _node3d("BridgeWardenSpan")
	span.basis = frame.basis
	var stone: Material = _material(BRIDGE_STONE)
	var deck: StaticBody3D = StaticBody3D.new()
	deck.name = "Deck"
	deck.collision_layer = ActorBase.LAYER_LOW_SCENERY
	deck.collision_mask = 0
	span.add_child(deck)
	_deck_piece(deck, "Middle", Vector3(0.0, SPAN_DECK - 0.25, 0.0), Vector3(SPAN_WIDTH, 0.5, SPAN_MIDDLE * 2.0), 0.0, stone)
	for side: float in [-1.0, 1.0]:
		var end_ground: float = _vale.sample_height(frame.origin.x + frame.basis.z.x * side * (SPAN_MIDDLE + SPAN_RAMP),
			frame.origin.z + frame.basis.z.z * side * (SPAN_MIDDLE + SPAN_RAMP)) - OakshireValeLayout.RIVER_WATER
		var rise: float = SPAN_DECK - end_ground
		var length: float = sqrt(SPAN_RAMP * SPAN_RAMP + rise * rise)
		var tilt: float = atan2(rise, SPAN_RAMP) * side
		_deck_piece(deck, "Ramp", Vector3(0.0, (SPAN_DECK + end_ground) * 0.5 - 0.25, side * (SPAN_MIDDLE + SPAN_RAMP * 0.5)), Vector3(SPAN_WIDTH, 0.5, length + 0.4),
			tilt, stone)
		for rail: float in [-1.0, 1.0]:
			span.add_child(ShapeKit.box("Parapet", Vector3(0.4, 0.8, SPAN_MIDDLE * 2.0), Vector3(rail * (SPAN_WIDTH * 0.5 - 0.2), SPAN_DECK + 0.4, 0.0), stone))
	span.add_child(ShapeKit.cylinder("Arch", SPAN_MIDDLE * 0.8, SPAN_MIDDLE * 0.8, SPAN_WIDTH - 0.6, Vector3(0.0, SPAN_DECK - SPAN_MIDDLE * 0.8 - 0.3, 0.0),
		_material(BRIDGE_STONE.darkened(0.15)), 16))
	(span.get_child(span.get_child_count() - 1) as Node3D).rotation.z = PI * 0.5
	_put(span, frame.origin, true)
	# Two Bridge-Wardens keep it, one at each end.
	for side: float in [-1.0, 1.0]:
		var post: Vector3 = frame.origin + frame.basis.z * side * (SPAN_MIDDLE + SPAN_RAMP + 3.0) + frame.basis.x * 4.0
		_guard("Bridge-Warden", _ground_at(post), atan2(-frame.basis.z.x * side, -frame.basis.z.z * side) + PI)


func _deck_piece(deck: StaticBody3D, piece_name: String, where: Vector3, size: Vector3, tilt: float, material: Material) -> void:
	var mesh: MeshInstance3D = ShapeKit.box(piece_name, size, where, material)
	mesh.rotation.x = tilt
	deck.add_child(mesh)
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = piece_name + "Collision"
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = where
	shape.rotation.x = tilt
	deck.add_child(shape)


func _add_mill() -> void:
	var at: Vector3 = _vale.mill_position()
	var mill: StaticBody3D = _box_body("Watermill", Vector3(6.0, 5.0, 6.0), Vector3.ZERO, _material(MILL_COLOR))
	_put(mill, at, true)
	mill.position.y += 2.5
	var roof: MeshInstance3D = MeshInstance3D.new()
	roof.name = "Roof"
	var roof_mesh: PrismMesh = PrismMesh.new()
	roof_mesh.size = Vector3(6.4, 2.0, 6.4)
	roof_mesh.material = _material(ROOF_COLOR)
	roof.mesh = roof_mesh
	roof.position = Vector3(0.0, 3.5, 0.0)
	mill.add_child(roof)
	var river: Vector2 = OakshireValeLayout.river_at(at.x)
	var wheel: Node3D = _node3d("WaterWheel")
	wheel.set_script(load(WHEEL_SCRIPT))
	wheel.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	_put(wheel, Vector3(at.x, 2.4, lerpf(at.z, river.x, 0.55)), true)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 908
	for index: int in 4:
		var home: Vector3 = _ground_at(at + Vector3(rng.randf_range(-9.0, 9.0), 0.0, rng.randf_range(-12.0, -4.0)))
		_villager(home, PackedVector3Array([_ground_at(at + Vector3(rng.randf_range(-10.0, 10.0), 0.0, rng.randf_range(-14.0, -6.0)))]))


# --- Camps, the Glade and the orchard -------------------------------------------------------

func _add_camp(petal: int) -> void:
	var center: Vector3 = _vale.camp_center(petal)
	var hub: String = OakshireValeLayout.PETAL_NAMES[petal]
	var glade: bool = petal == OakshireValeLayout.Petal.GLADE
	var fire: Node3D = _node3d("Campfire")
	fire.add_child(ShapeKit.no_shadow(ShapeKit.sphere("Flames", 0.55, Vector3(0.0, 0.45, 0.0), StorybookMaterial.glowing(FIRE_COLOR, 2.5))))
	for log_index: int in 4:
		var log_mesh: MeshInstance3D = ShapeKit.cylinder("Log%d" % log_index, 0.12, 0.12, 1.4, Vector3(0.0, 0.12, 0.0), _material(Color(0.36, 0.24, 0.14)), 6)
		log_mesh.rotation = Vector3(PI * 0.5, log_index * PI * 0.25, 0.0)
		fire.add_child(log_mesh)
	_put(fire, center, true)
	for index: int in 3:
		var bearing_degrees: float = 30.0 + index * 120.0 + OakshireValeLayout.PETAL_BEARINGS[petal]
		var spot: Vector3 = _around(center, bearing_degrees, 10.0 if not glade else 15.0)
		var tent: StaticBody3D = _box_body("Tent%d" % index, Vector3(3.2, 0.2, 3.6), Vector3.ZERO, _material(TENT_COLOR))
		var cloth: MeshInstance3D = MeshInstance3D.new()
		cloth.name = "Canvas"
		var prism: PrismMesh = PrismMesh.new()
		prism.size = Vector3(3.2, 2.4, 3.6)
		prism.material = _material(TENT_COLOR.lerp(STALL_COLORS[petal], 0.3))
		cloth.mesh = prism
		cloth.position = Vector3(0.0, 1.2, 0.0)
		tent.add_child(cloth)
		(tent.get_child(0) as CollisionShape3D).shape = _tent_shape()
		(tent.get_child(0) as CollisionShape3D).position = Vector3(0.0, 1.0, 0.0)
		_put(tent, spot, true)
		tent.rotation.y = _facing(spot, center)
	_add_quest_hub(hub, center, 4.5, OakshireValeLayout.PETAL_BEARINGS[petal] + 180.0)
	var post: Vector3 = _around(center, OakshireValeLayout.PETAL_BEARINGS[petal] + 90.0, (OakshireValeLayout.GLADE_RADIUS if glade else OakshireValeLayout.CAMP_RADIUS) - 3.0)
	_guard("Bridge-Warden", post, _facing(center, post))
	if glade:
		var second: Vector3 = _around(center, OakshireValeLayout.PETAL_BEARINGS[petal] - 90.0, OakshireValeLayout.GLADE_RADIUS - 3.0)
		_guard("Bridge-Warden", second, _facing(center, second))
		# The Wayfarer's Arch: walk into it together to go home to Bramble-Bridge.
		var arch: Node3D = _scripted("WayfarersArch", PORTAL_SCRIPT, Vector3.ZERO, {&"goes_home": true, &"title": "Wayfarer's Arch: home to Bramble-Bridge",
			&"portal_color": Color(0.95, 0.8, 0.4)})
		_put(_entity(arch), _around(center, OakshireValeLayout.PETAL_BEARINGS[petal], 14.0), true)


func _tent_shape() -> BoxShape3D:
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(3.0, 2.0, 3.4)
	return box


## Pippin-Green's cider rows beside its camp, and four villagers tending them.
func _add_orchard() -> void:
	var camp: Vector3 = _vale.camp_center(OakshireValeLayout.Petal.ORCHARD)
	var toward_village: Vector3 = (Vector3(OakshireValeLayout.CENTER.x, camp.y, OakshireValeLayout.CENTER.y) - camp).normalized()
	var across: Vector3 = toward_village.cross(Vector3.UP)
	var placed: int = 0
	for row: int in 4:
		for column: int in 5:
			var spot: Vector3 = camp + toward_village * (24.0 + row * 6.0) + across * ((column - 2.0) * 6.0)
			if _vale.is_kept_clear(spot.x, spot.z, 0.0) and _vale.road_lateral(spot.x, spot.z) < 6.0:
				continue
			_put(_fruit_tree("PearTree%d" % placed), _ground_at(spot), true)
			placed += 1
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4401
	for index: int in 4:
		var home: Vector3 = _ground_at(camp + toward_village * rng.randf_range(24.0, 40.0) + across * rng.randf_range(-12.0, 12.0))
		_villager(home, PackedVector3Array([_ground_at(camp + toward_village * rng.randf_range(24.0, 40.0) + across * rng.randf_range(-12.0, 12.0))]))


func _fruit_tree(tree_name: String) -> Node3D:
	var tree: Node3D = _tree(tree_name, Vector3.ZERO, 4.2, true)
	var fruit: Material = _material(FRUIT_COLOR)
	for index: int in 6:
		var angle: float = TAU * index / 6.0
		tree.add_child(ShapeKit.sphere("Pear%d" % index, 0.12, Vector3(cos(angle) * 0.9, 3.0 + sin(index * 1.7) * 0.4, sin(angle) * 0.9), fruit))
	return tree


# --- The portal aprons ------------------------------------------------------------------

func _add_aprons() -> void:
	var table: Array = [
		[OakshireValeLayout.Petal.WEALD, "[R1]", "Tangle-Root-Hollow", "Lvl 6 Capstone 5-Player Family Raid", 6, ScribeSignResource.Sign.SIGN_RIME_GALE, &"r1_root_sanctum"],
		[OakshireValeLayout.Petal.QUARRY, "[D1]", "Iron-Kettle-Hollow", "Lvl 4–5 5-Player Story Dungeon", 4, ScribeSignResource.Sign.SIGN_IRON_ROOT, &"d1_gloom_vein_mine"],
		[OakshireValeLayout.Petal.BARROWS, "[D2]", "Star-Barrow-Hollow", "Lvl 5–6 Spriggan Barrow", 5, ScribeSignResource.Sign.SIGN_STAR_TIDE, &"d2_hollow_kings_barrow"],
		[OakshireValeLayout.Petal.ORCHARD, "[D3]", "Flagstone-Hollow", "Lvl 3 Solo/Co-op Delve", 3, ScribeSignResource.Sign.SIGN_WARM_HEARTH, &"d3_root_cellar"],
	]
	for entry: Array in table:
		var frame: Transform3D = _vale.apron_portal(entry[0])
		var apron: Node3D = _scripted("PortalApron_%s" % String(entry[1]).trim_prefix("[").trim_suffix("]"), APRON_SCRIPT, Vector3.ZERO, {
			&"code": entry[1], &"title": entry[2], &"blurb": entry[3], &"required_level": entry[4], &"scribe_sign": entry[5], &"dungeon_id": entry[6]})
		apron.basis = frame.basis
		_put(_entity(apron), frame.origin, true)
		if entry[0] == OakshireValeLayout.Petal.ORCHARD:
			# The cellar's way in: a trapdoor in the apron floor before the arch.
			var hatch: MeshInstance3D = ShapeKit.box("Trapdoor", Vector3(2.4, 0.15, 2.0), Vector3.ZERO, _material(Color(0.42, 0.3, 0.18)))
			_put(hatch, frame.origin + frame.basis.z * 6.0 + Vector3(0.0, 0.08, 0.0))


# --- Creatures --------------------------------------------------------------------------

func _add_spawners() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1313
	var taken: Array[Vector2] = []
	for petal: int in _vale.petal_count():
		taken.append(Vector2(_vale.camp_center(petal).x, _vale.camp_center(petal).z))
	var trees: Array[Dictionary] = _vale.hero_trees()
	# 1. Meadow Vermin round the meadow, and Old Tusk-Crag at his hero tree.
	var vermin_packs: Array = [[&"cider_thief_bristleboar", &"cider_thief_bristleboar"], [&"thorn_tail_scuttler", &"thorn_tail_scuttler", &"cider_thief_bristleboar"],
		[&"cider_thief_bristleboar"], [&"thorn_tail_scuttler", &"thorn_tail_scuttler"]]
	for index: int in 10:
		var spot: Vector3 = _spot(rng, 36.0 * index + 8.0, 36.0 * index + 30.0, 170.0, 320.0, taken, 24.0)
		_spawner("Spawner_Vermin_%02d" % index, "The Settled Meadow", vermin_packs[index % vermin_packs.size()], spot, rng.randf_range(18.0, 25.0))
	_spawner("Spawner_OldTuskCrag", "The Settled Meadow", [&"old_tusk_crag"], _near_tree(trees[16], 9.0), 25.0)
	# 2. Weald Predators in the south weald and on the river's banks, and the Alpha Frost-Fang at his tree.
	for index: int in 6:
		var spot: Vector3 = _spot(rng, 142.0 + index * 13.0, 152.0 + index * 13.0, 390.0, 560.0, taken, 26.0)
		_spawner("Spawner_Prowlers_%02d" % index, "The Weald", [&"grey_pelt_prowler", &"grey_pelt_prowler"] if index % 2 == 0 else [&"grey_pelt_prowler"], spot, rng.randf_range(18.0, 25.0))
	for x: float in [300.0, 1120.0, 1290.0]:
		var river: Vector2 = OakshireValeLayout.river_at(x)
		var bank: Vector3 = _ground_at(Vector3(x, 0.0, river.x + 18.0))
		_spawner("Spawner_Toads_%d" % int(x), "The River Basin", [&"river_snapper_toad", &"river_snapper_toad"], bank, rng.randf_range(18.0, 25.0))
	_spawner("Spawner_AlphaFrostFang", "The Weald", [&"alpha_frost_fang"], _near_tree(trees[17], 10.0), 25.0)
	# 3. Soot-Paw Outlaws on the quarry terraces: a camp cluster of three pulls 12 m apart, and two more.
	var outlaw_pull: Array = [&"foreman_iron_gavel", &"soot_paw_cutthroat", &"quarry_sling_shotter"]
	var cluster: Vector3 = _spot(rng, 100.0, 124.0, 470.0, 540.0, taken, 30.0)
	for index: int in 3:
		var angle: float = TAU * index / 3.0
		var spot: Vector3 = _ground_at(cluster + Vector3(cos(angle), 0.0, sin(angle)) * 12.0 / sqrt(3.0))
		_spawner("Spawner_OutlawCamp_%d" % index, "Quarry-Wick", outlaw_pull, spot, rng.randf_range(18.0, 22.0))
	for index: int in 2:
		var spot: Vector3 = _spot(rng, 92.0 + index * 24.0, 112.0 + index * 22.0, 390.0, 470.0, taken, 26.0)
		_spawner("Spawner_Outlaws_%02d" % index, "Quarry-Wick", outlaw_pull, spot, rng.randf_range(18.0, 25.0))
	# 4. Blight-Thorn Briarlings in Bramble-Hollow.
	var briar_packs: Array = [[&"bramble_lasher_vine"], [&"spore_puff_shambler", &"spore_puff_shambler"], [&"bog_hulk_tangler"],
		[&"bramble_lasher_vine", &"spore_puff_shambler"], [&"spore_puff_shambler", &"bramble_lasher_vine"]]
	for index: int in briar_packs.size():
		var spot: Vector3 = _spot(rng, 18.0 + index * 9.5, 27.0 + index * 9.5, 390.0, 570.0, taken, 26.0)
		_spawner("Spawner_Briars_%02d" % index, "Bramble-Hollow", briar_packs[index], spot, rng.randf_range(18.0, 25.0))
	# 5. Tarnished Chime-Wights on the barrows, and at the gates of the Mine, the Barrow and the Root-Sanctum.
	var wight_packs: Array = [[&"risen_shield_sworn_husk"], [&"hollow_scribe_acolyte", &"risen_shield_sworn_husk"], [&"barrow_warden_knell"],
		[&"risen_shield_sworn_husk", &"hollow_scribe_acolyte"]]
	for index: int in wight_packs.size():
		var spot: Vector3 = _spot(rng, 236.0 + index * 11.0, 246.0 + index * 11.0, 400.0, 560.0, taken, 26.0)
		_spawner("Spawner_Wights_%02d" % index, "Nine-Stones-Crossing", wight_packs[index], spot, rng.randf_range(18.0, 25.0))
	for petal: int in [OakshireValeLayout.Petal.WEALD, OakshireValeLayout.Petal.QUARRY, OakshireValeLayout.Petal.BARROWS]:
		var gate: Transform3D = _vale.apron_portal(petal)
		_spawner("Spawner_GateWights_%d" % petal, OakshireValeLayout.PETAL_NAMES[petal], [&"risen_shield_sworn_husk", &"hollow_scribe_acolyte"],
			_ground_at(gate.origin + gate.basis.z * 12.0), 18.0)
	var cellar: Transform3D = _vale.apron_portal(OakshireValeLayout.Petal.ORCHARD)
	_spawner("Spawner_Smugglers", "Pippin-Green", [&"soot_paw_cutthroat", &"quarry_sling_shotter"], _ground_at(cellar.origin + cellar.basis.z * 12.0), 18.0)
	# 6. The Crag-Back Cairn-Drake walks the High Road.
	var round_trip: PackedVector3Array = PackedVector3Array()
	for step: int in 36:
		round_trip.append(_vale.ring_road_point(TAU * step / 36.0))
	_spawner("Spawner_CragBackBehemoth", "The High Road", [&"crag_back_behemoth"], round_trip[0], 25.0, round_trip)


func _spawner(spawner_name: String, territory: String, ids: Array, at: Vector3, leash: float, patrol: PackedVector3Array = PackedVector3Array()) -> void:
	var variant_ids: Array[StringName] = []
	for id: Variant in ids:
		variant_ids.append(id as StringName)
	var node: Node3D = _scripted(spawner_name, SPAWNER_SCRIPT, Vector3.ZERO, {&"territory": territory, &"variant_ids": variant_ids, &"leash": leash,
		&"respawn_time": Vector2(45.0, 90.0), &"patrol": patrol})
	_put(_entity(node), at)


## A spot in a sector (bearings in degrees, superellipse distances) clear of roads, the river, clearings and other spawners.
func _spot(rng: RandomNumberGenerator, from_degrees: float, to_degrees: float, near: float, far: float, taken: Array[Vector2], spacing: float) -> Vector3:
	var best: Vector2 = Vector2.ZERO
	for attempt: int in 200:
		var theta: float = deg_to_rad(rng.randf_range(from_degrees, to_degrees))
		var d: float = rng.randf_range(near, far)
		var at: Vector2 = OakshireValeLayout.CENTER + Vector2(sin(theta), -cos(theta)) * d / OakshireValeLayout.superellipse_factor(theta)
		best = at
		if _vale.is_kept_clear(at.x, at.y, 8.0) or OakshireValeLayout._crowded(taken, at, spacing):
			continue
		var height: float = _vale.sample_height(at.x, at.y)
		if _vale._on_riser(height, d) or _vale._on_spur(at.x, at.y):
			continue
		break
	taken.append(best)
	return _ground_at(Vector3(best.x, 0.0, best.y))


func _near_tree(tree: Dictionary, gap: float) -> Vector3:
	var at: Vector3 = tree["position"]
	var toward: Vector3 = (Vector3(OakshireValeLayout.CENTER.x, at.y, OakshireValeLayout.CENTER.y) - at).normalized()
	return _ground_at(at + toward * (float(tree["radius"]) + gap))


## Golden-Fleece Sheep grazing the meadow near the village, and Red Foxes at the weald's edge.
func _add_flocks() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 707
	var taken: Array[Vector2] = []
	for index: int in 4:
		var spot: Vector3 = _spot(rng, 60.0 + index * 72.0, 100.0 + index * 72.0, 130.0, 240.0, taken, 30.0)
		_put(_scripted("SheepFlock%d" % index, FLOCK_SCRIPT, Vector3.ZERO, {&"kind": AmbientFlock.Kind.SHEEP, &"count": 5, &"roam_radius": 10.0, &"flock_seed": 11 + index}), spot)
	for index: int in 3:
		var spot: Vector3 = _spot(rng, 300.0 + index * 25.0, 320.0 + index * 25.0, 340.0, 420.0, taken, 30.0)
		_put(_scripted("Foxes%d" % index, FLOCK_SCRIPT, Vector3.ZERO, {&"kind": AmbientFlock.Kind.FOX, &"count": 2, &"roam_radius": 14.0, &"flock_seed": 41 + index}), spot)
