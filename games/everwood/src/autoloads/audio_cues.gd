## Audio cues (autoload "Audio"): short sounds synthesized in code the first
## time each is played, so the game ships no audio files. Cues are
## non-positional, so every couch player hears the big moments equally.
##   AudioCues.play(&"synergy_frost")
class_name AudioCues
extends Node

signal cue_played(cue: StringName)

enum Wave { SINE, SQUARE, SAW, NOISE }

const MIX_RATE: int = 22050
const VOICES: int = 10
const VOLUME_DB: float = -8.0
const ATTACK: float = 0.004
## Every cue the game plays, by name.
const CUES: Array[StringName] = [&"hit", &"flow", &"perfect_guard", &"seal_kinetic", &"seal_elemental",
	&"seal_divine", &"seal_celestial", &"shot", &"equip", &"card_chime", &"card_chime_foil", &"card_chime_astral", &"reward", &"knockdown", &"telegraph", &"soak_ok", &"soak_fail", &"heal", &"join",
	&"portal_charge", &"portal", &"victory", &"chest", &"purchase", &"refuse", &"menu_move"]
## How fast each note fades: amplitude reaches e^-DECAY at the note's end.
const DECAY: float = 3.5

class Note:
	var start: float
	var length: float
	var from_hz: float
	var to_hz: float
	var wave: Wave
	var gain: float

	func _init(note_start: float, note_length: float, start_hz: float, end_hz: float, note_wave: Wave, note_gain: float) -> void:
		start = note_start
		length = note_length
		from_hz = start_hz
		to_hz = end_hz
		wave = note_wave
		gain = note_gain

## The live autoload node (see NetworkManager.current for why).
static var current: AudioCues

var _streams: Dictionary[StringName, AudioStreamWAV] = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
## Headless runs have no speakers; cues still report themselves but play nothing,
## so a sound in flight at quit can't outlive the audio server.
var _silent: bool = false


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null
	# A sound still playing at quit would otherwise outlive the engine's shutdown.
	for voice: AudioStreamPlayer in _voices:
		voice.stop()
		voice.stream = null
	_streams.clear()


func _ready() -> void:
	_silent = DisplayServer.get_name() == "headless"
	for index: int in VOICES:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.name = "Voice%d" % index
		voice.volume_db = VOLUME_DB
		add_child(voice)
		_voices.append(voice)


## Plays a cue by name. Safe to call from anywhere, even before the autoload exists.
static func play(cue: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if current != null:
		current.play_cue(cue, pitch, volume_db)


func play_cue(cue: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if _silent:
		cue_played.emit(cue)
		return
	var voice: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = stream_for(cue)
	voice.pitch_scale = clampf(pitch, 0.25, 4.0)
	voice.volume_db = VOLUME_DB + volume_db
	voice.play()
	cue_played.emit(cue)


## The synthesized sound for a cue, built the first time it's asked for.
func stream_for(cue: StringName) -> AudioStreamWAV:
	if not _streams.has(cue):
		_streams[cue] = _render(_notes_for(cue))
	return _streams[cue]


func _notes_for(cue: StringName) -> Array[Note]:
	match cue:
		&"hit":
			return [Note.new(0.0, 0.07, 0.0, 0.0, Wave.NOISE, 0.35), Note.new(0.0, 0.1, 140.0, 70.0, Wave.SINE, 0.7)]
		&"flow":
			return [Note.new(0.0, 0.06, 1320.0, 1760.0, Wave.SINE, 0.45)]
		&"perfect_guard":
			return [Note.new(0.0, 0.5, 1760.0, 1760.0, Wave.SINE, 0.4), Note.new(0.0, 0.4, 2637.0, 2637.0, Wave.SINE, 0.25),
				Note.new(0.0, 0.05, 0.0, 0.0, Wave.NOISE, 0.3)]
		&"seal_kinetic":
			return _arpeggio([330.0, 415.0, 494.0, 659.0], 0.07, Wave.SQUARE, 0.3)
		&"seal_elemental":
			return _arpeggio([880.0, 1109.0, 1319.0, 1760.0], 0.07, Wave.SINE, 0.45)
		&"seal_divine":
			return _arpeggio([523.0, 659.0, 784.0, 1047.0], 0.08, Wave.SINE, 0.45)
		&"seal_celestial":
			var chorus: Array[Note] = _arpeggio([392.0, 587.0, 784.0, 1175.0, 1568.0], 0.09, Wave.SINE, 0.35)
			chorus.append(Note.new(0.0, 0.9, 196.0, 196.0, Wave.SINE, 0.3))
			return chorus
		&"card_chime":
			return [Note.new(0.0, 0.6, 1568.0, 1568.0, Wave.SINE, 0.35), Note.new(0.0, 0.45, 2349.0, 2349.0, Wave.SINE, 0.15)]
		&"card_chime_foil":
			return [Note.new(0.0, 0.7, 1568.0, 1568.0, Wave.SINE, 0.35), Note.new(0.0, 0.6, 2349.0, 2349.0, Wave.SINE, 0.2),
				Note.new(0.04, 0.6, 3136.0, 3136.0, Wave.SINE, 0.15)]
		&"card_chime_astral":
			var sparkle: Array[Note] = _arpeggio([1319.0, 1760.0, 2093.0, 2637.0, 3136.0], 0.06, Wave.SINE, 0.25)
			sparkle.append(Note.new(0.0, 1.2, 392.0, 392.0, Wave.SINE, 0.25))
			return sparkle
		&"shot":
			return [Note.new(0.0, 0.12, 900.0, 300.0, Wave.NOISE, 0.25), Note.new(0.0, 0.1, 620.0, 380.0, Wave.SINE, 0.3)]
		&"equip":
			return [Note.new(0.0, 0.06, 0.0, 0.0, Wave.NOISE, 0.25), Note.new(0.02, 0.18, 330.0, 494.0, Wave.SQUARE, 0.2)]
		&"reward":
			return [Note.new(0.0, 0.25, 988.0, 988.0, Wave.SINE, 0.35), Note.new(0.08, 0.3, 1319.0, 1319.0, Wave.SINE, 0.35)]
		&"knockdown":
			return [Note.new(0.0, 0.7, 120.0, 40.0, Wave.SINE, 0.9), Note.new(0.0, 0.2, 0.0, 0.0, Wave.NOISE, 0.4)]
		&"telegraph":
			return [Note.new(0.0, 0.18, 233.0, 233.0, Wave.SAW, 0.3), Note.new(0.24, 0.18, 233.0, 233.0, Wave.SAW, 0.3)]
		&"soak_ok":
			return [Note.new(0.0, 0.4, 659.0, 659.0, Wave.SINE, 0.4), Note.new(0.0, 0.45, 988.0, 988.0, Wave.SINE, 0.35)]
		&"soak_fail":
			return [Note.new(0.0, 0.4, 98.0, 92.0, Wave.SAW, 0.45)]
		&"heal":
			return [Note.new(0.0, 0.2, 784.0, 1175.0, Wave.SINE, 0.35)]
		&"join":
			return [Note.new(0.0, 0.12, 523.0, 523.0, Wave.SINE, 0.4), Note.new(0.1, 0.2, 784.0, 784.0, Wave.SINE, 0.4)]
		&"portal_charge":
			return _arpeggio([392.0, 494.0, 587.0], 0.18, Wave.SINE, 0.35)
		&"portal":
			return [Note.new(0.0, 0.9, 220.0, 1320.0, Wave.SINE, 0.5), Note.new(0.0, 0.9, 330.0, 1980.0, Wave.SINE, 0.25)]
		&"victory":
			var fanfare: Array[Note] = _arpeggio([392.0, 523.0, 659.0, 784.0, 1047.0], 0.11, Wave.SQUARE, 0.25)
			fanfare.append(Note.new(0.0, 1.2, 131.0, 131.0, Wave.SINE, 0.5))
			return fanfare
		&"purchase":
			return [Note.new(0.0, 0.1, 880.0, 880.0, Wave.SINE, 0.35), Note.new(0.07, 0.3, 1319.0, 1760.0, Wave.SINE, 0.35),
				Note.new(0.0, 0.05, 0.0, 0.0, Wave.NOISE, 0.15)]
		&"refuse":
			return [Note.new(0.0, 0.18, 196.0, 175.0, Wave.SAW, 0.3)]
		&"menu_move":
			return [Note.new(0.0, 0.04, 1200.0, 1200.0, Wave.SINE, 0.25)]
		&"chest":
			var sparkle: Array[Note] = _arpeggio([1319.0, 1568.0, 1976.0, 2637.0], 0.05, Wave.SINE, 0.3)
			sparkle.append(Note.new(0.0, 0.12, 180.0, 90.0, Wave.SINE, 0.6))
			return sparkle
	return [Note.new(0.0, 0.03, 0.0, 0.0, Wave.NOISE, 0.2)]


func _arpeggio(pitches: Array[float], step: float, wave: Wave, gain: float) -> Array[Note]:
	var notes: Array[Note] = []
	for index: int in pitches.size():
		var last: bool = index == pitches.size() - 1
		notes.append(Note.new(step * index, step * (4.0 if last else 2.0), pitches[index], pitches[index], wave, gain))
	return notes


func _render(notes: Array[Note]) -> AudioStreamWAV:
	var total: float = 0.0
	for note: Note in notes:
		total = maxf(total, note.start + note.length)
	var count: int = int(total * MIX_RATE) + 1
	var mix: PackedFloat32Array = PackedFloat32Array()
	mix.resize(count)
	var noise: RandomNumberGenerator = RandomNumberGenerator.new()
	noise.seed = 7
	for note: Note in notes:
		var first: int = int(note.start * MIX_RATE)
		var length: int = maxi(1, int(note.length * MIX_RATE))
		var phase: float = 0.0
		for index: int in length:
			if first + index >= count:
				break
			var progress: float = float(index) / length
			phase += lerpf(note.from_hz, note.to_hz, progress) / MIX_RATE
			var value: float = 0.0
			match note.wave:
				Wave.SINE:
					value = sin(TAU * phase)
				Wave.SQUARE:
					value = tanh(3.0 * sin(TAU * phase))
				Wave.SAW:
					value = 2.0 * fposmod(phase, 1.0) - 1.0
				Wave.NOISE:
					value = noise.randf_range(-1.0, 1.0)
			var envelope: float = minf(1.0, float(index) / (ATTACK * MIX_RATE)) * exp(-DECAY * progress)
			mix[first + index] += value * envelope * note.gain
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count * 2)
	for index: int in count:
		bytes.encode_s16(index * 2, int(clampf(mix[index], -1.0, 1.0) * 32000.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
