## The Lead Card + Under-Card Composition Resolver (05_ARSENAL_AND_CARDS_GDD.md
## §3.1, §4.1). It turns a class (as one of its Callings) and an equipment kit
## into the ClassLoadoutResource an actor runs:
##   armor      → stats: mitigation, stamina regen, roll distance, Perfect Guard window
##   Calling    → adds to those, and scales every action's damage, poise and healing
##                (Callings, 07 GDD §1.3); it also decides which gear is allowed
##   weapon     → the Light chain and the Heavy (a Heavy always detonates seals)
##   lead card  → its posture's action, channelled through the weapon: melee
##                weapons swing it with a ribbon trail; ranged weapons fire it
##                as a rune projectile out to the weapon's card range
##   under-card → one verb changes that action (infusion, surge or echo)
##   empty R / L+R → the weapon's Un-Inked Martial Flourish (11 GDD §4.1)
## Every hero strike also gets its posture's step (ActorBase.STEP_*) and its
## kind of blow's hit-stop (CombatDirector.HIT_STOP_*), and R and L+R strikes
## detonate a teammate's seal (11_COMBAT_ONBOARDING_AND_FEEL_GDD.md §3-4).
## Deterministic: the same class and kit give the same actions with the same
## ids on every peer, which is what lets the network name actions by id.
##
## It also holds the Grimoire's rules (what a kit may hold), which the Binder and
## the Scribe Desk follow and the host checks again. Since the seven-card hand
## (22 GDD R4, R5) a hero's own Character Level opens its sockets: R at Lv 4, L
## at 6, L+R at 17, and one Tuck (an under-card beneath R or L+R) at 11; a
## locked socket plays the weapon's own flourish. Grimoire Memory is gone. The
## older checks' classic full kits (GrimoireRules.all_open) keep the old rules.
class_name LoadoutComposer
extends RefCounted

## Potency Surge multiplies damage, healing and poise by this.
const UNDER_POTENCY_MULTIPLIER: float = 1.2
## Hearth Echo: a heal bounces this share to the next most hurt friend...
const ECHO_HEAL_RATIO: float = 0.5
## ...a strike gives back this much stamina on a hit...
const ECHO_STAMINA_ON_HIT: float = 8.0
## ...and a sanctuary restores this much stamina a second to allies inside.
const ECHO_ZONE_STAMINA_PER_SECOND: float = 8.0
const MAX_GRIMOIRE_LEVEL: int = 5
## Grimoire Memory is this plus MEMORY_PER_LEVEL per level (6 at level 1, 14 at 5).
const BASE_MEMORY: int = 4
const MEMORY_PER_LEVEL: int = 2
const GUARD_LABEL: String = "hold: Guard"
## How each slot appears in action ids ("card/forward/rising_drive").
const SLOT_KEYS: Array[String] = ["forward", "back", "signature", "ultimate"]
## However a Calling and armor combine, stamina always comes back at least this fast.
const MIN_STAMINA_REGEN: float = 6.0
## Un-Inked Martial Flourishes (11 GDD §4.1), by WeaponType (Falchion, Broad-Axe,
## Way-Staff, Longbow): damage as a multiple of the weapon's Heavy, poise (times
## the tier's multiplier) and the step it takes.
const FLOURISH_DAMAGE: Array[float] = [1.6, 1.8, 1.4, 1.7]
const FLOURISH_POISE: Array[float] = [15.0, 28.0, 10.0, 20.0]
const FLOURISH_STEP: Array[float] = [1.8, 1.5, 0.0, -1.5]
## L+R's flourish hits this much harder, with twice the poise, all around the hero
## after a heroic surge forward.
const ULT_FLOURISH_MULTIPLIER: float = 1.75
const ULT_FLOURISH_STEP: float = 2.0
## The Way-Staff's flourishes mend the most hurt ally this close.
const STAFF_FLOURISH_HEAL: float = 10.0
const STAFF_ULT_FLOURISH_HEAL: float = 25.0
const STAFF_FLOURISH_HEAL_RADIUS: float = 8.0

const Fx = CombatActionResource.Effect


static func compose(player_class: PlayerClassResource, requested: EquipmentLoadoutResource) -> ClassLoadoutResource:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var kit: EquipmentLoadoutResource = gated(sanitized(player_class, requested), hero_level(player_class.class_id))
	var armor: EquipmentItemResource = catalog.item(kit.armor_id)
	var weapon: EquipmentItemResource = catalog.item(kit.weapon_id)
	var loadout: ClassLoadoutResource = ClassLoadoutResource.new()
	loadout.class_id = player_class.class_id
	loadout.display_name = player_class.display_name
	loadout.calling = player_class.calling
	loadout.fellowship_name = player_class.fellowship_name
	loadout.calling_subtitle = player_class.calling_subtitle
	loadout.role = player_class.role
	loadout.body_color = player_class.body_color
	loadout.has_soul_tethers = player_class.has_soul_tethers
	loadout.guard_on_trigger_l = true
	loadout.kit = kit
	loadout.weapon = weapon
	loadout.armor = armor
	loadout.stats = _stats_with_armor(player_class, armor)
	loadout.dodge = catalog.dodge_template()

	var lights: Array[CombatActionResource] = []
	for template: CombatActionResource in weapon.light_chain:
		lights.append(_weapon_action(weapon, template))
	var heavy: CombatActionResource = _weapon_action(weapon, weapon.heavy)
	heavy.detonates = true
	var cards: Array[CombatActionResource] = []
	for slot: int in EquipmentLoadoutResource.SLOT_COUNT:
		var lead: ScribeCardResource = catalog.card(kit.lead_ids[slot])
		var action: CombatActionResource = _flourish_action(weapon, slot) if lead == null else _card_action(lead, slot, weapon)
		if lead != null:
			_apply_finish(action, kit.lead_variants[slot])
		var under: ScribeCardResource = catalog.card(kit.under_ids[slot])
		if under != null and under.is_under():
			apply_under(action, under)
		cards.append(action)
	_apply_ink_well(loadout, kit, cards, player_class)
	_link_flows(lights, heavy, cards)
	for action: CombatActionResource in lights + [heavy] + cards:
		_apply_calling(action, player_class)
		_apply_kinetics(action)

	loadout.openers.append(lights[0])
	loadout.openers.append(heavy)
	loadout.openers.append_array(cards)
	loadout.combo_actions.assign(lights.slice(1))
	loadout.trigger_l_label = GUARD_LABEL
	loadout.forward_label = _label(cards[ScribeCardResource.GrimoireSlot.FORWARD])
	loadout.back_label = _label(cards[ScribeCardResource.GrimoireSlot.BACK])
	loadout.trigger_r_label = _label(cards[ScribeCardResource.GrimoireSlot.SIGNATURE])
	loadout.ult_label = _label(cards[ScribeCardResource.GrimoireSlot.ULTIMATE])
	return loadout


## A Fellowship's hero's Character Level (Lv 20 where there's no party, in tools).
static func hero_level(class_id: StringName) -> int:
	return PartyProgress.current.character_level(class_id) if PartyProgress.current != null else PartyProgress.MAX_CHARACTER_LEVEL


## The kit as a hero of `level` may wear it (22 GDD R4): a socket the level hasn't
## opened holds no card, and the one Tuck sits under R or L+R from Lv 11 (R's
## first if both were set). The Forward and Back cards are the Fellowship's
## stance moves and keep no under-card. Unchanged under the classic full kits.
static func gated(kit: EquipmentLoadoutResource, level: int) -> EquipmentLoadoutResource:
	if GrimoireRules.all_open():
		return kit
	var worn: EquipmentLoadoutResource = kit.copy()
	const Slot = ScribeCardResource.GrimoireSlot
	if not GrimoireRules.socket_open(GrimoireRules.SOCKET_R, level):
		worn.lead_ids[Slot.SIGNATURE] = &""
	if not GrimoireRules.socket_open(GrimoireRules.SOCKET_LR, level):
		worn.lead_ids[Slot.ULTIMATE] = &""
	if not GrimoireRules.socket_open(GrimoireRules.SOCKET_L, level):
		worn.guard_leaf_id = &""
	worn.under_ids[Slot.FORWARD] = &""
	worn.under_ids[Slot.BACK] = &""
	var tuck_slot: int = tuck_slot_of(worn)
	for slot: int in [Slot.SIGNATURE, Slot.ULTIMATE]:
		if slot != tuck_slot or not GrimoireRules.tuck_open(level) or worn.lead_ids[slot] == &"":
			worn.under_ids[slot] = &""
	return worn


## Which slot the kit's Tuck sits under: R's (SIGNATURE) if it has one, else L+R's, else -1.
static func tuck_slot_of(kit: EquipmentLoadoutResource) -> int:
	const Slot = ScribeCardResource.GrimoireSlot
	if kit.under_ids[Slot.SIGNATURE] != &"":
		return Slot.SIGNATURE
	if kit.under_ids[Slot.ULTIMATE] != &"":
		return Slot.ULTIMATE
	return -1


## The three socket cards the hero wears (L, R, L+R), &"" where empty.
static func socket_cards(kit: EquipmentLoadoutResource) -> Array[StringName]:
	const Slot = ScribeCardResource.GrimoireSlot
	return [kit.guard_leaf_id, kit.lead_ids[Slot.SIGNATURE], kit.lead_ids[Slot.ULTIMATE]]


## A copy of `requested` with anything unknown, misplaced or not allowed by
## the Calling swapped for the class's starter choice, so a stale save or a bad
## packet can't break an actor.
static func sanitized(player_class: PlayerClassResource, requested: EquipmentLoadoutResource) -> EquipmentLoadoutResource:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var starter: EquipmentLoadoutResource = player_class.starter_kit
	var kit: EquipmentLoadoutResource = (requested if requested != null else starter).copy()
	var armor: EquipmentItemResource = catalog.item(kit.armor_id)
	if armor == null or not armor.is_armor() or not player_class.allows(armor):
		kit.armor_id = starter.armor_id
	var weapon: EquipmentItemResource = catalog.item(kit.weapon_id)
	if weapon == null or not weapon.is_weapon() or not player_class.allows(weapon):
		kit.weapon_id = starter.weapon_id
	for slot: int in EquipmentLoadoutResource.SLOT_COUNT:
		if kit.lead_ids[slot] == &"" and can_stay_uninked(slot):
			kit.lead_variants[slot] = ScribeCardResource.CardVariant.STANDARD
		elif not fits_slot(player_class, catalog.card(kit.lead_ids[slot]), slot):
			kit.lead_ids[slot] = starter.lead_ids[slot]
			kit.lead_variants[slot] = ScribeCardResource.CardVariant.STANDARD
		var under: ScribeCardResource = catalog.card(kit.under_ids[slot])
		if under == null or not under.is_under():
			kit.under_ids[slot] = &""
	# The diorama layer (14 GDD §4): L's leaf must suit the class, frames must be Place-Cards.
	var guard_leaf: ScribeCardResource = catalog.card(kit.guard_leaf_id)
	if guard_leaf == null or not fits_diorama(player_class, guard_leaf):
		kit.guard_leaf_id = &""
		kit.guard_leaf_variant = ScribeCardResource.CardVariant.STANDARD
	for socket: int in EquipmentLoadoutResource.SOCKET_COUNT:
		var place: ScribeCardResource = catalog.card(kit.place_ids[socket])
		if place == null or not place.is_place_card():
			kit.place_ids[socket] = &""
			kit.place_variants[socket] = ScribeCardResource.CardVariant.STANDARD
	return kit


## Whether an Action-Leaf can stand in a diorama socket for this class (any slot's leaf will do in L).
static func fits_diorama(player_class: PlayerClassResource, leaf: ScribeCardResource) -> bool:
	return leaf != null and leaf.is_action_leaf() and (player_class.has_soul_tethers or not leaf.needs_soul_tether)


## R and L+R may be left empty: they fire the weapon's Un-Inked Martial Flourish.
static func can_stay_uninked(slot: int) -> bool:
	return slot == ScribeCardResource.GrimoireSlot.SIGNATURE or slot == ScribeCardResource.GrimoireSlot.ULTIMATE


## Whether a lead card can sit in a slot for this class.
static func fits_slot(player_class: PlayerClassResource, lead: ScribeCardResource, slot: int) -> bool:
	return lead != null and lead.is_lead() and lead.slot == slot and (player_class.has_soul_tethers or not lead.needs_soul_tether)


## One under-card verb applied to the lead card's action above it.
static func apply_under(action: CombatActionResource, under: ScribeCardResource) -> void:
	match under.verb:
		ScribeCardResource.UnderVerb.SIGN_INFUSION:
			if action.effect == Fx.STRIKE:
				action.primer = under.scribe_sign
			action.scribe_sign = under.scribe_sign
		ScribeCardResource.UnderVerb.POTENCY_SURGE:
			action.damage *= UNDER_POTENCY_MULTIPLIER
			action.heal_amount *= UNDER_POTENCY_MULTIPLIER
			action.poise_damage *= UNDER_POTENCY_MULTIPLIER
		ScribeCardResource.UnderVerb.HEARTH_ECHO:
			match action.effect:
				Fx.HOMING_HEAL:
					action.echo_heal_ratio = ECHO_HEAL_RATIO
				Fx.GREEN_SANCTUARY, Fx.SHADOW_SANCTUARY:
					action.zone_stamina_per_second = ECHO_ZONE_STAMINA_PER_SECOND
				Fx.STRIKE:
					action.echo_stamina_on_hit = ECHO_STAMINA_ON_HIT


# --- Grimoire rules -------------------------------------------------------

## Each victory raises the Grimoire a level, up to 5.
static func grimoire_level(victories: int) -> int:
	return clampi(1 + victories, 1, MAX_GRIMOIRE_LEVEL)


## Grimoire Memory at a level, plus any the Calling adds (a Wise Hand holds one more).
static func memory_capacity(level: int, bonus: int = 0) -> int:
	return BASE_MEMORY + MEMORY_PER_LEVEL * level + bonus


## Under-Card link slots open one per level after the first.
static func under_slots(level: int) -> int:
	return clampi(level - 1, 0, EquipmentLoadoutResource.SLOT_COUNT)


static func memory_used(kit: EquipmentLoadoutResource) -> int:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var used: int = 0
	for slot: int in EquipmentLoadoutResource.SLOT_COUNT:
		var lead: ScribeCardResource = catalog.card(kit.lead_ids[slot])
		var under: ScribeCardResource = catalog.card(kit.under_ids[slot])
		used += lead.memory_cost() if lead != null else 0
		used += under.memory_cost() if under != null else 0
	return used


## Whether the party owns enough copies: starter cards are free in Standard;
## anything else needs a collected copy per use.
static func owns(copy_key: StringName, uses: int, collection: Dictionary[StringName, int]) -> bool:
	var owned: ScribeCardResource = ArsenalCatalog.current.card(ScribeCardResource.copy_card_id(copy_key))
	if owned == null:
		return false
	if owned.starter and ScribeCardResource.copy_variant(copy_key) == ScribeCardResource.CardVariant.STANDARD:
		return true
	return collection.get(copy_key, 0) >= uses


## Whether an Under-Card link is open: none before the trail reaches
## UNDER_TUCK_LEVEL; then the one beneath R, plus one per Grimoire level after the first.
static func under_link_open(slot: int, level: int, trail_level: int = ArsenalCatalog.MAX_TRAIL_LEVEL) -> bool:
	if trail_level < ArsenalCatalog.UNDER_TUCK_LEVEL:
		return false
	return slot < under_slots(level) or slot == ScribeCardResource.GrimoireSlot.SIGNATURE


## Why this kit can't be equipped at this Grimoire level (and party trail
## level, 11 GDD §5), or "" when it can.
static func kit_problem(player_class: PlayerClassResource, kit: EquipmentLoadoutResource, level: int,
		collection: Dictionary[StringName, int], trail_level: int = ArsenalCatalog.MAX_TRAIL_LEVEL) -> String:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	for item_id: StringName in [kit.armor_id, kit.weapon_id]:
		var item: EquipmentItemResource = catalog.item(item_id)
		if item != null and not player_class.allows(item):
			var unlock: int = Callings.unlocked_by(item)
			return "%s needs a %s Calling" % [item.display_name, Callings.secondary_label(unlock)] if unlock >= 0 else "That doesn't fit this class"
		if item != null and item.required_level > trail_level:
			return "%s opens at Level %d" % [item.display_name, item.required_level]
	if not sanitized(player_class, kit).same_as(kit):
		return "That doesn't fit this class"
	var uses: Dictionary[StringName, int] = {}
	for slot: int in EquipmentLoadoutResource.SLOT_COUNT:
		if kit.lead_ids[slot] != &"":
			var lead_key: StringName = kit.lead_copy_key(slot)
			uses[lead_key] = uses.get(lead_key, 0) + 1
		if kit.under_ids[slot] != &"":
			if GrimoireRules.all_open():
				if trail_level < ArsenalCatalog.UNDER_TUCK_LEVEL:
					return "Under-Card links open at Level %d" % ArsenalCatalog.UNDER_TUCK_LEVEL
				if not under_link_open(slot, level, trail_level):
					return "Under-Card link %d opens at Grimoire Lv %d" % [slot + 1, slot + 2]
			else:
				if slot != ScribeCardResource.GrimoireSlot.SIGNATURE and slot != ScribeCardResource.GrimoireSlot.ULTIMATE:
					return "The Tuck goes under R or L+R"
				if not GrimoireRules.tuck_open(hero_level(player_class.class_id)):
					return "The Tuck opens at Lv %d" % GrimoireRules.TUCK_OPEN_LEVEL
				if slot == ScribeCardResource.GrimoireSlot.ULTIMATE and kit.under_ids[ScribeCardResource.GrimoireSlot.SIGNATURE] != &"":
					return "Only one Tuck: take it from under R first"
			uses[kit.under_ids[slot]] = uses.get(kit.under_ids[slot], 0) + 1
	# The diorama's own copies (they take no Grimoire Memory): L's leaf needs a
	# copy of its own; one charted Place-Card can frame every socket.
	if kit.guard_leaf_id != &"":
		var guard_key: StringName = ScribeCardResource.copy_key(kit.guard_leaf_id, kit.socket_leaf_variant(ScribeCardResource.DioramaSocket.GUARD))
		uses[guard_key] = uses.get(guard_key, 0) + 1
	for socket: int in EquipmentLoadoutResource.SOCKET_COUNT:
		if kit.place_ids[socket] != &"":
			uses[ScribeCardResource.copy_key(kit.place_ids[socket], kit.socket_place_variant(socket))] = 1
	for key: StringName in uses:
		if not owns(key, uses[key], collection):
			var missing: ScribeCardResource = catalog.card(ScribeCardResource.copy_card_id(key))
			return "Not in the binder: %s (%s)" % [missing.display_name if missing != null else String(key),
				ScribeCardResource.VARIANT_NAMES[ScribeCardResource.copy_variant(key)]]
	if GrimoireRules.all_open():
		# The classic full kits keep the old Grimoire Memory rule (the older checks).
		var used: int = memory_used(kit)
		var capacity: int = memory_capacity(level, player_class.bonus_memory)
		if used > capacity:
			return "Needs %d Grimoire Memory (Lv %d holds %d)" % [used, level, capacity]
		return ""
	# The seven-card hand (22 GDD R4, R5): one card per socket, one Tuck, seven different titles.
	var twice: StringName = GrimoireRules.duplicate_title(socket_cards(kit))
	if twice != &"":
		var worn_twice: ScribeCardResource = catalog.card(twice)
		return "%s is already in another socket" % (worn_twice.display_name if worn_twice != null else String(twice))
	return ""


# --- The Ink-Well (22 GDD R1) -----------------------------------------------

## A hero in play runs on the Ink-Well: the well as deep as its stage (and Wise Hand)
## allows, R's card costing 1 drop (2 for a mid-tier card or under its Tuck) and
## L+R's 3. Unchanged under the classic full kits the older checks use.
static func _apply_ink_well(loadout: ClassLoadoutResource, kit: EquipmentLoadoutResource, cards: Array[CombatActionResource],
		player_class: PlayerClassResource) -> void:
	if GrimoireRules.all_open() or PartyProgress.current == null:
		return
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var level: int = hero_level(player_class.class_id)
	loadout.stats.ink_well = true
	loadout.stats.max_resonance_pips = GrimoireRules.well_depth(PlayerLoadoutResource.stage_for_true_level(level), player_class.bonus_memory > 0)
	const Slot = ScribeCardResource.GrimoireSlot
	var r_card: ScribeCardResource = catalog.card(kit.lead_ids[Slot.SIGNATURE])
	if r_card != null:
		cards[Slot.SIGNATURE].resonance_cost = GrimoireRules.ink_cost(GrimoireRules.SOCKET_R, r_card, kit.under_ids[Slot.SIGNATURE] != &"")
	if catalog.card(kit.lead_ids[Slot.ULTIMATE]) != null:
		cards[Slot.ULTIMATE].resonance_cost = GrimoireRules.COST_GRAND


# --- Building actions -----------------------------------------------------

static func _stats_with_armor(player_class: PlayerClassResource, armor: EquipmentItemResource) -> CharacterStatsResource:
	var stats: CharacterStatsResource = player_class.base_stats.duplicate() as CharacterStatsResource
	stats.damage_mitigation = armor.mitigation
	stats.stamina_regen_per_sec = maxf(MIN_STAMINA_REGEN, armor.stamina_regen_per_sec + player_class.stamina_regen_bonus)
	stats.roll_distance = armor.roll_distance
	stats.perfect_guard_window = armor.perfect_guard_window + player_class.perfect_guard_bonus
	stats.can_perfect_guard = true
	return stats


## The Secondary Calling's potency: harder strikes, heavier poise hits, stronger heals.
static func _apply_calling(action: CombatActionResource, player_class: PlayerClassResource) -> void:
	if action.effect == Fx.STRIKE:
		action.damage *= player_class.strike_damage_multiplier
	action.poise_damage *= player_class.poise_damage_multiplier
	action.heal_amount *= player_class.heal_multiplier


static func _weapon_action(weapon: EquipmentItemResource, template: CombatActionResource) -> CombatActionResource:
	var action: CombatActionResource = template.duplicate() as CombatActionResource
	action.action_id = StringName("%s/%s" % [weapon.item_id, template.action_id])
	action.flow_links = []
	if action.is_projectile():
		action.projectile_look = weapon.item_id
		action.projectile_radius = weapon.projectile_radius
	return action


static func _card_action(lead: ScribeCardResource, slot: int, weapon: EquipmentItemResource) -> CombatActionResource:
	var action: CombatActionResource = lead.template.duplicate() as CombatActionResource
	action.action_id = StringName("card/%s/%s" % [SLOT_KEYS[slot], lead.card_id])
	action.command = ScribeCardResource.SLOT_COMMANDS[slot] as CombatActionResource.Command
	action.card_id = lead.card_id
	action.grimoire_slot = slot
	action.scribe_sign = lead.scribe_sign
	action.flow_links = []
	if lead.delivery == ScribeCardResource.Delivery.THROUGH_WEAPON and action.effect == Fx.STRIKE:
		_channel_through(action, weapon)
	if action.effect == Fx.GREEN_SANCTUARY or action.effect == Fx.SHADOW_SANCTUARY:
		action.effect_radius *= weapon.support_radius_multiplier
	return action


## A finer finish's potency (14 GDD §8): Gilded Leaf +10%, Star-Inked Vellum +20%
## to the card's damage, poise and heals. Every peer composes the same kit, so
## every peer gets the same numbers.
static func _apply_finish(action: CombatActionResource, variant: int) -> void:
	var potency: float = ScribeCardResource.finish_potency(variant)
	if is_equal_approx(potency, 1.0):
		return
	action.damage *= potency
	action.poise_damage *= potency
	action.heal_amount *= potency


## Martial Imbuement's un-inked half (11 GDD §4.1): R (1 pip) or L+R (3 pips)
## with no card slotted swings the weapon itself, harder than a Heavy and with
## no seal. The Falchion lunges through an X-slash, the Broad-Axe leaps into a
## slam, the Longbow vaults back and looses a piercing bodkin, and the Way-Staff
## sweeps a warm gust that mends the most hurt ally near you. L+R surges
## forward first and lands it all around you.
static func _flourish_action(weapon: EquipmentItemResource, slot: int) -> CombatActionResource:
	var ult: bool = slot == ScribeCardResource.GrimoireSlot.ULTIMATE
	var kind: int = weapon.weapon_type
	var action: CombatActionResource = CombatActionResource.new()
	action.action_id = StringName("uninked/%s/%s" % [SLOT_KEYS[slot], weapon.item_id])
	action.display_name = weapon.uninked_ult_name if ult else weapon.uninked_r_skill_name
	action.command = ScribeCardResource.SLOT_COMMANDS[slot] as CombatActionResource.Command
	action.effect = Fx.STRIKE
	action.grimoire_slot = slot
	action.uninked = true
	action.stamina_cost = 0.0
	action.resonance_cost = 3 if ult else 1
	action.resonance_gain = 0.0
	action.windup_time = 0.3 if ult else 0.2
	action.active_time = 0.28 if ult else 0.2
	action.recovery_time = 0.32 if ult else 0.24
	action.damage = weapon.heavy.damage * FLOURISH_DAMAGE[kind] * (ULT_FLOURISH_MULTIPLIER if ult else 1.0)
	action.poise_damage = FLOURISH_POISE[kind] * weapon.damage_multiplier * (2.0 if ult else 1.0)
	action.lunge_distance = ULT_FLOURISH_STEP if ult else FLOURISH_STEP[kind]
	action.reach = 0.0 if ult else 1.8
	action.hit_radius = 3.2 if ult else 1.8
	match kind:
		EquipmentItemResource.WeaponType.HEAVY_AXE:
			action.reach = 0.0 if ult else 1.4
			action.hit_radius = 3.5 if ult else 2.2
		EquipmentItemResource.WeaponType.STAFF:
			action.reach = 0.0 if ult else 1.5
			action.hit_radius = 4.0 if ult else 3.0
			action.heal_amount = STAFF_ULT_FLOURISH_HEAL if ult else STAFF_FLOURISH_HEAL
			action.effect_radius = STAFF_FLOURISH_HEAL_RADIUS
		EquipmentItemResource.WeaponType.BOW:
			action.delivery = CombatActionResource.Delivery.PROJECTILE
			action.projectile_range = weapon.card_range
			action.projectile_speed = weapon.projectile_speed
			action.projectile_radius = weapon.projectile_radius * (2.0 if ult else 1.4)
			action.projectile_look = weapon.item_id
			action.pierces = true
			if ult:
				action.lunge_distance = 0.0
	action.trail = not action.is_projectile()
	return action


## The kinetic loop and the hit-stop ladder (11 GDD §3.1, §4.2) on a hero strike:
## a melee swing with no lunge of its own steps along its posture (projectiles
## plant, except Back+Heavy's back-hop, which every strike takes); R and L+R
## detonate a teammate's seal; and the freeze on a hit is 50 ms for a Light,
## 100 for a Heavy or flourish, 140 for an inked card.
static func _apply_kinetics(action: CombatActionResource) -> void:
	if action.effect != Fx.STRIKE:
		return
	var planted: bool = action.is_projectile() or not is_zero_approx(action.lunge_distance)
	match action.command:
		CombatActionResource.Command.LIGHT:
			if not planted:
				action.lunge_distance = ActorBase.STEP_LIGHT_M
		CombatActionResource.Command.HEAVY:
			if not planted:
				action.lunge_distance = ActorBase.STEP_HEAVY_M
		CombatActionResource.Command.FORWARD_HEAVY:
			if not planted:
				action.lunge_distance = ActorBase.STEP_FORWARD_HEAVY_M
		CombatActionResource.Command.BACK_HEAVY:
			action.lunge_distance = minf(action.lunge_distance, ActorBase.STEP_BACK_HEAVY_M)
	if action.is_skill():
		action.detonates = true
	var freeze: float = CombatDirector.HIT_STOP_LIGHT
	if action.is_card():
		freeze = CombatDirector.HIT_STOP_CARD
	elif action.uninked or action.is_heavy_family():
		freeze = CombatDirector.HIT_STOP_HEAVY
	action.hit_stop_scale = freeze / CombatDirector.BASE_HIT_STOP


## "The Weapon Channels the Card": a ranged weapon fires the card as a rune
## projectile (you plant and cast, so forward lunges go; backward steps stay);
## a melee weapon swings it with a ribbon trail.
static func _channel_through(action: CombatActionResource, weapon: EquipmentItemResource) -> void:
	if weapon.is_ranged():
		action.delivery = CombatActionResource.Delivery.PROJECTILE
		action.projectile_range = weapon.card_range
		action.projectile_speed = weapon.projectile_speed
		action.projectile_radius = weapon.projectile_radius
		action.projectile_look = weapon.item_id
		action.lunge_distance = minf(action.lunge_distance, 0.0)
	else:
		action.trail = true


## Each light flows into the next swing, the Heavy, the movement cards, R and
## L+R (11 GDD §3.1: the skills chain from any Flow-Link window); the Heavy and
## cards flow back into the chain. Ultimates end a combo.
static func _link_flows(lights: Array[CombatActionResource], heavy: CombatActionResource, cards: Array[CombatActionResource]) -> void:
	var forward: CombatActionResource = cards[ScribeCardResource.GrimoireSlot.FORWARD]
	var back: CombatActionResource = cards[ScribeCardResource.GrimoireSlot.BACK]
	var signature: CombatActionResource = cards[ScribeCardResource.GrimoireSlot.SIGNATURE]
	var ultimate: CombatActionResource = cards[ScribeCardResource.GrimoireSlot.ULTIMATE]
	for index: int in lights.size():
		var links: Array[CombatActionResource] = []
		if index < lights.size() - 1:
			links.append(lights[index + 1])
		links.append_array([heavy, forward, back, signature, ultimate])
		lights[index].flow_links = _ids(links)
	heavy.flow_links = _ids([lights[0], forward, back, signature, ultimate])
	forward.flow_links = _ids([lights[0], back, signature, ultimate])
	back.flow_links = _ids([lights[0], forward, signature, ultimate])
	signature.flow_links = _ids([lights[0]])


static func _ids(actions: Array[CombatActionResource]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for action: CombatActionResource in actions:
		ids.append(action.action_id)
	return ids


static func _label(action: CombatActionResource) -> String:
	if action.resonance_cost <= 0:
		return action.display_name
	return "%s (%d pip%s)" % [action.display_name, action.resonance_cost, "" if action.resonance_cost == 1 else "s"]
