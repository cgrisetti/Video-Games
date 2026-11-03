## One Calling's chamber voice (16_ADAPTIVE_AUDIO_ARCHITECTURE.md §3.2, §7.2 C):
## its Fellowship, lead instrument, the posture motif played over the zone's
## tonic when a hero takes the Calling, and the band it keeps to so the nine
## never muddy each other. Pure data in AudioCatalog.
class_name CallingAudioProfileResource
extends Resource

## The Calling's id in ArsenalCatalog (&"bridge_warden").
@export var calling_id: StringName = &"bridge_warden"
@export var display_name: String = "Bridge-Warden"
## &"SHIELD_SWORN", &"WAYFARERS" or &"LANTERN_BEARERS".
@export var trinity_family: StringName = &"SHIELD_SWORN"
@export var lead_instrument: StringName = &"BRONZE_BELL_CELLO_PIZZ"
## The stem the character-select ensemble would bring in for this Calling.
@export var character_select_stem_index: int = 2
@export var posture_motif_intervals: PackedInt32Array = PackedInt32Array([0, 7, 12])
@export var frequency_band_hz: Vector2 = Vector2(80.0, 350.0)
## Octaves from the zone's tonic (Shield-Sworn low, Lantern-Bearers high).
@export var octave_shift: int = -1
