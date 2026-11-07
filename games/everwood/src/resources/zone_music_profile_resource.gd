## One zone's adaptive score (16_ADAPTIVE_AUDIO_ARCHITECTURE.md §4, §7.2 A): its
## key, mode and tempo, the four phase-locked stems' resting volumes, the
## optional depth blend into the Holloway discord, and the Brower silence
## breath between music cycles. Pure data; AudioCatalog registers them and
## AudioDirector plays them: the acoustic stems tools/build_audio_stems.py bakes
## (res://assets/audio/music/<profile_id>/), otherwise ProceduralChamberSynth's
## physical-model rendition of the same score.
##
## A zone with mosaic_cells is a Chamber-Folk Audio Mosaic (16 §7): instead of one
## loop it has twelve four-bar phrase cells, two in each of the six moods, and
## MusicMoodEngine picks the next one at every phrase boundary, so the tune, its
## chords and its lead voice keep changing. Each cell still has the four stems.
class_name ZoneMusicProfileResource
extends Resource

## The six composed moods of a mosaic (16 §7.1), in suite order of the brief.
enum MoodState {
	WONDER = 0,      ## Hisaishi's skyward lift: Lydian, soaring sixths and octaves
	INTEREST = 1,    ## the jaunty bustle: secondary dominants over a walking bass
	MELLOW = 2,      ## late-afternoon sway: warm Ionian / Mixolydian in parallel sixths
	PEACE = 3,       ## Shore's hearth: pentatonic over an open-fifth drone, then the silence breath
	CURIOSITY = 4,   ## a two-part woodwind invention: Dorian, ending on a question
	ANXIOUSNESS = 5  ## Into the Unknown: harmonic minor and a diminished seventh, the discord stem up
}
const MOOD_COUNT: int = 6
const MOOD_NAMES: Array[String] = ["WONDER", "INTEREST", "MELLOW", "PEACE", "CURIOSITY", "ANXIOUSNESS"]

## The four Hisaishi Quartet voicings a cell's lead is carried by (16 §7.2).
enum LeadVoice {
	OCEAN_VIEW = 0,         ## Variation A: pizzicato strings and accordion lead, bassoon counter-melody
	SKY_SOAR = 1,           ## Variation B: legato violin (or cello) in sixths over guitar and harp
	WOODWIND_DIALOGUE = 2,  ## Variation C: oboe and bassoon call and response over mandolin
	PASTORAL_HEARTH = 3     ## Variation D: low whistle or recorder over harp and cello fifths
}
const VOICE_LETTERS: Array[String] = ["A", "B", "C", "D"]

## Canonical tuning constants (Godot 4.7.2 verified)
const DEFAULT_BPM: float = 108.0
const DEFAULT_BEATS_PER_BAR: int = 3
const SILENCE_BUFFER_MIN_SEC: float = 15.0
const SILENCE_BUFFER_MAX_SEC: float = 30.0
const SKIRMISH_ATTACK_SEC: float = 0.4
const RESTORATION_EXHALE_SEC: float = 3.6
const POST_COMBAT_SILENCE_SEC: float = 10.0
const PROXIMITY_OUTER_RADIUS_M: float = 35.0
const PROXIMITY_INNER_RADIUS_M: float = 14.0

## Stem indices inside the phase-locked AudioStreamSynchronized resource
enum StemLayer {
	FOLK_BASE = 0,        ## Guitar, Mandolin, Harp, Pizzicato Bass
	PASTORAL_LEAD = 1,    ## Accordion, Legato Violin, Sunny Woodwinds (Lydian/Ionian)
	HOLLOWAY_DISCORD = 2, ## Bassoon, Oboe, Diminished/Harmonic Minor Counterpoint
	SKIRMISH_DRIVE = 3    ## Hammered Dulcimer, Bodhran, Rapid Folk Ostinato
}
const STEM_COUNT: int = 4

@export var profile_id: StringName = &"bramble_bridge_square"
@export var display_title: String = "Bramble-Bridge Waltz"
@export var root_pitch_midi: int = 67 ## 67 = G4 (the regional tonic of Tizzi-Wed-Green's trail)
@export var modal_signature: StringName = &"G_LYDIAN"
## Quarter-note tempo.
@export var bpm: float = DEFAULT_BPM
## Quarter notes per bar (3 for 3/4 and 6/8, 4 for 4/4).
@export var beats_per_bar: int = DEFAULT_BEATS_PER_BAR
## A 6/8 lilt: the code-built stems group eighths in threes.
@export var compound_meter: bool = false

## Optional path to a curated 4-stem AudioStreamSynchronized (.tres wrapping 4 .ogg streams).
## Without it AudioDirector finds res://assets/audio/music/<profile_id>_sync.tres, then the four
## baked .ogg stems beside it, then falls back to ProceduralChamberSynth.
@export_file("*.tres") var synchronized_stream_path: String = ""

## Default exploration stem volumes (in dB) when out of combat
@export var explore_stem_volumes_db: PackedFloat32Array = PackedFloat32Array([
	0.0,   ## Stem 0: FOLK_BASE active
	0.0,   ## Stem 1: PASTORAL_LEAD active
	-80.0, ## Stem 2: HOLLOWAY_DISCORD muted until Z-threshold or 35m Hush-Crack proximity
	-80.0  ## Stem 3: SKIRMISH_DRIVE muted until CombatDirector aggro
])

## Intra-zone world-Z threshold to blend Stem 1 -> Stem 2 (Rush-Light-Hollow's sunken lane)
@export var enable_z_depth_discord_blend: bool = false
@export var discord_blend_z_start: float = -54.0
@export var discord_blend_z_full: float = -74.0

## Silence breath window between exploration loop cycles (Russell Brower rule)
@export var silence_interval_range_sec: Vector2 = Vector2(SILENCE_BUFFER_MIN_SEC, SILENCE_BUFFER_MAX_SEC)
## Seconds of music before each silence breath.
@export var music_cycle_sec: float = 90.0
## Arriving here plays the Sanctuary Cadence (minor to Lydian: "coming home").
@export var sanctuary_cadence_on_arrival: bool = false
## Bars in the baked acoustic arrangement (tools/build_audio_stems.py); 0 means one per chord
## of the progression. Every tier of the score loops this many bars.
@export var arrangement_bars: int = 0

@export_group("Code-built stems (ProceduralChamberSynth)")
## Semitones above the root of the sunny lead and base stems' mode.
@export var lead_scale: PackedInt32Array = PackedInt32Array([0, 2, 4, 6, 7, 9, 11])
## Semitones above the root of the Holloway discord and skirmish stems' mode.
@export var discord_scale: PackedInt32Array = PackedInt32Array([0, 2, 3, 5, 7, 8, 11])
## Scale degree (0-based) each bar's harmony is built on; the loop is this many bars.
@export var progression: PackedInt32Array = PackedInt32Array([0, 1, 6, 0])
## Lead-scale degrees the melody steps over (Evan Call's spacing: no natural 4 in an Ionian tune).
@export var melody_skips_degrees: PackedInt32Array = PackedInt32Array()
## The lead stem's voice: &"WHISTLE", &"ACCORDION", &"VIOLIN" or &"REED".
@export var lead_timbre: StringName = &"ACCORDION"

@export_group("Audio Mosaic (16 §7)")
## The zone's phrase cells; empty for a classic single-loop score.
@export var mosaic_cells: Array[MosaicCellResource] = []
## Bars in one phrase cell (every cell of a zone is this long).
@export var phrase_bars: int = 4
## The cell the zone opens on when the party arrives with nothing chosen yet.
@export var opening_cell: int = 0


## A mood's name ("WONDER") for logs and the F4 line.
static func mood_name(mood: int) -> String:
	return MOOD_NAMES[mood] if mood >= 0 and mood < MOOD_NAMES.size() else "-"


## A voicing's letter and instruments ("Var B: Violin/Harp").
static func voice_name(voice: int, label: String) -> String:
	return "Var %s: %s" % [VOICE_LETTERS[voice] if voice >= 0 and voice < VOICE_LETTERS.size() else "?", label]


func is_mosaic() -> bool:
	return not mosaic_cells.is_empty()


## One phrase cell, in seconds.
func cell_sec() -> float:
	return bar_sec() * phrase_bars


func cell(index: int) -> MosaicCellResource:
	return mosaic_cells[index] if index >= 0 and index < mosaic_cells.size() else null


## The index of a cell by id (-1 if it isn't one of this zone's).
func cell_index(id: StringName) -> int:
	for index: int in mosaic_cells.size():
		if mosaic_cells[index].cell_id == id:
			return index
	return -1


## The cell that follows `index` when nothing chooses (the suite order).
func fallback_after(index: int) -> int:
	var made: MosaicCellResource = cell(index)
	if made == null:
		return 0
	return made.fallback_next if made.fallback_next >= 0 else (index + 1) % mosaic_cells.size()


## Seconds per quarter note.
func beat_sec() -> float:
	return 60.0 / maxf(bpm, 1.0)


func bar_sec() -> float:
	return beat_sec() * beats_per_bar


## Bars in one loop of the score: the baked arrangement's, else one per chord of the progression.
func loop_bars() -> int:
	return arrangement_bars if arrangement_bars > 0 else maxi(1, progression.size())


## One loop of the score, in seconds.
func loop_sec() -> float:
	return bar_sec() * loop_bars()


## Resting volume of a stem.
func explore_db(layer: int) -> float:
	return explore_stem_volumes_db[layer] if layer < explore_stem_volumes_db.size() else -80.0
