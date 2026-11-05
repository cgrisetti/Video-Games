## A boss's encounter suite (16_ADAPTIVE_AUDIO_ARCHITECTURE.md §4.5, §5.3 Stage C):
## the ZoneMusicProfileResource its deck plays (Stem 1 is the Lydian flourish
## held back for the Poise-Stagger window), when Phase 2 lifts the discord
## stem, how hard the percussion ducks while the boss is staggered, and the
## acoustic flourish that marks the stagger.
## Pure data in AudioCatalog.
class_name BossAudioProfileResource
extends Resource

const DEFAULT_CROSSFADE_BEATS: float = 2.0
const DEFAULT_STAGGER_DUCK_DB: float = -14.0
const DEFAULT_STAGGER_DISCORD_DUCK_DB: float = -18.0

## The boss's BossEncounterResource id (&"cairnsman").
@export var boss_id: StringName = &"cairnsman"
@export var display_title: String = "The Cairnsman's Vigil"
## The ZoneMusicProfileResource the boss deck plays.
@export var suite_profile_id: StringName = &"cairnsmans_vigil"
## Zone deck to boss deck, in beats of the suite.
@export var crossfade_beats: float = DEFAULT_CROSSFADE_BEATS
## Below this share of health, Phase 2 lifts the discord counterpoint.
@export var phase_two_health_ratio: float = 0.55
## Stem 3 (percussion) drops this far while the boss is poise-staggered.
@export var stagger_percussion_duck_db: float = DEFAULT_STAGGER_DUCK_DB
## Stem 2 (the minor counterpoint) drops this far in the stagger window, so the Lydian lift rings clear.
@export var stagger_discord_duck_db: float = DEFAULT_STAGGER_DISCORD_DUCK_DB
## The baked flourish (in the suite's key); without it the flourish is played by ProceduralChamberSynth.
@export_file("*.wav", "*.ogg") var stagger_stinger_path: String = ""
## The flourish stinger on the stagger frame, in semitones over the suite's tonic (D Lydian).
@export var stagger_flourish_intervals: PackedInt32Array = PackedInt32Array([0, 4, 6, 7, 11, 12, 16])
