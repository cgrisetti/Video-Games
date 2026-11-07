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
## Its Miyamoto tier (14 GDD §8) comes from its encounter: hobs and padfoots up
## to Lv 2 are roadside kin; from Lv 3 each family leaps back at 75% and shows
## its lock (the Frost-Fang's and the Bramble-Hobs' martial, the Iron-Men's rust
## that Warm-Hearth melts, the Spriggans' shields that Iron-Root cracks), and
## the Crag-Back locks at every gate. Each hostile family's blow carries a Sign
## (its limb glows through the wind-up), which a Tank's Ward-Mantle can soak.
##   7 The Crown's Trial-Kin (docs/20 Part II, Lv 15-18): the three open-air
##     trials' guards and capstones. The Trial of the Anvil's Forge-Clad
##     Sentinels and the Anvil-Warden Colossus (poise 180, shrugging off nine
##     tenths of every blow until its poise breaks, then taking it all); the
##     Trial of the Gale's Rime-Wing Harriers and Storm-Caller Vaelen (a
##     Breach-wind spirit in a Wayfarer's shape whose long wind-shear charge
##     leaves a wide window); the Trial of the Tide's Tarnished Scribe-Wights
##     and the Siphon-Prelate. Kin of the First-Quiet like the rest: bowed into
##     stewards, released as sea-swallows or lulled into cairns.
##   8 The Crown's Shore-Kin (docs/23 §5, Lv 15-17): the kin of the three
##     shores outside the trials, each teaching its trial's lesson in small.
##     Iron Shore's Clinker Iron-Men shrug off chip blows until their poise
##     breaks, and Cinder-Scuttlers swarm; the Gale Cliffs' Gust-Padfoots dash
##     in long straight lines and Scree-Hobs dart; the Tide Grottos'
##     Sap-Sodden Buccas wallow and rooted Blight-Lashers whip from the
##     sluices. One named rare walks each shore's track: Old Bellows by the
##     vents, the Grey Squall on the cliff-top, Mother Sluice on the shelf by the sea.
class_name Bestiary
extends RefCounted

const FAMILY_NAMES: Array[String] = ["Curious Weald-Wights", "Padfoot Boggarts", "Furrow Iron-Men", "Bramble-Hobs", "Crag-Spriggans",
	"Ambient Wildlife", "The Crown's Trial-Kin"]
## The Crown's Trial-Kin, by id (docs/20 Part II areas 3 to 5).
const FORGE_CLAD_SENTINEL: StringName = &"forge_clad_sentinel"
const ANVIL_WARDEN_COLOSSUS: StringName = &"anvil_warden_colossus"
const RIME_WING_HARRIER: StringName = &"rime_wing_harrier"
const STORM_CALLER_VAELEN: StringName = &"storm_caller_vaelen"
const TARNISHED_SCRIBE_WIGHT: StringName = &"tarnished_scribe_wight"
const SIPHON_PRELATE: StringName = &"siphon_prelate"
## The Crown's Shore-Kin, by id (docs/23 §5).
const CLINKER_IRON_MAN: StringName = &"clinker_iron_man"
const CINDER_SCUTTLER: StringName = &"cinder_scuttler"
const OLD_BELLOWS: StringName = &"old_bellows"
const GUST_PADFOOT: StringName = &"gust_padfoot"
const SCREE_HOB: StringName = &"scree_hob"
const GREY_SQUALL: StringName = &"grey_squall"
const SAP_SODDEN_BUCCA: StringName = &"sap_sodden_bucca"
const BLIGHT_LASHER: StringName = &"blight_lasher"
const MOTHER_SLUICE: StringName = &"mother_sluice"
## The starting zone's creatures (families 1 to 6); the Crown's kin come after them.
const STARTING_ZONE_COUNT: int = 16
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
	blow.scribe_sign = chosen.blow_sign as ScribeSignResource.Sign
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
	# Their Miyamoto tiers and locks (ArsenalCatalog encounters), and the Sign each family's blow carries.
	alpha.encounter_id = ArsenalCatalog.FROST_FANG_KIN
	for kin: MobVariantResource in [cutthroat, slinger, foreman]:
		kin.encounter_id = ArsenalCatalog.IRON_MAN_KIN
	for kin: MobVariantResource in [lasher, puff, hulk]:
		kin.encounter_id = ArsenalCatalog.BRAMBLE_HOB_KIN
	for kin: MobVariantResource in [husk, acolyte, knell]:
		kin.encounter_id = ArsenalCatalog.SPRIGGAN_KIN
	behemoth.encounter_id = ArsenalCatalog.CRAG_BACK_DRAKE
	lasher.blow_sign = ScribeSignResource.Sign.SIGN_IRON_ROOT
	hulk.blow_sign = ScribeSignResource.Sign.SIGN_IRON_ROOT
	puff.blow_sign = ScribeSignResource.Sign.SIGN_STAR_TIDE
	for kin: MobVariantResource in [prowler, toad, alpha, acolyte]:
		kin.blow_sign = ScribeSignResource.Sign.SIGN_RIME_GALE
	for kin: MobVariantResource in [cutthroat, slinger, foreman, behemoth]:
		kin.blow_sign = ScribeSignResource.Sign.SIGN_IRON_ROOT
	for kin: MobVariantResource in [husk, knell]:
		kin.blow_sign = ScribeSignResource.Sign.SIGN_STAR_TIDE
	_add_crown_trial_kin()
	_add_crown_shore_kin()


## Family 7: the guards and capstones of The Crown's three trials (Lv 15-18).
static func _add_crown_trial_kin() -> void:
	var sentinel: MobVariantResource = _make(FORGE_CLAD_SENTINEL, "Forge-Clad Sentinel", Family.CROWN_TRIAL_KIN, 16, Body.HUMANOID, 900.0, 90.0, 28.0)
	_hostile(sentinel, 12.0, 1.0, 1.2)
	sentinel.mitigation = 0.35
	sentinel.radius = 0.6
	sentinel.height = 2.2
	sentinel.reach = 2.0
	sentinel.hit_radius = 1.5
	sentinel.main_color = Color(0.42, 0.3, 0.24)
	sentinel.accent_color = Color(0.95, 0.52, 0.18)
	sentinel.eye_color = Color(1.0, 0.62, 0.2)
	var colossus: MobVariantResource = _make(ANVIL_WARDEN_COLOSSUS, "The Anvil-Warden Colossus", Family.CROWN_TRIAL_KIN, 18, Body.HULK, 5200.0, 180.0, 42.0)
	_hostile(colossus, 14.0, 1.4, 1.6)
	colossus.rank = Rank.BOSS
	# Its molten-iron carapace: nine tenths of every blow glance off until its poise breaks; then it takes it all.
	colossus.mitigation = 0.88
	colossus.knockdown_damage_taken = 7.5
	colossus.radius = 1.4
	colossus.height = 3.6
	colossus.reach = 2.8
	colossus.hit_radius = 2.4
	colossus.move_speed = 2.4
	colossus.turn_speed = 2.6
	colossus.stomps = true
	colossus.main_color = Color(0.3, 0.24, 0.22)
	colossus.accent_color = Color(1.0, 0.5, 0.14)
	colossus.eye_color = Color(1.0, 0.72, 0.3)
	var harrier: MobVariantResource = _make(RIME_WING_HARRIER, "Rime-Wing Harrier", Family.CROWN_TRIAL_KIN, 16, Body.WOLF, 700.0, 50.0, 22.0)
	_hostile(harrier, 16.0, 0.7, 6.0)
	harrier.move_speed = 6.0
	harrier.main_color = Color(0.84, 0.9, 0.96)
	harrier.accent_color = Color(0.4, 0.62, 0.86)
	harrier.eye_color = Color(0.5, 0.86, 1.0)
	var vaelen: MobVariantResource = _make(STORM_CALLER_VAELEN, "Storm-Caller Vaelen", Family.CROWN_TRIAL_KIN, 18, Body.WIGHT, 4600.0, 120.0, 36.0)
	_hostile(vaelen, 18.0, 0.9, 9.0)
	vaelen.rank = Rank.BOSS
	vaelen.move_speed = 6.2
	# The wind-shear charge's long recovery is the Glacial Rupture window.
	vaelen.recovery = 1.6
	vaelen.radius = 0.7
	vaelen.height = 2.6
	vaelen.reach = 2.2
	vaelen.hit_radius = 1.8
	vaelen.main_color = Color(0.7, 0.8, 0.9)
	vaelen.accent_color = Color(0.3, 0.52, 0.8)
	vaelen.eye_color = Color(0.7, 0.95, 1.0)
	var wight: MobVariantResource = _make(TARNISHED_SCRIBE_WIGHT, "Tarnished Scribe-Wight", Family.CROWN_TRIAL_KIN, 16, Body.WIGHT, 650.0, 45.0, 20.0)
	_hostile(wight, 15.0, 1.0, 0.0)
	wight.mitigation = 0.25
	wight.ranged = true
	wight.projectile_look = ArsenalCatalog.SCRIBE_STAFF
	wight.projectile_range = 16.0
	wight.main_color = Color(0.4, 0.34, 0.48)
	wight.accent_color = Color(0.62, 0.4, 0.92)
	wight.eye_color = Color(0.78, 0.55, 1.0)
	var prelate: MobVariantResource = _make(SIPHON_PRELATE, "The Siphon-Prelate", Family.CROWN_TRIAL_KIN, 18, Body.HULK, 5000.0, 140.0, 38.0)
	_hostile(prelate, 14.0, 1.2, 1.4)
	prelate.rank = Rank.BOSS
	prelate.mitigation = 0.3
	prelate.radius = 1.2
	prelate.height = 3.2
	prelate.reach = 2.6
	prelate.hit_radius = 2.2
	prelate.move_speed = 2.8
	prelate.main_color = Color(0.26, 0.2, 0.32)
	prelate.accent_color = Color(0.6, 0.32, 0.9)
	prelate.eye_color = Color(0.82, 0.6, 1.0)
	_spirit(sentinel, Equilibrium.BOGGART_AWOKEN, Resolution.STATE_STEWARD_HELPER, Form.SINK_TO_SLEEP)
	_spirit(colossus, Equilibrium.BOGGART_AWOKEN, Resolution.STATE_STEWARD_HELPER, Form.SINK_TO_SLEEP)
	_spirit(harrier, Equilibrium.BOGGART_AWOKEN, Resolution.STATE_UNBOGGART_RELEASE, Form.SEA_SWALLOW)
	_spirit(vaelen, Equilibrium.BOGGART_AWOKEN, Resolution.STATE_UNBOGGART_RELEASE, Form.SEA_SWALLOW)
	_spirit(wight, Equilibrium.BOGGART_AWOKEN, Resolution.STATE_LULLED_CAIRN, Form.HEDGE_WREN)
	_spirit(prelate, Equilibrium.BOGGART_AWOKEN, Resolution.STATE_LULLED_CAIRN, Form.HEDGE_WREN)
	for kin: MobVariantResource in [sentinel, colossus]:
		kin.blow_sign = ScribeSignResource.Sign.SIGN_IRON_ROOT
	for kin: MobVariantResource in [harrier, vaelen]:
		kin.blow_sign = ScribeSignResource.Sign.SIGN_RIME_GALE
	for kin: MobVariantResource in [wight, prelate]:
		kin.blow_sign = ScribeSignResource.Sign.SIGN_STAR_TIDE


## Family 8: the kin of The Crown's three shores outside the trials (Lv 15-17),
## tuned between the outer isles' elites and the trials' guards, each one the
## trial's lesson in small (docs/23 §5).
static func _add_crown_shore_kin() -> void:
	# Iron Shore: posture. Their clinker shells glance blows until the poise breaks.
	var clinker: MobVariantResource = _make(CLINKER_IRON_MAN, "Clinker Iron-Man", Family.CROWN_SHORE_KIN, 15, Body.HUMANOID, 420.0, 80.0, 20.0)
	_hostile(clinker, 11.0, 1.0, 1.2)
	clinker.mitigation = 0.55
	clinker.knockdown_damage_taken = 3.0
	clinker.radius = 0.55
	clinker.height = 2.0
	clinker.main_color = Color(0.36, 0.28, 0.24)
	clinker.accent_color = Color(0.9, 0.48, 0.18)
	clinker.eye_color = Color(1.0, 0.6, 0.2)
	var scuttler: MobVariantResource = _make(CINDER_SCUTTLER, "Cinder-Scuttler Hob", Family.CROWN_SHORE_KIN, 15, Body.SCUTTLER, 200.0, 30.0, 14.0)
	_hostile(scuttler, 10.0, 0.7, 3.0)
	scuttler.move_speed = 5.0
	scuttler.main_color = Color(0.24, 0.2, 0.2)
	scuttler.accent_color = Color(1.0, 0.46, 0.16)
	var bellows: MobVariantResource = _make(OLD_BELLOWS, "Old Bellows", Family.CROWN_SHORE_KIN, 17, Body.HULK, 2400.0, 140.0, 32.0)
	_hostile(bellows, 12.0, 1.3, 1.4)
	bellows.rank = Rank.RARE
	# A rare walks its shore's track (its spawner's patrol) when it isn't fighting.
	bellows.patrols = true
	bellows.mitigation = 0.7
	bellows.knockdown_damage_taken = 5.0
	bellows.stomps = true
	bellows.radius = 1.3
	bellows.height = 3.3
	bellows.reach = 2.6
	bellows.hit_radius = 2.2
	bellows.move_speed = 2.2
	bellows.main_color = Color(0.28, 0.22, 0.2)
	bellows.accent_color = Color(1.0, 0.56, 0.2)
	bellows.eye_color = Color(1.0, 0.76, 0.32)
	# Gale Cliffs: mobility. Long straight dashes to step aside from, darting hobs.
	var gust: MobVariantResource = _make(GUST_PADFOOT, "Gust-Padfoot", Family.CROWN_SHORE_KIN, 15, Body.WOLF, 340.0, 40.0, 18.0)
	_hostile(gust, 13.0, 0.75, 7.0)
	gust.move_speed = 5.6
	gust.recovery = 0.9
	gust.main_color = Color(0.78, 0.84, 0.9)
	gust.accent_color = Color(0.4, 0.58, 0.8)
	gust.eye_color = Color(0.6, 0.9, 1.0)
	var scree: MobVariantResource = _make(SCREE_HOB, "Scree-Hob", Family.CROWN_SHORE_KIN, 15, Body.SCUTTLER, 190.0, 28.0, 12.0)
	_hostile(scree, 11.0, 0.7, 3.4)
	scree.move_speed = 5.2
	scree.main_color = Color(0.56, 0.58, 0.6)
	scree.accent_color = Color(0.36, 0.5, 0.66)
	var squall: MobVariantResource = _make(GREY_SQUALL, "The Grey Squall", Family.CROWN_SHORE_KIN, 17, Body.WOLF, 1800.0, 90.0, 28.0)
	_hostile(squall, 14.0, 0.8, 10.0)
	squall.rank = Rank.RARE
	# A rare walks its shore's track (its spawner's patrol) when it isn't fighting.
	squall.patrols = true
	squall.move_speed = 6.6
	# Its long charge's long recovery is the window to answer in.
	squall.recovery = 1.3
	squall.radius = 0.95
	squall.height = 1.6
	squall.reach = 2.0
	squall.main_color = Color(0.62, 0.66, 0.7)
	squall.accent_color = Color(0.3, 0.46, 0.72)
	squall.eye_color = Color(0.7, 0.95, 1.0)
	# Tide Grottos: darkness and cleansing. Wallowers in the pools, lashers rooted at the sluices.
	var bucca: MobVariantResource = _make(SAP_SODDEN_BUCCA, "Sap-Sodden Bucca", Family.CROWN_SHORE_KIN, 15, Body.TOAD, 380.0, 40.0, 18.0)
	_hostile(bucca, 11.0, 0.8, 3.0)
	bucca.move_speed = 3.0
	bucca.main_color = Color(0.3, 0.28, 0.38)
	bucca.accent_color = Color(0.62, 0.38, 0.9)
	bucca.eye_color = Color(0.8, 0.6, 1.0)
	var lasher: MobVariantResource = _make(BLIGHT_LASHER, "Blight-Lasher Hob", Family.CROWN_SHORE_KIN, 15, Body.VINE, 340.0, 70.0, 18.0)
	_hostile(lasher, 7.0, 0.9, 0.0)
	_bark(lasher)
	lasher.rooted = true
	lasher.reach = 3.6
	lasher.hit_radius = 1.4
	lasher.main_color = Color(0.26, 0.3, 0.26)
	lasher.accent_color = Color(0.56, 0.3, 0.86)
	var sluice: MobVariantResource = _make(MOTHER_SLUICE, "Mother Sluice", Family.CROWN_SHORE_KIN, 17, Body.SHAMBLER, 2200.0, 120.0, 26.0)
	_hostile(sluice, 12.0, 1.1, 0.0)
	sluice.rank = Rank.RARE
	# A rare walks its shore's track (its spawner's patrol) when it isn't fighting.
	sluice.patrols = true
	sluice.mitigation = 0.35
	sluice.move_speed = 2.6
	sluice.reach = 0.4
	sluice.hit_radius = 3.0
	sluice.radius = 1.2
	sluice.height = 2.4
	sluice.main_color = Color(0.3, 0.26, 0.36)
	sluice.accent_color = Color(0.66, 0.4, 0.95)
	sluice.eye_color = Color(0.85, 0.65, 1.0)
	_spirit(clinker, Equilibrium.BOGGART_AWOKEN, Resolution.STATE_STEWARD_HELPER, Form.SINK_TO_SLEEP)
	_spirit(bellows, Equilibrium.BOGGART_AWOKEN, Resolution.STATE_STEWARD_HELPER, Form.SINK_TO_SLEEP)
	for kin: MobVariantResource in [scuttler, gust, scree, squall]:
		_spirit(kin, Equilibrium.BOGGART_AWOKEN, Resolution.STATE_UNBOGGART_RELEASE, Form.SEA_SWALLOW)
	for kin: MobVariantResource in [bucca, lasher, sluice]:
		_spirit(kin, Equilibrium.BOGGART_AWOKEN, Resolution.STATE_LULLED_CAIRN, Form.HEDGE_WREN)
	for kin: MobVariantResource in [clinker, scuttler, bellows]:
		kin.blow_sign = ScribeSignResource.Sign.SIGN_IRON_ROOT
	for kin: MobVariantResource in [gust, scree, squall]:
		kin.blow_sign = ScribeSignResource.Sign.SIGN_RIME_GALE
	for kin: MobVariantResource in [bucca, lasher, sluice]:
		kin.blow_sign = ScribeSignResource.Sign.SIGN_STAR_TIDE


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
