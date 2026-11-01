## The Co-Op Threshold at the Sinaya Gatehouse (07_EXPEDITION_HUD_AND_ART_GDD.md
## §3, Zone 2). A timber portcullis seals the way to the Ring of the Cairnsman
## while the Gorge Gale-Jet sweeps the bridge in front of it. Two ways open it:
##   Rune-Plates  stand on the twin plates on the bridge's side bays together
##                for 2 s (as many plates as min(2, standing party), so a
##                lone player needs one; in solo play an AI companion takes
##                the second, LevelBase's companions are steered here)
##   Bell-Winch   a Shield-Sworn raises Shadow Sanctuary against the gale and
##                a teammate standing in its shelter rings the Bronze
##                Bridge-Bell
## The gate builds its moving parts in code (portcullis, plates, winch, gale);
## the level builder raises the stone towers around it. Its frame: the
## portcullis at the origin, the bridge running out along +Z. The host decides
## when it opens and tells every peer; a peer arriving later asks.
class_name CoopGate
extends Node3D

signal opened(method: int)

enum Method { NONE, RUNE_PLATES, BELL_WINCH }

const PORTCULLIS_WIDTH: float = 4.8
const PORTCULLIS_HEIGHT: float = 4.2
const PORTCULLIS_SINK_TIME: float = 1.6
const BAR_SPACING: float = 0.55
const TIMBER_COLOR: Color = Color(0.36, 0.25, 0.15)
const IRON_COLOR: Color = Color(0.3, 0.3, 0.33)
## Seconds the plates must be held together.
const PLATE_HOLD_TIME: float = 2.0
const MAX_PLATES_NEEDED: int = 2
## The plates on the bridge's side bays and the winch before the portcullis (in the gate's frame).
const PLATE_SPOTS: Array[Vector3] = [Vector3(-4.8, 0.0, 10.0), Vector3(4.8, 0.0, 10.0)]
const WINCH_SPOT: Vector3 = Vector3(0.0, 0.0, 3.4)
## Metres of lag forgiveness when the host checks a ringer's reach.
const RING_SLACK: float = 1.5

var is_open: bool = false
var opened_by: Method = Method.NONE
var plates: Array[RunePlate] = []
var winch: BellWinch
var gale: GorgeGaleJet
## Seconds the plates have been held (the host's count).
var hold_time: float = 0.0

var _portcullis: StaticBody3D
var _portcullis_collision: CollisionShape3D
var _sink: Tween


func _ready() -> void:
	_build_portcullis()
	for index: int in PLATE_SPOTS.size():
		var plate: RunePlate = RunePlate.new()
		plate.name = "RunePlate%d" % (index + 1)
		plate.position = PLATE_SPOTS[index]
		add_child(plate)
		plates.append(plate)
	winch = BellWinch.new()
	winch.name = "BellWinch"
	winch.position = WINCH_SPOT
	add_child(winch)
	winch.ring_requested.connect(_on_ring_requested)
	gale = GorgeGaleJet.new()
	gale.name = "GaleJet"
	add_child(gale)
	InstanceManager.current.instance_live.connect(_on_instance_live)


func _exit_tree() -> void:
	var instances: InstanceManager = InstanceManager.current
	if instances != null and instances.instance_live.is_connected(_on_instance_live):
		instances.instance_live.disconnect(_on_instance_live)


## Plates a party needs: min(2, standing players), at least one.
static func plates_needed(standing: int) -> int:
	return clampi(standing, 1, MAX_PLATES_NEEDED)


func _physics_process(delta: float) -> void:
	if is_open:
		return
	var party: Array[ActorBase] = CombatDirector.current.alive_party()
	var occupied: int = 0
	for plate: RunePlate in plates:
		var stood_on: bool = false
		for member: ActorBase in party:
			stood_on = stood_on or plate.contains(member.global_position)
		if stood_on:
			occupied += 1
		plate.show_state(stood_on, hold_time / PLATE_HOLD_TIME)
	if not NetworkManager.current.is_host() or not InstanceManager.current.is_live():
		return
	hold_time = hold_time + delta if occupied >= plates_needed(party.size()) and not party.is_empty() else 0.0
	if hold_time >= PLATE_HOLD_TIME:
		open(Method.RUNE_PLATES)


## Host: the plate a companion should go and stand on: the empty one while
## somebody holds the other and two are needed. Null otherwise.
func plate_needing_help() -> RunePlate:
	if is_open:
		return null
	var party: Array[ActorBase] = CombatDirector.current.alive_party()
	if plates_needed(party.size()) < 2:
		return null
	var free: Array[RunePlate] = []
	for plate: RunePlate in plates:
		var held: bool = false
		for member: ActorBase in party:
			held = held or (plate.contains(member.global_position) and not member.is_companion)
		if not held:
			free.append(plate)
	return free[0] if free.size() == 1 else null


func _on_ring_requested(actor: ActorBase) -> void:
	if is_open:
		return
	if not CombatDirector.current.is_sheltered(actor):
		AudioCues.play(&"refuse")
		CombatDirector.current.show_float_text(actor.global_position + Vector3.UP * 2.4, "The gale is too strong!", GorgeGaleJet.LANE_COLOR)
		return
	if NetworkManager.current.is_host():
		_server_ring(actor.player_id)
	elif NetworkManager.current.is_online():
		_request_ring.rpc_id(1, String(actor.player_id))


@rpc("any_peer", "call_remote", "reliable")
func _request_ring(player_id: String) -> void:
	if multiplayer.is_server():
		_server_ring(StringName(player_id))


## Host: the ringer must be sheltered and at the winch, as the host sees it.
func _server_ring(player_id: StringName) -> void:
	var ringer: ActorBase = CombatDirector.current.get_actor(player_id)
	if is_open or ringer == null or ringer.stats.is_downed or not CombatDirector.current.is_sheltered(ringer):
		return
	if ringer.global_position.distance_to(winch.global_position) <= winch.reach + RING_SLACK:
		open(Method.BELL_WINCH)


## Host: opens the gate for everyone.
func open(method: Method) -> void:
	if is_open or not NetworkManager.current.is_host():
		return
	_open(method)
	for peer_id: int in InstanceManager.current.live_remote_peers():
		_open.rpc_id(peer_id, method)


## Every peer: the bell rings, the portcullis sinks into the ground and the gale dies away.
@rpc("authority", "call_local", "reliable")
func _open(method: int) -> void:
	if is_open:
		return
	is_open = true
	opened_by = method as Method
	gale.calm()
	_portcullis_collision.set_deferred(&"disabled", true)
	if _sink != null:
		_sink.kill()
	_sink = create_tween()
	_sink.tween_property(_portcullis, "position:y", -PORTCULLIS_HEIGHT - 0.2, PORTCULLIS_SINK_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if method == Method.BELL_WINCH:
		winch.ring()
	else:
		AudioCues.play(&"bell")
	AudioCues.play(&"gate")
	for plate: RunePlate in plates:
		plate.show_state(true, 1.0)
	opened.emit(method)


## Host: seals the gate again (the smoke test tries both ways to open it).
func reset_gate() -> void:
	if not NetworkManager.current.is_host():
		return
	_close()
	for peer_id: int in InstanceManager.current.live_remote_peers():
		_close.rpc_id(peer_id)


@rpc("authority", "call_local", "reliable")
func _close() -> void:
	is_open = false
	opened_by = Method.NONE
	hold_time = 0.0
	if _sink != null:
		_sink.kill()
	_portcullis.position.y = 0.0
	_portcullis_collision.set_deferred(&"disabled", false)
	gale.active = true


## A peer that loads in after the gate opened asks the host how it stands.
func _on_instance_live(_id: StringName) -> void:
	if is_inside_tree() and not NetworkManager.current.is_host() and NetworkManager.current.is_online():
		_request_state.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _request_state() -> void:
	if multiplayer.is_server() and is_open:
		_open.rpc_id(multiplayer.get_remote_sender_id(), opened_by)


## A lattice of timber bars bound with iron, one solid collider.
func _build_portcullis() -> void:
	_portcullis = StaticBody3D.new()
	_portcullis.name = "Portcullis"
	_portcullis.collision_layer = ActorBase.LAYER_WORLD
	_portcullis.collision_mask = 0
	add_child(_portcullis)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(PORTCULLIS_WIDTH, PORTCULLIS_HEIGHT, 0.5)
	_portcullis_collision = CollisionShape3D.new()
	_portcullis_collision.name = "Collision"
	_portcullis_collision.shape = shape
	_portcullis_collision.position = Vector3(0.0, PORTCULLIS_HEIGHT * 0.5, 0.0)
	_portcullis.add_child(_portcullis_collision)
	var timber: Material = StorybookMaterial.make(TIMBER_COLOR)
	var iron: Material = StorybookMaterial.make(IRON_COLOR, 0.4)
	var bars: int = int(PORTCULLIS_WIDTH / BAR_SPACING)
	for index: int in bars + 1:
		var x: float = -PORTCULLIS_WIDTH * 0.5 + index * PORTCULLIS_WIDTH / bars
		_portcullis.add_child(ShapeKit.box("Bar%d" % index, Vector3(0.16, PORTCULLIS_HEIGHT, 0.16), Vector3(x, PORTCULLIS_HEIGHT * 0.5, 0.0), timber))
	for row: int in 4:
		var y: float = 0.5 + row * (PORTCULLIS_HEIGHT - 0.8) / 3.0
		_portcullis.add_child(ShapeKit.box("Band%d" % row, Vector3(PORTCULLIS_WIDTH, 0.14, 0.22), Vector3(0.0, y, 0.0), iron))
	for index: int in bars + 1:
		var x: float = -PORTCULLIS_WIDTH * 0.5 + index * PORTCULLIS_WIDTH / bars
		_portcullis.add_child(ShapeKit.tilted(ShapeKit.cone("Spike%d" % index, 0.09, 0.3, Vector3(x, -0.15, 0.0), iron), Vector3(PI, 0.0, 0.0)))
