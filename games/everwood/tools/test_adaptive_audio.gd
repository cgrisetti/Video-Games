## The adaptive score's checks (16_ADAPTIVE_AUDIO_ARCHITECTURE.md §5.2), run by
## tools/smoke_test.gd in two parts:
##   run_corridor(), in the seamless world after its own checks:
##     1  the five buses in order with their effects (the Music bus's low-pass,
##        warm EQ, chamber-hall reverb and SignTelegraphs-keyed compressor; the
##        SignTelegraphs hall; the limiters)
##     2  the catalog: fourteen zone profiles (The Crown's five shore suites since docs/23; the two
##        Audio Mosaics' cells are tools/test_audio_architecture.gd's), the Four Signs' chords, nine Callings,
##        the Cairnsman's suite; every zone's four baked acoustic stems (looping
##        Ogg Vorbis, its arrangement's length) in its _sync.tres; and the
##        fallback: ProceduralChamberSynth playing Moss-Oak Hollow's score, and a
##        profile with no score, on its physical models
##     3  walking the trail picks each chunk's score: Honey-Wick, Bramble-Bridge
##        (both on acoustic stems with the folk base and lead at 0 dB, and the
##        Sanctuary Cadence on arrival), Moss-Oak Hollow blending into
##        Rush-Light-Hollow's discord as the lane sinks (dropped 12 dB under an
##        E Lydian harp glissando by the water-shrine), Doverslap Falls and the
##        Ring; the majority of local players wins, a tie going up the trail
##     4  the stations' ambience: every emitter on Ambience3D with area_mask = 1
##        (the carillon and the gate's plates acoustic), and the campfire's
##        crackle dropping 6 dB while it burns low
##   run_vale(), in Oakshire Vale after the Lens's checks:
##     5  the 32-voice pool: 64 sounds at 10 m never sound more than 32 voices or
##        make a node, a second sound of a kind within 50 ms is turned away, one
##        beyond 45 m is culled, and every voice has area_mask = 1
##     6  the four stages on a padfoot grown beside the village: Proximity
##        Pre-Warm at 24 m, the Skirmish Lock (0 / -18 / -3 / 0 dB on the same
##        stream, the accent on the next eighth note), and the Restoration
##        Exhale (1.5 s hold, the cadence, stems 2 and 3 gone after 3.6 s, a 10 s
##        breath at -24 dB, then exploring again)
##     7  each Sign's stinger is its acoustic chord re-pitched to the vale's tonic
##        and ducks the Music bus 4.5 dB for 0.3 s; a Calling's motif sits an
##        octave under
## (The Cairnsman's Poise-Stagger window and the Co-Op Gate's plate harmonies
## are checked in the expedition, in smoke_test.gd.)
extends RefCounted

const SpiritState = HobSpectrumComponent.SpiritState
const State = AudioDirector.AcousticState
const VILLAGE: Vector3 = Vector3(768.0, 12.0, 778.0)

var tree: SceneTree
var check: Callable
var director: AudioDirector
var _spawners: Array[MobSpawner] = []


# --- In the seamless world -------------------------------------------------------

func run_corridor(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	director = AudioDirector.current
	if director == null:
		check.call(false, "the AudioDirector autoload (Score) is running")
		return
	director.wait_for_renders()
	_check_buses()
	_check_catalog()
	var world: EverwoodWorld = tree.current_scene as EverwoodWorld
	if world == null:
		check.call(false, "the trail's score checks run in the seamless world")
		return
	await _check_trail(world)
	await _check_station_ambience(world)


func _check_buses() -> void:
	var names: PackedStringArray = PackedStringArray()
	for index: int in AudioDirector.BUS_NAMES.size():
		names.append(AudioServer.get_bus_name(index))
	var music: int = AudioServer.get_bus_index(&"Music")
	var warmth: AudioEffectEQ6 = AudioServer.get_bus_effect(music, 1) as AudioEffectEQ6
	var hall: AudioEffectReverb = AudioServer.get_bus_effect(music, 2) as AudioEffectReverb
	var squeeze: AudioEffectCompressor = AudioServer.get_bus_effect(music, 3) as AudioEffectCompressor if AudioServer.get_bus_effect_count(music) > 3 else null
	var sign_hall: AudioEffectReverb = AudioServer.get_bus_effect(AudioServer.get_bus_index(&"SignTelegraphs"), 0) as AudioEffectReverb
	var effects: bool = AudioServer.get_bus_effect(0, 0) is AudioEffectHardLimiter and AudioServer.get_bus_effect(music, 0) is AudioEffectLowPassFilter \
		and warmth != null and is_equal_approx(warmth.get_band_gain_db(2), 1.5) and is_equal_approx(warmth.get_band_gain_db(4), -2.0) \
		and hall != null and is_equal_approx(hall.room_size, 0.38) and is_equal_approx(hall.damping, 0.68) and is_equal_approx(hall.spread, 0.85) \
		and is_equal_approx(hall.wet, 0.18) and squeeze != null and squeeze.sidechain == &"SignTelegraphs" \
		and is_equal_approx(squeeze.ratio, 4.0) and is_equal_approx(squeeze.threshold, -18.0) \
		and sign_hall != null and is_equal_approx(sign_hall.room_size, 0.42) and is_equal_approx(sign_hall.wet, 0.22) \
		and AudioServer.get_bus_effect(AudioServer.get_bus_index(&"Ambience3D"), 0) is AudioEffectLowPassFilter \
		and AudioServer.get_bus_effect(AudioServer.get_bus_index(&"CombatSFX"), 0) is AudioEffectHardLimiter
	var routed: bool = true
	for index: int in range(1, AudioDirector.BUS_NAMES.size()):
		routed = routed and AudioServer.get_bus_send(index) == &"Master"
	check.call(AudioServer.bus_count >= 5 and ", ".join(names) == "Master, Music, Ambience3D, SignTelegraphs, CombatSFX" and effects and routed,
		"five buses built in code, in order (%s), each sending to Master: limiters on Master and CombatSFX; Music low-passed, warmed (+1.5 dB round 250 Hz, -2 dB at 3.2 kHz), in a warm wooden chamber hall (room 0.38, damping 0.68, spread 0.85, wet 0.18) and compressed 4:1 from -18 dB keyed by SignTelegraphs, which has its own hall" % ", ".join(names))


func _check_catalog() -> void:
	var ids: Array[String] = []
	var stems_ok: bool = true
	for zone: ZoneMusicProfileResource in AudioCatalog.zones():
		ids.append(String(zone.profile_id))
		# The two Audio Mosaics' cells are checked by tools/test_audio_architecture.gd.
		if zone.is_mosaic():
			continue
		var sync: AudioStreamSynchronized = director._stream_for(zone) as AudioStreamSynchronized
		stems_ok = stems_ok and sync != null and sync.stream_count == 4 and ResourceLoader.exists(AudioDirector.sync_path(zone.profile_id))
		if sync == null:
			continue
		for layer: int in 4:
			var ogg: AudioStreamOggVorbis = sync.get_sync_stream(layer) as AudioStreamOggVorbis
			stems_ok = stems_ok and ogg != null and ogg.loop and absf(ogg.get_length() - zone.loop_sec()) < 0.02 \
				and is_equal_approx(ogg.bpm, zone.bpm) and ogg.beat_count == zone.loop_bars() * zone.beats_per_bar
	ids.sort()
	check.call(", ".join(ids) == "bramble_bridge_square, cairnsmans_vigil, crown_gale_cliffs, crown_iron_shore, crown_island, crown_millers_oak, crown_south_bay, crown_tide_grottos, dover_slap_falls, honey_wick, millers_holm, moss_oak_hollow, oakshire_vale, ring_of_the_cairnsman" and stems_ok,
		"fourteen zone profiles: the vale's seven and The Crown's five, each with four phase-locked acoustic stems (looping Ogg Vorbis rendered from the SoundFont by tools/build_audio_stems.py, each exactly its arrangement's bars) in its baked AudioStreamSynchronized, and the Caldera's two Audio Mosaics")
	# Tier 2: without the stems, ProceduralChamberSynth plays the same score on its physical models.
	var hollow: ZoneMusicProfileResource = AudioCatalog.zone(&"moss_oak_hollow")
	var snap: Dictionary = ProceduralChamberSynth.snapshot(hollow)
	var modelled: Array[PackedByteArray] = ProceduralChamberSynth.render_stems(snap)
	var bare: ZoneMusicProfileResource = ZoneMusicProfileResource.new()
	bare.profile_id = &"no_score_here"
	var generated: Array[PackedByteArray] = ProceduralChamberSynth.render_stems(ProceduralChamberSynth.snapshot(bare))
	var fallback_ok: bool = (snap["score"] as Dictionary).has("stems") and modelled.size() == 4 and generated.size() == 4
	for pcm: PackedByteArray in modelled:
		fallback_ok = fallback_ok and absf(pcm.size() / 2.0 / ProceduralChamberSynth.MIX_RATE - hollow.loop_sec()) < 0.01 and _loudest(pcm) > 12000
	for pcm: PackedByteArray in generated:
		fallback_ok = fallback_ok and absf(pcm.size() / 2.0 / ProceduralChamberSynth.MIX_RATE - bare.loop_sec()) < 0.01 and _loudest(pcm) > 12000
	check.call(fallback_ok, "the fallback plays Moss-Oak Hollow's baked score (%d notes) on Karplus-Strong strings, formant reeds, musette reeds and bowed strings, and builds a waltz for a profile with no score" % [
		(snap["score"]["stems"][0] as Array).size() + (snap["score"]["stems"][1] as Array).size() + (snap["score"]["stems"][2] as Array).size() + (snap["score"]["stems"][3] as Array).size()])
	var chords: Array[String] = []
	for sign_id: int in [ScribeSignResource.Sign.SIGN_IRON_ROOT, ScribeSignResource.Sign.SIGN_RIME_GALE, ScribeSignResource.Sign.SIGN_WARM_HEARTH,
			ScribeSignResource.Sign.SIGN_STAR_TIDE]:
		var profile: SignHarmonicProfileResource = AudioCatalog.sign_profile(sign_id)
		chords.append(str(profile.chord_semitone_intervals) if profile != null else "none")
	var callings: int = 0
	for calling: CallingResource in ArsenalCatalog.current.callings():
		callings += 1 if AudioCatalog.calling(calling.calling_id) != null else 0
	var boss: BossAudioProfileResource = AudioCatalog.boss(ArsenalCatalog.CAIRNSMAN)
	check.call(" ".join(chords) == "[0, 7, 12] [0, 4, 6, 7, 12] [0, 4, 7, 11, 14] [0, 5, 9, 12]" and callings == 9 and boss != null
		and AudioCatalog.zone(boss.suite_profile_id) != null,
		"the Four Signs' chords (Shatterpoint's open fifth, Glacial Rupture's Lydian burst, Dawnburst's major ninth, Astral Chorus's rising IV), all nine Callings' voices and the Cairnsman's suite are registered")


func _check_trail(world: EverwoodWorld) -> void:
	var people: Array[ActorBase] = _people()
	var heard: Array[StringName] = []
	var listen: Callable = func(id: StringName, _notes: PackedInt32Array) -> void: heard.append(id)
	director.stinger_played.connect(listen)
	_move(people, Vector3(40.0, 0.5, 178.0))
	director.evaluate_now()
	var commons: StringName = director.get_active_profile_id()
	var commons_up: bool = _acoustic_and_up()
	_move(people, LandblockManifest.TOWN_SQUARE_SPAWN)
	director.evaluate_now()
	var square: StringName = director.get_active_profile_id()
	var square_up: bool = _acoustic_and_up()
	for frame: int in 130:
		await tree.process_frame
	check.call(commons == &"honey_wick" and square == &"bramble_bridge_square" and commons_up and square_up and heard.has(&"sanctuary_cadence"),
		"the Kindle-Fire (Chunk (0, 1)) plays Honey-Wick's G Ionian sway and Bramble-Bridge (Chunk (0, 0)) its G Lydian waltz, both on four acoustic stems with the folk base and the pastoral lead at 0 dB, and crossing in brings the Sanctuary Cadence on the next bar")
	# Down the sunken lane (clear of the water-shrine at z -64.5, whose oasis would lift the hush).
	var depths: Array[float] = []
	var heard_ok: Array[bool] = []
	for z: float in [-30.0, -58.0, -80.0]:
		_move(people, Vector3(64.0, -1.6, z))
		director.evaluate_now()
		depths.append(director.discord_depth)
		var expected: Vector2 = _expected_lead_discord(director.discord_depth)
		heard_ok.append(absf(director.get_stem_target_db(1) - expected.x) < 0.1 and absf(director.get_stem_target_db(2) - expected.y) < 0.1)
	check.call(director.get_active_profile_id() == &"moss_oak_hollow" and is_zero_approx(depths[0]) and is_equal_approx(depths[1], 0.2) and is_equal_approx(depths[2], 1.0)
		and not heard_ok.has(false) and director.get_stem_target_db(2) > -0.1 and director.get_stem_target_db(1) <= -79.0,
		"down Moss-Oak Hollow's sunken lane the lead stem hands over to Rush-Light-Hollow's discord on an equal-power curve (depth %.1f, %.1f, %.1f), under the sleeping Hush-Crack's pre-warm (S = %.2f)" % [
			depths[0], depths[1], depths[2], director.proximity])
	var oasis: Node3D = null
	for node: Node in tree.get_nodes_in_group(AudioDirector.OASIS_GROUP):
		if node is WaterShrine and (node as Node3D).is_inside_tree():
			oasis = node as Node3D
	var lifted: float = 0.0
	if oasis != null:
		heard.clear()
		_move(people, oasis.global_position + Vector3(1.5, 0.0, 0.0))
		director.evaluate_now()
		lifted = _expected_lead_discord(director.discord_depth).y + AudioDirector.OASIS_DISCORD_DB
	check.call(oasis != null and director.oasis and director.discord_depth > 0.0 and absf(director.get_stem_target_db(2) - maxf(-80.0, lifted)) < 0.1
		and heard.has(&"oasis_glissando") and director.last_stinger_stream is AudioStreamWAV
		and is_equal_approx(director.last_stinger_pitch, AudioDirector.key_shift(64, AudioDirector.BAKED_TONIC)),
		"by the Wayfarer's Water-Shrine (a Miyazaki oasis) the hush drops 12 dB, to %.1f dB, under the harp's two-octave Lydian glissando moved into E" % director.get_stem_target_db(2))
	_move(people, Vector3(64.0, 3.0, -150.0))
	director.evaluate_now()
	var falls: StringName = director.get_active_profile_id()
	_move(people, Vector3(64.0, 6.0, -280.0))
	director.evaluate_now()
	check.call(falls == &"dover_slap_falls" and director.get_active_profile_id() == &"ring_of_the_cairnsman",
		"Doverslap Falls plays its A Dorian march, and the Ring of the Cairnsman its wind-swept D Dorian")
	if people.size() >= 2:
		people[0].place_at(Transform3D(Basis.IDENTITY, LandblockManifest.TOWN_SQUARE_SPAWN))
		for index: int in range(1, people.size()):
			people[index].place_at(Transform3D(Basis.IDENTITY, Vector3(64.0 + index, 3.0, -150.0)))
		director.evaluate_now()
		var most_up: StringName = director.get_active_profile_id()
		people[0].place_at(Transform3D(Basis.IDENTITY, Vector3(64.0, 3.0, -150.0)))
		for index: int in range(1, people.size()):
			people[index].place_at(Transform3D(Basis.IDENTITY, LandblockManifest.TOWN_SQUARE_SPAWN + Vector3(index, 0.0, 0.0)))
		director.evaluate_now()
		var expected: StringName = &"dover_slap_falls" if people.size() == 2 else &"bramble_bridge_square"
		check.call(most_up == &"dover_slap_falls" and director.get_active_profile_id() == expected,
			"split across the trail, %d local players hear the zone most of them stand in, a tie going up the trail" % people.size())
	director.stinger_played.disconnect(listen)
	_move(people, LandblockManifest.TOWN_SQUARE_SPAWN)
	director.evaluate_now()
	for frame: int in 60:
		await tree.physics_frame


## The lead and discord stems' targets for a depth, as §5.2-5.3 set them (and Stage A's pre-warm if it's on).
func _expected_lead_discord(depth: float) -> Vector2:
	var profile: ZoneMusicProfileResource = AudioCatalog.zone(director.get_active_profile_id())
	var lead: float = profile.explore_db(1)
	var discord: float = profile.explore_db(2)
	if depth > 0.0:
		lead = maxf(-80.0, lead + linear_to_db(cos(depth * PI * 0.5)))
		discord = maxf(-80.0, linear_to_db(sin(depth * PI * 0.5)))
	if director.state == State.PROXIMITY:
		lead += AudioDirector.PREWARM_LEAD_DIP_DB * director.proximity
		discord = maxf(discord, maxf(-80.0, AudioDirector.PREWARM_DISCORD_DB + linear_to_db(sin(director.proximity * PI * 0.5))))
	return Vector2(lead, discord)


func _check_station_ambience(world: EverwoodWorld) -> void:
	var emitters: Array[AudioStreamPlayer3D] = director.ambience_emitters()
	var masked: bool = not emitters.is_empty()
	for emitter: AudioStreamPlayer3D in emitters:
		masked = masked and emitter.area_mask == 1 and emitter.bus == &"Ambience3D" and emitter.stream != null
	var baked: int = 0
	for kind: StringName in [&"carillon", &"gate_drone", &"gate_counter"]:
		var loop: AudioStreamOggVorbis = director.ambience_stream(kind) as AudioStreamOggVorbis
		baked += 1 if loop != null and loop.loop else 0
	var fire: HearthCampfire = _find(world, func(node: Node) -> bool: return node is HearthCampfire) as HearthCampfire
	var crackle: AudioStreamPlayer3D = fire.get_node_or_null(^"Ambience_hearth_fire") as AudioStreamPlayer3D if fire != null else null
	var lit: float = crackle.volume_db if crackle != null else 1.0
	if fire != null:
		fire.resting_left = 5.0
		await tree.process_frame
		await tree.process_frame
	var low: float = crackle.volume_db if crackle != null else 1.0
	if fire != null:
		fire.resting_left = 0.0
	check.call(masked and baked == 3 and crackle != null and is_zero_approx(lit) and is_equal_approx(low, HearthCampfire.LOW_CRACKLE_DB),
		"the stations sing in 3D on Ambience3D with area_mask = 1 (%d emitters; the carillon and the gate's plate harmonies are acoustic loops), and the Kindle-Fire's crackle drops 6 dB while it burns low" % emitters.size())


# --- In Oakshire Vale ---------------------------------------------------------------

func run_vale(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	director = AudioDirector.current
	var level: OakshireVale = tree.current_scene as OakshireVale
	if director == null or level == null:
		check.call(false, "the vale's score checks run in Oakshire Vale")
		return
	var p1: ActorBase = _people()[0]
	p1.place_at(Transform3D(Basis.IDENTITY, VILLAGE))
	director.evaluate_now()
	check.call(director.get_active_profile_id() == OakshireVale.MUSIC_PROFILE, "Oakshire Vale plays its own F Lydian pastoral")
	# The Lens's checks fought just now: let that fight's exhale and breath finish first.
	for frame: int in 1500:
		if director.state == State.EXPLORATION or director.state == State.PROXIMITY:
			break
		await tree.physics_frame
	await _check_voice_pool(p1)
	await _check_stages(p1, level)
	await _check_stingers()
	for spawner: MobSpawner in _spawners:
		if is_instance_valid(spawner):
			spawner.queue_free()
	await tree.physics_frame


func _check_voice_pool(p1: ActorBase) -> void:
	await tree.physics_frame
	var pool: Node = director.get_node(^"VoicePool")
	var nodes_before: int = pool.get_child_count()
	var stream: AudioStream = AudioCues.current.stream_for(&"hit")
	var near: Vector3 = p1.global_position + Vector3(10.0, 0.0, 0.0)
	var claimed: int = 0
	for index: int in 64:
		claimed += 1 if director.play_sfx_3d(StringName("test_sfx_%d" % index), near, stream) else 0
	var active: int = director.active_voice_count()
	var masked: bool = true
	for voice: AudioStreamPlayer3D in director.voice_pool():
		masked = masked and voice.area_mask == 1 and voice.bus == &"CombatSFX"
	check.call(director.get_voice_pool_size() == 32 and claimed == 64 and active <= 32 and pool.get_child_count() == nodes_before and masked,
		"64 different sounds at 10 m share the 32-voice pool: %d sounding, no node made, every voice on CombatSFX with area_mask = 1" % active)
	var first: bool = director.play_sfx_3d(&"test_cooldown", near, stream)
	var again: bool = director.play_sfx_3d(&"test_cooldown", near, stream)
	for frame: int in 4:
		await tree.physics_frame
	var later: bool = director.play_sfx_3d(&"test_cooldown", near, stream)
	var culled_before: int = director.culled_count
	var far: bool = director.play_sfx_3d(&"test_far", p1.global_position + Vector3(50.0, 0.0, 0.0), stream)
	check.call(first and not again and later and not far and director.culled_count == culled_before + 1,
		"a second sound of the same kind within 50 ms is turned away (allowed again 66 ms later), and one 50 m from everyone is culled")


func _check_stages(p1: ActorBase, level: OakshireVale) -> void:
	var at: Vector3 = VILLAGE + Vector3(0.0, 0.0, 60.0)
	var padfoot: WildMob = await _grow(level, &"grey_pelt_prowler", at)
	if padfoot == null:
		check.call(false, "a padfoot grows beside the village")
		return
	var heard: Array[StringName] = []
	var listen: Callable = func(id: StringName, _notes: PackedInt32Array) -> void: heard.append(id)
	director.stinger_played.connect(listen)
	padfoot.loadout.stats.move_speed = 0.0
	p1.place_at(Transform3D(Basis.IDENTITY, padfoot.global_position + Vector3(0.0, 0.5, 24.0)))
	director.evaluate_now()
	check.call(director.state == State.PROXIMITY and director.proximity > 0.4 and director.proximity < 0.6
		and director.get_stem_target_db(2) > -12.0 and director.get_stem_target_db(1) < -1.0,
		"24 m from an awake padfoot the Proximity Pre-Warm whispers: S = %.2f, the discord stem up to %.1f dB, the lead down to %.1f dB" % [
			director.proximity, director.get_stem_target_db(2), director.get_stem_target_db(1)])
	var stream_before: AudioStreamSynchronized = director.front_stream()
	padfoot.engaged = true
	p1.place_at(Transform3D(Basis.IDENTITY, padfoot.global_position + Vector3(0.0, 0.5, 6.0)))
	director.evaluate_now()
	for frame: int in 40:
		await tree.process_frame
	var volumes: Array[float] = []
	for layer: int in 4:
		volumes.append(roundf(director.get_stem_volume_db(layer)))
	check.call(director.state == State.SKIRMISH and director.front_stream() == stream_before and str(volumes) == "[0.0, -18.0, -3.0, 0.0]"
		and heard.has(&"skirmish_accent"),
		"the fight locks the Skirmish stage on the same playing stems (no restart): %s dB, with a bodhran-and-dulcimer accent on the next eighth note" % str(volumes))
	padfoot.stats.take_damage(padfoot.stats.health + 1.0)
	p1.place_at(Transform3D(Basis.IDENTITY, VILLAGE))
	var held: bool = true
	for frame: int in 60:
		await tree.process_frame
		held = held and director.state == State.SKIRMISH
	var exhaling: bool = false
	for frame: int in 60:
		await tree.process_frame
		exhaling = exhaling or director.state == State.EXHALE
	await _seconds(ZoneMusicProfileResource.RESTORATION_EXHALE_SEC + 0.2)
	var faded: bool = director.get_stem_volume_db(2) <= -79.0 and director.get_stem_volume_db(3) <= -79.0
	await _seconds(1.5)
	var breath: bool = director.state == State.EXHALE and director.get_stem_volume_db(0) <= AudioDirector.BREATH_DB + 0.5 \
		and director.get_stem_volume_db(1) <= AudioDirector.BREATH_DB + 0.5
	await _seconds(ZoneMusicProfileResource.POST_COMBAT_SILENCE_SEC)
	director.stinger_played.disconnect(listen)
	check.call(held and exhaling and heard.has(&"restoration_exhale") and faded and breath and director.state == State.EXPLORATION,
		"un-boggarted, the fight holds 1.5 s, then the Restoration Exhale: a minor-to-Lydian cadence, the skirmish stems gone in 3.6 s, 10 s of breath at -24 dB, then exploring again")


func _check_stingers() -> void:
	var root: int = AudioCatalog.zone(OakshireVale.MUSIC_PROFILE).root_pitch_midi
	var chords: Array[String] = []
	var ducked: bool = true
	var acoustic: bool = true
	var expected: Array[String] = []
	var p1: ActorBase = _people()[0]
	for sign_id: int in [ScribeSignResource.Sign.SIGN_IRON_ROOT, ScribeSignResource.Sign.SIGN_RIME_GALE, ScribeSignResource.Sign.SIGN_WARM_HEARTH,
			ScribeSignResource.Sign.SIGN_STAR_TIDE]:
		CombatDirector.current.synergy_detonated.emit(p1, sign_id, true, "TEST")
		chords.append(str(director.last_stinger_notes))
		expected.append(str(AudioCatalog.sign_profile(sign_id).notes_over(root)))
		acoustic = acoustic and director.last_stinger_stream is AudioStreamWAV and (director.last_stinger_stream as AudioStreamWAV).data.size() > 10000 \
			and is_equal_approx(director.last_stinger_pitch, AudioDirector.key_shift(root, AudioDirector.BAKED_TONIC))
		for frame: int in 6:
			await tree.process_frame
		ducked = ducked and director.music_duck_db() < -4.0 and AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music")) < -8.0
	await _seconds(1.4)
	var released: bool = director.music_duck_db() > -0.5
	check.call(chords == expected and int(director.last_stinger_notes[0]) == root and acoustic and ducked and released,
		"every Four-Sign detonation plays its acoustic chord baked in G, moved down to the vale's tonic (F = %d: %s, at x%.3f), and ducks the Music bus 4.5 dB for 0.3 s" % [
			root, chords[0], AudioDirector.key_shift(root, AudioDirector.BAKED_TONIC)])
	director.play_calling_motif(&"bridge_warden")
	check.call(director.last_stinger_id == &"calling_bridge_warden" and director.last_stinger_notes == PackedInt32Array([root - 12, root - 5, root]),
		"a Bridge-Warden's posture motif is a low root, fifth and octave under the zone's tonic")


# --- Helpers ----------------------------------------------------------------------

## The playing deck is the four acoustic stems, with the folk base and the pastoral lead at 0 dB.
func _acoustic_and_up() -> bool:
	var sync: AudioStreamSynchronized = director.front_stream()
	if sync == null or sync.stream_count != 4:
		return false
	for layer: int in 4:
		if not sync.get_sync_stream(layer) is AudioStreamOggVorbis:
			return false
	return is_zero_approx(director.get_stem_volume_db(0)) and is_zero_approx(director.get_stem_volume_db(1))


## The loudest sample in 16-bit PCM.
static func _loudest(pcm: PackedByteArray) -> int:
	var loudest: int = 0
	for index: int in range(0, pcm.size() - 1, 8):
		loudest = maxi(loudest, absi(pcm.decode_s16(index)))
	return loudest


func _people() -> Array[ActorBase]:
	var people: Array[ActorBase] = []
	for actor: ActorBase in CombatDirector.current.party_actors():
		if actor.is_local_player() and not actor.is_companion:
			people.append(actor)
	return people


func _move(people: Array[ActorBase], spot: Vector3) -> void:
	for index: int in people.size():
		people[index].place_at(Transform3D(Basis.IDENTITY, spot + Vector3(index * 1.2, 0.2, 0.0)))


func _grow(level: OakshireVale, variant_id: StringName, at: Vector3) -> WildMob:
	var spawner: MobSpawner = MobSpawner.new()
	spawner.name = "AudioSpawner%d" % _spawners.size()
	spawner.territory = "Oakshire-Wick"
	spawner.variant_ids = [variant_id]
	spawner.leash = 40.0
	level.add_child(spawner)
	spawner.global_position = Vector3(at.x, WorldGridConfig.layout.sample_height(at.x, at.z), at.z)
	_spawners.append(spawner)
	spawner.spawn_mobs()
	for frame: int in 3:
		await tree.physics_frame
	return spawner.mobs[0] if not spawner.mobs.is_empty() else null


func _find(root: Node, matches: Callable) -> Node:
	if matches.call(root):
		return root
	for child: Node in root.get_children():
		var found: Node = _find(child, matches)
		if found != null:
			return found
	return null


func _seconds(seconds: float) -> void:
	var left: float = seconds
	while left > 0.0:
		await tree.physics_frame
		left -= 1.0 / 60.0
