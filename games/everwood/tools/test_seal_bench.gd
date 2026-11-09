## The Binder's stamping bench (docs/everwood_equipment_grimoire_architecture.md,
## Build notes, "Stamping bench"), run by tools/smoke_test.gd and
## tools/run_equipment_grimoire_checks.gd straight after the Seal-and-Tuck
## Grimoire's three gates, on the keyboard hero:
##   - the ladder's slot gates agree with trim_to_stage at every stage and level,
##     and a level that opens a slot fills a chosen hand's empty slot with the
##     Fellowship's starting seal
##   - the Reed-Light Scribery's Seal Cards counter sells a seal once for Chimes
##   - the Binder's "4. Seal Press" tab lists the three Seals beside the
##     live preview, a pressed seal shows on the hero at once and in
##     EquipmentSealComponent.loadout, rides the seat and is saved per Fellowship
##   - a locked slot and a card the party can't use are refused with a reason
##   - the host refuses an over-stage hand, and so does every copy of the hero
##   - the hand survives a save and load, and a fresh seat of the Fellowship wears it
##   - a playtest writes nothing
extends RefCounted

const Hand = PlayerLoadoutResource.HandSlot
## Where the fresh seat's controller id starts looking (the first free one from here is used).
const FRESH_SEAT_DEVICE: int = 9

var tree: SceneTree
var check: Callable
var level: LevelBase


func run(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	level = tree.current_scene as LevelBase
	var seals_were: bool = EquipmentSealComponent.enabled
	EquipmentSealComponent.enabled = true
	print("  [Seal bench] the Binder's stamping bench")
	_check_ladder()
	var hero: ActorBase = _keyboard_hero()
	var hud: PlayerHUD = level.huds.get(hero.player_id) as PlayerHUD if hero != null and level != null else null
	var seat: PartyMember = NetworkManager.current.member(hero.player_id) if hero != null else null
	if hero == null or hero.seal == null or hud == null or seat == null:
		check.call(false, "a seated keyboard hero with a HUD and a seal component for the stamping bench checks")
		EquipmentSealComponent.enabled = seals_were
		return
	await _wait_out_of_combat(hero)
	await _stand_by_chime_post(hero)
	# A clean start: no saved hand for the Fellowship, the seat on the role's default.
	PartyProgress.current.save_seal_hand(seat.class_id, {})
	NetworkManager.current.grant_seal_hand(hero.player_id, {})
	hero.seal.debug_stage_override = 0
	hero.seal.clear_custom_loadout()
	await _frames(2)
	await _check_scribery_seals(hero, hud)
	await _check_bench(hero, hud, seat)
	await _check_save_round_trip(hero, seat)
	await _check_playtest_saves_nothing(hero, hud, seat)
	# Back to the role's default for whatever runs next.
	PartyProgress.current.save_seal_hand(seat.class_id, {})
	NetworkManager.current.grant_seal_hand(hero.player_id, {})
	hero.seal.clear_custom_loadout()
	EquipmentSealComponent.enabled = seals_were


# --- Helpers --------------------------------------------------------------------------

## In the Caldera, cards change only within a checkpoint chime-post's reach (docs/27 §7): the bench is used beside one.
func _stand_by_chime_post(hero: ActorBase) -> void:
	var world: CalderaArchipelagoWorld = level as CalderaArchipelagoWorld
	if world == null:
		return
	for node: Node in tree.get_nodes_in_group(ChimePost.GROUP):
		var post: ChimePost = node as ChimePost
		if post != null and post.checkpoint:
			var spot: Vector3 = post.global_position + Vector3(3.0, 0.0, 2.0)
			world.streamer.ensure_ground_at(spot)
			spot.y = world.streamer.height_at(spot.x, spot.z) + 0.05
			hero.place_at(Transform3D(Basis.IDENTITY, spot))
			await _frames(2)
			return


func _frames(count: int) -> void:
	for index: int in count:
		await tree.physics_frame


func _keyboard_hero() -> ActorBase:
	if level == null:
		return null
	for actor: ActorBase in level.party_in_order():
		if actor.is_local_player() and actor.input != null and actor.input.device_id == InputComponent.KEYBOARD_DEVICE:
			return actor
	for actor: ActorBase in level.party_in_order():
		if actor.is_local_player():
			return actor
	return null


## The Binder opens only out of a fight.
func _wait_out_of_combat(hero: ActorBase) -> void:
	hero.input.release_script()
	hero.action_queue.interrupt()
	for index: int in 240:
		if hero.sign_flow == null or not hero.sign_flow.is_in_combat:
			return
		await tree.physics_frame


func _open_bench(hud: PlayerHUD) -> GrimoireBinderPanel:
	if hud.binder_panel() == null:
		hud.open_binder()
	await _frames(2)
	var binder: GrimoireBinderPanel = hud.binder_panel()
	if binder != null:
		binder.show_tab(GrimoireBinderPanel.Tab.SEALS)
		await _frames(2)
	return binder


## The saved file's hand for a Fellowship, read straight off the disk ({} if none).
static func _hand_on_disk(class_id: StringName) -> Dictionary:
	var file: ConfigFile = ConfigFile.new()
	if file.load(PartyProgress.current.save_path) != OK:
		return {}
	var hands: Dictionary = file.get_value("seal_hands", "by_class", {}) as Dictionary
	return hands.get(String(class_id), {}) as Dictionary


## A seal card the party can't put in a slot: not owned and not the Fellowship's starting seal there.
static func _unusable_card(role: int, slot: int) -> StringName:
	for card_id: StringName in ArsenalCatalog.SEAL_CARD_IDS:
		if card_id != ArsenalCatalog.starting_seal_for_slot(role, slot) and not ArsenalCatalog.owns_any_finish(card_id, PartyProgress.current.collection):
			return card_id
	return &""


# --- The ladder ------------------------------------------------------------------------

func _check_ladder() -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var agrees: bool = true
	for stage: int in range(PlayerLoadoutResource.STAGE_HOMESTEAD, PlayerLoadoutResource.STAGE_APEX + 1):
		for true_level: int in range(1, ArsenalCatalog.MAX_TRUE_LEVEL + 1):
			var full: PlayerLoadoutResource = PlayerLoadoutResource.new()
			for slot: int in PlayerLoadoutResource.HAND_SLOT_COUNT:
				full.set_card_in_slot(slot, ArsenalCatalog.CARD_QUIET_WEIR)
			full.trim_to_stage(stage, true_level)
			for slot: int in PlayerLoadoutResource.HAND_SLOT_COUNT:
				agrees = agrees and (full.card_in_slot(slot) != &"") == PlayerLoadoutResource.slot_open(slot, stage, true_level)
	var levels_ok: bool = PlayerLoadoutResource.slot_open_level(Hand.WEAPON_SEAL) == 3 and PlayerLoadoutResource.slot_open_level(Hand.OFFHAND_SEAL) == 6 \
		and PlayerLoadoutResource.slot_open_level(Hand.MANTLE_SEAL) == 10 and PlayerLoadoutResource.slot_open_level(Hand.L_PRIMARY) > ArsenalCatalog.MAX_TRUE_LEVEL \
		and PlayerLoadoutResource.slot_open_level(Hand.R_TUCK) > ArsenalCatalog.MAX_TRUE_LEVEL \
		and PlayerLoadoutResource.slot_opens_text(Hand.MANTLE_SEAL) == "opens at Lv 10" and PlayerLoadoutResource.slot_opens_text(Hand.OFFHAND_SEAL) == "opens at Lv 6" \
		and PlayerLoadoutResource.slot_opens_text(Hand.L_PRIMARY) == "is in the Cross now"
	check.call(agrees and levels_ok,
		"the bench's slot gates match trim_to_stage at all 4 stages and 14 levels: the weapon Seal at Lv 3, the offhand's at 6, the mantle's at 10; the old pocket slots never open (their cards live in the Cross)")
	var role: int = ClassLoadoutResource.Role.TANK
	var chosen: PlayerLoadoutResource = PlayerLoadoutResource.new()
	chosen.offhand_seal_card_id = ArsenalCatalog.CARD_WEST_WIND_PROMISE
	var at_two: bool = catalog.apply_seal_milestone(chosen, role, 2)
	var at_three: bool = catalog.apply_seal_milestone(chosen, role, 3)
	check.call(not at_two and at_three and chosen.offhand_seal_card_id == ArsenalCatalog.CARD_WEST_WIND_PROMISE
		and chosen.weapon_seal_card_id == ArsenalCatalog.starting_seal_for_slot(role, Hand.WEAPON_SEAL)
		and chosen.active_count() == 0 and chosen.mantle_seal_card_id == &"",
		"Lv 3 fills a chosen hand's newly opened weapon Seal with the Fellowship's starting seal; the player's own offhand choice stays as it was, and no pocket card appears")


# --- The Reed-Light Scribery's Seal Cards ---------------------------------------------------

func _check_scribery_seals(hero: ActorBase, hud: PlayerHUD) -> void:
	var progress: PartyProgress = PartyProgress.current
	hud.open_scribery_shop()
	await _frames(1)
	var shop: ScriberyShopPanel = hud.scribery_panel()
	if shop == null:
		check.call(false, "the Scribery's counter opens for the Seal Cards checks")
		return
	progress.chimes = 100
	shop.select_tab(ScriberyShopPanel.Tab.SEALS)
	var listed: Array[StringName] = shop.options()
	var pulls_before: int = hero.visuals.pocket_pull_count()
	var on_row: bool = shop.select_option(ArsenalCatalog.CARD_WEST_WIND_PROMISE)
	var flourished: bool = hero.visuals.pocket_pull_count() > pulls_before
	var bought: bool = shop.buy()
	await _frames(2)
	var again: bool = shop.buy()
	var made_note: bool = shop.note_text().begins_with("Already made")
	var copies: Dictionary = {}
	var file: ConfigFile = ConfigFile.new()
	if file.load(progress.save_path) == OK:
		copies = file.get_value("cards", "collection", {}) as Dictionary
	check.call(listed.size() == ArsenalCatalog.SEAL_CARD_IDS.size() and listed.has(ArsenalCatalog.CARD_QUIET_WEIR) and on_row and flourished
		and bought and progress.chimes == 100 - ArsenalCatalog.SEAL_CHIME_COST and progress.owns_card(ArsenalCatalog.CARD_WEST_WIND_PROMISE)
		and int(copies.get("CARD_WEST_WIND_PROMISE", 0)) == 1 and not again and made_note
		and PartyProgress.is_scribery_card(ArsenalCatalog.CARD_EMBER_BOUGH) and shop.gildable_copies().all(func(key: StringName) -> bool:
			return not ArsenalCatalog.current.card(ScribeCardResource.copy_card_id(key)).is_seal_card()),
		"the Scribery's Seal Cards counter lists the four seals (highlighting one has the hero pull it from the pouch), makes the West-Wind once for %d Chimes and saves it; a second is refused" % ArsenalCatalog.SEAL_CHIME_COST)
	shop.close()
	await _frames(2)


# --- The bench ------------------------------------------------------------------------------

func _check_bench(hero: ActorBase, hud: PlayerHUD, seat: PartyMember) -> void:
	var binder: GrimoireBinderPanel = await _open_bench(hud)
	if binder == null:
		check.call(false, "the Grimoire Binder opens for the stamping bench checks")
		return
	var progress: PartyProgress = PartyProgress.current
	var role: int = hero.role()
	var stage: int = hero.seal.progression_stage
	var open_rows: int = 0
	var locked_rows: int = 0
	var starter_marked: bool = true
	var rows_ok: bool = binder._seal_rows.size() == GrimoireBinderPanel.SEAL_ROWS.size()
	for slot: int in mini(binder._seal_rows.size(), GrimoireBinderPanel.SEAL_ROWS.size()):
		var text: String = binder.seal_row_text(slot)
		rows_ok = rows_ok and binder._seal_rows[slot].visible and text.contains(PlayerLoadoutResource.HAND_SLOT_NAMES[slot] + ":")
		if binder.seal_slot_open(slot):
			open_rows += 1
			rows_ok = rows_ok and (text.contains(GrimoireBinderPanel.SEAL_PRESSED) or text.contains(GrimoireBinderPanel.SEAL_EMPTY))
			var card_id: StringName = hero.seal.loadout.card_in_slot(slot)
			var lent: bool = card_id != &"" and card_id == ArsenalCatalog.starting_seal_for_slot(role, slot) \
				and not ArsenalCatalog.owns_any_finish(card_id, progress.collection)
			starter_marked = starter_marked and text.contains("(starter)") == lent
		else:
			locked_rows += 1
			rows_ok = rows_ok and text.contains(GrimoireBinderPanel.SEAL_LOCKED) and text.contains(PlayerLoadoutResource.slot_opens_text(slot))
	check.call(binder.tab == GrimoireBinderPanel.Tab.SEALS and binder.preview_live() and rows_ok and starter_marked
		and open_rows == PlayerLoadoutResource.seals_open_at_stage(stage) + PlayerLoadoutResource.actives_open_at_stage(stage)
		and binder.tooltip_text_now().contains(GrimoireBinderPanel.TAB_TOOLTIPS[GrimoireBinderPanel.Tab.SEALS]),
		"\"4. Seal Press\" lists the three Seals beside the lit preview: %d open at Stage %d (the starting seals marked), %d locked by shape with when they open"
		% [open_rows, stage, locked_rows])
	# The Seal Press (the Seals wireframe): → to the offhand, ↓ to its next card, light presses it, on the hero at once.
	binder.pick_seal_slot(Hand.WEAPON_SEAL)
	hero.input.menu_input.emit(InputComponent.MENU_RIGHT)
	var options: Array[StringName] = binder.seal_options(Hand.OFFHAND_SEAL)
	var worn_before: StringName = hero.seal.loadout.offhand_seal_card_id
	var expected: StringName = options[wrapi(options.find(worn_before) + 1, 0, options.size())]
	hero.input.menu_input.emit(InputComponent.MENU_DOWN)
	hero.input.menu_input.emit(InputComponent.MENU_ACCEPT)
	await _frames(1)
	var stepped: bool = binder.seal_row == Hand.OFFHAND_SEAL and hero.seal.loadout.offhand_seal_card_id == expected \
		and hero.visuals.seal_state().get("offhand_seal", &"x") == expected
	# The West-Wind the party just made, pressed on the off-hand.
	var pressed: bool = binder.press_seal(Hand.OFFHAND_SEAL, ArsenalCatalog.CARD_WEST_WIND_PROMISE)
	await _frames(1)
	var shown: Dictionary = hero.visuals.seal_state()
	check.call(options.has(&"") and options.has(ArsenalCatalog.CARD_WEST_WIND_PROMISE) and options.has(ArsenalCatalog.starting_seal_for_slot(role, Hand.OFFHAND_SEAL))
		and stepped and pressed and hero.seal.loadout.offhand_seal_card_id == ArsenalCatalog.CARD_WEST_WIND_PROMISE
		and shown.get("offhand_seal", &"") == ArsenalCatalog.CARD_WEST_WIND_PROMISE and bool(shown.get("offhand_sealed", false)) and binder.preview_live()
		and binder._seal_rows[Hand.OFFHAND_SEAL].text.contains("Firth-Squall Feather") and hero.seal.wears_chosen_hand(),
		"→, ↓ and light press the offhand's next card, then the Firth-Squall Feather goes on: the hero's crest shows it in the preview at once and EquipmentSealComponent.loadout holds it")
	check.call(String(seat.seal_hand.get("offhand_seal", "")) == "CARD_WEST_WIND_PROMISE" and hero.seal.seat_hand() == seat.seal_hand
		and String(progress.seal_hand_for(seat.class_id).get("offhand_seal", "")) == "CARD_WEST_WIND_PROMISE"
		and String(_hand_on_disk(seat.class_id).get("offhand_seal", "")) == "CARD_WEST_WIND_PROMISE"
		and PartyMember.from_dict(seat.to_dict()).seal_hand == seat.seal_hand and seat.seal_hand.values().all(func(value: Variant) -> bool:
			return typeof(value) in [TYPE_INT, TYPE_STRING]),
		"the host took the hand: it rides the seat in the roster as Strings and ints and is saved for the %s" % Callings.fellowship_member(seat.class_id))
	# A locked slot refuses, and the tooltip box says when it opens.
	var locked_slot: int = -1
	for slot: int in GrimoireBinderPanel.SEAL_ROWS:
		if not binder.seal_slot_open(slot):
			locked_slot = slot
			break
	if locked_slot >= 0:
		var before: Dictionary = hero.seal.loadout.to_network_dict()
		binder.seal_row = locked_slot
		hero.input.menu_input.emit(InputComponent.MENU_ACCEPT)
		await _frames(1)
		var keyed_refusal: String = binder.note_text()
		var pressed_locked: bool = binder.press_seal(locked_slot, ArsenalCatalog.CARD_WEST_WIND_PROMISE)
		var tip: String = binder.tooltip_text_now()
		var opens: String = PlayerLoadoutResource.slot_opens_text(locked_slot)
		check.call(keyed_refusal.contains(opens) and not pressed_locked and binder.note_text().contains(opens)
			and tip.begins_with("Locked: the %s slot %s" % [PlayerLoadoutResource.HAND_SLOT_NAMES[locked_slot], opens])
			and hero.seal.loadout.to_network_dict() == before and hero.seal.loadout.card_in_slot(locked_slot) == &"",
			"the locked %s slot refuses light and a press (\"%s\"); the tooltip box says why: %s" % [PlayerLoadoutResource.HAND_SLOT_NAMES[locked_slot], keyed_refusal, tip.get_slice("\n", 0)])
	else:
		check.call(GrimoireRules.all_open() or GrimoireRules.seal_open(GrimoireRules.SEAL_OPEN_LEVELS.size() - 1, hero.seal.true_level),
			"every Seal is open: the mantle Seal at Lv %d, or the classic full kits" % GrimoireRules.SEAL_OPEN_LEVELS[2])
	# A card the party can't use refuses too.
	var unusable: StringName = _unusable_card(role, Hand.WEAPON_SEAL)
	if unusable != &"" and binder.seal_slot_open(Hand.WEAPON_SEAL):
		var worn_weapon: StringName = hero.seal.loadout.weapon_seal_card_id
		var pressed_unowned: bool = binder.press_seal(Hand.WEAPON_SEAL, unusable)
		check.call(not pressed_unowned and binder.note_text().contains("Reed-Light Scribery") and hero.seal.loadout.weapon_seal_card_id == worn_weapon
			and not binder.seal_options(Hand.WEAPON_SEAL).has(unusable),
			"a seal the party hasn't made (%s) isn't offered for the weapon, and pressing it says to get it at the Scribery" % ArsenalCatalog.current.get_card(unusable).display_name)
	binder.close()
	await _frames(2)
	# The host refuses an over-stage hand that skipped the bench's own check, and so does every copy.
	var over: PlayerLoadoutResource = hero.seal.loadout.copy()
	var claimed: int = -1
	for slot: int in PlayerLoadoutResource.HAND_SLOT_COUNT:
		if not PlayerLoadoutResource.slot_open(slot, hero.seal.progression_stage, hero.seal.true_level):
			over.set_card_in_slot(slot, ArsenalCatalog.CARD_WEST_WIND_PROMISE)
			claimed = slot if claimed < 0 else claimed
	var refusals: Array[String] = []
	var catch_refusal: Callable = func(device_id: int, why: String) -> void:
		if device_id == hero.device_id:
			refusals.append(why)
	NetworkManager.current.seal_hand_refused.connect(catch_refusal)
	var seat_before: Dictionary = seat.seal_hand.duplicate(true)
	var saved_before: Dictionary = progress.seal_hand_for(seat.class_id).duplicate(true)
	var reason: String = level.check_seal_hand(seat, over.to_network_dict())
	NetworkManager.current.update_local_seal_hand(hero.device_id, over.to_network_dict())
	var refused_before: int = hero.seal.refused_hands()
	var worn_hand: Dictionary = hero.seal.loadout.to_network_dict()
	hero.seal.sync_loadout_rpc(over.to_network_dict())
	NetworkManager.current.seal_hand_refused.disconnect(catch_refusal)
	check.call(claimed >= 0 and reason.contains(PlayerLoadoutResource.HAND_SLOT_NAMES[claimed]) and refusals.size() == 1 and refusals[0] == reason
		and seat.seal_hand == seat_before and progress.seal_hand_for(seat.class_id) == saved_before
		and hero.seal.refused_hands() == refused_before + 1 and hero.seal.loadout.to_network_dict() == worn_hand,
		"the host refuses a hand that claims a locked slot (%s); the seat and the save keep the old hand, and a copy named it over the network keeps its own" % reason)


# --- Saving -----------------------------------------------------------------------------------

func _check_save_round_trip(hero: ActorBase, seat: PartyMember) -> void:
	var progress: PartyProgress = PartyProgress.current
	var chosen: Dictionary = progress.seal_hand_for(seat.class_id).duplicate(true)
	progress.load_save()
	await _frames(1)
	var loaded: Dictionary = progress.seal_hand_for(seat.class_id)
	var picked: Dictionary = level.pick_seal_hand(seat.class_id, false)
	var companion_pick: Dictionary = level.pick_seal_hand(seat.class_id, true)
	# A fresh seat of the same Fellowship, seated the way any new player is: it wears the saved hand from its first frame.
	var network: NetworkManager = NetworkManager.current
	var room: bool = network.local_player_count() < NetworkManager.MAX_LOCAL_PLAYERS and network.party_size() < NetworkManager.MAX_PARTY_SIZE
	var fresh_ok: bool = true
	var fresh_label: String = "no room for a fresh seat"
	if room:
		# The first controller id nobody holds (the full smoke test's fake pads sit on high ids too).
		var fresh_device: int = FRESH_SEAT_DEVICE
		while network.roster.has(PartyMember.make_player_id(network.local_peer_id(), fresh_device)):
			fresh_device += 1
		var fresh_id: StringName = PartyMember.make_player_id(network.local_peer_id(), fresh_device)
		network.request_local_player(fresh_device, seat.class_id, InputComponent.AssistMode.ADVENTURER)
		await _frames(3)
		var fresh_seat: PartyMember = network.member(fresh_id)
		var fresh: ActorBase = level.actors.get(fresh_id) as ActorBase
		fresh_ok = fresh_seat != null and fresh_seat.seal_hand == chosen and fresh != null and fresh.seal != null \
			and fresh.seal.loadout.offhand_seal_card_id == ArsenalCatalog.CARD_WEST_WIND_PROMISE \
			and fresh.visuals.seal_state().get("offhand_seal", &"") == ArsenalCatalog.CARD_WEST_WIND_PROMISE
		fresh_label = "a fresh %s seated now wears it" % Callings.fellowship_member(seat.class_id)
		network.drop_local_player(fresh_device)
		await _frames(3)
	var parts: Array[bool] = [not chosen.is_empty(), loaded == chosen, picked == chosen, companion_pick.is_empty(), fresh_ok,
		hero.seal.loadout.offhand_seal_card_id == ArsenalCatalog.CARD_WEST_WIND_PROMISE, room]
	var all_ok: bool = not parts.has(false)
	check.call(all_ok,
		"the hand survives a save and a load (the West-Wind off-hand), the next seat of the Fellowship is handed it, companions keep the default, and %s%s"
		% [fresh_label, "" if all_ok else " [parts %s; chosen %s; loaded %s; picked %s; worn off-hand %s]" % [parts, chosen, loaded, picked, hero.seal.loadout.offhand_seal_card_id]])


func _check_playtest_saves_nothing(hero: ActorBase, hud: PlayerHUD, seat: PartyMember) -> void:
	var progress: PartyProgress = PartyProgress.current
	var on_disk: Dictionary = _hand_on_disk(seat.class_id)
	var was: bool = progress.playtest
	progress.playtest = true
	var binder: GrimoireBinderPanel = await _open_bench(hud)
	var pressed: bool = binder != null and binder.press_seal(Hand.OFFHAND_SEAL, &"")
	await _frames(1)
	var worn_now: bool = hero.seal.loadout.offhand_seal_card_id == &"" and String(seat.seal_hand.get("offhand_seal", "x")) == ""
	var disk_after: Dictionary = _hand_on_disk(seat.class_id)
	if binder != null:
		binder.close()
	await _frames(2)
	progress.playtest = was
	check.call(pressed and worn_now and not on_disk.is_empty() and disk_after == on_disk,
		"in a playtest the bench still works (the off-hand seal lifted) but the save file keeps the hand it had")
