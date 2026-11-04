## How a foe opens to a Bravery Counter (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §2–3,
## and §8's Miyamoto Posture Escalation): its tier, its level, the Signs and
## locks that crack it, and how long its Glimmer-Spot stays open as the family
## learns the pattern.
##
## The four tiers grow with the trail, so each teaches one more thing:
## - TIER_0_PUNCHING_BAG (Lv 1-2: roadside pebbles, Scree-Worms, the
##   expedition's minions) is always open: any Iron-Root strike cracks it for
##   1.25x poise, with no text.
## - TIER_1_SINGLE_EVADE (Lv 3-5) fights in its attacking posture until it
##   drops to 75% health, then leaps 3 m back, sheds an armour plate and shows
##   a lock: a MARTIAL_COMBO_KEY (white-gold, cracked by a stunning combo such
##   as the Sundering Gap-Leap) or an ELEMENTAL_INK_KEY (in a Sign's colour,
##   cracked by a Weapon-Coat or a Support's Ink-Share of that Sign). Cracking
##   it is a Bravery Counter: (60 + 45) poise times the impact multiplier, and
##   a 2.5 s stun. Plain blows still work while it's locked, at half damage
##   (uninked_physical_mult), so nobody is ever stuck.
## - TIER_2_MULTI_LOCK (Lv 6-15) does it again at every gate threshold (75%,
##   50%, 25%), each lock its own key (gate_weakness_signs).
## - TIER_3_FOUR_GATE_BOSS (the milestone bosses: Lv 5, 10, 15, 25 ... 60)
##   plays the four gates (BossGateComponent): the Measure, the Summons (an
##   Aegis Mantle and henchmen), the Tempest (the arena telegraphs and a
##   shifted weakness) and the Seal-Turn. Its Glimmer-Spot opens during its
##   pattern for the scaled window: 12 frames tighter for each of the party's
##   first five sightings, down to the floor.
##
## Encounters are data, registered by id in ArsenalCatalog (Gate 4); a new foe
## is one register call, and the same components play any of them.
class_name BossEncounterResource
extends Resource

enum MiyamotoTier { TIER_0_PUNCHING_BAG = 0, TIER_1_SINGLE_EVADE = 1, TIER_2_MULTI_LOCK = 2, TIER_3_FOUR_GATE_BOSS = 3 }
## What cracks a Tier 1 or 2 foe's lock.
enum LockKeyType { NONE = 0, MARTIAL_COMBO_KEY = 1, ELEMENTAL_INK_KEY = 2 }

## Frames in a second: every window is counted at 60 FPS.
const FRAMES_PER_SECOND: int = 60
## A Tier 0 foe's window never closes.
const ALWAYS_OPEN_FRAMES: int = 999999
## Each sighting tightens the window by this many frames, for the first MAX_TIGHTENING_SIGHTINGS.
const FRAMES_PER_SIGHTING: int = 12
const MAX_TIGHTENING_SIGHTINGS: int = 5
## The HUD rhyme shows on the first sightings and hides once this many have been seen.
const RHYME_HIDDEN_AFTER: int = 3
## A Bravery Counter's poise before the impact multiplier: 60 for the counter, 45 for Shatterpoint.
const BRAVERY_COUNTER_POISE: float = 60.0
const BRAVERY_SIGN_POISE: float = 45.0
## Tier 0: an Iron-Root strike cracks minor kin for this much more poise.
const TIER_0_POISE_MULTIPLIER: float = 1.25
## A cracked lock stuns the foe this long.
const LOCK_COUNTER_STUN: float = 2.5
## M(L) = 1.25 + 3.75 * (L / 60) ^ 1.6
const IMPACT_BASE: float = 1.25
const IMPACT_RANGE: float = 3.75
const IMPACT_EXPONENT: float = 1.6
const MAX_ENCOUNTER_LEVEL: float = 60.0
const GATE_COUNT: int = 4
const TIER_NAMES: Array[String] = ["Roadside Kin", "Leaping Kin", "Many-Locked Kin", "Four-Gate Boss"]
const GATE_NAMES: Array[String] = ["The Measure", "The Summons", "The Tempest", "The Seal-Turn"]
const LOCK_NAMES: Array[String] = ["", "Martial lock", "Ink lock"]

@export var encounter_id: StringName = &""
@export var display_name: String = ""
@export var miyamoto_tier: MiyamotoTier = MiyamotoTier.TIER_0_PUNCHING_BAG
@export var encounter_level: int = 1
## ScribeSignResource.Sign values whose strikes crack the Glimmer-Spot (and an ELEMENTAL_INK_KEY lock).
@export var weakness_counter_signs: Array[int] = []
@export var base_glimmer_window_frames: int = 180
@export var floor_glimmer_window_frames: int = 45
## Two lines of coaching shown on the HUD while the Glimmer-Spot is open, for the first sightings.
@export_multiline var hud_rhyme_couplet: String = ""
## What the foe is doing when it opens ("roar", "wing-spread").
@export var opening_pattern: String = ""

@export_group("Evasive armour-drop (Tiers 1 and 2)")
## Tier 1 leaps back and locks at this share of its health.
@export var evade_armor_drop_hp_pct: float = 0.75
## How far it leaps (0 for a rooted foe, which sheds its plate where it stands).
@export var evade_leap_distance_m: float = 3.0
@export var primary_lock_type: LockKeyType = LockKeyType.NONE
## Struck with a plain blow while locked, a foe takes this share of the damage (a dull clank).
@export var uninked_physical_mult: float = 0.50

@export_group("Gates (Tier 2 locks, Tier 3 bosses)")
## The health shares where the next gate (or the next lock) begins.
@export var gate_thresholds: Array[float] = [0.75, 0.50, 0.25]
## Each gate's own weakness (a Sign, or NONE to keep weakness_counter_signs), in gate order from Gate 1.
## A Tier 2 foe's lock at threshold i is an ink lock of gate_weakness_signs[i + 1] when one is set.
@export var gate_weakness_signs: Array[int] = []
## Gate 2's summons: the henchman template (ArsenalCatalog.henchman_kind) and how many.
@export var gate_2_henchman_id: StringName = &"mob_scree_worm"
@export var gate_2_henchman_count: int = 3


func is_always_open() -> bool:
	return miyamoto_tier == MiyamotoTier.TIER_0_PUNCHING_BAG


## Tier 1 and 2 foes leap back, shed armour and lock.
func has_armor_drop() -> bool:
	return miyamoto_tier == MiyamotoTier.TIER_1_SINGLE_EVADE or miyamoto_tier == MiyamotoTier.TIER_2_MULTI_LOCK


func is_four_gate_boss() -> bool:
	return miyamoto_tier == MiyamotoTier.TIER_3_FOUR_GATE_BOSS


## How many frames the Glimmer-Spot stays open after `pattern_seen_count` earlier sightings.
func get_scaled_glimmer_frames(pattern_seen_count: int) -> int:
	if is_always_open():
		return ALWAYS_OPEN_FRAMES
	return maxi(floor_glimmer_window_frames,
		base_glimmer_window_frames - FRAMES_PER_SIGHTING * mini(maxi(pattern_seen_count, 0), MAX_TIGHTENING_SIGHTINGS))


func get_scaled_glimmer_seconds(pattern_seen_count: int) -> float:
	return float(get_scaled_glimmer_frames(pattern_seen_count)) / FRAMES_PER_SECOND


## M(L): how much harder a Bravery Counter lands at this encounter's level (1.25 at 0, 5.0 at 60).
func get_impact_multiplier() -> float:
	return IMPACT_BASE + IMPACT_RANGE * pow(clampf(float(encounter_level) / MAX_ENCOUNTER_LEVEL, 0.0, 1.0), IMPACT_EXPONENT)


## A Bravery Counter's poise damage here: (60 + 45) x M(L).
func bravery_counter_poise() -> float:
	return (BRAVERY_COUNTER_POISE + BRAVERY_SIGN_POISE) * get_impact_multiplier()


## Whether a strike carrying `scribe_sign` cracks this foe's Glimmer-Spot (in Gate 1, or for a foe without gates).
func is_countered_by(scribe_sign: int) -> bool:
	return is_countered_in_gate(scribe_sign, 0)


## Whether a strike carrying `scribe_sign` cracks the Glimmer-Spot in gate `gate` (0 for Gate 1).
func is_countered_in_gate(scribe_sign: int, gate: int) -> bool:
	return scribe_sign != ScribeSignResource.Sign.NONE and weakness_for_gate(gate).has(scribe_sign)


## The Signs that crack the spot in gate `gate`: its own weakness, or weakness_counter_signs.
func weakness_for_gate(gate: int) -> Array[int]:
	if gate >= 0 and gate < gate_weakness_signs.size() and gate_weakness_signs[gate] != ScribeSignResource.Sign.NONE:
		var shifted: Array[int] = [gate_weakness_signs[gate]]
		return shifted
	return weakness_counter_signs


## Which gate a boss at this share of its health is in (0 for Gate 1, 3 for Gate 4).
func gate_for_health(health_ratio: float) -> int:
	var gate: int = 0
	for threshold: float in gate_thresholds:
		if health_ratio <= threshold + 0.0001:
			gate += 1
	return mini(gate, GATE_COUNT - 1)


## The health shares where a Tier 1 or 2 foe locks: one for Tier 1, every gate threshold for Tier 2.
func lock_thresholds() -> Array[float]:
	var shares: Array[float] = []
	match miyamoto_tier:
		MiyamotoTier.TIER_1_SINGLE_EVADE:
			shares.append(evade_armor_drop_hp_pct)
		MiyamotoTier.TIER_2_MULTI_LOCK:
			shares.assign(gate_thresholds)
	return shares


## The kind of key the lock at threshold `index` takes.
func lock_type_at(index: int) -> LockKeyType:
	if miyamoto_tier == MiyamotoTier.TIER_2_MULTI_LOCK:
		var sign_at: int = _gate_sign(index + 1)
		if sign_at != ScribeSignResource.Sign.NONE:
			return LockKeyType.ELEMENTAL_INK_KEY
	return primary_lock_type


## The Signs that crack the lock at threshold `index` (none for a martial lock).
func lock_signs_at(index: int) -> Array[int]:
	var signs: Array[int] = []
	if lock_type_at(index) != LockKeyType.ELEMENTAL_INK_KEY:
		return signs
	var sign_at: int = _gate_sign(index + 1) if miyamoto_tier == MiyamotoTier.TIER_2_MULTI_LOCK else ScribeSignResource.Sign.NONE
	if sign_at != ScribeSignResource.Sign.NONE:
		signs.append(sign_at)
	else:
		signs.assign(weakness_counter_signs)
	return signs


## Whether the HUD shows the rhyme after this many sightings (the count includes the one now).
func shows_rhyme(pattern_seen_count: int) -> bool:
	return hud_rhyme_couplet != "" and not is_always_open() and pattern_seen_count < RHYME_HIDDEN_AFTER


func tier_name() -> String:
	return TIER_NAMES[miyamoto_tier]


func _gate_sign(gate: int) -> int:
	return gate_weakness_signs[gate] if gate >= 0 and gate < gate_weakness_signs.size() else ScribeSignResource.Sign.NONE
