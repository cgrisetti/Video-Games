## The Wayfarer's trail to a pinned place (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §7.3):
## a ribbon of warm fireflies drifting 0.8 m above the ground from the hero
## toward `pinned_target_xz`, up to 48 m of it at a time, in the hero's seat
## colour warmed toward lantern-gold. It follows the hero and the ground, and
## goes out when they arrive (within 4 m), or when the pin moves or is cleared.
## One MultiMesh, no colliders, nothing for the camera to bump.
class_name WayfarerTrailGuideFX
extends Node3D

signal arrived

const RIBBON_HEIGHT_M: float = 0.8
const MOTE_COUNT: int = 30
const SPACING_M: float = 1.6
const MAX_LENGTH_M: float = 48.0
const ARRIVE_RADIUS_M: float = 4.0
## Metres a second the fireflies drift along the ribbon.
const DRIFT_SPEED: float = 1.8
const MOTE_RADIUS: float = 0.07
const LANTERN_GOLD: Color = Color(1.0, 0.84, 0.42)

var actor: ActorBase
var pinned_target_xz: Vector2 = Vector2.ZERO
var color: Color = LANTERN_GOLD

var _motes: MultiMeshInstance3D
var _phase: float = 0.0
var _points: PackedVector3Array = PackedVector3Array()


func setup(guided: ActorBase, target_xz: Vector2, tint: Color) -> void:
	actor = guided
	pinned_target_xz = target_xz
	color = tint.lerp(LANTERN_GOLD, 0.55)


func _ready() -> void:
	name = "WayfarerTrailGuide"
	top_level = true
	global_transform = Transform3D.IDENTITY
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = MOTE_RADIUS
	sphere.height = MOTE_RADIUS * 2.0
	sphere.radial_segments = 6
	sphere.rings = 3
	var glow: StandardMaterial3D = StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.vertex_color_use_as_albedo = true
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.emission_enabled = true
	glow.emission = color
	glow.emission_energy_multiplier = 2.2
	sphere.material = glow
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = sphere
	multimesh.instance_count = MOTE_COUNT
	_motes = MultiMeshInstance3D.new()
	_motes.name = "Fireflies"
	_motes.multimesh = multimesh
	_motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_motes)
	_update(0.0)


func _process(delta: float) -> void:
	_update(delta)


## The fireflies' places now (world), one per firefly.
func ribbon_points() -> PackedVector3Array:
	return _points


## Metres from the hero to the pin on the ground.
func distance_left() -> float:
	if not is_instance_valid(actor):
		return 0.0
	return Vector2(actor.global_position.x, actor.global_position.z).distance_to(pinned_target_xz)


func _update(delta: float) -> void:
	if not is_instance_valid(actor) or not actor.is_inside_tree():
		queue_free()
		return
	var from: Vector2 = Vector2(actor.global_position.x, actor.global_position.z)
	var to_target: Vector2 = pinned_target_xz - from
	var left: float = to_target.length()
	if left <= ARRIVE_RADIUS_M:
		arrived.emit()
		queue_free()
		return
	_phase += delta * DRIFT_SPEED
	var along: Vector2 = to_target / left
	var across: Vector2 = Vector2(-along.y, along.x)
	var length: float = minf(left, MAX_LENGTH_M)
	var span: float = minf(length, MOTE_COUNT * SPACING_M)
	_points.resize(MOTE_COUNT)
	for index: int in MOTE_COUNT:
		var s: float = 1.0 + fposmod(index * SPACING_M + _phase, span)
		var sway: float = sin(s * 0.9 + _phase * 1.7 + index) * 0.35
		var flat: Vector2 = from + along * s + across * sway
		var ground: float = _ground(flat, actor.global_position.y)
		var bob: float = sin(_phase * 2.3 + index * 1.3) * 0.12
		var at: Vector3 = Vector3(flat.x, ground + RIBBON_HEIGHT_M + bob, flat.y)
		_points[index] = at
		# Brightest mid-ribbon, fading in at the hero's end and out at the far end.
		var share: float = s / maxf(span, 0.01)
		var tint: Color = color
		tint.a = clampf(smoothstep(0.0, 0.12, share) * (1.0 - smoothstep(0.82, 1.0, share)) * (0.75 + 0.25 * sin(_phase * 5.0 + index)), 0.0, 1.0)
		_motes.multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * (0.8 + 0.4 * tint.a)), at))
		_motes.multimesh.set_instance_color(index, tint)


## The ground's height under a spot: the seamless world's own ground, or the colliders straight down.
func _ground(at: Vector2, fallback: float) -> float:
	var level: LevelBase = get_tree().current_scene as LevelBase if is_inside_tree() else null
	if level is EverwoodWorld or level is OakshireVale:
		return WorldGridConfig.layout.sample_height(at.x, at.y)
	var world: World3D = get_world_3d()
	if world == null:
		return fallback
	var top: Vector3 = Vector3(at.x, fallback + 6.0, at.y)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 30.0, ActorBase.LAYER_WORLD)
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	return fallback if hit.is_empty() else (hit["position"] as Vector3).y
