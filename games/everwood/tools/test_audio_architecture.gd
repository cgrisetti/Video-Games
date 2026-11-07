## The Chamber-Folk Audio Mosaic's checks (16_ADAPTIVE_AUDIO_ARCHITECTURE.md §7), run by
## tools/smoke_test.gd after the Caldera Isles' (and alone by tools/run_audio_architecture_checks.gd):
##   1  the catalog: Crown Island (crown_island) and Miller's Holm (millers_holm, Oakshire
##      Holm, the mill-isle) are mosaics of twelve four-bar cells, two in each of the six moods
##      on different Hisaishi Quartet voicings, in their own tempo, key and meter; Oakshire
##      Holm's grid names its mosaic, and The Crown's keeps its five shore suites (docs/23)
##      until its entry names crown_island; every cell's four baked stems are one-shot Ogg
##      Vorbis tagged with its beats, holding the cell and its tail; the baked score.json lists
##      the same cells; each mosaic is one AudioStreamInteractive of twelve four-stem clips
##   2  sample-accurate chaining, mixed offline: a cell asked for half a cell ahead starts on
##      the bar line with no gap, the old cell's tail ringing under it, and a cell nobody
##      chooses for goes on to its fallback
##   3  the Mood State Machine: seeded and repeatable; walking 24 bars it plays at least four
##      moods (and over most seeds), never repeats a cell, trades the lead voice every phrase
##      and never repeats an eight-bar pair; hearths and towns lean to Peace, Mellow and Wonder,
##      the wild edges to Curiosity, Interest and Anxiousness, high ground to Wonder; a threat
##      turns the next phrase to Anxiousness from any cell; a fight keeps to the driving moods;
##      the Peace breath takes the melody away and fades the harp over two to four cells
##   4  in the Caldera: Oakshire Holm plays millers_holm on the mosaic deck; 24 simulated bars
##      of exploring walk at least four moods with no two identical consecutive phrases or
##      eight-bar signatures, on the same deck; the F4 badge reads the score line; Mellow
##      softens the Music bus's top end 3 dB; a padfoot 20 m away swells the discord and turns
##      the next phrase to Anxiousness; its aggro locks the Skirmish (0 / -18 / -3 / 0 dB) on
##      the same cell and deck within 0.4 s, the grid running on (no restart), and the fight's
##      phrases keep to the driving moods; after the exhale no Anxiousness; The Crown plays
##      its shore suites, and crown_island all over it once its atlas entry names it; and no
##      bus, effect, director node or orphan node is left over
extends RefCounted

const CALDERA_SCENE: String = "res://scenes/worlds/caldera_isles.tscn"
const Mood = ZoneMusicProfileResource.MoodState
const SIMULATED_BARS: int = 24
## Seeds the walk's spread is checked over, and the share of them that must reach four moods in 24 bars.
const SPREAD_SEEDS: int = 200
const SPREAD_SHARE: float = 0.9
const THREAT_DISTANCE: float = 20.0
const TICK: float = 1.0 / 60.0

var tree: SceneTree
var check: Callable
var director: AudioDirector
var level: CalderaArchipelagoWorld
var _spawners: Array[MobSpawner] = []


func run(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	director = AudioDirector.current
	if director == null:
		check.call(false, "the AudioDirector autoload (Score) is running")
		return
	_check_catalog()
	_check_chaining()
	_check_mood_machine()
	await _check_caldera()
	for spawner: MobSpawner in _spawners:
		if is_instance_valid(spawner):
			spawner.queue_free()
	await tree.physics_frame


# --- 1: the catalog --------------------------------------------------------------------

func _check_catalog() -> void:
	# [its island, tempo, beats, 6/8, tonic, mode, whether the island plays it by default].
	var expected: Dictionary[StringName, Array] = {&"crown_island": [CalderaAtlas.ISLE_THE_CROWN, 110.0, 3, false, 67, &"G_LYDIAN", false],
		&"millers_holm": [CalderaAtlas.ISLE_OAKSHIRE_HOLM, 104.0, 3, true, 65, &"F_LYDIAN", true]}
	for id: StringName in expected:
		var want: Array = expected[id]
		var profile: ZoneMusicProfileResource = AudioCatalog.zone(id)
		var isle: IslandGridResource = CalderaAtlas.isle(want[0])
		if profile == null:
			check.call(false, "%s is registered in AudioCatalog" % id)
			continue
		var per_mood: Dictionary[int, Array] = {}
		for each: MosaicCellResource in profile.mosaic_cells:
			if not per_mood.has(each.mood):
				per_mood[each.mood] = []
			per_mood[each.mood].append(each.lead_voice)
		var paired: bool = per_mood.size() == ZoneMusicProfileResource.MOOD_COUNT
		for voices: Array in per_mood.values():
			paired = paired and voices.size() == 2 and voices[0] != voices[1]
		var chained: bool = true
		for index: int in profile.mosaic_cells.size():
			var next: int = profile.fallback_after(index)
			chained = chained and profile.cell(next).lead_voice != profile.cell(index).lead_voice
		check.call(profile.is_mosaic() and profile.mosaic_cells.size() == 12 and paired and chained and is_equal_approx(profile.bpm, float(want[1]))
			and profile.beats_per_bar == int(want[2]) and profile.compound_meter == bool(want[3]) and profile.root_pitch_midi == int(want[4])
			and profile.modal_signature == want[5] and profile.phrase_bars == 4 and isle != null and (isle.music_profile == id) == bool(want[6]),
			"%s is a mosaic of twelve four-bar cells (two in each of the six moods, on different voicings; its fallback chain never repeats a voicing) in %s at %d BPM%s, and %s"
			% [id, profile.modal_signature, int(profile.bpm), " in 6/8" if profile.compound_meter else " in 3/4",
			("%s plays it" % isle.display_name) if bool(want[6]) else "%s keeps its five shore suites until its atlas entry names it" % isle.display_name])
		# Every cell's four baked stems, the score that lists them, and the interactive stream.
		var stems_ok: bool = AudioDirector.has_baked_stems(id)
		var beats: int = profile.phrase_bars * profile.beats_per_bar
		for each: MosaicCellResource in profile.mosaic_cells:
			var stems: Array[AudioStream] = AudioDirector.baked_stems(AudioDirector.cell_folder(id, each.cell_id))
			stems_ok = stems_ok and stems.size() == 4
			for stem: AudioStream in stems:
				var ogg: AudioStreamOggVorbis = stem as AudioStreamOggVorbis
				stems_ok = stems_ok and ogg != null and not ogg.loop and is_equal_approx(ogg.bpm, profile.bpm) and ogg.beat_count == beats \
					and ogg.bar_beats == profile.beats_per_bar and ogg.get_length() > profile.cell_sec() and ogg.get_length() < profile.cell_sec() + 2.0
		var score: Dictionary = ProceduralChamberSynth.load_score(id)
		var listed: Array = score.get("cells", [])
		var agrees: bool = listed.size() == profile.mosaic_cells.size()
		for index: int in mini(listed.size(), profile.mosaic_cells.size()):
			var row: Dictionary = listed[index]
			var each: MosaicCellResource = profile.cell(index)
			agrees = agrees and StringName(str(row.get("id", ""))) == each.cell_id and str(row.get("voice", "")) == ZoneMusicProfileResource.VOICE_LETTERS[each.lead_voice] \
				and String(each.cell_id).begins_with(str(row.get("mood", "?"))) and PackedStringArray(row.get("chords", [])) == each.chords
		var interactive: AudioStreamInteractive = AudioDirector.mosaic_stream(profile, profile.opening_cell)
		var clips_ok: bool = interactive != null and interactive.clip_count == 12 and interactive.initial_clip == profile.opening_cell
		if interactive != null:
			for index: int in interactive.clip_count:
				var sync: AudioStreamSynchronized = interactive.get_clip_stream(index) as AudioStreamSynchronized
				clips_ok = clips_ok and sync != null and sync.stream_count == 4 and interactive.get_clip_name(index) == profile.cell(index).cell_id \
					and interactive.get_clip_auto_advance(index) == AudioStreamInteractive.AUTO_ADVANCE_ENABLED \
					and interactive.get_clip_auto_advance_next_clip(index) == profile.fallback_after(index)
		check.call(stems_ok and agrees and clips_ok and score.get("bars", 0) == 48,
			"%s's 48 cell stems are baked one-shot Ogg Vorbis (%d beats at %d BPM, the cell and its tail), its score.json lists the same twelve cells, moods, voicings and chords, and it plays as one AudioStreamInteractive of twelve four-stem clips"
			% [id, beats, int(profile.bpm)])


# --- 2: sample-accurate chaining ---------------------------------------------------------

func _check_chaining() -> void:
	var profile: ZoneMusicProfileResource = AudioCatalog.zone(&"crown_island")
	var opening: int = profile.cell_index(&"wonder_a")
	var asked: int = profile.cell_index(&"curiosity_b")
	var stream: AudioStreamInteractive = AudioDirector.mosaic_stream(profile, opening) if profile != null else null
	if stream == null:
		check.call(false, "The Crown's mosaic builds to mix offline")
		return
	for index: int in stream.clip_count:
		var sync: AudioStreamSynchronized = stream.get_clip_stream(index) as AudioStreamSynchronized
		for layer: int in 4:
			sync.set_sync_stream_volume(layer, 0.0 if layer < 2 else -80.0)
	var rate: float = AudioServer.get_mix_rate()
	var cell: int = int(round(profile.cell_sec() * rate))
	var chunk: int = 256
	var changes: Array[Vector2i] = []
	var mixed: PackedVector2Array = _mix_asking(stream, asked, cell, chunk, changes)
	# The asked-for cell begins in the chunk holding the bar line; then its fallback, a chunk or so either side of the next.
	var on_the_bar: bool = changes.size() >= 2 and changes[0].x == asked and changes[0].y >= cell - 2 and changes[0].y - cell <= chunk
	var fallback: bool = changes.size() >= 2 and changes[1].x == profile.fallback_after(asked) and absi(changes[1].y - cell * 2) <= chunk * 3
	var quiet: float = INF
	for start: int in range(cell - 2205, cell + 2205, 441):
		quiet = minf(quiet, _rms(mixed, start, 441))
	# The same with the asked-for cell silent: what sounds past the bar line is Wonder's own tail, fading out.
	var asked_sync: AudioStreamSynchronized = stream.get_clip_stream(asked) as AudioStreamSynchronized
	for layer: int in 4:
		asked_sync.set_sync_stream_volume(layer, -80.0)
	var tail_only: PackedVector2Array = _mix_asking(stream, asked, cell, chunk, [] as Array[Vector2i])
	var ringing: float = _rms(tail_only, cell + 441, 4410)
	var gone: float = _rms(tail_only, cell + int(1.6 * rate), 4410)
	check.call(on_the_bar and fallback and quiet > 0.01 and ringing > 0.003 and gone < ringing * 0.05,
		"mixed offline, The Crown's mosaic chains on the bar line: Curiosity, asked for half a cell ahead, starts %d frames after %.3f s (inside one %d-frame mix chunk) with no gap (the quietest 10 ms round it is %.3f RMS); Wonder's tail rings on under it (%.4f RMS just past the line, %.5f by 1.6 s); then the fallback cell follows"
		% [changes[0].y - cell if not changes.is_empty() else -1, profile.cell_sec(), chunk, quiet, ringing, gone])


## Mixes a mosaic from its opening cell, asking for `asked` half a cell in, for two and a quarter cells,
## noting each clip change as [clip, frames mixed by the end of the chunk it happened in].
static func _mix_asking(stream: AudioStreamInteractive, asked: int, cell: int, chunk: int, changes: Array[Vector2i]) -> PackedVector2Array:
	var playback: AudioStreamPlaybackInteractive = stream.instantiate_playback() as AudioStreamPlaybackInteractive
	playback.start(0.0)
	var mixed: PackedVector2Array = playback.mix_audio(1.0, int(cell * 0.5))
	playback.switch_to_clip(asked)
	var last: int = playback.get_current_clip_index()
	while mixed.size() < int(cell * 2.25):
		mixed.append_array(playback.mix_audio(1.0, chunk))
		var now: int = playback.get_current_clip_index()
		if now != last:
			changes.append(Vector2i(now, mixed.size()))
			last = now
	playback.stop()
	return mixed


static func _rms(frames: PackedVector2Array, start: int, count: int) -> float:
	var total: float = 0.0
	var used: int = 0
	for index: int in range(maxi(0, start), mini(frames.size(), start + count)):
		total += frames[index].length_squared()
		used += 1
	return sqrt(total / maxf(used, 1.0))


# --- 3: the Mood State Machine -------------------------------------------------------------

func _check_mood_machine() -> void:
	var profile: ZoneMusicProfileResource = AudioCatalog.zone(&"crown_island")
	var walking: MusicMoodEngine.Context = MusicMoodEngine.Context.new()
	var phrases: int = int(SIMULATED_BARS / float(profile.phrase_bars))
	# Repeatable: the same seed and context give the same phrases.
	var first: PackedInt32Array = _walk(profile, 16, phrases, walking).history
	var again: PackedInt32Array = _walk(profile, 16, phrases, walking).history
	var engine: MusicMoodEngine = _walk(profile, 16, phrases, walking)
	var rules: Array[String] = _broken_rules(profile, engine.history)
	var moods: Dictionary[int, bool] = {}
	for index: int in engine.history:
		moods[profile.cell(index).mood] = true
	var reaching: int = 0
	var broken: int = 0
	for seed_value: int in SPREAD_SEEDS:
		var trial: MusicMoodEngine = _walk(profile, seed_value, phrases, walking)
		var seen: Dictionary[int, bool] = {}
		for index: int in trial.history:
			seen[profile.cell(index).mood] = true
		reaching += 1 if seen.size() >= 4 else 0
		broken += 0 if _broken_rules(profile, trial.history).is_empty() else 1
	check.call(first == again and moods.size() >= 4 and rules.is_empty() and broken == 0 and reaching >= int(SPREAD_SEEDS * SPREAD_SHARE),
		"the Mood State Machine is seeded and repeatable; 24 bars of plain exploring walk %d moods (%s), and over %d seeds %d reach four or more; no seed repeats a cell, keeps a voicing two phrases or repeats an eight-bar pair%s"
		% [moods.size(), _moods_named(profile, engine.history), SPREAD_SEEDS, reaching, "" if rules.is_empty() else " (broken: %s)" % ", ".join(rules)])
	# Context leans the walk.
	var calm: MusicMoodEngine.Context = MusicMoodEngine.Context.new()
	calm.hearth = 1.0
	calm.settled = 1.0
	var wild: MusicMoodEngine.Context = MusicMoodEngine.Context.new()
	wild.wild = 1.0
	var high: MusicMoodEngine.Context = MusicMoodEngine.Context.new()
	high.height = 1.0
	var calm_share: float = _share(profile, calm, [Mood.PEACE, Mood.MELLOW, Mood.WONDER])
	var wild_calm_share: float = _share(profile, wild, [Mood.PEACE, Mood.MELLOW, Mood.WONDER])
	var wild_share: float = _share(profile, wild, [Mood.CURIOSITY, Mood.INTEREST, Mood.ANXIOUSNESS])
	var calm_wild_share: float = _share(profile, calm, [Mood.CURIOSITY, Mood.INTEREST, Mood.ANXIOUSNESS])
	var wonder_high: float = _share(profile, high, [Mood.WONDER])
	var wonder_plain: float = _share(profile, walking, [Mood.WONDER])
	check.call(calm_share > wild_calm_share + 0.15 and wild_share > calm_wild_share + 0.15 and wonder_high > wonder_plain + 0.04,
		"context leans the walk: by a hearth in town Peace, Mellow and Wonder play %.0f%% of phrases (%.0f%% out on the wild edges, where Curiosity, Interest and Anxiousness play %.0f%%, %.0f%% in town); high ground plays Wonder %.0f%% (%.0f%% on the flat)"
		% [calm_share * 100.0, wild_calm_share * 100.0, wild_share * 100.0, calm_wild_share * 100.0, wonder_high * 100.0, wonder_plain * 100.0])
	# A threat turns the next phrase to Anxiousness from any cell; a fight keeps to the driving moods.
	var threat: MusicMoodEngine.Context = MusicMoodEngine.Context.new()
	threat.threat = true
	var turned: int = 0
	for index: int in profile.mosaic_cells.size():
		var trial: MusicMoodEngine = MusicMoodEngine.new()
		trial.reset(profile, index, null)
		trial.commit(index)
		turned += 1 if profile.cell(trial.choose_next(threat)).mood == Mood.ANXIOUSNESS else 0
	var held: MusicMoodEngine = _walk(profile, 3, 10, threat)
	var fight: MusicMoodEngine.Context = MusicMoodEngine.Context.new()
	fight.fighting = true
	var fought: MusicMoodEngine = _walk(profile, 5, 12, fight)
	var driving: bool = true
	for index: int in fought.history.slice(1):
		driving = driving and MusicMoodEngine.FIGHT_MOODS.has(profile.cell(index).mood)
	var held_moods: bool = true
	for index: int in held.history.slice(1):
		held_moods = held_moods and (profile.cell(index).mood == Mood.ANXIOUSNESS or profile.cell(index).mood == Mood.CURIOSITY)
	check.call(turned == profile.mosaic_cells.size() and held_moods and _broken_rules(profile, held.history.slice(1)).is_empty() and driving,
		"a threat turns the next phrase to Anxiousness from every one of the twelve cells, a held threat stays with Anxiousness and Curiosity without an A B A B, and a fight keeps to Interest, Curiosity and Anxiousness (%s)"
		% _moods_named(profile, fought.history.slice(1, 6)))
	# The Emergent Silence breath: due after the music cycle, it opens from Peace.
	var breath: MusicMoodEngine = MusicMoodEngine.new()
	breath.reset(profile, 9, null)
	breath.commit(profile.cell_index(&"peace_a"))
	breath.phrases_since_breath = ceili(profile.music_cycle_sec / profile.cell_sec())
	var levels: Array[float] = []
	var leads_gone: bool = true
	var breath_cells: int = 0
	for step: int in 6:
		breath.commit(breath.choose_next(walking))
		if not breath.in_breath():
			break
		breath_cells += 1
		var targets: PackedFloat32Array = breath.stem_targets(0.0)
		levels.append(targets[0])
		leads_gone = leads_gone and targets[1] <= -79.0 and targets[2] <= -79.0 and targets[3] <= -79.0 and breath.mood() == Mood.PEACE
	var fading: bool = levels.size() >= 2 and levels[0] <= -12.0
	for index: int in range(1, levels.size()):
		fading = fading and levels[index] < levels[index - 1]
	check.call(breath_cells >= MusicMoodEngine.BREATH_MIN_CELLS and breath_cells <= MusicMoodEngine.BREATH_MAX_CELLS and leads_gone and fading
		and not breath.in_breath(),
		"after %d s of music a Peace phrase opens the Emergent Silence breath: %d Peace cells with the melody, discord and drive gone and the harp fading (%s dB), then the music re-emerges"
		% [int(profile.music_cycle_sec), breath_cells, str(levels)])


## A walk of `phrases` phrases from a seed in a steady context.
static func _walk(profile: ZoneMusicProfileResource, seed_value: int, phrases: int, context: MusicMoodEngine.Context) -> MusicMoodEngine:
	var engine: MusicMoodEngine = MusicMoodEngine.new()
	engine.reset(profile, seed_value, context)
	for step: int in phrases:
		engine.commit(engine.choose_next(context))
	return engine


## Which of rules 1, 2 and 5 a sequence of cells breaks (breath cells may keep their mood).
static func _broken_rules(profile: ZoneMusicProfileResource, history: PackedInt32Array) -> Array[String]:
	var broken: Array[String] = []
	for index: int in range(1, history.size()):
		if history[index] == history[index - 1]:
			broken.append("cell %s twice" % profile.cell(history[index]).cell_id)
		elif profile.cell(history[index]).lead_voice == profile.cell(history[index - 1]).lead_voice:
			broken.append("voicing kept at %d" % index)
		if index >= 3 and history[index] == history[index - 2] and history[index - 1] == history[index - 3]:
			broken.append("A B A B at %d" % index)
	return broken


## The share of phrases in `moods` over many seeds' long walks in a context.
static func _share(profile: ZoneMusicProfileResource, context: MusicMoodEngine.Context, moods: Array[int]) -> float:
	var hits: int = 0
	var total: int = 0
	for seed_value: int in 60:
		var engine: MusicMoodEngine = _walk(profile, 1000 + seed_value, 30, context)
		for index: int in engine.history:
			hits += 1 if moods.has(profile.cell(index).mood) else 0
			total += 1
	return float(hits) / maxf(total, 1.0)


static func _moods_named(profile: ZoneMusicProfileResource, history: PackedInt32Array) -> String:
	var names: PackedStringArray = PackedStringArray()
	for index: int in history:
		names.append(ZoneMusicProfileResource.mood_name(profile.cell(index).mood))
	return " > ".join(names)


# --- 4: in the Caldera ------------------------------------------------------------------

func _check_caldera() -> void:
	CalderaArchipelagoWorld.use_boot_zone(CalderaArchipelagoWorld.ZONE_OAKSHIRE)
	InstanceManager.current.previous_instance = &""
	tree.change_scene_to_file(CALDERA_SCENE)
	await _frames(12)
	level = tree.current_scene as CalderaArchipelagoWorld
	if level == null or _p1() == null:
		check.call(false, "the Caldera Isles load for the score's checks")
		return
	var buses: int = AudioServer.bus_count
	var music_effects: int = AudioServer.get_bus_effect_count(AudioServer.get_bus_index(&"Music"))
	var director_nodes: int = director.get_child_count()
	var orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	# A plain spot on Oakshire Holm, clear of its places, hearths, edges and kin.
	var spot: Vector3 = _plain_spot()
	await _place(spot)
	director.evaluate_now()
	var holm: ZoneMusicProfileResource = AudioCatalog.zone(&"millers_holm")
	var deck: AudioStream = director.front_deck_stream()
	check.call(director.get_active_profile_id() == &"millers_holm" and deck is AudioStreamInteractive and director.is_mosaic_playing()
		and director.current_cell() != null and director.state == AudioDirector.AcousticState.EXPLORATION,
		"Oakshire Holm plays millers_holm, its F Lydian mill-wheel mosaic, as one AudioStreamInteractive on the front deck (exploring, at %s)" % str(spot.round()))
	# 24 simulated bars of walking.
	var before: int = director.phrase_log.size()
	var opening: Dictionary = director.phrase_log[before - 1] if before > 0 else {}
	var bar_from: int = director.clock.bar
	await _simulate(SIMULATED_BARS, true)
	var played: Array[Dictionary] = [opening]
	played.append_array(director.phrase_log.slice(before))
	var moods: Dictionary[int, bool] = {}
	var repeats: int = 0
	var eight_bar_repeats: int = 0
	var voice_kept: int = 0
	var named: PackedStringArray = PackedStringArray()
	for index: int in played.size():
		moods[int(played[index].get("mood", -1))] = true
		named.append("%s:%s" % [ZoneMusicProfileResource.mood_name(int(played[index].get("mood", -1))), String(played[index].get("cell_id", "?"))])
		if index >= 1:
			repeats += 1 if played[index]["signature"] == played[index - 1]["signature"] else 0
			voice_kept += 1 if played[index]["voice"] == played[index - 1]["voice"] and int(played[index]["breath"]) < 0 else 0
		if index >= 3:
			var pair: String = "%s|%s" % [played[index - 1]["signature"], played[index]["signature"]]
			var previous: String = "%s|%s" % [played[index - 3]["signature"], played[index - 2]["signature"]]
			eight_bar_repeats += 1 if pair == previous else 0
	check.call(director.clock.bar - bar_from == SIMULATED_BARS and played.size() == int(SIMULATED_BARS / float(holm.phrase_bars)) + 1 and moods.size() >= 4
		and repeats == 0 and eight_bar_repeats == 0 and voice_kept == 0 and director.front_deck_stream() == deck,
		"24 simulated bars of walking Oakshire Holm walk %d moods (%s): no two consecutive phrases or eight-bar pairs alike, the lead voice traded every phrase, on the same deck"
		% [moods.size(), " > ".join(named)])
	# The F4 badge reads the score's line.
	level.set_telemetry_visible(true)
	var badge: WorldTelemetryBadge = level.telemetry_badge()
	var line: String = director.telemetry_line()
	var cell: MosaicCellResource = director.current_cell()
	var shape: RegEx = RegEx.create_from_string("^Audio: millers_holm \\[[A-G]#?b?_[A-Z_]+ 104BPM\\] · Mood: [A-Z]+( breath \\d)? \\(Var [ABCD]: [^)]+\\) · State: [A-Z]+ · Stems: -?\\d+\\.\\d/-?\\d+\\.\\d/-?\\d+\\.\\d/-?\\d+\\.\\d dB · Voices: \\d+/32$")
	check.call(level.is_telemetry_visible() and badge != null and badge.readout() == line and shape.search(line) != null and cell != null
		and line.contains("[%s 104BPM]" % cell.mode_label) and line.contains(ZoneMusicProfileResource.voice_name(cell.lead_voice, cell.voice_label)),
		"F4 shows the score line: %s" % line)
	level.set_telemetry_visible(false)
	# Mellow softens the top end 3 dB.
	await _check_mellow_shelf(holm)
	# A padfoot 20 m away: the Pre-Warm, then Anxiousness at the next phrase.
	await _tick_to_next_phrase()
	var p1: ActorBase = _p1()
	var padfoot: WildMob = await _grow(p1.global_position + Vector3(0.0, 0.0, -THREAT_DISTANCE))
	if padfoot == null:
		check.call(false, "a padfoot grows 20 m from the party")
		return
	padfoot.loadout.stats.move_speed = 0.0
	await _place(padfoot.global_position + Vector3(0.0, 0.0, THREAT_DISTANCE))
	director.evaluate_now()
	var warming: bool = director.state == AudioDirector.AcousticState.PROXIMITY and director.proximity > 0.6 and director.proximity < 0.8
	var discord_rising: float = director.get_stem_target_db(2)
	await _tick_to_next_phrase()
	var turned: MosaicCellResource = director.current_cell()
	var anxious_discord: float = director.get_stem_target_db(2)
	check.call(warming and discord_rising > -12.0 and turned != null and turned.mood == Mood.ANXIOUSNESS and anxious_discord > -12.0
		and anxious_discord <= MusicMoodEngine.ANXIOUS_DISCORD_FULL_DB + 0.01,
		"a padfoot %d m away warms the score (S = %.2f, the discord rising to %.1f dB) and the next phrase turns to Anxiousness (%s), the Holloway discord swelling to %.1f dB"
		% [int(THREAT_DISTANCE), director.proximity, discord_rising, turned.describe() if turned != null else "none", anxious_discord])
	# Its aggro locks the Skirmish on the same cell and deck, the grid running on.
	await _tick_to_next_phrase()
	var cell_before: int = director.mood_engine.current_cell
	var grid_before: float = director.clock.elapsed
	var deck_before: AudioStream = director.front_deck_stream()
	var sync_before: AudioStreamSynchronized = director.front_stream()
	padfoot.engaged = true
	await _place(padfoot.global_position + Vector3(0.0, 0.0, 6.0))
	director.evaluate_now()
	_tick(ZoneMusicProfileResource.SKIRMISH_ATTACK_SEC + 0.05)
	var volumes: Array[float] = []
	for layer: int in 4:
		volumes.append(roundf(director.get_stem_volume_db(layer)))
	check.call(director.state == AudioDirector.AcousticState.SKIRMISH and str(volumes) == "[0.0, -18.0, -3.0, 0.0]" and director.front_deck_stream() == deck_before
		and director.front_stream() == sync_before and director.mood_engine.current_cell == cell_before and director.clock.elapsed > grid_before + 0.4,
		"the padfoot's aggro locks the Skirmish within %.1f s on the same cell and deck (%s dB), the phrase grid running on: nothing restarts" % [
			ZoneMusicProfileResource.SKIRMISH_ATTACK_SEC, str(volumes)])
	var fight_moods: Array[String] = []
	var driving: bool = true
	for phrase: int in 2:
		await _tick_to_next_phrase()
		var playing: MosaicCellResource = director.current_cell()
		fight_moods.append(ZoneMusicProfileResource.mood_name(playing.mood))
		driving = driving and MusicMoodEngine.FIGHT_MOODS.has(playing.mood) and director.state == AudioDirector.AcousticState.SKIRMISH
	# Beaten: the exhale, its breath, then no Anxiousness while the relief lasts.
	padfoot.stats.take_damage(padfoot.stats.health + 100000.0)
	await _place(spot)
	_tick(AudioDirector.HYSTERESIS_HOLD + ZoneMusicProfileResource.RESTORATION_EXHALE_SEC + ZoneMusicProfileResource.POST_COMBAT_SILENCE_SEC + 1.0)
	var calm_again: bool = director.state == AudioDirector.AcousticState.EXPLORATION
	await _tick_to_next_phrase()
	var relieved: MosaicCellResource = director.current_cell()
	check.call(driving and calm_again and relieved != null and relieved.mood != Mood.ANXIOUSNESS,
		"the fight's phrases keep to the driving moods (%s); beaten, the exhale and its breath pass and the walk resumes in %s"
		% [", ".join(fight_moods), ZoneMusicProfileResource.mood_name(relieved.mood) if relieved != null else "nothing"])
	# The Crown: its shore suites (docs/23), then crown_island all over it once its atlas entry names it.
	for phrase: int in AudioDirector.RELIEF_PHRASES:
		await _tick_to_next_phrase()
	level.playtest_warp()
	await _frames(12)
	director.evaluate_now()
	var shore: StringName = director.get_active_profile_id()
	var shore_classic: bool = not director.is_mosaic_playing() and String(shore).begins_with("crown_") and shore != &"crown_island"
	var crown: IslandGridResource = CalderaAtlas.isle(CalderaAtlas.ISLE_THE_CROWN)
	var kept: StringName = crown.music_profile
	crown.music_profile = &"crown_island"
	director.evaluate_now()
	var crown_line: String = director.telemetry_line()
	var mosaic_on: bool = director.get_active_profile_id() == &"crown_island" and director.is_mosaic_playing() and crown_line.begins_with("Audio: crown_island [") \
		and crown_line.contains(" 110BPM] · Mood: ")
	crown.music_profile = kept
	director.evaluate_now()
	check.call(shore_classic and mosaic_on and director.get_active_profile_id() == shore,
		"The Crown plays its shore suite (%s at the landing); with its atlas entry naming crown_island it plays the sea-wind mosaic all over the isle (%s), and back"
		% [shore, crown_line])
	level.playtest_warp()
	await _frames(12)
	# Nothing left over.
	await _frames(4)
	var orphans_after: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	check.call(AudioServer.bus_count == buses and AudioServer.get_bus_effect_count(AudioServer.get_bus_index(&"Music")) == music_effects
		and director.get_child_count() == director_nodes and orphans_after <= orphans,
		"no leaks: %d buses, %d Music effects (the Mellow shelf among them), %d director nodes and %d orphan nodes, as before the mosaic's checks"
		% [AudioServer.bus_count, music_effects, director.get_child_count(), orphans_after])


func _check_mellow_shelf(profile: ZoneMusicProfileResource) -> void:
	await _tick_to_next_phrase()
	var restore: int = director.mood_engine.current_cell
	var music: int = AudioServer.get_bus_index(&"Music")
	var shelf: AudioEffectHighShelfFilter = null
	for index: int in AudioServer.get_bus_effect_count(music):
		if AudioServer.get_bus_effect(music, index) is AudioEffectHighShelfFilter:
			shelf = AudioServer.get_bus_effect(music, index) as AudioEffectHighShelfFilter
	director.mood_engine.commit(profile.cell_index(&"mellow_a"))
	director._retarget_stems()
	_tick(AudioDirector.SHELF_RAMP_SEC + 0.1)
	var warm: float = shelf.gain if shelf != null else 1.0
	director.mood_engine.commit(profile.cell_index(&"wonder_b"))
	director._retarget_stems()
	_tick(AudioDirector.SHELF_RAMP_SEC + 0.1)
	var bright: float = shelf.gain if shelf != null else 0.0
	director.mood_engine.commit(restore)
	check.call(shelf != null and is_equal_approx(shelf.cutoff_hz, AudioDirector.WARMTH_SHELF_HZ) and absf(warm - AudioDirector.MELLOW_SHELF_GAIN) < 0.01
		and is_equal_approx(bright, 1.0),
		"a Mellow phrase softens the Music bus's top end: its high shelf at %d Hz eases to %.1f dB, and back to flat for Wonder" % [
			int(AudioDirector.WARMTH_SHELF_HZ), linear_to_db(warm)])


# --- Helpers ------------------------------------------------------------------------

func _frames(count: int) -> void:
	for index: int in count:
		await tree.physics_frame


## Moves the score's time on by `seconds` at once (headless, nothing plays: the director's own grid runs).
func _tick(seconds: float) -> void:
	var left: float = seconds
	while left > 0.0:
		director.tick_score(minf(TICK, left))
		left -= TICK


## 24 bars (or `bars`) of the score, Player 1 walking.
func _simulate(bars: int, walking: bool) -> void:
	var p1: ActorBase = _p1()
	var target: int = director.clock.bar + bars
	while director.clock.bar < target:
		if walking:
			p1.velocity = Vector3(3.0, 0.0, 0.0)
		director.tick_score(TICK)
	p1.velocity = Vector3.ZERO
	await tree.process_frame


func _tick_to_next_phrase() -> void:
	var phrase: int = director.clock.phrase
	var guard: int = 0
	while director.clock.phrase == phrase and guard < 2000:
		director.tick_score(TICK)
		guard += 1
	_tick(TICK * 2.0)
	await tree.process_frame


## A spot on the island with nothing leaning the moods and no kin within 45 m.
func _plain_spot() -> Vector3:
	var fallback: Vector3 = _p1().global_position
	for ring: float in [180.0, 240.0, 300.0, 120.0]:
		for step: int in 16:
			var angle: float = TAU * step / 16.0
			var at: Vector3 = Vector3(cos(angle) * ring, 0.0, sin(angle) * ring)
			at.y = level.streamer.height_at(at.x, at.z)
			var context: MusicMoodEngine.Context = MusicMoodEngine.Context.new()
			level.music_mood_context(at + Vector3(0.0, 0.5, 0.0), context)
			if at.y < CalderaWorldState.current.sea_level_y + 1.5 or context.settled > 0.0 or context.wild > 0.05 or context.height > 0.0:
				continue
			var kin: bool = false
			for foe: ActorBase in CombatDirector.current.enemies():
				kin = kin or (not foe.is_beaten() and foe.global_position.distance_to(at) < 45.0)
			if not kin:
				return at
	return fallback


func _place(at: Vector3) -> void:
	var seat: int = 0
	for actor: ActorBase in _party():
		var spot: Vector3 = at + Vector3(seat * 1.6, 0.0, 0.0)
		level.streamer.ensure_ground_at(spot)
		spot.y = level.streamer.height_at(spot.x, spot.z) + 0.2
		actor.place_at(Transform3D(Basis.IDENTITY, spot))
		seat += 1
	await _frames(2)


func _grow(at: Vector3) -> WildMob:
	var spawner: MobSpawner = MobSpawner.new()
	spawner.name = "MosaicSpawner%d" % _spawners.size()
	spawner.territory = "Oakshire Holm"
	spawner.variant_ids = [&"grey_pelt_prowler"]
	spawner.leash = 40.0
	level.add_child(spawner)
	level.streamer.ensure_ground_at(at)
	spawner.global_position = Vector3(at.x, level.streamer.height_at(at.x, at.z), at.z)
	_spawners.append(spawner)
	spawner.spawn_mobs()
	await _frames(3)
	return spawner.mobs[0] if not spawner.mobs.is_empty() else null


func _party() -> Array[ActorBase]:
	var list: Array[ActorBase] = []
	for actor: ActorBase in CombatDirector.current.party_actors():
		if actor.is_local_player() and not actor.is_companion:
			list.append(actor)
	return list


func _p1() -> ActorBase:
	var party: Array[ActorBase] = _party()
	return party[0] if not party.is_empty() else null
