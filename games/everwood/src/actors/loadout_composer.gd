## The Lead Card + Under-Card Composition Resolver (05_ARSENAL_AND_CARDS_GDD.md
## §3.1, §4.1). It turns a class and an equipment kit into the
## ClassLoadoutResource an actor runs:
##   armor      → stats: mitigation, stamina regen, roll distance, Perfect Guard window
##   weapon     → the Light chain and the Heavy (a Heavy always detonates seals)
##   lead card  → its posture's action, channelled through the weapon: melee
##                weapons swing it with a ribbon trail; ranged weapons fire it
##                as a rune projectile out to the weapon's card range
##   under-card → one verb changes that action (infusion, surge or echo)
## Deterministic: the same class and kit give the same actions with the same
## ids on every peer, which is what lets the network name actions by id.
##
## It also holds the Grimoire's rules (levels, memory, what a kit may hold),
## which the Scribe Desk follows and the host checks again.
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

const Fx = CombatActionResource.Effect


static func compose(player_class: PlayerClassResource, requested: EquipmentLoadoutResource) -> ClassLoadoutResource:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var kit: EquipmentLoadoutResource = sanitized(player_class, requested)
	var armor: EquipmentItemResource = catalog.item(kit.armor_id)
	var weapon: EquipmentItemResource = catalog.item(kit.weapon_id)
	var loadout: ClassLoadoutResource = ClassLoadoutResource.new()
	loadout.class_id = player_class.class_id
	loadout.display_name = player_class.display_name
	loadout.role = player_class.role
	loadout.body_color = player_class.body_color
	loadout.has_soul_tethers = player_class.has_soul_tethers
	loadout.guard_on_trigger_l = true
	loadout.kit = kit
	loadout.weapon = weapon
	loadout.armor = armor
	loadout.stats = _stats_with_armor(player_class.base_stats, armor)
	loadout.dodge = catalog.dodge_template()

	var lights: Array[CombatActionResource] = []
	for template: CombatActionResource in weapon.light_chain:
		lights.append(_weapon_action(weapon, template))
	var heavy: CombatActionResource = _weapon_action(weapon, weapon.heavy)
	heavy.detonates = true
	var cards: Array[CombatActionResource] = []
	for slot: int in EquipmentLoadoutResource.SLOT_COUNT:
		var action: CombatActionResource = _card_action(catalog.card(kit.lead_ids[slot]), slot, weapon)
		var under: ScribeCardResource = catalog.card(kit.under_ids[slot])
		if under != null and under.is_under():
			apply_under(action, under)
		cards.append(action)
	_link_flows(lights, heavy, cards)

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


## A copy of `requested` with anything unknown or misplaced swapped for the
## class's starter choice, so a stale save or a bad packet can't break an actor.
static func sanitized(player_class: PlayerClassResource, requested: EquipmentLoadoutResource) -> EquipmentLoadoutResource:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var starter: EquipmentLoadoutResource = player_class.starter_kit
	var kit: EquipmentLoadoutResource = (requested if requested != null else starter).copy()
	var armor: EquipmentItemResource = catalog.item(kit.armor_id)
	if armor == null or not armor.is_armor():
		kit.armor_id = starter.armor_id
	var weapon: EquipmentItemResource = catalog.item(kit.weapon_id)
	if weapon == null or not weapon.is_weapon():
		kit.weapon_id = starter.weapon_id
	for slot: int in EquipmentLoadoutResource.SLOT_COUNT:
		if not fits_slot(player_class, catalog.card(kit.lead_ids[slot]), slot):
			kit.lead_ids[slot] = starter.lead_ids[slot]
			kit.lead_variants[slot] = ScribeCardResource.CardVariant.STANDARD
		var under: ScribeCardResource = catalog.card(kit.under_ids[slot])
		if under == null or not under.is_under():
			kit.under_ids[slot] = &""
	return kit


## Whether a lead card can sit in a slot for this class.
static func fits_slot(player_class: PlayerClassResource, lead: ScribeCardResource, slot: int) -> bool:
	return lead != null and lead.is_lead() and lead.slot == slot and (player_class.has_soul_tethers or not lead.needs_soul_tether)


## One under-card verb applied to the lead card's action above it.
static func apply_under(action: CombatActionResource, under: ScribeCardResource) -> void:
	match under.verb:
		ScribeCardResource.UnderVerb.ASPECT_INFUSION:
			if action.effect == Fx.STRIKE:
				action.primer = under.aspect
			action.aspect = under.aspect
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


static func memory_capacity(level: int) -> int:
	return BASE_MEMORY + MEMORY_PER_LEVEL * level


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


## Why this kit can't be equipped at this Grimoire level, or "" when it can.
static func kit_problem(player_class: PlayerClassResource, kit: EquipmentLoadoutResource, level: int,
		collection: Dictionary[StringName, int]) -> String:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	if not sanitized(player_class, kit).same_as(kit):
		return "That doesn't fit this class"
	var uses: Dictionary[StringName, int] = {}
	for slot: int in EquipmentLoadoutResource.SLOT_COUNT:
		var lead_key: StringName = kit.lead_copy_key(slot)
		uses[lead_key] = uses.get(lead_key, 0) + 1
		if kit.under_ids[slot] != &"":
			if slot >= under_slots(level):
				return "Under-Card link %d opens at Grimoire Lv %d" % [slot + 1, slot + 2]
			uses[kit.under_ids[slot]] = uses.get(kit.under_ids[slot], 0) + 1
	for key: StringName in uses:
		if not owns(key, uses[key], collection):
			var missing: ScribeCardResource = catalog.card(ScribeCardResource.copy_card_id(key))
			return "Not in the binder: %s (%s)" % [missing.display_name if missing != null else String(key),
				ScribeCardResource.VARIANT_NAMES[ScribeCardResource.copy_variant(key)]]
	var used: int = memory_used(kit)
	if used > memory_capacity(level):
		return "Needs %d Grimoire Memory (Lv %d holds %d)" % [used, level, memory_capacity(level)]
	return ""


# --- Building actions -----------------------------------------------------

static func _stats_with_armor(base: CharacterStatsResource, armor: EquipmentItemResource) -> CharacterStatsResource:
	var stats: CharacterStatsResource = base.duplicate() as CharacterStatsResource
	stats.damage_mitigation = armor.mitigation
	stats.stamina_regen_per_sec = armor.stamina_regen_per_sec
	stats.roll_distance = armor.roll_distance
	stats.perfect_guard_window = armor.perfect_guard_window
	stats.can_perfect_guard = true
	return stats


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
	action.aspect = lead.aspect
	action.flow_links = []
	if lead.delivery == ScribeCardResource.Delivery.THROUGH_WEAPON and action.effect == Fx.STRIKE:
		_channel_through(action, weapon)
	if action.effect == Fx.GREEN_SANCTUARY or action.effect == Fx.SHADOW_SANCTUARY:
		action.effect_radius *= weapon.support_radius_multiplier
	return action


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


## Each light flows into the next swing, the Heavy and the movement cards; the
## Heavy and cards flow back into the chain. Ultimates end a combo.
static func _link_flows(lights: Array[CombatActionResource], heavy: CombatActionResource, cards: Array[CombatActionResource]) -> void:
	var forward: CombatActionResource = cards[ScribeCardResource.GrimoireSlot.FORWARD]
	var back: CombatActionResource = cards[ScribeCardResource.GrimoireSlot.BACK]
	var signature: CombatActionResource = cards[ScribeCardResource.GrimoireSlot.SIGNATURE]
	for index: int in lights.size():
		var links: Array[CombatActionResource] = []
		if index < lights.size() - 1:
			links.append(lights[index + 1])
		links.append_array([heavy, forward, back])
		if index == lights.size() - 1:
			links.append(signature)
		lights[index].flow_links = _ids(links)
	heavy.flow_links = _ids([lights[0], forward, back])
	forward.flow_links = _ids([lights[0], back])
	back.flow_links = _ids([lights[0], forward])
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
