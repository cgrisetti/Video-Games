## The Gorge Gale-Jet (07_EXPEDITION_HUD_AND_ART_GDD.md §3, Zone 2): every few
## seconds a gust gathers in the Sinaya Gatehouse's throat (the lane down the
## middle of the Doverslap Gorge Bridge pales and streams), then blasts down
## the bridge, shoving anyone standing in the lane back toward the holloway.
## Anyone sheltered by a Shadow Sanctuary (and the Shield-Sworn holding it)
## stands firm. It falls quiet when the gate opens.
##
## It lives in its CoopGate's frame: the gate at the origin, the lane running
## out along +Z. The host runs the cycle and the shoves and tells every peer
## each phase, so everyone sees the same gust.
class_name GorgeGaleJet
extends Node3D

signal gusted(pushed: int)

enum Phase { QUIET, GATHER, BLAST }

const QUIET_TIME: float = 3.5
const GATHER_TIME: float = 1.4
const BLAST_TIME: float = 0.6
const LANE_HALF_WIDTH: float = 1.5
## Where the lane starts in front of the gate, and how far down the bridge it runs.
const LANE_START: float = 0.6
const LANE_LENGTH: float = 21.5
const PUSH_DISTANCE: float = 5.0
const PUSH_TIME: float = 0.35
const LANE_COLOR: Color = Color(0.75, 0.9, 1.0)
const LANE_ALPHA: Array[float] = [0.06, 0.2, 0.42]

var phase: Phase = Phase.QUIET
var phase_left: float = QUIET_TIME
## False once the gate is open: no more gusts.
var active: bool = true

var _lane_material: StandardMaterial3D
var _streaks: CPUParticles3D


func _ready() -> void:
	_lane_material = StandardMaterial3D.new()
	_lane_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_lane_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_lane_material.albedo_color = Color(LANE_COLOR, LANE_ALPHA[Phase.QUIET])
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(LANE_HALF_WIDTH * 2.0, LANE_LENGTH)
	plane.material = _lane_material
	var lane: MeshInstance3D = MeshInstance3D.new()
	lane.name = "Lane"
	lane.mesh = plane
	lane.position = Vector3(0.0, 0.07, LANE_START + LANE_LENGTH * 0.5)
	lane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lane)
	_streaks = CPUParticles3D.new()
	_streaks.name = "Streaks"
	_streaks.position = Vector3(0.0, 1.0, LANE_START)
	_streaks.amount = 24
	_streaks.lifetime = 1.2
	_streaks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_streaks.emission_box_extents = Vector3(LANE_HALF_WIDTH, 0.8, 0.2)
	_streaks.direction = Vector3(0.0, 0.0, 1.0)
	_streaks.spread = 4.0
	_streaks.gravity = Vector3.ZERO
	_streaks.initial_velocity_min = 8.0
	_streaks.initial_velocity_max = 14.0
	var streak: BoxMesh = BoxMesh.new()
	streak.size = Vector3(0.04, 0.04, 0.9)
	var streak_material: StandardMaterial3D = StandardMaterial3D.new()
	streak_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak_material.albedo_color = Color(1.0, 1.0, 1.0, 0.55)
	streak.material = streak_material
	_streaks.mesh = streak
	_streaks.emitting = false
	add_child(_streaks)


## In the gust's path: on the lane, within reach of the ground.
func in_lane(point: Vector3) -> bool:
	var local: Vector3 = to_local(point)
	return absf(local.x) <= LANE_HALF_WIDTH and local.z >= LANE_START and local.z <= LANE_START + LANE_LENGTH and absf(local.y) < 2.0


func _physics_process(delta: float) -> void:
	if not active or not NetworkManager.current.is_host() or not InstanceManager.current.is_live():
		return
	phase_left -= delta
	if phase_left > 0.0:
		return
	match phase:
		Phase.QUIET:
			_tell_phase(Phase.GATHER)
		Phase.GATHER:
			_tell_phase(Phase.BLAST)
			blast()
		Phase.BLAST:
			_tell_phase(Phase.QUIET)


## Host: blows now, shoving everyone unsheltered in the lane down the bridge. Returns how many it shoved.
func blast() -> int:
	var pushed: int = 0
	var down_bridge: Vector3 = global_basis.z.normalized()
	for member: ActorBase in CombatDirector.current.alive_party():
		if not in_lane(member.global_position) or CombatDirector.current.is_sheltered(member):
			continue
		var local_z: float = to_local(member.global_position).z
		var room: float = minf(PUSH_DISTANCE, LANE_START + LANE_LENGTH - local_z)
		CombatDirector.current.shove(member, member.global_position + down_bridge * maxf(0.0, room), PUSH_TIME)
		pushed += 1
	gusted.emit(pushed)
	return pushed


## Quiet for good (the gate is open).
func calm() -> void:
	active = false
	_show_phase(Phase.QUIET)
	_streaks.emitting = false


func _tell_phase(next: Phase) -> void:
	_show_phase(next)
	for peer_id: int in InstanceManager.current.live_remote_peers():
		_show_phase.rpc_id(peer_id, next)


## Every peer: the lane pales as the gust gathers and streams while it blows.
@rpc("authority", "call_local", "reliable")
func _show_phase(next: int) -> void:
	phase = next as Phase
	phase_left = [QUIET_TIME, GATHER_TIME, BLAST_TIME][phase]
	_lane_material.albedo_color = Color(LANE_COLOR, LANE_ALPHA[phase])
	_streaks.emitting = phase != Phase.QUIET
	if phase == Phase.BLAST:
		AudioCues.play(&"gale", 1.0, -2.0)
