## The Phase 12 Combat Kaizen refinement's checks (K1 to K5), run by
## tools/smoke_test.gd after the Caldera Isles' (the party stands on
## Hearthstead Market's level green):
##   K1  jump on ✕ / A (Space), roll on ○ / B (L), sprint on L3 / LS (Left
##       Shift): the bindings and their HUD labels, a 6.5 m/s jump to about a
##       metre and back down with its stretch and landing squash, a roll, a
##       sprint at 1.5x drawing 12 stamina a second that stops dry and waits for
##       a fresh press, on the keyboard and on a pad; jump backs out of a menu
##   K2  the playtest switcher (F2, or hold Share and tap the D-Pad): Bridge-
##       Warden, Hedge-Runner and Bell-Keeper at Levels 3, 7 and 12 in turn,
##       each with its Fellowship, Calling, weapon tier and Grimoire, a toast,
##       and nothing saved; Share's tap and hold untouched by the chord
##   K3  the cross HUD is the four diamonds alone: no slot grid and no words on
##       it, the hero's keys on the diamonds, a swing's flash and its combo pips
##       on the weapon diamond, health and stamina as the arcs round them
##   K4  the Grimoire Binder's tabs, stepped with Q / E: 1. Gear & Weapon (the
##       live hero in a lit preview window: its own camera, sky and two lights
##       on the hero alone), 2. Quick Magic-Ink Cards (where it opens), 3. Combo
##       Moves, and the Atlas Map, each with its tooltip box
##   K5  the 70-20-10 Playground Linter (08 Gate 6): no string in src/ that
##       could reach the screen uses a retired word (Vellum, Folio, Weapon-Coat,
##       Ward-Mantle, Bravery Counter, Hearth-Rite Tuck, Four-Sign, Sign-Coat,
##       Ink-Wheel, Glimmer-Spot, Action-Leaves), and the playground names
##       stand in their places (Plain Ink, Star-Ink, Ink Blade, Ink Shield,
##       PARRY & STRIKE!, INK READY, the Ink Card Collection, Make Ink Cards)
extends RefCounted

const LENS: GDScript = preload("res://tools/test_mythopoetic_lens.gd")
## The green by the Doverslap chime-post on Embershore: flat ground to jump and sprint on, within the post's reach (cards change there).
const GREEN: Vector3 = Vector3(745.35, 0.0, -121.64)

var tree: SceneTree
var check: Callable
var level: CalderaArchipelagoWorld


func run(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	level = tree.current_scene as CalderaArchipelagoWorld
	if level == null:
		check.call(false, "the Phase 12 Kaizen checks run in the Caldera Isles")
		return
	CalderaWorldState.current.reset_for_testing()
	level.travel_to(CalderaAtlas.ISLE_OAKSHIRE_HOLM, CalderaAtlas.ARRIVE_NORTH_QUAY)
	await _frames(4)
	_check_bindings()
	await _check_jump_and_roll()
	await _check_sprint()
	await _check_menu_back()
	await _check_minimal_hud()
	await _check_binder_tabs()
	_check_playground_linter()
	await _check_playtest_switcher()


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


func _pad_button(pad: int, button: JoyButton, pressed: bool) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.device = pad
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)


func _pad_axis(pad: int, axis: JoyAxis, value: float) -> void:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.device = pad
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


func _keyboard_hero() -> ActorBase:
	for actor: ActorBase in level.party_in_order():
		if actor.is_local_player() and actor.input != null and actor.input.device_id == InputComponent.KEYBOARD_DEVICE:
			return actor
	return null


func _pad_hero() -> ActorBase:
	for actor: ActorBase in level.party_in_order():
		if actor.is_local_player() and actor.input != null and actor.input.device_id != InputComponent.KEYBOARD_DEVICE:
			return actor
	return null


## Stands a hero on the green (each a little apart), idle, rested, its input its own again.
func _stand(actor: ActorBase, slot: int) -> void:
	actor.input.release_script()
	var spot: Vector3 = GREEN + Vector3(float(slot) * 3.0 - 3.0, 0.0, 0.0)
	level.streamer.ensure_ground_at(spot)
	spot.y = level.streamer.height_at(spot.x, spot.z) + 0.05
	actor.place_at(Transform3D(Basis.IDENTITY, spot))
	actor.stats.restore_stamina(actor.stats.stats.max_stamina)
	if not actor.state_machine.is_in(&"idle"):
		actor.state_machine.transition(&"idle")


static func _events_of(action: StringName) -> Array[String]:
	var seen: Array[String] = []
	for event: InputEvent in InputMap.action_get_events(action):
		var key: InputEventKey = event as InputEventKey
		var button: InputEventJoypadButton = event as InputEventJoypadButton
		if key != null:
			seen.append("key:%s" % OS.get_keycode_string(key.physical_keycode))
		elif button != null:
			seen.append("pad:%d" % button.button_index)
	return seen


# --- K1: jump, roll and sprint ------------------------------------------------------------

func _check_bindings() -> void:
	var jump: Array[String] = _events_of(InputComponent.ACTION_JUMP)
	var dodge: Array[String] = _events_of(InputComponent.ACTION_DODGE)
	var sprint: Array[String] = _events_of(InputComponent.ACTION_SPRINT)
	var calling: Array[String] = _events_of(InputComponent.ACTION_CHANGE_CALLING)
	check.call(jump == ["key:Space", "pad:%d" % JOY_BUTTON_A] and dodge == ["key:L", "pad:%d" % JOY_BUTTON_B]
		and sprint == ["key:Shift", "pad:%d" % JOY_BUTTON_LEFT_STICK] and calling == ["key:C"],
		"K1 bindings: jump on Space and ✕ / A, roll on L and ○ / B, sprint on Left Shift and L3 / LS; the Calling keeps C (L3 is sprint now): %s %s %s %s"
		% [jump, dodge, sprint, calling])
	var ps: InputComponent.PadFamily = InputComponent.PadFamily.PLAYSTATION
	check.call(InputComponent._pad_button_name(JOY_BUTTON_A, ps) == "✕" and InputComponent._pad_button_name(JOY_BUTTON_B, ps) == "○"
		and InputComponent._pad_button_name(JOY_BUTTON_LEFT_STICK, ps) == "L3"
		and InputComponent.binding_label(InputComponent.ACTION_JUMP, InputComponent.KEYBOARD_DEVICE) == "Space"
		and InputComponent.binding_label(InputComponent.ACTION_DODGE, InputComponent.KEYBOARD_DEVICE) == "L",
		"on a PlayStation pad jump reads ✕, roll ○ and sprint L3; on the keyboard, Space and L")


func _check_jump_and_roll() -> void:
	var hero: ActorBase = _keyboard_hero()
	if hero == null:
		check.call(false, "K1 needs the keyboard hero")
		return
	_stand(hero, 0)
	await _frames(6)
	var start_y: float = hero.global_position.y
	var jumps_before: int = hero.jumps
	var landings: Array[int] = [0]
	var on_land: Callable = func(_actor: ActorBase) -> void: landings[0] += 1
	hero.landed.connect(on_land)
	_key(KEY_SPACE, true)
	await _frames(2)
	_key(KEY_SPACE, false)
	var in_air: bool = hero.state_machine.is_in(&"jump")
	var apex: float = 0.0
	var stretched: bool = false
	var squashed: bool = false
	for frame: int in 60:
		await tree.physics_frame
		apex = maxf(apex, hero.global_position.y - start_y)
		var animator: HeroCombatAnimator = hero.visuals.animator if hero.visuals != null and hero.visuals.has_rig() else null
		if animator != null and hero.state_machine.is_in(&"jump") and animator.hips_scale.y > 1.03:
			stretched = true
		if animator != null and animator.land_squash > 0.0 and animator.hips_scale.y < 0.97:
			squashed = true
	hero.landed.disconnect(on_land)
	check.call(in_air and hero.jumps == jumps_before + 1 and apex > 0.8 and apex < 1.15 and landings[0] == 1 and hero.is_on_floor()
		and not hero.state_machine.is_in(&"jump"),
		"Space jumps the keyboard hero at %.1f m/s to %.2f m (about a metre) and lands back on the green" % [ActorBase.JUMP_VELOCITY, apex])
	check.call(stretched and squashed, "the jump stretches the hero tall in the air and squashes them on landing (the rig's hips)")
	await _tap_key(KEY_L)
	var rolled: bool = hero.state_machine.is_in(&"dodge")
	await _seconds(0.8)
	var pad_hero: ActorBase = _pad_hero()
	var pad_ok: bool = false
	var pad_rolled: bool = false
	if pad_hero != null:
		_stand(pad_hero, 2)
		await _frames(6)
		var pad: int = pad_hero.input.device_id - 1
		var before: int = pad_hero.jumps
		_pad_button(pad, JOY_BUTTON_A, true)
		await _frames(2)
		_pad_button(pad, JOY_BUTTON_A, false)
		pad_ok = pad_hero.state_machine.is_in(&"jump") and pad_hero.jumps == before + 1
		await _seconds(0.8)
		_pad_button(pad, JOY_BUTTON_B, true)
		await _frames(2)
		_pad_button(pad, JOY_BUTTON_B, false)
		pad_rolled = pad_hero.state_machine.is_in(&"dodge")
		await _seconds(0.8)
	check.call(rolled and pad_hero != null and pad_ok and pad_rolled,
		"L rolls the keyboard hero; on a pad ✕ / A jumps and ○ / B rolls (no longer both)")


func _check_sprint() -> void:
	var hero: ActorBase = _keyboard_hero()
	_stand(hero, 0)
	await _frames(4)
	var pace: float = hero.loadout.stats.move_speed
	_key(KEY_W, true)
	await _seconds(0.6)
	var run_speed: float = Vector2(hero.velocity.x, hero.velocity.z).length()
	_key(KEY_SHIFT, true)
	await _seconds(0.3)
	var stamina_at: float = hero.stats.stamina
	await _seconds(1.0)
	var sprint_speed: float = Vector2(hero.velocity.x, hero.velocity.z).length()
	var drained: float = stamina_at - hero.stats.stamina
	var leaning: float = hero.visuals.kinematics.lean_reach if hero.visuals != null and hero.visuals.has_rig() else 0.0
	check.call(hero.sprinting and absf(run_speed - pace) < 0.3 and absf(sprint_speed - pace * ActorBase.SPRINT_SPEED_SCALE) < 0.4
		and absf(drained - ActorBase.SPRINT_STAMINA_PER_SEC) < 1.5 and leaning > 1.2,
		"holding Left Shift while moving sprints at 1.5x (%.1f -> %.1f m/s), draws %.1f stamina a second and leans the hero further into the run"
		% [run_speed, sprint_speed, drained])
	hero.stats.stamina = 2.0
	await _seconds(0.4)
	var dry: bool = not hero.sprinting and hero.stats.stamina <= 0.5
	hero.stats.restore_stamina(40.0)
	await _seconds(0.2)
	var still_spent: bool = not hero.sprinting
	_key(KEY_SHIFT, false)
	await _frames(3)
	_key(KEY_SHIFT, true)
	await _seconds(0.2)
	var again: bool = hero.sprinting
	_key(KEY_SHIFT, false)
	_key(KEY_W, false)
	await _seconds(0.3)
	check.call(dry and still_spent and again, "run dry, the sprint stops at 0 stamina and waits for a fresh press of sprint")
	var pad_hero: ActorBase = _pad_hero()
	var pad_sprint: bool = false
	if pad_hero != null:
		_stand(pad_hero, 2)
		await _frames(4)
		var pad: int = pad_hero.input.device_id - 1
		_pad_axis(pad, JOY_AXIS_LEFT_Y, -1.0)
		_pad_button(pad, JOY_BUTTON_LEFT_STICK, true)
		await _seconds(0.8)
		pad_sprint = pad_hero.sprinting and Vector2(pad_hero.velocity.x, pad_hero.velocity.z).length() > pad_hero.loadout.stats.move_speed * 1.35
		_pad_button(pad, JOY_BUTTON_LEFT_STICK, false)
		_pad_axis(pad, JOY_AXIS_LEFT_Y, 0.0)
		await _seconds(0.3)
	check.call(pad_sprint, "on a pad, holding L3 while pushing the stick sprints")


func _check_menu_back() -> void:
	var hero: ActorBase = _keyboard_hero()
	_stand(hero, 0)
	await _frames(4)
	var hud: PlayerHUD = level.huds.get(hero.player_id) as PlayerHUD
	hud.open_binder()
	await _frames(4)
	var opened: bool = hud.binder_panel() != null
	var jumps_before: int = hero.jumps
	await _tap_key(KEY_SPACE)
	await _frames(2)
	check.call(opened and hud.binder_panel() == null and hero.jumps == jumps_before and not hero.state_machine.is_in(&"jump"),
		"in a menu, Space (jump) backs out of it without jumping")


# --- K3: the minimalist cross -------------------------------------------------------------

func _check_minimal_hud() -> void:
	var hero: ActorBase = _keyboard_hero()
	var hud: PlayerHUD = level.huds.get(hero.player_id) as PlayerHUD if hero != null else null
	if hud == null:
		check.call(false, "the keyboard hero has a HUD for the K3 checks")
		return
	var cross: CrossGrimoireHUD = hud.cross_grimoire
	var widgets: Array[Node] = cross.find_children("*", "CrossGrimoireDiamondWidget", true, false)
	var labels: Array[Node] = cross.find_children("*", "Label", true, false)
	var rich: Array[Node] = cross.find_children("*", "RichTextLabel", true, false)
	var slot_class: bool = false
	for listed: Dictionary in ProjectSettings.get_global_class_list():
		slot_class = slot_class or listed["class"] == &"CrossSlot"
	check.call(not ResourceLoader.exists("res://src/ui/cross_slot.gd") and not slot_class and not cross.has_method("slot_for_command")
		and widgets.size() == 1 and widgets[0] == cross.diorama and labels.is_empty() and rich.size() == 1 and rich[0].name == &"Couplet",
		"the text-heavy slot cross is gone: the HUD's cross is one diamond widget, with no labels (the rhyme ribbon aside)")
	var diamonds: CrossGrimoireDiamondWidget = cross.diorama
	check.call(CrossGrimoireDiamondWidget.DIAMOND_COUNT == 4 and diamonds.display_scale == CrossGrimoireDiamondWidget.HUD_SCALE
		and not diamonds.interactive and diamonds.follow == hero and ",".join(diamonds.key_texts) == "Q,E,R",
		"four diamonds (L, R, L+R and the weapon at the foot) at the HUD's size, wearing the keyboard's Q, E and R")
	var pad_hero: ActorBase = _pad_hero()
	if pad_hero != null:
		var pad_keys: Array[String] = CrossGrimoireHUD.socket_keys(pad_hero.input)
		var left: String = pad_hero.input.label(InputComponent.ACTION_TRIGGER_L)
		check.call(pad_keys.size() == 3 and pad_keys[2] == "%s+%s" % [left, pad_hero.input.label(InputComponent.ACTION_TRIGGER_R)] and left in ["L2", "LT"],
			"on a pad the diamonds read %s" % " / ".join(pad_keys))
	_stand(hero, 0)
	await _frames(6)
	ComboChainComponent.enabled = true
	hero.input.inject_command(CombatActionResource.Command.LIGHT)
	await _frames(3)
	var flashed: bool = diamonds.is_pulsing(CrossGrimoireDiamondWidget.WEAPON)
	await _seconds(0.3)
	var pips: Vector2i = diamonds.combo_pips()
	check.call(flashed and pips == Vector2i(hero.combo.step_index, hero.combo.max_steps) and pips.x >= 1 and pips.y >= 2,
		"a light swing flashes the weapon diamond and lights its first combo pip (%d of %d: o - o - >)" % [pips.x, pips.y])
	await _seconds(1.2)
	_stand(hero, 0)


# --- K4: the Grimoire Binder's tabs -----------------------------------------------------------

func _check_binder_tabs() -> void:
	var hero: ActorBase = _keyboard_hero()
	var hud: PlayerHUD = level.huds.get(hero.player_id) as PlayerHUD if hero != null else null
	if hud == null:
		check.call(false, "the keyboard hero has a HUD for the K4 checks")
		return
	_stand(hero, 0)
	await _frames(4)
	var opened: bool = hud.open_binder()
	await _frames(3)
	var binder: GrimoireBinderPanel = hud.binder_panel()
	if not opened or binder == null:
		check.call(false, "the Grimoire Binder opens on the green")
		return
	var Tab: Dictionary = GrimoireBinderPanel.Tab
	var names_ok: bool = "|".join(GrimoireBinderPanel.TAB_NAMES) == "1. Gear & Weapon|2. Quick Magic-Ink Cards|3. Combo Moves|4. Seal Press|Atlas Map"
	var tips: int = 0
	for index: int in GrimoireBinderPanel.TAB_TOOLTIPS.size():
		tips += 1 if GrimoireBinderPanel.TAB_TOOLTIPS[index].length() > 30 else 0
	var on_cards: bool = binder.tab == Tab.CARDS and binder.tooltip_text_now().contains(GrimoireBinderPanel.TAB_TOOLTIPS[Tab.CARDS])
	check.call(names_ok and tips == 5 and on_cards and not binder.preview_live(),
		"the Binder has the tabs 1. Gear & Weapon, 2. Quick Magic-Ink Cards, 3. Combo Moves, 4. Seal Press and the Atlas Map, each with a tooltip, and opens on the cards")
	await _tap_key(KEY_E)
	await _frames(2)
	var forms: Array[ComboChainResource] = ArsenalCatalog.current.combos()
	var tip: String = binder.tooltip_text_now()
	check.call(binder.tab == Tab.COMBOS and binder._combo_rows.size() == forms.size() and tip.begins_with("Press %s in a row" % forms[0].glyphs())
		and tip.contains("hits"), "E turns to Combo Moves: a row per form, and the tooltip says how to play the first (%s)" % tip.get_slice("\n", 0))
	await _tap_key(KEY_E)
	await _frames(2)
	var on_bench: bool = binder.tab == Tab.SEALS and binder.preview_live()
	await _tap_key(KEY_E)
	await _frames(3)
	var on_atlas: bool = binder.tab == Tab.ATLAS and is_instance_valid(binder.atlas)
	await _tap_key(KEY_Q)
	await _tap_key(KEY_Q)
	await _tap_key(KEY_Q)
	await _tap_key(KEY_Q)
	await _frames(3)
	check.call(on_bench and on_atlas and binder.tab == Tab.GEAR and binder.atlas == null,
		"E again opens the Seal Press (the hero in the preview) and then the Atlas Map; Q steps back through the tabs to Gear & Weapon")
	var lit: bool = true
	for node: Node in hero.find_children("*", "MeshInstance3D", true, false):
		lit = lit and (node as MeshInstance3D).get_layer_mask_value(GrimoireBinderPanel.PREVIEW_LAYER)
	var camera: Camera3D = binder.preview_camera
	var start_angle: float = binder._preview_angle
	await _seconds(0.5)
	var to_hero: float = camera.global_position.distance_to(hero.global_position)
	var looking: float = (-camera.global_basis.z).dot((hero.global_position + Vector3.UP * GrimoireBinderPanel.PREVIEW_LOOK_HEIGHT - camera.global_position).normalized())
	check.call(binder.preview_live() and lit and camera.current and camera.get_viewport() == binder.preview_viewport
		and binder.preview_viewport.world_3d == hero.get_world_3d() and absf(to_hero - Vector2(GrimoireBinderPanel.PREVIEW_DISTANCE, GrimoireBinderPanel.PREVIEW_HEIGHT).length()) < 0.05
		and looking > 0.999 and binder._preview_angle > start_angle,
		"Gear & Weapon shows the live hero in its own window, the camera circling %.1f m off at chest height" % to_hero)
	var sky: Environment = hero.get_world_3d().environment
	check.call(binder.key_light.visible and binder.rim_light.visible and binder.key_light.light_cull_mask == 1 << (GrimoireBinderPanel.PREVIEW_LAYER - 1)
		and binder.rim_light.light_cull_mask == binder.key_light.light_cull_mask and not camera.get_cull_mask_value(WorldLabelStyle.STATION_LABEL_LAYER)
		and camera.environment != null and camera.environment != sky and (sky == null or camera.environment.fog_density <= sky.fog_density)
		and (camera.attributes as CameraAttributesPractical).dof_blur_far_enabled,
		"the preview has its own lighting: a warm key and a cool rim light that reach only the hero, a clearer sky, and the far world softly blurred")
	var weapon_tip: String = binder.tooltip_text_now()
	await _tap_key(KEY_S)
	await _frames(2)
	check.call(binder._gear_rows[0].text == binder.weapon_title() and weapon_tip.contains(GrimoireBinderPanel.TAB_TOOLTIPS[Tab.GEAR])
		and binder.gear_row == GrimoireBinderPanel.GearRow.OFF_HAND and binder.tooltip_text_now().begins_with(binder.gear_tooltip(GrimoireBinderPanel.GearRow.OFF_HAND)),
		"its rows name the weapon (%s), offhand, mantle and Calling; ↓ moves the tooltip to the offhand" % binder.weapon_title())
	await _tap_key(KEY_L)
	await _frames(3)
	var unlit: bool = true
	for node: Node in hero.find_children("*", "MeshInstance3D", true, false):
		unlit = unlit and not (node as MeshInstance3D).get_layer_mask_value(GrimoireBinderPanel.PREVIEW_LAYER)
	check.call(hud.binder_panel() == null and unlit and not hero.input.menu_open, "roll closes the Binder, and the hero's meshes leave the preview's light layer")
	_stand(hero, 0)


# --- K5: the 70-20-10 Playground Linter ------------------------------------------------------

## Words Gate 6 retired from the screen (ids, class names, node names and save keys keep theirs).
const RETIRED_WORDS: Array[String] = ["Vellum", "VELLUM", "Folio", "FOLIO", "Weapon-Coat", "WEAPON-COAT", "Ward-Mantle", "WARD-MANTLE",
	"Bravery Counter", "BRAVERY COUNTER", "Bravery-Counter", "Hearth-Rite Tuck", "HEARTH-RITE TUCK", "Four-Sign", "Four Signs", "Sign-Coat",
	"Ink-Wheel", "Mantle & Tuck", "Glimmer-Spot", "GLIMMER-SPOT", "Action-Leaves", "Action-Leaf",
	# R7 (25 GDD): Defender / Striker, Armor Guard, Breath Recovery, Marks, no frame counts,
	# Great-Boggart, Bulwark, Deep-Tide, hills and woods.
	"+Tank", "+DPS", "the Tank", "the DPS", "mitigation", "Mitigation", "Stamina Regen", "stamina regen", " AP ", "18-frame",
	"Elite", "ELITE", "Aegis", "AEGIS", "Abyssal", "ABYSSAL", "landblocks", "Landblocks"]
## A line that names the old words on purpose (to read old saves back) is let through.
const LINTER_ALLOWED: Array[String] = ["OLD_VARIANT_NAMES"]


func _check_playground_linter() -> void:
	var literal: RegEx = RegEx.create_from_string("\"(?:[^\"\\\\]|\\\\.)*\"")
	var offenders: PackedStringArray = PackedStringArray()
	var scanned: int = 0
	for path: String in _scripts_under("res://src"):
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		scanned += 1
		for number: int in lines.size():
			var line: String = lines[number]
			if line.strip_edges().begins_with("#") or LINTER_ALLOWED.any(func(word: String) -> bool: return line.contains(word)):
				continue
			for found: RegExMatch in literal.search_all(line):
				var start: int = found.get_start()
				var text: String = found.get_string()
				# &"ids", ^"node paths", res:// paths and bare node names (no space) never reach the screen.
				if (start > 0 and line[start - 1] in ["&", "^"]) or text.contains("res://") or not text.contains(" "):
					continue
				for word: String in RETIRED_WORDS:
					if text.contains(word):
						offenders.append("%s:%d %s" % [path.get_file(), number + 1, text])
	check.call(scanned > 100 and offenders.is_empty(),
		"Gate 6: no on-screen string in %d scripts uses a retired word%s" % [scanned, "" if offenders.is_empty() else ": " + ", ".join(offenders)])
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var subtitles: PackedStringArray = PackedStringArray()
	for calling: CallingResource in catalog.callings():
		subtitles.append(calling.subtitle)
	check.call("|".join(ScribeCardResource.VARIANT_NAMES) == "Plain Ink|Gilded Leaf|Star-Ink"
		and "|".join(ScribeCardResource.MODE_NAMES) == "Ink Blade|Ink Shield|Lantern-Tether"
		and ScriberyShopPanel.TAB_NAMES[0] == "Make Ink Cards" and GrimoireBinderPanel._folio_text().begins_with("INK CARD COLLECTION")
		and GrimoireBinderPanel.TAB_NAMES[1] == "2. Quick Magic-Ink Cards" and "|".join(subtitles).contains("Journeyman of the Four Ink-Signs")
		and ScribeCardResource.variant_for_key("Plain Vellum") == ScribeCardResource.CardVariant.STANDARD
		and ScribeCardResource.variant_for_key("Star-Inked Vellum") == ScribeCardResource.CardVariant.STAR_INKED_VELLUM,
		"the playground names stand in: Plain Ink, Gilded Leaf, Star-Ink; Ink Blade and Ink Shield; Make Ink Cards; the Ink Card Collection; the Four Ink-Signs (old finish names still read back)")


static func _scripts_under(folder: String) -> Array[String]:
	var found: Array[String] = []
	for file: String in DirAccess.get_files_at(folder):
		if file.ends_with(".gd"):
			found.append(folder.path_join(file))
	for sub: String in DirAccess.get_directories_at(folder):
		found.append_array(_scripts_under(folder.path_join(sub)))
	return found


# --- K2: the playtest switcher --------------------------------------------------------------

func _check_playtest_switcher() -> void:
	PlaytestSwitcher.reset()
	var progress: PartyProgress = PartyProgress.current
	var saved_at: int = FileAccess.get_modified_time(progress.save_path) if FileAccess.file_exists(progress.save_path) else 0
	var hero: ActorBase = _keyboard_hero()
	_stand(hero, 0)
	await _frames(4)
	await _tap_key(KEY_F2)
	await _frames(4)
	hero = _keyboard_hero()
	var first: bool = (hero.loadout.class_id == ClassLoadouts.SHIELD_TANK and hero.loadout.display_name == "Bridge-Warden"
		and progress.trail_level() == 3 and progress.grimoire_level() == 1 and progress.playtest
		and hero.loadout.kit.weapon_id == ArsenalCatalog.current.trail_kit_for_role(hero.role(), 3).weapon_id)
	var notice: String = level._notice
	check.call(first and notice.begins_with("Debug Switch: Bridge-Warden Lv 3"),
		"K2: F2 switches the keyboard hero to a Bridge-Warden at Level 3 (Grimoire 1, Level 3's weapon tier) with a toast: \"%s\"" % notice)
	var seen: Array[String] = ["Bridge-Warden Lv 3"]
	for press: int in 4:
		await _tap_key(KEY_F2)
		await _frames(3)
		hero = _keyboard_hero()
		seen.append("%s Lv %d" % [hero.loadout.display_name, progress.playtest_level])
	check.call(seen == ["Bridge-Warden Lv 3", "Bridge-Warden Lv 7", "Bridge-Warden Lv 12", "Hedge-Runner Lv 3", "Hedge-Runner Lv 7"]
		and hero.loadout.class_id == ClassLoadouts.DIRECTIONAL_FLOW_DPS and progress.grimoire_level() == 2,
		"each F2 steps the matrix in order: %s" % ", ".join(seen))
	progress.save()
	var unsaved: bool = (FileAccess.get_modified_time(progress.save_path) if FileAccess.file_exists(progress.save_path) else 0) == saved_at
	check.call(unsaved and progress.trail_level() == 7, "while playtesting nothing is written to the save")
	var pad_hero: ActorBase = _pad_hero()
	var chord_ok: bool = false
	var share_clean: bool = false
	if pad_hero != null:
		_stand(pad_hero, 2)
		await _frames(4)
		var pad: int = pad_hero.input.device_id - 1
		var device: int = pad_hero.input.device_id
		var class_before: StringName = pad_hero.loadout.class_id
		_pad_button(pad, JOY_BUTTON_BACK, true)
		await _frames(3)
		_pad_button(pad, JOY_BUTTON_DPAD_RIGHT, true)
		await _frames(3)
		_pad_button(pad, JOY_BUTTON_DPAD_RIGHT, false)
		await _seconds(InputComponent.MENU_HOLD_TIME + 0.2)
		_pad_button(pad, JOY_BUTTON_BACK, false)
		await _frames(6)
		var after: ActorBase = null
		for actor: ActorBase in level.party_in_order():
			if actor.input != null and actor.input.device_id == device:
				after = actor
		var hud: PlayerHUD = level.huds.get(after.player_id) as PlayerHUD if after != null else null
		chord_ok = (after != null and PlaytestSwitcher.cursor(device) == 0 and after.loadout.display_name == "Bridge-Warden")
		# The chord spent the Share press: no Binder on its release, no Fellowship change from its long hold.
		share_clean = (hud != null and hud.binder_panel() == null and after.loadout.class_id == ClassLoadouts.SHIELD_TANK and class_before != &"")
	check.call(chord_ok and share_clean,
		"on a pad, holding Share and tapping D-Pad → steps the matrix too, and the chord spends the Share press (no Binder, no Fellowship change)")
	await _tap_key(KEY_F2)
	await _frames(3)
	var capped: bool = progress.playtest_level == 12 or progress.trail_level() <= PartyProgress.TRAIL_TOP_LEVEL
	check.call(capped and PlaytestSwitcher.MATRIX.size() == 9 and PlaytestSwitcher.toast_text(8) == "Debug Switch: Bell-Keeper Lv 12",
		"the matrix runs Bridge-Warden, Hedge-Runner and Bell-Keeper at Levels 3, 7 and 12; Level 12 wears the trail's Level 10 gear")
	progress.end_playtest()
	PlaytestSwitcher.reset()
	if CalderaWorldState.current != null:
		CalderaWorldState.current.playtest = false
