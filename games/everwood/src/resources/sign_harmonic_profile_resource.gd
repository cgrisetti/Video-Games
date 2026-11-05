## How one of the Four Scribe Signs sounds when it detonates
## (16_ADAPTIVE_AUDIO_ARCHITECTURE.md §3.2, §7.2 B): a chamber stinger whose
## chord is set in semitones above the active zone's tonic, and the Music bus's
## duck while it rings (-4.5 dB for 300 ms). AudioDirector plays the acoustic
## chord baked in G (res://assets/audio/samples/<sign_id lower-cased>.wav)
## re-pitched to the zone's tonic. Pure data in AudioCatalog.
class_name SignHarmonicProfileResource
extends Resource

const DEFAULT_SIDECHAIN_DUCK_DB: float = -4.5
const DEFAULT_SIDECHAIN_DURATION_SEC: float = 0.3

## The Sign's ScribeSignResource.Sign key ("SIGN_IRON_ROOT").
@export var sign_id: StringName = &"SIGN_IRON_ROOT"
@export var instrument_timbre: StringName = &"BASSOON_CELLO_ANVIL_CHIME"
## Semitone offsets relative to the active ZoneMusicProfileResource.root_pitch_midi
@export var chord_semitone_intervals: PackedInt32Array = PackedInt32Array([0, 7, 12])
@export var arpeggio_step_sec: float = 0.035
@export var sidechain_duck_db: float = DEFAULT_SIDECHAIN_DUCK_DB
@export var sidechain_duration_sec: float = DEFAULT_SIDECHAIN_DURATION_SEC
## Octaves to shift the chord from the zone's tonic (the bassoon sits one down).
@export var octave_shift: int = 0
## A stinger to play instead of the baked one (also re-pitched from G to the zone's tonic).
@export_file("*.wav", "*.ogg") var custom_stinger_path: String = ""


## The stinger's MIDI notes over a zone tonic.
func notes_over(root_midi: int) -> PackedInt32Array:
	var notes: PackedInt32Array = PackedInt32Array()
	for interval: int in chord_semitone_intervals:
		notes.append(root_midi + octave_shift * 12 + interval)
	return notes
