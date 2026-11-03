## A primed enemy's Sign, readable from the 4.8 m split-screen camera
## (11_COMBAT_ONBOARDING_AND_FEEL_GDD.md §4.2, Layer 3): a 2.5 m Sign Ring
## turning flat on the ground beneath it, and a floating badge 2.2 m above its
## head in the Sign's colour with the seal's name and a countdown arc that
## empties as the seal runs out. CombatDirector puts one on every peer when a
## seal lands and takes it off when it's detonated, replaced or runs out.
## A detonation also bursts a 1.5 m shockwave torus (shockwave()).
class_name SignMark
extends Node3D

const RING_RADIUS: float = 1.25
## A big foe's ring sits at least this far outside its body, so it isn't hidden.
const RING_CLEARANCE: float = 0.6
const RING_WIDTH: float = 0.12
const RING_SPIN: float = 1.4
const RING_LIFT: float = 0.06
const RING_TICKS: int = 4
const BADGE_HEIGHT: float = 2.2
const BADGE_RADIUS: float = 0.6
const ARC_WIDTH: float = 0.11
const ARC_SEGMENTS: int = 32
const GLOW: float = 2.2
## The shockwave grows to this radius over this long.
const SHOCKWAVE_RADIUS: float = 1.5
const SHOCKWAVE_TIME: float = 0.3
## A Sign-Flow ground ring fades over this long.
const GROUND_RING_TIME: float = 0.9

var target: ActorBase
var scribe_sign: int = ScribeSignResource.Sign.NONE
var duration: float = 8.0

var _left: float = 0.0
var _color: Color = Color.WHITE
var _ring: Node3D
var _badge: Node3D
var _arc: MeshInstance3D
var _arc_mesh: ImmediateMesh
var _arc_material: StandardMaterial3D


func configure(on: ActorBase, sign_id: int, seconds: float) -> void:
	target = on
	scribe_sign = sign_id
	duration = maxf(0.1, seconds)
	_left = duration


func _ready() -> void:
	name = "SignMark"
	var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(scribe_sign)
	_color = seal.color
	var glowing: StandardMaterial3D = _glowing_material(_color)
	_ring = Node3D.new()
	_ring.name = "SignRing"
	add_child(_ring)
	# 2.5 m across, or wider round a foe as big as the Cairnsman.
	_ring.scale = Vector3.ONE * ring_radius() / RING_RADIUS
	var band: MeshInstance3D = MeshInstance3D.new()
	band.name = "Band"
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = RING_RADIUS - RING_WIDTH
	torus.outer_radius = RING_RADIUS
	torus.rings = 40
	torus.ring_segments = 6
	torus.material = glowing
	band.mesh = torus
	band.scale = Vector3(1.0, 0.25, 1.0)
	band.position = Vector3(0.0, RING_LIFT, 0.0)
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.add_child(band)
	# Glyph ticks round the ring, so its turning reads.
	for index: int in RING_TICKS:
		var angle: float = TAU * index / RING_TICKS
		var tick: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(0.12, 0.03, 0.42)
		box.material = glowing
		tick.mesh = box
		tick.position = Vector3(cos(angle), 0.0, sin(angle)) * (RING_RADIUS - RING_WIDTH * 0.5) + Vector3.UP * RING_LIFT
		tick.rotation.y = -angle
		tick.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_ring.add_child(tick)

	_badge = Node3D.new()
	_badge.name = "Badge"
	add_child(_badge)
	var label: Label3D = Label3D.new()
	label.name = "SealName"
	label.text = seal.display_name.to_upper()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 48
	label.outline_size = 14
	label.pixel_size = 0.009
	label.modulate = _color.lightened(0.3)
	label.position = Vector3(0.0, BADGE_RADIUS + 0.22, 0.0)
	_badge.add_child(label)
	# The badge: a bright disc of the Sign's colour inside its countdown arc,
	# both always facing the camera.
	var disc: MeshInstance3D = MeshInstance3D.new()
	disc.name = "Disc"
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE * BADGE_RADIUS * 1.2
	var disc_material: StandardMaterial3D = _glowing_material(_color)
	disc_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = disc_material
	disc.mesh = quad
	disc.rotation_degrees = Vector3(0.0, 0.0, 45.0)
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_badge.add_child(disc)
	_arc_mesh = ImmediateMesh.new()
	_arc = MeshInstance3D.new()
	_arc.name = "CountdownArc"
	_arc.mesh = _arc_mesh
	_arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_arc_material = _glowing_material(_color.lightened(0.45))
	_arc_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_arc_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_badge.add_child(_arc)
	_follow()
	_draw_arc()


## The ring's radius on the ground: 1.25 m, or just outside a bigger foe's body.
func ring_radius() -> float:
	if not is_instance_valid(target):
		return RING_RADIUS
	return maxf(RING_RADIUS, target.body_radius() + RING_CLEARANCE)


## The share of the seal's time still left, 1 to 0.
func time_left_ratio() -> float:
	return clampf(_left / duration, 0.0, 1.0)


func _process(delta: float) -> void:
	_left -= delta
	# Gone when it runs out, or its foe falls or streams out with its Landblock.
	if _left <= 0.0 or not is_instance_valid(target) or not target.is_inside_tree() or target.stats == null or target.stats.is_downed:
		queue_free()
		return
	_ring.rotation.y += RING_SPIN * delta
	_follow()
	_draw_arc()


func _follow() -> void:
	if not is_instance_valid(target) or not target.is_inside_tree():
		return
	var feet: Vector3 = target.global_position
	_ring.global_position = feet
	_badge.global_position = feet + Vector3.UP * (target.body_height() + BADGE_HEIGHT)


## The countdown arc: a band round the badge from 12 o'clock, shrinking as the seal runs out.
func _draw_arc() -> void:
	_arc_mesh.clear_surfaces()
	var segments: int = maxi(1, roundi(ARC_SEGMENTS * time_left_ratio()))
	_arc_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _arc_material)
	for index: int in segments + 1:
		var angle: float = PI * 0.5 - TAU * time_left_ratio() * float(index) / float(segments)
		var direction: Vector3 = Vector3(cos(angle), sin(angle), 0.0)
		_arc_mesh.surface_add_vertex(direction * BADGE_RADIUS)
		_arc_mesh.surface_add_vertex(direction * (BADGE_RADIUS + ARC_WIDTH))
	_arc_mesh.surface_end()


static func _glowing_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = GLOW
	material.no_depth_test = false
	return material


## A Sign detonation's crisp shockwave: a torus of the seal's colour bursting
## out to 1.5 m around the target, then gone.
static func shockwave(parent: Node3D, at: Vector3, color: Color) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var wave: MeshInstance3D = MeshInstance3D.new()
	wave.name = "SignShockwave"
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.86
	torus.outer_radius = 1.0
	torus.rings = 40
	torus.material = _glowing_material(color)
	wave.mesh = torus
	wave.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(wave)
	wave.global_position = at + Vector3.UP * 0.8
	wave.scale = Vector3.ONE * 0.2
	var tween: Tween = wave.create_tween()
	tween.tween_property(wave, "scale", Vector3(SHOCKWAVE_RADIUS, 0.5, SHOCKWAVE_RADIUS), SHOCKWAVE_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_callback(wave.queue_free)


## A Sign-Flow cast's 2.5 m Sign ring (14 GDD §2): stamped flat on the ground
## under the hero in the Sign's colour, turning once as it fades.
static func ground_ring(parent: Node3D, at: Vector3, color: Color, radius: float) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.name = "SignFlowRing"
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = radius - RING_WIDTH * 1.4
	torus.outer_radius = radius
	torus.rings = 48
	torus.ring_segments = 6
	var material: StandardMaterial3D = _glowing_material(color)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	torus.material = material
	ring.mesh = torus
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ring)
	ring.global_position = at + Vector3.UP * RING_LIFT
	ring.scale = Vector3(1.0, 0.25, 1.0)
	var tween: Tween = ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "rotation:y", PI, GROUND_RING_TIME)
	tween.tween_property(material, "albedo_color:a", 0.0, GROUND_RING_TIME).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(ring.queue_free)
