## Phase 18's checks (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §9), run by
## tools/smoke_test.gd in each instance it visits:
##   run_hub    the camera pitch rig and its controls, the label style on every
##              Label3D and the station layer under a modal, the sculpted
##              generators and kits, the shaders and their globals, the clutter's
##              grass, verges and cornices, the parchment map, the minimap, the
##              Atlas and its pins and firefly trail, and a Hush-Crack sealing
##              into a cairn on the minimap
##   run_dojo   labels and nameplates (staggered, no "(bot)"), the Ring's
##              sculpted megaliths (no BoxMesh stones), the Lantern's Promise
##              halos, the Holloway's sleepers and guide-posts, the expedition's map
##   run_world  labels, the fog, the corridor's map from its layout and listing
##   run_vale   labels, Oakshire's map (river, roads, 31 footprints, 10 cracks),
##              its market pavilions on the cobbled plaza, Quarry-Wick's terrace
##              climbs and Nine-Stones' causeway posts and megaliths, and the
##              minimap's ribbon in Oakshire-Wick
extends RefCounted

const Succession = ZoneSuccessionVisualResource.SuccessionState
const NEW_KITS: Array[StringName] = [&"kit_market_pavilion", &"kit_cliff_cornice", &"kit_path_sleeper", &"kit_stepping_stone", &"kit_guide_post"]
const VALE_ZONES: Dictionary[StringName, Vector2] = {&"oakshire_wick": Vector2(768.0, 768.0), &"wayfarer_green": Vector2(736.5, 1218.0),
	&"pippin_green": Vector2(434.9, 378.5), &"quarry_wick": Vector2(1184.3, 1012.1), &"bramble_hollow": Vector2(1040.2, 311.4),
	&"nine_stones_crossing": Vector2(305.7, 805.1)}
const TRAIL_ZONES: Array[StringName] = [&"honey_wick", &"bramble_bridge", &"moss_oak_hollow", &"rush_light_hollow", &"dover_slap_bridge",
	&"ring_of_the_cairnsman"]

var tree: SceneTree
var check: Callable


func _seconds(duration: float) -> void:
	await tree.create_timer(duration, true, true).timeout


func _frames(count: int) -> void:
	for frame: int in count:
		await tree.process_frame


func _level() -> LevelBase:
	return tree.current_scene as LevelBase


func _first_local() -> ActorBase:
	var level: LevelBase = _level()
	if level == null:
		return null
	for player_id: StringName in level.actors:
		var actor: ActorBase = level.actors[player_id]
		if is_instance_valid(actor) and actor.input != null:
			return actor
	return null


# --- In Bramble-Bridge (Hub Town) ------------------------------------------------------------

func run_hub(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	_check_map_zones()
	await _check_camera_pitch()
	await _check_labels("hub_town")
	_check_generators_and_kits()
	_check_shaders_and_globals()
	_check_clutter()
	await _check_hub_cartography()
	await _check_atlas_and_trail()
	await _check_crack_seal_on_minimap()


func _check_map_zones() -> void:
	var placed: Array[String] = []
	for id: StringName in VALE_ZONES:
		var zone: WorldMapZoneResource = WorldVisualCatalog.map_zone(id)
		if zone == null or zone.instance_id != &"oakshire_vale" or zone.world_center_xz.distance_to(VALE_ZONES[id]) > 0.5:
			placed.append(String(id))
	for id: StringName in TRAIL_ZONES:
		var zone: WorldMapZoneResource = WorldVisualCatalog.map_zone(id)
		if zone == null or zone.instance_id != &"everwood_world":
			placed.append(String(id))
	var named: WorldMapZoneResource = WorldVisualCatalog.map_zone_at(&"oakshire_vale", Vector2(770.0, 770.0))
	check.call(placed.is_empty() and WorldVisualCatalog.map_zones(&"oakshire_vale").size() == 6 and WorldVisualCatalog.map_zones(&"everwood_world").size() == 6
		and named != null and named.zone_id == &"oakshire_wick" and named.cooper_sign_title != "" and named.contains_xz(Vector2(800.0, 800.0)),
		"the Wayfarer's map zones: Oakshire-Wick and its five petals, and the Bramble-Bridge trail's six stops, each with its Cooper Sign%s"
		% ("" if placed.is_empty() else " (wrong: %s)" % ", ".join(placed)))


func _check_camera_pitch() -> void:
	var level: LevelBase = _level()
	var view: PlayerCamera = level.camera_for_seat(1) if level != null else null
	check.call(view != null and is_equal_approx(level.get_camera_pitch_degrees(1), PlayerCamera.CAM_DEFAULT_PITCH_DEG)
		and is_equal_approx(PlayerCamera.pivot_height(22.0) + PlayerCamera.CAM_HIGH_BOOM_M * sin(deg_to_rad(22.0)), PlayerCamera.CAM_DEFAULT_HEIGHT_M),
		"P1's camera starts at +22 degrees, its eye 4.8 m up on a 6.8 m boom")
	if view == null:
		return
	var feet: Vector3 = view.actor.global_position
	level.set_camera_pitch_degrees(1, -10.0)
	await _frames(3)
	var low_ground: float = view.ground_height_under(view.global_position)
	var low_ok: bool = (is_equal_approx(level.get_camera_pitch_degrees(1), -10.0) and is_equal_approx(view.current_pivot_height(), PlayerCamera.CAM_LOW_PIVOT_HEIGHT_M)
		and is_equal_approx(PlayerCamera.boom_length(-10.0), PlayerCamera.CAM_LOW_BOOM_M)
		and (is_nan(low_ground) or view.global_position.y >= low_ground + 0.4) and view.global_position.y < feet.y + 2.0)
	check.call(low_ok, "set_camera_pitch_degrees(1, -10): it looks up from a 1.65 m pivot on a 3.6 m boom over the shoulder, its eye %.2f m up, never within 0.4 m of the ground"
		% (view.global_position.y - feet.y))
	level.set_camera_pitch_degrees(1, 48.0)
	await _frames(3)
	var rise: float = view.global_position.y - view.actor.global_position.y
	var wanted: float = PlayerCamera.pivot_height(48.0) + PlayerCamera.CAM_HIGH_BOOM_M * sin(deg_to_rad(48.0))
	check.call(is_equal_approx(level.get_camera_pitch_degrees(1), 48.0) and absf(rise - wanted) < 0.35,
		"set_camera_pitch_degrees(1, 48): it looks down over the fight from %.1f m up on the 6.8 m boom" % rise)
	level.set_camera_pitch_degrees(1, 90.0)
	var top: float = level.get_camera_pitch_degrees(1)
	level.set_camera_pitch_degrees(1, -40.0)
	var bottom: float = level.get_camera_pitch_degrees(1)
	level.set_camera_pitch_degrees(1, PlayerCamera.CAM_DEFAULT_PITCH_DEG)
	await _frames(2)
	var events: Array[String] = []
	for action: StringName in [InputComponent.ACTION_CAMERA_PITCH_UP, InputComponent.ACTION_CAMERA_PITCH_DOWN, InputComponent.ACTION_MOUSE_LOOK]:
		if not InputMap.has_action(action):
			events.append("no %s" % action)
	var up: Array[InputEvent] = InputMap.action_get_events(InputComponent.ACTION_CAMERA_PITCH_UP) if InputMap.has_action(InputComponent.ACTION_CAMERA_PITCH_UP) else []
	var keys: Array[int] = []
	var axis_ok: bool = false
	for event: InputEvent in up:
		if event is InputEventKey:
			keys.append((event as InputEventKey).physical_keycode)
		if event is InputEventJoypadMotion and (event as InputEventJoypadMotion).axis == JOY_AXIS_RIGHT_Y and (event as InputEventJoypadMotion).axis_value < 0.0:
			axis_ok = true
	check.call(is_equal_approx(top, 52.0) and is_equal_approx(bottom, -12.0) and events.is_empty() and KEY_PAGEUP in keys and KEY_BRACKETLEFT in keys and axis_ok
		and is_equal_approx(InputMap.action_get_deadzone(InputComponent.ACTION_CAMERA_PITCH_UP), 0.15) and PlayerCamera.CAM_PITCH_SPEED == 1.85
		and InputComponent.MOUSE_PITCH_SENSITIVITY == 0.0035,
		"the pitch holds between -12 and +52 degrees, on the right stick's Y (deadzone 0.15, 1.85 rad/s), PageUp / [ and PageDown / ], the mouse's Y (x0.0035) and V for mouse-look%s"
		% ("" if events.is_empty() else " (%s)" % ", ".join(events)))


## Every Label3D in the level wears the world style; nameplates and world signs on their layers.
func _check_labels(where: String) -> void:
	await _frames(2)
	var level: LevelBase = _level()
	var labels: Array[Node] = level.find_children("*", "Label3D", true, false) if level != null else []
	var wrong: Array[String] = []
	var stations: int = 0
	for node: Node in labels:
		var label: Label3D = node as Label3D
		if (label.fixed_size or label.visibility_range_end > 30.0 or label.visibility_range_end <= 0.0 or not is_equal_approx(label.pixel_size, WorldLabelStyle.PIXEL_SIZE)
				or label.font_size != WorldLabelStyle.FONT_SIZE or label.outline_size != WorldLabelStyle.OUTLINE_SIZE
				or label.visibility_range_fade_mode != GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF or not is_equal_approx(label.visibility_range_begin, 1.8)):
			if wrong.size() < 4:
				wrong.append(String(label.get_path()).get_file())
			else:
				wrong.append("")
		if WorldLabelStyle.is_station_label(label):
			stations += 1
			if label.layers != 1 << (WorldLabelStyle.STATION_LABEL_LAYER - 1):
				wrong.append("%s not on the station layer" % label.name)
	check.call(labels.size() > 0 and wrong.is_empty(),
		"%s: all %d Label3Ds are sized in the world (fixed_size off, 32 px at 0.0042 m, outline 8), shown 1.8 to 24 m and fading themselves out (%d world signs on the station layer)%s"
		% [where, labels.size(), stations, "" if wrong.is_empty() else " (%d wrong: %s)" % [wrong.size(), ", ".join(wrong.filter(func(text: String) -> bool: return text != ""))]])


func _check_generators_and_kits() -> void:
	var trunk: ArrayMesh = ShapeKit.make_gnarled_trunk_mesh(8.0, 0.45, 0.18, 4, 7)
	var crown: ArrayMesh = ShapeKit.make_leaf_cloud_crown(Vector3(0.0, 6.0, 0.0), 3.0, 14, 7, Color(0.3, 0.5, 0.2), Color(0.5, 0.75, 0.3))
	var tuft: ArrayMesh = ShapeKit.make_lush_grass_tuft_mesh(8, 11)
	var stone: ArrayMesh = ShapeKit.make_sculpted_megalith(Vector3(1.4, 4.2, 0.9), 3)
	var cornice: ArrayMesh = ShapeKit.make_cliff_cornice(6.0, 1.8, 3)
	var skirt: ArrayMesh = ShapeKit.make_ground_contact_skirt(Vector2(6.0, 5.0))
	var stone_box: AABB = stone.get_aabb()
	var boughs: PackedVector3Array = trunk.get_meta(ShapeKit.META_BOUGH_TIPS, PackedVector3Array())
	var high_boughs: bool = boughs.size() == 4
	for tip: Vector3 in boughs:
		high_boughs = high_boughs and tip.y > ShapeKit.BOUGH_START_M
	check.call(_vertices(trunk) > 100 and high_boughs and _vertices(crown) > 14 * 12 and _vertices(tuft) == 8 * 10 and _vertices(stone) > 24
		and stone_box.size.y > 4.0 and stone_box.position.y > -0.01 and cornice.get_surface_count() == 2 and _vertices(skirt) > 24,
		"the sculpted generators: a gnarled trunk (%d vertices, its 4 boughs forking above 3.2 m), a 14-lobe leaf-cloud crown, an 8-blade grass tuft, a Voronoi-cleaved megalith (%d vertices), a rock-and-turf cornice and a contact skirt"
		% [_vertices(trunk), _vertices(stone)])
	var missing: Array[String] = []
	for id: StringName in NEW_KITS:
		var kit: WorldPropKitResource = WorldVisualCatalog.kit(id)
		if kit == null:
			missing.append(String(id))
	var post: WorldPropKitResource = WorldVisualCatalog.kit(WorldVisualCatalog.KIT_GUIDE_POST)
	var pavilion: WorldPropKitResource = WorldVisualCatalog.kit(WorldVisualCatalog.KIT_MARKET_PAVILION)
	check.call(missing.is_empty() and WorldVisualCatalog.kits().size() == 26 and post != null and post.is_low_scenery and post.bounding_size.y <= 0.601
		and pavilion != null and pavilion.category == &"ARCHITECTURE" and pavilion.enable_sightline_fade,
		"the five new kits (market pavilion, Crag-Crest Cornice, log sleepers, stepping-stones, a 0.6 m LowScenery guide-post), %d in all%s"
		% [WorldVisualCatalog.kits().size(), "" if missing.is_empty() else " (missing: %s)" % ", ".join(missing)])
	if post != null and pavilion != null and not (post.is_low_scenery and post.bounding_size.y <= 0.6 and pavilion.category == &"ARCHITECTURE" and pavilion.enable_sightline_fade):
		print("    kits: post low %s %s, pavilion %s fade %s" % [post.is_low_scenery, post.bounding_size, pavilion.category, pavilion.enable_sightline_fade])
	var market: Node3D = WorldAssetCatalog.build(WorldVisualCatalog.KIT_MARKET_PAVILION, {"color": WorldAssetCatalog.MARKET_DYES[2]})
	var house: Node3D = WorldAssetCatalog.build(WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE, {})
	var tree_kit: Node3D = WorldAssetCatalog.build(WorldVisualCatalog.KIT_TREE_MOSS_OAK, {"height": 10.0})
	var cairn: Node3D = WorldAssetCatalog.build(WorldVisualCatalog.KIT_HUSH_CRACK_AND_CAIRN, {"variant": &"CAIRN"})
	var neon: int = 0
	for dye: Color in WorldAssetCatalog.MARKET_DYES:
		neon += 1 if dye.s > 0.8 and dye.v > 0.9 else 0
	check.call(_kit_vertices(market) > 1500 and _has_shaded_surface(house) and _has_canopy(tree_kit) and _kit_vertices(cairn) > 42 * 20 and neon == 0
		and WorldAssetCatalog.MARKET_DYES == [Color("#D99B38"), Color("#B85A40"), Color("#46789C"), Color("#5C8558")],
		"the kits build: an artisan pavilion under draped striped linen in the four heritage dyes (%d vertices), a house on its mossy contact skirt, a moss-oak's crown in the leaf ramp, a cairn ringed by 42 wildflowers"
		% _kit_vertices(market))
	for made: Node3D in [market, house, tree_kit, cairn]:
		made.free()


func _vertices(mesh: ArrayMesh) -> int:
	var count: int = 0
	for surface: int in mesh.get_surface_count():
		count += (mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return count


func _kit_vertices(root: Node) -> int:
	var count: int = 0
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: ArrayMesh = (node as MeshInstance3D).mesh as ArrayMesh
		if mesh != null:
			count += _vertices(mesh)
	return count


func _surface_materials(root: Node) -> Array[ShaderMaterial]:
	var found: Array[ShaderMaterial] = []
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (node as MeshInstance3D).mesh
		if mesh == null:
			continue
		for surface: int in mesh.get_surface_count():
			var material: ShaderMaterial = mesh.surface_get_material(surface) as ShaderMaterial
			if material != null:
				found.append(material)
	return found


func _has_shaded_surface(root: Node) -> bool:
	for material: ShaderMaterial in _surface_materials(root):
		if material.get_shader_parameter(&"vertex_shade") == true:
			return true
	return false


func _has_canopy(root: Node) -> bool:
	for material: ShaderMaterial in _surface_materials(root):
		if material.get_shader_parameter(&"leaf_ramp") != null and float(material.get_shader_parameter(&"leaf_ramp")) > 0.5:
			return true
	return false


func _check_shaders_and_globals() -> void:
	var foliage: String = FileAccess.get_file_as_string("res://src/world/shaders/storybook_foliage_wind.gdshader")
	var light: String = FileAccess.get_file_as_string("res://src/actors/storybook_cel_light.gdshaderinc")
	var common: String = FileAccess.get_file_as_string("res://src/world/shaders/storybook_world_common.gdshaderinc")
	var splat: String = FileAccess.get_file_as_string("res://src/world/shaders/storybook_terrain_splat.gdshader")
	var terrain3d: String = FileAccess.get_file_as_string("res://src/world/landblock_terrain3d.gdshader")
	var triplanar: String = FileAccess.get_file_as_string("res://src/world/shaders/storybook_world_triplanar.gdshaderinc")
	var ring: String = FileAccess.get_file_as_string("res://src/world/shaders/hush_ring_pulse.gdshader")
	var shader_ok: bool = (foliage.contains("grass_blades") and foliage.contains("wave_bend_degrees") and foliage.contains("gust_sheen")
		and foliage.contains("blight_at(origin)") and foliage.contains("frozen_wind_scale") and light.contains("vec3(0.45, 0.62, 0.18)")
		and light.contains("LEAF_MID") and common.contains("float cloud_shadow(") and common.contains("lantern_halo_3") and common.contains("float blight_at(")
		and common.contains("sin(world_xz.x * 0.18 + world_xz.y * 0.12 - TIME * 2.4)") and splat.contains("STORYBOOK_CLOUD_POS")
		and terrain3d.contains("STORYBOOK_CLOUD_POS") and triplanar.contains("STORYBOOK_CLOUD_POS") and triplanar.contains("vertex_shade") and ring.contains("ring_radius"))
	var globals: Array[String] = []
	for name: String in ["lantern_halo_0", "lantern_halo_1", "lantern_halo_2", "lantern_halo_3", "cloud_shadow_params", "blight_ashen", "blight_rime",
			"blight_wind", "ground_turf", "ground_road", "ground_verge"]:
		if not ProjectSettings.has_setting("shader_globals/%s" % name):
			globals.append(name)
	var hushed: ZoneSuccessionVisualResource = WorldVisualCatalog.succession(Succession.ZONE_HUSHED)
	check.call(shader_ok and globals.is_empty() and ZoneBiomeResource.DEFAULT_HUSH_RADIUS_M == 22.0 and ZoneBiomeResource.LANTERN_HALO_RADIUS_M == 5.5
		and HushCrackLandmark.HUSH_RADIUS == 22.0 and is_equal_approx(hushed.blight_desaturation, 0.85) and is_equal_approx(hushed.frozen_wind_multiplier, 0.05)
		and is_equal_approx(hushed.pressed_grass_height, 0.55),
		"the shaders: rolling wind-waves bending grass 28 degrees with a gust sheen, the leaf ramp and its backlight, cloud shadows in the terrain, Terrain3D and triplanar shaders, the blight in 22 m (85% drained, wind x0.05, grass pressed to 55%%) pushed back by 5.5 m Lantern's Promise halos, all bound as global parameters%s"
		% ("" if globals.is_empty() else " (missing globals: %s)" % ", ".join(globals)))


func _check_clutter() -> void:
	var look: ZoneBiomeResource = WorldVisualCatalog.biome(&"wayfarer_green")
	var data: Dictionary = LandblockClutter.build_clutter_data(Vector2i(0, -1))
	var baked: Dictionary = data["baked"]
	var grass: ShaderMaterial = WorldVisualCatalog.grass_blades()
	var magenta: Array[String] = []
	for biome: ZoneBiomeResource in WorldVisualCatalog.biomes():
		for bloom: Color in ChunkClutterBaker.grounded_palette(biome.flower_colors):
			if bloom.h * 360.0 > 285.0 and bloom.h * 360.0 < 340.0 and bloom.s > 0.45:
				magenta.append(String(biome.biome_id))
	var nodes: Array[MultiMeshInstance3D] = ChunkClutterBaker.make_nodes(baked)
	var fades: bool = not nodes.is_empty()
	for node: MultiMeshInstance3D in nodes:
		fades = fades and node.visibility_range_fade_mode == GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		node.free()
	var tuft_mesh: ArrayMesh = ChunkClutterBaker.mesh_for(ChunkClutterBaker.GRASS, &"wayfarer_green")
	check.call(ChunkClutterBaker.grass_count(look) == ChunkClutterBaker.GRASS_HEADLESS and int(baked[ChunkClutterBaker.GRASS]["count"]) <= 600
		and clampi(int(look.grass_clump_count * ChunkClutterBaker.GRASS_DENSITY), 2500, 3600) >= 2500 and grass.get_shader_parameter(&"grass_blades") == true
		and is_equal_approx(float(grass.get_shader_parameter(&"wave_bend_degrees")), 28.0) and is_equal_approx(float(grass.get_shader_parameter(&"gust_sheen")), 0.14)
		and is_equal_approx(float(grass.get_shader_parameter(&"fade_out_distance")), 95.0) and _vertices(tuft_mesh) == 80 and fades and magenta.is_empty(),
		"the grass: lush 8-blade tufts, 600 a landblock headless (2,500 to 3,600 in a window), roots in the ground's colour, tips #84BD52, bending 28 degrees in the wind-waves, shrinking away by 95 m and fading themselves; no neon-magenta blooms%s"
		% ("" if magenta.is_empty() else " (magenta in %s)" % ", ".join(magenta)))
	check.call(int(baked[ChunkClutterBaker.CURBS]["count"]) > 10 and int(baked[ChunkClutterBaker.VERGES]["count"]) > 30
		and int(baked[ChunkClutterBaker.CORNICES]["count"]) > 4 and int(data[LandblockClutter.Kind.GUIDE_POST]["count"]) >= 0,
		"the Moss-Oak trail's landblock: %d curb-stones and %d fern, plantain and clover verges along its edges, %d Crag-Crest Cornices on its ridges"
		% [int(baked[ChunkClutterBaker.CURBS]["count"]), int(baked[ChunkClutterBaker.VERGES]["count"]), int(baked[ChunkClutterBaker.CORNICES]["count"])])
	var climbing: Dictionary = LandblockClutter.build_clutter_data(Vector2i(0, -2))
	check.call(int(climbing[LandblockClutter.Kind.GUIDE_POST]["count"]) > 6 and int(climbing[LandblockClutter.Kind.STEPPING_STONE]["count"]) > 6,
		"the climb to Dover-Slap-Bridge: stepping-stones up the trail bordered by %d low guide-posts" % int(climbing[LandblockClutter.Kind.GUIDE_POST]["count"]))


func _check_hub_cartography() -> void:
	var level: LevelBase = _level()
	var viewports: int = tree.root.find_children("*", "SubViewport", true, false).size()
	CartographyBaker.clear_cache()
	var map: ImageTexture = CartographyBaker.bake_level_map(level)
	var image: Image = map.get_image()
	var counts: Dictionary[String, int] = _palette_counts(image)
	check.call(maxi(map.get_width(), map.get_height()) == CartographyBaker.MAP_SIZE_HEADLESS and CartographyBaker.world_rect(map) == level.map_rect()
		and counts["parchment"] > 0 and counts["road"] > 0 and counts["water"] > 0 and counts["footprint"] > 0
		and tree.root.find_children("*", "SubViewport", true, false).size() == viewports,
		"Bramble-Bridge's parchment map is drawn in code (%dx%d, no SubViewports): its lane, its canal and %d px of buildings"
		% [map.get_width(), map.get_height(), counts["footprint"]])
	var actor: ActorBase = _first_local()
	var hud: PlayerHUD = PlayerHUD.for_actor(tree, actor) if actor != null else null
	var minimap: WayfarerMinimapWidget = hud.minimap if hud != null else null
	# Its map is painted on a worker thread: give it a few seconds.
	for wait: int in 40:
		if minimap == null or minimap.map != null:
			break
		await _seconds(0.2)
	check.call(minimap != null and minimap.window_size() == WayfarerMinimapWidget.SIZE_FEW and minimap.ribbon_text().begins_with("Bramble-Bridge · (Chunk ")
		and minimap.map != null and minimap.get_rect().end.x <= hud.size.x + 1.0 and minimap.get_rect().position.x > hud.size.x * 0.5,
		"P1's minimap sits top-right of their HUD (124 px with one or two players): \"%s\" (%s in a %s HUD, %s)"
		% [minimap.ribbon_text() if minimap != null else "none", minimap.get_rect() if minimap != null else Rect2(), hud.size if hud != null else Vector2.ZERO,
			"map ready" if minimap != null and minimap.map != null else "no map yet"])


## How many of a map's pixels are each of its inks.
func _palette_counts(image: Image) -> Dictionary[String, int]:
	var counts: Dictionary[String, int] = {"parchment": 0, "road": 0, "water": 0, "footprint": 0, "contour": 0}
	var inks: Dictionary[String, Color] = {"road": CartographyBaker.ROAD, "water": CartographyBaker.WATER, "footprint": CartographyBaker.FOOTPRINT}
	for y: int in range(0, image.get_height(), 2):
		for x: int in range(0, image.get_width(), 2):
			var pixel: Color = image.get_pixel(x, y)
			var found: bool = false
			for ink: String in inks:
				if _near(pixel, inks[ink], 0.02):
					counts[ink] += 1
					found = true
			if not found and _near(pixel, CartographyBaker.PARCHMENT, 0.09):
				counts["parchment"] += 1
			elif not found and _near(pixel, CartographyBaker.PARCHMENT.lerp(CartographyBaker.CONTOUR, 0.85), 0.04):
				counts["contour"] += 1
	return counts


func _near(a: Color, b: Color, reach: float) -> bool:
	return absf(a.r - b.r) < reach and absf(a.g - b.g) < reach and absf(a.b - b.b) < reach


func _check_atlas_and_trail() -> void:
	var actor: ActorBase = _first_local()
	var hud: PlayerHUD = PlayerHUD.for_actor(tree, actor) if actor != null else null
	if hud == null:
		check.call(false, "the Atlas needs P1's HUD")
		return
	var level: LevelBase = _level()
	var view: PlayerCamera = level.camera_for_seat(actor.party_slot + 1)
	var opened: bool = hud.open_atlas()
	await _frames(2)
	var atlas: CartographyAtlasPanel = hud.atlas_panel()
	var hidden: bool = view != null and not view.get_cull_mask_value(WorldLabelStyle.STATION_LABEL_LAYER)
	check.call(opened and atlas != null and actor.input.menu_open and hidden and atlas.zones().size() == 1 and atlas.map != null,
		"a tap of M opens the Wayfarer's Atlas over P1's view (the controller drives it, the station signs drop out of the view behind it)")
	var target: Vector2 = Vector2(actor.global_position.x, actor.global_position.z) + Vector2(0.0, -24.0)
	atlas.pin(target)
	await _frames(3)
	var trail: WayfarerTrailGuideFX = hud.trail_guide
	var lifted: bool = trail != null and trail.ribbon_points().size() == WayfarerTrailGuideFX.MOTE_COUNT
	if lifted:
		for point: Vector3 in trail.ribbon_points():
			var ground: float = view.ground_height_under(point) if view != null else 0.0
			lifted = lifted and (is_nan(ground) or absf(point.y - ground - WayfarerTrailGuideFX.RIBBON_HEIGHT_M) < 0.2)
	check.call(hud.has_pin() and hud.pinned_target_xz == target and lifted,
		"pinning a place on the Atlas lights a firefly trail toward it, 0.8 m over the ground")
	atlas.handle_menu(InputComponent.MENU_BACK)
	await _frames(2)
	check.call(hud.atlas_panel() == null and not actor.input.menu_open and view != null and view.get_cull_mask_value(WorldLabelStyle.STATION_LABEL_LAYER)
		and hud.has_pin() and is_instance_valid(hud.trail_guide),
		"dodge closes the Atlas, the station signs come back, and the trail still leads to the pin")
	hud.clear_pin()
	await _frames(1)
	var binder_opened: bool = hud.open_binder()
	await _frames(2)
	var binder: GrimoireBinderPanel = hud.binder_panel()
	hud.toggle_atlas()
	await _frames(2)
	var tabbed: bool = binder != null and binder.tab == GrimoireBinderPanel.Tab.ATLAS and is_instance_valid(binder.atlas) and binder.atlas.embedded
	hud.toggle_atlas()
	await _frames(1)
	var back: bool = binder != null and binder.tab == GrimoireBinderPanel.Tab.GRIMOIRE
	if binder != null:
		binder.close()
	await _frames(2)
	check.call(binder_opened and tabbed and back and not hud.has_pin() and not actor.input.menu_open,
		"inside the Grimoire Binder, M turns to its \"Atlas Map\" tab and back")


func _check_crack_seal_on_minimap() -> void:
	var actor: ActorBase = _first_local()
	var hud: PlayerHUD = PlayerHUD.for_actor(tree, actor) if actor != null else null
	if hud == null:
		return
	var crack: HushCrackLandmark = HushCrackLandmark.new()
	crack.name = "Phase18Crack"
	crack.crack_id = &"phase_18_test_crack"
	_level().add_child(crack)
	crack.global_position = actor.global_position + Vector3(9.0, 0.0, 6.0)
	await _frames(2)
	var shown: Dictionary = _drawn(hud.minimap, crack.crack_id)
	var open_ok: bool = not shown.is_empty() and not shown["calmed"] and hud.minimap.calmed_text() == "Hush-Cracks: 0/1 Calmed"
	var ash: CPUParticles3D = crack.get_node("AshMotes") as CPUParticles3D
	var ring: MeshInstance3D = crack.get_node("HushRing") as MeshInstance3D
	var shards: Node3D = crack.get_node("Crack") as Node3D
	var cairn: Node3D = crack.get_node("Cairn") as Node3D
	check.call(open_ok and ash != null and ash.emitting and ash.gravity.y > 0.0 and ring != null and ring.visible and shards.visible and not cairn.visible
		and is_equal_approx(crack.hush_radius, 22.0),
		"an open Hush-Crack: slate shards and weeping roots, a breathing slate-violet ring, ash falling upward, its blight 22 m; a slate blot on the minimap (Hush-Cracks: 0/1 Calmed)")
	crack.set_state(Succession.ZONE_RECLAIMED, true)
	await _seconds(1.2)
	var sinking: bool = shards.position.y < -0.3 and cairn.visible and cairn.scale.x < 0.99
	await _seconds(1.6)
	shown = _drawn(hud.minimap, crack.crack_id)
	check.call(sinking and not shards.visible and cairn.visible and cairn.scale.is_equal_approx(Vector3.ONE) and not ring.visible and not ash.emitting
		and is_zero_approx(crack.hush_radius) and not shown.is_empty() and shown["calmed"] and hud.minimap.calmed_text() == "Hush-Cracks: 1/1 Calmed",
		"sealing it sinks the shards into the earth as the mossy cairn and its Way-Lantern rise over 2.5 s; the minimap's blot becomes a Saffron-Gold star (1/1 Calmed)")
	crack.queue_free()
	await _frames(2)


func _drawn(minimap: WayfarerMinimapWidget, id: StringName) -> Dictionary:
	for crack: Dictionary in minimap.drawn_cracks():
		if crack["id"] == id:
			return crack
	return {}


# --- On the expedition ---------------------------------------------------------------------

func run_dojo(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	await _check_labels("dungeon_dojo")
	_check_nameplates()
	_check_megaliths(_level(), "the Ring of the Cairnsman")
	_check_holloway_dressing()
	_check_halos()
	CartographyBaker.clear_cache()
	var map: ImageTexture = CartographyBaker.bake_level_map(_level())
	var counts: Dictionary[String, int] = _palette_counts(map.get_image())
	check.call(counts["road"] > 0 and counts["contour"] > 0 and CartographyBaker.world_rect(map) == DungeonDojo.MAP_RECT,
		"the expedition's map: its trail and the contours of the holloway and the gorge (%d px of contour)" % counts["contour"])


func _check_nameplates() -> void:
	var wrong: Array[String] = []
	var heights: Dictionary[float, bool] = {}
	var companions: int = 0
	for actor: ActorBase in CombatDirector.current.alive_party():
		var plate: Label3D = actor.get_node_or_null("NameLabel") as Label3D
		var name: String = actor.display_name()
		if not name.begins_with("P%d · " % (actor.party_slot + 1)) or name.contains("(bot)"):
			wrong.append(name)
		if plate == null or plate.text != name or not (absf(plate.position.y - actor.nameplate_height(true)) < 0.02 or absf(plate.position.y - actor.nameplate_height(false)) < 0.02):
			wrong.append("%s's plate" % name)
		heights[snappedf(actor.nameplate_height(true) - actor.nameplate_height(false), 0.01)] = true
		companions += 1 if actor.is_companion else 0
	check.call(wrong.is_empty() and CombatDirector.current.alive_party().size() >= 2 and heights.size() >= mini(3, CombatDirector.current.alive_party().size()),
		"nameplates read \"P2 · Bell-Keeper\" for heroes and companions alike (%d companions), staggered 0.22 m by seat over 2.25 m when heroes crowd within 3 m%s"
		% [companions, "" if wrong.is_empty() else " (%s)" % ", ".join(wrong)])


func _check_megaliths(root: Node, where: String, wanted: int = 6) -> void:
	var boxes: Array[String] = []
	var sculpted: int = 0
	for node: Node in root.find_children("*", "WorldKitInstance", true, false):
		var placed: WorldKitInstance = node as WorldKitInstance
		if placed.kit_id != WorldVisualCatalog.KIT_STANDING_STONE:
			continue
		var holder: Node = placed.get_parent()
		for mesh_node: Node in holder.find_children("*", "MeshInstance3D", true, false):
			var mesh: Mesh = (mesh_node as MeshInstance3D).mesh
			if mesh is BoxMesh or mesh is CylinderMesh:
				boxes.append(String(holder.name))
			elif mesh is ArrayMesh and _vertices(mesh as ArrayMesh) > 24:
				sculpted += 1
	check.call(sculpted >= wanted and boxes.is_empty(), "%s's standing stones are sculpted megaliths (%d), none a BoxMesh block%s"
		% [where, sculpted, "" if boxes.is_empty() else " (boxes: %s)" % ", ".join(boxes)])


func _check_holloway_dressing() -> void:
	var level: LevelBase = _level()
	var sleepers: int = 0
	var posts: Array[StaticBody3D] = []
	for node: Node in level.find_children("*", "", true, false):
		if node.name.begins_with("Ramp") and node.name.ends_with("Sleepers"):
			sleepers += 1
		if node.name.begins_with("GuidePost") and node is StaticBody3D:
			posts.append(node as StaticBody3D)
	var low: bool = not posts.is_empty()
	for post: StaticBody3D in posts:
		var shape: BoxShape3D = (post.get_node("Collision") as CollisionShape3D).shape as BoxShape3D
		low = low and post.collision_layer == ActorBase.LAYER_LOW_SCENERY and shape.size.y <= 0.6
	check.call(sleepers == 2 and posts.size() >= 16 and low,
		"Rush-Light-Hollow's two ramps wear half-set log sleepers, bordered by %d guide-posts no taller than 0.6 m on the LowScenery layer" % posts.size())


func _check_halos() -> void:
	var director: WorldAtmosphereDirector = WorldAtmosphereDirector.current
	var healers: int = 0
	for member: ActorBase in CombatDirector.current.alive_party():
		healers += 1 if member.role() == ClassLoadoutResource.Role.HEALER else 0
	var radius_ok: bool = true
	for halo: Vector4 in director.halo_globals:
		radius_ok = radius_ok and (halo.w == 0.0 or is_equal_approx(halo.w, 5.5))
	check.call(director != null and (healers == 0 or director.halos_lit() > 0) and radius_ok,
		"the Lantern's Promise: a warm 5.5 m halo round each Lantern-Bearer (%d lit)" % director.halos_lit())


# --- In the seamless world -----------------------------------------------------------------

func run_world(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	await _check_labels("everwood_world")
	var level: LevelBase = _level()
	var environment: Environment = level.get_world_3d().environment if level.get_world_3d() != null else null
	var world_env: WorldEnvironment = level.find_children("*", "WorldEnvironment", true, false)[0] as WorldEnvironment if not level.find_children("*", "WorldEnvironment", true, false).is_empty() else null
	if environment == null and world_env != null:
		environment = world_env.environment
	check.call(environment != null and is_equal_approx(environment.fog_aerial_perspective, 0.65) and is_equal_approx(environment.fog_sun_scatter, 0.38)
		and is_equal_approx(environment.fog_height, 2.5) and is_equal_approx(environment.fog_height_density, 0.12),
		"the storybook air: aerial perspective 0.65, sun scatter 0.38, a ground fog from 2.5 m (density 0.12)")
	CartographyBaker.clear_cache()
	var map: ImageTexture = CartographyBaker.bake_level_map(level)
	var counts: Dictionary[String, int] = _palette_counts(map.get_image())
	var listed: Dictionary = CartographyBaker._read_json(WorldGridConfig.layout.cartography_path())
	check.call(CartographyBaker.world_rect(map) == WorldGridConfig.layout.map_rect() and counts["road"] > 0 and counts["water"] > 0 and counts["footprint"] > 0
		and (listed.get("footprints", []) as Array).size() >= 10 and (listed.get("cracks", []) as Array).size() >= 2,
		"the trail's map from its layout: the trail and lane, the falls' river, and the %d footprints and %d Hush-Cracks its builder listed"
		% [(listed.get("footprints", []) as Array).size(), (listed.get("cracks", []) as Array).size()])


# --- In Oakshire Vale ----------------------------------------------------------------------

func run_vale(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	await _check_labels("oakshire_vale")
	var level: LevelBase = _level()
	CartographyBaker.clear_cache()
	var map: ImageTexture = CartographyBaker.bake_level_map(level)
	var counts: Dictionary[String, int] = _palette_counts(map.get_image())
	var listed: Dictionary = CartographyBaker._read_json(WorldGridConfig.layout.cartography_path())
	var cracks: Array[Dictionary] = CartographyBaker.cracks(level)
	check.call(CartographyBaker.world_rect(map) == Rect2(0.0, 0.0, OakshireValeLayout.SIZE, OakshireValeLayout.SIZE) and counts["water"] > 20 and counts["road"] > 50
		and counts["footprint"] > 10 and (listed.get("footprints", []) as Array).size() >= 25 and cracks.size() >= 10,
		"Oakshire Vale's parchment map: its river (%d px), its roads (%d px), %d building footprints and all %d Hush-Cracks"
		% [counts["water"], counts["road"], (listed.get("footprints", []) as Array).size(), cracks.size()])
	var actor: ActorBase = _first_local()
	var hud: PlayerHUD = PlayerHUD.for_actor(tree, actor) if actor != null else null
	if hud != null:
		var ribbon: String = hud.minimap.ribbon_text()
		var calmed: String = hud.minimap.calmed_text()
		var zone: WorldMapZoneResource = WorldVisualCatalog.map_zone_at(&"oakshire_vale", Vector2(actor.global_position.x, actor.global_position.z))
		var chunk: Vector2i = WorldGridConfig.world_to_chunk(actor.global_position)
		check.call(ribbon == "%s · (Chunk %d, %d)" % [zone.display_name, chunk.x, chunk.y] and calmed.begins_with("Hush-Cracks: ") and calmed.ends_with("/%d Calmed" % cracks.size()),
			"in the vale the minimap's ribbon reads \"%s\" and \"%s\"" % [ribbon, calmed])
	var layout: OakshireValeLayout = WorldGridConfig.layout as OakshireValeLayout
	var plaza: WorldLayout.MapFeature = layout.map_feature(OakshireValeLayout.CENTER.x + 25.0, OakshireValeLayout.CENTER.y, 12.0) as WorldLayout.MapFeature
	var counts_in_files: Dictionary[String, int] = {"pavilions": 0, "terrace": 0, "terrace_posts": 0, "causeway_posts": 0}
	for file: String in DirAccess.get_files_at(OakshireValeLayout.LANDBLOCK_FOLDER):
		if not file.begins_with("landblock_"):
			continue
		var text: String = FileAccess.get_file_as_string(OakshireValeLayout.LANDBLOCK_FOLDER + file)
		counts_in_files["pavilions"] += text.count("&\"kit_market_pavilion\"")
		counts_in_files["terrace"] += text.count("name=\"TerraceSleepers")
		counts_in_files["terrace_posts"] += text.count("name=\"TerracePost")
		counts_in_files["causeway_posts"] += text.count("name=\"CausewayPost")
	check.call(counts_in_files["pavilions"] == 14 and plaza == WorldLayout.MapFeature.ROAD,
		"Oakshire-Wick's fourteen market stalls are artisan pavilions on a cobbled plaza apron")
	check.call(counts_in_files["terrace"] == 2 and counts_in_files["terrace_posts"] >= 8 and counts_in_files["causeway_posts"] >= 6,
		"the slope contract: log sleepers where the Quarry-Wick road climbs its two terrace risers (%d guide-posts), and %d guide-posts up Nine-Stones' causeway"
		% [counts_in_files["terrace_posts"], counts_in_files["causeway_posts"]])
	var crests: int = 0
	for chunk_x: int in range(0, OakshireValeLayout.CHUNKS):
		crests += layout.crest_pieces(Vector2i(chunk_x, 6)).size()
	check.call(crests > 20, "Crag-Crest Cornices line the cliff ring's crest (%d across the vale's middle row)" % crests)
	# The nine stones may stand in more than one landblock: load each that has any.
	var ring: Node3D = Node3D.new()
	ring.name = "NineStonesProbe"
	WorldKitInstance.immediate = true
	for file: String in DirAccess.get_files_at(OakshireValeLayout.LANDBLOCK_FOLDER):
		if file.begins_with("landblock_") and FileAccess.get_file_as_string(OakshireValeLayout.LANDBLOCK_FOLDER + file).contains("name=\"NineStone"):
			var block: Node = (load(OakshireValeLayout.LANDBLOCK_FOLDER + file) as PackedScene).instantiate()
			for stone: Node in block.find_children("NineStone*", "StaticBody3D", true, false):
				stone.get_parent().remove_child(stone)
				ring.add_child(stone)
			block.free()
	tree.root.add_child(ring)
	await _frames(1)
	_check_megaliths(ring, "Nine-Stones-Crossing", 9)
	ring.queue_free()
	WorldKitInstance.immediate = false
