## A raid mechanic painted on the floor. It fills from the centre while the boss
## casts, then resolves once, reporting which players are inside:
##   CRIMSON_DODGE_OUT  red: get out, or take a big hit
##   GOLD_PARTY_SOAK    gold: stack in to split the damage
## Every peer shows the decal; only the boss's owner turns it into damage.
class_name RaidTelegraphDecal
extends Node3D

signal resolved(decal: RaidTelegraphDecal, inside: Array[ActorBase])

enum Kind { CRIMSON_DODGE_OUT, GOLD_PARTY_SOAK }

const SHADER: Shader = preload("res://src/actors/raid_telegraph_decal.gdshader")
const CRIMSON_COLOR: Color = Color(0.9, 0.1, 0.14, 0.95)
const GOLD_COLOR: Color = Color(1.0, 0.78, 0.2, 0.95)
const FLOOR_OFFSET: float = 0.04
const RESOLVE_FLASH_TIME: float = 0.4
## A soak follows its target until it is this full, then locks in place.
const FOLLOW_UNTIL_FILL: float = 0.7

var kind: Kind = Kind.CRIMSON_DODGE_OUT
var radius: float = 4.0
var cast_time: float = 2.5
var elapsed: float = 0.0
var follow_target: ActorBase

var _material: ShaderMaterial
var _resolved: bool = false
var _flash_left: float = 0.0


func configure(decal_kind: Kind, decal_radius: float, decal_cast_time: float, follow: ActorBase) -> void:
	kind = decal_kind
	radius = decal_radius
	cast_time = maxf(0.1, decal_cast_time)
	follow_target = follow


func _ready() -> void:
	name = "Telegraph"
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter(&"tint", CRIMSON_COLOR if is_hostile() else GOLD_COLOR)
	_material.set_shader_parameter(&"soak", 0.0 if is_hostile() else 1.0)
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(radius * 2.0, radius * 2.0)
	plane.material = _material
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = plane
	mesh.position = Vector3(0.0, FLOOR_OFFSET, 0.0)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	CombatDirector.current.register_telegraph(self)


func _exit_tree() -> void:
	CombatDirector.current.unregister_telegraph(self)


func is_hostile() -> bool:
	return kind == Kind.CRIMSON_DODGE_OUT


func fill_ratio() -> float:
	return clampf(elapsed / cast_time, 0.0, 1.0)


func contains(point: Vector3) -> bool:
	var flat: Vector2 = Vector2(point.x - global_position.x, point.z - global_position.z)
	return flat.length() <= radius


func players_inside() -> Array[ActorBase]:
	var inside: Array[ActorBase] = []
	for member: ActorBase in CombatDirector.current.alive_party():
		if contains(member.global_position):
			inside.append(member)
	return inside


func _physics_process(delta: float) -> void:
	if _resolved:
		_flash_left -= delta
		_material.set_shader_parameter(&"flash", maxf(0.0, _flash_left / RESOLVE_FLASH_TIME))
		_material.set_shader_parameter(&"fade", maxf(0.0, _flash_left / RESOLVE_FLASH_TIME))
		if _flash_left <= 0.0:
			queue_free()
		return
	elapsed += delta
	if is_instance_valid(follow_target) and fill_ratio() < FOLLOW_UNTIL_FILL:
		global_position = Vector3(follow_target.global_position.x, global_position.y, follow_target.global_position.z)
	_material.set_shader_parameter(&"fill", fill_ratio())
	if elapsed >= cast_time:
		_resolved = true
		_flash_left = RESOLVE_FLASH_TIME
		resolved.emit(self, players_inside())
