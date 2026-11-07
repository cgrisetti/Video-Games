## Renders a listening copy of an Audio Mosaic as the game plays it (16_ADAPTIVE_AUDIO_ARCHITECTURE.md
## §7): MusicMoodEngine choosing every next cell through a little walk (a town, out to the wild
## edge, past a sleeping foe, the exhale after a fight, a hearth where the music breathes), and
## Godot's own AudioStreamInteractive chaining the cells, mixed offline at each phrase's mood mix
## (the Music bus's effects, the hall and the Mellow shelf, aren't in it). Writes
## tools/audio_previews/<zone>_mood_walk.wav (git-ignored) and prints the phrases it chose.
## Run from games/everwood:
##   godot --headless --path . -s res://tools/preview_audio_mosaic.gd -- --zone=crown_island --phrases=28 --seed=16
extends SceneTree

const OUT_FOLDER: String = "res://tools/audio_previews/"
const CHUNK: int = 1024
## The walk, phrase by phrase: [from phrase, what's round the party].
const STORY: Array[Array] = [[0, "town"], [6, "wild"], [12, "threat"], [16, "relief"], [19, "hearth"]]


func _initialize() -> void:
	var zone: StringName = &"crown_island"
	var phrases: int = 28
	var seed_value: int = 16
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--zone="):
			zone = StringName(arg.get_slice("=", 1))
		elif arg.begins_with("--phrases="):
			phrases = arg.get_slice("=", 1).to_int()
		elif arg.begins_with("--seed="):
			seed_value = arg.get_slice("=", 1).to_int()
	var profile: ZoneMusicProfileResource = AudioCatalog.zone(zone)
	var stream: AudioStreamInteractive = AudioDirector.mosaic_stream(profile, profile.opening_cell) if profile != null and profile.is_mosaic() else null
	if stream == null:
		printerr("[Mosaic] %s isn't a baked mosaic" % zone)
		quit(1)
		return
	var cells: Array[AudioStreamSynchronized] = []
	for index: int in stream.clip_count:
		cells.append(stream.get_clip_stream(index) as AudioStreamSynchronized)
	var engine: MusicMoodEngine = MusicMoodEngine.new()
	var opening: int = engine.reset(profile, seed_value, _context("town"))
	stream.initial_clip = opening
	var playback: AudioStreamPlaybackInteractive = stream.instantiate_playback() as AudioStreamPlaybackInteractive
	var rate: float = AudioServer.get_mix_rate()
	var cell_frames: int = int(round(profile.cell_sec() * rate))
	var decide_at: int = int(round(profile.bar_sec() * (profile.phrase_bars - 1) * rate))
	_set_levels(cells, engine, _context("town"))
	playback.start(0.0)
	var pcm: PackedByteArray = PackedByteArray()
	var phrase: int = 0
	var into: int = 0
	var decided: bool = false
	var lines: PackedStringArray = PackedStringArray([_line(0, engine, "town")])
	while phrase < phrases:
		var story: String = _story(phrase)
		if not decided and into >= decide_at:
			playback.switch_to_clip(engine.choose_next(_context(_story(phrase + 1))))
			decided = true
		var frames: PackedVector2Array = playback.mix_audio(1.0, CHUNK)
		var at: int = pcm.size()
		pcm.resize(at + frames.size() * 4)
		for index: int in frames.size():
			pcm.encode_s16(at + index * 4, int(clampf(frames[index].x, -1.0, 1.0) * 32767.0))
			pcm.encode_s16(at + index * 4 + 2, int(clampf(frames[index].y, -1.0, 1.0) * 32767.0))
		into += CHUNK
		if playback.get_current_clip_index() != engine.current_cell:
			engine.commit(playback.get_current_clip_index())
			phrase += 1
			into -= cell_frames
			decided = false
			story = _story(phrase)
			_set_levels(cells, engine, _context(story))
			lines.append(_line(phrase, engine, story))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = true
	wav.mix_rate = int(rate)
	wav.data = pcm
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_FOLDER))
	var path: String = ProjectSettings.globalize_path(OUT_FOLDER + "%s_mood_walk.wav" % zone)
	wav.save_to_wav(path)
	print("\n".join(lines))
	print("[Mosaic] %s: %d phrases, %.1f s -> %s" % [zone, phrases, pcm.size() / 4.0 / rate, path])
	quit(0)


static func _story(phrase: int) -> String:
	var now: String = String(STORY[0][1])
	for step: Array in STORY:
		if phrase >= int(step[0]):
			now = String(step[1])
	return now


static func _context(story: String) -> MusicMoodEngine.Context:
	var context: MusicMoodEngine.Context = MusicMoodEngine.Context.new()
	match story:
		"town":
			context.settled = 1.0
		"wild":
			context.wild = 1.0
		"threat":
			context.threat = true
			context.wild = 1.0
		"relief":
			context.relief = true
		"hearth":
			context.hearth = 1.0
			context.still = 1.0
	return context


## The cell's mood mix on every clip (a sleeping foe 20 m off while the threat lasts).
static func _set_levels(cells: Array[AudioStreamSynchronized], engine: MusicMoodEngine, context: MusicMoodEngine.Context) -> void:
	var levels: PackedFloat32Array = engine.stem_targets(0.7 if context.threat else 0.0)
	for each: AudioStreamSynchronized in cells:
		for layer: int in levels.size():
			each.set_sync_stream_volume(layer, levels[layer])


static func _line(phrase: int, engine: MusicMoodEngine, story: String) -> String:
	var made: MosaicCellResource = engine.cell()
	return "  %2d  %-7s %-12s %-12s %s%s" % [phrase, story, made.cell_id, ZoneMusicProfileResource.mood_name(made.mood),
		ZoneMusicProfileResource.voice_name(made.lead_voice, made.voice_label), " (breath %d)" % (engine.breath_step + 1) if engine.in_breath() else ""]
