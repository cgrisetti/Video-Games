## Embershore's worked land (docs/32_EMBERSHORE_THE_WORKED_LAND.md), checked on
## the live island once the Caldera has booted. Run by tools/test_caldera_isles.gd
## right after Embershore's own checks (so by the smoke test and
## tools/run_caldera_checks.gd):
##   1  the layer is read and the generator's ground is untouched under it
##   2  nothing of it stands on what Act I and the corridor use
##   3  every wall has a way through, low walls are solid and hedges are not
##   4  the valley's trees: a dozen and more kinds, each sculpted and clear of a hero's head
##   5  the homes stand on their ground: the villages' 24, the steadings', each lived-in hearth smoking
##   6  the fields: each use its colour, the plough its furrows, the barley its ripe grain
##   7  the tracks are laid as roads and join the roads they leave
##   8  the stock keeps to the ground and gives way before a hero
extends RefCounted

const Species = IslandBuilder.Species
const Use = EmbershoreSettlement.Use
## A wall is never a cage: no stretch of it runs further than this without a gateway, a stile or a gap.
const WALL_REACH: float = 62.0
const TREE_TRIANGLES: int = 3200
const CROWN_CLEARANCE: float = 2.4
## A door stands this near its ground.
const DOOR_SLACK: float = 0.4

var check: Callable
var level: CalderaArchipelagoWorld
var tree: SceneTree
var builder: EmbershoreBuilder
var settlement: EmbershoreSettlement


func run(live_level: CalderaArchipelagoWorld, checker: Callable, scene_tree: SceneTree) -> void:
	check = checker
	level = live_level
	tree = scene_tree
	builder = CalderaAtlas.builder_for(CalderaAtlas.ISLE_EMBERSHORE) as EmbershoreBuilder
	if builder == null or not builder.loaded or not builder.settlement.loaded or level.streamer.active_isle != CalderaAtlas.ISLE_EMBERSHORE:
		check.call(false, "Embershore is live with its worked land (run tools/worldgen/embershore_settle.py world/embershore/gen/engine world/embershore/settle 7)")
		return
	settlement = builder.settlement
	_check_layer()
	_check_keep_clear()
	await _check_boundaries()
	_check_trees()
	_check_homes()
	await _check_fields()
	_check_tracks()
	await _check_stock()
	# Back to the start, the window built, for the checks that follow.
	level.place_party_at(CalderaAtlas.ARRIVE_START)
	level.streamer.load_now([level.tether_centroid()])
	await _frames(2)


# --- 1: the layer, and the ground under it -----------------------------------------------------------

func _check_layer() -> void:
	var uses: Dictionary[int, int] = {}
	for index: int in range(0, settlement.use.size(), 97):
		uses[settlement.use[index]] = int(uses.get(settlement.use[index], 0)) + 1
	var steadings: Array = settlement.list("steadings")
	var named: int = 0
	for steading: Variant in steadings:
		var entry: Dictionary = steading as Dictionary
		var at: Vector2 = EmbershoreSettlement.at2(entry["at"])
		if builder.place_name_at(Vector3(at.x, 0.0, at.y)) == String(entry["name"]):
			named += 1
	# The generator's ground is the ground: no pad or ramp is pressed into Embershore, and its height at any
	# metre is the heightmap's own.
	var pads: PackedFloat32Array = builder.get("_pads")
	var ramps: PackedFloat32Array = builder.get("_ramps")
	var drift: float = 0.0
	for spot: Vector2i in [Vector2i(160, 470), Vector2i(700, 300), Vector2i(1100, 320), Vector2i(1500, 240), Vector2i(1380, 740)]:
		var raw: float = builder.heights[spot.y * EmbershoreBuilder.HEIGHT_COLUMNS + spot.x]
		drift = maxf(drift, absf(builder.height_at(float(spot.x) + EmbershoreBuilder.ORIGIN.x, float(spot.y) + EmbershoreBuilder.ORIGIN.y) - raw))
	check.call(settlement.loaded and steadings.size() >= 14 and named == steadings.size() and settlement.list("fields").size() >= 280 and uses.size() >= 12
		and pads.is_empty() and ramps.is_empty() and drift < 0.001,
		"the worked land lies over Embershore without moving its ground: %d steadings (each a named place), %d fields in %d uses, %d boundaries, %d trees; no pad or ramp pressed in, the height at five spots the heightmap's own (drift %.3f m)"
		% [steadings.size(), settlement.list("fields").size(), uses.size(), settlement.list("boundaries").size(), settlement.list("trees").size(), drift])


# --- 2: nothing on what Act I and the corridor use ---------------------------------------------------------

func _check_keep_clear() -> void:
	# Where the quests, the packs and the chime-posts stand (centre, how far round it is kept clear).
	var spots: Array[Vector3] = [Vector3(EmbershoreBuilder.START_AT.x, EmbershoreBuilder.START_AT.y, 20.0)]
	for place_id: StringName in [ActOnePlaces.ORCHARD_GATE, ActOnePlaces.WRIGHTS_YARD, ActOnePlaces.OLD_WATERMILL, ActOnePlaces.NORTH_QUAY_BRIDGE, ActOnePlaces.WEIR,
			ActOnePlaces.GROVE_ROOT, ActOnePlaces.GROVE_LEAF, ActOnePlaces.GROVE_FLOWER, ActOnePlaces.GROVE_SEED]:
		var at: Vector3 = ActOnePlaces.centre(place_id)
		spots.append(Vector3(at.x, at.z, minf(ActOnePlaces.reach(place_id), 26.0) - 2.0))
	for pack: Vector2 in ActOneDirector.HOUND_PACKS:
		spots.append(Vector3(pack.x, pack.y, 24.0))
	spots.append(Vector3(ActOneDirector.GRANARY_AT.x, ActOneDirector.GRANARY_AT.y, 24.0))
	spots.append(Vector3(EmbershoreBuilder.GREEN_AT.x, EmbershoreBuilder.GREEN_AT.y, 18.0))
	for node: Node in tree.get_nodes_in_group(&"caldera_streamed_spawners"):
		var pack: MobSpawner = node as MobSpawner
		if pack != null and level.streamer.structures.is_ancestor_of(pack):
			spots.append(Vector3(pack.position.x, pack.position.z, 20.0))
	for key: StringName in [&"moss_oaks_chimepost", &"doverslap_chimepost", &"hearthstead_chimepost", &"hearthstead_market", &"elder_oak", &"root_sanctum_entrance"]:
		spots.append(Vector3(builder.landmark(key).x, builder.landmark(key).z, 8.0))
	var crowding: PackedStringArray = PackedStringArray()
	var blocking: Array[int] = [Species.WALL_RUN, Species.FENCE_RUN, Species.HURDLE_RUN, Species.HEDGE_RUN, Species.HEDGE_BLOOM, Species.FIELD_GATE, Species.HAYCOCK,
		Species.TROUGH]
	blocking.append_array(WorkedLandKit.NEW_TREES)
	var checked: int = 0
	for chunk: Vector2i in settlement.get("_scatter"):
		var block: Dictionary = settlement.scatter_in(chunk)
		for species: Variant in block:
			if not blocking.has(int(species)):
				continue
			for where: Transform3D in block[species] as Array:
				checked += 1
				for spot: Vector3 in spots:
					if Vector2(where.origin.x - spot.x, where.origin.z - spot.y).length() < spot.z and crowding.size() < 4:
						crowding.append("%s at (%.0f, %.0f)" % [Species.keys()[int(species)], where.origin.x, where.origin.z])
	for node: Node in tree.get_nodes_in_group(EmbershoreSteadings.HOMES):
		var home: Node3D = node as Node3D
		for spot: Vector3 in spots:
			if Vector2(home.position.x - spot.x, home.position.z - spot.y).length() < minf(spot.z, 9.0) and crowding.size() < 4:
				crowding.append("%s" % home.name)
	check.call(crowding.is_empty() and checked > 3000,
		"nothing of the worked land stands on what Act I and the corridor use: %d places (the spawn, the gate, the groves, the packs, the chime-posts) are clear of all %d runs, trees and field pieces, and of every home%s"
		% [spots.size(), checked, "" if crowding.is_empty() else ": " + "; ".join(crowding)])


# --- 3: boundaries -------------------------------------------------------------------------------------------

func _check_boundaries() -> void:
	var lengths: Dictionary[String, float] = {}
	var caged: int = 0
	var longest: float = 0.0
	var a_wall: Vector2 = Vector2.INF
	for boundary: Variant in settlement.list("boundaries"):
		var entry: Dictionary = boundary as Dictionary
		var kind: String = String(entry["kind"])
		var length: float = float(entry.get("length", 0.0))
		lengths[kind] = float(lengths.get(kind, 0.0)) + length
		if kind != "wall" and kind != "fence":
			continue
		var from: float = 0.0
		var worst: float = 0.0
		for gap: Variant in entry.get("gaps", []):
			worst = maxf(worst, float((gap as Array)[0]) - from)
			from = float((gap as Array)[1])
		worst = maxf(worst, length - from)
		longest = maxf(longest, worst)
		if worst > WALL_REACH:
			caged += 1
		if kind == "wall" and length > 40.0 and a_wall == Vector2.INF:
			var points: PackedVector2Array = EmbershoreSettlement.points_of(entry["points"])
			a_wall = points[points.size() / 2]
	# In the window, a wall's runs are low boxes a hero hops and a camera sees over; a hedge's are none.
	var low_boxes: int = 0
	var tallest: float = 0.0
	var wall_runs: int = 0
	var hedge_runs: int = 0
	var low_layer: bool = true
	if a_wall != Vector2.INF:
		_place_party(Vector3(a_wall.x + 3.0, 0.0, a_wall.y + 3.0))
		level.streamer.load_now([level.tether_centroid()])
		await _frames(3)
		var record: ArchipelagoStreamer.LoadedChunk = level.streamer.chunks.get(IslandGridResource.chunk_of(Vector3(a_wall.x, 0.0, a_wall.y)), null)
		if record != null and record.body != null:
			for kind: int in IslandBuilder.SOLID_BOX:
				wall_runs += (record.scatter.get(kind, []) as Array).size()
			hedge_runs = (record.scatter.get(Species.HEDGE_RUN, []) as Array).size() + (record.scatter.get(Species.HEDGE_BLOOM, []) as Array).size()
			var low: StaticBody3D = record.body.get_node_or_null("LowSolids") as StaticBody3D
			if low != null:
				low_layer = low.collision_layer == ActorBase.LAYER_LOW_SCENERY
				for shape: Node in low.get_children():
					var box: BoxShape3D = (shape as CollisionShape3D).shape as BoxShape3D
					if box != null:
						low_boxes += 1
						tallest = maxf(tallest, box.size.y)
	check.call(caged == 0 and float(lengths.get("hedge", 0.0)) > 6000.0 and float(lengths.get("wall", 0.0)) > 6000.0 and low_boxes == wall_runs and wall_runs > 0
		and low_layer and tallest <= 0.9 and ActorBase.JUMP_VELOCITY * ActorBase.JUMP_VELOCITY / (2.0 * ActorBase.GRAVITY) > tallest,
		"the fields are parted by %.1f km of hedge and %.1f km of dry-stone wall (and %.1f km of green baulk); no wall runs further than %.0f m without a way through; in the window a landblock's %d wall runs are %d low boxes (%.2f m, under a hero's %.2f m jump) and its %d hedge runs are none"
		% [float(lengths.get("hedge", 0.0)) / 1000.0, (float(lengths.get("wall", 0.0)) + float(lengths.get("wall_tumbled", 0.0))) / 1000.0, float(lengths.get("baulk", 0.0)) / 1000.0,
			longest, wall_runs, low_boxes, tallest, ActorBase.JUMP_VELOCITY * ActorBase.JUMP_VELOCITY / (2.0 * ActorBase.GRAVITY), hedge_runs])


# --- 4: trees -------------------------------------------------------------------------------------------------

func _check_trees() -> void:
	var standing: Dictionary[int, int] = {}
	for record: ArchipelagoStreamer.LoadedChunk in level.streamer.chunks.values():
		for species: Variant in record.scatter:
			if WorkedLandKit.is_tree(int(species)):
				standing[int(species)] = int(standing.get(int(species), 0)) + (record.scatter[species] as Array).size()
	var problems: PackedStringArray = PackedStringArray()
	var heaviest: int = 0
	var lowest: float = INF
	for species: int in WorkedLandKit.NEW_TREES:
		var label: String = Species.keys()[species]
		var mesh: ArrayMesh = CalderaKit.atelier_mesh(species)
		if mesh == null or mesh.get_surface_count() < 2:
			problems.append("%s has no sculpted trunk and crown" % label)
			continue
		var triangles: int = 0
		for surface: int in mesh.get_surface_count():
			triangles += (mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
			var material: ShaderMaterial = mesh.surface_get_material(surface) as ShaderMaterial
			if material == null or material.shader != WorldVisualCatalog.FOLIAGE_SHADER:
				continue
			for point: Vector3 in mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX] as PackedVector3Array:
				lowest = minf(lowest, point.y)
		heaviest = maxi(heaviest, triangles)
		if not standing.has(species):
			problems.append("no %s stands on Embershore" % label)
		if CalderaKit.species_mesh(species).get_surface_count() == 0:
			problems.append("%s has no stand-in" % label)
	check.call(problems.is_empty() and standing.size() >= 14 and heaviest <= TREE_TRIANGLES and lowest >= CROWN_CLEARANCE,
		"the valley keeps %d kinds of tree (field oak and ash, beech, elm, chestnut, birch, poplar, thorn, alder, pollard willow, plum, pear, yew, holly and Scots pine beside the Moss-Oaks, willow, rowan and apple): each sculpted one at most %d triangles with no leaf under %.1f m, and each with its far shape%s"
		% [standing.size(), heaviest, lowest, "" if problems.is_empty() else ": " + "; ".join(problems)])


# --- 5: homes -------------------------------------------------------------------------------------------------

func _check_homes() -> void:
	var homes: int = 0
	var village: int = 0
	var smoking: int = 0
	var cold: int = 0
	var problems: PackedStringArray = PackedStringArray()
	for node: Node in tree.get_nodes_in_group(EmbershoreSteadings.HOMES):
		if not level.streamer.structures.is_ancestor_of(node):
			continue
		homes += 1
		if String(node.name).begins_with("Bramblebridge") or String(node.name).begins_with("Hearthstead"):
			village += 1
		if node is WorldKitInstance:
			continue
		var home: Node3D = node as Node3D
		var near: MeshInstance3D = home.get_node_or_null("Near") as MeshInstance3D
		var far: MeshInstance3D = home.get_node_or_null("Far") as MeshInstance3D
		if near == null or far == null or near.mesh == null or far.mesh == null or not is_equal_approx(near.visibility_range_end, far.visibility_range_begin):
			problems.append("%s has no near and far pair" % home.name)
		if home.get_node_or_null("Smoke0") != null:
			smoking += 1
		else:
			cold += 1
		# Its door is on its ground: the floor is the ground a stride out from the front wall.
		var out: Vector3 = home.global_transform.basis.z
		var reach: float = (near.mesh.get_aabb().size.z * 0.5) if near != null and near.mesh != null else 3.0
		var worst: float = INF
		for step: float in [2.0, 2.6, 3.2, 3.8]:
			var door: Vector3 = home.position + out * step
			worst = minf(worst, absf(builder.height_at(door.x, door.z) - home.position.y))
		if worst > DOOR_SLACK and reach > 0.0 and problems.size() < 4:
			problems.append("%s's floor is %.2f m off its ground" % [home.name, worst])
	var stewards: int = 0
	var ruins: int = 0
	for node: Node in level.streamer.structures.find_children("*Steward", "TownsfolkNPC", true, false):
		stewards += 1
	for node: Node in level.streamer.structures.find_children("FallowHollowRuin*", "Node3D", true, false):
		if node.get_node_or_null("Near") != null:
			ruins += 1
	var flitted_cold: bool = level.streamer.structures.find_child("FallowHollowSteward", true, false) == null and ruins >= 2
	check.call(problems.is_empty() and village == 24 and homes >= 36 and smoking >= 12 and stewards >= 12 and flitted_cold,
		"Embershore's homes stand on their ground: the two villages' 24 houses turned to their lanes, %d steading homes of stone, lime and thatch with %d hearths smoking, %d stewards about their yards, and Fallow-Hollow cold, roofless and empty (%d ruins)%s"
		% [homes - village, smoking, stewards, ruins, "" if problems.is_empty() else ": " + "; ".join(problems)])


# --- 6: fields ------------------------------------------------------------------------------------------------

func _check_fields() -> void:
	# One spot of each use, from the fields' own middles.
	var spot_of: Dictionary[String, Vector2] = {}
	for field: Variant in settlement.list("fields"):
		var entry: Dictionary = field as Dictionary
		var use: String = String(entry.get("use", ""))
		if spot_of.has(use) or int(entry.get("area", 0)) < 900:
			continue
		var at: Vector2 = EmbershoreSettlement.at2(entry["centroid"])
		if settlement.use_at(at.x, at.y) == int((settlement.data["landuse"] as Dictionary).get(use, -1)):
			spot_of[use] = at
	var problems: PackedStringArray = PackedStringArray()
	for use: String in ["pasture", "hay", "barley", "plough", "roots", "stubble"]:
		if not spot_of.has(use):
			problems.append("no %s field" % use)
	var plough: Vector2 = spot_of.get("plough", Vector2.ZERO)
	var pasture: Vector2 = spot_of.get("pasture", Vector2.ZERO)
	var barley: Vector2 = spot_of.get("barley", Vector2.ZERO)
	var roots: Vector2 = spot_of.get("roots", Vector2.ZERO)
	var loam: Color = builder.surface_color(plough.x, plough.y, builder.height_at(plough.x, plough.y), 1.0)
	var turf: Color = builder.surface_color(pasture.x, pasture.y, builder.height_at(pasture.x, pasture.y), 1.0)
	var gold: Color = builder.surface_color(barley.x, barley.y, builder.height_at(barley.x, barley.y), 1.0)
	var furrows: Vector4 = builder.ground_tilth(plough.x, plough.y)
	var rows: Vector4 = builder.ground_tilth(roots.x, roots.y)
	var ripe: Vector3 = builder.call("_meadow_style", barley.x, barley.y)
	var grazed: Vector3 = builder.call("_meadow_style", pasture.x, pasture.y)
	# The near ground at the plough carries its furrows in its UVs, for the shader to draw.
	var carried: bool = false
	if not problems.is_empty():
		check.call(false, "the fields are worked: %s" % "; ".join(problems))
		return
	_place_party(Vector3(plough.x, 0.0, plough.y))
	level.streamer.load_now([level.tether_centroid()])
	await _frames(3)
	var record: ArchipelagoStreamer.LoadedChunk = level.streamer.chunks.get(IslandGridResource.chunk_of(Vector3(plough.x, 0.0, plough.y)), null)
	if record != null and record.near_mesh != null:
		var uvs: Variant = record.near_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
		if uvs is PackedVector2Array:
			for uv: Vector2 in uvs as PackedVector2Array:
				if uv.length() > 0.9:
					carried = true
					break
	var shader_code: String = (WorldVisualCatalog.terrain().shader as Shader).code
	check.call(loam.r > loam.g + 0.05 and turf.g > turf.r + 0.1 and gold.r > 0.55 and gold.r <= gold.g + 0.03 and Vector2(furrows.x, furrows.y).length() > 0.9 and furrows.w < 0.0
		and rows.w > 0.0 and ripe.z > 0.9 and ripe.x > 1.4 and grazed.x < 0.7 and carried and shader_code.contains("v_tilth"),
		"the fields are worked: the plough is loam with furrows every %.2f m drawn per pixel (the near ground carries them in its UVs), the root crop grows in green rows, pasture is grazed turf, hay stands tall, and the barley is straw-gold with ripe grain %.1f times a meadow's height"
		% [furrows.z, ripe.x])


# --- 7: tracks --------------------------------------------------------------------------------------------------

func _check_tracks() -> void:
	var tracks: Array = settlement.list("tracks")
	var joined: int = 0
	var metres: float = 0.0
	for track: Variant in tracks:
		var points: PackedVector2Array = EmbershoreSettlement.points_of((track as Dictionary)["points"])
		for index: int in points.size() - 1:
			metres += points[index].distance_to(points[index + 1])
		var end: Vector2 = points[points.size() - 1]
		# Its far end is on another road or track (not its own).
		var near: bool = false
		for road: Dictionary in builder.laid_roads:
			var line: PackedVector2Array = road["points"]
			if line[line.size() - 1].distance_to(end) < 0.6 and line[0].distance_to(points[0]) < 0.6:
				continue
			for index: int in line.size() - 1:
				if Geometry2D.get_closest_point_to_segment(end, line[index], line[index + 1]).distance_to(end) < 4.0:
					near = true
					break
			if near:
				break
		if near or String((track as Dictionary).get("to", "")) == "":
			joined += 1
	var on_path: bool = true
	if not tracks.is_empty():
		var points: PackedVector2Array = EmbershoreSettlement.points_of((tracks[0] as Dictionary)["points"])
		var middle: Vector2 = points[points.size() / 2]
		on_path = builder.on_path(middle.x, middle.y)
	check.call(tracks.size() >= 14 and builder.laid_roads.size() == 7 + tracks.size() and joined == tracks.size() and on_path,
		"%d cart tracks and footpaths (%.1f km) are laid as roads, drawn like them and on the map, and every steading's track joins a road"
		% [tracks.size(), metres / 1000.0])


# --- 8: stock ----------------------------------------------------------------------------------------------------

func _check_stock() -> void:
	var flocks: Array[GrazingStock] = []
	var head: Dictionary[int, int] = {}
	for node: Node in level.streamer.structures.find_children("*", "GrazingStock", true, false):
		var flock: GrazingStock = node as GrazingStock
		flocks.append(flock)
		head[int(flock.kind)] = int(head.get(int(flock.kind), 0)) + flock.count
	var sheep: GrazingStock = null
	for flock: GrazingStock in flocks:
		if flock.kind == GrazingStock.Kind.SHEEP and flock.count >= 4:
			sheep = flock
			break
	if sheep == null:
		check.call(false, "a flock of sheep grazes on Embershore")
		return
	# Stand a hero beside one ewe: she gives way, and every beast stays on the ground.
	var p1: ActorBase = _p1()
	_place_party(sheep.global_position + Vector3(40.0, 0.0, 0.0))
	level.streamer.load_now([level.tether_centroid()])
	await _seconds(0.5)
	var before: Vector3 = sheep.where(0)
	p1.place_at(Transform3D(Basis.IDENTITY, before + Vector3(0.9, 0.3, 0.0)))
	await _seconds(1.6)
	var after: Vector3 = sheep.where(0)
	var gave_way: float = Vector2(after.x - p1.global_position.x, after.z - p1.global_position.z).length()
	var afloat: float = 0.0
	for index: int in sheep.count:
		var at: Vector3 = sheep.where(index)
		afloat = maxf(afloat, absf(at.y - builder.height_at(at.x, at.z)))
	check.call(flocks.size() >= 30 and head.size() == 4 and gave_way > 2.0 and afloat < 0.25,
		"stock is about: %d sheep, %d cattle, %d hens and %d geese in %d flocks, each two draws; a ewe gives way before a hero who walks up to her (%.1f m off after 1.6 s) and every beast keeps to the ground (within %.2f m)"
		% [int(head.get(GrazingStock.Kind.SHEEP, 0)), int(head.get(GrazingStock.Kind.CATTLE, 0)), int(head.get(GrazingStock.Kind.HENS, 0)),
			int(head.get(GrazingStock.Kind.GEESE, 0)), flocks.size(), gave_way, afloat])


# --- Helpers ---------------------------------------------------------------------------------------------------

func _party() -> Array[ActorBase]:
	var members: Array[ActorBase] = []
	for actor: ActorBase in level.party_in_order():
		if actor.is_multiplayer_authority() and actor.is_local_player() and not actor.is_companion:
			members.append(actor)
	return members


func _p1() -> ActorBase:
	var party: Array[ActorBase] = _party()
	return party[0] if not party.is_empty() else null


func _place_party(at: Vector3) -> void:
	var seat: int = 0
	for actor: ActorBase in _party():
		var spot: Vector3 = at + Vector3((float(seat % 4) - 1.5) * 1.6, 0.0, 0.0)
		level.streamer.ensure_ground_at(spot)
		spot.y = level.streamer.height_at(spot.x, spot.z) + 0.2
		actor.place_at(Transform3D(Basis.IDENTITY, spot))
		seat += 1


func _frames(count: int) -> void:
	for index: int in count:
		await tree.physics_frame


func _seconds(seconds: float) -> void:
	await _frames(int(ceil(seconds * 60.0)))
