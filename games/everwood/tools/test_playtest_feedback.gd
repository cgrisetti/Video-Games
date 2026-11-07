## Phase 12.5's checks (docs/13_PLAYTEST_KAIZEN_UPDATE_PROMPT.md), run by
## tools/smoke_test.gd after the Phase 12 Combat Kaizen's, in the Caldera Isles:
##   K1  no debug text over play; the Options menu on Esc (Audio, Video,
##       Controls, Gameplay) changing and saving settings to the smoke test's
##       own file; the Controls tab's keyboard and pad drawn from the Input
##       Map; invert Y; toggle sprint (a click keeps running until you turn
##       aside, stop or click again; off, it's held)
##   K2  the map: Embershore's Zone Map painted from its island (sea, an
##       inked shore, roads and the huts' footprints), its towns, dungeon and
##       four crossings named, a legend, the hero's turning arrow; a click on
##       a mark, a click on open ground and the pad's keys each set a
##       way-marker and its firefly trail (and a second click takes it away);
##       the World Map of all five isles, and a mark on Iron-Ness routed by
##       way of The West Strait
##   K3  the storybook sky (painterly clouds and the caldera's far ridgelines)
##       in every level's environment; natural joints over the whole clip
##       library (no elbow bends backward, no shoulder swings round behind,
##       forearms twist no more than 85 degrees) and a broken pose put right;
##       both arms swinging on the run; the greatshield clear of the shoulder,
##       head and chest; back gear past the cloak, which it straps down
##   K4  atelier foliage: sculpted oak clumps, ash, weeping willows, orchard
##       apples, tiered pines and layered ferns near a camera (light enough to
##       instance, their crowns over a hero's head), one-draw stand-ins past
##       it, willows on Oakshire's low shore; organic coasts: every elliptical
##       isle's shore wanders into bays and headlands, two or more river
##       inlets (or firths) hold the sea, and no quay, arrival, place or road
##       is moved or cut
##   K5  the Developer Tools on F1 (and Share + D-Pad ↑ on a pad): their own
##       hazard-banded panel with the old banner's lines and the test tools
##       (debug hero, end the playtest, the warp, host / join / leave), none of
##       it in the Binder or the Options menu; card tooltips that say what a
##       card does, when to use it (on the trail it gets your ink ready; in a
##       fight a tap in the flash casts it) and whether your level takes it,
##       in Gate 6's words; level and danger badges over enemies ("[Lv. 3]",
##       "[Lv. 10 Great-Boggart]", the boss's on its bar), coloured for the party's
##       level and hidden from the Options menu
extends RefCounted

## The green by the Doverslap chime-post on Embershore: flat ground to sprint on, within the post's reach (cards change there).
const GREEN: Vector3 = Vector3(745.35, 0.0, -121.64)

var tree: SceneTree
var check: Callable
var level: CalderaArchipelagoWorld


func run(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	level = tree.current_scene as CalderaArchipelagoWorld
	if level == null:
		check.call(false, "the Phase 12.5 checks run in the Caldera Isles")
		return
	if level.streamer.active_isle != CalderaAtlas.ISLE_OAKSHIRE_HOLM:
		level.travel_to(CalderaAtlas.ISLE_OAKSHIRE_HOLM, CalderaAtlas.ARRIVE_NORTH_QUAY)
		await _frames(4)
	await _check_quiet_screen()
	await _check_options_menu()
	await _check_toggle_sprint()
	await _check_zone_map()
	await _check_world_map()
	_check_sky()
	_check_natural_arms()
	_check_shield_clearance()
	await _check_strapped_cloak()
	_check_atelier_foliage()
	_check_organic_coasts()
	await _check_dev_tools()
	await _check_card_tooltips()
	await _check_enemy_badges()


# --- Helpers --------------------------------------------------------------------------

func _frames(count: int) -> void:
	for index: int in count:
		await tree.physics_frame


func _seconds(seconds: float) -> void:
	await _frames(int(ceil(seconds * 60.0)))


func _key(key: Key, pressed: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)


func _tap_key(key: Key) -> void:
	_key(key, true)
	await _frames(3)
	_key(key, false)
	await _frames(3)


func _keyboard_hero() -> ActorBase:
	for actor: ActorBase in level.party_in_order():
		if actor.is_local_player() and actor.input != null and actor.input.device_id == InputComponent.KEYBOARD_DEVICE:
			return actor
	return null


## Stands a hero on the green, idle and rested, its input its own again.
func _stand(actor: ActorBase) -> void:
	actor.input.release_script()
	var spot: Vector3 = GREEN
	level.streamer.ensure_ground_at(spot)
	spot.y = level.streamer.height_at(spot.x, spot.z) + 0.05
	actor.place_at(Transform3D(Basis.IDENTITY, spot))
	actor.stats.restore_stamina(actor.stats.stats.max_stamina)
	if not actor.state_machine.is_in(&"idle"):
		actor.state_machine.transition(&"idle")


## The names a key or pad control carries on the Controls tab's drawings.
func _names(bound: Dictionary[int, Array], slot: int) -> PackedStringArray:
	return bound[slot][0] as PackedStringArray if bound.has(slot) else PackedStringArray()


# --- K1: the quiet screen, the Options menu and toggle sprint ------------------------------

func _check_quiet_screen() -> void:
	await _frames(3)
	var hint: String = level.level_hint().get_slice("\n", 0)
	var shown: String = level.banner.text if level.banner.visible else ""
	check.call(not shown.contains(hint) and not shown.contains("F5 host") and not shown.contains("Plug in a pad") and level.debug_banner_text().contains(hint)
		and level.debug_banner_text().contains("F5 host") and hint != "",
		"K1: no debug text over play (the level's hint, keys and network line wait in the Developer Tools: \"%s\")" % hint.left(60))


func _check_options_menu() -> void:
	var settings: SettingsManager = SettingsManager.current
	var hero: ActorBase = _keyboard_hero()
	var hud: PlayerHUD = PlayerHUD.for_actor(tree, hero) if hero != null else null
	if settings == null or hud == null:
		check.call(false, "K1: the Options menu needs the Settings autoload and the keyboard hero's HUD")
		return
	check.call(settings.settings_path() != SettingsManager.SETTINGS_PATH and settings.toggle_sprint_mode and not settings.invert_y_axis
		and InputMap.has_action(InputComponent.ACTION_OPTIONS),
		"K1: the Settings autoload is up, on the smoke test's own file (%s), starting from the defaults" % settings.settings_path())
	hud.close_menu()
	await _frames(2)
	await _tap_key(KEY_ESCAPE)
	await _frames(2)
	var options: OptionsMenu = hud.options_menu()
	var tabs_ok: bool = options != null and OptionsMenu.TAB_NAMES == ["Audio", "Video", "Controls", "Gameplay"] and hero.input.menu_open
	check.call(tabs_ok, "K1: Esc opens the Options menu over the player's view, its tabs Audio, Video, Controls and Gameplay")
	if options == null:
		return
	# Music down a notch from the controller's own menu input.
	hero.input.menu_input.emit(InputComponent.MENU_DOWN)
	hero.input.menu_input.emit(InputComponent.MENU_LEFT)
	await _frames(2)
	var saved: Dictionary = SaveManager.load_json(settings.settings_path())
	var gain: float = settings.volume_db_on(&"Music")
	check.call(is_equal_approx(settings.music_volume, 0.95) and absf(gain - linear_to_db(0.95)) < 0.05 and is_equal_approx(float(saved.get("music_volume", -1.0)), 0.95)
		and is_equal_approx(settings.master_volume, 1.0),
		"K1: ↓ then ← turns the music to 95%%: the Music bus's amplifier at %.2f dB, saved to the file at once" % gain)
	options.set_tab(OptionsMenu.Tab.CONTROLS)
	await _frames(2)
	var keys: Dictionary[int, Array] = OptionsMenu.keyboard_bindings()
	var pad: Dictionary[int, Array] = OptionsMenu.pad_bindings()
	var drawn: bool = options.get_node_or_null(^"Book") != null and options.find_child("ControlsDiagram", true, false) != null \
		and (options.find_child("ControlsDiagram", true, false) as Control).visible
	check.call(drawn and _names(keys, KEY_W).has("Move") and _names(keys, KEY_SPACE).has("Jump")
		and not keys.has(KEY_F2) and _names(pad, JOY_BUTTON_A).has("Jump")
		and _names(pad, OptionsMenu.ControlsDiagram.LEFT_STICK).has("Move")
		and _names(pad, JOY_BUTTON_START).has("Options")
		and _names(keys, KEY_ESCAPE).has("Options"),
		"K1: the Controls tab draws the keyboard and the pad from the Input Map (W moves, Space and ✕ jump, Esc and Options open this menu; the debug key isn't shown)")
	# Invert Y is the Controls tab's first row; light flips it.
	hero.input.menu_input.emit(InputComponent.MENU_ACCEPT)
	await _frames(3)
	check.call(settings.invert_y_axis and hero.input.invert_pitch, "K1: Invert Y flips on from the Controls tab and the hero's camera input follows it")
	settings.set_value(&"field_of_view", 70.0)
	await tree.process_frame
	await tree.process_frame
	var view: PlayerCamera = level.camera_for_seat(hero.party_slot + 1)
	check.call(view != null and is_equal_approx(view.fov, 70.0), "K1: the cameras' field of view follows the Video tab (70°)")
	# The Options wireframe's new rows (25 GDD §2).
	settings.set_value(&"world_detail", SettingsManager.WorldDetail.NEAR)
	settings.set_value(&"grass_density", SettingsManager.GrassDensity.FEW)
	settings.set_value(&"craft_textures", SettingsManager.CraftTextures.SOFT)
	settings.set_value(&"rhyme_ribbon_size", SettingsManager.RibbonSize.LARGE)
	await tree.process_frame
	check.call(view != null and is_equal_approx(view.far, view.horizon * SettingsManager.VIEW_DISTANCE_SCALES[0])
		and is_equal_approx(SettingsManager.grass_scale(), SettingsManager.GRASS_SCALES[0])
		and is_equal_approx(tree.root.texture_mipmap_bias, SettingsManager.TEXTURE_BIASES[0])
		and SettingsManager.ribbon_font_size() == SettingsManager.RIBBON_FONT_SIZES[1]
		and OptionsMenu.ROWS[OptionsMenu.Tab.VIDEO].has(&"world_detail") and OptionsMenu.ROWS[OptionsMenu.Tab.GAMEPLAY].has(&"ink_ready_border"),
		"K1: World detail Near draws the cameras to %.0f m, Grass & flowers, Craft textures Soft and the Large rhyme ribbon all take hold" % (view.far if view != null else 0.0))
	options = hud.options_menu()
	if options != null:
		options.set_tab(OptionsMenu.Tab.GAMEPLAY)
		await _frames(2)
		var help_rows: int = 0
		for key: StringName in options.rows():
			help_rows += 1 if OptionsMenu.help_seat(key) != null else 0
		var help_seat: PartyMember = OptionsMenu.help_seat(&"help_0")
		var mode_before: int = help_seat.assist_mode if help_seat != null else -1
		options.change(&"help_0", 1)
		await _frames(3)
		var stepped: PartyMember = OptionsMenu.help_seat(&"help_0")
		var mode_after: int = stepped.assist_mode if stepped != null else -1
		options.change(&"help_0", -1)
		await _frames(3)
		check.call(help_rows == OptionsMenu.help_seats().size() and help_rows >= 1 and mode_after == wrapi(mode_before + 1, 0, InputComponent.MODE_NAMES.size()),
			"K1: the Gameplay tab sets each player's help on this screen (%d rows): P1 steps from %s to %s" % [help_rows,
			InputComponent.MODE_NAMES[maxi(mode_before, 0)], InputComponent.MODE_NAMES[maxi(mode_after, 0)]])
	await _tap_key(KEY_ESCAPE)
	await _frames(2)
	check.call(hud.options_menu() == null and not hero.input.menu_open, "K1: Esc closes it again")
	settings.reset_to_defaults()
	await _frames(2)
	check.call(not settings.invert_y_axis and is_equal_approx(settings.music_volume, 1.0) and is_equal_approx(settings.field_of_view, 62.0),
		"K1: \"Put everything back\" restores the defaults")


func _check_toggle_sprint() -> void:
	var hero: ActorBase = _keyboard_hero()
	if hero == null:
		check.call(false, "K1: toggle sprint needs the keyboard hero")
		return
	_stand(hero)
	await _frames(4)
	var input: InputComponent = hero.input
	input.inject_move(Vector2(0.0, 1.0))
	await _seconds(0.3)
	input.inject_hold(InputComponent.ACTION_SPRINT, true)
	await _frames(3)
	input.inject_hold(InputComponent.ACTION_SPRINT, false)
	await _seconds(0.5)
	var kept: bool = hero.sprinting and hero.sprint_latched
	input.inject_move(Vector2(1.0, 0.0))
	await _frames(4)
	var turned_aside: bool = not hero.sprinting and not hero.sprint_latched
	input.inject_move(Vector2(0.0, 1.0))
	input.inject_hold(InputComponent.ACTION_SPRINT, true)
	await _frames(3)
	input.inject_hold(InputComponent.ACTION_SPRINT, false)
	await _seconds(0.2)
	var again: bool = hero.sprinting
	input.inject_hold(InputComponent.ACTION_SPRINT, true)
	await _frames(3)
	input.inject_hold(InputComponent.ACTION_SPRINT, false)
	await _frames(3)
	var clicked_off: bool = not hero.sprinting and not hero.sprint_latched
	input.inject_hold(InputComponent.ACTION_SPRINT, true)
	await _frames(3)
	input.inject_hold(InputComponent.ACTION_SPRINT, false)
	input.inject_move(Vector2.ZERO)
	await _seconds(0.5)
	var stopped: bool = not hero.sprint_latched
	check.call(kept and turned_aside and again and clicked_off and stopped,
		"K1: Toggle Sprint: one click of sprint keeps the hero running after it's let go, until they steer sideways, click again or stand still")
	SettingsManager.current.set_value(&"toggle_sprint_mode", false)
	input.inject_move(Vector2(0.0, 1.0))
	input.inject_hold(InputComponent.ACTION_SPRINT, true)
	await _seconds(0.3)
	var held: bool = hero.sprinting
	input.inject_hold(InputComponent.ACTION_SPRINT, false)
	await _frames(3)
	check.call(held and not hero.sprinting and not hero.sprint_latched, "K1: with Toggle Sprint off, sprint lasts only while it's held")
	SettingsManager.current.set_value(&"toggle_sprint_mode", true)
	input.inject_move(Vector2.ZERO)
	await _frames(2)
	input.release_script()


# --- K2: the map and its way-markers --------------------------------------------------------

## Opens the map over the keyboard hero's view and waits for its picture.
func _open_map(hud: PlayerHUD) -> WorldMapPanel:
	hud.close_menu()
	await _frames(2)
	hud.open_atlas()
	var panel: WorldMapPanel = hud.map_panel()
	for wait: int in 240:
		if panel == null or panel.map != null:
			break
		await _seconds(0.1)
	await tree.process_frame
	await tree.process_frame
	return panel


func _node_named(panel: WorldMapPanel, label: String) -> Dictionary:
	for node: Dictionary in panel.nodes:
		if String(node["label"]) == label:
			return node
	return {}


## A left click at a point of the panel, straight to its handler.
func _click(panel: WorldMapPanel, at: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = at
	panel._gui_input(event)


func _check_zone_map() -> void:
	var hero: ActorBase = _keyboard_hero()
	var hud: PlayerHUD = PlayerHUD.for_actor(tree, hero) if hero != null else null
	if hud == null:
		check.call(false, "K2: the map needs the keyboard hero's HUD")
		return
	# The quests come from the world's flags: start them where a new party starts.
	CalderaWorldState.current.reset_for_testing()
	_stand(hero)
	await _frames(3)
	CartographyBaker.clear_cache()
	var panel: WorldMapPanel = await _open_map(hud)
	if panel == null or panel.map == null:
		check.call(false, "K2: the map opens and its Zone Map is painted")
		return
	var half: Vector2 = CalderaAtlas.isle(CalderaAtlas.ISLE_EMBERSHORE).half_size()
	var inks: Dictionary[String, int] = _inks(panel.map.get_image())
	var title: String = CartographyBaker.map_title(level, panel.scope, Vector2(hero.global_position.x, hero.global_position.z))
	check.call(CartographyBaker.world_rect(panel.map) == Rect2(-half, half * 2.0) and inks["water"] > 200 and inks["shore"] > 50
		and inks["road"] > 30 and inks["footprint"] > 4 and title.begins_with("Embershore · Lv 1–6 · "),
		"K2: the Zone Map is Embershore itself (2,048 x 1,024 m), painted from its island: the sea and its inked shore, the roads and the huts (%s); the header reads \"%s\""
		% [inks, title])
	var market: Dictionary = _node_named(panel, "Hearthstead")
	var sanctum: Dictionary = _node_named(panel, "The Root-Sanctum")
	var crossings: Array[Dictionary] = panel.nodes_of(CartographyBaker.NodeKind.CROSSING)
	var quests: Array[Dictionary] = panel.nodes_of(CartographyBaker.NodeKind.QUEST)
	var goal: String = String(quests[0]["label"]) if not quests.is_empty() else "none"
	check.call(not market.is_empty() and int(market["kind"]) == CartographyBaker.NodeKind.TOWN and not sanctum.is_empty()
		and int(sanctum["kind"]) == CartographyBaker.NodeKind.DUNGEON and crossings.size() == 4 and not quests.is_empty(),
		"K2: towns, dungeons, crossings and quests are named on it: Hearthstead (a town), The Root-Sanctum (a dungeon), the four crossings (%s) and the quest \"%s\""
		% [", ".join(crossings.map(func(node: Dictionary) -> String: return String(node["label"]))), goal])
	var up: PackedVector2Array = WorldMapPanel.arrow_points(Vector2.ZERO, 0.0, 10.0)
	var left: PackedVector2Array = WorldMapPanel.arrow_points(Vector2.ZERO, PI * 0.5, 10.0)
	check.call(up[0].y < -9.0 and absf(up[0].x) < 0.01 and left[0].x < -9.0 and absf(left[0].y) < 0.01 and panel.get_rect().size.x > 0.0
		and panel._map_rect.size.x > 0.0,
		"K2: the hero's arrow turns with them: facing north it points up the map, turned left it points left; the legend lists every kind of mark shown")
	# A click on a mark sets the way-marker there (a town well away from the hero, so the trail doesn't arrive at once).
	var far: Dictionary = {}
	for node: Dictionary in panel.nodes_of(CartographyBaker.NodeKind.TOWN) + panel.nodes_of(CartographyBaker.NodeKind.DUNGEON):
		if far.is_empty() or (node["local"] as Vector2).distance_to(Vector2(hero.global_position.x, hero.global_position.z)) \
				> (far["local"] as Vector2).distance_to(Vector2(hero.global_position.x, hero.global_position.z)):
			far = node
	_click(panel, panel.to_panel(far["at"]))
	await _frames(3)
	var trail: bool = is_instance_valid(hud.trail_guide) and (hud.pinned_target_xz - (far["local"] as Vector2)).length() < 0.5
	check.call(hud.has_waymarker() and String(hud.waymarker["label"]) == String(far["label"]) and trail,
		"K2: a click on %s sets the way-marker there and a firefly trail leads to it" % String(far["label"]))
	_click(panel, panel.to_panel(far["at"]))
	await _frames(2)
	var cleared: bool = not hud.has_waymarker() and not is_instance_valid(hud.trail_guide)
	var ground: Vector2 = panel._map_rect.position + panel._map_rect.size * Vector2(0.62, 0.55)
	if panel.node_at(ground) >= 0:
		ground += Vector2(23.0, 17.0)
	_click(panel, ground)
	await _frames(2)
	var spot: Vector2 = panel.from_panel(ground)
	check.call(cleared and hud.has_waymarker() and String(hud.waymarker["label"]) == "Marked spot" and (hud.pinned_target_xz - spot).length() < 1.0,
		"K2: clicking the mark again takes the way-marker away; a click on open ground marks that very spot")
	# The pad: move to the next mark and press light.
	panel.selected = panel.nodes.find(sanctum)
	panel.handle_menu(InputComponent.MENU_ACCEPT)
	await _frames(2)
	var by_pad: bool = String(hud.waymarker.get("label", "")) == "The Root-Sanctum"
	var before: int = panel.selected
	panel.handle_menu(InputComponent.MENU_RIGHT)
	check.call(by_pad and panel.selected != before and panel.selected >= 0,
		"K2: on a pad, light marks the chosen mark (The Root-Sanctum), and the D-Pad moves to the next mark over")
	hud.clear_waymarker()


func _check_world_map() -> void:
	var hero: ActorBase = _keyboard_hero()
	var hud: PlayerHUD = PlayerHUD.for_actor(tree, hero) if hero != null else null
	var panel: WorldMapPanel = hud.map_panel() if hud != null else null
	if panel == null:
		check.call(false, "K2: the World Map needs the open map")
		return
	panel.handle_menu(InputComponent.MENU_ALT)
	for wait: int in 400:
		if panel.map != null:
			break
		await _seconds(0.1)
	await tree.process_frame
	await tree.process_frame
	var isles: Array[Dictionary] = panel.nodes_of(CartographyBaker.NodeKind.ISLE)
	var towns: Array[Dictionary] = panel.nodes_of(CartographyBaker.NodeKind.TOWN)
	var whole: Rect2 = CartographyBaker.world_rect(panel.map) if panel.map != null else Rect2()
	var holds_all: bool = whole.size.x > 3000.0
	for isle: IslandGridResource in CalderaAtlas.isles():
		holds_all = holds_all and whole.has_point(isle.sound_position)
	check.call(panel.scope == CartographyBaker.MapScope.WORLD and isles.size() == 5 and towns.size() >= 5 and holds_all
		and CartographyBaker.map_title(level, panel.scope, Vector2.ZERO).begins_with("The Caldera Isles"),
		"K2: heavy turns to the World Map: all five isles in The Sound with their towns (%d), the header naming the Caldera" % towns.size())
	var forge: Dictionary = {}
	for node: Dictionary in towns:
		if node.get("isle", &"") == CalderaAtlas.ISLE_IRON_NESS:
			forge = node
	panel.selected = panel.nodes.find(forge)
	panel.mark_selected()
	await _frames(3)
	var strait: Vector3 = CalderaAtlas.seam(CalderaAtlas.SEAM_WEST_STRAIT).anchor(CalderaAtlas.ISLE_OAKSHIRE_HOLM)
	check.call(not forge.is_empty() and hud.has_waymarker() and hud.waymarker.get("isle", &"") == CalderaAtlas.ISLE_IRON_NESS
		and String(hud.waymarker.get("via", "")) == "The West Strait" and (hud.pinned_target_xz - Vector2(strait.x, strait.z)).length() < 0.5,
		"K2: a way-marker on Iron-Ness's %s leads first to The West Strait, the crossing that heads there" % String(forge.get("label", "town")))
	hud.clear_waymarker()
	hud.toggle_options()
	await _frames(2)
	check.call(hud.map_panel() == null and not hero.input.menu_open, "K2: Esc (the Options button) closes the map")


## How many of a map's pixels are each of its inks.
func _inks(image: Image) -> Dictionary[String, int]:
	var counts: Dictionary[String, int] = {"water": 0, "shore": 0, "road": 0, "footprint": 0}
	var inks: Dictionary[String, Color] = {"road": CartographyBaker.ROAD, "footprint": CartographyBaker.FOOTPRINT, "shore": CartographyBaker.SHORE_INK}
	for y: int in range(0, image.get_height(), 1):
		for x: int in range(0, image.get_width(), 1):
			var pixel: Color = image.get_pixel(x, y)
			var named: bool = false
			for ink: String in inks:
				if absf(pixel.r - inks[ink].r) < 0.02 and absf(pixel.g - inks[ink].g) < 0.02 and absf(pixel.b - inks[ink].b) < 0.02:
					counts[ink] += 1
					named = true
			if not named and pixel.b > pixel.r + 0.12 and pixel.b > 0.35:
				counts["water"] += 1
	return counts


# --- K3: the sky, natural arms, the shield and the back --------------------------------------

const B = HeroRigBuilder.Bone


func _check_sky() -> void:
	var environment: Environment = null
	for found: Node in level.find_children("*", "WorldEnvironment", true, false):
		environment = (found as WorldEnvironment).environment
	var uniforms: Array[String] = []
	for uniform: Dictionary in StorybookSky.SHADER.get_shader_uniform_list():
		uniforms.append(String(uniform["name"]))
	var eased: bool = false
	if StorybookSky.is_installed(environment):
		var top: Variant = (environment.sky.sky_material as ShaderMaterial).get_shader_parameter(&"sky_top_color")
		eased = top is Color
	check.call(StorybookSky.is_installed(environment) and eased and uniforms.has("cloud_cover") and uniforms.has("ridge_height")
		and uniforms.has("cirrus_amount") and uniforms.has("sky_top_color") and environment.sky.radiance_size == StorybookSky.RADIANCE_SIZE,
		"K3: the Caldera's sky is the storybook sky: painterly cumulus and cirrus at half resolution, the caldera's far ridgelines in three hazy layers, its colours eased by the atmosphere (%d uniforms)" % uniforms.size())


## A clip's pose at a frame as the rig's arrays (rotations, positions).
func _pose_arrays(clip: StringName, frame: float) -> Array:
	var pose: Dictionary = HeroCombatAnimator.sample_pose(clip, frame)
	var rot: Array[Quaternion] = []
	rot.assign(pose["rotations"])
	var pos: Array[Vector3] = []
	for rest: Transform3D in HeroRigBuilder.local_rests():
		pos.append(rest.origin)
	return [rot, pos]


## The arms' worst after the natural joints: (backward reach share, backward elbow share, forearm twist degrees).
func _arm_worst(rot: Array[Quaternion], pos: Array[Vector3]) -> Vector3:
	var globals: Array[Transform3D] = StorybookKinematicsModifier3D._globals(rot, pos)
	var chest: Basis = globals[B.CHEST].basis.orthonormalized()
	var worst: Vector3 = Vector3(-INF, -INF, -INF)
	for side: Array in [[B.UPPER_ARM_L, B.FOREARM_L, B.HAND_L], [B.UPPER_ARM_R, B.FOREARM_R, B.HAND_R]]:
		var upper: Basis = globals[int(side[0])].basis.orthonormalized()
		var fore: Basis = globals[int(side[1])].basis.orthonormalized()
		var arm: Vector3 = upper.y.normalized()
		var forearm: Vector3 = fore.y.normalized()
		var bend: float = rad_to_deg(acos(clampf(arm.dot(forearm), -1.0, 1.0)))
		var local: Vector3 = upper.inverse() * forearm
		var backward_elbow: float = -local.z / maxf(sin(deg_to_rad(bend)), 0.001) if bend > 27.0 else 0.0
		var carried: Vector3 = Basis(HeroPoseBaker.arc(arm, forearm)) * upper.z
		var reference: Vector3 = (carried - forearm * forearm.dot(carried)).normalized()
		var facing: Vector3 = (fore.z - forearm * forearm.dot(fore.z)).normalized()
		var twist: float = absf(rad_to_deg(reference.signed_angle_to(facing, forearm)))
		var reach: float = arm.dot(chest.z.normalized()) - lerpf(StorybookKinematicsModifier3D.SHOULDER_BACK_REACH_DOWN,
			StorybookKinematicsModifier3D.SHOULDER_BACK_REACH_UP, clampf((arm.dot(chest.y.normalized()) + 1.0) * 0.5, 0.0, 1.0))
		worst = worst.max(Vector3(reach, backward_elbow, twist))
	return worst


func _check_natural_arms() -> void:
	var worst: Vector3 = Vector3(-INF, -INF, -INF)
	var before_elbow: float = -INF
	var worst_clip: String = ""
	var frames_seen: int = 0
	for clip: StringName in HeroCombatAnimator.clip_names():
		var frames: int = int(HeroCombatAnimator.clip_info(clip).get("frames", 30))
		for frame: int in range(0, frames + 1, 3):
			var arrays: Array = _pose_arrays(clip, float(frame))
			var rot: Array[Quaternion] = arrays[0]
			var pos: Array[Vector3] = arrays[1]
			before_elbow = maxf(before_elbow, _arm_worst(rot, pos).y)
			StorybookKinematicsModifier3D.limit_arms(rot, pos)
			var after: Vector3 = _arm_worst(rot, pos)
			if after.y > worst.y:
				worst_clip = String(clip)
			worst = worst.max(after)
			frames_seen += 1
	check.call(worst.x <= 0.01 and worst.y <= 0.02 and worst.z <= StorybookKinematicsModifier3D.FOREARM_TWIST_MAX_DEG + 1.0 and before_elbow > 0.5,
		"K3: natural joints over all %d frames of the clip library: no elbow bends backward (it did, by up to %.0f%%; now %.2f), no shoulder reaches round behind (%.2f past its reach), forearms twist at most %.0f°"
		% [frames_seen, before_elbow * 100.0, worst.y, worst.x, worst.z])
	# A broken pose: the right arm flung up and round behind the head, the elbow snapped the wrong way.
	var arrays: Array = _pose_arrays(&"idle_combat_ready", 0.0)
	var rot: Array[Quaternion] = arrays[0]
	var pos: Array[Vector3] = arrays[1]
	rot[B.UPPER_ARM_R] = Quaternion(Vector3.RIGHT, deg_to_rad(-200.0)) * rot[B.UPPER_ARM_R]
	rot[B.FOREARM_R] = Quaternion(Vector3.RIGHT, deg_to_rad(-120.0)) * rot[B.FOREARM_R]
	var broken: Vector3 = _arm_worst(rot, pos)
	var held: int = StorybookKinematicsModifier3D.limit_arms(rot, pos)
	var fixed: Vector3 = _arm_worst(rot, pos)
	check.call(held > 0 and (broken.x > 0.05 or broken.y > 0.1) and fixed.x <= 0.01 and fixed.y <= 0.02,
		"K3: an arm flung round behind the head with its elbow snapped backward is put right (%d joints held: reach %.2f -> %.2f, elbow %.2f -> %.2f)"
		% [held, broken.x, fixed.x, broken.y, fixed.y])
	# The run: both arms swing, the weapon arm opposite the off arm.
	var frame_4: Array = _pose_arrays(&"locomotion_run_cycle", 4.0)
	var frame_18: Array = _pose_arrays(&"locomotion_run_cycle", 18.0)
	StorybookKinematicsModifier3D.limit_arms(frame_4[0], frame_4[1])
	StorybookKinematicsModifier3D.limit_arms(frame_18[0], frame_18[1])
	var at_4: Array[Transform3D] = StorybookKinematicsModifier3D._globals(frame_4[0], frame_4[1])
	var at_18: Array[Transform3D] = StorybookKinematicsModifier3D._globals(frame_18[0], frame_18[1])
	var right_4: float = at_4[B.UPPER_ARM_R].basis.y.normalized().z
	var right_18: float = at_18[B.UPPER_ARM_R].basis.y.normalized().z
	var left_4: float = at_4[B.UPPER_ARM_L].basis.y.normalized().z
	var left_18: float = at_18[B.UPPER_ARM_L].basis.y.normalized().z
	check.call(right_4 < -0.2 and right_18 > 0.2 and left_4 > 0.2 and left_18 < -0.2,
		"K3: running, both arms swing: the weapon arm forward as the off arm goes back (frame 4: %.2f / %.2f), then the other way (frame 18: %.2f / %.2f)"
		% [right_4, left_4, right_18, left_18])


func _check_shield_clearance() -> void:
	var shield: Node3D = HeroMeshAtelier.build_greatshield(StandardMaterial3D.new())
	var box: AABB = _aabb(shield, Transform3D.IDENTITY)
	shield.free()
	var shoulder_min: float = INF
	var head_min: float = INF
	var chest_in: float = 0.0
	for clip: StringName in [&"idle_combat_ready", &"idle_steward_calm", &"guard_hold", &"perfect_guard_parry", &"locomotion_run_cycle",
			&"falchion_light_1", &"falchion_light_2", &"falchion_light_3", &"falchion_heavy_advancing_thrust", &"falchion_flourish_r_timber_cross",
			&"falchion_ult_lr_bramble_whirl", &"dodge_roll_evade", &"shadow_sanctuary_brace", &"stagger_reel"]:
		var frames: int = int(HeroCombatAnimator.clip_info(clip).get("frames", 30))
		for frame: int in range(0, frames + 1, 3):
			var arrays: Array = _pose_arrays(clip, float(frame))
			StorybookKinematicsModifier3D.limit_arms(arrays[0], arrays[1])
			var globals: Array[Transform3D] = StorybookKinematicsModifier3D._globals(arrays[0], arrays[1])
			var hand: Transform3D = globals[B.HAND_L] * ActorVisuals.SHIELD_ON_FOREARM
			for index: int in 8:
				var at: Vector3 = hand * box.get_endpoint(index)
				shoulder_min = minf(shoulder_min, at.distance_to(globals[B.UPPER_ARM_L].origin))
				head_min = minf(head_min, at.distance_to(globals[B.HEAD].origin + Vector3(0.0, 0.12, 0.0)))
				chest_in = maxf(chest_in, 0.17 - at.distance_to(Geometry3D.get_closest_point_to_segment(at, globals[B.SPINE].origin, globals[B.NECK].origin)))
	check.call(shoulder_min >= 0.22 and head_min >= 0.06 and chest_in <= 0.0,
		"K3: the greatshield, strapped across the forearm, stays clear of the shoulder (%.2f m), the head (%.2f m) and the chest in every guard, swing, run and roll"
		% [shoulder_min, head_min])


func _check_strapped_cloak() -> void:
	var hero: ActorBase = _keyboard_hero()
	# A bow stays in hand out of a fight: measure on a Bridge-Warden's sword (the Debug Switch's first step), then end the playtest.
	var switched: bool = hero != null and hero.loadout.weapon != null and hero.loadout.weapon.weapon_type == EquipmentItemResource.WeaponType.BOW
	if switched:
		PlaytestSwitcher.reset()
		PlaytestSwitcher.step_hero(level, InputComponent.KEYBOARD_DEVICE, 1)
		await _frames(6)
		hero = _keyboard_hero()
	if hero == null or hero.visuals == null or not hero.visuals.has_rig():
		check.call(false, "K3: the strapped cloak needs the keyboard hero's rig")
		return
	_stand(hero)
	await _frames(3)
	# Out of a fight a while: the weapon goes on the back (a bow stays in hand).
	hero.visuals.animator._since_fight = HeroCombatAnimator.CALM_AFTER + 1.0
	await _frames(3)
	hero.input.inject_move(Vector2(0.0, 1.0))
	await _seconds(1.2)
	var kinematics: StorybookKinematicsModifier3D = hero.visuals.kinematics
	var strapped: bool = kinematics.back_strapped and hero.visuals.is_weapon_stowed()
	var top: float = minf(kinematics.cloak_pitch[0], kinematics.cloak_pitch[1])
	var hem: float = kinematics.cloak_pitch[2]
	var mount: Node3D = hero.visuals._weapon_mount
	var depth: float = mount.position.z if mount != null else 0.0
	hero.input.inject_move(Vector2.ZERO)
	await _frames(2)
	hero.input.release_script()
	var animator: HeroCombatAnimator = hero.visuals.animator
	if switched:
		PartyProgress.current.end_playtest()
		PlaytestSwitcher.reset()
		if CalderaWorldState.current != null:
			CalderaWorldState.current.playtest = false
	check.call(strapped and top >= -StorybookKinematicsModifier3D.STRAPPED_FLARE_MAX - 0.02 and depth >= ActorVisuals.BACK_GEAR_DEPTH - 0.001 and hem < top,
		"K3: a weapon on the back rides %.2f m out, past the cloak, and straps its top down while running (its top flares %.2f rad at most, its hem %.2f)%s"
		% [depth, -top, -hem, "" if strapped else " [not stowed: calm %s, %.1f s out of a fight, weapon %s, state %s, action %s, in combat %s]" % [animator.calm,
			animator._since_fight, hero.loadout.weapon.weapon_type if hero.loadout.weapon != null else -1, hero.state_machine.current_name(),
			hero.current_action(), hero.sign_flow.is_in_combat if hero.sign_flow != null else false]])


func _aabb(node: Node, where: Transform3D) -> AABB:
	var box: AABB = AABB()
	var started: bool = false
	var here: Transform3D = where * ((node as Node3D).transform if node is Node3D else Transform3D.IDENTITY)
	var mesh: MeshInstance3D = node as MeshInstance3D
	if mesh != null and mesh.mesh != null:
		box = here * mesh.mesh.get_aabb()
		started = true
	for child: Node in node.get_children():
		var inner: AABB = _aabb(child, here)
		if inner.size != Vector3.ZERO:
			box = inner if not started else box.merge(inner)
			started = true
	return box


# --- K4: atelier foliage and organic coasts -------------------------------------------

## A tree's triangle budget (it is instanced by the hundred) and a fern's.
const TREE_TRIANGLES: int = 3200
const FERN_TRIANGLES: int = 400
## A crown's lowest leaves hang above a hero's head.
const CROWN_CLEARANCE: float = 2.4


func _triangles(mesh: ArrayMesh) -> int:
	var total: int = 0
	for surface: int in mesh.get_surface_count():
		total += (mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return total


func _check_atelier_foliage() -> void:
	var trees: Array[int] = [IslandBuilder.Species.OAK_TREE, IslandBuilder.Species.ASH_TREE, IslandBuilder.Species.WILLOW_TREE,
		IslandBuilder.Species.ORCHARD_TREE, IslandBuilder.Species.PINE_TREE, IslandBuilder.Species.SNOW_PINE]
	var problems: PackedStringArray = PackedStringArray()
	var heaviest: int = 0
	var lowest_crown: float = INF
	for species: int in trees:
		var label: String = IslandBuilder.Species.keys()[species]
		var mesh: ArrayMesh = CalderaKit.atelier_mesh(species)
		if mesh == null or mesh.get_surface_count() < 2:
			problems.append("%s has no sculpted trunk and crown" % label)
			continue
		heaviest = maxi(heaviest, _triangles(mesh))
		# Its leaves: the swaying foliage surfaces (not the bark).
		for surface: int in mesh.get_surface_count():
			var material: ShaderMaterial = mesh.surface_get_material(surface) as ShaderMaterial
			if material == null or material.shader != WorldVisualCatalog.FOLIAGE_SHADER:
				continue
			var low: float = INF
			for point: Vector3 in mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX] as PackedVector3Array:
				low = minf(low, point.y)
			# Ferns at an oak's foot don't count as its crown.
			if low > 1.5:
				lowest_crown = minf(lowest_crown, low)
			elif species != IslandBuilder.Species.OAK_TREE:
				problems.append("%s's leaves hang to %.1f m" % [label, low])
	var fern: ArrayMesh = CalderaKit.atelier_mesh(IslandBuilder.Species.FERN_TUFT)
	if fern == null or _triangles(fern) > FERN_TRIANGLES or fern.get_aabb().size.y > 1.2:
		problems.append("the layered fern is missing or too big")
	if CalderaKit.atelier_mesh(IslandBuilder.Species.ROCK) != null:
		problems.append("stones have an atelier mesh")
	# Live: the loaded island shows atelier meshes near and stand-ins far, from the same spots.
	var near_far: int = 0
	var mismatched: int = 0
	var willows: int = 0
	for record: ArchipelagoStreamer.LoadedChunk in level.streamer.chunks.values():
		if record.root == null:
			continue
		willows += (record.scatter.get(IslandBuilder.Species.WILLOW_TREE, []) as Array).size()
		for species: int in trees:
			var near: MultiMeshInstance3D = record.root.get_node_or_null("Atelier_%d" % species) as MultiMeshInstance3D
			var far: MultiMeshInstance3D = record.root.get_node_or_null("Scatter_%d" % species) as MultiMeshInstance3D
			if near == null and far == null:
				continue
			if near == null or far == null or near.multimesh.instance_count != far.multimesh.instance_count or near.material_override != null \
					or not is_equal_approx(near.visibility_range_end, CalderaKit.ATELIER_RANGE) \
					or not is_equal_approx(far.visibility_range_begin, CalderaKit.ATELIER_RANGE):
				mismatched += 1
			else:
				near_far += 1
	if mismatched > 0:
		problems.append("%d landblock species without a matching near and far pair" % mismatched)
	if willows == 0:
		problems.append("no weeping willows on Embershore")
	check.call(problems.is_empty() and near_far > 0 and heaviest <= TREE_TRIANGLES and lowest_crown >= CROWN_CLEARANCE,
		"K4: oak clumps, ash, weeping willows (%d on Embershore), orchard apples and tiered pines are sculpted (at most %d triangles, crowns from %.1f m up), with layered ferns; %d landblock stands swap to one-draw stand-ins past %.0f m%s"
		% [willows, heaviest, lowest_crown, near_far, CalderaKit.ATELIER_RANGE, "" if problems.is_empty() else ": " + "; ".join(problems)])


func _check_organic_coasts() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var summary: PackedStringArray = PackedStringArray()
	# Embershore's coast is its heightmap's own (docs/27), so only the three procedural outer isles grow an organic coast.
	for isle_id: StringName in [CalderaAtlas.ISLE_IRON_NESS, CalderaAtlas.ISLE_BARROW_EYOT, CalderaAtlas.ISLE_RIME_FIRTH]:
		var builder: IslandBuilder = CalderaAtlas.builder_for(isle_id)
		var shape: Dictionary = builder._coast_shape()
		if not builder.has_organic_coast() or shape.is_empty():
			problems.append("%s keeps its plain ellipse" % isle_id)
			continue
		var center: Vector2 = shape["center"]
		var semi: Vector2 = shape["semi"]
		# The shore's reach along 90 rays, as a share of the plain ellipse's.
		var shares: PackedFloat32Array = PackedFloat32Array()
		for ray: int in 90:
			var angle: float = TAU * float(ray) / 90.0
			var share: float = 0.5
			while share < 1.5 and builder.height_at(center.x + cos(angle) * semi.x * share, center.y + sin(angle) * semi.y * share) >= 0.0:
				share += 0.005
			shares.append(share)
		var mean: float = 0.0
		for share: float in shares:
			mean += share / shares.size()
		var spread: float = 0.0
		for share: float in shares:
			spread += (share - mean) * (share - mean) / shares.size()
		spread = sqrt(spread)
		var lowest: float = Array(shares).min()
		var highest: float = Array(shares).max()
		if spread < 0.03 or highest - lowest < 0.12:
			problems.append("%s's shore barely wanders (spread %.3f)" % [isle_id, spread])
		# Its inlets hold the sea from mouth to head, clear of every road.
		var inlets: Array[PackedVector2Array] = builder.inlet_lines()
		if inlets.size() < IslandBuilder.INLET_MIN:
			problems.append("%s has %d inlets" % [isle_id, inlets.size()])
		for line: PackedVector2Array in inlets:
			var mouth: Vector2 = line[1]
			var head: Vector2 = line[line.size() - 1]
			if builder.height_at(mouth.x, mouth.y) > -1.0 or builder.height_at(head.x, head.y) > 0.0:
				problems.append("%s's inlet at %s runs dry" % [isle_id, mouth])
			var index: int = 0
			while index < builder._paths.size():
				var a: Vector2 = Vector2(builder._paths[index], builder._paths[index + 1])
				var b: Vector2 = Vector2(builder._paths[index + 2], builder._paths[index + 3])
				for step: int in 11:
					var on_road: Vector2 = a.lerp(b, float(step) / 10.0)
					for point: int in line.size() - 1:
						if on_road.distance_to(Geometry2D.get_closest_point_to_segment(on_road, line[point], line[point + 1])) < IslandBuilder.INLET_MOUTH_HALF + 4.0:
							problems.append("%s's inlet cuts a road at %s" % [isle_id, on_road])
				index += 5
		# Quays, arrivals and named places keep the plain shore.
		for at: Vector3 in builder.arrivals.values():
			if builder.coast_kept(at.x, at.z) < 0.99:
				problems.append("%s's arrival at %s is reshaped" % [isle_id, at])
		summary.append("%s %d inlets, shore %.2f to %.2f" % [builder.isle.display_name, inlets.size(), lowest, highest])
	check.call(problems.is_empty(), "K4: organic coasts: %s; quays, arrivals and roads untouched%s"
		% [", ".join(summary), "" if problems.is_empty() else " (" + "; ".join(problems.slice(0, 6)) + ")"])


# --- K5: the Developer Tools, card tooltips and enemy badges ----------------------------

const KAIZEN: GDScript = preload("res://tools/test_phase12_kaizen.gd")
## Words that belong to the Developer Tools and never to a player's menu.
const DEV_WORDS: Array[String] = ["F1", "F2", "F5", "F6", "F7", "F9", "Debug", "DEBUG", "Developer", "Playtest", "playtest"]


func _texts(node: Node) -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	for label: Node in node.find_children("*", "Label", true, false):
		found.append((label as Label).text)
	return found


func _pad_button(pad: int, button: JoyButton, pressed: bool) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.device = pad
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)


func _hud_of(actor: ActorBase) -> PlayerHUD:
	return level.huds.get(actor.player_id) as PlayerHUD if actor != null else null


func _check_dev_tools() -> void:
	var hero: ActorBase = _keyboard_hero()
	_stand(hero)
	await _frames(3)
	var hud: PlayerHUD = _hud_of(hero)
	await _tap_key(KEY_F1)
	await _frames(2)
	var tools: DevAdminPanel = hud.dev_tools_panel() if hud != null else null
	if tools == null:
		check.call(false, "K5: F1 opens the Developer Tools")
		return
	var offered: Array[int] = tools.tools()
	var shown: String = "\n".join(_texts(tools))
	var banner_kept: bool = level.debug_banner_text() != "" and tools.info_text().contains(level.debug_banner_text())
	check.call(hero.input.menu_open and shown.contains(DevAdminPanel.TITLE) and shown.contains("not part of your hero's gear") and banner_kept
		and offered.has(DevAdminPanel.Tool.DEBUG_NEXT) and offered.has(DevAdminPanel.Tool.WARP) and offered.has(DevAdminPanel.Tool.HOST)
		and not offered.has(DevAdminPanel.Tool.END_PLAYTEST),
		"K5: F1 opens the Developer Tools, a hazard-banded workbench of their own (\"%s\"): the old banner's lines, the debug hero switch, the Caldera warp, host / join / leave"
		% DevAdminPanel.SUBTITLE.get_slice(":", 0))
	# The debug hero switch from the panel, then ending the playtest from it.
	tools.row = offered.find(DevAdminPanel.Tool.DEBUG_NEXT)
	tools.handle_menu(InputComponent.MENU_ACCEPT)
	await _frames(6)
	var switched: bool = PartyProgress.current.playtest
	hero = _keyboard_hero()
	hud = _hud_of(hero)
	if hud.dev_tools_panel() == null:
		hud.open_dev_tools()
		await _frames(2)
	tools = hud.dev_tools_panel()
	var can_end: bool = tools != null and tools.tools().has(DevAdminPanel.Tool.END_PLAYTEST)
	if tools != null:
		tools.use(DevAdminPanel.Tool.END_PLAYTEST)
	await _frames(2)
	var ended: bool = not PartyProgress.current.playtest and not CalderaWorldState.current.playtest
	await _tap_key(KEY_F1)
	await _frames(2)
	check.call(switched and can_end and ended and hud.dev_tools_panel() == null and not hero.input.menu_open,
		"K5: from the panel the debug hero switch starts a playtest, \"End the playtest\" ends it, and F1 closes the tools")
	# Neither the Binder nor the Options menu carries a test tool.
	hud.close_menu()
	await _frames(2)
	hud.open_binder()
	await _frames(3)
	var binder: GrimoireBinderPanel = hud.binder_panel()
	var had_binder: bool = binder != null
	var leaks: PackedStringArray = PackedStringArray()
	if binder != null:
		for tab: int in [GrimoireBinderPanel.Tab.GEAR, GrimoireBinderPanel.Tab.CARDS, GrimoireBinderPanel.Tab.COMBOS]:
			binder.show_tab(tab)
			await _frames(2)
			for text: String in _texts(binder):
				for word: String in DEV_WORDS:
					if text.contains(word):
						leaks.append("Binder: " + text.get_slice("\n", 0))
		hud.close_menu()
		await _frames(2)
	hud.open_options()
	await _frames(2)
	var options: OptionsMenu = hud.options_menu()
	var had_options: bool = options != null
	if options != null:
		for tab: int in OptionsMenu.TAB_NAMES.size():
			options.set_tab(tab)
			await _frames(1)
			for text: String in _texts(options):
				for word: String in DEV_WORDS:
					if text.contains(word):
						leaks.append("Options: " + text.get_slice("\n", 0))
		options.close()
		await _frames(2)
	# A pad opens them with Share held and D-Pad ↑, and the chord spends the Share press.
	var pad_ok: bool = true
	var pad_hero: ActorBase = null
	for actor: ActorBase in level.party_in_order():
		if actor.is_local_player() and actor.input != null and actor.input.device_id != InputComponent.KEYBOARD_DEVICE:
			pad_hero = actor
	if pad_hero != null:
		var pad: int = pad_hero.input.device_id - 1
		_pad_button(pad, JOY_BUTTON_BACK, true)
		await _frames(3)
		_pad_button(pad, JOY_BUTTON_DPAD_UP, true)
		await _frames(3)
		_pad_button(pad, JOY_BUTTON_DPAD_UP, false)
		_pad_button(pad, JOY_BUTTON_BACK, false)
		await _frames(4)
		var pad_hud: PlayerHUD = _hud_of(pad_hero)
		pad_ok = pad_hud != null and pad_hud.dev_tools_panel() != null and pad_hud.binder_panel() == null
		if pad_hud != null:
			pad_hud.close_menu()
		await _frames(2)
	check.call(had_binder and had_options and leaks.is_empty() and pad_ok,
		"K5: the Binder (gear, cards, combos) and the Options menu show no test tool or key; %s%s%s"
		% ["a pad opens the tools with Share + D-Pad ↑, no Binder" if pad_hero != null else "no pad seated for the chord", "" if leaks.is_empty() else " (" + ", ".join(leaks.slice(0, 4)) + ")",
			"" if had_binder and had_options and pad_ok else " [binder %s, options %s, pad %s]" % [had_binder, had_options, pad_ok]])


func _check_card_tooltips() -> void:
	var hero: ActorBase = _keyboard_hero()
	var hud: PlayerHUD = _hud_of(hero)
	_stand(hero)
	await _frames(2)
	await _tap_key(KEY_TAB)
	await _frames(3)
	var binder: GrimoireBinderPanel = hud.binder_panel() if hud != null else null
	if binder == null:
		check.call(false, "K5: the Binder opens for the card tooltips")
		return
	binder.show_tab(GrimoireBinderPanel.Tab.CARDS)
	var problems: PackedStringArray = PackedStringArray()
	var cards: int = 0
	var places: int = 0
	var retired: Array = KAIZEN.RETIRED_WORDS
	var sample: String = ""
	for socket: int in [ScribeCardResource.DioramaSocket.GUARD, ScribeCardResource.DioramaSocket.SKILL, ScribeCardResource.DioramaSocket.ULT]:
		binder._select_socket(socket)
		for page: int in [GrimoireBinderPanel.Column.LEAVES, GrimoireBinderPanel.Column.PLACES]:
			var options: Array[StringName] = binder.leaf_options() if page == GrimoireBinderPanel.Column.LEAVES else binder.place_options()
			for key: StringName in options:
				if key == &"":
					continue
				var tip: String = binder.card_tooltip_for(key, page)
				var lines: PackedStringArray = tip.split("\n")
				var fits: bool = lines.size() == 3 and (lines[2].begins_with("Ready:") or lines[2].begins_with("Not yet")) and lines[2].contains("Lv ")
				var when: bool
				if page == GrimoireBinderPanel.Column.PLACES:
					when = lines.size() > 1 and lines[1] == GrimoireBinderPanel.PLACE_WHEN and lines[0].contains("Place-Card")
					places += 1
				elif socket == ScribeCardResource.DioramaSocket.GUARD:
					when = lines.size() > 1 and lines[1].contains("In a fight") and lines[1].contains("never readies")
					cards += 1
				else:
					when = lines.size() > 1 and lines[1].contains("On the trail") and lines[1].contains("INK READY") and lines[1].contains("In a fight")
					cards += 1
					if sample == "" and socket == ScribeCardResource.DioramaSocket.SKILL:
						sample = tip
				if not fits or not when:
					problems.append(tip.replace("\n", " / "))
				for word: Variant in retired:
					if tip.contains(String(word)):
						problems.append("retired word %s" % word)
	# A Place-Card not in the binder says so, and when it would ride along.
	binder._select_socket(ScribeCardResource.DioramaSocket.SKILL)
	for listed: ScribeCardResource in ArsenalCatalog.current.cards():
		if not listed.is_place_card() or places >= 3:
			continue
		var key: StringName = ScribeCardResource.copy_key(listed.card_id, ScribeCardResource.CardVariant.STANDARD)
		var tip: String = binder.card_tooltip_for(key, GrimoireBinderPanel.Column.PLACES)
		var lines: PackedStringArray = tip.split("\n")
		places += 1
		if lines.size() != 3 or not lines[0].contains("Place-Card") or lines[1] != GrimoireBinderPanel.PLACE_WHEN \
				or not (lines[2].begins_with("Ready:") or lines[2].begins_with("Not yet")):
			problems.append(tip.replace("\n", " / "))
		elif sample.find("Not yet") < 0 and lines[2].begins_with("Not yet"):
			sample += " · " + tip.replace("\n", " / ")
	# The diamond rows say when they're used too.
	binder.column = GrimoireBinderPanel.Column.DIAMONDS
	binder.diamond_row = GrimoireBinderPanel.DIAMOND_ROWS.find(ScribeCardResource.DioramaSocket.ULT)
	var diamond: String = binder.tooltip_text_now()
	hud.close_menu()
	await _frames(2)
	check.call(problems.is_empty() and cards > 0 and places > 0 and diamond.contains("3 pips") and diamond.contains("INK READY"),
		"K5: %d Ink Card and %d Place-Card tooltips say what each does, when to use it (on the trail: INK READY; in a fight: a tap in the flash) and whether your level takes it, e.g. \"%s\"%s"
		% [cards, places, sample.replace("\n", " / "), "" if problems.is_empty() else " (" + "; ".join(problems.slice(0, 3)) + ")"])


func _check_enemy_badges() -> void:
	var Danger: Dictionary = EnemyNameplate.Danger
	var texts_ok: bool = (EnemyNameplate.badge_text(3, "") == "[Lv. 3]" and EnemyNameplate.badge_text(10, "Elite") == "[Lv. 10 Great-Boggart]"
		and EnemyNameplate.badge_text(25, "Boss") == "[Lv. 25 Boss]")
	var scale_ok: bool = (EnemyNameplate.danger_for(1, "", 10) == Danger.TRIVIAL and EnemyNameplate.danger_for(7, "", 10) == Danger.EASY
		and EnemyNameplate.danger_for(10, "", 10) == Danger.EVEN and EnemyNameplate.danger_for(11, "Elite", 10) == Danger.TOUGH
		and EnemyNameplate.danger_for(12, "Boss", 10) == Danger.DEADLY)
	# Grow the island's packs that aren't out yet (as streaming in their landblock would).
	for node: Node in tree.get_nodes_in_group(&"caldera_streamed_spawners"):
		var spawner: MobSpawner = node as MobSpawner
		if spawner != null and level.streamer.structures != null and level.streamer.structures.is_ancestor_of(spawner) and spawner.mobs.is_empty() \
				and not spawner.has_meta(&"beacon_guards"):
			spawner.spawn_mobs()
	await _frames(2)
	var foes: Array[ActorBase] = []
	for node: Node in level.find_children("*", "", true, false):
		if node is WildMob or node is WoodlandMinion:
			foes.append(node as ActorBase)
	var badged: int = 0
	var wrong: PackedStringArray = PackedStringArray()
	var example: String = ""
	for foe: ActorBase in foes:
		var plate: EnemyNameplate = foe.get_node_or_null(^"LevelBadge") as EnemyNameplate
		if plate == null:
			wrong.append("%s has no badge" % foe.display_name())
			continue
		plate.refresh()
		var expected: String = EnemyNameplate.badge_text(EnemyNameplate.level_of(foe), EnemyNameplate.rank_of(foe))
		if foe.stats.is_downed:
			continue
		if not plate.visible or not plate.text.begins_with(expected):
			wrong.append("%s reads %s" % [foe.display_name(), plate.text])
			continue
		badged += 1
		var mob: WildMob = foe as WildMob
		if example == "" or (mob != null and mob.variant.rank != MobVariantResource.Rank.COMMON):
			example = "%s %s (%s)" % [foe.display_name(), plate.text, EnemyNameplate.DANGER_NAMES[EnemyNameplate.danger_for(plate.level, plate.rank, EnemyNameplate.party_level())]]
	# The Options menu's Gameplay tab hides them all.
	SettingsManager.current.set_value(&"enemy_level_badges", false)
	var hidden: bool = true
	for foe: ActorBase in foes:
		var plate: EnemyNameplate = foe.get_node_or_null(^"LevelBadge") as EnemyNameplate
		if plate != null:
			plate.refresh()
			hidden = hidden and not plate.visible
	SettingsManager.current.set_value(&"enemy_level_badges", true)
	check.call(texts_ok and scale_ok and badged > 0 and wrong.is_empty() and hidden,
		"K5: %d enemies wear a level and danger badge over their health dots (e.g. %s), grey to red against the party's level; the Options menu hides them%s"
		% [badged, example, "" if wrong.is_empty() else " (" + ", ".join(wrong.slice(0, 4)) + ")"])
