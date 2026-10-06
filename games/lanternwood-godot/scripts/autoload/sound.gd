extends Node

# Music and sound effects. The forest theme loops under everything (or its 8-bit version, picked
# in Settings); while the game is paused it gets quieter and muffled, as if through a door.
# The effects are made right here from noise and tones, so there are no sound files to manage.

const TRACKS := {
	"forest": preload("res://audio/forest-theme.ogg"),
	"8bit": preload("res://audio/forest-theme-8bit.ogg"),
}
# Each track turned down to sit under the action (they were mastered at different loudness).
const TRACK_GAIN_DB := {"forest": -6.4, "8bit": -5.2}
const PAUSED_DB := -4.5 # Quieter while paused...
const MIX_RATE := 22050

var _music := AudioStreamPlayer.new()
var _effects: Array[AudioStreamPlayer] = []
var _paused := false
var _swing: AudioStreamWAV
var _pop: AudioStreamWAV
var _chime: AudioStreamWAV


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music.bus = "Music"
	add_child(_music)
	for i in 4:
		var player := AudioStreamPlayer.new()
		player.bus = "Effects"
		add_child(player)
		_effects.append(player)
	_swing = _make_swing()
	_pop = _make_tone(880.0, 1320.0, 0.09)
	_chime = _make_tone(660.0, 990.0, 0.35)
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
	_music.stream = stream
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


func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.data = data
	return wav
