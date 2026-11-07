## The Harmonic Bell in Miller's Oak's lower southern bough (docs/20 Part II
## §1.5, §1.6: "the bell is rung together"): one rope per seat, and every
## active hero in the party must pull within 2.5 s of each other. Nobody can
## ring it alone for the others or sit it out. When they do,
## CalderaWorldState.trigger_the_ebb() ends the Long Flood (the level plays the
## Ebb cinematic). Ropes are pulled with light; the host keeps the count.
class_name HarmonicBell
extends Node3D

signal rope_pulled(actor: ActorBase, pulled: int, needed: int)
signal rung

## Every active hero must pull inside this many seconds.
const SYNC_WINDOW: float = 2.5
const ROPE_COUNT: int = 5
## Where the bell hangs above its foot, and the ropes' arc in front of it.
const BELL_HEIGHT: float = 7.5
const ROPE_ARC_RADIUS: float = 3.4

var has_rung: bool = false
var ropes: Array[HarmonicBellRope] = []

## Player id -> when (CombatDirector.game_time) they last pulled.
var _pulls: Dictionary[StringName, float] = {}
var _bell: Node3D
var _swing: float = 0.0


func _ready() -> void:
	add_to_group(&"map_glyphs")
	var bough: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_beam(bough, Vector3(-6.0, BELL_HEIGHT + 2.6, 2.0), Vector3(6.0, BELL_HEIGHT + 3.4, -1.0), 1.1, Color(0.42, 0.34, 0.26))
	# A frame of root-timber under the bough (the bell hangs well out from the trunk).
	CalderaKit.add_post(bough, Vector3(-5.6, 0.0, 1.9), 0.42, 0.6, BELL_HEIGHT + 2.7, Color(0.38, 0.3, 0.22), 7)
	CalderaKit.add_post(bough, Vector3(5.6, 0.0, -0.9), 0.42, 0.6, BELL_HEIGHT + 3.5, Color(0.38, 0.3, 0.22), 7)
	add_child(CalderaKit.mesh_node("Bough", bough))
	_bell = Node3D.new()
	_bell.name = "Bell"
	_bell.position = Vector3(0.0, BELL_HEIGHT + 2.9, 0.4)
	add_child(_bell)
	var bronze: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_cone(bronze, Vector3(0.0, -2.4, 0.0), 1.6, 2.2, CalderaKit.BRASS, 16)
	CalderaKit.add_post(bronze, Vector3(0.0, -2.6, 0.0), 1.75, 1.75, 0.3, CalderaKit.BRASS.darkened(0.2), 16)
	CalderaKit.add_sphere(bronze, Vector3(0.0, -2.9, 0.0), 0.35, CalderaKit.DARK_STONE, 1.0, 8)
	_bell.add_child(CalderaKit.mesh_node("Bronze", bronze))
	for index: int in ROPE_COUNT:
		var angle: float = lerpf(-0.9, 0.9, float(index) / float(ROPE_COUNT - 1))
		var rope: HarmonicBellRope = HarmonicBellRope.new()
		rope.name = "Rope%d" % (index + 1)
		rope.bell = self
		rope.rope_index = index
		rope.position = Vector3(sin(angle) * ROPE_ARC_RADIUS, 0.0, cos(angle) * ROPE_ARC_RADIUS)
		add_child(rope)
		ropes.append(rope)
	CalderaKit.sign_label(self, "Sign", "The Harmonic Bell\nevery hero pulls a rope together", Vector3(0.0, 3.2, ROPE_ARC_RADIUS + 1.2))


func _process(delta: float) -> void:
	if _swing > 0.0:
		_swing = maxf(0.0, _swing - delta * 0.12)
		_bell.rotation.x = sin(_swing * 30.0) * 0.35 * _swing


## The heroes who must pull: every human in the party who's up (at least one).
func ringers() -> Array[ActorBase]:
	var list: Array[ActorBase] = []
	for member: ActorBase in CombatDirector.current.party_actors():
		if not member.is_companion and not member.stats.is_downed:
			list.append(member)
	return list


func ringers_needed() -> int:
	return maxi(1, ringers().size())


## How many of the heroes needed have pulled inside the window right now.
func pulled_count() -> int:
	var now: float = CombatDirector.game_time()
	var count: int = 0
	for member: ActorBase in ringers():
		if _pulls.has(member.player_id) and now - _pulls[member.player_id] <= SYNC_WINDOW:
			count += 1
	return count


## Whether the bell can be rung at all: the stair is open (or playtesting) and the Ebb hasn't come.
func can_ring() -> bool:
	var state: CalderaWorldState = CalderaWorldState.current
	return state != null and not state.ebb_unlocked and (state.cliff_stair_open() or state.playtest)


## A hero pulls a rope (their own peer calls this; the host counts).
func pull(actor: ActorBase) -> void:
	if not can_ring():
		AudioCues.play(&"refuse")
		return
	AudioCues.play(&"bell", 1.0 + 0.08 * float(actor.party_slot), -10.0)
	if NetworkManager.current.is_online() and not NetworkManager.current.is_host():
		_report_pull.rpc_id(1, String(actor.player_id))
		return
	_register(actor.player_id)


@rpc("any_peer", "call_remote", "reliable")
func _report_pull(player_id: String) -> void:
	if multiplayer.is_server():
		_register(StringName(player_id))


func _register(player_id: StringName) -> void:
	if has_rung or not can_ring():
		return
	_pulls[player_id] = CombatDirector.game_time()
	var actor: ActorBase = null
	for member: ActorBase in ringers():
		if member.player_id == player_id:
			actor = member
	var pulled: int = pulled_count()
	rope_pulled.emit(actor, pulled, ringers_needed())
	if pulled >= ringers_needed():
		ring()


## Rings it: the Long Flood ends.
func ring() -> void:
	if has_rung:
		return
	has_rung = true
	_swing = 1.0
	AudioCues.play(&"victory")
	CalderaWorldState.current.trigger_the_ebb()
	rung.emit()
