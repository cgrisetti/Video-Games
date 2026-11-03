## The starting zone's creatures (13_STARTING_ZONE_ENCOUNTER_DESIGN.md §2) as
## kin of the First-Quiet (15_THE_MYTHOPOETIC_LENS.md): six families of three,
## as typed data (MobVariantResource) registered by id.
##   1 Curious Weald-Wights (Tier 1, Lvl 1-2): hobs nobody has wronged
##     (HOB_BENIGN), with slow 1.2 s wind-ups; wave the Truce-Sign within 6 m
##     and they dance, strike one and it turns boggart
##   2 Padfoot Boggarts (Tier 2, Lvl 2-3): mist-hounds and a puddle-bucca,
##     awake within 10 m, linear dash telegraphs; released as white sea-swallows
##   3 Furrow Iron-Men (Tier 3, Lvl 3-4): shielded three-spirit pulls, one heavy,
##     one melee, one clod-flinger (the tank breaks their shots behind
##     boulders); each wears an upside-down Maker-Seal, and turned right-way up
##     before he's beaten, an Iron-Man bows as a steward
##   4 Bramble-Hobs (Tier 4, Lvl 4-5): armour bark that a knockdown cracks
##   5 Crag-Spriggans (Tier 5, Lvl 5): barrier-shielded stone-guards at the
##     delve gates, curling back into mossy cairns when beaten
##   6 Ambient wildlife and the roaming Cairn-Drake: sheep and foxes
##     (AmbientFlock, not fighters) and the Crag-Back Cairn-Drake, which
##     bellows a Challenge-Roar on the High Road and is lulled into a cairn
## How each fights its Sign counter (Glacial Rupture slows the dashers,
## Shatterpoint cracks the shields) comes from the Four Signs as they stand.
class_name Bestiary
extends RefCounted

const FAMILY_NAMES: Array[String] = ["Curious Weald-Wights", "Padfoot Boggarts", "Furrow Iron-Men", "Bramble-Hobs", "Crag-Spriggans",
	"Ambient Wildlife"]
## Ambient critters (AmbientFlock), by kind.
const CRITTER_NAMES: Array[String] = ["Golden-Fleece Sheep", "Red Fox"]
const Family = MobVariantResource.Family
const Rank = MobVariantResource.Rank
const Body = MobVariantResource.Body
const Equilibrium = HobSpectrumComponent.EquilibriumState
const Resolution = HobSpectrumComponent.UnboggartResolution
const Form = HobSpectrumComponent.ReleaseForm

static var _variants: Dictionary[StringName, MobVariantResource] = {}
static var _order: Array[StringName] = []


static func variant(id: StringName) -> MobVariantResource:
	_ensure()
	return _variants.get(id, null)


## Every variant, in registration order.
static func all() -> Array[MobVariantResource]:
	_ensure()
	var list: Array[MobVariantResource] = []
	for id: StringName in _order:
		list.append(_variants[id])
	return list


static func family_of(family: int) -> Array[MobVariantResource]:
	var list: Array[MobVariantResource] = []
	for listed: MobVariantResource in all():
		if listed.family == family:
			list.append(listed)
	return list


## The actor's loadout: its stats and its one blow.
static func loadout(chosen: MobVariantResource) -> ClassLoadoutResource:
	var stats: CharacterStatsResource = CharacterStatsResource.new()
	stats.max_health = chosen.health
	stats.max_poise = chosen.poise
	stats.poise_regen_per_sec = maxf(8.0, chosen.poise * 0.25)
	stats.poise_regen_delay = 2.5
	stats.poise_knockdown_time = 4.0 if chosen.rank == Rank.BOSS else 2.4
	stats.knockdown_damage_taken = chosen.knockdown_damage_taken
	stats.damage_mitigation = chosen.mitigation
	stats.move_speed = 0.0 if chosen.rooted else chosen.move_speed
	stats.turn_speed = chosen.turn_speed
	var blow: CombatActionResource = CombatActionResource.new()
	blow.action_id = StringName("%s_blow" % chosen.variant_id)
	blow.display_name = "Shot" if chosen.ranged else "Strike"
	blow.command = CombatActionResource.Command.LIGHT
	blow.windup_time = chosen.windup
	blow.active_time = chosen.active
	blow.recovery_time = chosen.recovery
	blow.stamina_cost = 0.0
	blow.damage = chosen.damage
	blow.poise_damage = chosen.poise_damage
	blow.reach = chosen.reach
	blow.hit_radius = chosen.hit_radius
	blow.lunge_distance = chosen.lunge
	blow.hit_stop_scale = 1.4 if chosen.rank == Rank.BOSS else 0.9
	blow.resonance_gain = 0.0
	if chosen.ranged:
		blow.delivery = CombatActionResource.Delivery.PROJECTILE
		blow.projectile_range = chosen.projectile_range
		blow.projectile_speed = 22.0
		blow.projectile_radius = 0.35
		blow.projectile_look = chosen.projectile_look
	var made: ClassLoadoutResource = ClassLoadoutResource.new()
	made.class_id = chosen.variant_id
	made.display_name = chosen.display_name
	made.role = ClassLoadoutResource.Role.BOSS
	made.body_color = chosen.main_color
	made.stats = stats
	made.openers = [blow]
	return made


static func _ensure() -> void:
	if not _variants.is_empty():
		return
	# 1. Curious Weald-Wights: hobs nobody has wronged (yellow), low poise and health, slow wind-ups.
	var boar: MobVariantResource = _make(&"cider_thief_bristleboar", "Bristle-Hob", Family.CURIOUS_WEALD_WIGHTS, 1, Body.BOAR, 80.0, 15.0, 8.0)
	boar.main_color = Color(0.5, 0.36, 0.26)
	boar.accent_color = Color(0.86, 0.8, 0.66)
	boar.lunge = 1.2
	var tail: MobVariantResource = _make(&"thorn_tail_scuttler", "Thorn-Tail Hedgerow-Hob", Family.CURIOUS_WEALD_WIGHTS, 1, Body.SCUTTLER, 80.0, 15.0, 7.0)
	tail.move_speed = 4.6
	tail.main_color = Color(0.4, 0.46, 0.24)
	tail.accent_color = Color(0.54, 0.38, 0.22)
	var tusk: MobVariantResource = _make(&"old_tusk_crag", "Old Tusk-Hob", Family.CURIOUS_WEALD_WIGHTS, 2, Body.BOAR, 320.0, 40.0, 16.0)
	tusk.rank = Rank.RARE
	tusk.radius = 0.95
	tusk.height = 1.5
	tusk.windup = 1.3
	tusk.lunge = 2.2
	tusk.reach = 1.9
	tusk.hit_radius = 1.5
	tusk.main_color = Color(0.42, 0.4, 0.38)
	tusk.accent_color = Color(0.95, 0.92, 0.84)
	# 2. Padfoot Boggarts: awake within 10 m, lunging dashes along their facing.
	var prowler: MobVariantResource = _make(&"grey_pelt_prowler", "Grey Padfoot", Family.PADFOOT_BOGGARTS, 2, Body.WOLF, 180.0, 30.0, 12.0)
	_hostile(prowler, 10.0, 0.7, 4.0)
	prowler.main_color = Color(0.5, 0.5, 0.5)
	prowler.accent_color = Color(0.32, 0.32, 0.34)
	var toad: MobVariantResource = _make(&"river_snapper_toad", "Puddle-Bucca", Family.PADFOOT_BOGGARTS, 2, Body.TOAD, 180.0, 30.0, 14.0)
	_hostile(toad, 10.0, 0.8, 3.0)
	toad.move_speed = 3.0
	toad.main_color = Color(0.32, 0.46, 0.3)
	toad.accent_color = Color(0.7, 0.66, 0.4)
	var alpha: MobVariantResource = _make(&"alpha_frost_fang", "Frost-Fang Padfoot", Family.PADFOOT_BOGGARTS, 3, Body.WOLF, 520.0, 60.0, 18.0)
	_hostile(alpha, 12.0, 0.8, 6.0)
	alpha.rank = Rank.ELITE
	alpha.radius = 0.85
	alpha.height = 1.5
	alpha.reach = 1.8
	alpha.main_color = Color(0.82, 0.88, 0.95)
	alpha.accent_color = Color(0.45, 0.62, 0.85)
	alpha.eye_color = Color(0.5, 0.85, 1.0)
	# 3. Furrow Iron-Men: shielded three-spirit pulls, each with an upside-down Maker-Seal.
	var cutthroat: MobVariantResource = _make(&"soot_paw_cutthroat", "Furrow Iron-Man", Family.FURROW_IRON_MEN, 3, Body.HUMANOID, 220.0, 45.0, 14.0)
	_hostile(cutthroat, 9.0, 0.6, 1.5)
	cutthroat.mitigation = 0.2
	cutthroat.main_color = Color(0.3, 0.28, 0.27)
	cutthroat.accent_color = Color(0.62, 0.22, 0.18)
	var slinger: MobVariantResource = _make(&"quarry_sling_shotter", "Clod-Flinger Iron-Man", Family.FURROW_IRON_MEN, 3, Body.HUMANOID, 160.0, 30.0, 10.0)
	_hostile(slinger, 14.0, 0.9, 0.0)
	slinger.ranged = true
	slinger.projectile_look = ArsenalCatalog.HUNTER_BOW
	slinger.projectile_range = 16.0
	slinger.main_color = Color(0.48, 0.42, 0.32)
	slinger.accent_color = Color(0.36, 0.3, 0.22)
	var foreman: MobVariantResource = _make(&"foreman_iron_gavel", "Plough-Giant Iron-Man", Family.FURROW_IRON_MEN, 4, Body.HUMANOID, 420.0, 70.0, 24.0)
	_hostile(foreman, 9.0, 1.0, 1.0)
	foreman.rank = Rank.ELITE
	foreman.mitigation = 0.3
	foreman.radius = 0.62
	foreman.height = 2.1
	foreman.reach = 1.9
	foreman.hit_radius = 1.5
	foreman.main_color = Color(0.36, 0.3, 0.26)
	foreman.accent_color = Color(0.55, 0.57, 0.6)
	# 4. Bramble-Hobs: armour bark; a knockdown cracks it (twice the damage while down).
	var lasher: MobVariantResource = _make(&"bramble_lasher_vine", "Bramble-Lasher Hob", Family.BRAMBLE_HOBS, 4, Body.VINE, 260.0, 75.0, 14.0)
	_hostile(lasher, 6.0, 0.9, 0.0)
	_bark(lasher)
	lasher.rooted = true
	lasher.reach = 3.4
	lasher.hit_radius = 1.4
	lasher.main_color = Color(0.3, 0.4, 0.2)
	lasher.accent_color = Color(0.55, 0.2, 0.3)
	var puff: MobVariantResource = _make(&"spore_puff_shambler", "Spore-Puff Lob", Family.BRAMBLE_HOBS, 4, Body.SHAMBLER, 300.0, 75.0, 12.0)
	_hostile(puff, 8.0, 1.1, 0.0)
	_bark(puff)
	puff.move_speed = 2.4
	puff.reach = 0.2
	puff.hit_radius = 2.6
	puff.main_color = Color(0.46, 0.42, 0.3)
	puff.accent_color = Color(0.8, 0.78, 0.5)
	var hulk: MobVariantResource = _make(&"bog_hulk_tangler", "Bog-Hulk Boggart", Family.BRAMBLE_HOBS, 5, Body.HULK, 600.0, 110.0, 26.0)
	_hostile(hulk, 9.0, 1.2, 1.2)
	_bark(hulk)
	hulk.rank = Rank.ELITE
	hulk.radius = 1.0
	hulk.height = 2.6
	hulk.reach = 2.2
	hulk.hit_radius = 1.8
	hulk.move_speed = 2.8
	hulk.main_color = Color(0.3, 0.34, 0.24)
	hulk.accent_color = Color(0.42, 0.3, 0.2)
	# 5. Crag-Spriggans: stone-guards behind barrier shields at the delve gates; beaten, they curl into cairns.
	var husk: MobVariantResource = _make(&"risen_shield_sworn_husk", "Moss-Shield Spriggan", Family.CRAG_SPRIGGANS, 5, Body.WIGHT, 380.0, 60.0, 18.0)
	_hostile(husk, 10.0, 0.9, 1.0)
	husk.mitigation = 0.35
	husk.main_color = Color(0.5, 0.54, 0.5)
	husk.accent_color = Color(0.62, 0.5, 0.28)
	husk.eye_color = Color(0.55, 0.95, 0.85)
	var acolyte: MobVariantResource = _make(&"hollow_scribe_acolyte", "Barrow-Rime Spriggan", Family.CRAG_SPRIGGANS, 5, Body.WIGHT, 260.0, 40.0, 14.0)
	_hostile(acolyte, 14.0, 1.0, 0.0)
	acolyte.mitigation = 0.35
	acolyte.ranged = true
	acolyte.projectile_look = ArsenalCatalog.SCRIBE_STAFF
	acolyte.projectile_range = 15.0
	acolyte.main_color = Color(0.42, 0.4, 0.48)
	acolyte.accent_color = Color(0.7, 0.66, 0.9)
	acolyte.eye_color = Color(0.7, 0.6, 1.0)
	var knell: MobVariantResource = _make(&"barrow_warden_knell", "Barrow-Bell Spriggan", Family.CRAG_SPRIGGANS, 5, Body.WIGHT, 700.0, 90.0, 26.0)
	_hostile(knell, 11.0, 1.2, 1.4)
	knell.rank = Rank.ELITE
	knell.mitigation = 0.35
	knell.radius = 0.75
	knell.height = 2.4
	knell.reach = 2.0
	knell.hit_radius = 1.6
	knell.main_color = Color(0.46, 0.46, 0.42)
	knell.accent_color = Color(0.8, 0.62, 0.3)
	knell.eye_color = Color(0.5, 1.0, 0.8)
	# 6. The roaming mini-boss: the Crag-Back Cairn-Drake patrols the High Road.
	var behemoth: MobVariantResource = _make(&"crag_back_behemoth", "The Crag-Back Cairn-Drake", Family.WILDLIFE, 6, Body.BEHEMOTH, 2500.0, 150.0, 34.0)
	_hostile(behemoth, 12.0, 1.4, 2.0)
	behemoth.rank = Rank.BOSS
	behemoth.patrols = true
	behemoth.stomps = true
	behemoth.radius = 1.6
	behemoth.height = 3.4
	behemoth.reach = 3.0
	behemoth.hit_radius = 2.6
	behemoth.move_speed = 2.6
	behemoth.turn_speed = 2.4
	behemoth.mitigation = 0.15
	behemoth.main_color = Color(0.44, 0.4, 0.36)
	behemoth.accent_color = Color(0.36, 0.48, 0.28)
	behemoth.eye_color = Color(1.0, 0.7, 0.3)
	# Where each stands on the Hob-to-Boggart Spectrum, and how it's un-boggarted.
	for kin: MobVariantResource in [boar, tail, tusk]:
		_spirit(kin, Equilibrium.HOB_BENIGN, Resolution.STATE_UNBOGGART_RELEASE, Form.HEDGE_WREN)
	for kin: MobVariantResource in [prowler, toad, alpha]:
		_spirit(kin, Equilibrium.BOGGART_AWOKEN, Resolution.STATE_UNBOGGART_RELEASE, Form.SEA_SWALLOW)
	for kin: MobVariantResource in [cutthroat, slinger, foreman]:
		_spirit(kin, Equilibrium.BOGGART_AWOKEN, Resolution.STATE_STEWARD_HELPER, Form.SINK_TO_SLEEP)
		kin.has_maker_seal = true
	for kin: MobVariantResource in [lasher, puff, hulk]:
		_spirit(kin, Equilibrium.BOGGART_AWOKEN, Resolution.STATE_UNBOGGART_RELEASE, Form.HEDGE_WREN)
	for kin: MobVariantResource in [husk, acolyte, knell, behemoth]:
		_spirit(kin, Equilibrium.BOGGART_AWOKEN, Resolution.STATE_LULLED_CAIRN, Form.HEDGE_WREN)
	behemoth.roars = true


static func _make(id: StringName, label: String, family: Family, level: int, body: Body, health: float, poise: float, damage: float) -> MobVariantResource:
	var made: MobVariantResource = MobVariantResource.new()
	made.variant_id = id
	made.display_name = label
	made.family = family
	made.level = level
	made.body = body
	made.health = health
	made.poise = poise
	made.damage = damage
	made.poise_damage = poise * 0.3
	match body:
		Body.SCUTTLER:
			made.radius = 0.5
			made.height = 0.8
		Body.WOLF:
			made.radius = 0.6
			made.height = 1.1
		Body.TOAD:
			made.radius = 0.65
			made.height = 0.9
		Body.HUMANOID, Body.WIGHT:
			made.radius = 0.45
			made.height = 1.8
		Body.VINE:
			made.radius = 0.5
			made.height = 2.0
		Body.SHAMBLER:
			made.radius = 0.7
			made.height = 1.6
	_variants[id] = made
	_order.append(id)
	return made


static func _spirit(made: MobVariantResource, equilibrium: Equilibrium, resolution: Resolution, form: Form) -> void:
	made.equilibrium = equilibrium
	made.resolution = resolution
	made.release_form = form


static func _hostile(made: MobVariantResource, aggro: float, windup: float, lunge: float) -> void:
	made.aggro_radius = aggro
	made.windup = windup
	made.lunge = lunge
	made.recovery = 0.5
	made.cooldown = 1.3


static func _bark(made: MobVariantResource) -> void:
	made.mitigation = 0.45
	made.knockdown_damage_taken = 2.0
