## The Breach Gales of the Trial of the Gale (docs/20 Part II area 4): every
## few seconds the cold wind off The Breach gathers (streaks race across the
## arena from the north-west), then blasts, shoving every hero in the open
## downwind. Standing in the lee of an Old Sanctum wall, inside a Shadow
## Sanctuary, or mid-dodge (a Flow-Link dash) keeps you where you are. Built
## on the Gorge Gale-Jet's pattern; the host runs it.
class_name BreachGale
extends Node3D

signal gusted(pushed: int)

enum Phase { QUIET, GATHER, BLAST }

const QUIET_TIME: float = 6.0
const GATHER_TIME: float = 1.6
const BLAST_TIME: float = 0.6
const PUSH_DISTANCE: float = 6.0
const PUSH_TIME: float = 0.4
## A wall's lee: this far downwind of it, and this far past its ends.
const LEE_DEPTH: float = 4.5
const LEE_OVERHANG: float = 0.6

## The wind blows this way (from The Breach, north-west, toward the south-east).
@export var wind: Vector3 = Vector3(0.62, 0.0, 0.78)
@export var radius: float = 30.0

var phase: Phase = Phase.QUIET
var phase_left: float = QUIET_TIME
var active: bool = false
var gusts: int = 0
## The Old Sanctum wall pieces (each a Node3D whose local X runs along it; meta "half_length").
var walls: Array[Node3D] = []

var _streaks: CPUParticles3D


func _ready() -> void:
	wind = wind.normalized()
	_streaks = CPUParticles3D.new()
	_streaks.name = "Streaks"
	_streaks.position = -wind * radius + Vector3(0.0, 1.4, 0.0)
	_streaks.amount = 40
	_streaks.lifetime = 1.4
	_streaks.emitting = false
	_streaks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_streaks.emission_box_extents = Vector3(radius, 1.2, 2.0)
	_streaks.rotation.y = atan2(wind.x, wind.z)
	_streaks.direction = Vector3(0.0, 0.0, 1.0)
	_streaks.spread = 4.0
	_streaks.gravity = Vector3.ZERO
	_streaks.initial_velocity_min = 34.0
	_streaks.initial_velocity_max = 44.0
	var streak: BoxMesh = BoxMesh.new()
	streak.size = Vector3(0.05, 0.05, 2.4)
	var white: StandardMaterial3D = StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	white.albedo_color = Color(0.9, 0.96, 1.0, 0.55)
	streak.material = white
	_streaks.mesh = streak
	_streaks.local_coords = false
	_streaks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_streaks)


func _physics_process(delta: float) -> void:
	if not active:
		phase = Phase.QUIET
		phase_left = QUIET_TIME
		_streaks.emitting = false
		return
	phase_left -= delta
	if phase_left > 0.0:
		return
	match phase:
		Phase.QUIET:
			phase = Phase.GATHER
			phase_left = GATHER_TIME
			_streaks.emitting = true
			AudioCues.play(&"gale")
		Phase.GATHER:
			phase = Phase.BLAST
			phase_left = BLAST_TIME
			blast()
		Phase.BLAST:
			phase = Phase.QUIET
			phase_left = QUIET_TIME
			_streaks.emitting = false


## One gust now: everyone in the open in the arena is shoved downwind. Returns how many.
func blast() -> int:
	var pushed: int = 0
	for member: ActorBase in CombatDirector.current.party_actors():
		if not member.is_multiplayer_authority() or member.stats.is_downed:
			continue
		var flat: Vector2 = Vector2(member.global_position.x - global_position.x, member.global_position.z - global_position.z)
		if flat.length() > radius or is_sheltered(member):
			continue
		member.start_forced_move(member.global_position + wind * PUSH_DISTANCE, PUSH_TIME)
		pushed += 1
	gusts += 1
	gusted.emit(pushed)
	return pushed


## In a wall's lee, inside a Shadow Sanctuary, or dodging through the gust.
func is_sheltered(member: ActorBase) -> bool:
	if CombatDirector.current.is_sheltered(member) or member.state_machine.is_in(&"dodge"):
		return true
	return in_lee(member.global_position)


func in_lee(at: Vector3) -> bool:
	for wall: Node3D in walls:
		var local: Vector3 = wall.global_transform.affine_inverse() * at
		var half: float = float(wall.get_meta(&"half_length", 2.5))
		var downwind: float = (at - wall.global_position).dot(wind)
		if absf(local.x) <= half + LEE_OVERHANG and downwind > 0.0 and downwind <= LEE_DEPTH:
			return true
	return false
