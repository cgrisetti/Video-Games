## A portal between instances (Hub Town to the Dungeon Dojo and back). When
## every standing party member is on its platform, a short countdown runs and
## the host moves the whole party through the InstanceManager. Every peer shows
## the count; only the host acts on it. After a victory the portal can also
## call the party home on its own (recall).
class_name RaidPortal
extends Node3D

signal countdown_started
signal party_entered(target: StringName)

const RADIUS: float = 2.6
const COUNTDOWN: float = 3.0
const RING_RADIUS: float = 1.7
const RING_HEIGHT: float = 2.1
const SPIN_SPEED: float = 0.9
const FLOOR_OFFSET: float = 0.03

## The InstanceManager id this portal leads to.
@export var target_instance: StringName = &""
@export var title: String = "Raid Portal"
@export var portal_color: Color = Color(0.45, 0.62, 1.0)

var countdown_left: float = -1.0

var _recall_left: float = -1.0

var _ring: MeshInstance3D
var _veil_material: StandardMaterial3D
var _status_label: Label3D


func _ready() -> void:
	var glow: StandardMaterial3D = StandardMaterial3D.new()
	glow.albedo_color = portal_color
	glow.emission_enabled = true
	glow.emission = portal_color
	glow.emission_energy_multiplier = 2.2
	var platform_mesh: CylinderMesh = CylinderMesh.new()
	platform_mesh.top_radius = RADIUS
	platform_mesh.bottom_radius = RADIUS
	platform_mesh.height = 0.06
	platform_mesh.radial_segments = 48
	var platform_material: StandardMaterial3D = StandardMaterial3D.new()
	platform_material.albedo_color = portal_color.darkened(0.55)
	platform_material.emission_enabled = true
	platform_material.emission = portal_color.darkened(0.4)
	platform_mesh.material = platform_material
	var platform: MeshInstance3D = MeshInstance3D.new()
	platform.name = "Platform"
	platform.mesh = platform_mesh
	platform.position = Vector3(0.0, FLOOR_OFFSET, 0.0)
	add_child(platform)
	var rim_mesh: TorusMesh = TorusMesh.new()
	rim_mesh.inner_radius = RADIUS - 0.12
	rim_mesh.outer_radius = RADIUS
	rim_mesh.material = glow
	var rim: MeshInstance3D = MeshInstance3D.new()
	rim.name = "Rim"
	rim.mesh = rim_mesh
	rim.position = Vector3(0.0, FLOOR_OFFSET + 0.05, 0.0)
	add_child(rim)
	# A standing ring with a shimmering veil: the "door" you walk into.
	var ring_mesh: TorusMesh = TorusMesh.new()
	ring_mesh.inner_radius = RING_RADIUS - 0.16
	ring_mesh.outer_radius = RING_RADIUS
	ring_mesh.material = glow
	_ring = MeshInstance3D.new()
	_ring.name = "Ring"
	_ring.mesh = ring_mesh
	_ring.position = Vector3(0.0, RING_HEIGHT, 0.0)
	_ring.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	add_child(_ring)
	_veil_material = StandardMaterial3D.new()
	_veil_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_veil_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_veil_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_veil_material.albedo_color = Color(portal_color, 0.3)
	var veil_mesh: CylinderMesh = CylinderMesh.new()
	veil_mesh.top_radius = RING_RADIUS - 0.16
	veil_mesh.bottom_radius = RING_RADIUS - 0.16
	veil_mesh.height = 0.02
	veil_mesh.material = _veil_material
	var veil: MeshInstance3D = MeshInstance3D.new()
	veil.name = "Veil"
	veil.mesh = veil_mesh
	_ring.add_child(veil)
	for child: Node in get_children():
		(child as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var title_label: Label3D = _make_label(title, 56, RING_HEIGHT + RING_RADIUS + 0.7)
	title_label.modulate = portal_color.lightened(0.4)
	add_child(title_label)
	_status_label = _make_label("", 40, RING_HEIGHT + RING_RADIUS + 0.2)
	add_child(_status_label)


func _make_label(text: String, size: int, height: float) -> Label3D:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font_size = size
	label.outline_size = 10
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0.0, height, 0.0)
	return label


func contains(point: Vector3) -> bool:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length() <= RADIUS


## Standing (not downed) party members, and how many of them are on the platform.
func party_on_platform() -> Vector2i:
	var standing: Array[ActorBase] = CombatDirector.current.alive_party()
	var inside: int = 0
	for member: ActorBase in standing:
		if contains(member.global_position):
			inside += 1
	return Vector2i(inside, standing.size())


## Takes the whole party through in `seconds`, wherever they're standing.
func recall(seconds: float) -> void:
	if _recall_left < 0.0:
		AudioCues.play(&"portal_charge")
	_recall_left = seconds


func is_recalling() -> bool:
	return _recall_left >= 0.0


func _physics_process(delta: float) -> void:
	_ring.rotate_object_local(Vector3.FORWARD, SPIN_SPEED * delta)
	if _recall_left >= 0.0:
		_update_recall(delta)
		return
	var count: Vector2i = party_on_platform()
	var everyone: bool = count.y > 0 and count.x == count.y and InstanceManager.current.is_live()
	if not everyone:
		countdown_left = -1.0
		_veil_material.albedo_color.a = 0.3
		_status_label.text = "Stand here together: %d/%d" % [count.x, count.y]
		return
	if countdown_left < 0.0:
		countdown_left = COUNTDOWN
		countdown_started.emit()
		AudioCues.play(&"portal_charge")
	countdown_left -= delta
	_veil_material.albedo_color.a = 0.3 + 0.5 * (1.0 - countdown_left / COUNTDOWN)
	_status_label.text = "Entering in %d…" % maxi(1, ceili(countdown_left))
	if countdown_left <= 0.0:
		countdown_left = -1.0
		party_entered.emit(target_instance)
		InstanceManager.current.change_instance(target_instance)


func _update_recall(delta: float) -> void:
	_recall_left -= delta
	_veil_material.albedo_color.a = 0.8
	_status_label.text = "Going home in %d…" % maxi(1, ceili(_recall_left))
	if _recall_left <= 0.0:
		_recall_left = -1.0
		party_entered.emit(target_instance)
		InstanceManager.current.change_instance(target_instance)
