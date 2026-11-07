## The Living Storybook Atelier's checks (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md
## §7.2), run by tools/smoke_test.gd: run_world() in the seamless world after
## the corridor's score, run_vale() in Oakshire Vale before the Lens.
##   1  the catalog: seventeen biomes in mid-values, the kits (curated-model
##      paths, low scenery and sightline flags), the three succession looks and
##      the biome each place wears
##   2  the atelier: eight craft sets, three Texture2DArrays bound as global
##      shader parameters (64 px headless)
##   3  the four world shaders and the Terrain3D shader: their uniforms and
##      shared include, and the global parameters they read
##   4  in the world: crafted ground (Mode B splat), the clutter batches, kits
##      built in streamed landblocks, Chime-Posts at the thresholds
##   5  sightlines and footing: knee-high walls on the LowScenery layer, ramps
##      at 25° or less, roofs and crowns above 3.2 m dither out of sightlines
##   6  draw distance: cameras' far planes at 2.5 km or more, the
##      HorizonVistaRing round the party with its four landmarks, low-poly HLODs
##   7  Ecological Succession: a camp cleared earlier streams back as a Lulled
##      Cairn; an open Hush-Crack greys its 22 m (18 GDD §5) and dims the Wind-Lanterns in
##      it; clearing its camp sweeps a Reclamation Bloom, seals it into a cairn
##      and lights the lanterns again; a weathering biome thickens its fog
##   8  streaming: the kit queue builds a slice a frame inside the 2 ms budget,
##      and the Ring of the Cairnsman's floor grows no clutter
##   9  in Oakshire Vale: each part's biome and the atmosphere easing to it,
##      the village's and petals' landmarks in their landblocks, the
##      Hush-Cracks on the briars, outlaws and wights, Pippin-Green's furrows
##      and each petal's own clutter
extends RefCounted

const Succession = ZoneSuccessionVisualResource.SuccessionState
const BIOME_IDS: Array[StringName] = [&"tizzi_wed_green", &"gull_wick_haven", &"barley_bridge_meadow", &"rush_light_hollow", &"barrow_crag_crossing",
	&"sunken_crown_falls", &"oakshire_wick", &"wayfarer_green", &"pippin_green", &"quarry_wick", &"bramble_hollow", &"nine_stones_crossing", &"honey_wick",
	&"bramble_bridge", &"moss_oak_hollow", &"dover_slap_falls", &"ring_of_the_cairnsman"]
const REQUIRED_KITS: Array[StringName] = [&"kit_house_stepped_gable", &"kit_watermill_wheel", &"kit_bridge_stone_arch", &"kit_bridge_carpathian_trestle",
	&"kit_scribe_desk_pavilion", &"kit_chime_shrine_pagoda", &"kit_chime_post_diagnostic", &"kit_water_shrine_oasis", &"kit_hush_crack_and_cairn",
	&"kit_tree_moss_oak", &"kit_tree_orchard_apple", &"kit_tree_weeping_willow", &"kit_tree_highland_pine"]
const SHADERS: Dictionary[String, Array] = {
	"res://src/world/shaders/storybook_world_triplanar.gdshaderinc": ["craft_layer", "triplanar_scale", "moss_amount", "sightline_fade", "texture_chroma"],
	"res://src/world/shaders/storybook_terrain_splat.gdshader": ["detail_strength", "min_value", "max_value", "storybook_ground"],
	"res://src/world/shaders/storybook_foliage_wind.gdshader": ["sway_height", "brush", "sightline_fade", "fade_out_distance"],
	"res://src/world/shaders/storybook_water_stream.gdshader": ["shallow_color", "deep_color", "flow", "waterfall", "fixed_depth"],
	"res://src/world/landblock_terrain3d.gdshader": ["storybook_world_common", "storybook_ground", "apply_succession"],
	"res://src/world/shaders/storybook_world_common.gdshaderinc": ["atelier_albedo", "hero_pos_0", "hush_crack_0", "bloom_0", "world_wind", "sightline_blocked"],
}
const GLOBALS: Array[String] = ["atelier_albedo", "atelier_normal", "atelier_roughness", "atelier_ready", "hero_pos_0", "hero_pos_3", "hush_crack_0",
	"bloom_0", "world_wind"]
const SQUARE: Vector3 = Vector3(64.0, 0.0, 20.0)
const OAKS: Vector3 = Vector3(64.0, 0.0, -30.0)
const SUNKEN_LANE: Vector3 = Vector3(64.0, -1.8, -70.0)
const HOLLOW_CAMP_WALK: Vector3 = Vector3(66.0, -1.8, -70.0)
const LOW_HEIGHT: float = 0.95
const MAX_RAMP_DEG: float = ZoneBiomeResource.MAX_WALKABLE_RAMP_DEG
const FADE_FLOOR: float = ZoneBiomeResource.MAX_OBSTACLE_SIGHTLINE_M
## The petals' biomes, in OakshireValeLayout.PETAL_NAMES order.
const PETAL_BIOMES: Array[StringName] = [&"bramble_hollow", &"quarry_wick", &"wayfarer_green", &"nine_stones_crossing", &"pippin_green"]
const VALE_LANDMARKS: Array[String] = ["KindleFire", "ScribeDeskPavilion", "ChimeShrinePagoda", "PumpkinPatch1", "PumpkinPatch2", "VillageChimePost",
	"Windmill", "CiderMill", "Crane0", "Ashlar0", "Cairn0", "WillowPool0", "HollowLantern0", "WaterShrine", "NineStone9", "ThresholdBellFrame"]

var tree: SceneTree
var check: Callable
var director: WorldAtmosphereDirector


# --- In the seamless world ----------------------------------------------------------------

func run_world(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	director = WorldAtmosphereDirector.current
	_check_catalog()
	_check_atelier()
	_check_shaders()
	var world: EverwoodWorld = tree.current_scene as EverwoodWorld
	check.call(world != null, "the world-visual checks start in the seamless world")
	if world == null:
		return
	_move(world, SQUARE)
	await _settle(world, [Vector2i(0, 0), Vector2i(0, -1)])
	_check_world_materials(world)
	_check_sightlines_and_footing(world)
	_check_draw_distance(world)
	await _check_succession(world)
	await _check_streaming(world)


# 1 --------------------------------------------------------------------------------------------

func _check_catalog() -> void:
	var ids: Array[StringName] = []
	var muddy: Array[String] = []
	for look: ZoneBiomeResource in WorldVisualCatalog.biomes():
		ids.append(look.biome_id)
		for ground: Color in [look.turf_albedo, look.road_albedo, look.hollow_albedo, look.crag_albedo]:
			if ground.get_luminance() < 0.2 or ground.get_luminance() > 0.8 or ground.s > 0.7:
				muddy.append("%s %s" % [look.biome_id, ground.to_html(false)])
	check.call(ids == BIOME_IDS and muddy.is_empty(), "the catalog holds the seventeen biomes (six atlas zones, Oakshire Vale's six parts, the trail's five), every ground colour mid-value and never neon%s"
		% ("" if muddy.is_empty() else " (%s)" % ", ".join(muddy)))
	var looks: ZoneBiomeResource = WorldVisualCatalog.biome(&"tizzi_wed_green")
	check.call(looks.turf_albedo.to_html(false) == "5b8c4a" and looks.road_albedo.to_html(false) == "c8bfa8" and looks.hollow_albedo.to_html(false) == "594636"
		and looks.crag_albedo.to_html(false) == "7a8086" and looks.sky_top_color.to_html(false) == "3b78b8" and looks.cooper_sign_title == "Sign of Wood"
		and ZoneBiomeResource.CAMERA_EYELINE_HEIGHT_M == 4.8 and ZoneBiomeResource.DEFAULT_HUSH_RADIUS_M == 22.0,
		"Tizzi-Wed-Green wears the master palette (turf #5B8C4A, flagstone #C8BFA8, loam #594636, granite #7A8086, sky #3B78B8) under the Sign of Wood")
	var missing: Array[String] = []
	var bad_flags: Array[String] = []
	for id: StringName in REQUIRED_KITS:
		var kit: WorldPropKitResource = WorldVisualCatalog.kit(id)
		if kit == null:
			missing.append(String(id))
			continue
		if kit.glb_override_path != "res://assets/models/world/%s.glb" % id:
			bad_flags.append("%s path" % id)
	for kit: WorldPropKitResource in WorldVisualCatalog.kits():
		if kit.is_low_scenery and kit.bounding_size.y > 1.5:
			bad_flags.append("%s is tall for low scenery" % kit.kit_id)
		if kit.category in [&"TREE", &"ARCHITECTURE"] and not kit.enable_sightline_fade:
			bad_flags.append("%s doesn't fade" % kit.kit_id)
	check.call(missing.is_empty() and bad_flags.is_empty(), "every kit of §4 is in the catalog with its curated-model path (res://assets/models/world/<id>.glb), low scenery stays low and trees and buildings fade from sightlines%s"
		% ("" if missing.is_empty() and bad_flags.is_empty() else " (%s)" % ", ".join(missing + bad_flags)))
	var hushed: ZoneSuccessionVisualResource = WorldVisualCatalog.succession(Succession.ZONE_HUSHED)
	var reclaimed: ZoneSuccessionVisualResource = WorldVisualCatalog.succession(Succession.ZONE_RECLAIMED)
	var weathering: ZoneSuccessionVisualResource = WorldVisualCatalog.succession(Succession.ZONE_WEATHERING_EVENT)
	check.call(hushed.hush_desaturation == 0.45 and hushed.lantern_warmth_multiplier < 1.0 and reclaimed.reclamation_bloom_duration_sec == 2.5
		and weathering.weathering_frost_or_fog_intensity > 0.0 and weathering.lantern_warmth_multiplier > 1.0,
		"Ecological Succession's three looks: hushed (45% toward slate, lanterns dim), reclaimed (a 2.5 s bloom) and weathering (fog, lanterns flare)")
	var unplaced: Array[String] = []
	for place: String in MythopoeticAtlas.PLACE_ZONES:
		if WorldVisualCatalog.biome(WorldVisualCatalog.biome_for_place(place)) == null:
			unplaced.append(place)
	check.call(unplaced.is_empty() and WorldVisualCatalog.biome_for_music(&"bramble_bridge_square") == &"bramble_bridge",
		"every place in the atlas wears a biome, and the trail's scores map to theirs%s" % ("" if unplaced.is_empty() else " (%s)" % ", ".join(unplaced)))


# 2 --------------------------------------------------------------------------------------------

func _check_atelier() -> void:
	check.call(director != null, "the WorldAtmosphereDirector is an autoload (Atmosphere)")
	if director == null:
		return
	director.wait_for_atelier()
	var layered: bool = director.atelier_arrays.size() == 3
	for array: Texture2DArray in director.atelier_arrays:
		layered = layered and array.get_layers() == 8 and array.get_width() == ProceduralTextureAtelier.HEADLESS_SIZE
	check.call(director.atelier_is_ready and layered and ProceduralTextureAtelier.SET_IDS.size() == 8,
		"the atelier's eight craft sets are rendered on worker threads into three Texture2DArrays (albedo, normal, roughness) of 64 px in headless runs, in %d ms" % director.atelier_msec)
	var images: Array[Image] = ProceduralTextureAtelier.render_set(ProceduralTextureAtelier.Set.SCALLOP_SHINGLE, 32)
	var varied: bool = images.size() == 3
	if varied:
		var first: Color = images[0].get_pixel(0, 0)
		var different: int = 0
		for x: int in 32:
			different += 1 if not images[0].get_pixel(x, 11).is_equal_approx(first) else 0
		varied = different > 8 and images[1].get_width() == 32 and images[2].get_height() == 32
	check.call(varied and ProceduralTextureAtelier.OVERRIDE_FOLDER == "res://assets/textures/world/",
		"a craft set is three maps of the size asked for, with real detail, and curated textures in res://assets/textures/world/ win")


# 3 --------------------------------------------------------------------------------------------

func _check_shaders() -> void:
	var missing: Array[String] = []
	for path: String in SHADERS:
		var resource: Resource = load(path)
		var code: String = ""
		if resource is Shader:
			code = (resource as Shader).code
		elif resource is ShaderInclude:
			code = (resource as ShaderInclude).code
		for word: String in SHADERS[path]:
			if not code.contains(word):
				missing.append("%s: %s" % [path.get_file(), word])
	var triplanar: Shader = load("res://src/world/shaders/storybook_world_triplanar.gdshader") as Shader
	var double: Shader = load("res://src/world/shaders/storybook_world_triplanar_double.gdshader") as Shader
	check.call(missing.is_empty() and triplanar.code.contains("cull_back") and double.code.contains("cull_disabled"),
		"the four world shaders (triplanar, terrain splat, foliage wind, water stream) and the Terrain3D shader carry their uniforms and the shared include%s"
		% ("" if missing.is_empty() else " (missing %s)" % ", ".join(missing)))
	var unset: Array[String] = []
	for name: String in GLOBALS:
		if not ProjectSettings.has_setting("shader_globals/%s" % name):
			unset.append(name)
	check.call(unset.is_empty(), "the global shader parameters (the atelier's arrays, heroes, cracks, blooms, wind) are declared in the project%s"
		% ("" if unset.is_empty() else " (missing %s)" % ", ".join(unset)))


# 4 --------------------------------------------------------------------------------------------

func _check_world_materials(world: EverwoodWorld) -> void:
	var grid: WorldGridManager = world.grid_manager
	var village: Node3D = grid.chunk_node(Vector2i(0, 0))
	var ground_ok: bool = true
	if not grid.use_terrain3d:
		var ground: MeshInstance3D = village.find_child("Terrain_0_0", true, false) as MeshInstance3D if village != null else null
		ground_ok = ground != null and ground.mesh.surface_get_material(0) == WorldVisualCatalog.terrain()
	var batches: Dictionary[String, int] = {}
	for name: String in ChunkClutterBaker.BATCH_NAMES:
		var batch: MultiMeshInstance3D = village.find_child(name, true, false) as MultiMeshInstance3D if village != null else null
		batches[name] = batch.multimesh.instance_count if batch != null else 0
	check.call(ground_ok and batches.values().min() > 0, "Bramble-Bridge's ground is the storybook splat%s and its clutter grows %s"
		% ["" if not grid.use_terrain3d else " (Terrain3D's)", ", ".join(batches.keys().map(func(key: String) -> String: return "%d %s" % [batches[key], key]))])
	WorldKitInstance.build_waiting(1000000)
	var houses: int = 0
	var built: int = 0
	var posts: Array[String] = []
	for node: Node in world.find_children("*", "Node3D", true, false):
		var placed: WorldKitInstance = node as WorldKitInstance
		if placed != null and placed.kit_id == WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE:
			houses += 1
			built += 1 if placed.kit != null and placed.kit.get_node_or_null("Static") != null else 0
		if node is ChimePost:
			posts.append(String(node.name))
	check.call(houses >= 6 and built == houses and posts.has("GateChimePost") and posts.has("CampChimePost") and posts.has("HollowChimePost"),
		"the village's %d stepped-gable houses are built from their kit, and Chime-Posts stand at the Forest Gate and the two Hush-Crack trailheads (%s)" % [houses, ", ".join(posts)])


# 5 --------------------------------------------------------------------------------------------

func _check_sightlines_and_footing(world: EverwoodWorld) -> void:
	var high_walls: Array[String] = []
	var steep: Array[String] = []
	var walls: int = 0
	var ramps: int = 0
	for node: Node in world.find_children("*", "StaticBody3D", true, false):
		var body: StaticBody3D = node as StaticBody3D
		if _in_station(body):
			continue
		for child: Node in body.get_children():
			var shape: CollisionShape3D = child as CollisionShape3D
			if shape == null:
				continue
			var box: BoxShape3D = shape.shape as BoxShape3D
			if box != null and box.size.y <= LOW_HEIGHT and minf(box.size.x, box.size.z) <= 1.2 and maxf(box.size.x, box.size.z) >= 1.5 and _is_upright(shape):
				walls += 1
				if body.collision_layer != ActorBase.LAYER_LOW_SCENERY:
					high_walls.append(String(body.name))
			var hull: ConvexPolygonShape3D = shape.shape as ConvexPolygonShape3D
			if hull != null and (String(body.name).begins_with("Ramp") or body.name == &"Bramblebridge"):
				ramps += 1
				var slope: float = _steepest(hull.points)
				if slope > MAX_RAMP_DEG + 0.01:
					steep.append("%s %.1f°" % [body.name, slope])
	check.call(walls > 20 and high_walls.is_empty(), "all %d knee-high walls, parapets and garden borders sit on the LowScenery layer (cameras see past them)%s"
		% [walls, "" if high_walls.is_empty() else " (not: %s)" % ", ".join(high_walls)])
	check.call(ramps >= 2 and steep.is_empty(), "the %d walkable ramps and arches (the bridge, the holloway) climb at %d° or less%s" % [ramps, int(MAX_RAMP_DEG),
		"" if steep.is_empty() else " (%s)" % ", ".join(steep)])
	var unfaded: Array[String] = []
	var tall_surfaces: int = 0
	for node: Node in world.find_children("*", "Node3D", true, false):
		var placed: WorldKitInstance = node as WorldKitInstance
		if placed == null or placed.kit == null or not (placed.kit_id == WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE or WorldVisualCatalog.TREE_KITS.has(placed.kit_id)):
			continue
		var shape: MeshInstance3D = placed.kit.get_node_or_null("Static") as MeshInstance3D
		if shape == null:
			continue
		for surface: int in shape.mesh.get_surface_count():
			var points: PackedVector3Array = shape.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			var lowest: float = INF
			for point: Vector3 in points:
				lowest = minf(lowest, point.y)
			var material: ShaderMaterial = shape.mesh.surface_get_material(surface) as ShaderMaterial
			if lowest > FADE_FLOOR and material != null:
				tall_surfaces += 1
				if not bool(material.get_shader_parameter(&"sightline_fade")):
					unfaded.append("%s/%d" % [placed.name, surface])
	var arch: Node3D = world.find_child("GreatArch", true, false) as Node3D
	var arch_faded: bool = arch != null
	if arch != null:
		for name: String in ["BoughWest", "Canopy2"]:
			var part: MeshInstance3D = arch.find_child(name, true, false) as MeshInstance3D
			var material: ShaderMaterial = (part.mesh as PrimitiveMesh).material as ShaderMaterial if part != null else null
			arch_faded = arch_faded and material != null and bool(material.get_shader_parameter(&"sightline_fade"))
	check.call(tall_surfaces > 10 and unfaded.is_empty() and arch_faded,
		"every roof, gable and leaf-crown above 3.2 m (%d surfaces) and the Moss-Oak Great Arch dither out of a camera's sightline to its hero%s"
		% [tall_surfaces, "" if unfaded.is_empty() else " (not: %s)" % ", ".join(unfaded.slice(0, 6))])


## Stations' counters and desks (an Interactable's own bodies) aren't scenery walls.
func _in_station(node: Node) -> bool:
	var up: Node = node.get_parent()
	while up != null:
		if up is Interactable:
			return true
		up = up.get_parent()
	return false


func _is_upright(shape: CollisionShape3D) -> bool:
	return absf(shape.global_basis.y.normalized().dot(Vector3.UP)) > 0.95


## The steepest climb along a hull's walkable top, in degrees.
func _steepest(points: PackedVector3Array) -> float:
	var lowest: float = INF
	for point: Vector3 in points:
		lowest = minf(lowest, point.y)
	var top: Array[Vector2] = []
	for point: Vector3 in points:
		if point.x > 0.0 and point.y > lowest + 0.05:
			top.append(Vector2(point.z, point.y))
	top.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var steepest: float = 0.0
	for index: int in range(1, top.size()):
		var run: float = absf(top[index].x - top[index - 1].x)
		if run > 0.01:
			steepest = maxf(steepest, rad_to_deg(atan2(absf(top[index].y - top[index - 1].y), run)))
	return steepest


# 6 --------------------------------------------------------------------------------------------

func _check_draw_distance(world: EverwoodWorld) -> void:
	var fars: Array[float] = []
	for node: Node in tree.root.find_children("*", "Camera3D", true, false):
		if node is PlayerCamera:
			fars.append((node as PlayerCamera).far)
	check.call(not fars.is_empty() and fars.min() >= 2500.0, "every player camera sees out to %d m (Ring 3, 2.5 km or more)" % int(fars.min() if not fars.is_empty() else 0.0))
	var ring: HorizonVistaRing = director.horizon
	var shape: MeshInstance3D = ring.get_node_or_null("Ridgelines") as MeshInstance3D if ring != null else null
	var party: Vector3 = Vector3.ZERO
	var people: Array[ActorBase] = _people()
	for person: ActorBase in people:
		party += person.global_position / float(people.size())
	check.call(ring != null and ring.is_inside_tree() and ring.visible and shape != null and shape.mesh.get_aabb().size.x > 4000.0
		and HorizonVistaRing.landmark_bearings().size() == 4 and Vector2(ring.global_position.x - party.x, ring.global_position.z - party.z).length() < 1.0,
		"the HorizonVistaRing stands round the party out to %d m, with Sunken-Crown-Falls north, Barley-Bridge-Meadow east, Gull-Wick-Haven south and Barrow-Crag-Crossing west"
		% int(shape.mesh.get_aabb().size.x * 0.5 if shape != null else 0.0))
	var heavy: Array[String] = []
	for chunk: Vector2i in [Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, -2), Vector2i(0, -3)]:
		var mesh: ArrayMesh = load(LandblockManifest.hlod_path(chunk)) as ArrayMesh
		var vertices: int = 0
		if mesh != null:
			for surface: int in mesh.get_surface_count():
				vertices += (mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		if mesh == null or vertices == 0 or vertices > 60000:
			heavy.append("%s (%d)" % [chunk, vertices])
	check.call(heavy.is_empty() and WorldGridConfig.LOAD_GAMEPLAY_RADIUS == 1 and WorldGridConfig.LOAD_CLUTTER_RADIUS == 2 and WorldGridConfig.LOAD_HLOD_RADIUS == 3,
		"four rings: gameplay within a chunk, clutter within two, every corridor chunk's merged low-poly HLOD within three to four, then the horizon%s"
		% ("" if heavy.is_empty() else " (bad HLODs: %s)" % ", ".join(heavy)))


# 7 --------------------------------------------------------------------------------------------

func _check_succession(world: EverwoodWorld) -> void:
	# A camp on record as cleared comes back in as a cairn: what streaming does when its landblock returns.
	var returning: MinionCamp = MinionCamp.new()
	returning.name = "ReturningCamp"
	returning.persist_id = &"test_returning_camp"
	returning.apply_persisted_state({"cleared": true})
	world.add_child(returning)
	returning.global_position = OAKS + Vector3(-30.0, 0.0, 10.0)
	var sealed: HushCrackLandmark = returning.hush_crack
	check.call(sealed != null and not sealed.is_hushed() and sealed.hush_radius == 0.0 and sealed.get_node("Cairn").visible and not sealed.get_node("Crack").visible
		and director.succession_state(&"test_returning_camp") == Succession.ZONE_RECLAIMED,
		"a camp WorldStateDB holds as cleared streams back in sealed as a Lulled Cairn, with no hush")
	returning.queue_free()
	_move(world, HOLLOW_CAMP_WALK)
	await _settle(world, [Vector2i(0, -1)])
	# Read it as soon as the crack is in a shader slot and its lantern has dimmed: the
	# party's companions start clearing the camp the moment they arrive.
	for frame: int in 30:
		await tree.process_frame
		var waiting: MinionCamp = _camp(world, LandblockManifest.CAMP_HOLLOWAY)
		if waiting != null and waiting.hush_crack != null and _crack_slot(waiting.hush_crack.global_position) >= 0:
			var near: WindLantern = _nearest_lantern(world, waiting.hush_crack.global_position)
			if near != null and (near.get_node("Pivot/Light") as OmniLight3D).light_energy < 0.5:
				break
	var camp: MinionCamp = _camp(world, LandblockManifest.CAMP_HOLLOWAY)
	if camp == null or camp.hush_crack == null:
		check.call(false, "the Rush-Light Hush-Crack is streamed in")
		return
	var crack: HushCrackLandmark = camp.hush_crack
	var slot: int = _crack_slot(crack.global_position)
	var lantern: WindLantern = _nearest_lantern(world, crack.global_position)
	var dim: float = (lantern.get_node("Pivot/Light") as OmniLight3D).light_energy if lantern != null else -1.0
	check.call(crack.is_hushed() and is_equal_approx(crack.hush_radius, 22.0) and slot >= 0 and is_equal_approx(director.crack_globals[slot].w, 22.0)
		and lantern != null and dim < 0.5 and director.succession_state(LandblockManifest.CAMP_HOLLOWAY) == Succession.ZONE_HUSHED,
		"the Rush-Light Hush-Crack is open: its 22 m blight goes to every world shader, and the Wind-Lantern in it burns dim (%.2f; hushed %s, %.1f m, slot %d, state %d)"
		% [dim, crack.is_hushed(), crack.hush_radius, slot, director.succession_state(LandblockManifest.CAMP_HOLLOWAY)])
	for minion: WoodlandMinion in camp.minions:
		minion.stats.take_damage(minion.stats.health + 100.0)
	var bloomed: bool = false
	for frame: int in 60:
		await tree.physics_frame
		await tree.process_frame
		if _bloom_near(crack.global_position) > 0.0:
			bloomed = true
			break
	var db: WorldStateDB = world.world_state
	check.call(camp.is_cleared and bloomed and bool(db.get_entity_state(Vector2i(0, -1), LandblockManifest.CAMP_HOLLOWAY).get("cleared", false))
		and director.succession_state(LandblockManifest.CAMP_HOLLOWAY) == Succession.ZONE_RECLAIMED,
		"clearing its camp seals it (WorldStateDB: cleared) and a golden-emerald Reclamation Bloom sweeps out from it")
	for frame: int in 200:
		await tree.process_frame
	var lit: float = (lantern.get_node("Pivot/Light") as OmniLight3D).light_energy
	check.call(crack.hush_radius == 0.0 and _crack_slot(crack.global_position) < 0 and crack.get_node("Cairn").visible and not crack.get_node("Crack").visible
		and is_equal_approx(lit, 0.9) and director.blooms_running() == 0,
		"2.5 s later the hush is gone, a mossy Lulled Cairn stands where the crack was and the Wind-Lantern burns warm again (%.2f)" % lit)
	director.set_succession_state(&"moss_oak_hollow", Succession.ZONE_WEATHERING_EVENT)
	_move(world, OAKS)
	for frame: int in 30:
		await tree.process_frame
	director.settle()
	var look: ZoneBiomeResource = WorldVisualCatalog.biome(&"moss_oak_hollow")
	var weather: Dictionary = director.look_snapshot()
	var foggy: bool = float(weather["fog_density"]) > look.fog_density * 1.8 and (weather["wind"] as Vector4).w > WorldAtmosphereDirector.BASE_WIND.w * 1.5
	director.set_succession_state(&"moss_oak_hollow", Succession.ZONE_HUSHED)
	director.settle()
	var greyed: bool = is_equal_approx(float(director.look_snapshot()["saturation"]), WorldAtmosphereDirector.HUSHED_SATURATION)
	director.set_succession_state(&"moss_oak_hollow", Succession.ZONE_RECLAIMED)
	director.settle()
	check.call(weather["biome"] == &"moss_oak_hollow" and foggy and greyed and is_equal_approx(float(director.look_snapshot()["fog_density"]), look.fog_density),
		"a weathering event thickens Moss-Oak Hollow's fog and wind, a hushed zone loses colour, and reclaimed it's itself again")


func _crack_slot(at: Vector3) -> int:
	for slot: int in director.crack_globals.size():
		var value: Vector4 = director.crack_globals[slot]
		if value.w > 0.0 and Vector3(value.x, value.y, value.z).distance_to(at) < 0.1:
			return slot
	return -1


func _bloom_near(at: Vector3) -> float:
	for value: Vector4 in director.bloom_globals:
		if value.w > 0.0 and Vector3(value.x, value.y, value.z).distance_to(at) < 0.1:
			return value.w
	return 0.0


func _nearest_lantern(world: EverwoodWorld, at: Vector3) -> WindLantern:
	var best: WindLantern = null
	for node: Node in world.find_children("*", "Node3D", true, false):
		var lantern: WindLantern = node as WindLantern
		if lantern != null and lantern.global_position.distance_to(at) < 14.0 and (best == null or lantern.global_position.distance_to(at) < best.global_position.distance_to(at)):
			best = lantern
	return best


# 8 --------------------------------------------------------------------------------------------

func _check_streaming(world: EverwoodWorld) -> void:
	var fresh: Array[WorldKitInstance] = []
	for index: int in 6:
		var placed: WorldKitInstance = WorldKitInstance.make("TestOak%d" % index, WorldVisualCatalog.KIT_TREE_MOSS_OAK, OAKS + Vector3(40.0 + index * 3.0, 0.0, 0.0), 0.0,
			{&"height": 7.13 + index * 0.31, &"seed_value": 700 + index})
		world.add_child(placed)
		fresh.append(placed)
	var waiting: int = WorldKitInstance.waiting_count()
	var start: int = Time.get_ticks_usec()
	var built: int = WorldKitInstance.build_waiting()
	var slice: int = Time.get_ticks_usec() - start
	for frame: int in 30:
		await tree.process_frame
	var all_built: bool = fresh.all(func(placed: WorldKitInstance) -> bool: return placed.kit != null)
	for placed: WorldKitInstance in fresh:
		placed.queue_free()
	# A slice stops once its budget is spent (or nothing waits), so one frame builds only what fits.
	check.call(waiting >= 6 and built >= 1 and (built == waiting or slice >= WorldKitInstance.BUILD_BUDGET_USEC) and all_built
		and WorldKitInstance.BUILD_BUDGET_USEC < WorldGridConfig.FRAME_BUDGET_USEC,
		"new kits wait their turn: a frame builds them for about %d µs (%d of %d in %d µs), inside the 2 ms streaming budget, and the queue drains"
		% [WorldKitInstance.BUILD_BUDGET_USEC, built, waiting, slice])
	var ring_chunk: Vector2i = Vector2i(0, -3)
	var data: Dictionary = LandblockClutter.build_clutter_data(ring_chunk)
	var on_floor: int = 0
	var instances: int = 0
	var baked: Dictionary = data["baked"]
	var center: Vector3 = baked.get("center", Vector3.ZERO)
	for batch: int in ChunkClutterBaker.BATCH_NAMES.size():
		var buffer: PackedFloat32Array = baked[batch]["buffer"]
		for index: int in int(baked[batch]["count"]):
			instances += 1
			var x: float = buffer[index * 16 + 3] + center.x
			var z: float = buffer[index * 16 + 11] + center.z
			on_floor += 1 if LandblockManifest.in_footprint(x, z) else 0
	check.call(instances > 100 and on_floor == 0 and baked["biome"] == &"ring_of_the_cairnsman",
		"the Ring of the Cairnsman's chunk grows %d tufts, blooms and pebbles round it, none on the arena floor (telegraphs read clean)" % instances)


# --- In Oakshire Vale ------------------------------------------------------------------------

func run_vale(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	director = WorldAtmosphereDirector.current
	var level: OakshireVale = tree.current_scene as OakshireVale
	check.call(level != null, "the vale's visual checks run in Oakshire Vale")
	if level == null:
		return
	var vale: OakshireValeLayout = WorldGridConfig.layout as OakshireValeLayout
	var wrong: Array[String] = []
	for petal: int in OakshireValeLayout.PETAL_NAMES.size():
		var at: Vector3 = vale.camp_center(petal)
		if level.visual_biome_at(at) != PETAL_BIOMES[petal]:
			wrong.append("%s: %s" % [OakshireValeLayout.PETAL_NAMES[petal], level.visual_biome_at(at)])
	var village: Vector3 = Vector3(OakshireValeLayout.CENTER.x, 12.0, OakshireValeLayout.CENTER.y)
	check.call(wrong.is_empty() and level.visual_biome_at(village) == &"oakshire_wick",
		"each part of the vale wears its own biome: Oakshire-Wick in the village, and each petal its own%s" % ("" if wrong.is_empty() else " (%s)" % ", ".join(wrong)))
	var people: Array[ActorBase] = _people()
	var homes: Array[Vector3] = []
	for index: int in people.size():
		homes.append(people[index].global_position)
		people[index].place_at(Transform3D(Basis.IDENTITY, vale.camp_center(OakshireValeLayout.Petal.WEALD) + Vector3(index * 1.6, 0.3, 0.0)))
	for frame: int in 20:
		await tree.process_frame
	director.settle()
	var look: Dictionary = director.look_snapshot()
	var hollow: ZoneBiomeResource = WorldVisualCatalog.biome(&"bramble_hollow")
	check.call(look["biome"] == &"bramble_hollow" and is_equal_approx(float(look["fog_density"]), hollow.fog_density)
		and (look["sky_top"] as Color).is_equal_approx(hollow.sky_top_color),
		"walking into Bramble-Hollow, the sky, sun and fog ease to its damp, misty look")
	for index: int in people.size():
		people[index].place_at(Transform3D(Basis.IDENTITY, homes[index]))
	_check_vale_landmarks()
	var stripes: Array[bool] = []
	var petal_theta: float = deg_to_rad(OakshireValeLayout.PETAL_BEARINGS[OakshireValeLayout.Petal.ORCHARD])
	var outward: Vector2 = Vector2(sin(petal_theta), -cos(petal_theta))
	var across: Vector2 = Vector2(cos(petal_theta), sin(petal_theta))
	for step: int in 8:
		var at: Vector2 = OakshireValeLayout.CENTER + outward * 420.0 + across * (20.0 + step * 2.0)
		if vale.road_lateral(at.x, at.y) > 8.0:
			stripes.append(vale.field_color(at.x, at.y, vale.sample_height(at.x, at.y)).r > 0.585)
	check.call(stripes.has(true) and stripes.has(false), "Pippin-Green's pasture is striped with ochre plough-furrows")
	var chunk: Vector2i = WorldGridConfig.world_to_chunk(vale.camp_center(OakshireValeLayout.Petal.WEALD) + Vector3(30.0, 0.0, 30.0))
	var clutter: Dictionary = vale.build_clutter_data(chunk)
	var baked: Dictionary = clutter.get("baked", {})
	check.call(baked.get("biome", &"") == &"bramble_hollow" and ChunkClutterBaker.instance_count(baked) > 200,
		"Bramble-Hollow's landblocks grow their own ground life (%d tufts, ferns and rush-reeds, and pebbles)" % ChunkClutterBaker.instance_count(baked))


## The village's and petals' landmarks, and the Hush-Cracks under the briars, outlaws and wights, in the baked landblocks.
func _check_vale_landmarks() -> void:
	var found: Dictionary[String, bool] = {}
	var posts: int = 0
	var hives: int = 0
	var cracked: int = 0
	var hall: bool = false
	for file: String in DirAccess.get_files_at(OakshireValeLayout.LANDBLOCK_FOLDER):
		if not file.begins_with("landblock_") or not file.ends_with(".tscn"):
			continue
		var scene: PackedScene = load(OakshireValeLayout.LANDBLOCK_FOLDER + file) as PackedScene
		var root: Node = scene.instantiate()
		for node: Node in root.find_children("*", "", true, false):
			found[String(node.name)] = true
			posts += 1 if node is ChimePost else 0
			hives += 1 if String(node.name).begins_with("Hive") else 0
			var spawner: MobSpawner = node as MobSpawner
			cracked += 1 if spawner != null and spawner.has_hush_crack else 0
			var placed: WorldKitInstance = node as WorldKitInstance
			hall = hall or (placed != null and placed.variant == &"OAKSHIRE_HOMESTEAD_HALL")
		root.free()
	var missing: Array[String] = []
	for name: String in VALE_LANDMARKS:
		if not found.has(name):
			missing.append(name)
	check.call(missing.is_empty() and hall and hives == 7 and posts >= 6,
		"Oakshire-Wick has its Homestead Hall, Kindle-Fire, desk pavilion, Chime-Shrine pagoda, %d bee-hives and walled pumpkin patches, and every petal its landmarks and Chime-Post (%d posts)%s"
		% [hives, posts, "" if missing.is_empty() else " (missing %s)" % ", ".join(missing)])
	check.call(cracked >= 8, "%d of the vale's spawners sit on Hush-Cracks (Bramble-Hollow's briars, the outlaws' camp, the barrow wights)" % cracked)


# --- Helpers ---------------------------------------------------------------------------------

func _people() -> Array[ActorBase]:
	var people: Array[ActorBase] = []
	for actor: ActorBase in CombatDirector.current.party_actors():
		if not actor.is_companion:
			people.append(actor)
	return people


func _camp(world: EverwoodWorld, id: StringName) -> MinionCamp:
	for camp: MinionCamp in world.camps:
		if is_instance_valid(camp) and camp.persist_id == id:
			return camp
	return null


func _move(world: EverwoodWorld, spot: Vector3) -> void:
	var index: int = 0
	for actor: ActorBase in world.actors.values():
		actor.place_at(Transform3D(Basis.IDENTITY, spot + Vector3((index - 1) * 1.6, 0.2, 0.0)))
		index += 1


func _settle(world: EverwoodWorld, full: Array[Vector2i]) -> void:
	var grid: WorldGridManager = world.grid_manager
	for frame: int in 1200:
		await tree.process_frame
		if frame < 26 or not grid.is_idle():
			continue
		var ready: bool = true
		for chunk: Vector2i in full:
			ready = ready and grid.get_chunk_state(chunk) == WorldGridManager.ChunkState.FULL_GAMEPLAY
		if ready:
			WorldKitInstance.build_waiting(1000000)
			return
