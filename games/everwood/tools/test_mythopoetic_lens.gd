## The Mythopoetic Lens's checks (15_THE_MYTHOPOETIC_LENS.md), run by
## tools/smoke_test.gd last, while the party stands in Oakshire Vale:
##   1  the four Linter Rules: no banned word in any name, blurb, quest or rhyme
##      the game shows (catalog, bestiary, places, townsfolk, atlas), and every
##      settlement, zone, delve and Place-Card a hyphenated Map-Sense compound
##      (-bridge, -green, -hollow, -falls, -haven, -wick or -crossing)
##   2  the atlas: six zones, each with its Cooper Sign, kin and four-line rhyme
##      whose coaching words are tinted by a Scribe Sign
##   3  the Hob-to-Boggart Spectrum, on spirits grown beside the village: a
##      curious hob's 6 m parley window runs 180 frames; waving the Truce-Sign
##      pays 25 Chimes and a pip and sets it dancing, and a soothed hob keeps
##      out of fights; striking one turns it boggart; a beaten padfoot flies
##      off a white sea-swallow; an Iron-Man fed a coal and turned right-way up
##      bows as a steward, while one left upside-down sinks back to sleep; a
##      spriggan curls into a mossy cairn; the Crag-Back Cairn-Drake holds its
##      blow through a 45-frame Challenge-Roar
##   4  the Chime-Post ribbon: crossing into Quarry-Wick unfurls the Iron-Men's
##      couplet, and a Hearth-Rite Tuck there sings the next one with "feed
##      him a coal" in Saffron-Gold, inside a glowing Saffron-Gold border
extends RefCounted

## Rule 4's grimy and textbook words, and the Lens's cut tropes, as whole words.
const BANNED_PATTERN: String = "(?i)\\b(runes?|aspects?|constructs?|wharfs?|silt|polders?|lamellar|hauberks?|cuirass(es)?|rubrics?|vermin|trash mobs?|minions?|goblins?|orcs?|lizards?|predators?|dojo shards?|aggro|factions?|loot drops?|undead|outlaws?|smugglers?)\\b"
## Rule 2's seven geographical nouns. One may sit inside the compound, as in Barley-Bridge-Meadow.
const MAP_SENSE: Array[String] = ["bridge", "green", "hollow", "falls", "haven", "wick", "crossing"]
## Places that aren't settlements or zones: a boss arena and a ring of the vale's terrain.
const NOT_SETTLEMENTS: Array[String] = ["The Ring of the Cairnsman", "The Settled Meadow"]
const VILLAGE: Vector3 = Vector3(768.0, 12.0, 778.0)
const SpiritState = HobSpectrumComponent.SpiritState

var tree: SceneTree
var check: Callable
var level: OakshireVale
var p1: ActorBase
var _spawners: Array[MobSpawner] = []


func run(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	_check_linter()
	_check_atlas()
	level = tree.current_scene as OakshireVale
	if level == null:
		check.call(false, "the Mythopoetic Lens checks run in Oakshire Vale")
		return
	for actor: ActorBase in CombatDirector.current.party_actors():
		if actor.is_local_player() and not actor.is_companion:
			p1 = actor
			break
	HobSpectrumComponent.enabled = true
	await _check_parley()
	await _check_unboggarting()
	await _check_challenge_roar()
	await _check_ribbon()
	for spawner: MobSpawner in _spawners:
		if is_instance_valid(spawner):
			spawner.queue_free()
	HobSpectrumComponent.enabled = false
	await tree.physics_frame


# --- 1: the four Linter Rules -------------------------------------------------------

func _check_linter() -> void:
	var shown: Array[String] = []
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	for card: ScribeCardResource in catalog.cards():
		shown.append_array([card.display_name, card.description])
	for item: EquipmentItemResource in catalog.armors() + catalog.weapons():
		shown.append_array([item.display_name, item.description])
	for encounter: BossEncounterResource in catalog.encounters():
		shown.append_array([encounter.display_name, encounter.hud_rhyme_couplet])
	for calling: CallingResource in catalog.callings():
		shown.append(calling.display_name)
	for creature: MobVariantResource in Bestiary.all():
		shown.append(creature.display_name)
	shown.append_array(Bestiary.FAMILY_NAMES)
	shown.append_array(Bestiary.CRITTER_NAMES)
	shown.append_array(WoodlandMinion.KIND_NAMES)
	shown.append_array([BossDummy.DISPLAY_NAME, BossDummy.BEAM_NAME, LandblockManifest.BORDER_NAME, EverwoodWorld.TITLE])
	shown.append_array(LandblockManifest.ZONE_NAMES)
	shown.append_array(DungeonDojo.ZONE_NAMES)
	shown.append_array(OakshireValeLayout.PETAL_NAMES)
	shown.append_array(OakshireVale.PETAL_LINES)
	for zone: StewardshipZoneResource in MythopoeticAtlas.all():
		shown.append_array([zone.display_name, zone.kin, zone.crack, zone.payoff])
		shown.append_array(Array(zone.rhyme_lines))
	var vale: OakshireVale = tree.current_scene as OakshireVale
	if vale != null:
		for npc: TownsfolkNPC in vale.townsfolk:
			shown.append_array([npc.npc_name, npc.title, npc.hub, npc.wares_note])
			shown.append_array(Array(npc.quests))
		for apron: PortalApron in vale.aprons:
			shown.append_array([apron.title, apron.blurb])
	var banned: RegEx = RegEx.create_from_string(BANNED_PATTERN)
	var offenders: Array[String] = []
	for text: String in shown:
		var found: RegExMatch = banned.search(text)
		if found != null:
			offenders.append("%s (%s)" % [text, found.get_string()])
	check.call(offenders.is_empty() and shown.size() > 250,
		"Linter Rule 4 and the Lens's cut tropes: none of %d names, blurbs, quests and rhymes says rune, aspect, vermin, minion, aggro or the like%s"
		% [shown.size(), "" if offenders.is_empty() else " (found: %s)" % "; ".join(offenders)])
	# Rules 2 and 3: settlements, zones, delves and Place-Cards are hyphenated Map-Sense compounds.
	var places: Array[String] = []
	for zone: StewardshipZoneResource in MythopoeticAtlas.all():
		places.append(zone.display_name)
	places.append_array(OakshireValeLayout.PETAL_NAMES)
	places.append_array(MythopoeticAtlas.PLACE_ZONES.keys())
	places.append_array(LandblockManifest.ZONE_NAMES)
	for card: ScribeCardResource in catalog.cards():
		if card.card_kind == ScribeCardResource.CardKind.LOCATION_PLACE:
			places.append(card.display_name)
	if vale != null:
		for apron: PortalApron in vale.aprons:
			places.append(apron.title)
	var unsound: Array[String] = []
	for place: String in places:
		if place == "" or NOT_SETTLEMENTS.has(place):
			continue
		var compound: bool = false
		for part: String in place.to_lower().replace(" ", "-").split("-"):
			compound = compound or MAP_SENSE.has(part)
		if not compound or not place.contains("-"):
			unsound.append(place)
	check.call(unsound.is_empty() and places.size() >= 25,
		"Linter Rules 2 and 3: all %d settlements, zones, delves and Place-Cards are hyphenated Map-Sense compounds (Bramble-Bridge, Quarry-Wick, Flagstone-Hollow...)%s"
		% [places.size(), "" if unsound.is_empty() else " (not: %s)" % ", ".join(unsound)])


# --- 2: the Six-Zone Stewardship Atlas -------------------------------------------------

func _check_atlas() -> void:
	var zones: Array[StewardshipZoneResource] = MythopoeticAtlas.all()
	var whole: bool = zones.size() == 6
	for zone: StewardshipZoneResource in zones:
		var tinted: bool = false
		for phrase: String in zone.tinted_phrases:
			tinted = tinted or "\n".join(zone.rhyme_lines).contains(phrase)
		whole = whole and zone.rhyme_lines.size() == 4 and zone.cooper_sign.begins_with("Sign of ") and zone.kin != "" \
			and not zone.harmony_signs.is_empty() and tinted
	var names: Array[String] = []
	for zone: StewardshipZoneResource in zones:
		names.append(zone.display_name)
	check.call(whole and ", ".join(names) == "Tizzi-Wed-Green, Gull-Wick-Haven, Barley-Bridge-Meadow, Rush-Light-Hollow, Barrow-Crag-Crossing, Sunken-Crown-Falls",
		"the Six-Zone Atlas: %s, each with its Cooper Sign, kin and a four-line rhyme tinted by Sign" % ", ".join(names))
	check.call(MythopoeticAtlas.zone_for_place("Quarry-Wick") == MythopoeticAtlas.BARLEY_BRIDGE_MEADOW
		and MythopoeticAtlas.zone_for_place("Nine-Stones-Crossing") == MythopoeticAtlas.BARROW_CRAG_CROSSING
		and MythopoeticAtlas.zone_for_place("Rush-Light-Hollow") == MythopoeticAtlas.RUSH_LIGHT_HOLLOW
		and MythopoeticAtlas.zone_for_place("Bramble-Bridge") == MythopoeticAtlas.TIZZI_WED_GREEN,
		"each built place sings its zone's rhyme: Quarry-Wick the Iron-Men's, Nine-Stones-Crossing the Cairn-Drakes', Bramble-Bridge Tizzi-Wed-Green's")


# --- 3: the Hob-to-Boggart Spectrum -----------------------------------------------------

func _check_parley() -> void:
	_place(p1, VILLAGE)
	await _frames(2)
	var hob: WildMob = await _grow(&"cider_thief_bristleboar", VILLAGE + Vector3(40.0, 0.0, 0.0))
	var hob_two: WildMob = await _grow(&"thorn_tail_scuttler", VILLAGE + Vector3(-40.0, 0.0, 0.0))
	if hob == null or hob_two == null:
		check.call(false, "curious hobs grow beside the village")
		return
	var spirit: HobSpectrumComponent = hob.spectrum
	check.call(spirit != null and spirit.equilibrium == HobSpectrumComponent.EquilibriumState.HOB_BENIGN and spirit.state == SpiritState.STATE_CURIOUS
		and hob.display_name() == "Bristle-Hob" and hob_two.spectrum.state == SpiritState.STATE_CURIOUS,
		"Oakshire's Curious Weald-Wights start HOB_BENIGN and STATE_CURIOUS (a Bristle-Hob, a Thorn-Tail Hedgerow-Hob)")
	# Walk up to the hob: a 180-frame window opens and light waves the Truce-Sign.
	_place(p1, hob.global_position + Vector3(0.0, 0.0, 2.0))
	await _frames(3)
	var point: HobSpectrumComponent.ParleyPoint = p1.interactable as HobSpectrumComponent.ParleyPoint
	var hud: PlayerHUD = level.huds.get(p1.player_id) as PlayerHUD
	var frames_open: int = point.window_frames(p1.player_id) if point != null else 0
	check.call(point != null and point.spirit == spirit and hud != null and hud.prompt_text().contains("Truce-Sign")
		and frames_open > HobSpectrumComponent.PARLEY_WINDOW_FRAMES - 6 and frames_open <= HobSpectrumComponent.PARLEY_WINDOW_FRAMES,
		"within 6 m a curious hob opens a 180-frame parley window and the HUD says light waves the Truce-Sign (%d frames left)" % frames_open)
	var chimes_before: int = PartyProgress.current.chimes
	p1.stats.resonance_charge = 0.0
	if point != null:
		point.interact(p1)
	await _frames(2)
	check.call(spirit.state == SpiritState.STATE_SOOTHED and PartyProgress.current.chimes == chimes_before + HobSpectrumComponent.PARLEY_CHIMES
		and is_equal_approx(p1.stats.resonance_charge, HobSpectrumComponent.PARLEY_PIPS) and p1.interactable != point,
		"waving the Truce-Sign soothes it: it dances (STATE_SOOTHED), the pouch gets 25 Chimes and the waver a pip, and it asks no more")
	# Its pack is fighting: an unsoothed hob would join in, a soothed one stays out.
	hob.spawner.alert = true
	hob._update_engagement(hob.spawn_transform.origin)
	check.call(not hob.engaged and spirit.state == SpiritState.STATE_SOOTHED, "a soothed hob keeps out of its pack's fights")
	# The second hob, held still: its window runs down a frame at a time and then shuts.
	hob_two.loadout.stats.move_speed = 0.0
	_place(p1, hob_two.global_position + Vector3(0.0, 0.0, 2.5))
	await _frames(3)
	var second: HobSpectrumComponent.ParleyPoint = p1.interactable as HobSpectrumComponent.ParleyPoint
	var early: int = second.window_frames(p1.player_id) if second != null else 0
	await _frames(30)
	var later: int = second.window_frames(p1.player_id) if second != null else 0
	if second != null:
		second.windows[p1.player_id] = 1
	await _frames(3)
	check.call(second != null and early - later >= 28 and early - later <= 32 and p1.interactable != second and second.window_frames(p1.player_id) == 0,
		"the window counts down one frame a tick (%d to %d in 30) and, run out, it shuts until you step away and back" % [early, later])
	# Striking a curious hob breaks the etiquette: it turns boggart.
	hob_two.stats.take_damage(5.0)
	await _frames(3)
	check.call(hob_two.spectrum.equilibrium == HobSpectrumComponent.EquilibriumState.BOGGART_AWOKEN and hob_two.spectrum.state == SpiritState.STATE_HOSTILE
		and hob_two.is_engaged(), "striking a curious hob turns it boggart (BOGGART_AWOKEN, STATE_HOSTILE) and it fights back")
	_place(p1, VILLAGE)
	hob_two.stats.take_damage(hob_two.stats.health + 1.0)
	await _frames(3)


func _check_unboggarting() -> void:
	var padfoot: WildMob = await _grow(&"grey_pelt_prowler", VILLAGE + Vector3(0.0, 0.0, 60.0))
	var iron_man: WildMob = await _grow(&"soot_paw_cutthroat", VILLAGE + Vector3(60.0, 0.0, 30.0))
	var sleeper: WildMob = await _grow(&"soot_paw_cutthroat", VILLAGE + Vector3(-60.0, 0.0, 30.0))
	var spriggan: WildMob = await _grow(&"risen_shield_sworn_husk", VILLAGE + Vector3(-60.0, 0.0, -30.0))
	if padfoot == null or iron_man == null or sleeper == null or spriggan == null:
		check.call(false, "awakened kin grow beside the village")
		return
	check.call(padfoot.spectrum.equilibrium == HobSpectrumComponent.EquilibriumState.BOGGART_AWOKEN and padfoot.spectrum.state == SpiritState.STATE_SLUMBER
		and padfoot.display_name() == "Grey Padfoot" and iron_man.display_name() == "Furrow Iron-Man" and spriggan.display_name() == "Moss-Shield Spriggan",
		"the other families are awakened kin (BOGGART_AWOKEN), in STATE_SLUMBER until they fight: a Grey Padfoot, a Furrow Iron-Man, a Moss-Shield Spriggan")
	padfoot.stats.take_damage(padfoot.stats.health + 1.0)
	await _frames(3)
	check.call(padfoot.spectrum.state == SpiritState.STATE_UNBOGGART_RELEASE and _fx_under(padfoot.spawner, "UnboggartRelease") != null,
		"a beaten padfoot leaves no body: its mist dissolves and a white sea-swallow wheels up (STATE_UNBOGGART_RELEASE)")
	# The Maker-Seal: upside-down, a Warm-Hearth strike opens the chest, an Iron-Root strike turns it.
	var spirit: HobSpectrumComponent = iron_man.spectrum
	var seal: Label3D = iron_man.get_node_or_null(^"MakerSeal") as Label3D
	var inverted: bool = spirit.has_maker_seal and not spirit.is_maker_seal_upright and seal != null and seal.text == "▼"
	_hit(iron_man, ScribeSignResource.Sign.SIGN_IRON_ROOT, false)
	await _frames(1)
	var shut_tight: bool = not spirit.is_maker_seal_upright and not spirit.is_maker_seal_exposed
	_hit(iron_man, ScribeSignResource.Sign.SIGN_WARM_HEARTH, true)
	await _frames(1)
	var exposed: bool = spirit.is_maker_seal_exposed and not spirit.is_maker_seal_upright
	_hit(iron_man, ScribeSignResource.Sign.SIGN_IRON_ROOT, false)
	await _frames(1)
	check.call(inverted and shut_tight and exposed and spirit.is_maker_seal_upright and seal.text == "▲",
		"an Iron-Man's Maker-Seal starts upside-down; Iron-Root alone can't reach it, a Warm-Hearth coat feeds him a coal and opens his chest, then Iron-Root turns it right-way up")
	iron_man.stats.take_damage(iron_man.stats.health + 1.0)
	sleeper.stats.take_damage(sleeper.stats.health + 1.0)
	await _frames(90)
	check.call(spirit.state == SpiritState.STATE_STEWARD_HELPER and spirit.is_steward() and iron_man.visual.visible and not iron_man.has_faded()
		and is_equal_approx(iron_man.visual.rotation.x, WildMob.STEWARD_BOW) and not iron_man.is_targetable(),
		"beaten with his seal upright, the Iron-Man bows as a steward for 600 s (STATE_STEWARD_HELPER): his body stays, friendly")
	check.call(sleeper.spectrum.state == SpiritState.STATE_UNBOGGART_RELEASE and not sleeper.visual.visible and _fx_under(sleeper.spawner, "UnboggartRelease") == null,
		"one beaten with his seal still upside-down just sinks back into the furrow to sleep")
	spriggan.stats.take_damage(spriggan.stats.health + 1.0)
	await _frames(3)
	var cairn: UnboggartFx = _fx_under(spriggan.spawner, "LulledCairn")
	check.call(spriggan.spectrum.state == SpiritState.STATE_LULLED_CAIRN and cairn != null and cairn.linger == HobSpectrumComponent.CAIRN_LINGER,
		"a beaten Crag-Spriggan curls back into a mossy cairn where it stood (STATE_LULLED_CAIRN)")


func _check_challenge_roar() -> void:
	var at: Vector3 = VILLAGE + Vector3(70.0, 0.0, -10.0)
	var drake: WildMob = await _grow(&"crag_back_behemoth", at, PackedVector3Array([at, at + Vector3(2.0, 0.0, 0.0)]))
	if drake == null:
		check.call(false, "the Crag-Back Cairn-Drake grows beside the village")
		return
	await _frames(5)
	_place(p1, drake.global_position + Vector3(0.0, 0.0, 8.0))
	var roared: bool = false
	var struck_in_roar: bool = false
	for frame: int in 20:
		await tree.physics_frame
		if drake.spectrum.is_roaring():
			roared = true
			struck_in_roar = struck_in_roar or drake.action_queue.is_busy()
	var roar_frames: int = 0
	while drake.spectrum.is_roaring() and roar_frames < 80:
		await tree.physics_frame
		roar_frames += 1
		struck_in_roar = struck_in_roar or drake.action_queue.is_busy()
	await _frames(2)
	check.call(roared and not struck_in_roar and drake.is_engaged() and drake.spectrum.state == SpiritState.STATE_HOSTILE,
		"walking up wakes the Crag-Back Cairn-Drake: a 45-frame Challenge-Roar first (no blow during it), then STATE_HOSTILE (roared %s, struck %s, engaged %s, state %s)"
		% [roared, struck_in_roar, drake.is_engaged(), SpiritState.keys()[drake.spectrum.state]])
	_place(p1, VILLAGE)
	drake.stats.take_damage(drake.stats.health + 1.0)
	await _frames(3)
	check.call(drake.spectrum.state == SpiritState.STATE_LULLED_CAIRN and _fx_under(drake.spawner, "LulledCairn") != null,
		"beaten, the Cairn-Drake is lulled into a mossy cairn")
	await _frames(20)


# --- 4: the Chime-Post ribbon and the Hearth-Rite border ----------------------------

func _check_ribbon() -> void:
	var hud: PlayerHUD = level.huds.get(p1.player_id) as PlayerHUD
	if hud == null:
		check.call(false, "player one has a HUD")
		return
	var grimoire: CrossGrimoireHUD = hud.cross_grimoire
	hud.enter_place("Quarry-Wick")
	await tree.process_frame
	await tree.process_frame
	var first: String = grimoire.ribbon_text()
	var first_tints: String = grimoire.ribbon_bbcode()
	var shown: bool = grimoire.get_node(^"ChimePostRibbon").visible
	check.call(first.contains("Deep in the furrow the Iron-Man sleeps") and first_tints.contains("[color=#") and shown
		and grimoire.ribbon_zone_id == MythopoeticAtlas.BARLEY_BRIDGE_MEADOW,
		"crossing into Quarry-Wick unfurls the Iron-Men's couplet on the Chime-Post ribbon, its coaching words tinted")
	SignFlowComponent.enabled = true
	await _frames(2)
	var tucked: bool = p1.sign_flow.begin_hearth_rite(ScribeCardResource.DioramaSocket.SKILL)
	await tree.process_frame
	var saffron: String = ArsenalCatalog.current.sign_seal(ScribeSignResource.Sign.SIGN_WARM_HEARTH).color.lightened(0.15).to_html(false)
	check.call(tucked and grimoire.ribbon_text().contains("feed him a coal") and grimoire.ribbon_bbcode().contains("[color=#%s]feed him a coal" % saffron)
		and grimoire.hearth_rite_border_lit(),
		"a Hearth-Rite Tuck there sings the next couplet, \"feed him a coal\" in Saffron-Gold, and a Saffron-Gold ember border glows round the cell")
	SignFlowComponent.enabled = false


# --- Helpers ----------------------------------------------------------------------------

## Grows one spirit from a fresh spawner at `at` (on the ground), and keeps the spawner to free later.
func _grow(variant_id: StringName, at: Vector3, patrol: PackedVector3Array = PackedVector3Array()) -> WildMob:
	var spawner: MobSpawner = MobSpawner.new()
	spawner.name = "LensSpawner%d" % _spawners.size()
	spawner.territory = "Oakshire-Wick"
	spawner.variant_ids = [variant_id]
	spawner.leash = 25.0
	spawner.patrol = patrol
	level.add_child(spawner)
	spawner.global_position = Vector3(at.x, WorldGridConfig.layout.sample_height(at.x, at.z), at.z)
	_spawners.append(spawner)
	spawner.spawn_mobs()
	await _frames(3)
	return spawner.mobs[0] if not spawner.mobs.is_empty() else null


func _place(actor: ActorBase, at: Vector3) -> void:
	actor.place_at(Transform3D(Basis.IDENTITY, Vector3(at.x, WorldGridConfig.layout.sample_height(at.x, at.z) + 0.2, at.z)))


## A strike on `target` reported as resolved, carrying `sign_id` in its card (or as a coat).
func _hit(target: ActorBase, sign_id: int, as_coat: bool) -> void:
	var event: CombatEvent = CombatEvent.new()
	event.target_path = target.get_path()
	event.attacker_player_id = p1.player_id
	if as_coat:
		event.coat_sign = sign_id
	else:
		event.scribe_sign = sign_id
	CombatDirector.current.hit_resolved.emit(event, StatsComponent.StrikeOutcome.HIT)


func _fx_under(holder: Node, prefix: String) -> UnboggartFx:
	for child: Node in holder.get_children():
		if child is UnboggartFx and String(child.name).begins_with(prefix):
			return child as UnboggartFx
	return null


func _frames(count: int) -> void:
	for frame: int in count:
		await tree.physics_frame
