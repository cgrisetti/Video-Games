## How a foe opens to a Bravery Counter (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §2–3):
## its threat tier, its level, the Signs that crack it, and how long its
## Glimmer-Spot stays open as the family learns the pattern.
##
## Tier 1 kin (roadside pebbles, Scree-Worms, the expedition's minions) are
## always open: any Iron-Root strike cracks them for 1.25x poise, with no text.
## Tier 2 and 3 foes open a Glimmer-Spot during one pattern (the Cairnsman's
## roar as he starts a raid cast). Striking it with one of their counter Signs
## is a Bravery Counter: (60 + 45) poise times the encounter's impact
## multiplier, and the Sign's detonation. Every sighting tightens the window by
## 12 frames (60 per second) for the first five, down to the encounter's floor.
##
## Encounters are data, registered by id in ArsenalCatalog (Gate 4); a new boss
## is one register call, and GlimmerSpotComponent plays any of them the same way.
class_name BossEncounterResource
extends Resource

enum ThreatTier { TIER_1_MINOR_PEBBLE = 1, TIER_2_TRAIL_WARDEN = 2, TIER_3_MILESTONE_BOSS = 3 }

## Frames in a second: every window is counted at 60 FPS.
const FRAMES_PER_SECOND: int = 60
## A Tier 1 foe's window never closes.
const ALWAYS_OPEN_FRAMES: int = 999999
## Each sighting tightens the window by this many frames, for the first MAX_TIGHTENING_SIGHTINGS.
const FRAMES_PER_SIGHTING: int = 12
const MAX_TIGHTENING_SIGHTINGS: int = 5
## The HUD rhyme shows on the first sightings and hides once this many have been seen.
const RHYME_HIDDEN_AFTER: int = 3
## A Bravery Counter's poise before the impact multiplier: 60 for the counter, 45 for Shatterpoint.
const BRAVERY_COUNTER_POISE: float = 60.0
const BRAVERY_SIGN_POISE: float = 45.0
## Tier 1: an Iron-Root strike cracks minor kin for this much more poise.
const TIER_1_POISE_MULTIPLIER: float = 1.25
## M(L) = 1.25 + 3.75 * (L / 60) ^ 1.6
const IMPACT_BASE: float = 1.25
const IMPACT_RANGE: float = 3.75
const IMPACT_EXPONENT: float = 1.6
const MAX_ENCOUNTER_LEVEL: float = 60.0
const TIER_NAMES: Array[String] = ["", "Roadside Kin", "Trail Warden", "Milestone Boss"]

@export var encounter_id: StringName = &""
@export var display_name: String = ""
@export var threat_tier: ThreatTier = ThreatTier.TIER_1_MINOR_PEBBLE
@export var encounter_level: int = 1
## ScribeSignResource.Sign values whose strikes crack the Glimmer-Spot.
@export var weakness_counter_signs: Array[int] = []
@export var base_glimmer_window_frames: int = 180
@export var floor_glimmer_window_frames: int = 45
## Two lines of coaching shown on the HUD while the Glimmer-Spot is open, for the first sightings.
@export_multiline var hud_rhyme_couplet: String = ""
## What the foe is doing when it opens ("roar", "wing-spread").
@export var opening_pattern: String = ""


func is_always_open() -> bool:
	return threat_tier == ThreatTier.TIER_1_MINOR_PEBBLE


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


## Whether a strike carrying `scribe_sign` cracks this foe.
func is_countered_by(scribe_sign: int) -> bool:
	return scribe_sign != ScribeSignResource.Sign.NONE and weakness_counter_signs.has(scribe_sign)


## Whether the HUD shows the rhyme after this many sightings (the count includes the one now).
func shows_rhyme(pattern_seen_count: int) -> bool:
	return hud_rhyme_couplet != "" and not is_always_open() and pattern_seen_count < RHYME_HIDDEN_AFTER


func tier_name() -> String:
	return TIER_NAMES[threat_tier]
