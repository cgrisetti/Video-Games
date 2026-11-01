## The Arsenal Catalog (autoload "Arsenal"): every Scribe Sign, armor, weapon
## and Scribe Card in the game, indexed by StringName id
## (05_ARSENAL_AND_CARDS_GDD.md). Kits, the roster, save files and RPCs name
## things by id and look them up here, so every peer resolves an id to the
## same data.
##
## Adding a card or a weapon is one register call below, or a .tres card file
## dropped in CARD_FOLDER. Nothing that plays cards or weapons changes.
class_name ArsenalCatalog
extends Node

## The live autoload node (see NetworkManager.current for why).
static var current: ArsenalCatalog

## Card resources saved as .tres files here are registered at startup too.
const CARD_FOLDER: String = "res://data/cards/"
## Odds of a chest card being a Plain Vellum, Gilded Leaf or Star-Inked Vellum copy.
const VARIANT_ODDS: Array[float] = [0.6, 0.3, 0.1]

# Armor
const HEARTH_LINEN: StringName = &"hearth_linen"
const RANGER_LEATHER: StringName = &"ranger_leather"
const IRONWOOD_PLATE: StringName = &"ironwood_plate"
# Weapons
const LIGHT_SWORD: StringName = &"light_sword"
const HEAVY_AXE: StringName = &"heavy_axe"
const SCRIBE_STAFF: StringName = &"scribe_staff"
const HUNTER_BOW: StringName = &"hunter_bow"
# Starter lead cards (three per Grimoire slot: one each from the tank, healer and DPS kits)
const SHIELD_CHARGE: StringName = &"shield_charge"
const RISING_DRIVE: StringName = &"rising_drive"
const SUNLIT_LANCE: StringName = &"sunlit_lance"
const SHADOW_SANCTUARY: StringName = &"shadow_sanctuary"
const FROST_CRESCENT: StringName = &"frost_crescent"
const GREEN_SANCTUARY: StringName = &"green_sanctuary"
const TAUNT: StringName = &"taunt"
const HOMING_HEAL: StringName = &"homing_heal"
const GALE_RUSH: StringName = &"gale_rush"
const BULWARK_QUAKE: StringName = &"bulwark_quake"
const LIFELINE_PULL: StringName = &"lifeline_pull"
const TEMPEST_FLOW: StringName = &"tempest_flow"
# Boss-drop lead cards
const MOONFALL_CLEAVE: StringName = &"moonfall_cleave"
const EMBER_AEGIS: StringName = &"ember_aegis"
const STARLIT_VOLLEY: StringName = &"starlit_volley"
const DAWNBREAKER: StringName = &"dawnbreaker"
# Uncommon cards found on the Doverslap Expedition (the Wayfarer's Chest).
const HOLLOWAY_LUNGE: StringName = &"holloway_lunge"
const ROOT_SNARE_STEP: StringName = &"root_snare_step"
const LANTERN_MOTE: StringName = &"lantern_mote"
const GORGE_GALE: StringName = &"gorge_gale"
# Under-cards
const IRON_ROOT_LINK: StringName = &"iron_root_link"
const RIME_GALE_LINK: StringName = &"rime_gale_link"
const WARM_HEARTH_LINK: StringName = &"warm_hearth_link"
const STAR_TIDE_LINK: StringName = &"star_tide_link"

# The Secondary Callings (06 §3, 07 GDD §1.3), in column order.
const STOUT_HEART: StringName = &"stout_heart"
const SWIFT_FOOT: StringName = &"swift_foot"
const WISE_HAND: StringName = &"wise_hand"

const Cmd = CombatActionResource.Command
const Fx = CombatActionResource.Effect
const Sign = ScribeSignResource.Sign
const Slot = ScribeCardResource.GrimoireSlot
const Part = PropPartResource.Shape

var _signs: Dictionary[int, ScribeSignResource] = {}
var _secondaries: Dictionary[StringName, SecondaryCallingResource] = {}
var _callings: Dictionary[StringName, CallingResource] = {}
var _secondary_order: Array[StringName] = []
var _items: Dictionary[StringName, EquipmentItemResource] = {}
var _cards: Dictionary[StringName, ScribeCardResource] = {}
# Registration order, so menus and drop rolls are the same on every peer.
var _item_order: Array[StringName] = []
var _card_order: Array[StringName] = []


func _init() -> void:
	_build_signs()
	_build_armor()
	_build_weapons()
	_build_lead_cards()
	_build_under_cards()
	_build_callings()
	_load_card_folder()


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


# --- Lookups --------------------------------------------------------------

func sign_seal(scribe_sign: int) -> ScribeSignResource:
	return _signs.get(scribe_sign, _signs[Sign.NONE])


func item(id: StringName) -> EquipmentItemResource:
	return _items.get(id, null)


func card(id: StringName) -> ScribeCardResource:
	return _cards.get(id, null)


## A Secondary Calling by id (&"swift_foot"), or null.
func secondary_calling(id: StringName) -> SecondaryCallingResource:
	return _secondaries.get(id, null)


## The Secondary Calling in a column of the matrix (Callings.Secondary), or null.
func secondary_at(column: int) -> SecondaryCallingResource:
	return _secondaries[_secondary_order[column]] if column >= 0 and column < _secondary_order.size() else null


## The Secondary Callings in column order.
func secondary_callings() -> Array[SecondaryCallingResource]:
	var list: Array[SecondaryCallingResource] = []
	for id: StringName in _secondary_order:
		list.append(_secondaries[id])
	return list


## The Calling a Fellowship becomes with a Secondary (by id), or null.
func calling_for(fellowship_class_id: StringName, secondary_id: StringName) -> CallingResource:
	for listed: CallingResource in _callings.values():
		if listed.fellowship_class_id == fellowship_class_id and listed.secondary_id == secondary_id:
			return listed
	return null


## Every registered Calling.
func callings() -> Array[CallingResource]:
	var list: Array[CallingResource] = []
	list.assign(_callings.values())
	return list


func armors() -> Array[EquipmentItemResource]:
	return _items_in(EquipmentItemResource.ItemSlot.ARMOR)


func weapons() -> Array[EquipmentItemResource]:
	return _items_in(EquipmentItemResource.ItemSlot.WEAPON)


## Every card in registration order.
func cards() -> Array[ScribeCardResource]:
	var list: Array[ScribeCardResource] = []
	for id: StringName in _card_order:
		list.append(_cards[id])
	return list


## The lead cards that fit one Grimoire slot.
func lead_cards(slot: int) -> Array[ScribeCardResource]:
	var list: Array[ScribeCardResource] = []
	for listed: ScribeCardResource in cards():
		if listed.is_lead() and listed.slot == slot:
			list.append(listed)
	return list


func under_cards() -> Array[ScribeCardResource]:
	var list: Array[ScribeCardResource] = []
	for listed: ScribeCardResource in cards():
		if listed.is_under():
			list.append(listed)
	return list


## How a card copy reads in menus and banners: "Moonfall Cleave (Rare, Gilded Leaf)".
func copy_name(copy_key: StringName) -> String:
	var named: ScribeCardResource = card(ScribeCardResource.copy_card_id(copy_key))
	if named == null:
		return String(copy_key)
	var variant: ScribeCardResource.CardVariant = ScribeCardResource.copy_variant(copy_key)
	var extras: PackedStringArray = PackedStringArray()
	if named.rarity >= ScribeCardResource.CardRarity.RARE:
		extras.append(named.rarity_name())
	if variant != ScribeCardResource.CardVariant.STANDARD:
		extras.append(ScribeCardResource.VARIANT_NAMES[variant])
	return named.display_name if extras.is_empty() else "%s (%s)" % [named.display_name, ", ".join(extras)]


## A fresh dodge roll; the armor sets how far it carries (DodgeState).
func dodge_template() -> CombatActionResource:
	var roll: CombatActionResource = _support(&"dodge_roll", "Dodge Roll", Cmd.DODGE, Fx.DODGE, 0.03, 0.32, 0.22)
	roll.stamina_cost = 20.0
	return roll


## A boss chest's card: a weighted pick from every droppable card, with a rolled
## variant. Starter cards are free in Standard, so they always drop as Shiny or
## Astral copies. Returns the copy key. The host rolls; peers are told the key.
func roll_card_drop(rng: RandomNumberGenerator) -> StringName:
	var total: float = 0.0
	for listed: ScribeCardResource in cards():
		total += listed.drop_weight
	var pick: float = rng.randf() * total
	var chosen: ScribeCardResource = null
	for listed: ScribeCardResource in cards():
		if listed.drop_weight <= 0.0:
			continue
		chosen = listed
		pick -= listed.drop_weight
		if pick <= 0.0:
			break
	var variant: ScribeCardResource.CardVariant = roll_variant(rng)
	if chosen.starter and variant == ScribeCardResource.CardVariant.STANDARD:
		variant = ScribeCardResource.CardVariant.SHINY_FOIL
	return ScribeCardResource.copy_key(chosen.card_id, variant)


## A card of one rarity (the Wayfarer's Chest gives an Uncommon one), evenly
## picked, with a rolled variant. Returns the copy key.
func roll_card_of_rarity(rng: RandomNumberGenerator, rarity: ScribeCardResource.CardRarity) -> StringName:
	var pool: Array[ScribeCardResource] = []
	for listed: ScribeCardResource in cards():
		if listed.is_lead() and listed.rarity == rarity:
			pool.append(listed)
	if pool.is_empty():
		return &""
	var chosen: ScribeCardResource = pool[rng.randi() % pool.size()]
	return ScribeCardResource.copy_key(chosen.card_id, roll_variant(rng))


func roll_variant(rng: RandomNumberGenerator) -> ScribeCardResource.CardVariant:
	var roll: float = rng.randf()
	for variant: int in VARIANT_ODDS.size():
		roll -= VARIANT_ODDS[variant]
		if roll < 0.0:
			return variant as ScribeCardResource.CardVariant
	return ScribeCardResource.CardVariant.STANDARD


# --- Registering ----------------------------------------------------------

func register_sign(seal: ScribeSignResource) -> void:
	_signs[seal.scribe_sign] = seal


func register_item(added: EquipmentItemResource) -> void:
	assert(added.item_id != &"", "ArsenalCatalog: an item needs an id")
	if not _items.has(added.item_id):
		_item_order.append(added.item_id)
	_items[added.item_id] = added


func register_secondary_calling(added: SecondaryCallingResource) -> void:
	if not _secondaries.has(added.calling_id):
		_secondary_order.append(added.calling_id)
	_secondaries[added.calling_id] = added


func register_calling(added: CallingResource) -> void:
	_callings[added.calling_id] = added


func register_card(added: ScribeCardResource) -> void:
	if added.card_id == &"" or (added.is_lead() and added.template == null):
		push_warning("ArsenalCatalog: skipped a card with no id or no action")
		return
	if not _cards.has(added.card_id):
		_card_order.append(added.card_id)
	_cards[added.card_id] = added


func _items_in(slot: EquipmentItemResource.ItemSlot) -> Array[EquipmentItemResource]:
	var list: Array[EquipmentItemResource] = []
	for id: StringName in _item_order:
		if _items[id].item_slot == slot:
			list.append(_items[id])
	return list


func _load_card_folder() -> void:
	if not DirAccess.dir_exists_absolute(CARD_FOLDER):
		return
	for file: String in ResourceLoader.list_directory(CARD_FOLDER):
		if file.ends_with(".tres") or file.ends_with(".res"):
			var loaded: ScribeCardResource = load(CARD_FOLDER + file) as ScribeCardResource
			if loaded != null:
				register_card(loaded)


# --- The Four Scribe Signs (06 GDD §2) -----------------------------------

func _build_signs() -> void:
	register_sign(_seal(Sign.NONE, "Plain", "", "", Color(0.9, 0.9, 0.9), ScribeSignResource.Glyph.RING, &""))
	# Iron-Root (amber / ochre): the poise and stagger lever.
	var iron_root: ScribeSignResource = _seal(Sign.SIGN_IRON_ROOT, "Iron-Root", "Sign of Iron-Root", "SHATTERPOINT", Color(0.93, 0.6, 0.22),
		ScribeSignResource.Glyph.GEAR, &"seal_iron_root")
	iron_root.bonus_poise = 45.0
	iron_root.bonus_hit_stop = 1.0
	register_sign(iron_root)
	# Rime-Gale (sea-azure): the elemental burst lever.
	var rime_gale: ScribeSignResource = _seal(Sign.SIGN_RIME_GALE, "Rime-Gale", "Sign of Rime-Gale", "GLACIAL RUPTURE", Color(0.35, 0.72, 0.95),
		ScribeSignResource.Glyph.STAR, &"seal_rime_gale")
	rime_gale.bonus_damage = 45.0
	rime_gale.burst_radius = 4.0
	register_sign(rime_gale)
	# Warm-Hearth (saffron-gold): the mending and shelter lever.
	var warm_hearth: ScribeSignResource = _seal(Sign.SIGN_WARM_HEARTH, "Warm-Hearth", "Sign of Warm-Hearth", "DAWNBURST", Color(1.0, 0.76, 0.28),
		ScribeSignResource.Glyph.SUN, &"seal_warm_hearth")
	warm_hearth.party_heal = 20.0
	register_sign(warm_hearth)
	# Star-Tide (twilight-violet): the tempo and resource lever.
	var star_tide: ScribeSignResource = _seal(Sign.SIGN_STAR_TIDE, "Star-Tide", "Sign of Star-Tide", "ASTRAL CHORUS", Color(0.6, 0.45, 0.95),
		ScribeSignResource.Glyph.MOON, &"seal_star_tide")
	star_tide.party_stamina = 25.0
	star_tide.party_pips = 0.5
	register_sign(star_tide)


func _seal(scribe_sign: Sign, label: String, seal_name: String, detonation: String, color: Color,
		glyph: ScribeSignResource.Glyph, sound: StringName) -> ScribeSignResource:
	var seal: ScribeSignResource = ScribeSignResource.new()
	seal.scribe_sign = scribe_sign
	seal.display_name = label
	seal.seal_name = seal_name
	seal.detonation_name = detonation
	seal.color = color
	seal.glyph = glyph
	seal.sound = sound
	return seal


# --- Armor (05 GDD §2.1) --------------------------------------------------

func _build_armor() -> void:
	var linen: EquipmentItemResource = _armor(HEARTH_LINEN, "Hearth-Linen", EquipmentItemResource.ArmorWeight.LIGHT, 0.10, 27.5, 5.2, 0.20,
		"Light and quick: long rolls and fast stamina for healers and archers.")
	linen.prop_parts = [PropPartResource.make(Part.CYLINDER, Vector3(0.5, 0.14, 0.5), Vector3(0.0, 1.5, 0.0), Color(0.93, 0.88, 0.76))]
	register_item(linen)
	var leather: EquipmentItemResource = _armor(RANGER_LEATHER, "Ranger Leather", EquipmentItemResource.ArmorWeight.MEDIUM, 0.20, 22.0, 4.6, 0.20,
		"The all-rounder: fair protection, fair footwork.")
	leather.prop_parts = [
		PropPartResource.make(Part.CYLINDER, Vector3(0.49, 0.14, 0.49), Vector3(0.0, 0.95, 0.0), Color(0.42, 0.28, 0.16)),
		PropPartResource.make(Part.BOX, Vector3(0.12, 0.6, 0.06), Vector3(0.2, 1.25, -0.43), Color(0.42, 0.28, 0.16), Vector3(0.0, 0.0, -25.0)),
	]
	register_item(leather)
	var plate: EquipmentItemResource = _armor(IRONWOOD_PLATE, "Ironwood Plate", EquipmentItemResource.ArmorWeight.HEAVY, 0.35, 18.0, 3.8, 0.26,
		"Heavy plate for the front line: shrugs off blows, rolls short, and widens the Perfect Guard window.")
	var iron: Color = Color(0.55, 0.57, 0.6)
	plate.prop_parts = [
		PropPartResource.make(Part.BOX, Vector3(0.34, 0.16, 0.42), Vector3(-0.42, 1.45, 0.0), iron, Vector3(0.0, 0.0, 18.0)),
		PropPartResource.make(Part.BOX, Vector3(0.34, 0.16, 0.42), Vector3(0.42, 1.45, 0.0), iron, Vector3(0.0, 0.0, -18.0)),
		PropPartResource.make(Part.BOX, Vector3(0.62, 0.5, 0.1), Vector3(0.0, 1.05, -0.44), iron.darkened(0.15)),
	]
	register_item(plate)


func _armor(id: StringName, label: String, weight: EquipmentItemResource.ArmorWeight, mitigation: float, regen: float,
		roll: float, perfect_guard: float, blurb: String) -> EquipmentItemResource:
	var armor: EquipmentItemResource = EquipmentItemResource.new()
	armor.item_id = id
	armor.display_name = label
	armor.item_slot = EquipmentItemResource.ItemSlot.ARMOR
	armor.armor_weight = weight
	armor.mitigation = mitigation
	armor.stamina_regen_per_sec = regen
	armor.roll_distance = roll
	armor.perfect_guard_window = perfect_guard
	armor.description = blurb
	return armor


# --- Weapons (05 GDD §2.2) ------------------------------------------------

func _build_weapons() -> void:
	var steel: Color = Color(0.85, 0.86, 0.9)
	var wood: Color = Color(0.45, 0.3, 0.18)

	var sword: EquipmentItemResource = _weapon(LIGHT_SWORD, "Falchion", EquipmentItemResource.WeaponType.LIGHT_SWORD,
		EquipmentItemResource.DeliveryVector.MELEE, "A crisp three-cut chain and an advancing thrust. Cards land as rune-wreathed cuts.")
	var slash_1: CombatActionResource = _strike(&"slash_1", "Slash", Cmd.LIGHT, 0.15, 0.1, 0.3, 10.0, 8.0)
	slash_1.poise_damage = 4.0
	slash_1.resonance_gain = 0.07
	var slash_2: CombatActionResource = _strike(&"slash_2", "Slash II", Cmd.LIGHT, 0.15, 0.1, 0.3, 10.0, 9.0)
	slash_2.poise_damage = 5.0
	slash_2.resonance_gain = 0.07
	var slash_3: CombatActionResource = _strike(&"slash_3", "Slash III", Cmd.LIGHT, 0.15, 0.1, 0.3, 10.0, 12.0)
	slash_3.poise_damage = 10.0
	slash_3.hit_stop_scale = 1.4
	slash_3.resonance_gain = 0.08
	var thrust: CombatActionResource = _strike(&"advancing_thrust", "Advancing Thrust", Cmd.HEAVY, 0.35, 0.15, 0.55, 18.0, 18.0)
	thrust.poise_damage = 15.0
	thrust.lunge_distance = 2.0
	thrust.reach = 2.0
	thrust.hit_stop_scale = 1.6
	thrust.resonance_gain = 0.12
	sword.light_chain = [slash_1, slash_2, slash_3]
	sword.heavy = thrust
	sword.trail_color = Color(0.95, 0.96, 1.0, 0.8)
	sword.trail_base = Vector3(0.5, 1.0, -0.25)
	sword.trail_tip = Vector3(0.5, 1.0, -1.3)
	# A broad, single-edged falchion with a clipped point, a brass guard and pommel.
	var brass: Color = Color(0.86, 0.66, 0.3)
	sword.prop_parts = [
		PropPartResource.make(Part.BOX, Vector3(0.05, 0.17, 0.86), Vector3(0.48, 1.0, -0.82), steel),
		PropPartResource.make(Part.BOX, Vector3(0.05, 0.13, 0.26), Vector3(0.48, 1.03, -1.31), steel, Vector3(22.0, 0.0, 0.0)),
		PropPartResource.make(Part.BOX, Vector3(0.32, 0.06, 0.07), Vector3(0.48, 1.0, -0.36), brass),
		PropPartResource.make(Part.CYLINDER, Vector3(0.035, 0.22, 0.035), Vector3(0.48, 1.0, -0.24), Color(0.38, 0.24, 0.14), Vector3(90.0, 0.0, 0.0)),
		PropPartResource.make(Part.SPHERE, Vector3(0.05, 0.05, 0.05), Vector3(0.48, 1.0, -0.12), brass),
	]
	register_item(sword)

	var axe: EquipmentItemResource = _weapon(HEAVY_AXE, "Broad-Axe", EquipmentItemResource.WeaponType.HEAVY_AXE,
		EquipmentItemResource.DeliveryVector.MELEE, "Two deliberate, wide cleaves and an earth-splitting heavy. Slow, heavy, honest.")
	var cleave_1: CombatActionResource = _strike(&"cleave_1", "Wide Cleave", Cmd.LIGHT, 0.3, 0.15, 0.4, 16.0, 14.0)
	cleave_1.poise_damage = 10.0
	cleave_1.reach = 1.8
	cleave_1.hit_radius = 1.8
	cleave_1.hit_stop_scale = 1.4
	cleave_1.resonance_gain = 0.09
	var cleave_2: CombatActionResource = _strike(&"cleave_2", "Wide Cleave II", Cmd.LIGHT, 0.3, 0.15, 0.4, 16.0, 17.0)
	cleave_2.poise_damage = 14.0
	cleave_2.reach = 1.8
	cleave_2.hit_radius = 1.8
	cleave_2.hit_stop_scale = 1.5
	cleave_2.resonance_gain = 0.09
	var splitter: CombatActionResource = _strike(&"earth_splitter", "Earth-Splitter", Cmd.HEAVY, 0.55, 0.15, 0.65, 24.0, 28.0)
	splitter.poise_damage = 35.0
	splitter.reach = 2.0
	splitter.hit_radius = 1.6
	splitter.hit_stop_scale = 2.2
	splitter.resonance_gain = 0.12
	axe.light_chain = [cleave_1, cleave_2]
	axe.heavy = splitter
	axe.trail_color = Color(1.0, 0.85, 0.7, 0.8)
	axe.trail_base = Vector3(0.5, 1.05, -0.5)
	axe.trail_tip = Vector3(0.5, 1.15, -1.45)
	# A long oak haft with a leather grip and a wide, bearded broad-axe head.
	var axe_steel: Color = Color(0.58, 0.6, 0.64)
	axe.prop_parts = [
		PropPartResource.make(Part.CYLINDER, Vector3(0.05, 1.6, 0.05), Vector3(0.5, 1.0, -0.6), wood, Vector3(90.0, 0.0, 0.0)),
		PropPartResource.make(Part.CYLINDER, Vector3(0.062, 0.26, 0.062), Vector3(0.5, 1.0, -0.2), Color(0.32, 0.2, 0.12), Vector3(90.0, 0.0, 0.0)),
		PropPartResource.make(Part.BOX, Vector3(0.07, 0.62, 0.36), Vector3(0.5, 1.14, -1.24), axe_steel),
		PropPartResource.make(Part.BOX, Vector3(0.07, 0.26, 0.2), Vector3(0.5, 0.86, -1.17), axe_steel, Vector3(-20.0, 0.0, 0.0)),
		PropPartResource.make(Part.BOX, Vector3(0.06, 0.12, 0.2), Vector3(0.5, 1.1, -1.48), axe_steel.darkened(0.2)),
	]
	register_item(axe)

	var staff: EquipmentItemResource = _weapon(SCRIBE_STAFF, "Rowan Way-Staff", EquipmentItemResource.WeaponType.STAFF,
		EquipmentItemResource.DeliveryVector.RANGED_BOLT, "Two sweeps and an arcane bolt; a grounded pulse. Cards fly as bolts, sanctuaries grow 25%.")
	var sweep_1: CombatActionResource = _strike(&"sweep_1", "Staff Sweep", Cmd.LIGHT, 0.16, 0.1, 0.4, 7.0, 7.0)
	sweep_1.resonance_gain = 0.06
	var sweep_2: CombatActionResource = _strike(&"sweep_2", "Staff Sweep II", Cmd.LIGHT, 0.16, 0.1, 0.45, 7.0, 7.0)
	sweep_2.resonance_gain = 0.06
	var bolt: CombatActionResource = _shot(&"arcane_bolt", "Arcane Bolt", Cmd.LIGHT, 0.22, 0.08, 0.4, 10.0, 10.0, 12.0, 22.0)
	bolt.resonance_gain = 0.07
	var pulse: CombatActionResource = _strike(&"resonant_pulse", "Resonant Pulse", Cmd.HEAVY, 0.4, 0.15, 0.6, 20.0, 16.0)
	pulse.poise_damage = 8.0
	pulse.reach = 0.0
	pulse.hit_radius = 2.8
	pulse.resonance_gain = 0.1
	staff.light_chain = [sweep_1, sweep_2, bolt]
	staff.heavy = pulse
	staff.card_range = 12.0
	staff.projectile_speed = 22.0
	staff.projectile_radius = 0.38
	staff.support_radius_multiplier = 1.25
	staff.projectile_parts = [PropPartResource.make(Part.SPHERE, Vector3(0.24, 0.24, 0.24), Vector3.ZERO, Color(0.6, 1.0, 0.75), Vector3.ZERO, 3.0)]
	# A rowan way-staff: a reddish forked crook cradling a glowing seed, rowan berries and a ribbon.
	var rowan: Color = Color(0.56, 0.33, 0.2)
	staff.prop_parts = [
		PropPartResource.make(Part.CYLINDER, Vector3(0.045, 1.9, 0.04), Vector3(0.55, 1.0, -0.2), rowan),
		PropPartResource.make(Part.CYLINDER, Vector3(0.03, 0.34, 0.02), Vector3(0.48, 2.06, -0.2), rowan, Vector3(0.0, 0.0, 28.0)),
		PropPartResource.make(Part.CYLINDER, Vector3(0.03, 0.34, 0.02), Vector3(0.62, 2.06, -0.2), rowan, Vector3(0.0, 0.0, -28.0)),
		PropPartResource.make(Part.SPHERE, Vector3(0.13, 0.13, 0.13), Vector3(0.55, 2.04, -0.2), Color(0.6, 1.0, 0.68), Vector3.ZERO, 2.0),
		PropPartResource.make(Part.SPHERE, Vector3(0.045, 0.045, 0.045), Vector3(0.49, 1.82, -0.16), Color(0.85, 0.18, 0.15)),
		PropPartResource.make(Part.SPHERE, Vector3(0.045, 0.045, 0.045), Vector3(0.52, 1.77, -0.24), Color(0.85, 0.18, 0.15)),
		PropPartResource.make(Part.BOX, Vector3(0.02, 0.32, 0.07), Vector3(0.6, 1.72, -0.2), Color(0.95, 0.85, 0.5), Vector3(0.0, 0.0, -10.0)),
	]
	register_item(staff)

	var bow: EquipmentItemResource = _weapon(HUNTER_BOW, "Yew Longbow", EquipmentItemResource.WeaponType.BOW,
		EquipmentItemResource.DeliveryVector.RANGED_ARROW, "Stepping snap-shots and a planted, piercing draw. Cards fly as rune arrows.")
	var snap_1: CombatActionResource = _shot(&"snap_shot_1", "Snap-Shot", Cmd.LIGHT, 0.14, 0.08, 0.34, 10.0, 8.0, 14.0, 34.0)
	snap_1.lunge_distance = -0.6
	snap_1.resonance_gain = 0.06
	var snap_2: CombatActionResource = _shot(&"snap_shot_2", "Snap-Shot II", Cmd.LIGHT, 0.14, 0.08, 0.34, 10.0, 9.0, 14.0, 34.0)
	snap_2.lunge_distance = -0.6
	snap_2.resonance_gain = 0.06
	var draw: CombatActionResource = _shot(&"piercing_draw", "Piercing Draw", Cmd.HEAVY, 0.5, 0.1, 0.5, 20.0, 24.0, 18.0, 42.0)
	draw.poise_damage = 20.0
	draw.pierces = true
	draw.hit_stop_scale = 1.8
	draw.resonance_gain = 0.12
	bow.light_chain = [snap_1, snap_2]
	bow.heavy = draw
	bow.card_range = 18.0
	bow.projectile_speed = 38.0
	bow.projectile_radius = 0.3
	bow.projectile_parts = [
		PropPartResource.make(Part.BOX, Vector3(0.07, 0.07, 0.9), Vector3.ZERO, Color(0.75, 0.6, 0.4), Vector3.ZERO, 0.6),
		PropPartResource.make(Part.BOX, Vector3(0.16, 0.16, 0.16), Vector3(0.0, 0.0, -0.48), Color(0.9, 0.95, 1.0), Vector3(0.0, 45.0, 0.0), 3.0),
		PropPartResource.make(Part.BOX, Vector3(0.2, 0.03, 0.2), Vector3(0.0, 0.0, 0.4), Color(0.95, 0.9, 0.8), Vector3.ZERO, 1.0),
	]
	# A tall yew longbow: golden limbs, a leather grip, brass nocks and a pale string.
	var yew: Color = Color(0.66, 0.48, 0.26)
	bow.prop_parts = [
		PropPartResource.make(Part.BOX, Vector3(0.05, 0.86, 0.07), Vector3(-0.5, 1.53, -0.42), yew, Vector3(-16.0, 0.0, 0.0)),
		PropPartResource.make(Part.BOX, Vector3(0.05, 0.86, 0.07), Vector3(-0.5, 0.77, -0.42), yew, Vector3(16.0, 0.0, 0.0)),
		PropPartResource.make(Part.BOX, Vector3(0.07, 0.2, 0.09), Vector3(-0.5, 1.15, -0.46), Color(0.34, 0.22, 0.13)),
		PropPartResource.make(Part.SPHERE, Vector3(0.035, 0.035, 0.035), Vector3(-0.5, 1.94, -0.3), Color(0.86, 0.66, 0.3)),
		PropPartResource.make(Part.SPHERE, Vector3(0.035, 0.035, 0.035), Vector3(-0.5, 0.36, -0.3), Color(0.86, 0.66, 0.3)),
		PropPartResource.make(Part.CYLINDER, Vector3(0.008, 1.5, 0.008), Vector3(-0.5, 1.15, -0.27), Color(0.95, 0.95, 0.9)),
	]
	register_item(bow)


func _weapon(id: StringName, label: String, type: EquipmentItemResource.WeaponType, delivery: EquipmentItemResource.DeliveryVector,
		blurb: String) -> EquipmentItemResource:
	var weapon: EquipmentItemResource = EquipmentItemResource.new()
	weapon.item_id = id
	weapon.display_name = label
	weapon.item_slot = EquipmentItemResource.ItemSlot.WEAPON
	weapon.weapon_type = type
	weapon.delivery = delivery
	weapon.description = blurb
	return weapon


# --- Lead cards (05 GDD §3.1) ---------------------------------------------

func _build_lead_cards() -> void:
	# Forward + Heavy: gap-closers and offensive primers.
	var charge: CombatActionResource = _strike(SHIELD_CHARGE, "Shield Charge", Cmd.FORWARD_HEAVY, 0.25, 0.25, 0.5, 20.0, 20.0)
	charge.poise_damage = 20.0
	charge.lunge_distance = 5.0
	charge.detonates = true
	charge.hit_stop_scale = 1.5
	charge.resonance_gain = 0.12
	_lead(charge, Slot.FORWARD, Sign.SIGN_IRON_ROOT, "Charge through the gap behind your shield. Detonates seals.")
	var drive: CombatActionResource = _strike(RISING_DRIVE, "Rising Drive", Cmd.FORWARD_HEAVY, 0.24, 0.14, 0.5, 18.0, 16.0)
	drive.poise_damage = 12.0
	drive.lunge_distance = 3.5
	drive.primer = Sign.SIGN_IRON_ROOT
	_lead(drive, Slot.FORWARD, Sign.SIGN_IRON_ROOT, "A rising lunge that stamps the Sign of Iron-Root.")
	var lance: CombatActionResource = _strike(SUNLIT_LANCE, "Sunlit Lance", Cmd.FORWARD_HEAVY, 0.2, 0.1, 0.35, 14.0, 6.0)
	lance.reach = 2.6
	lance.hit_radius = 1.6
	lance.primer = Sign.SIGN_WARM_HEARTH
	_lead(lance, Slot.FORWARD, Sign.SIGN_WARM_HEARTH, "A lance of morning light that stamps the Sign of Warm-Hearth.")

	# Back + Heavy: retreats, sanctuaries and counter primers.
	var shadow: CombatActionResource = _support(SHADOW_SANCTUARY, "Shadow Sanctuary", Cmd.BACK_HEAVY, Fx.SHADOW_SANCTUARY, 0.35, 0.1, 0.5)
	shadow.stamina_cost = 25.0
	shadow.effect_radius = 7.0
	shadow.effect_duration = 6.0
	_lead(shadow, Slot.BACK, Sign.SIGN_STAR_TIDE, "A shield cone behind you: allies inside take 60% less damage.", ScribeCardResource.Delivery.AT_CASTER)
	var crescent: CombatActionResource = _strike(FROST_CRESCENT, "Frost Crescent", Cmd.BACK_HEAVY, 0.28, 0.16, 0.5, 18.0, 14.0)
	crescent.lunge_distance = -1.5
	crescent.reach = 1.4
	crescent.hit_radius = 2.0
	crescent.primer = Sign.SIGN_RIME_GALE
	_lead(crescent, Slot.BACK, Sign.SIGN_RIME_GALE, "Step back through a frost arc that stamps the Sign of Rime-Gale.")
	var ring: CombatActionResource = _support(GREEN_SANCTUARY, "Green Sanctuary", Cmd.BACK_HEAVY, Fx.GREEN_SANCTUARY, 0.3, 0.1, 0.45)
	ring.resonance_cost = 1
	ring.heal_amount = 8.0
	ring.effect_radius = 4.5
	ring.effect_duration = 6.0
	_lead(ring, Slot.BACK, Sign.SIGN_WARM_HEARTH, "A healing ring on the floor (1 pip).", ScribeCardResource.Delivery.AT_CASTER)

	# R: the signature role card.
	var taunt: CombatActionResource = _support(TAUNT, "Taunt", Cmd.TRIGGER_R_SKILL, Fx.TAUNT, 0.2, 0.1, 0.3)
	taunt.resonance_cost = 1
	taunt.effect_duration = 6.0
	_lead(taunt, Slot.SIGNATURE, Sign.SIGN_IRON_ROOT, "Lock the boss onto you for 6 s (1 pip).", ScribeCardResource.Delivery.AT_CASTER)
	var heal: CombatActionResource = _support(HOMING_HEAL, "Homing Heal", Cmd.TRIGGER_R_SKILL, Fx.HOMING_HEAL, 0.12, 0.05, 0.3)
	heal.stamina_cost = 12.0
	heal.heal_amount = 22.0
	var heal_card: ScribeCardResource = _lead(heal, Slot.SIGNATURE, Sign.SIGN_WARM_HEARTH, "A heal that flies down your Soul Tether.", ScribeCardResource.Delivery.AT_CASTER)
	heal_card.needs_soul_tether = true
	var rush: CombatActionResource = _strike(GALE_RUSH, "Gale Rush", Cmd.TRIGGER_R_SKILL, 0.1, 0.2, 0.4, 0.0, 22.0)
	rush.resonance_cost = 1
	rush.lunge_distance = 6.0
	rush.resonance_gain = 0.0
	rush.primer = Sign.SIGN_STAR_TIDE
	_lead(rush, Slot.SIGNATURE, Sign.SIGN_STAR_TIDE, "A moonlit dash that stamps the Sign of Star-Tide (1 pip).")

	# L + R: the ultimate.
	var quake: CombatActionResource = _strike(BULWARK_QUAKE, "Bulwark Quake", Cmd.TRIGGER_BOTH_ULT, 0.6, 0.2, 0.8, 0.0, 30.0)
	quake.resonance_cost = 3
	quake.poise_damage = 60.0
	quake.reach = 0.0
	quake.hit_radius = 3.5
	quake.detonates = true
	quake.hit_stop_scale = 2.5
	quake.resonance_gain = 0.0
	_lead(quake, Slot.ULTIMATE, Sign.SIGN_IRON_ROOT, "Slam the ground around you; detonates seals (3 pips).", ScribeCardResource.Delivery.AT_CASTER)
	var pull: CombatActionResource = _support(LIFELINE_PULL, "Lifeline Pull", Cmd.TRIGGER_BOTH_ULT, Fx.LIFELINE_PULL, 0.12, 0.08, 0.4)
	pull.resonance_cost = 2
	pull.effect_duration = 0.4
	var pull_card: ScribeCardResource = _lead(pull, Slot.ULTIMATE, Sign.SIGN_WARM_HEARTH, "Yank your tethered ally to safety (2 pips).", ScribeCardResource.Delivery.AT_CASTER)
	pull_card.needs_soul_tether = true
	var tempest: CombatActionResource = _strike(TEMPEST_FLOW, "Tempest Flow", Cmd.TRIGGER_BOTH_ULT, 0.5, 0.3, 0.7, 0.0, 55.0)
	tempest.resonance_cost = 3
	tempest.poise_damage = 25.0
	tempest.reach = 0.5
	tempest.hit_radius = 3.2
	tempest.hit_stop_scale = 2.5
	tempest.resonance_gain = 0.0
	_lead(tempest, Slot.ULTIMATE, Sign.SIGN_RIME_GALE, "A whirling storm of cuts all around you (3 pips).", ScribeCardResource.Delivery.AT_CASTER)

	# Boss drops: collected from the Dojo Warden's chest, not in the starter kit.
	var moonfall: CombatActionResource = _strike(MOONFALL_CLEAVE, "Moonfall Cleave", Cmd.FORWARD_HEAVY, 0.3, 0.15, 0.5, 20.0, 24.0)
	moonfall.poise_damage = 18.0
	moonfall.lunge_distance = 3.0
	moonfall.primer = Sign.SIGN_STAR_TIDE
	moonfall.hit_stop_scale = 1.6
	_boss_drop(_lead(moonfall, Slot.FORWARD, Sign.SIGN_STAR_TIDE, "A falling crescent that stamps the Sign of Star-Tide."), ScribeCardResource.CardRarity.RARE)
	var aegis: CombatActionResource = _support(EMBER_AEGIS, "Aegis of Embers", Cmd.BACK_HEAVY, Fx.SHADOW_SANCTUARY, 0.3, 0.1, 0.45)
	aegis.stamina_cost = 22.0
	aegis.effect_radius = 8.5
	aegis.effect_duration = 7.0
	_boss_drop(_lead(aegis, Slot.BACK, Sign.SIGN_IRON_ROOT, "A wider, longer shield cone of banked embers.", ScribeCardResource.Delivery.AT_CASTER),
		ScribeCardResource.CardRarity.RARE)
	var volley: CombatActionResource = _strike(STARLIT_VOLLEY, "Starlit Volley", Cmd.TRIGGER_R_SKILL, 0.15, 0.15, 0.4, 0.0, 26.0)
	volley.resonance_cost = 1
	volley.primer = Sign.SIGN_RIME_GALE
	volley.resonance_gain = 0.0
	_boss_drop(_lead(volley, Slot.SIGNATURE, Sign.SIGN_RIME_GALE, "A burst of starlight that stamps the Sign of Rime-Gale (1 pip)."),
		ScribeCardResource.CardRarity.RARE)
	var dawn: CombatActionResource = _strike(DAWNBREAKER, "Dawnbreaker", Cmd.TRIGGER_BOTH_ULT, 0.55, 0.25, 0.75, 0.0, 48.0)
	dawn.resonance_cost = 3
	dawn.poise_damage = 40.0
	dawn.reach = 0.0
	dawn.hit_radius = 4.0
	dawn.detonates = true
	dawn.primer = Sign.SIGN_WARM_HEARTH
	dawn.hit_stop_scale = 2.6
	dawn.resonance_gain = 0.0
	var dawn_card: ScribeCardResource = _lead(dawn, Slot.ULTIMATE, Sign.SIGN_WARM_HEARTH,
		"A sunrise around you: detonates the old seal and stamps the Sign of Warm-Hearth (3 pips).", ScribeCardResource.Delivery.AT_CASTER)
	_boss_drop(dawn_card, ScribeCardResource.CardRarity.LEGENDARY)
	dawn_card.drop_weight = 1.0

	# Expedition finds: Uncommon cards from the Wayfarer's Chest, one per slot
	# (never in the boss's chest).
	var holloway: CombatActionResource = _strike(HOLLOWAY_LUNGE, "Holloway Lunge", Cmd.FORWARD_HEAVY, 0.24, 0.14, 0.5, 18.0, 17.0)
	holloway.poise_damage = 10.0
	holloway.lunge_distance = 3.0
	holloway.primer = Sign.SIGN_RIME_GALE
	_trail_find(_lead(holloway, Slot.FORWARD, Sign.SIGN_RIME_GALE, "A low lunge down the holloway that stamps the Sign of Rime-Gale."))
	var snare: CombatActionResource = _strike(ROOT_SNARE_STEP, "Root-Snare Step", Cmd.BACK_HEAVY, 0.26, 0.16, 0.5, 16.0, 14.0)
	snare.poise_damage = 16.0
	snare.lunge_distance = -1.5
	snare.reach = 1.4
	snare.hit_radius = 2.0
	snare.primer = Sign.SIGN_IRON_ROOT
	_trail_find(_lead(snare, Slot.BACK, Sign.SIGN_IRON_ROOT, "Step back as roots snatch at the foe, stamping the Sign of Iron-Root."))
	var mote: CombatActionResource = _strike(LANTERN_MOTE, "Lantern Mote", Cmd.TRIGGER_R_SKILL, 0.15, 0.12, 0.4, 0.0, 20.0)
	mote.resonance_cost = 1
	mote.reach = 2.4
	mote.hit_radius = 1.8
	mote.resonance_gain = 0.0
	mote.primer = Sign.SIGN_WARM_HEARTH
	_trail_find(_lead(mote, Slot.SIGNATURE, Sign.SIGN_WARM_HEARTH, "A Wind-Lantern's warm mote that stamps the Sign of Warm-Hearth (1 pip)."))
	var gale: CombatActionResource = _strike(GORGE_GALE, "Gorge Gale", Cmd.TRIGGER_BOTH_ULT, 0.5, 0.25, 0.7, 0.0, 42.0)
	gale.resonance_cost = 3
	gale.poise_damage = 35.0
	gale.reach = 0.0
	gale.hit_radius = 3.4
	gale.hit_stop_scale = 2.2
	gale.resonance_gain = 0.0
	gale.primer = Sign.SIGN_STAR_TIDE
	_trail_find(_lead(gale, Slot.ULTIMATE, Sign.SIGN_STAR_TIDE, "The Doverslap's gale bursts out around you, stamping the Sign of Star-Tide (3 pips).",
		ScribeCardResource.Delivery.AT_CASTER))


func _lead(template: CombatActionResource, slot: Slot, scribe_sign: Sign, blurb: String,
		delivery: ScribeCardResource.Delivery = ScribeCardResource.Delivery.THROUGH_WEAPON) -> ScribeCardResource:
	var lead: ScribeCardResource = ScribeCardResource.new()
	lead.card_id = template.action_id
	lead.display_name = template.display_name
	lead.description = blurb
	lead.kind = ScribeCardResource.CardKind.LEAD
	lead.slot = slot
	lead.scribe_sign = scribe_sign
	lead.delivery = delivery
	lead.template = template
	lead.template.scribe_sign = scribe_sign
	lead.rarity = ScribeCardResource.CardRarity.BASIC
	lead.starter = true
	lead.drop_weight = 1.0
	register_card(lead)
	return lead


## An Uncommon card found on the expedition: not a starter, never in the boss's chest.
func _trail_find(lead: ScribeCardResource) -> void:
	lead.rarity = ScribeCardResource.CardRarity.UNCOMMON
	lead.starter = false
	lead.drop_weight = 0.0


func _boss_drop(lead: ScribeCardResource, rarity: ScribeCardResource.CardRarity) -> void:
	lead.rarity = rarity
	lead.starter = false
	lead.drop_weight = 3.0


# --- The 3x3 Callings (06 §3, 07 GDD §1.3) ---------------------------------

## The three Secondary Callings and the nine Callings they make with the
## Fellowships. The names are the Creative Director's (06 §3, chosen
## 2026-11-01); a rename is one line here.
func _build_callings() -> void:
	var stout: SecondaryCallingResource = _secondary(STOUT_HEART, "Stout Heart", "+Tank", Color(0.86, 0.56, 0.26))
	stout.health_bonus = 20.0
	stout.stamina_regen_bonus = -2.0
	stout.poise_damage_multiplier = 1.25
	stout.perfect_guard_bonus = 0.03
	stout.unlocked_armor_weights = [EquipmentItemResource.ArmorWeight.HEAVY]
	var swift: SecondaryCallingResource = _secondary(SWIFT_FOOT, "Swift Foot", "+DPS", Color(0.38, 0.76, 0.5))
	swift.stamina_regen_bonus = 3.0
	swift.strike_damage_multiplier = 1.15
	swift.unlocked_weapon_types = [EquipmentItemResource.WeaponType.BOW, EquipmentItemResource.WeaponType.HEAVY_AXE]
	var wise: SecondaryCallingResource = _secondary(WISE_HAND, "Wise Hand", "+Magic", Color(0.68, 0.54, 0.95))
	wise.health_bonus = -5.0
	wise.stamina_regen_bonus = 2.0
	wise.resonance_gain_multiplier = 1.2
	wise.heal_multiplier = 1.2
	wise.bonus_memory = 1
	wise.unlocked_weapon_types = [EquipmentItemResource.WeaponType.STAFF]
	_calling(&"bridge_warden", "Bridge-Warden", "Keeper of the Stone-Span", ClassLoadouts.SHIELD_TANK, STOUT_HEART)
	_calling(&"weald_captain", "Weald-Captain", "Vanguard of the Green Company", ClassLoadouts.SHIELD_TANK, SWIFT_FOOT)
	_calling(&"hearth_guard", "Hearth-Guard", "Watcher of the Kindled Stone", ClassLoadouts.SHIELD_TANK, WISE_HAND)
	_calling(&"iron_woodsman", "Iron-Woodsman", "Hewn-Hand of the High Pines", ClassLoadouts.DIRECTIONAL_FLOW_DPS, STOUT_HEART)
	_calling(&"hedge_runner", "Hedge-Runner", "Outrider of the Bramble-Ways", ClassLoadouts.DIRECTIONAL_FLOW_DPS, SWIFT_FOOT)
	_calling(&"sign_seeker", "Sign-Seeker", "Journeyman of the Four Signs", ClassLoadouts.DIRECTIONAL_FLOW_DPS, WISE_HAND)
	_calling(&"bell_keeper", "Bell-Keeper", "Ringer of the Sanctuary Chime", ClassLoadouts.SOUL_TETHER_HEALER, STOUT_HEART)
	_calling(&"wind_mender", "Wind-Mender", "Weather-Worker of the Sound", ClassLoadouts.SOUL_TETHER_HEALER, SWIFT_FOOT)
	_calling(&"lantern_scribe", "Lantern-Scribe", "Bearer of the Reed-Light", ClassLoadouts.SOUL_TETHER_HEALER, WISE_HAND)


func _secondary(id: StringName, label: String, tag: String, trim: Color) -> SecondaryCallingResource:
	var secondary: SecondaryCallingResource = SecondaryCallingResource.new()
	secondary.calling_id = id
	secondary.column = _secondary_order.size()
	secondary.display_name = label
	secondary.tag = tag
	secondary.trim_color = trim
	register_secondary_calling(secondary)
	return secondary


func _calling(id: StringName, label: String, subtitle: String, fellowship_class_id: StringName, secondary_id: StringName) -> void:
	var calling: CallingResource = CallingResource.new()
	calling.calling_id = id
	calling.display_name = label
	calling.subtitle = subtitle
	calling.fellowship_class_id = fellowship_class_id
	calling.secondary_id = secondary_id
	register_calling(calling)


# --- Under-cards (05 GDD §3.1) --------------------------------------------

func _build_under_cards() -> void:
	_under(IRON_ROOT_LINK, "Iron-Root Link", Sign.SIGN_IRON_ROOT, ScribeCardResource.UnderVerb.POTENCY_SURGE,
		"Potency Surge: +20% damage, healing and poise.")
	_under(RIME_GALE_LINK, "Rime-Gale Link", Sign.SIGN_RIME_GALE, ScribeCardResource.UnderVerb.SIGN_INFUSION,
		"Sign Infusion: the card's hits stamp the Sign of Rime-Gale.")
	_under(WARM_HEARTH_LINK, "Warm-Hearth Link", Sign.SIGN_WARM_HEARTH, ScribeCardResource.UnderVerb.HEARTH_ECHO,
		"Hearth Echo: heals bounce 50% to a friend, sanctuaries restore stamina, hits return stamina.")
	_under(STAR_TIDE_LINK, "Star-Tide Link", Sign.SIGN_STAR_TIDE, ScribeCardResource.UnderVerb.SIGN_INFUSION,
		"Sign Infusion: the card's hits stamp the Sign of Star-Tide.")


func _under(id: StringName, label: String, scribe_sign: Sign, verb: ScribeCardResource.UnderVerb, blurb: String) -> void:
	var under: ScribeCardResource = ScribeCardResource.new()
	under.card_id = id
	under.display_name = label
	under.description = blurb
	under.kind = ScribeCardResource.CardKind.UNDER
	under.scribe_sign = scribe_sign
	under.verb = verb
	under.rarity = ScribeCardResource.CardRarity.COMMON
	under.starter = true
	register_card(under)


# --- Action builders ------------------------------------------------------

func _strike(id: StringName, label: String, command: CombatActionResource.Command,
		windup: float, active: float, recovery: float, stamina: float, damage: float) -> CombatActionResource:
	var action: CombatActionResource = CombatActionResource.new()
	action.action_id = id
	action.display_name = label
	action.command = command
	action.effect = Fx.STRIKE
	action.windup_time = windup
	action.active_time = active
	action.recovery_time = recovery
	action.stamina_cost = stamina
	action.damage = damage
	return action


func _shot(id: StringName, label: String, command: CombatActionResource.Command, windup: float, active: float, recovery: float,
		stamina: float, damage: float, flight_range: float, speed: float) -> CombatActionResource:
	var action: CombatActionResource = _strike(id, label, command, windup, active, recovery, stamina, damage)
	action.delivery = CombatActionResource.Delivery.PROJECTILE
	action.projectile_range = flight_range
	action.projectile_speed = speed
	return action


func _support(id: StringName, label: String, command: CombatActionResource.Command, effect: CombatActionResource.Effect,
		windup: float, active: float, recovery: float) -> CombatActionResource:
	var action: CombatActionResource = _strike(id, label, command, windup, active, recovery, 0.0, 0.0)
	action.effect = effect
	action.resonance_gain = 0.0
	return action
