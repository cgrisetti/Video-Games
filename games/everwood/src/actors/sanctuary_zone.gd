## A support zone on the floor:
##   RING  Green Sanctuary (healer): heals allies standing inside every second
##   CONE  Shadow Sanctuary (tank): a shield cone behind the tank; allies inside
##         take much less damage
## Every peer spawns the zone; each peer heals or protects only the actors it owns.
class_name SanctuaryZone
extends Node3D

enum Shape { RING, CONE }

const CONE_HALF_ANGLE: float = PI * 0.25 # 45 degrees each side
const SHADOW_DAMAGE_REDUCTION: float = 0.6
const HEAL_TICK: float = 1.0
const FADE_TIME: float = 0.5
const FLOOR_OFFSET: float = 0.05
const RING_COLOR: Color = Color(0.35, 1.0, 0.5, 0.32)
const CONE_COLOR: Color = Color(0.55, 0.35, 0.95, 0.34)
const WALL_HEIGHT: float = 2.2

var owner_player_id: StringName = &""
var shape: Shape = Shape.RING
var radius: float = 4.0
var duration: float = 6.0
var heal_per_second: float = 0.0
var damage_reduction: float = 0.0

var _age: float = 0.0
var _tick_accum: float = 0.0
var _material: StandardMaterial3D


func configure(zone_owner: StringName, zone_shape: Shape, zone_radius: float, zone_duration: float, zone_heal_per_second: float) -> void:
	owner_player_id = zone_owner
	shape = zone_shape
	radius = zone_radius
	duration = zone_duration
	heal_per_second = zone_heal_per_second
	damage_reduction = SHADOW_DAMAGE_REDUCTION if zone_shape == Shape.CONE else 0.0


func _ready() -> void:
	name = "SanctuaryZone"
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.albedo_color = CONE_COLOR if shape == Shape.CONE else RING_COLOR
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	floor_mesh.mesh = _build_cone_mesh() if shape == Shape.CONE else _build_ring_mesh()
	floor_mesh.material_override = _material
	floor_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	floor_mesh.position = Vector3(0.0, FLOOR_OFFSET, 0.0)
	add_child(floor_mesh)
	if shape == Shape.CONE:
		# The "physical" shield: a translucent wall at the tank, facing the boss.
		var wall: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(2.6, WALL_HEIGHT, 0.12)
		wall.mesh = box
		wall.material_override = _material
		wall.position = Vector3(0.0, WALL_HEIGHT * 0.5, -0.9)
		wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(wall)
	CombatDirector.current.register_zone(self)


func _exit_tree() -> void:
	CombatDirector.current.unregister_zone(self)


## A ring around the centre, or a cone that opens out behind the tank (+Z, away from where it faces).
func contains(point: Vector3) -> bool:
	var local: Vector3 = global_transform.affine_inverse() * point
	var flat: Vector2 = Vector2(local.x, local.z)
	if flat.length() > radius:
		return false
	if shape == Shape.RING:
		return true
	if local.z <= 0.0:
		return false
	return absf(atan2(local.x, local.z)) <= CONE_HALF_ANGLE


func _physics_process(delta: float) -> void:
	_age += delta
	var remaining: float = duration - _age
	_material.albedo_color.a = (CONE_COLOR.a if shape == Shape.CONE else RING_COLOR.a) * clampf(remaining / FADE_TIME, 0.0, 1.0)
	if remaining <= 0.0:
		queue_free()
		return
	if heal_per_second <= 0.0:
		return
	_tick_accum += delta
	if _tick_accum < HEAL_TICK:
		return
	_tick_accum -= HEAL_TICK
	var healer: ActorBase = CombatDirector.current.get_actor(owner_player_id)
	for member: ActorBase in CombatDirector.current.party_actors():
		if member.is_multiplayer_authority() and contains(member.global_position):
			CombatDirector.current.apply_heal(healer if healer != null else member, member, heal_per_second * HEAL_TICK)


func _build_ring_mesh() -> Mesh:
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.02
	disc.radial_segments = 48
	return disc


func _build_cone_mesh() -> Mesh:
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps: int = 16
	for index: int in steps:
		var a0: float = lerpf(-CONE_HALF_ANGLE, CONE_HALF_ANGLE, float(index) / steps)
		var a1: float = lerpf(-CONE_HALF_ANGLE, CONE_HALF_ANGLE, float(index + 1) / steps)
		tool.add_vertex(Vector3.ZERO)
		tool.add_vertex(Vector3(sin(a0), 0.0, cos(a0)) * radius)
		tool.add_vertex(Vector3(sin(a1), 0.0, cos(a1)) * radius)
	return tool.commit()
