## Embershore's homes, yards and stock (docs/32_EMBERSHORE_THE_WORKED_LAND.md §7, §8),
## built once per visit by EmbershoreBuilder.build_structures from the worked
## land's file (EmbershoreSettlement): every steading's house, barn and byre
## (SteadingKit) on its own footing, what stands about its yard, its name on a
## board by the gate; the two villages' houses turned to face their lanes, each
## with its toft; the finger-posts, fords and cairns; and the flocks.
##
## A building's floor is the ground at its door, so on a slope it is dug into
## the bank behind and stands on its stone footing in front. Near, it is its
## crafted mesh; past SteadingKit.NEAR_RANGE, a one-draw stand-in.
class_name EmbershoreSteadings
extends RefCounted

## Every dwelling is in this group (the checks count the island's homes by it).
const HOMES: StringName = &"embershore_homes"
## A stepped-gable village house's roof by its look (docs/17 §2.1: clay, slate-blue or moss-green shingles).
const GABLE_ROOFS: Dictionary[String, Color] = {"gable_clay": WorldAssetCatalog.SHINGLE_CLAY, "gable_slate": WorldAssetCatalog.SHINGLE_SLATE,
	"gable_moss": WorldAssetCatalog.SHINGLE_MOSS, "inn": WorldAssetCatalog.SHINGLE_SLATE}
## Lime wash is never one white: each house's own, warm to cool.
const GABLE_WASHES: Array[Color] = [Color(0.78, 0.7, 0.58), Color(0.84, 0.78, 0.66), Color(0.8, 0.66, 0.56), Color(0.72, 0.72, 0.64), Color(0.86, 0.8, 0.6)]
const PROPS_RANGE: float = 150.0
const STEWARD_RANGE: float = 75.0
const SMOKE_RANGE: float = 380.0
## Yard pieces that block the way: a tall one a pillar (radius, height), a low one a box a hero can hop.
const PROP_PILLARS: Dictionary[String, Vector2] = {"rick": Vector2(2.3, 4.6), "well": Vector2(0.95, 0.9), "well_dry": Vector2(0.95, 0.9),
	"charcoal_clamp": Vector2(1.7, 1.2), "cairn": Vector2(0.9, 1.6)}
const PROP_BOXES: Dictionary[String, Vector3] = {"cart": Vector3(2.6, 0.9, 1.5), "cart_broken": Vector3(2.6, 0.8, 1.5), "woodpile": Vector3(2.2, 0.9, 1.0),
	"boat": Vector3(4.6, 0.7, 1.5), "timber_stack": Vector3(4.2, 0.9, 2.0), "hives": Vector3(2.6, 0.9, 0.7), "bench": Vector3(1.6, 0.45, 0.4)}


static func build(root: Node3D, builder: EmbershoreBuilder) -> void:
	var settlement: EmbershoreSettlement = builder.settlement
	var holder: Node3D = Node3D.new()
	holder.name = "WorkedLand"
	root.add_child(holder)
	for steading: Variant in settlement.list("steadings"):
		_build_steading(holder, builder, steading as Dictionary)
	var house_in: Dictionary[String, int] = {}
	for plot: Variant in settlement.list("village_plots"):
		var entry: Dictionary = plot as Dictionary
		var village: String = String(entry.get("village", "")).capitalize()
		var index: int = int(house_in.get(village, 0))
		house_in[village] = index + 1
		_build_plot(holder, builder, entry, village, index)
	# Each village's well, benches and cart, on the free ground by its green.
	var greens: Dictionary[String, Array] = {}
	for prop: Variant in settlement.list("village_props"):
		var village: String = String((prop as Dictionary).get("village", "")).capitalize()
		if not greens.has(village):
			greens[village] = []
		greens[village].append(prop)
	for village: String in greens:
		var first: Vector2 = EmbershoreSettlement.at2((greens[village][0] as Dictionary)["at"])
		var green: Node3D = Node3D.new()
		green.name = village + "Green"
		green.position = builder.ground(first.x, first.y)
		holder.add_child(green)
		_build_props(green, holder, builder, greens[village], village + "Green")
	_build_waymarks(holder, builder, settlement.list("props"))
	_build_stock(holder, builder, settlement.list("flocks"))


# --- Steadings ---------------------------------------------------------------------------------------------

static func _build_steading(holder: Node3D, builder: EmbershoreBuilder, steading: Dictionary) -> void:
	var id: String = String(steading.get("id", "steading"))
	var at: Vector2 = EmbershoreSettlement.at2(steading["at"])
	var yard: Node3D = Node3D.new()
	yard.name = id.to_pascal_case()
	yard.position = builder.ground(at.x, at.y)
	holder.add_child(yard)
	var lived_in: bool = String(steading.get("kind", "")) != "flitted"
	var buildings: Array = steading.get("buildings", [])
	for index: int in buildings.size():
		var entry: Dictionary = buildings[index]
		if String(entry.get("kind", "")) == "fold":
			continue
		_build_home(holder, builder, entry, "%s%s%d" % [id.to_pascal_case(), String(entry["kind"]).to_pascal_case(), index], lived_in)
	_build_props(yard, holder, builder, steading.get("props", []), id.to_pascal_case())
	# Its name on a board by the gate, as every place on the island has.
	var gate: Vector2 = EmbershoreSettlement.at2(steading["gate"])
	if lived_in:
		_build_steward(holder, builder, steading, at, gate, id.to_pascal_case())
	var line: String = {"farm": "a farm", "hillfarm": "a hill farm", "croft": "a croft", "fisher": "a fisher's cot", "mill": "the miller's",
		"forester": "the wood-wright's cot", "flitted": "nobody has lived here for a long while"}.get(String(steading.get("kind", "")), "a steading")
	CalderaKit.sign_label(holder, id.to_pascal_case() + "Sign", "%s\n%s" % [String(steading.get("name", "")), line],
		builder.ground(gate.x, gate.y) + Vector3(0.0, 2.9, 0.0))


## Whoever keeps the steading, about their day's round: from the door to the well, out to the gate and back by the
## barn (a TownsfolkNPC villager: the same round on every peer, never in the way of a quest).
static func _build_steward(holder: Node3D, builder: EmbershoreBuilder, steading: Dictionary, at: Vector2, gate: Vector2, node_name: String) -> void:
	var facing: Vector2 = EmbershoreSettlement.facing_of(steading)
	var across: Vector2 = Vector2(-facing.y, facing.x)
	var stops: Array[Vector2] = [at - facing * 4.5 + across * 1.5, at + across * 5.0 + facing * 3.0, gate - facing * 2.5, at - across * 6.5 + facing * 1.0]
	var steward: TownsfolkNPC = TownsfolkNPC.new()
	steward.name = node_name + "Steward"
	steward.role = TownsfolkNPC.Role.VILLAGER
	steward.npc_seed = 300 + node_name.hash() % 500
	steward.body_color = [Color(0.46, 0.4, 0.3), Color(0.36, 0.44, 0.34), Color(0.5, 0.36, 0.3), Color(0.38, 0.42, 0.52)][steward.npc_seed % 4]
	steward.accent_color = Color(0.82, 0.74, 0.56)
	var route: PackedVector3Array = PackedVector3Array()
	for index: int in range(1, stops.size()):
		route.append(builder.ground(stops[index].x, stops[index].y))
	steward.route = route
	steward.position = builder.ground(stops[0].x, stops[0].y)
	holder.add_child(steward)
	# Seen from across the yard, not across the valley: a figure is fifteen thousand triangles.
	for part: Node in steward.find_children("*", "GeometryInstance3D", true, false):
		(part as GeometryInstance3D).visibility_range_end = STEWARD_RANGE
		(part as GeometryInstance3D).visibility_range_end_margin = 8.0


## One building: a village's stepped-gable house (docs/17's kit, turned to its lane) or one of the valley's own (SteadingKit).
static func _build_home(holder: Node3D, builder: EmbershoreBuilder, entry: Dictionary, node_name: String, lived_in: bool) -> Node3D:
	var kind: String = String(entry.get("kind", "cottage"))
	var look: String = String(entry.get("look", "slate_stone"))
	var at: Vector2 = EmbershoreSettlement.at2(entry["at"])
	var facing: Vector2 = EmbershoreSettlement.facing_of(entry)
	var size: Vector2 = Vector2(float((entry["size"] as Array)[0]), float((entry["size"] as Array)[1]))
	var seed_value: int = int(entry.get("seed", 1))
	if kind == "house" or kind == "inn":
		return _build_gable_house(holder, builder, at, facing, look, kind == "inn", seed_value, node_name)
	# The floor is the ground at the door; the footing goes down to the lowest corner.
	var across: Vector2 = Vector2(-facing.y, facing.x)
	var door: Vector2 = at + facing * (size.y * 0.5 + 0.3)
	var floor_y: float = builder.height_at(door.x, door.y) - 0.02
	var lowest: float = floor_y
	for hand: float in [-1.0, 1.0]:
		for deep: float in [-1.0, 1.0]:
			var corner: Vector2 = at + across * hand * size.x * 0.5 + facing * deep * size.y * 0.5
			lowest = minf(lowest, builder.height_at(corner.x, corner.y))
	var footing: float = clampf(ceilf((floor_y - lowest + 0.35) / 0.5) * 0.5, 0.5, 5.0)
	var home: Node3D = Node3D.new()
	home.name = node_name
	home.position = Vector3(at.x, floor_y, at.y)
	home.rotation.y = atan2(facing.x, facing.y)
	holder.add_child(home)
	var near: MeshInstance3D = MeshInstance3D.new()
	near.name = "Near"
	near.mesh = SteadingKit.mesh(kind, look, size, footing, seed_value)
	near.visibility_range_end = SteadingKit.NEAR_RANGE
	near.visibility_range_end_margin = 20.0
	home.add_child(near)
	var far: MeshInstance3D = MeshInstance3D.new()
	far.name = "Far"
	far.mesh = SteadingKit.far_mesh(kind, look, size, footing)
	far.material_override = CalderaKit.vertex_material()
	far.visibility_range_begin = SteadingKit.NEAR_RANGE
	far.visibility_range_begin_margin = 20.0
	far.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	home.add_child(far)
	if kind == "cottage" or kind == "farmhouse":
		home.add_to_group(HOMES)
		if lived_in:
			var tops: Array[Vector3] = SteadingKit.chimneys(kind, look, size)
			for index: int in tops.size():
				var smoke: CPUParticles3D = WorldAssetCatalog.smoke("Smoke%d" % index, tops[index], 7 if index == 0 else 4)
				smoke.visibility_range_end = SMOKE_RANGE
				home.add_child(smoke)
			var glow: OmniLight3D = WorldAssetCatalog.light("DoorGlow", WorldAssetCatalog.WINDOW_GLOW, 0.5, 4.0)
			glow.position = Vector3(0.0, 1.6, size.y * 0.5 + 1.0)
			home.add_child(glow)
	var tall: float = SteadingKit.wall_height(kind) + (1.2 if kind != "ruin" else 0.0)
	if kind == "ruin":
		# A ruin is walked into: only its standing gable and back wall block the way.
		var turn: Basis = Basis(Vector3.UP, home.rotation.y)
		CalderaKit.solid_box(holder, node_name + "Gable", home.position + turn * Vector3(-size.x * 0.5 + 0.25, tall * 0.5, 0.0), Vector3(0.6, tall, size.y), home.rotation.y)
		CalderaKit.solid_box(holder, node_name + "Back", home.position + turn * Vector3(0.0, 0.9, -size.y * 0.5 + 0.25), Vector3(size.x, 1.8, 0.6), home.rotation.y)
	else:
		CalderaKit.solid_box(holder, node_name + "Body", home.position + Vector3(0.0, (tall - footing) * 0.5, 0.0), Vector3(size.x, tall + footing, size.y), home.rotation.y)
	return home


static func _build_gable_house(holder: Node3D, builder: EmbershoreBuilder, at: Vector2, facing: Vector2, look: String, inn: bool, seed_value: int,
		node_name: String) -> Node3D:
	var spot: Vector3 = builder.ground(at.x, at.y)
	# The kit's door is on its +X side: turn that to the lane.
	var yaw: float = atan2(-facing.y, facing.x)
	var options: Dictionary = {"seed_value": seed_value, "accent": GABLE_ROOFS.get(look, WorldAssetCatalog.SHINGLE_CLAY),
		"tint": GABLE_WASHES[seed_value % GABLE_WASHES.size()]}
	if inn:
		options["variant"] = &"OAKSHIRE_HOMESTEAD_HALL"
	elif seed_value % 9 == 5:
		options["variant"] = &"SMOKING_BAKERY"
	var house: WorldKitInstance = WorldKitInstance.make(node_name, WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE, spot, yaw, options)
	if inn:
		house.scale = Vector3.ONE * 1.15
	house.add_to_group(HOMES)
	holder.add_child(house)
	var body: Vector3 = Vector3(6.4, 5.0, 5.6) * (1.15 if inn else 1.0)
	CalderaKit.solid_box(holder, node_name.replace("House", "HouseBody").replace("Inn", "InnBody"), spot + Vector3(0.0, 2.5, 0.0), body, yaw)
	return house


# --- The villages' tofts -----------------------------------------------------------------------------------------

static func _build_plot(holder: Node3D, builder: EmbershoreBuilder, plot: Dictionary, village: String, index: int) -> void:
	var entry: Dictionary = plot["building"]
	var node_name: String = "%sInn" % village if String(entry.get("kind", "")) == "inn" else "%sHouse%d" % [village, index]
	var home: Node3D = _build_home(holder, builder, entry, node_name, true)
	var toft: Node3D = Node3D.new()
	toft.name = node_name + "Toft"
	toft.position = Vector3(home.position.x, builder.height_at(home.position.x, home.position.z), home.position.z)
	holder.add_child(toft)
	_build_props(toft, holder, builder, plot.get("props", []), node_name, true)


# --- What stands about a yard ---------------------------------------------------------------------------------------

## A yard's pieces, merged into one mesh under `yard` (each on its own ground), with the solids that block the way.
static func _build_props(yard: Node3D, holder: Node3D, builder: EmbershoreBuilder, props: Array, prefix: String, small: bool = false) -> void:
	var parts: WorldAssetCatalog.Parts = WorldAssetCatalog.Parts.new()
	var smoking: Array[Vector3] = []
	for index: int in props.size():
		var entry: Dictionary = props[index]
		var kind: String = String(entry.get("kind", ""))
		var mesh: ArrayMesh = SteadingKit.prop_mesh(kind)
		if mesh == null:
			continue
		var at: Vector2 = EmbershoreSettlement.at2(entry["at"])
		var facing: Vector2 = EmbershoreSettlement.facing_of(entry)
		var spot: Vector3 = builder.ground(at.x, at.y)
		if spot.y < 0.4 or builder.mask(&"river", at.x, at.y) > 0.0:
			continue
		var where: Transform3D = Transform3D(Basis(Vector3.UP, atan2(facing.x, facing.y)), spot - yard.position - Vector3(0.0, 0.03, 0.0))
		var materials: Array[Material] = []
		for surface: int in mesh.get_surface_count():
			materials.append(mesh.surface_get_material(surface))
		parts.add_mesh(mesh, where, materials)
		if kind == "charcoal_clamp":
			smoking.append(where.origin + Vector3(0.0, 1.8, 0.0))
		if PROP_PILLARS.has(kind):
			var pillar: Vector2 = PROP_PILLARS[kind]
			CalderaKit.solid_cylinder(holder, "%sProp%d" % [prefix, index], spot - Vector3(0.0, 0.3, 0.0), pillar.x, pillar.y + 0.3,
				ActorBase.LAYER_WORLD if pillar.y > 2.0 else ActorBase.LAYER_LOW_SCENERY)
		elif PROP_BOXES.has(kind):
			var box: Vector3 = PROP_BOXES[kind]
			var turn: Basis = Basis(Vector3.UP, atan2(facing.x, facing.y))
			CalderaKit.solid_box(holder, "%sProp%d" % [prefix, index], spot + Vector3(0.0, box.y * 0.5, 0.0) + turn * (Vector3(0.9, 0.0, 0.0) if kind.begins_with("cart") else Vector3.ZERO),
				box, atan2(facing.x, facing.y), ActorBase.LAYER_LOW_SCENERY)
	if parts.is_empty():
		return
	var pieces: MeshInstance3D = MeshInstance3D.new()
	pieces.name = "Pieces"
	pieces.mesh = parts.commit()
	pieces.visibility_range_end = PROPS_RANGE * (0.7 if small else 1.0)
	pieces.visibility_range_end_margin = 12.0
	# A toft's woodpile and bench throw no shadow of their own (there are two dozen tofts in a village view).
	if small:
		pieces.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	yard.add_child(pieces)
	for index: int in smoking.size():
		var smoke: CPUParticles3D = WorldAssetCatalog.smoke("ClampSmoke%d" % index, smoking[index], 5)
		smoke.visibility_range_end = SMOKE_RANGE
		yard.add_child(smoke)


## The finger-posts where a track leaves a road (each with its steading's name), the fords' stepping stones and the hill's cairns.
static func _build_waymarks(holder: Node3D, builder: EmbershoreBuilder, props: Array) -> void:
	var marks: Node3D = Node3D.new()
	marks.name = "Waymarks"
	holder.add_child(marks)
	var parts: WorldAssetCatalog.Parts = WorldAssetCatalog.Parts.new()
	var index: int = 0
	for prop: Variant in props:
		var entry: Dictionary = prop as Dictionary
		var kind: String = String(entry.get("kind", ""))
		if kind != "way_stone" and kind != "ford" and kind != "cairn":
			continue
		var mesh: ArrayMesh = SteadingKit.prop_mesh(kind)
		var at: Vector2 = EmbershoreSettlement.at2(entry["at"])
		var facing: Vector2 = EmbershoreSettlement.facing_of(entry)
		var spot: Vector3 = builder.ground(at.x, at.y)
		if kind == "ford":
			# The stones stand in the stream with their tops just over it (EmbershoreWater: the water lies 0.6 m over the bed).
			spot.y += 0.6
		var materials: Array[Material] = []
		for surface: int in mesh.get_surface_count():
			materials.append(mesh.surface_get_material(surface))
		parts.add_mesh(mesh, Transform3D(Basis(Vector3.UP, atan2(facing.x, facing.y)), spot), materials)
		if kind == "way_stone":
			CalderaKit.sign_label(marks, "WayPost%d" % index, String(entry.get("name", "")), spot + Vector3(0.0, 2.75, 0.0))
			CalderaKit.solid_cylinder(marks, "WayPostBody%d" % index, spot, 0.2, 2.2, ActorBase.LAYER_LOW_SCENERY)
		elif kind == "cairn":
			CalderaKit.solid_cylinder(marks, "CairnBody%d" % index, spot, 0.9, 1.6, ActorBase.LAYER_LOW_SCENERY)
		index += 1
	if not parts.is_empty():
		var stones: MeshInstance3D = MeshInstance3D.new()
		stones.name = "Stones"
		stones.mesh = parts.commit()
		marks.add_child(stones)


# --- Stock -------------------------------------------------------------------------------------------------------

static func _build_stock(holder: Node3D, builder: EmbershoreBuilder, flocks: Array) -> void:
	var stock: Node3D = Node3D.new()
	stock.name = "Stock"
	holder.add_child(stock)
	var kinds: Dictionary[String, int] = {"sheep": GrazingStock.Kind.SHEEP, "cattle": GrazingStock.Kind.CATTLE, "hens": GrazingStock.Kind.HENS,
		"geese": GrazingStock.Kind.GEESE}
	for index: int in flocks.size():
		var entry: Dictionary = flocks[index]
		var kind: String = String(entry.get("kind", "sheep"))
		if not kinds.has(kind):
			continue
		var at: Vector2 = EmbershoreSettlement.at2(entry["at"])
		var flock: GrazingStock = GrazingStock.make(kinds[kind] as GrazingStock.Kind, int(entry.get("count", 4)), float(entry.get("reach", 10.0)), index + 1,
			builder.height_at)
		flock.name = "%s%d" % [kind.capitalize(), index]
		flock.position = builder.ground(at.x, at.y)
		stock.add_child(flock)
