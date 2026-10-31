extends Node

# Music and sound effects. The forest theme loops under everything (or its 8-bit version, picked
# in Settings); while the game is paused it gets quieter and muffled, as if through a door. A
# danger layer, in step with the theme, swells in as an inch worm creeps closer (set_danger).
# The effects are made right here from noise and tones, so there are no sound files to manage.
# Some come from where they happen (play_at), so a bonk on your left sounds from the left.

const TRACKS := {
	"forest": preload("res://audio/forest-theme.ogg"),
	"8bit": preload("res://audio/forest-theme-8bit.ogg"),
}
# Each track turned down to sit under the action (they were mastered at different loudness).
const TRACK_GAIN_DB := {"forest": -6.4, "8bit": -5.2}
const DANGER := preload("res://audio/forest-danger.ogg")
const DANGER_GAIN_DB := -1.3 # The danger layer at the same loudness as the theme...
const DANGER_LOUDEST := 0.9 # ...and at its strongest, this much of it.
const THEME_DIP := 0.3 # How much the theme steps back while the danger layer is in.
const DANGER_FADE := 0.6 # Seconds to swell or fade.
# A berry's chime climbs with each one picked; the golden one gets a sparkling run.
const BERRY_NOTES := [587.33, 659.25, 739.99, 880.0, 987.77, 1174.66, 1318.51, 1479.98, 1760.0]
const GOLDEN_RUN := [1174.66, 1479.98, 1661.22, 1760.0, 2349.32]
const PAUSED_DB := -4.5 # Quieter while paused...
const MIX_RATE := 22050

var _music := AudioStreamPlayer.new()
var _effects: Array[AudioStreamPlayer] = []
var _paused := false
var _swing: AudioStreamWAV
var _pop: AudioStreamWAV
var _chime: AudioStreamWAV
var _berry_pops: Array[AudioStreamWAV] = []
var _golden_pop: AudioStreamWAV
var _bonk: AudioStreamWAV
var _chomp: AudioStreamWAV
var _alert: AudioStreamWAV
var _places: Array[AudioStreamPlayer3D] = []
var _together: AudioStreamSynchronized
var _danger := 0.0
var _danger_goal := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music.bus = "Music"
	add_child(_music)
	for i in 4:
		var player := AudioStreamPlayer.new()
		player.bus = "Effects"
		add_child(player)
		_effects.append(player)
	for i in 4:
		var place := AudioStreamPlayer3D.new()
		place.bus = "Effects"
		place.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED # Only the side it's on.
		place.panning_strength = 0.8
		add_child(place)
		_places.append(place)
	_swing = _make_swing()
	_pop = _make_tone(880.0, 1320.0, 0.09)
	_chime = _make_tone(660.0, 990.0, 0.35)
	for note: float in BERRY_NOTES:
		_berry_pops.append(_render(0.6, _plop() + [{"type": "chime", "from": note, "at": 0.02, "decay": 0.45, "gain": 0.2}]))
	var run := _plop()
	for i in GOLDEN_RUN.size():
		run.append({"type": "chime", "from": GOLDEN_RUN[i], "at": i * 0.07, "decay": 0.55, "gain": 0.22})
	run.append({"type": "noise", "band": 6000.0, "attack": 0.05, "decay": 0.6, "gain": 0.08, "at": 0.05}) # Sparkle.
	_golden_pop = _render(1.1, run)
	_bonk = _render(0.6, [
		{"type": "tone", "from": 900.0, "to": 600.0, "glide": 0.03, "decay": 0.06, "gain": 0.35}, # Tok! The wood.
		{"type": "noise", "band": 2200.0, "decay": 0.035, "gain": 0.4},
		{"type": "tone", "from": 180.0, "to": 80.0, "glide": 0.12, "decay": 0.14, "gain": 0.55}, # The thud of a soft head.
		{"type": "tone", "from": 330.0, "to": 250.0, "glide": 0.35, "attack": 0.01, "decay": 0.4, "gain": 0.16, "at": 0.03, "wobble": Vector2(22.0, 30.0)}, # Boing.
	])
	var chomp := []
	for at: float in [0.0, 0.24]: # Two hungry chomps...
		chomp.append({"type": "noise", "band": 4000.0, "decay": 0.012, "gain": 0.25, "at": at})
		chomp.append({"type": "noise", "band": 800.0, "attack": 0.004, "decay": 0.09, "gain": 0.5, "at": at})
		chomp.append({"type": "tone", "from": 160.0, "to": 70.0, "glide": 0.1, "decay": 0.11, "gain": 0.55, "at": at})
	chomp.append({"type": "tone", "from": 520.0, "to": 150.0, "glide": 0.2, "attack": 0.02, "decay": 0.24, "gain": 0.4, "at": 0.55}) # ...then a gulp.
	chomp.append({"type": "tone", "from": 260.0, "to": 75.0, "glide": 0.2, "attack": 0.02, "decay": 0.24, "gain": 0.3, "at": 0.55})
	_chomp = _render(1.0, chomp)
	_alert = _render(0.35, [ # A worm noticing you: a quick, curious "boop-boop?" going up.
		{"type": "tone", "from": 520.0, "to": 700.0, "glide": 0.03, "attack": 0.005, "decay": 0.09, "gain": 0.3},
		{"type": "tone", "from": 700.0, "to": 1040.0, "glide": 0.05, "attack": 0.005, "decay": 0.12, "gain": 0.3, "at": 0.11},
	])
	Settings.changed.connect(_on_setting)
	_play_music()
	_apply_volumes()


func set_paused(paused: bool) -> void:
	_paused = paused
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Music"), 0, paused) # ...and muffled.
	_apply_volumes()


func play_swing() -> void:
	_play(_swing, randf_range(0.9, 1.1))


func play_pop() -> void:
	_play(_pop, 1.0)


func play_chime() -> void:
	_play(_chime, 1.0)


# A raspberry popping: a quick "plop" that jumps up in pitch, and a chime that climbs with each
# berry picked (`number` is 1 to 9), or the golden raspberry's sparkling run.
func play_berry(number: int, golden: bool) -> void:
	_play(_golden_pop if golden else _berry_pops[clampi(number, 1, BERRY_NOTES.size()) - 1], 1.0)


# The stick bonking an inch worm on the head, from where it happened.
func play_bonk(at: Vector3) -> void:
	play_at(_bonk, at)


# An inch worm noticing the gnome.
func play_alert(at: Vector3) -> void:
	play_at(_alert, at)


# An inch worm catching the gnome: two hungry chomps, then a gulp.
func play_chomp(at: Vector3) -> void:
	play_at(_chomp, at)


func play_at(stream: AudioStream, at: Vector3) -> void:
	for place in _places:
		if not place.playing:
			place.stream = stream
			place.global_position = at
			place.play()
			return


# How strong the danger layer should be, 0 (gone) to 1 (a worm's right there). Call every frame.
func set_danger(amount: float) -> void:
	_danger_goal = clampf(amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if _together == null:
		return
	_danger = move_toward(_danger, _danger_goal, delta / DANGER_FADE)
	var style: String = Settings.get_value("music_style")
	_together.set_sync_stream_volume(0, linear_to_db(1.0 - THEME_DIP * _danger))
	_together.set_sync_stream_volume(1, linear_to_db(maxf(_danger * DANGER_LOUDEST, 0.0001)) + DANGER_GAIN_DB - TRACK_GAIN_DB[style])


func _play(stream: AudioStream, pitch: float) -> void:
	for player in _effects:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = pitch
			player.play()
			return


func _on_setting(name: String) -> void:
	if name == "music_style":
		_play_music()
	_apply_volumes()


func _play_music() -> void:
	var style: String = Settings.get_value("music_style")
	var at := _music.get_playback_position() if _music.playing else 0.0
	var stream: AudioStreamOggVorbis = TRACKS[style]
	stream.loop = true
	var danger: AudioStreamOggVorbis = DANGER
	danger.loop = true
	# The theme and the danger layer play together, in step (they're the same length and tempo).
	_together = AudioStreamSynchronized.new()
	_together.stream_count = 2
	_together.set_sync_stream(0, stream)
	_together.set_sync_stream(1, DANGER)
	_together.set_sync_stream_volume(1, -80.0)
	_music.stream = _together
	_music.play(at) # The versions line up, so switching carries on from the same spot.


func _apply_volumes() -> void:
	var style: String = Settings.get_value("music_style")
	var music: float = Settings.get_value("music_volume") if Settings.get_value("music_on") else 0.0
	_music.volume_db = TRACK_GAIN_DB[style] + (PAUSED_DB if _paused else 0.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), linear_to_db(Settings.get_value("sound_volume")))


# A soft whoosh: noise that swells and fades, getting brighter in the middle.
func _make_swing() -> AudioStreamWAV:
	var length := 0.28
	var count := int(length * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var low := 0.0
	for i in count:
		var t := float(i) / count
		var envelope := sin(t * PI) ** 2
		var brightness := 0.08 + 0.3 * envelope
		low += (randf_range(-1.0, 1.0) - low) * brightness
		data.encode_s16(i * 2, int(clampf(low * envelope * 1.6, -1.0, 1.0) * 32767))
	return _wav(data)


# A gentle bell-like blip that slides from one pitch to another.
func _make_tone(from_hz: float, to_hz: float, length: float) -> AudioStreamWAV:
	var count := int(length * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		phase += lerpf(from_hz, to_hz, sqrt(t)) / MIX_RATE * TAU
		var envelope := minf(t * 40.0, 1.0) * exp(-t * 5.0)
		var value := (sin(phase) + 0.3 * sin(phase * 2.0)) * 0.35 * envelope
		data.encode_s16(i * 2, int(value * 32767))
	return _wav(data)


# A quick "plop" jumping up in pitch, and a little squish of juice.
func _plop() -> Array:
	return [
		{"type": "tone", "from": 300.0, "to": 950.0, "glide": 0.035, "attack": 0.003, "decay": 0.07, "gain": 0.6},
		{"type": "noise", "band": 1000.0, "decay": 0.06, "gain": 0.18, "at": 0.01},
	]


# Mix a sound from parts, each starting `at` seconds in: a "tone" that glides `from` one pitch
# `to` another (with an optional `wobble`: [how fast, how far]), a bell-like "chime", or a puff of
# "noise" around a `band` of pitches. Each swells over `attack` seconds and fades over `decay`.
func _render(length: float, parts: Array) -> AudioStreamWAV:
	var count := int(length * MIX_RATE)
	var mix := PackedFloat32Array()
	mix.resize(count)
	for part: Dictionary in parts:
		var start := int(part.get("at", 0.0) * MIX_RATE)
		var attack: float = part.get("attack", 0.002)
		var decay: float = part.get("decay", 0.1)
		var gain: float = part.get("gain", 0.3)
		var from_hz: float = part.get("from", 440.0)
		var to_hz: float = part.get("to", from_hz)
		var glide: float = part.get("glide", 0.05)
		var wobble: Vector2 = part.get("wobble", Vector2.ZERO)
		var band: float = part.get("band", 1000.0)
		var phase := 0.0
		var low := 0.0
		var lower := 0.0
		for i in range(start, count):
			var t := float(i - start) / MIX_RATE
			var envelope := minf(t / attack, 1.0) * exp(-maxf(t - attack, 0.0) * 4.6 / decay)
			if t > attack and envelope < 0.0005:
				break
			var value := 0.0
			match part.type:
				"tone", "chime":
					var hz := to_hz + (from_hz - to_hz) * exp(-t / glide) + sin(t * TAU * wobble.x) * wobble.y
					phase += hz / MIX_RATE * TAU
					value = sin(phase) if part.type == "tone" else sin(phase) + 0.35 * sin(phase * 2.76) + 0.15 * sin(phase * 5.4)
				"noise":
					# Noise through two soft filters, keeping the pitches round `band`.
					var white := randf_range(-1.0, 1.0)
					low += (white - low) * (1.0 - exp(-TAU * band * 1.5 / MIX_RATE))
					lower += (white - lower) * (1.0 - exp(-TAU * band * 0.66 / MIX_RATE))
					value = (low - lower) * 2.0
			mix[i] += value * envelope * gain
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		data.encode_s16(i * 2, int(tanh(mix[i]) * 32767.0)) # Rounded off gently if it ever gets loud.
	return _wav(data)


func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.data = data
	return wav
