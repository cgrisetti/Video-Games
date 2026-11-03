## A raid mechanic painted on the floor. It fills while the boss casts, then
## resolves once, reporting which players are inside:
##   CRIMSON_DODGE_OUT  red: get out, or take a big hit
##   GOLD_PARTY_SOAK    gold: stack in to split the damage
##   BLUE_BEHIND_TANK   blue: a long lane from the boss to its tank, with a
##                      shield pillar on the tank: get behind the tank's
##                      Shadow Sanctuary (the Cairnsman's Dover-Slap Gale-Beam;
##                      each player's HUD says what to do)
## Every peer shows the decal; only the boss's owner turns it into damage.
class_name RaidTelegraphDecal
extends Node3D

signal resolved(decal: RaidTelegraphDecal, inside: Array[ActorBase])

enum Kind { CRIMSON_DODGE_OUT, GOLD_PARTY_SOAK, BLUE_BEHIND_TANK }

const SHADER: Shader = preload("res://src/actors/raid_telegraph_decal.gdshader")
const CRIMSON_COLOR: Color = Color(0.9, 0.1, 0.14, 0.95)
const GOLD_COLOR: Color = Color(1.0, 0.78, 0.2, 0.95)
const BLUE_COLOR: Color = Color(0.3, 0.62, 1.0, 0.95)
const PILLAR_HEIGHT: float = 4.0
const PILLAR_RADIUS: float = 0.6
const FLOOR_OFFSET: float = 0.04
const RESOLVE_FLASH_TIME: float = 0.4
## A soak follows its target until it is this full, then locks in place.
const FOLLOW_UNTIL_FILL: float = 0.7

var kind: Kind = Kind.CRIMSON_DODGE_OUT
var radius: float = 4.0
var cast_time: float = 2.5
var elapsed: float = 0.0
var follow_target: ActorBase
## A beam: how long and wide its lane is, and the boss it runs out from.
var length: float = 0.0
var width: float = 0.0
var origin_actor: ActorBase

var _material: ShaderMaterial
var _pillar: Node3D
var _resolved: bool = false
var _flash_left: float = 0.0


func configure(decal_kind: Kind, decal_radius: float, decal_cast_time: float, follow: ActorBase) -> void:
	kind = decal_kind
	radius = decal_radius
	cast_time = maxf(0.1, decal_cast_time)
	follow_target = follow


## A beam lane from `origin` toward `target`, which it tracks until it's FOLLOW_UNTIL_FILL full.
func configure_beam(beam_length: float, beam_width: float, decal_cast_time: float, origin: ActorBase, target: ActorBase) -> void:
	kind = Kind.BLUE_BEHIND_TANK
	length = beam_length
	width = beam_width
	radius = beam_length
	cast_time = maxf(0.1, decal_cast_time)
	origin_actor = origin
	follow_target = target


func is_beam() -> bool:
	return kind == Kind.BLUE_BEHIND_TANK


func _ready() -> void:
	name = "Telegraph"
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	var tints: Array[Color] = [CRIMSON_COLOR, GOLD_COLOR, BLUE_COLOR]
	_material.set_shader_parameter(&"tint", tints[kind])
	_material.set_shader_parameter(&"soak", 1.0 if kind == Kind.GOLD_PARTY_SOAK else 0.0)
	_material.set_shader_parameter(&"beam", 1.0 if is_beam() else 0.0)
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(width, length) if is_beam() else Vector2(radius * 2.0, radius * 2.0)
	plane.material = _material
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = plane
	# A beam's lane runs out along -Z from the boss.
	mesh.position = Vector3(0.0, FLOOR_OFFSET, -length * 0.5 if is_beam() else 0.0)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	if is_beam():
		_build_pillar()
		# Aimed from its first frame, so nobody (a Squire safety net, a companion) reads a lane pointing nowhere.
		if is_instance_valid(follow_target):
			_aim_beam()
	CombatDirector.current.register_telegraph(self)


## The "stand behind the tank" sign: a blue column of light with a shield, on the tank.
func _build_pillar() -> void:
	_pillar = Node3D.new()
	_pillar.name = "ShieldPillar"
	add_child(_pillar)
	var glow: StandardMaterial3D = StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.albedo_color = Color(BLUE_COLOR, 0.28)
	glow.cull_mode = BaseMaterial3D.CULL_DISABLED
	var column: CylinderMesh = CylinderMesh.new()
	column.top_radius = PILLAR_RADIUS
	column.bottom_radius = PILLAR_RADIUS
	column.height = PILLAR_HEIGHT
	column.material = glow
	var beam_column: MeshInstance3D = MeshInstance3D.new()
	beam_column.name = "Column"
	beam_column.mesh = column
	beam_column.position = Vector3(0.0, PILLAR_HEIGHT * 0.5, 0.0)
	beam_column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pillar.add_child(beam_column)


func _exit_tree() -> void:
	CombatDirector.current.unregister_telegraph(self)


func is_hostile() -> bool:
	return kind == Kind.CRIMSON_DODGE_OUT


func is_soak() -> bool:
	return kind == Kind.GOLD_PARTY_SOAK


func fill_ratio() -> float:
	return clampf(elapsed / cast_time, 0.0, 1.0)


func contains(point: Vector3) -> bool:
	if is_beam():
		var local: Vector3 = global_transform.affine_inverse() * point
		return local.z <= 0.0 and local.z >= -length and absf(local.x) <= width * 0.5
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
		if is_beam():
			_aim_beam()
		else:
			global_position = Vector3(follow_target.global_position.x, global_position.y, follow_target.global_position.z)
	_material.set_shader_parameter(&"fill", fill_ratio())
	if _pillar != null and is_instance_valid(follow_target):
		_pillar.global_position = Vector3(follow_target.global_position.x, global_position.y, follow_target.global_position.z)
	if elapsed >= cast_time:
		_resolved = true
		if _pillar != null:
			_pillar.visible = false
		_flash_left = RESOLVE_FLASH_TIME
		resolved.emit(self, players_inside())


## Runs out from the boss toward its target, flat on the floor.
func _aim_beam() -> void:
	var start: Vector3 = origin_actor.global_position if is_instance_valid(origin_actor) else global_position
	var toward: Vector3 = follow_target.global_position - start
	toward.y = 0.0
	if toward.length() < 0.1:
		return
	global_transform = Transform3D(Basis.looking_at(toward.normalized(), Vector3.UP), Vector3(start.x, global_position.y, start.z))
