## The Ink Card Deck (25_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md §7), run by
## tools/smoke_test.gd after the Ink-Well checks, on the keyboard hero:
##   1  the eight cards: an R Ink Blade and an L Ink Shield for each Sign, their
##      twists, words and pictures; Ember-Wick Cut is the starting card, the
##      Commons are inscribed at the Scribery, the Uncommons are found on the isles
##   2  the twists: every third coated hit of Cairn-Cleave rings the foe, Squall-Lash
##      frost-slows, Ember-Wick Cut's burn stacks, Tide-Turn Thrust gives Breath back;
##      a slow rides the strike over the network and slows the pace; Hoarfrost
##      Mantle's shield shrugs slows off; Moon-Weir Guard turns a Perfect Guard into
##      an Ink-Drop, once in four seconds
##   3  a calmed foe on Rime-Firth leaves a Rime-Gale deck card the party hasn't
##      found, and "A NEW CARD!" springs up on the screen
##   4  the card bench: the picture guide opens and closes, the spotlight says what
##      light will do, and a card going in gets its cheerful note
extends RefCounted

var tree: SceneTree
var check: Callable
var level: LevelBase


func run(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	level = tree.current_scene as LevelBase
	print("  [Ink Card Deck] the eight cards, their twists, finds and the bench")
	_check_cards()
	var hero: ActorBase = _keyboard_hero()
	if hero == null or hero.sign_flow == null:
		check.call(false, "a seated keyboard hero with Sign-Flow for the deck checks")
		return
	_check_twists(hero)
	await _check_find(hero)
	await _check_bench(hero)


func _frames(count: int) -> void:
	for index: int in count:
		await tree.process_frame


func _keyboard_hero() -> ActorBase:
	if level == null:
		return null
	for actor: ActorBase in level.party_in_order():
		if actor.is_local_player() and actor.input != null and actor.input.device_id == InputComponent.KEYBOARD_DEVICE:
			return actor
	return null


# --- 1: the eight cards --------------------------------------------------------------------------

func _check_cards() -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var deck: Array[ScribeCardResource] = catalog.ink_deck()
	var per_sign: Dictionary[int, int] = {}
	var shaped: bool = deck.size() == 8
	for card: ScribeCardResource in deck:
		var attack: bool = card.slot == ScribeCardResource.GrimoireSlot.SIGNATURE
		per_sign[card.scribe_sign] = int(per_sign.get(card.scribe_sign, 0)) + 1
		shaped = shaped and card.twist != CardTwists.Twist.NONE and card.art_motif != &"" and card.kid_text != "" and card.flavor_text != "" and card.found_text != ""
		if attack:
			shaped = shaped and card.manifestation_mode == ScribeCardResource.ManifestationMode.WEAPON_COAT
		else:
			shaped = shaped and card.manifestation_mode == ScribeCardResource.ManifestationMode.WARD_MANTLE and is_equal_approx(card.ward_damage_mitigation_pct, ArsenalCatalog.DECK_SHIELD_WARD) \
				and card.grants_stun_immunity and LoadoutComposer.fits_diorama(ClassLoadouts.player_class(ClassLoadouts.SHIELD_TANK), card)
	var signs_ok: bool = per_sign.size() == 4 and per_sign.values().all(func(count: Variant) -> bool: return int(count) == 2)
	var wick: ScribeCardResource = catalog.card(ArsenalCatalog.EMBER_WICK_CUT)
	var squall: ScribeCardResource = catalog.card(ArsenalCatalog.SQUALL_LASH)
	var sold: Array[ScribeCardResource] = catalog.scribery_leaves()
	check.call(shaped and signs_ok and wick.starter and catalog.lead_cards(ScribeCardResource.GrimoireSlot.SIGNATURE).has(squall)
		and sold.has(catalog.card(ArsenalCatalog.CAIRN_CLEAVE)) and not sold.has(squall) and squall.drop_weight == 0.0
		and GrimoireRules.ink_cost(GrimoireRules.SOCKET_R, squall, false) == 2 and GrimoireRules.ink_cost(GrimoireRules.SOCKET_R, catalog.card(ArsenalCatalog.CAIRN_CLEAVE), false) == 1,
		"the deck: an R Ink Blade and an L Ink Shield (70% ward, no stuns) for each of the four Signs, each with its twist, picture, kid words, flavour and where it's found; Ember-Wick Cut starts in every binder, Commons cost 1 drop and are sold at the Scribery, Uncommons cost 2 and are found on the isles")


# --- 2: the twists ---------------------------------------------------------------------------------

func _strike_on(hero: ActorBase, target: ActorBase, coat_sign: int) -> CombatEvent:
	var event: CombatEvent = CombatEvent.new()
	event.attacker_path = hero.get_path()
	event.target_path = target.get_path()
	event.coat_sign = coat_sign
	event.poise_damage = 10.0
	return event


func _check_twists(hero: ActorBase) -> void:
	var flow: SignFlowComponent = hero.sign_flow
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var target: ActorBase = null
	for actor: ActorBase in level.party_in_order():
		if actor != hero:
			target = actor
	if target == null:
		target = hero
	var saved_card: ScribeCardResource = flow.twist_card
	# Cairn-Cleave: the third coated hit rings the foe.
	flow.twist_card = catalog.card(ArsenalCatalog.CAIRN_CLEAVE)
	flow.twist_hits.clear()
	var rings: Array[int] = []
	for hit: int in 3:
		var event: CombatEvent = _strike_on(hero, target, ScribeSignResource.Sign.SIGN_IRON_ROOT)
		CardTwists.on_coated_hit(flow, event)
		rings.append(event.primer)
	var ring_ok: bool = rings == [ScribeSignResource.Sign.NONE, ScribeSignResource.Sign.NONE, ScribeSignResource.Sign.SIGN_IRON_ROOT]
	# Squall-Lash: a frost slow on the strike.
	flow.twist_card = catalog.card(ArsenalCatalog.SQUALL_LASH)
	flow.twist_hits.clear()
	var frost: CombatEvent = _strike_on(hero, target, ScribeSignResource.Sign.SIGN_RIME_GALE)
	CardTwists.on_coated_hit(flow, frost)
	var frost_ok: bool = is_equal_approx(frost.slow_fraction, CardTwists.FROST_SLOW) and is_equal_approx(frost.slow_seconds, CardTwists.FROST_SLOW_SECONDS)
	var carried: CombatEvent = CombatEvent.from_dict(frost.to_dict())
	# Ember-Wick Cut: the burn stacks.
	flow.twist_card = catalog.card(ArsenalCatalog.EMBER_WICK_CUT)
	flow.twist_stacks.clear()
	var first: CombatEvent = _strike_on(hero, target, ScribeSignResource.Sign.SIGN_WARM_HEARTH)
	CardTwists.on_coated_hit(flow, first)
	var second: CombatEvent = _strike_on(hero, target, ScribeSignResource.Sign.SIGN_WARM_HEARTH)
	CardTwists.on_coated_hit(flow, second)
	var ember_ok: bool = is_equal_approx(first.poise_damage, 10.0 * (1.0 + CardTwists.EMBER_PER_STACK)) and is_equal_approx(second.poise_damage, 10.0 * (1.0 + 2.0 * CardTwists.EMBER_PER_STACK))
	# Tide-Turn Thrust: Breath back.
	flow.twist_card = catalog.card(ArsenalCatalog.TIDE_TURN_THRUST)
	hero.stats.stamina = 10.0
	CardTwists.on_coated_hit(flow, _strike_on(hero, target, ScribeSignResource.Sign.SIGN_STAR_TIDE))
	var tide_ok: bool = is_equal_approx(hero.stats.stamina, 10.0 + CardTwists.TIDE_BREATH)
	check.call(ring_ok and frost_ok and ember_ok and tide_ok and is_equal_approx(carried.slow_fraction, CardTwists.FROST_SLOW),
		"the attack twists: Cairn-Cleave rings the foe on the third coated hit, Squall-Lash frost-slows 20% for 2 s (and the slow rides the strike over the network), Ember-Wick Cut's burn stacks, Tide-Turn Thrust gives 6 Breath back")
	# A slow slows the pace; Hoarfrost Mantle's shield shrugs it off (Sign-Flow on for the shields, as in play).
	var flow_was: bool = SignFlowComponent.enabled
	SignFlowComponent.enabled = true
	hero.apply_slow(0.4, 1.0)
	var slowed: float = hero.slow_factor()
	hero.apply_slow(0.0, 0.0)
	hero._slow_until = 0.0
	var coat_was: float = flow.coat_time_left
	var mode_was: int = flow.coat_mode
	flow.twist_card = catalog.card(ArsenalCatalog.HOARFROST_MANTLE)
	flow.coat_time_left = 5.0
	flow.coat_mode = ScribeCardResource.ManifestationMode.WARD_MANTLE
	hero.apply_slow(0.4, 1.0)
	var shrugged: bool = is_equal_approx(hero.slow_factor(), 1.0)
	# Moon-Weir Guard: a Perfect Guard pours an Ink-Drop, then rests four seconds.
	flow.twist_card = catalog.card(ArsenalCatalog.MOON_WEIR_GUARD)
	flow.twist_guard_ready_at = 0.0
	var first_guard: bool = CardTwists.on_perfect_guard(flow)
	var second_guard: bool = CardTwists.on_perfect_guard(flow)
	flow.coat_time_left = coat_was
	flow.coat_mode = mode_was
	flow.twist_card = saved_card
	SignFlowComponent.enabled = flow_was
	check.call(is_equal_approx(slowed, 0.6) and shrugged and first_guard and not second_guard,
		"the shield twists: a 40% slow leaves 60% of the pace, Hoarfrost Mantle's shield shrugs slows off, Moon-Weir Guard's Perfect Guard pours an Ink-Drop once in 4 s")


# --- 3: a find on the isles ---------------------------------------------------------------------------

func _check_find(hero: ActorBase) -> void:
	var progress: PartyProgress = PartyProgress.current
	var hud: PlayerHUD = level.huds.get(hero.player_id) as PlayerHUD if level != null else null
	var squall_had: int = progress.copies_of(ArsenalCatalog.SQUALL_LASH)
	var mantle_had: int = progress.copies_of(ArsenalCatalog.HOARFROST_MANTLE)
	progress.collection.erase(ArsenalCatalog.SQUALL_LASH)
	progress.collection.erase(ArsenalCatalog.HOARFROST_MANTLE)
	var found: StringName = progress.roll_deck_find(ScribeSignResource.Sign.SIGN_RIME_GALE, GrimoireRules.REFILL_GREAT_BOGGART)
	await _frames(3)
	var reveal: CardReveal = hud.card_reveal() if hud != null else null
	var shown: bool = reveal != null and reveal.copy_key == found
	if reveal != null:
		reveal.queue_free()
	var nothing: StringName = progress.roll_deck_find(ScribeSignResource.Sign.SIGN_RIME_GALE, 0)
	check.call((found == ArsenalCatalog.SQUALL_LASH or found == ArsenalCatalog.HOARFROST_MANTLE) and progress.copies_of(found) == 1 and shown and nothing == &"",
		"a calmed Great-Boggart on a Rime-Gale isle leaves a Rime-Gale deck card the party hadn't found (%s), and A NEW CARD! springs up on the screen" % found)
	progress.collection.erase(ArsenalCatalog.SQUALL_LASH)
	progress.collection.erase(ArsenalCatalog.HOARFROST_MANTLE)
	if squall_had > 0:
		progress.collection[ArsenalCatalog.SQUALL_LASH] = squall_had
	if mantle_had > 0:
		progress.collection[ArsenalCatalog.HOARFROST_MANTLE] = mantle_had


# --- 4: the card bench ------------------------------------------------------------------------------

func _check_bench(hero: ActorBase) -> void:
	var hud: PlayerHUD = level.huds.get(hero.player_id) as PlayerHUD
	hud.close_menu()
	await _frames(2)
	if not hud.open_binder():
		check.call(false, "the Binder opens for the card bench checks")
		return
	await _frames(3)
	var binder: GrimoireBinderPanel = hud.binder_panel()
	binder.show_tab(GrimoireBinderPanel.Tab.CARDS)
	await _frames(2)
	binder.show_guide()
	await _frames(2)
	var opened: bool = binder._guide != null
	hero.input.menu_input.emit(InputComponent.MENU_ACCEPT)
	await _frames(2)
	var closed: bool = binder._guide == null
	binder._select_socket(ScribeCardResource.DioramaSocket.SKILL)
	binder.open_layer(GrimoireBinderPanel.Layer.CARD)
	var options: Array[StringName] = binder.leaf_options()
	var wick_at: int = options.find(ArsenalCatalog.EMBER_WICK_CUT)
	var before: StringName = hero.loadout.kit.socket_leaf_id(GrimoireRules.SOCKET_R)
	binder.leaf_row = wick_at
	await _frames(2)
	var words: String = binder.spotlight_words(GrimoireBinderPanel.Layer.CARD, ArsenalCatalog.EMBER_WICK_CUT,
		binder.fit_verdict(GrimoireBinderPanel.Layer.CARD, ArsenalCatalog.EMBER_WICK_CUT))
	binder.accept()
	await _frames(3)
	var placed: bool = hero.loadout.kit.socket_leaf_id(GrimoireRules.SOCKET_R) == ArsenalCatalog.EMBER_WICK_CUT
	var cheer: String = binder.note_text()
	# Put the hero's R card back as it was.
	binder.open_layer(GrimoireBinderPanel.Layer.CARD)
	binder.leaf_row = maxi(0, binder.leaf_options().find(before))
	binder.accept()
	await _frames(3)
	binder.close()
	await _frames(2)
	check.call(opened and closed and wick_at >= 0 and words == "Light: put it in your R diamond!" and placed and cheer == "Ember-Wick Cut is in your R diamond!",
		"the card bench: the picture guide opens and light closes it; the starting Ember-Wick Cut waits in your cards, the spotlight says \"%s\", and light puts it in with \"%s\"" % [words, cheer])
