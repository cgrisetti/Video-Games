## The adaptive score and mix (autoload "Score"; 16_ADAPTIVE_AUDIO_ARCHITECTURE.md).
##
## - The bus layout is built here in code (§5.1): Master (hard limiter), Music
##   (low-pass, a warm EQ: +1.5 dB round 250 Hz and -2 dB at 3.2 kHz, the warm
##   wooden chamber hall's reverb, a compressor keyed by SignTelegraphs),
##   Ambience3D, SignTelegraphs (the same hall, a touch wetter) and CombatSFX
##   (hard limiter).
## - Two decks (Deck A and Deck B) each play one zone's four phase-locked stems
##   as an AudioStreamSynchronized: the acoustic stems tools/build_audio_stems.py
##   bakes (res://assets/audio/music/<profile_id>_sync.tres, or the four .ogg
##   stems beside it), else ProceduralChamberSynth's physical-model rendition of
##   the same score, rendered on a worker thread. A new zone or a boss suite
##   loads into the back deck and crossfades; the stems never restart in a fight.
## - Every 0.4 s (2.5 Hz, two beats of the world grid's 0.2 s streaming
##   heartbeat) it resolves one party state from the local players (§5.2): the
##   zone most of them stand in (ties go to the one furthest up the trail),
##   the depth blend into the Holloway discord, and the threat round them.
## - The four-stage envelope (§5.3): Exploration, the 35 m -> 14 m Proximity
##   Pre-Warm, the Active Skirmish Lock (0.4 s, its accent on the next eighth
##   note), the Boss suite with its Poise-Stagger Lydian window, and the
##   Restoration Exhale (1.5 s hold, a cadence on the next bar, a 3.6 s fade,
##   then 10 s of breath). Out of a fight, each music cycle is followed by a
##   Brower silence breath.
## - Four-Sign detonations play their acoustic chord (baked in G) re-pitched to
##   the zone's tonic on SignTelegraphs and duck the Music bus 4.5 dB for 300 ms;
##   bosses' stagger flourishes go there too. The cadences, the skirmish accent,
##   the gate's fanfare and the portal's chord are baked acoustic stingers as
##   well; ProceduralChamberSynth plays any that are missing.
## - By a water-shrine or wind-lantern (an oasis) the Holloway discord drops
##   12 dB under a Lydian harp glissando in the zone's key; coming home through
##   a portal plays the Sanctuary Cadence.
## - A pool of 32 AudioStreamPlayer3D voices made once at start (§1.2): combat
##   sounds beyond 45 m of every local player are culled, each kind of sound
##   waits 50 ms between plays, and every 3D player gets area_mask = 1.
## Levels say which profile plays where (LevelBase.music_profile_at()); nothing
## here names a zone or a boss. Headless runs keep every state and volume but
## start no playback, so nothing is left sounding at quit.
class_name AudioDirector
extends Node

signal profile_changed(profile_id: StringName)
signal state_changed(state: AcousticState)
signal stinger_played(stinger_id: StringName, notes: PackedInt32Array)

enum AcousticState { EXPLORATION, PROXIMITY, SKIRMISH, BOSS, EXHALE }

const BUS_NAMES: Array[StringName] = [&"Master", &"Music", &"Ambience3D", &"SignTelegraphs", &"CombatSFX"]
const BUS_VOLUMES_DB: Array[float] = [0.0, -4.0, -6.0, -1.5, -3.0]
const MUSIC_BUS: int = 1
const AMBIENCE_BUS: int = 2
const SIGN_BUS: int = 3
const SFX_BUS: int = 4
## Seconds between party-state evaluations (2.5 Hz).
const HEARTBEAT: float = 0.4
const MUTED_DB: float = -80.0
const VOICE_POOL_SIZE: int = 32
const SFX_COOLDOWN: float = 0.05
const CULL_DISTANCE: float = 45.0
## The Proximity Pre-Warm's outer and inner radii (ZoneMusicProfileResource's).
const PREWARM_OUTER: float = 35.0
const PREWARM_INNER: float = 14.0
## A fight this close to a local player (or a teammate near one) locks the skirmish.
const ENGAGE_RADIUS: float = 35.0
const BOSS_RADIUS: float = 45.0
const HYSTERESIS_HOLD: float = 1.5
const BREATH_DB: float = -24.0
const ZONE_CROSSFADE_SEC: float = 4.0
const SILENCE_FADE_SEC: float = 3.0
const EXPLORE_RETURN_SEC: float = 3.0
const STATE_RAMP_SEC: float = 1.0
const STAGGER_RAMP_SEC: float = 0.1
const OASIS_RADIUS: float = 4.0
## Nodes in this group (water-shrines, wind-lanterns) lift the Holloway discord within OASIS_RADIUS.
const OASIS_GROUP: StringName = &"audio_oasis"
const SKIRMISH_DB: Array[float] = [0.0, -18.0, -3.0, 0.0]
const PREWARM_LEAD_DIP_DB: float = -4.0
const PREWARM_DISCORD_DB: float = -6.0
const LPF_OPEN_HZ: float = 20000.0
const LPF_PORTAL_HZ: float = 900.0
const PORTAL_SWEEP_SEC: float = 0.5
const DUCK_ATTACK_SEC: float = 0.03
const DUCK_RELEASE_SEC: float = 0.25
## Combat sounds: a 4-take randomizer's spread (x1.08 pitch, ±1.5 dB).
const SFX_PITCH_SPREAD: float = 1.08
const SFX_GAIN_SPREAD_DB: float = 1.5
## Godot 4.7.2's calibrated 3D sweet spot (16 §6.2).
const UNIT_SIZE: float = 10.0
const MAX_DB: float = 3.0
const MAX_DISTANCE: float = 60.0
const FAR_FILTER_HZ: float = 5000.0
const FAR_FILTER_DB: float = -9.5
const STINGER_VOICES: int = 6
const MUSIC_FOLDER: String = "res://assets/audio/music/"
## A zone's four baked stems, in its folder under MUSIC_FOLDER.
const STEM_FILES: Array[String] = ["stem_0_folk_base.ogg", "stem_1_pastoral_lead.ogg", "stem_2_holloway_discord.ogg",
	"stem_3_skirmish_drive.ogg"]
## The key the Sign chords and most stingers are baked in (G4): they're re-pitched to the zone's tonic.
const BAKED_TONIC: int = 67
## The warm wooden chamber hall (16 §5.1, §4.2): room size, damping, spread, wet.
const MUSIC_HALL: Array[float] = [0.38, 0.68, 0.85, 0.18]
const SIGN_HALL: Array[float] = [0.42, 0.65, 0.85, 0.22]
## The Music bus's warm EQ: +1.5 dB in the 320 Hz band (the bassoon and cello's warmth round
## 250 Hz; EQ6's nearest band) and -2 dB at 3.2 kHz, carving room for combat sounds.
const WARMTH_DB: float = 1.5
const CARVE_DB: float = -2.0
## By an oasis the Holloway discord drops this far.
const OASIS_DISCORD_DB: float = -12.0
## The baked acoustic stingers by id: [file in ProceduralChamberSynth.SAMPLES_FOLDER, the tonic
## it was baked over (re-pitched to the zone's), or 0 to play it as baked].
const STINGER_FILES: Dictionary[StringName, Array] = {&"sanctuary_cadence": ["stinger_sanctuary_cadence.wav", 67],
	&"restoration_exhale": ["stinger_restoration_exhale.wav", 67], &"skirmish_accent": ["stinger_skirmish_accent.wav", 67],
	&"gate_fanfare": ["stinger_gate_fanfare.wav", 0], &"wayfarers_threshold": ["stinger_wayfarers_threshold.wav", 0],
	&"oasis_glissando": ["sample_harp_lydian_gliss.wav", 67]}
## Instrument words in a profile's timbre name, and the code-built voice for each.
const TIMBRE_WORDS: Dictionary[String, ProceduralChamberSynth.Timbre] = {"BASSOON": ProceduralChamberSynth.Timbre.REED,
	"OBOE": ProceduralChamberSynth.Timbre.OBOE, "DULCIMER": ProceduralChamberSynth.Timbre.DULCIMER,
	"CELLO": ProceduralChamberSynth.Timbre.PIZZ, "PIZZ": ProceduralChamberSynth.Timbre.PIZZ,
	"ACCORDION": ProceduralChamberSynth.Timbre.ACCORDION, "MANDOLIN": ProceduralChamberSynth.Timbre.MANDOLIN,
	"GUITAR": ProceduralChamberSynth.Timbre.PLUCK, "HARP": ProceduralChamberSynth.Timbre.HARP, "BRONZE": ProceduralChamberSynth.Timbre.BELL,
	"CARILLON": ProceduralChamberSynth.Timbre.BELL, "WHISTLE": ProceduralChamberSynth.Timbre.WHISTLE, "VIOLIN": ProceduralChamberSynth.Timbre.VIOLIN}
## The Bramble-Bridge Sanctuary Cadence (16 §4.2): e minor, Cmaj7, D6, Gmaj9(#11).
const SANCTUARY_CADENCE: Array[Array] = [[52, 55, 59, 64], [48, 55, 59, 64], [50, 54, 57, 59], [43, 50, 54, 57, 61, 69]]
## The Restoration Exhale (16 §5.3 D): a minor chord resolving onto a Lydian sixth.
const EXHALE_CADENCE: Array[Array] = [[52, 55, 59], [48, 55, 57, 64]]
## The Wayfarer's Threshold (16 §6.3): G sus2 add9 on Chimes and harp.
const THRESHOLD_CHORD: Array[int] = [55, 57, 62, 69, 74]
## The skirmish accent: a bodhran rim-hit, a dulcimer roll and a mandolin slash.
const SKIRMISH_ACCENT_SEMITONES: Array[int] = [0, 7, 12, 7, 12]

## The live autoload node (see NetworkManager.current for why).
static var current: AudioDirector

var state: AcousticState = AcousticState.EXPLORATION
## Stage A's scalar: 0 at 35 m from the nearest awake foe, 1 at 14 m.
var proximity: float = 0.0
## The zone's depth blend into its Holloway discord (0 sunlit, 1 full discord).
var discord_depth: float = 0.0
## True while the boss is poise-staggered (Stage C's Lydian window).
var stagger_window: bool = false
var boss_phase_two: bool = false
## The zone profile the party is in (the boss suite may be playing over it).
var zone_profile_id: StringName = &""
var last_stinger_id: StringName = &""
var last_stinger_notes: PackedInt32Array = PackedInt32Array()
## The last stinger's stream and the pitch it played at (a baked one is re-pitched to the zone's tonic).
var last_stinger_stream: AudioStream
var last_stinger_pitch: float = 1.0
## True while a local player stands by an oasis (a water-shrine or wind-lantern) in a depth-blend zone.
var oasis: bool = false
## Combat sounds turned away for being too far from everyone.
var culled_count: int = 0

var _silent: bool = false
var _clock: float = 0.0
var _heartbeat_left: float = 0.0
var _decks: Array[AudioStreamPlayer] = []
var _deck_streams: Array[AudioStreamSynchronized] = [null, null]
var _deck_profiles: Array[StringName] = [&"", &""]
var _deck_started_at: Array[float] = [0.0, 0.0]
var _deck_gain: Array[Ramp] = []
## Per deck, one Ramp per stem.
var _stems: Array[Array] = []
var _front: int = 0
var _boss_profile: BossAudioProfileResource
var _calm_for: float = 0.0
## Whether the last heartbeat found a fight round the party.
var _fight_seen: bool = false
var _exhale_left: float = 0.0
var _breath_left: float = 0.0
var _cycle_left: float = 0.0
var _silence_left: float = 0.0
var _silence: Ramp = Ramp.new(0.0)
var _duck: Ramp = Ramp.new(0.0)
var _duck_left: float = 0.0
var _lpf: Ramp = Ramp.new(LPF_OPEN_HZ)
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _voices: Array[AudioStreamPlayer3D] = []
var _voice_free_at: PackedFloat64Array = PackedFloat64Array()
var _next_voice: int = 0
var _last_sfx: Dictionary[StringName, float] = {}
var _sfx_streams: Dictionary[StringName, AudioStreamRandomizer] = {}
var _stinger_voices: Array[AudioStreamPlayer] = []
var _next_stinger: int = 0
## Stingers waiting for their beat: {"at": clock, "id", "stream", "bus", "notes"}.
var _pending: Array[Dictionary] = []
var _stinger_cache: Dictionary[String, AudioStreamWAV] = {}
var _ambience_cache: Dictionary[StringName, AudioStream] = {}
var _emitters: Array[AudioStreamPlayer3D] = []
var _renders: Dictionary[StringName, RenderJob] = {}
var _rendered: Dictionary[StringName, Array] = {}


## A value easing from one level to another over a set time (linear, or a cosine S-curve).
class Ramp:
	var from: float
	var to: float
	var elapsed: float = 0.0
	var duration: float = 0.0
	var cosine: bool = false

	func _init(start: float) -> void:
		from = start
		to = start

	func value() -> float:
		if duration <= 0.0 or elapsed >= duration:
			return to
		var t: float = elapsed / duration
		if cosine:
			t = 0.5 - 0.5 * cos(PI * t)
		return lerpf(from, to, t)

	func retarget(target: float, seconds: float, shaped: bool = false) -> void:
		# Already heading there at least as fast: let it run (a slower ramp to the same level is hurried up).
		if is_equal_approx(target, to) and duration - elapsed <= maxf(seconds, 0.0) + 0.0001:
			return
		from = value()
		to = target
		elapsed = 0.0
		duration = maxf(seconds, 0.0)
		cosine = shaped

	func snap(target: float) -> void:
		from = target
		to = target
		duration = 0.0

	func tick(delta: float) -> void:
		elapsed += delta


## One zone's stems being rendered on a worker thread.
class RenderJob:
	var snap: Dictionary
	var stems: Array[PackedByteArray] = []
	var task_id: int = -1

	func run() -> void:
		stems = ProceduralChamberSynth.render_stems(snap)


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	for job: RenderJob in _renders.values():
		WorkerThreadPool.wait_for_task_completion(job.task_id)
	_renders.clear()
	for deck: AudioStreamPlayer in _decks:
		deck.stop()
		deck.stream = null
	for voice: AudioStreamPlayer3D in _voices:
		voice.stop()
		voice.stream = null
	for voice: AudioStreamPlayer in _stinger_voices:
		voice.stop()
		voice.stream = null
	_deck_streams = [null, null]
	_rendered.clear()
	_stinger_cache.clear()
	_ambience_cache.clear()
	_sfx_streams.clear()
	if current == self:
		current = null


func _ready() -> void:
	_silent = DisplayServer.get_name() == "headless"
	_rng.seed = 16
	_build_buses()
	for index: int in 2:
		var deck: AudioStreamPlayer = AudioStreamPlayer.new()
		deck.name = "Deck%s" % ["A", "B"][index]
		deck.bus = BUS_NAMES[MUSIC_BUS]
		deck.volume_db = MUTED_DB
		add_child(deck)
		_decks.append(deck)
		_deck_gain.append(Ramp.new(MUTED_DB))
		var ramps: Array[Ramp] = []
		for layer: int in ZoneMusicProfileResource.STEM_COUNT:
			ramps.append(Ramp.new(MUTED_DB))
		_stems.append(ramps)
	var pool: Node3D = Node3D.new()
	pool.name = "VoicePool"
	add_child(pool)
	for index: int in VOICE_POOL_SIZE:
		var voice: AudioStreamPlayer3D = _make_3d_player("Voice%02d" % index, BUS_NAMES[SFX_BUS])
		pool.add_child(voice)
		_voices.append(voice)
		_voice_free_at.append(-1.0)
	for index: int in STINGER_VOICES:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.name = "Stinger%d" % index
		add_child(voice)
		_stinger_voices.append(voice)
	CombatDirector.current.synergy_detonated.connect(_on_synergy_detonated)
	InstanceManager.current.instance_changing.connect(_on_instance_changing)
	InstanceManager.current.instance_live.connect(_on_instance_live)
	# Any zone without baked stems renders in the background from the start, so a new zone never waits.
	for profile: ZoneMusicProfileResource in AudioCatalog.zones():
		if not has_baked_stems(profile.profile_id):
			_request_render(profile)


# --- Buses (16 §5.1) ---------------------------------------------------------------

func _build_buses() -> void:
	for index: int in BUS_NAMES.size():
		var at: int = AudioServer.get_bus_index(BUS_NAMES[index])
		if at < 0:
			AudioServer.add_bus()
			at = AudioServer.bus_count - 1
			AudioServer.set_bus_name(at, BUS_NAMES[index])
		if index > 0:
			AudioServer.set_bus_send(at, BUS_NAMES[0])
		AudioServer.set_bus_volume_db(at, BUS_VOLUMES_DB[index])
		while AudioServer.get_bus_effect_count(at) > 0:
			AudioServer.remove_bus_effect(at, 0)
	var master_limit: AudioEffectHardLimiter = AudioEffectHardLimiter.new()
	master_limit.ceiling_db = -0.5
	AudioServer.add_bus_effect(_bus(0), master_limit)
	var low_pass: AudioEffectLowPassFilter = AudioEffectLowPassFilter.new()
	low_pass.cutoff_hz = LPF_OPEN_HZ
	low_pass.resonance = 0.5
	AudioServer.add_bus_effect(_bus(MUSIC_BUS), low_pass)
	var warmth: AudioEffectEQ6 = AudioEffectEQ6.new()
	# Bands: 32, 100, 320, 1000, 3200 and 10000 Hz: warmth for the bassoon and cello, room at 3.2 kHz for combat.
	warmth.set_band_gain_db(2, WARMTH_DB)
	warmth.set_band_gain_db(4, CARVE_DB)
	AudioServer.add_bus_effect(_bus(MUSIC_BUS), warmth)
	AudioServer.add_bus_effect(_bus(MUSIC_BUS), _hall(MUSIC_HALL))
	var squeeze: AudioEffectCompressor = AudioEffectCompressor.new()
	squeeze.ratio = 4.0
	squeeze.threshold = -18.0
	squeeze.attack_us = 15000.0
	squeeze.release_ms = 450.0
	squeeze.sidechain = BUS_NAMES[SIGN_BUS]
	AudioServer.add_bus_effect(_bus(MUSIC_BUS), squeeze)
	var ambience_pass: AudioEffectLowPassFilter = AudioEffectLowPassFilter.new()
	ambience_pass.cutoff_hz = LPF_OPEN_HZ
	AudioServer.add_bus_effect(_bus(AMBIENCE_BUS), ambience_pass)
	AudioServer.add_bus_effect(_bus(SIGN_BUS), _hall(SIGN_HALL))
	var sfx_limit: AudioEffectHardLimiter = AudioEffectHardLimiter.new()
	sfx_limit.ceiling_db = -1.5
	AudioServer.add_bus_effect(_bus(SFX_BUS), sfx_limit)


func _bus(index: int) -> int:
	return AudioServer.get_bus_index(BUS_NAMES[index])


## The warm wooden chamber hall: [room size, damping, spread, wet].
static func _hall(settings: Array[float]) -> AudioEffectReverb:
	var hall: AudioEffectReverb = AudioEffectReverb.new()
	hall.room_size = settings[0]
	hall.damping = settings[1]
	hall.spread = settings[2]
	hall.wet = settings[3]
	hall.dry = 1.0
	return hall


# --- Each frame -----------------------------------------------------------------

func _process(delta: float) -> void:
	_clock += delta
	_poll_renders()
	_heartbeat_left -= delta
	if _heartbeat_left <= 0.0:
		_heartbeat_left = HEARTBEAT
		_evaluate()
	_tick_stages(delta)
	_apply_volumes(delta)
	_fire_pending()


func _apply_volumes(delta: float) -> void:
	_silence.tick(delta)
	for deck: int in 2:
		var gain: Ramp = _deck_gain[deck]
		gain.tick(delta)
		_decks[deck].volume_db = maxf(MUTED_DB, gain.value() + _silence.value())
		var sync: AudioStreamSynchronized = _deck_streams[deck]
		for layer: int in ZoneMusicProfileResource.STEM_COUNT:
			var ramp: Ramp = _stems[deck][layer]
			ramp.tick(delta)
			if sync != null:
				sync.set_sync_stream_volume(layer, ramp.value())
	_duck_left = maxf(0.0, _duck_left - delta)
	if _duck_left == 0.0:
		_duck.retarget(0.0, DUCK_RELEASE_SEC)
	_duck.tick(delta)
	AudioServer.set_bus_volume_db(_bus(MUSIC_BUS), BUS_VOLUMES_DB[MUSIC_BUS] + _duck.value())
	_lpf.tick(delta)
	for bus: int in [MUSIC_BUS, AMBIENCE_BUS]:
		var filter: AudioEffectLowPassFilter = AudioServer.get_bus_effect(_bus(bus), 0) as AudioEffectLowPassFilter
		if filter != null:
			filter.cutoff_hz = _lpf.value()


# --- The party state (16 §5.2) ------------------------------------------------------

## Re-reads the party's place and threat now (the heartbeat does this every 0.4 s).
func evaluate_now() -> void:
	_heartbeat_left = HEARTBEAT
	_evaluate()


func _evaluate() -> void:
	var level: LevelBase = get_tree().current_scene as LevelBase
	if level == null or CombatDirector.current == null:
		return
	var locals: Array[ActorBase] = _local_players()
	if locals.is_empty():
		return
	_resolve_zone(level, locals)
	# The threat round the party: local players and the teammates near them.
	var listeners: Array[Vector3] = []
	for member: ActorBase in CombatDirector.current.party_actors():
		if locals.has(member) or _nearest(member.global_position, locals) <= ENGAGE_RADIUS:
			listeners.append(member.global_position)
	var nearest_awake: float = INF
	var engaged: bool = false
	var boss: ActorBase = null
	for foe: ActorBase in CombatDirector.current.enemies():
		if foe.is_beaten() or (foe.spectrum != null and foe.spectrum.equilibrium == HobSpectrumComponent.EquilibriumState.HOB_BENIGN):
			continue
		var distance: float = INF
		for point: Vector3 in listeners:
			distance = minf(distance, point.distance_to(foe.global_position))
		if foe.is_raid_boss() and foe.is_engaged() and distance <= BOSS_RADIUS:
			boss = foe
		elif foe.is_engaged() and distance <= ENGAGE_RADIUS:
			engaged = true
		nearest_awake = minf(nearest_awake, distance)
	proximity = clampf((PREWARM_OUTER - nearest_awake) / (PREWARM_OUTER - PREWARM_INNER), 0.0, 1.0)
	_fight_seen = boss != null or engaged
	if boss != null:
		_calm_for = 0.0
		_enter_boss(boss)
	elif engaged:
		_calm_for = 0.0
		if state != AcousticState.SKIRMISH:
			_enter_skirmish()
	elif state == AcousticState.SKIRMISH or state == AcousticState.BOSS:
		pass # the hysteresis hold runs in _tick_stages
	elif state == AcousticState.EXHALE:
		pass
	elif proximity > 0.0:
		_set_state(AcousticState.PROXIMITY)
	else:
		_set_state(AcousticState.EXPLORATION)
	_play_wanted_deck()
	_retarget_stems()


## The zone most local players stand in (ties: the one furthest up the trail), and its depth blend.
func _resolve_zone(level: LevelBase, locals: Array[ActorBase]) -> void:
	var counts: Dictionary[StringName, int] = {}
	var deepest: Dictionary[StringName, float] = {}
	for player: ActorBase in locals:
		var id: StringName = level.music_profile_at(player.global_position)
		if id == &"" or AudioCatalog.zone(id) == null:
			continue
		counts[id] = counts.get(id, 0) + 1
		deepest[id] = minf(deepest.get(id, INF), level.music_world_z(player.global_position))
	var chosen: StringName = &""
	for id: StringName in counts:
		if chosen == &"" or counts[id] > counts[chosen] or (counts[id] == counts[chosen] and deepest[id] < deepest[chosen]):
			chosen = id
	if chosen == &"":
		return
	if chosen != zone_profile_id:
		var arriving: bool = zone_profile_id != &""
		zone_profile_id = chosen
		_cycle_left = AudioCatalog.zone(chosen).music_cycle_sec
		if arriving and AudioCatalog.zone(chosen).sanctuary_cadence_on_arrival:
			_queue_cadence(&"sanctuary_cadence", SANCTUARY_CADENCE)
	var profile: ZoneMusicProfileResource = AudioCatalog.zone(chosen)
	discord_depth = 0.0
	var was_oasis: bool = oasis
	oasis = false
	if profile.enable_z_depth_discord_blend:
		var total: float = 0.0
		var inside: int = 0
		for player: ActorBase in locals:
			if level.music_profile_at(player.global_position) == chosen:
				total += level.music_world_z(player.global_position)
				inside += 1
		var mean: float = total / maxi(1, inside)
		discord_depth = clampf((mean - profile.discord_blend_z_start) / (profile.discord_blend_z_full - profile.discord_blend_z_start), 0.0, 1.0)
		# A Miyazaki oasis: by a water-shrine or a wind-lantern the hush drops 12 dB under a harp glissando.
		for node: Node in get_tree().get_nodes_in_group(OASIS_GROUP):
			var spot: Node3D = node as Node3D
			if spot != null and spot.is_inside_tree() and _nearest(spot.global_position, locals) <= OASIS_RADIUS:
				oasis = true
				break
	if oasis and not was_oasis:
		# A two-octave Lydian glissando in the zone's key (E Lydian in Moss-Oak-Hollow).
		var shift: int = key_semitones(profile.root_pitch_midi, BAKED_TONIC)
		var notes: PackedInt32Array = PackedInt32Array()
		for step: int in [0, 2, 4, 6, 7, 9, 11]:
			notes.append(BAKED_TONIC + shift + step)
		var glissando: Array = _acoustic_stinger(&"oasis_glissando", profile.root_pitch_midi)
		var stream: AudioStream = glissando[0] if glissando[0] != null else _cached_chord("oasis:%d" % notes[0], notes, 0.06, 1.6,
			ProceduralChamberSynth.Timbre.HARP)
		_play_now(&"oasis_glissando", stream, SIGN_BUS, notes, float(glissando[1]))


func _local_players() -> Array[ActorBase]:
	var locals: Array[ActorBase] = []
	for member: ActorBase in CombatDirector.current.party_actors():
		if member.is_local_player() and not member.is_companion:
			locals.append(member)
	return locals


static func _nearest(at: Vector3, actors: Array[ActorBase]) -> float:
	var best: float = INF
	for actor: ActorBase in actors:
		best = minf(best, actor.global_position.distance_to(at))
	return best


# --- The four stages (16 §5.3) ----------------------------------------------------

func _enter_skirmish() -> void:
	_set_state(AcousticState.SKIRMISH)
	_exhale_left = 0.0
	_breath_left = 0.0
	_cancel_silence()
	# The accent lands on the next eighth note of the playing deck.
	var profile: ZoneMusicProfileResource = _front_profile()
	if profile != null:
		var notes: PackedInt32Array = PackedInt32Array()
		var events: Array[Array] = []
		events.append([0.0, 0.0, 0.2, ProceduralChamberSynth.Timbre.DRUM, 1.0])
		for index: int in SKIRMISH_ACCENT_SEMITONES.size():
			var note: int = profile.root_pitch_midi - 12 + SKIRMISH_ACCENT_SEMITONES[index]
			notes.append(note)
			events.append([0.02 + index * 0.03, note, 0.3, ProceduralChamberSynth.Timbre.DULCIMER, 0.6])
		var accent: Array = _acoustic_stinger(&"skirmish_accent", profile.root_pitch_midi)
		var stream: AudioStream = accent[0] if accent[0] != null else _cached_phrase("skirmish:%d" % profile.root_pitch_midi, events)
		_queue(&"skirmish_accent", stream, MUSIC_BUS, notes, _next_subdivision(0.5), float(accent[1]))


func _enter_boss(boss: ActorBase) -> void:
	_boss_profile = AudioCatalog.boss(boss.glimmer_encounter_id())
	if _boss_profile == null:
		_boss_profile = AudioCatalog.boss(ArsenalCatalog.CAIRNSMAN)
	if state != AcousticState.BOSS:
		_set_state(AcousticState.BOSS)
		_exhale_left = 0.0
		_breath_left = 0.0
		_cancel_silence()
	var staggered: bool = boss.stats.is_knocked_down()
	boss_phase_two = boss.stats.health_ratio() < _boss_profile.phase_two_health_ratio
	if staggered and not stagger_window:
		var suite: ZoneMusicProfileResource = AudioCatalog.zone(_boss_profile.suite_profile_id)
		var root: int = suite.root_pitch_midi if suite != null else 62
		var notes: PackedInt32Array = PackedInt32Array()
		for interval: int in _boss_profile.stagger_flourish_intervals:
			notes.append(root + interval)
		# The acoustic flourish (harp, musette accordion and carillon, baked in the suite's key), else a modelled harp.
		var path: String = _boss_profile.stagger_stinger_path
		var stream: AudioStream = load(path) as AudioStream if path != "" and ResourceLoader.exists(path) else null
		if stream == null:
			stream = _cached_chord("stagger:%d" % root, notes, 0.045, 1.6, ProceduralChamberSynth.Timbre.HARP)
		_play_now(&"poise_stagger_flourish", stream, SIGN_BUS, notes)
	stagger_window = staggered


func _tick_stages(delta: float) -> void:
	match state:
		AcousticState.SKIRMISH, AcousticState.BOSS:
			if not _fight_seen:
				_calm_for += delta
				if _calm_for >= HYSTERESIS_HOLD:
					_enter_exhale()
		AcousticState.EXHALE:
			if _exhale_left > 0.0:
				_exhale_left = maxf(0.0, _exhale_left - delta)
				if _exhale_left == 0.0:
					_breath_left = ZoneMusicProfileResource.POST_COMBAT_SILENCE_SEC
					_retarget_stems()
			elif _breath_left > 0.0:
				_breath_left = maxf(0.0, _breath_left - delta)
				if _breath_left == 0.0:
					_set_state(AcousticState.EXPLORATION)
					_retarget_stems()
		AcousticState.EXPLORATION:
			_tick_silence(delta)


func _enter_exhale() -> void:
	_set_state(AcousticState.EXHALE)
	_calm_for = 0.0
	stagger_window = false
	boss_phase_two = false
	_exhale_left = ZoneMusicProfileResource.RESTORATION_EXHALE_SEC
	_breath_left = 0.0
	_queue_cadence(&"restoration_exhale", EXHALE_CADENCE)
	_play_wanted_deck()
	_retarget_stems()


## The Brower silence breath between music cycles, out of a fight.
func _tick_silence(delta: float) -> void:
	var profile: ZoneMusicProfileResource = _front_profile()
	if profile == null:
		return
	if _silence_left > 0.0:
		_silence_left = maxf(0.0, _silence_left - delta)
		if _silence_left == 0.0:
			_silence.retarget(0.0, SILENCE_FADE_SEC)
			_cycle_left = profile.music_cycle_sec
		return
	_cycle_left -= delta
	if _cycle_left <= 0.0:
		var span: Vector2 = profile.silence_interval_range_sec
		_silence_left = _rng.randf_range(span.x, span.y)
		_silence.retarget(MUTED_DB, SILENCE_FADE_SEC)


func _cancel_silence() -> void:
	_silence_left = 0.0
	_silence.retarget(0.0, HEARTBEAT)
	var profile: ZoneMusicProfileResource = _front_profile()
	_cycle_left = profile.music_cycle_sec if profile != null else 90.0


func _set_state(next: AcousticState) -> void:
	if next == state:
		return
	state = next
	if next != AcousticState.BOSS:
		stagger_window = false
	state_changed.emit(next)


## The stems' target volumes for the state (16 §5.3's table), on the front deck.
func _retarget_stems() -> void:
	var profile: ZoneMusicProfileResource = _front_profile()
	if profile == null:
		return
	var targets: PackedFloat32Array = PackedFloat32Array()
	for layer: int in ZoneMusicProfileResource.STEM_COUNT:
		targets.append(profile.explore_db(layer))
	var seconds: float = STATE_RAMP_SEC
	var shaped: bool = false
	match state:
		AcousticState.EXPLORATION, AcousticState.PROXIMITY:
			if discord_depth > 0.0:
				targets[1] = maxf(MUTED_DB, profile.explore_db(1) + linear_to_db(cos(discord_depth * PI * 0.5)))
				targets[2] = maxf(MUTED_DB, linear_to_db(sin(discord_depth * PI * 0.5)))
			if state == AcousticState.PROXIMITY:
				targets[1] += PREWARM_LEAD_DIP_DB * proximity
				targets[2] = maxf(targets[2], maxf(MUTED_DB, PREWARM_DISCORD_DB + linear_to_db(sin(proximity * PI * 0.5))))
				seconds = HEARTBEAT
			if oasis:
				targets[2] = maxf(MUTED_DB, targets[2] + OASIS_DISCORD_DB)
		AcousticState.SKIRMISH:
			for layer: int in ZoneMusicProfileResource.STEM_COUNT:
				targets[layer] = SKIRMISH_DB[layer] if layer > 0 else profile.explore_db(0)
			seconds = ZoneMusicProfileResource.SKIRMISH_ATTACK_SEC
		AcousticState.BOSS:
			if boss_phase_two:
				targets[2] = 0.0
			if stagger_window:
				targets[1] = 0.0
				targets[2] = maxf(MUTED_DB, targets[2] + (_boss_profile.stagger_discord_duck_db if _boss_profile != null else -18.0))
				targets[3] = profile.explore_db(3) + (_boss_profile.stagger_percussion_duck_db if _boss_profile != null else -14.0)
			seconds = STAGGER_RAMP_SEC if stagger_window else STATE_RAMP_SEC
		AcousticState.EXHALE:
			if _exhale_left > 0.0:
				targets[2] = MUTED_DB
				targets[3] = MUTED_DB
				seconds = ZoneMusicProfileResource.RESTORATION_EXHALE_SEC
				shaped = true
			else:
				targets[0] = BREATH_DB
				targets[1] = BREATH_DB
				targets[2] = MUTED_DB
				targets[3] = MUTED_DB
	if state == AcousticState.EXPLORATION and _was_breathing():
		seconds = EXPLORE_RETURN_SEC
	for layer: int in ZoneMusicProfileResource.STEM_COUNT:
		(_stems[_front][layer] as Ramp).retarget(targets[layer], seconds, shaped)


func _was_breathing() -> bool:
	return (_stems[_front][0] as Ramp).to <= BREATH_DB + 0.1


# --- Decks (16 §1.3, §5.1) ---------------------------------------------------------

## Puts the wanted profile on the front deck: the boss suite in a boss fight, else the zone.
func _play_wanted_deck() -> void:
	var wanted: StringName = zone_profile_id
	var crossfade: float = ZONE_CROSSFADE_SEC
	if state == AcousticState.BOSS and _boss_profile != null:
		wanted = _boss_profile.suite_profile_id
		var suite: ZoneMusicProfileResource = AudioCatalog.zone(wanted)
		crossfade = _boss_profile.crossfade_beats * (suite.beat_sec() if suite != null else 0.45)
	elif state == AcousticState.EXHALE and _deck_profiles[_front] != zone_profile_id:
		crossfade = ZoneMusicProfileResource.RESTORATION_EXHALE_SEC
	if wanted == &"" or wanted == _deck_profiles[_front]:
		return
	var sync: AudioStreamSynchronized = _stream_for(AudioCatalog.zone(wanted))
	if sync == null:
		return
	var back: int = 1 - _front
	var old_profile: ZoneMusicProfileResource = _front_profile()
	_deck_streams[back] = sync
	_deck_profiles[back] = wanted
	var deck: AudioStreamPlayer = _decks[back]
	deck.stop()
	deck.stream = sync
	var profile: ZoneMusicProfileResource = AudioCatalog.zone(wanted)
	# Same tempo: start in step with the deck already playing (phase-locked across zones).
	var offset: float = 0.0
	if old_profile != null and is_equal_approx(old_profile.bpm, profile.bpm) and _deck_profiles[_front] != &"":
		var loop: float = sync.get_length() if sync.get_length() > 0.0 else profile.loop_sec()
		offset = fposmod(_clock - _deck_started_at[_front], loop)
	_deck_started_at[back] = _clock - offset
	for layer: int in ZoneMusicProfileResource.STEM_COUNT:
		(_stems[back][layer] as Ramp).snap(profile.explore_db(layer))
		sync.set_sync_stream_volume(layer, profile.explore_db(layer))
	if not _silent:
		deck.play(offset)
	var first: bool = _deck_profiles[_front] == &""
	(_deck_gain[back] as Ramp).retarget(0.0, 0.0 if first else crossfade)
	(_deck_gain[_front] as Ramp).retarget(MUTED_DB, crossfade)
	_front = back
	_cycle_left = profile.music_cycle_sec
	profile_changed.emit(wanted)


## A four-stem AudioStreamSynchronized for a profile: its curated or baked .tres, else one built
## from its four baked .ogg stems, else its code-built stems (null while they're still rendering).
func _stream_for(profile: ZoneMusicProfileResource) -> AudioStreamSynchronized:
	if profile == null:
		return null
	for path: String in [profile.synchronized_stream_path, sync_path(profile.profile_id)]:
		if path != "" and ResourceLoader.exists(path):
			var curated: AudioStreamSynchronized = load(path) as AudioStreamSynchronized
			if curated != null:
				return curated.duplicate() as AudioStreamSynchronized
	var stems: Array[AudioStream] = baked_stems(profile.profile_id)
	if stems.is_empty():
		if not _rendered.has(profile.profile_id):
			_request_render(profile)
			return null
		stems.assign(_rendered[profile.profile_id])
	var sync: AudioStreamSynchronized = AudioStreamSynchronized.new()
	sync.stream_count = ZoneMusicProfileResource.STEM_COUNT
	for layer: int in ZoneMusicProfileResource.STEM_COUNT:
		sync.set_sync_stream(layer, stems[layer])
		sync.set_sync_stream_volume(layer, MUTED_DB)
	return sync


## Where a zone's baked AudioStreamSynchronized lives (tools/build_audio_resources.gd writes it).
static func sync_path(profile_id: StringName) -> String:
	return MUSIC_FOLDER + "%s_sync.tres" % profile_id


## A zone's four baked acoustic stems, in layer order (empty unless all four are there).
static func baked_stems(profile_id: StringName) -> Array[AudioStream]:
	var stems: Array[AudioStream] = []
	for file: String in STEM_FILES:
		var path: String = MUSIC_FOLDER + "%s/%s" % [profile_id, file]
		var stream: AudioStream = load(path) as AudioStream if ResourceLoader.exists(path) else null
		if stream == null:
			return []
		stems.append(stream)
	return stems


static func has_baked_stems(profile_id: StringName) -> bool:
	for file: String in STEM_FILES:
		if not ResourceLoader.exists(MUSIC_FOLDER + "%s/%s" % [profile_id, file]):
			return false
	return true


## A baked acoustic one-shot or loop in ProceduralChamberSynth.SAMPLES_FOLDER (null when it isn't there).
static func acoustic(file: String) -> AudioStream:
	var path: String = ProceduralChamberSynth.SAMPLES_FOLDER + file
	return load(path) as AudioStream if ResourceLoader.exists(path) else null


## Semitones from `baked` to `root` the nearer way (-6 to +5): how far a baked stinger moves.
static func key_semitones(root: int, baked: int) -> int:
	return posmod(root - baked + 6, 12) - 6


## The playback rate that puts a stinger baked over `baked` into the key of `root`.
static func key_shift(root: int, baked: int) -> float:
	return pow(2.0, key_semitones(root, baked) / 12.0)


## A baked stinger by id (STINGER_FILES) and the rate that puts it in the key of `root`: [stream or null, pitch].
func _acoustic_stinger(id: StringName, root: int) -> Array:
	if not STINGER_FILES.has(id):
		return [null, 1.0]
	var entry: Array = STINGER_FILES[id]
	var baked: int = int(entry[1])
	return [acoustic(String(entry[0])), key_shift(root, baked) if baked > 0 else 1.0]


func _request_render(profile: ZoneMusicProfileResource) -> void:
	if _rendered.has(profile.profile_id) or _renders.has(profile.profile_id):
		return
	var job: RenderJob = RenderJob.new()
	job.snap = ProceduralChamberSynth.snapshot(profile)
	job.task_id = WorkerThreadPool.add_task(job.run, false, "Render %s stems" % profile.profile_id)
	_renders[profile.profile_id] = job


func _poll_renders() -> void:
	for id: StringName in _renders.keys():
		var job: RenderJob = _renders[id]
		if not WorkerThreadPool.is_task_completed(job.task_id):
			continue
		WorkerThreadPool.wait_for_task_completion(job.task_id)
		_renders.erase(id)
		var streams: Array[AudioStream] = []
		for pcm: PackedByteArray in job.stems:
			streams.append(ProceduralChamberSynth.loop_stream(pcm))
		_rendered[id] = streams


## Waits for every zone's stems to finish rendering (tests, and loading screens).
func wait_for_renders() -> void:
	for job: RenderJob in _renders.values():
		WorkerThreadPool.wait_for_task_completion(job.task_id)
	_poll_renders()


func _front_profile() -> ZoneMusicProfileResource:
	return AudioCatalog.zone(_deck_profiles[_front]) if _deck_profiles[_front] != &"" else null


## Seconds from now to the next `fraction` of a beat on the playing deck (0.5: the next eighth).
func _next_subdivision(fraction: float) -> float:
	var profile: ZoneMusicProfileResource = _front_profile()
	if profile == null:
		return 0.0
	var step: float = profile.beat_sec() * fraction
	var played: float = _clock - _deck_started_at[_front]
	return ceilf(played / step - 0.0001) * step - played


# --- Stingers (16 §3, §4.1, §5.3) -------------------------------------------------

func _on_synergy_detonated(_target: ActorBase, primer: int, _cross_class: bool, _label: String) -> void:
	play_sign_stinger(primer)


## A Four-Sign detonation: its acoustic chord (baked in G, re-pitched to the zone's tonic) on
## SignTelegraphs, and the Music bus ducks under it.
func play_sign_stinger(scribe_sign: int) -> void:
	var profile: SignHarmonicProfileResource = AudioCatalog.sign_profile(scribe_sign)
	if profile == null:
		return
	var zone: ZoneMusicProfileResource = _front_profile()
	var root: int = zone.root_pitch_midi if zone != null else BAKED_TONIC
	var notes: PackedInt32Array = profile.notes_over(root)
	var stream: AudioStream = null
	var pitch: float = 1.0
	for path: String in [profile.custom_stinger_path, ProceduralChamberSynth.SAMPLES_FOLDER + String(profile.sign_id).to_lower() + ".wav"]:
		if path != "" and ResourceLoader.exists(path):
			stream = load(path) as AudioStream
			if stream != null:
				pitch = key_shift(root, BAKED_TONIC)
				break
	if stream == null:
		var events: Array[Array] = []
		var timbre: ProceduralChamberSynth.Timbre = timbre_for(profile.instrument_timbre)
		for index: int in notes.size():
			events.append([profile.arpeggio_step_sec * index, notes[index], 0.9, timbre, 0.7])
		# Every Sign rings out on a chime an octave over its top note.
		events.append([profile.arpeggio_step_sec * notes.size(), notes[notes.size() - 1] + 12, 1.1, ProceduralChamberSynth.Timbre.BELL, 0.45])
		stream = _cached_phrase("%s:%d" % [profile.sign_id, root], events)
	_play_now(StringName(profile.sign_id), stream, SIGN_BUS, notes, pitch)
	_duck.retarget(profile.sidechain_duck_db, DUCK_ATTACK_SEC)
	_duck_left = profile.sidechain_duration_sec


## A Calling's posture motif over the zone's tonic (a hero taking up a Calling), played on the
## baked acoustic samples by ProceduralChamberSynth.
func play_calling_motif(calling_id: StringName) -> void:
	var profile: CallingAudioProfileResource = AudioCatalog.calling(calling_id)
	if profile == null:
		return
	var zone: ZoneMusicProfileResource = _front_profile()
	var root: int = (zone.root_pitch_midi if zone != null else BAKED_TONIC) + profile.octave_shift * 12
	var notes: PackedInt32Array = PackedInt32Array()
	for interval: int in profile.posture_motif_intervals:
		notes.append(root + interval)
	_play_now(StringName("calling_%s" % profile.calling_id),
		_cached_chord("calling:%s:%d" % [profile.calling_id, root], notes, 0.09, 0.8, timbre_for(profile.lead_instrument)), MUSIC_BUS, notes)


## A named chord stinger on the Music or SignTelegraphs bus (the Co-Op Gate's fanfare): its baked
## recording if there is one, else the chord on a modelled voice.
func play_chord_stinger(id: StringName, notes: PackedInt32Array, step: float, timbre_name: StringName, on_sign_bus: bool = false) -> void:
	var baked: Array = _acoustic_stinger(id, BAKED_TONIC)
	var stream: AudioStream = baked[0] if baked[0] != null else _cached_chord("%s:%s" % [id, str(notes)], notes, step, 1.4, timbre_for(timbre_name))
	_play_now(id, stream, SIGN_BUS if on_sign_bus else MUSIC_BUS, notes, float(baked[1]))


## The code-built voice for a profile's instrument name (its first word that names one).
static func timbre_for(instrument: StringName) -> ProceduralChamberSynth.Timbre:
	for word: String in String(instrument).split("_"):
		if TIMBRE_WORDS.has(word):
			return TIMBRE_WORDS[word]
	return ProceduralChamberSynth.Timbre.HARP


## A cadence on the next bar line of the playing deck: its baked recording re-pitched to the
## zone's tonic, else `chords` on a modelled harp and accordion.
func _queue_cadence(id: StringName, chords: Array[Array]) -> void:
	var profile: ZoneMusicProfileResource = _front_profile()
	var beat: float = profile.beat_sec() if profile != null else 0.55
	var root: int = profile.root_pitch_midi if profile != null else BAKED_TONIC
	var baked: Array = _acoustic_stinger(id, root)
	var shift: int = key_semitones(root, BAKED_TONIC) if baked[0] != null and int(STINGER_FILES[id][1]) > 0 else 0
	var events: Array[Array] = []
	var notes: PackedInt32Array = PackedInt32Array()
	for chord: int in chords.size():
		var tones: Array = chords[chord]
		for tone: int in tones.size():
			var note: int = int(tones[tone])
			notes.append(note + shift)
			var timbre: ProceduralChamberSynth.Timbre = ProceduralChamberSynth.Timbre.HARP if tone > 0 else ProceduralChamberSynth.Timbre.ACCORDION
			events.append([chord * beat + tone * 0.03, note, beat * (2.0 if chord == chords.size() - 1 else 1.1), timbre, 0.5])
	var stream: AudioStream = baked[0] if baked[0] != null else _cached_phrase("%s:%d" % [id, int(beat * 1000.0)], events)
	var bar_wait: float = _next_subdivision(float(profile.beats_per_bar)) if profile != null else 0.0
	_queue(id, stream, MUSIC_BUS, notes, bar_wait, float(baked[1]))


func _queue(id: StringName, stream: AudioStream, bus: int, notes: PackedInt32Array, wait: float, pitch: float = 1.0) -> void:
	_pending.append({"at": _clock + wait, "id": id, "stream": stream, "bus": bus, "notes": notes, "pitch": pitch})


func _is_pending(id: StringName) -> bool:
	for item: Dictionary in _pending:
		if item["id"] == id:
			return true
	return false


func _fire_pending() -> void:
	var index: int = 0
	while index < _pending.size():
		var item: Dictionary = _pending[index]
		if _clock >= float(item["at"]):
			_pending.remove_at(index)
			_play_now(item["id"], item["stream"], int(item["bus"]), item["notes"], float(item["pitch"]))
		else:
			index += 1


func _play_now(id: StringName, stream: AudioStream, bus: int, notes: PackedInt32Array, pitch: float = 1.0) -> void:
	var voice: AudioStreamPlayer = _stinger_voices[_next_stinger]
	_next_stinger = (_next_stinger + 1) % _stinger_voices.size()
	voice.stop()
	voice.stream = stream
	voice.bus = BUS_NAMES[bus]
	voice.pitch_scale = pitch
	if not _silent:
		voice.play()
	last_stinger_id = id
	last_stinger_notes = notes
	last_stinger_stream = stream
	last_stinger_pitch = pitch
	stinger_played.emit(id, notes)


func _cached_phrase(key: String, events: Array[Array]) -> AudioStreamWAV:
	if not _stinger_cache.has(key):
		_stinger_cache[key] = ProceduralChamberSynth.render_phrase(events)
	return _stinger_cache[key]


func _cached_chord(key: String, notes: PackedInt32Array, step: float, ring: float, timbre: ProceduralChamberSynth.Timbre) -> AudioStreamWAV:
	if not _stinger_cache.has(key):
		_stinger_cache[key] = ProceduralChamberSynth.render_chord(notes, step, ring, timbre, 0.6)
	return _stinger_cache[key]


# --- Portals (16 §3.2) -------------------------------------------------------------

func _on_instance_changing(_instance_id: StringName) -> void:
	_lpf.retarget(LPF_PORTAL_HZ, PORTAL_SWEEP_SEC)
	var notes: PackedInt32Array = PackedInt32Array(THRESHOLD_CHORD)
	var baked: Array = _acoustic_stinger(&"wayfarers_threshold", BAKED_TONIC)
	var stream: AudioStream = baked[0] if baked[0] != null else _cached_chord("threshold", notes, 0.06, 2.4, ProceduralChamberSynth.Timbre.BELL)
	_play_now(&"wayfarers_threshold", stream, MUSIC_BUS, notes)
	_set_state(AcousticState.EXPLORATION)
	_calm_for = 0.0
	_exhale_left = 0.0
	_breath_left = 0.0


func _on_instance_live(instance_id: StringName) -> void:
	_lpf.retarget(LPF_OPEN_HZ, PORTAL_SWEEP_SEC)
	evaluate_now()
	# Home again through a portal (the gold portal after a raid): the Sanctuary Cadence, "coming home".
	var instances: InstanceManager = InstanceManager.current
	if instances != null and instance_id == instances.home_instance and instances.previous_instance != &"" \
			and instances.previous_instance != instance_id and not _is_pending(&"sanctuary_cadence"):
		_queue_cadence(&"sanctuary_cadence", SANCTUARY_CADENCE)


# --- The 3D voice pool (16 §1.2, §6.2) ---------------------------------------------

## Plays a combat sound at a spot through the 32-voice pool. False when it was
## culled (beyond 45 m of every local player) or its kind played under 50 ms ago.
func play_sfx_3d(cue: StringName, at: Vector3, stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> bool:
	var locals: Array[ActorBase] = _local_players() if CombatDirector.current != null else []
	if locals.is_empty() or _nearest(at, locals) > CULL_DISTANCE:
		culled_count += 1
		return false
	if _last_sfx.has(cue) and _clock - _last_sfx[cue] < SFX_COOLDOWN:
		return false
	_last_sfx[cue] = _clock
	var index: int = _next_voice
	_next_voice = (_next_voice + 1) % _voices.size()
	var voice: AudioStreamPlayer3D = _voices[index]
	voice.stop()
	voice.global_position = at
	voice.stream = _randomized(cue, stream)
	voice.volume_db = volume_db
	voice.pitch_scale = clampf(pitch, 0.25, 4.0)
	_voice_free_at[index] = _clock + (stream.get_length() if stream != null else 0.5) / voice.pitch_scale
	if not _silent:
		voice.play()
	return true


func get_voice_pool_size() -> int:
	return _voices.size()


## Voices still sounding (at most VOICE_POOL_SIZE: the ring reuses the oldest).
func active_voice_count() -> int:
	var count: int = 0
	for free_at: float in _voice_free_at:
		if free_at > _clock:
			count += 1
	return count


func voice_pool() -> Array[AudioStreamPlayer3D]:
	return _voices.duplicate()


func _randomized(cue: StringName, stream: AudioStream) -> AudioStreamRandomizer:
	var shuffled: AudioStreamRandomizer = _sfx_streams.get(cue, null)
	if shuffled == null or (stream != null and (shuffled.streams_count == 0 or shuffled.get_stream(0) != stream)):
		shuffled = AudioStreamRandomizer.new()
		shuffled.random_pitch = SFX_PITCH_SPREAD
		shuffled.random_volume_offset_db = SFX_GAIN_SPREAD_DB
		if stream != null:
			shuffled.add_stream(-1, stream)
		_sfx_streams[cue] = shuffled
	return shuffled


func _make_3d_player(label: String, bus: StringName) -> AudioStreamPlayer3D:
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.name = label
	player.bus = bus
	player.area_mask = 1
	player.unit_size = UNIT_SIZE
	player.max_db = MAX_DB
	player.max_distance = MAX_DISTANCE
	player.attenuation_filter_cutoff_hz = FAR_FILTER_HZ
	player.attenuation_filter_db = FAR_FILTER_DB
	return player


# --- Station ambience (16 §4) --------------------------------------------------------

## A looping ambience emitter on a station (the campfire, a water-shrine, the
## Chime-Shrine, the Co-Op Gate's plate harmonies), on Ambience3D with area_mask = 1.
static func attach_ambience(host: Node3D, kind: StringName, offset: Vector3 = Vector3.ZERO, volume_db: float = 0.0) -> AudioStreamPlayer3D:
	var director: AudioDirector = current
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.name = "Ambience_%s" % kind
	player.bus = BUS_NAMES[AMBIENCE_BUS]
	player.area_mask = 1
	player.unit_size = UNIT_SIZE
	player.max_db = MAX_DB
	player.max_distance = MAX_DISTANCE
	player.attenuation_filter_cutoff_hz = FAR_FILTER_HZ
	player.attenuation_filter_db = FAR_FILTER_DB
	player.position = offset
	player.volume_db = volume_db
	player.stream = director.ambience_stream(kind) if director != null else ProceduralChamberSynth.render_ambience(kind)
	player.autoplay = director != null and not director._silent
	host.add_child(player)
	if director != null:
		director._emitters.append(player)
	return player


## A station's loop: its baked recording (assets/audio/samples/ambience_<kind>.ogg) if there is
## one, else ProceduralChamberSynth's.
func ambience_stream(kind: StringName) -> AudioStream:
	if not _ambience_cache.has(kind):
		var baked: AudioStream = acoustic("ambience_%s.ogg" % kind)
		_ambience_cache[kind] = baked if baked != null else ProceduralChamberSynth.render_ambience(kind)
	return _ambience_cache[kind]


## Every live ambience emitter the stations have made.
func ambience_emitters() -> Array[AudioStreamPlayer3D]:
	var live: Array[AudioStreamPlayer3D] = []
	for emitter: AudioStreamPlayer3D in _emitters:
		if is_instance_valid(emitter) and emitter.is_inside_tree():
			live.append(emitter)
	_emitters = live.duplicate()
	return live


# --- What tests and HUDs read -------------------------------------------------------

func get_active_profile_id() -> StringName:
	return _deck_profiles[_front]


## A stem's volume on the playing deck right now (dB), as the AudioStreamSynchronized holds it.
func get_stem_volume_db(layer: int) -> float:
	var sync: AudioStreamSynchronized = _deck_streams[_front]
	return sync.get_sync_stream_volume(layer) if sync != null else MUTED_DB


## Where a stem on the playing deck is heading (dB).
func get_stem_target_db(layer: int) -> float:
	return (_stems[_front][layer] as Ramp).to


## The playing deck's stream (unchanged through a skirmish: the stems never restart).
func front_stream() -> AudioStreamSynchronized:
	return _deck_streams[_front]


## How far the Music bus is ducked under a Sign stinger right now (dB).
func music_duck_db() -> float:
	return _duck.value()


func is_profile_rendered(id: StringName) -> bool:
	return _rendered.has(id)
