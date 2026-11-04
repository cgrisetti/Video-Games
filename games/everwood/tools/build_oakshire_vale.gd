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
##
## Phase 17 (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §5.1): the village's
## houses are stepped-gable kits round the Oakshire Homestead Hall, with the
## Kindle-Fire ring, the Armory & Scribe Desk pavilion, the Chime-Shrine
## pagoda, seven cedar bee-hives along the east woodline and two walled
## pumpkin patches; every camp has a Chime-Post; and each petal has its
## landmarks: Wayfarer-Green's hillside windmill and sheep-stiles,
## Pippin-Green's cider mill and walled orchard, Quarry-Wick's pulley-cranes,
## ashlar stacks and cairns, Bramble-Hollow's willow pools, Wind-Lanterns and
## Water-Shrine, and Nine-Stones-Crossing's ring of nine standing stones, its
## flagged causeway and the Threshold Bell-Frame. Bramble-Hollow's briars, the
## outlaws' camp and the barrow wights sit on Hush-Cracks.
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
## Quarry-Wick's terrace climbs (18 GDD §3.2): sleepers this far either side of each riser, guide-posts this far apart.
const TERRACE_CLIMB_HALF: float = 6.0
const TERRACE_POST_SPACING: float = 2.4
## The Nine-Stones causeway's guide-posts: this far apart, this far off its flags.
const CAUSEWAY_POST_SPACING: float = 3.2
const CAUSEWAY_POST_OFFSET: float = 1.15
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
## Oakshire-Wick's landmarks round the green (bearing in degrees, distance in metres).
const KINDLE_FIRE_AT: Vector2 = Vector2(300.0, 15.0)
const PAVILION_AT: Vector2 = Vector2(76.0, 37.0)
const PAGODA_AT: Vector2 = Vector2(220.0, 37.0)
const HIVE_ARC_AT: Vector2 = Vector2(88.0, 74.0)
const PUMPKIN_PATCH_AT: Array[Vector2] = [Vector2(150.0, 74.0), Vector2(290.0, 74.0)]
const VILLAGE_POST_AT: Vector2 = Vector2(193.0, 58.0)
## Spawners that sit on a Hush-Crack (17 GDD §5.1).
const HUSH_CRACK_SPAWNERS: Array[String] = ["Spawner_Briars_", "Spawner_OutlawCamp_0", "Spawner_Wights_"]
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
	# The HLOD bakes read every kit the moment its landblock is in the tree.
	WorldKitInstance.immediate = true
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
	var cartography: Dictionary = {"footprints": [], "cracks": []}
	for chunk: Vector2i in _roots:
		_record_cartography(_roots[chunk], cartography)
	var listing: String = OakshireValeLayout.LANDBLOCK_FOLDER + CartographyBaker.CARTOGRAPHY_FILE
	_results.append("%s -> %s" % [listing, error_string(_save_cartography(cartography, listing))])
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
	_add_terrace_climbs()
	_add_spawners()
	_add_flocks()


## The slope contract on Quarry-Wick's terraces (18 GDD §3.2): where the
## quarry road climbs past each terrace riser, half-set log sleepers across it
## and low guide-posts both sides, so the way up reads at a glance.
func _add_terrace_climbs() -> void:
	var petal: int = OakshireValeLayout.Petal.QUARRY
	var step: float = (OakshireValeLayout.TERRACE_TOP - OakshireValeLayout.MEADOW_HEIGHT) / OakshireValeLayout.TERRACE_COUNT
	var run: float = (OakshireValeLayout.CLIFF_FOOT - OakshireValeLayout.MEADOW_OUTER) / OakshireValeLayout.TERRACE_COUNT
	for riser: int in range(1, OakshireValeLayout.TERRACE_COUNT):
		# The riser's middle, as a ring distance: just short of the shelf boundary.
		var target: float = OakshireValeLayout.MEADOW_OUTER + run * riser - run * OakshireValeLayout.TERRACE_RISER * 0.5
		var r: float = OakshireValeLayout.ROAD_START
		while r < _vale.road_end(petal):
			var point: Vector3 = _vale.road_point(petal, r)
			if OakshireValeLayout.ring_distance(Vector2(point.x, point.z) - OakshireValeLayout.CENTER) >= target:
				break
			r += 0.5
		if r >= _vale.road_end(petal):
			continue
		var foot: Vector3 = _vale.road_point(petal, r - TERRACE_CLIMB_HALF)
		var top: Vector3 = _vale.road_point(petal, r + TERRACE_CLIMB_HALF)
		var length: float = Vector2(foot.x, foot.z).distance_to(Vector2(top.x, top.z))
		_put(WorldKitInstance.make("TerraceSleepers%d" % riser, WorldVisualCatalog.KIT_PATH_SLEEPER, Vector3.ZERO, _facing(foot, Vector3(top.x, foot.y, top.z)),
			{&"size": Vector3(OakshireValeLayout.ROAD_HALF_WIDTH * 2.0 - 1.4, maxf(top.y - foot.y, 0.05), length), &"seed_value": 30 + riser}), foot, false)
		var posts: int = int(length / TERRACE_POST_SPACING) + 1
		for index: int in posts:
			var t: float = float(index) / maxf(1.0, posts - 1)
			var along: Vector3 = _vale.road_point(petal, lerpf(r - TERRACE_CLIMB_HALF, r + TERRACE_CLIMB_HALF, t))
			var ahead: Vector3 = _vale.road_point(petal, lerpf(r - TERRACE_CLIMB_HALF, r + TERRACE_CLIMB_HALF, t) + 1.0)
			var across: Vector3 = Vector3(ahead.z - along.z, 0.0, along.x - ahead.x).normalized()
			for side: float in [-1.0, 1.0]:
				var at: Vector3 = _ground_at(along + across * side * (OakshireValeLayout.ROAD_HALF_WIDTH + 0.45))
				_put(_guide_post("TerracePost%d%s%d" % [riser, "L" if side < 0.0 else "R", index], Vector3.ZERO), at - Vector3(0.0, 0.04, 0.0), false)
	if step <= 0.0:
		push_warning("build_oakshire_vale: the terraces have no rise")


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
			var variant: StringName = &"OAKSHIRE_HOMESTEAD_HALL" if house_index == 0 else &"VILLAGE_COTTAGE"
			var house: StaticBody3D = _house("House%d" % house_index, Vector3.ZERO, VALE_HOUSE_COLORS[house_index % VALE_HOUSE_COLORS.size()], variant, PI * 0.5)
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
			var dye: Color = WorldAssetCatalog.MARKET_DYES[vendor_index % WorldAssetCatalog.MARKET_DYES.size()]
			_put(_stall("Stall%d" % vendor_index, dye, _facing(spot, center), vendor_index), spot, true)
			var entry: Array = VENDORS[vendor_index]
			var behind: Vector3 = _around(center, bearing_degrees, STALL_RADIUS + 1.6)
			_npc(TownsfolkNPC.Role.VENDOR, entry[0], entry[1], "Oakshire-Wick", PackedStringArray(), entry[2], entry[3], behind, _facing(behind, center),
				PackedVector3Array(), STALL_COLORS[vendor_index % STALL_COLORS.size()].darkened(0.2), Color(0.86, 0.8, 0.66))
			vendor_index += 1
	_add_quest_hub("Oakshire-Wick", center, 7.0, 150.0)
	_add_village_landmarks(center)
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


## A market stall: an artisan timber pavilion under striped linen in one of the
## market's four heritage dyes (kit_market_pavilion, 18 GDD §4.3), its counter the collider.
func _stall(stall_name: String, dye: Color, yaw: float, seed_value: int) -> StaticBody3D:
	var stall: StaticBody3D = StaticBody3D.new()
	stall.name = stall_name
	stall.collision_layer = ActorBase.LAYER_LOW_SCENERY
	stall.collision_mask = 0
	stall.rotation.y = yaw
	stall.add_child(WorldKitInstance.make("Kit", WorldVisualCatalog.KIT_MARKET_PAVILION, Vector3.ZERO, 0.0,
		{&"tint": dye, &"accent": WorldAssetCatalog.MARKET_LINEN, &"seed_value": seed_value}))
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
	# Wind-Lanterns at its four corners.
	for side: float in [-1.0, 1.0]:
		for rail: float in [-1.0, 1.0]:
			var corner: Vector3 = frame.origin + frame.basis.z * side * (SPAN_MIDDLE + SPAN_RAMP + 1.0) + frame.basis.x * rail * (SPAN_WIDTH * 0.5 + 0.8)
			_put(_lantern("BridgeLantern", Vector3.ZERO), _ground_at(corner), true)
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
	var mill: StaticBody3D = _collider("Watermill", Vector3(6.0, 5.0, 6.0), Vector3.ZERO)
	_put(mill, at, true)
	mill.position.y += 2.5
	mill.add_child(WorldKitInstance.make("Kit", WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE, Vector3(0.0, -2.5, 0.0), PI * 0.5,
		{&"size": Vector3(6.0, 4.4, 6.0), &"tint": MILL_COLOR, &"accent": ROOF_TINTS[1]}))
	var river: Vector2 = OakshireValeLayout.river_at(at.x)
	var wheel: Node3D = _node3d("WaterWheel")
	wheel.set_script(load(WHEEL_SCRIPT))
	wheel.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	var wheel_at: Vector3 = Vector3(at.x, 2.4, lerpf(at.z, river.x, 0.55))
	_put(wheel, wheel_at, true)
	_put(WorldKitInstance.make("MillRace", WorldVisualCatalog.KIT_WATERMILL_WHEEL, Vector3.ZERO, 0.0, {&"height": WatermillWheel.RADIUS}), wheel_at, true)
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
		prism.material = WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.LIME_PLASTER, TENT_COLOR.lerp(STALL_COLORS[petal], 0.3))
		cloth.mesh = prism
		cloth.position = Vector3(0.0, 1.2, 0.0)
		tent.add_child(cloth)
		(tent.get_child(0) as CollisionShape3D).shape = _tent_shape()
		(tent.get_child(0) as CollisionShape3D).position = Vector3(0.0, 1.0, 0.0)
		_put(tent, spot, true)
		tent.rotation.y = _facing(spot, center)
	_add_quest_hub(hub, center, 4.5, OakshireValeLayout.PETAL_BEARINGS[petal] + 180.0)
	var post_radius: float = (OakshireValeLayout.GLADE_RADIUS if glade else OakshireValeLayout.CAMP_RADIUS) - 2.5
	_put(_chime_post("ChimePost", _around(center, OakshireValeLayout.PETAL_BEARINGS[petal] + 60.0, post_radius), hub),
		_around(center, OakshireValeLayout.PETAL_BEARINGS[petal] + 60.0, post_radius), true)
	_add_petal_landmarks(petal, center)
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


## An orchard tree hung with fruit (17 GDD kit_tree_orchard_apple).
func _fruit_tree(tree_name: String) -> Node3D:
	return _tree(tree_name, Vector3.ZERO, 4.8, true, WorldVisualCatalog.KIT_TREE_ORCHARD_APPLE)


# --- Phase 17 landmarks (17 GDD §5.1) ---------------------------------------------------

## Oakshire-Wick's Kindle-Fire ring, Armory & Scribe Desk pavilion, Chime-Shrine
## pagoda, bee-hives, walled pumpkin patches and its Chime-Post.
func _add_village_landmarks(center: Vector3) -> void:
	var fire_at: Vector3 = _around(center, KINDLE_FIRE_AT.x, KINDLE_FIRE_AT.y)
	_put(_kindle_fire(), fire_at, true)
	var pavilion_at: Vector3 = _around(center, PAVILION_AT.x, PAVILION_AT.y)
	var pavilion: StaticBody3D = _collider("ScribeDeskPavilion", Vector3(2.4, 0.9, 1.0), Vector3.ZERO)
	pavilion.add_child(WorldKitInstance.make("Kit", WorldVisualCatalog.KIT_SCRIBE_DESK_PAVILION, Vector3(0.0, -0.45, -0.35)))
	pavilion.add_child(ShapeKit.box("Desk", Vector3(2.4, 0.9, 1.0), Vector3.ZERO, WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.HEWN_TIMBER, WorldVisualCatalog.TIMBER)))
	_put(pavilion, pavilion_at + Vector3(0.0, 0.45, 0.0), true)
	pavilion.rotation.y = _facing(pavilion_at, center)
	var pagoda_at: Vector3 = _around(center, PAGODA_AT.x, PAGODA_AT.y)
	var pagoda: StaticBody3D = _low(_collider("ChimeShrinePagoda", Vector3(2.8, 0.6, 2.8), Vector3.ZERO, ActorBase.LAYER_LOW_SCENERY))
	pagoda.add_child(WorldKitInstance.make("Kit", WorldVisualCatalog.KIT_CHIME_SHRINE_PAGODA, Vector3(0.0, -0.3, -0.4)))
	for index: int in 5:
		var chime: MeshInstance3D = MeshInstance3D.new()
		chime.name = "Chime%d" % (index + 1)
		chime.mesh = WorldAssetCatalog.chime_mesh([0.9, 0.8, 0.7, 0.6, 0.52][index])
		chime.position = Vector3((float(index) - 2.0) * 0.42, 2.95, 0.0)
		pagoda.add_child(chime)
	_put(pagoda, pagoda_at + Vector3(0.0, 0.3, 0.0), true)
	pagoda.rotation.y = _facing(pagoda_at, center)
	# Seven cedar hives in a south-facing convex arc along the east woodline, and their bees.
	var arc_center: Vector3 = _around(center, HIVE_ARC_AT.x, HIVE_ARC_AT.y)
	for index: int in HIVE_COUNT:
		var angle: float = lerpf(PI * 0.12, PI * 0.88, float(index) / (HIVE_COUNT - 1))
		var at: Vector3 = _ground_at(arc_center + Vector3(cos(angle) * HIVE_ARC_RADIUS, 0.0, -sin(angle) * HIVE_ARC_RADIUS))
		var hive: StaticBody3D = _low(_collider("Hive%d" % (index + 1), Vector3(0.66, 1.2, 0.6), Vector3(0.0, 0.6, 0.0), ActorBase.LAYER_LOW_SCENERY))
		hive.add_child(WorldKitInstance.make("Kit", WorldVisualCatalog.KIT_BEE_HIVE, Vector3(0.0, -0.6, 0.0), 0.0, {&"height": float(2 + index % 2)}))
		_put(hive, at + Vector3(0.0, 0.6, 0.0), true)
	_put(_bees("Bees", Vector3.ZERO, Vector3(HIVE_ARC_RADIUS, 0.5, HIVE_ARC_RADIUS * 0.5)), arc_center + Vector3(0.0, 1.0, -HIVE_ARC_RADIUS * 0.6), true)
	# Two heirloom pumpkin patches inside knee-high dry-stone walls, open toward the green.
	for index: int in PUMPKIN_PATCH_AT.size():
		var at: Vector3 = _around(center, PUMPKIN_PATCH_AT[index].x, PUMPKIN_PATCH_AT[index].y)
		var patch: Node3D = _pumpkin_patch("PumpkinPatch%d" % (index + 1), Rect2(-5.0, -3.5, 10.0, 7.0), index, 1.0)
		_put(patch, at, true)
		patch.rotation.y = _facing(at, center) + PI * 0.5
	var post_at: Vector3 = _around(center, VILLAGE_POST_AT.x, VILLAGE_POST_AT.y)
	_put(_chime_post("VillageChimePost", Vector3.ZERO, "Oakshire-Wick"), post_at, true)


## The Kindle-Fire ring: river stones round a crackling fire, an iron tripod and kettle, and quilted travel packs.
func _kindle_fire() -> Node3D:
	var fire: Node3D = _node3d("KindleFire")
	var stone: Material = WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.CRAG_GRANITE, Color(0.6, 0.6, 0.58), false, 0.4)
	for index: int in 12:
		var angle: float = TAU * float(index) / 12.0
		fire.add_child(ShapeKit.stretched(ShapeKit.sphere("RingStone%d" % index, 0.28, Vector3(cos(angle) * 1.4, 0.1, sin(angle) * 1.4), stone), Vector3(1.2, 0.6, 1.0)))
	for log_index: int in 4:
		var log_mesh: MeshInstance3D = ShapeKit.cylinder("Log%d" % log_index, 0.12, 0.12, 1.4, Vector3(0.0, 0.14, 0.0),
			WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.HEWN_TIMBER, Color(0.36, 0.24, 0.14)), 6)
		log_mesh.rotation = Vector3(PI * 0.5, log_index * PI * 0.25, 0.0)
		fire.add_child(log_mesh)
	fire.add_child(ShapeKit.no_shadow(ShapeKit.sphere("Flames", 0.5, Vector3(0.0, 0.45, 0.0), WorldVisualCatalog.glowing(FIRE_COLOR, 2.5))))
	var iron: Material = WorldVisualCatalog.painted(WorldAssetCatalog.IRON)
	for leg: int in 3:
		var angle: float = TAU * float(leg) / 3.0
		fire.add_child(_beam("TripodLeg%d" % leg, Vector3(cos(angle) * 1.1, 0.0, sin(angle) * 1.1), Vector3(0.0, 1.7, 0.0), 0.04, iron))
	fire.add_child(ShapeKit.sphere("Kettle", 0.22, Vector3(0.0, 1.05, 0.0), iron))
	var steam: CPUParticles3D = _mist("Steam", Vector3(0.0, 1.35, 0.0), Vector3(0.1, 0.05, 0.1))
	steam.amount = 8
	steam.scale_amount_min = 0.2
	steam.scale_amount_max = 0.5
	fire.add_child(steam)
	for pack: int in 3:
		var angle: float = 0.6 + pack * 1.9
		var quilt: Color = [Color(0.72, 0.34, 0.3), Color(0.32, 0.46, 0.66), Color(0.82, 0.68, 0.36)][pack]
		fire.add_child(ShapeKit.stretched(ShapeKit.sphere("Pack%d" % pack, 0.35, Vector3(cos(angle) * 2.4, 0.25, sin(angle) * 2.4), WorldVisualCatalog.painted(quilt)),
			Vector3(1.3, 0.8, 1.0)))
	fire.add_child(WorldAssetCatalog.light("FireGlow", FIRE_COLOR, 1.4, 6.0))
	(fire.get_node("FireGlow") as OmniLight3D).position = Vector3(0.0, 1.0, 0.0)
	return fire


## A petal's landmarks (17 GDD §5.1), set round its camp clear of roads, the river and the aprons.
func _add_petal_landmarks(petal: int, center: Vector3) -> void:
	var village: Vector3 = Vector3(OakshireValeLayout.CENTER.x, center.y, OakshireValeLayout.CENTER.y)
	var outward: Vector3 = (center - village).normalized()
	outward.y = 0.0
	var across: Vector3 = outward.cross(Vector3.UP).normalized()
	var radius: float = OakshireValeLayout.GLADE_RADIUS if petal == OakshireValeLayout.Petal.GLADE else OakshireValeLayout.CAMP_RADIUS
	match petal:
		OakshireValeLayout.Petal.GLADE:
			var mill_at: Vector3 = _clear_spot(center, outward, across, -4.0, radius + 12.0, 3.0)
			if mill_at != Vector3.INF:
				var windmill: StaticBody3D = _collider("Windmill", Vector3(4.2, 8.0, 4.2), Vector3(0.0, 4.0, 0.0))
				windmill.add_child(WorldKitInstance.make("Kit", WorldVisualCatalog.KIT_WINDMILL, Vector3(0.0, -4.0, 0.0), 0.0, {&"spin_speed": 0.45}))
				_put(windmill, mill_at + Vector3(0.0, 4.0, 0.0), true)
				windmill.rotation.y = _facing(mill_at, mill_at - across)
				for stile: int in 2:
					var stile_at: Vector3 = _clear_spot(center, outward, across, 6.0 + stile * 8.0, radius + 6.0 + stile * 3.0, 1.0)
					if stile_at != Vector3.INF:
						_put(_sheep_stile("SheepStile%d" % stile), stile_at, true)
		OakshireValeLayout.Petal.ORCHARD:
			var cider_at: Vector3 = _clear_spot(center, -outward, across, 30.0, -26.0, 4.0)
			if cider_at != Vector3.INF:
				var cider: StaticBody3D = _collider("CiderMill", Vector3(5.0, 3.4, 5.0), Vector3(0.0, 1.7, 0.0))
				cider.add_child(WorldKitInstance.make("Kit", WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE, Vector3(0.0, -1.7, 0.0), PI * 0.5,
					{&"size": Vector3(5.0, 3.4, 5.0), &"tint": Color(0.86, 0.78, 0.6), &"accent": ROOF_TINTS[0]}))
				_put(cider, cider_at + Vector3(0.0, 1.7, 0.0), true)
				cider.rotation.y = _facing(cider_at, center)
				var barrels: Node3D = _node3d("CiderBarrels")
				for barrel: int in 4:
					barrels.add_child(ShapeKit.cylinder("Barrel%d" % barrel, 0.36, 0.32, 0.8, Vector3((barrel % 2) * 0.8, 0.4, floorf(barrel * 0.5) * 0.8),
						WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.HEWN_TIMBER, Color(0.5, 0.34, 0.2)), 10))
				_put(barrels, _ground_at(cider_at + across * 4.5), true)
			for side: float in [-1.0, 1.0]:
				var from: Vector3 = center - outward * 22.0 + across * side * 16.0
				_put(_drystone_run("OrchardWall", 20.0), _ground_at(from - outward * 10.0), true).rotation.y = _facing(from, from - outward) + PI * 0.5
		OakshireValeLayout.Petal.QUARRY:
			for crane: int in 2:
				var at: Vector3 = _clear_spot(center, outward, across, 6.0 + crane * 6.0, (radius + 8.0) * (1.0 if crane == 0 else -1.0), 2.5)
				if at != Vector3.INF:
					var body: StaticBody3D = _collider("Crane%d" % crane, Vector3(3.4, 5.6, 0.6), Vector3(0.0, 2.8, 0.0))
					body.add_child(WorldKitInstance.make("Kit", WorldVisualCatalog.KIT_QUARRY_CRANE, Vector3(0.0, -2.8, 0.0)))
					_put(body, at + Vector3(0.0, 2.8, 0.0), true)
					body.rotation.y = _facing(at, center)
			for stack: int in 3:
				var at: Vector3 = _clear_spot(center, outward, across, -6.0 + stack * 7.0, radius + 4.0 + stack * 2.0, 2.0)
				if at != Vector3.INF:
					var body: StaticBody3D = _low(_collider("Ashlar%d" % stack, Vector3(3.0, 1.7, 1.5), Vector3(0.0, 0.85, 0.0), ActorBase.LAYER_LOW_SCENERY))
					body.add_child(WorldKitInstance.make("Kit", WorldVisualCatalog.KIT_ASHLAR_STACK, Vector3(0.0, -0.85, 0.0), 0.0, {&"seed_value": stack}))
					_put(body, at + Vector3(0.0, 0.85, 0.0), true)
					body.rotation.y = _facing(at, center)
			for cairn: int in 3:
				var at: Vector3 = _clear_spot(center, outward, across, 14.0 + cairn * 5.0, -(radius + 3.0 + cairn * 4.0), 1.5)
				if at != Vector3.INF:
					_put(WorldKitInstance.make("Cairn%d" % cairn, WorldVisualCatalog.KIT_HUSH_CRACK_AND_CAIRN, Vector3.ZERO, cairn * 1.3, {&"variant": &"CAIRN"}), at, true)
		OakshireValeLayout.Petal.WEALD:
			for pool: int in 3:
				var at: Vector3 = _clear_spot(center, outward, across, -4.0 + pool * 9.0, (radius + 9.0) * (1.0 if pool != 1 else -1.0), 4.0)
				if at != Vector3.INF:
					_put(_willow_pool("WillowPool%d" % pool, pool), at, true)
			for lantern: int in 3:
				var at: Vector3 = _clear_spot(center, outward, across, -10.0 + lantern * 8.0, -(radius + 2.5), 0.8)
				if at != Vector3.INF:
					_put(_hanging_lantern("HollowLantern%d" % lantern), at, true).rotation.y = _facing(at, center)
			var shrine_at: Vector3 = _clear_spot(center, -outward, across, 8.0, radius + 5.0, 2.0)
			if shrine_at != Vector3.INF:
				_put(_scripted("WaterShrine", SHRINE_WATER_SCRIPT, Vector3.ZERO, {}), shrine_at, true)
		OakshireValeLayout.Petal.BARROWS:
			var ring_at: Vector3 = _clear_spot(center, outward, across, 2.0, radius + 16.0, 10.0)
			if ring_at == Vector3.INF:
				return
			for stone: int in 9:
				var angle: float = TAU * float(stone) / 9.0
				var at: Vector3 = _ground_at(ring_at + Vector3(cos(angle), 0.0, sin(angle)) * 8.0)
				var body: StaticBody3D = _collider("NineStone%d" % (stone + 1), Vector3(1.2, 3.6, 0.8), Vector3(0.0, 1.8, 0.0))
				body.add_child(WorldKitInstance.make("Kit", WorldVisualCatalog.KIT_STANDING_STONE, Vector3(0.0, -1.8, 0.0), 0.0,
					{&"size": Vector3(1.2, 3.6 + float(stone % 3) * 0.4, 0.8), &"tint": Color(0.56, 0.58, 0.6), &"seed_value": 70 + stone}))
				_put(body, at + Vector3(0.0, 1.8, 0.0), true)
				body.rotation.y = _facing(at, ring_at)
			# The Threshold Bell-Frame in the middle, and an old flagged causeway back to the camp.
			var frame: Node3D = WorldKitInstance.make("ThresholdBellFrame", WorldVisualCatalog.KIT_CHIME_SHRINE_PAGODA, Vector3.ZERO, 0.0, {&"size": Vector3(2.6, 3.0, 2.0)})
			var bell: MeshInstance3D = MeshInstance3D.new()
			bell.name = "Bell"
			bell.mesh = WorldAssetCatalog.chime_mesh(0.9)
			bell.scale = Vector3(1.8, 0.8, 1.8)
			bell.position = Vector3(0.0, 3.0, 0.4)
			frame.add_child(bell)
			_put(frame, ring_at, true)
			var steps: int = int(center.distance_to(ring_at) / 1.6)
			for step: int in steps:
				var t: float = float(step) / maxf(1.0, steps)
				var at: Vector3 = _ground_at(center.lerp(ring_at, t))
				var flag: MeshInstance3D = ShapeKit.box("Flagstone", Vector3(1.6, 0.12, 1.2), Vector3.ZERO,
					WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.COBBLED_FLAGSTONE, Color(0.74, 0.72, 0.66), false, 0.4))
				flag.rotation.y = _facing(center, ring_at) + sin(step * 2.3) * 0.15
				_put(flag, at + Vector3(0.0, 0.0, 0.0), false)
			# Low guide-posts both sides of the causeway's approach (18 GDD §3.2).
			var sideways: Vector3 = (ring_at - center).cross(Vector3.UP).normalized()
			var posts: int = int(center.distance_to(ring_at) / CAUSEWAY_POST_SPACING)
			for post: int in range(1, posts):
				var t: float = float(post) / posts
				for side: float in [-1.0, 1.0]:
					var at: Vector3 = _ground_at(center.lerp(ring_at, t) + sideways * side * CAUSEWAY_POST_OFFSET)
					_put(_guide_post("CausewayPost%s%d" % ["L" if side < 0.0 else "R", post], Vector3.ZERO), at - Vector3(0.0, 0.04, 0.0), false)


## A spot `ahead` metres along `outward` and `side` along `across` from `center`,
## nudged further out until it's clear of roads, the river and the aprons by `margin` (INF if none is).
func _clear_spot(center: Vector3, outward: Vector3, across: Vector3, ahead: float, side: float, margin: float) -> Vector3:
	for nudge: int in 6:
		var at: Vector3 = center + outward * ahead + across * (side + signf(side) * nudge * 4.0)
		var flat: Vector2 = Vector2(at.x, at.z)
		var river: float = OakshireValeLayout.river_distance(at.x, at.z)
		if _vale.road_lateral(at.x, at.z) < OakshireValeLayout.ROAD_HALF_WIDTH + 2.5 + margin or river < OakshireValeLayout.RIVER_HALF_WIDTH + 6.0 + margin:
			continue
		var on_apron: bool = false
		for apron: int in OakshireValeLayout.APRON_PETALS:
			var local: Vector2 = _vale.apron_local(apron, flat)
			on_apron = on_apron or (local.x > -OakshireValeLayout.APRON_INSIDE - 10.0 and absf(local.y) < OakshireValeLayout.APRON_HALF_WIDTH + 2.0 + margin)
		if on_apron:
			continue
		return _ground_at(at)
	return Vector3.INF


## A clay Wind-Lantern hanging from a timber post and bracket (it sways and chimes as players pass).
func _hanging_lantern(lantern_name: String) -> Node3D:
	var post: Node3D = _node3d(lantern_name)
	var timber: Material = WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.HEWN_TIMBER, WorldVisualCatalog.TIMBER, false, 0.3)
	post.add_child(ShapeKit.box("Post", Vector3(0.18, 3.5, 0.18), Vector3(0.0, 1.75, 0.0), timber))
	post.add_child(_beam("Bracket", Vector3(0.0, 3.3, 0.0), Vector3(0.75, 3.4, 0.0), 0.06, timber))
	post.add_child(_scripted("WindLantern", LANTERN_SCRIPT, Vector3(0.7, 3.35, 0.0), {}))
	return post


## A sheep-stile: three timber steps over a short stretch of dry-stone wall.
func _sheep_stile(stile_name: String) -> Node3D:
	var stile: Node3D = _node3d(stile_name)
	stile.add_child(WorldKitInstance.make("Wall", WorldVisualCatalog.KIT_DRYSTONE_WALL, Vector3.ZERO, 0.0, {&"size": Vector3(4.0, 0.8, 0.6)}))
	var timber: Material = WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.HEWN_TIMBER, WorldVisualCatalog.TIMBER)
	for step: int in 3:
		for side: float in [-1.0, 1.0]:
			stile.add_child(ShapeKit.box("Step%d" % step, Vector3(0.9, 0.08, 0.35), Vector3(0.0, 0.3 + step * 0.28, side * (0.75 - step * 0.22)), timber))
	return stile


## A run of knee-high dry-stone wall `length` long (along local X), on the LowScenery layer.
func _drystone_run(wall_name: String, length: float) -> StaticBody3D:
	var wall: StaticBody3D = _low(_collider(wall_name, Vector3(length, 0.8, 0.6), Vector3.ZERO, ActorBase.LAYER_LOW_SCENERY))
	(wall.get_node("Collision") as CollisionShape3D).position = Vector3(0.0, 0.4, 0.0)
	wall.add_child(WorldKitInstance.make("Stones", WorldVisualCatalog.KIT_DRYSTONE_WALL, Vector3.ZERO, 0.0, {&"size": Vector3(length, 0.8, 0.6), &"seed_value": int(length)}))
	return wall


## A weeping willow trailing over a reed-fringed pool.
func _willow_pool(pool_name: String, index: int) -> Node3D:
	var pool: Node3D = _node3d(pool_name)
	var water: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.cylinder("Water", 2.6, 2.6, 0.05, Vector3(0.0, 0.06, 0.0), WorldVisualCatalog.water(&"flat", Vector2(0.05, 0.08)), 20))
	pool.add_child(water)
	var bank: Material = WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.MEADOW_TURF, WorldVisualCatalog.MOSS)
	pool.add_child(ShapeKit.torus("Bank", 2.5, 3.1, Vector3(0.0, 0.04, 0.0), bank))
	pool.add_child(_tree("Willow", Vector3(3.6, 0.0, 0.8), 8.0 + index * 0.6, true, WorldVisualCatalog.KIT_TREE_WEEPING_WILLOW))
	return pool


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
	var cracked: bool = false
	for prefix: String in HUSH_CRACK_SPAWNERS:
		cracked = cracked or spawner_name.begins_with(prefix)
	var node: Node3D = _scripted(spawner_name, SPAWNER_SCRIPT, Vector3.ZERO, {&"territory": territory, &"variant_ids": variant_ids, &"leash": leash,
		&"respawn_time": Vector2(45.0, 90.0), &"patrol": patrol, &"has_hush_crack": cracked})
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
