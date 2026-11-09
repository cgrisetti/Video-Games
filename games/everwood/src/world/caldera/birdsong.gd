## The birds in the hedges, trees and reeds round the party (docs/33 §10, the Creative Director's call of
## 2026-11-09): every few seconds a blackbird's fluting phrase or a wren's run and trill (PastoralVoices) from a
## perch on dry land 14 to 38 m from the hero who listens (Player 1: split-screen hears the world from the
## first view). The isles differ: the high moor and the ironstone heath have fewer birds than the valleys and fens.
## The First-Quiet silences them. Where a Hush-Crack lies open, no bird sings (docs/17 §2.2: "Birdsong ... pause[s]
## inside the hush radius"), and when one is calmed and its Reclamation Bloom sweeps out, the birds there burst
## into song. Nothing to press and nothing shown, only the world answering what the party does.
class_name Birdsong
extends Node3D

## Seconds between songs (times the isle's sparseness), and how far from the listener a bird perches.
const GAP: Vector2 = Vector2(2.5, 7.0)
const NEAR: Vector2 = Vector2(14.0, 38.0)
## A perch is dry land this far over the sea, in a hedge or a tree this high.
const DRY_LAND: float = 1.5
const PERCH_HEIGHT: Vector2 = Vector2(2.5, 5.0)
## Spots tried for a perch before a song is given up (over the sea, past the Deep-Hush).
const TRIES: int = 6
## How far a song carries, how loud, and a wren's share of the songs.
const REACH: float = 48.0
const VOLUME_DB: float = -14.0
const WREN_SHARE: float = 0.35
## Fewer birds on the high moor and the ironstone heath (each isle's gap is multiplied by this).
const SPARSE: Dictionary[StringName, float] = {&"isle_iron_ness": 1.8, &"isle_rime_firth": 2.2}
## A bloom within BURST_REACH of the listener sets this many birds singing round it, one after another.
const BURST_SONGS: int = 4
const BURST_REACH: float = 70.0
const BURST_SPREAD: Vector2 = Vector2(4.0, 14.0)
const BURST_STEP: Vector2 = Vector2(0.3, 0.6)
## A listener this far under the ground is in the Sap Galleries: no birds.
const UNDERGROUND: float = 2.5
const PLAYERS: int = 3

var level: CalderaArchipelagoWorld
## Songs sung, songs the hush held back, bursts at a bloom, and the last song's voice (the checks).
var sung: int = 0
var hushed: int = 0
var bursts: int = 0
var last_voice: int = -1

var _players: Array[AudioStreamPlayer3D] = []
var _next: int = 0
var _left: float = 1.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _burst: Array[Vector3] = []
var _burst_left: float = 0.0


func _ready() -> void:
	name = "Birdsong"
	_rng.seed = hash("birdsong")
	for index: int in PLAYERS:
		var player: AudioStreamPlayer3D = PastoralVoices.player("Bird%d" % index, REACH, VOLUME_DB)
		add_child(player)
		_players.append(player)
	if WorldAtmosphereDirector.current != null:
		WorldAtmosphereDirector.current.bloomed.connect(_on_bloomed)


func _exit_tree() -> void:
	if WorldAtmosphereDirector.current != null and WorldAtmosphereDirector.current.bloomed.is_connected(_on_bloomed):
		WorldAtmosphereDirector.current.bloomed.disconnect(_on_bloomed)


func _process(delta: float) -> void:
	if level == null or level.streamer == null or level.streamer.builder == null:
		return
	var hero: ActorBase = listener()
	if hero == null:
		return
	if not _burst.is_empty():
		_burst_left -= delta
		if _burst_left <= 0.0:
			sing_at(_burst.pop_back())
			_burst_left = _rng.randf_range(BURST_STEP.x, BURST_STEP.y)
	_left -= delta
	if _left > 0.0:
		return
	_left = _rng.randf_range(GAP.x, GAP.y) * float(SPARSE.get(level.streamer.active_isle, 1.0))
	try_sing(hero.global_position)


## The hero who hears the world: Player 1 (split-screen plays sound from the first view).
func listener() -> ActorBase:
	for actor: ActorBase in level.party_in_order():
		if actor.is_local_player() and not actor.is_companion:
			return actor
	return null


## Tries a song near `around`: &"sang", &"hushed" (the First-Quiet holds it back) or &"no_perch".
func try_sing(around: Vector3) -> StringName:
	if around.y < level.streamer.height_at(around.x, around.z) - UNDERGROUND:
		return &"no_perch"
	if hushed_at(around):
		hushed += 1
		return &"hushed"
	for attempt: int in TRIES:
		var angle: float = _rng.randf() * TAU
		var spot: Vector3 = around + Vector3(cos(angle), 0.0, sin(angle)) * _rng.randf_range(NEAR.x, NEAR.y)
		if not is_perch(spot):
			continue
		if hushed_at(spot):
			hushed += 1
			return &"hushed"
		return &"sang" if sing_at(spot) else &"no_perch"
	return &"no_perch"


## Dry land on this isle, short of the Deep-Hush.
func is_perch(spot: Vector3) -> bool:
	var builder: IslandBuilder = level.streamer.builder
	var sea: float = CalderaWorldState.current.sea_level_y if CalderaWorldState.current != null else 0.0
	return level.streamer.height_at(spot.x, spot.z) > sea + DRY_LAND and not builder.beyond_seal(spot.x, spot.z)


func hushed_at(spot: Vector3) -> bool:
	return WorldAtmosphereDirector.current != null and WorldAtmosphereDirector.current.hush_at(spot)


## A bird sings from a perch over `spot`: a blackbird's phrase, or a wren's.
func sing_at(spot: Vector3) -> bool:
	var voice: PastoralVoices.Voice = PastoralVoices.Voice.WREN if _rng.randf() < WREN_SHARE else PastoralVoices.Voice.SONGBIRD
	var sound: AudioStreamWAV = PastoralVoices.stream(voice, _rng.randi() % PastoralVoices.TAKES)
	if sound == null:
		return false
	var player: AudioStreamPlayer3D = _players[_next]
	_next = (_next + 1) % _players.size()
	player.global_position = Vector3(spot.x, level.streamer.height_at(spot.x, spot.z) + _rng.randf_range(PERCH_HEIGHT.x, PERCH_HEIGHT.y), spot.z)
	player.stream = sound
	player.pitch_scale = 1.0
	if not PastoralVoices.silent():
		player.play()
	sung += 1
	last_voice = voice
	return true


## A bloom near the listener: the birds round it take up their song again, one after another.
func _on_bloomed(at: Vector3) -> void:
	if level == null or level.streamer == null:
		return
	var hero: ActorBase = listener()
	if hero == null or hero.global_position.distance_to(at) > BURST_REACH:
		return
	bursts += 1
	for song: int in BURST_SONGS:
		var angle: float = _rng.randf() * TAU
		_burst.append(at + Vector3(cos(angle), 0.0, sin(angle)) * _rng.randf_range(BURST_SPREAD.x, BURST_SPREAD.y))
	_burst_left = 0.25
