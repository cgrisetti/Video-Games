## A clay Wind-Lantern hanging from the Sunken Holloway's root arches
## (07_EXPEDITION_HUD_AND_ART_GDD.md §3, Zone 1). It sways on its cord, and when
## a player brushes past (or a Scribe Card is cast nearby) it swings, chimes and
## sheds a puff of golden motes. Each peer reacts to what it sees: it's only
## for looks and sound.
class_name WindLantern
extends Node3D

## A player this close (on the ground, in any direction) brushes it.
const BRUSH_RADIUS: float = 2.4
## A card cast this close makes it ring too.
const CARD_RADIUS: float = 5.0
const COOLDOWN: float = 2.0
const CORD_LENGTH: float = 1.1
const SWAY: float = 0.08
const SWING: float = 0.45
const SWING_DAMPING: float = 2.2
const CLAY_COLOR: Color = Color(0.72, 0.45, 0.3)
const GLOW_COLOR: Color = Color(1.0, 0.78, 0.38)
const MOTE_COLOR: Color = Color(1.0, 0.85, 0.4)

var chimes: int = 0

var _pivot: Node3D
var _motes: CPUParticles3D
var _cooldown: float = 0.0
var _swing: float = 0.0
var _age: float = 0.0


func _ready() -> void:
	_age = position.x * 1.7 + position.z * 0.9
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)
	var cord: MeshInstance3D = _cylinder(0.015, CORD_LENGTH, Color(0.25, 0.2, 0.15), 0.0)
	cord.position = Vector3(0.0, -CORD_LENGTH * 0.5, 0.0)
	_pivot.add_child(cord)
	var body: MeshInstance3D = _cylinder(0.17, 0.36, CLAY_COLOR, 0.0)
	(body.mesh as CylinderMesh).top_radius = 0.12
	body.position = Vector3(0.0, -CORD_LENGTH - 0.18, 0.0)
	_pivot.add_child(body)
	var flame: MeshInstance3D = _cylinder(0.1, 0.16, GLOW_COLOR, 3.0)
	flame.position = Vector3(0.0, -CORD_LENGTH - 0.2, 0.0)
	_pivot.add_child(flame)
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "Light"
	light.light_color = GLOW_COLOR
	light.light_energy = 0.9
	light.omni_range = 3.5
	light.position = Vector3(0.0, -CORD_LENGTH - 0.3, 0.0)
	_pivot.add_child(light)
	_motes = CPUParticles3D.new()
	_motes.name = "Motes"
	_motes.position = Vector3(0.0, -CORD_LENGTH - 0.2, 0.0)
	_motes.emitting = false
	_motes.one_shot = true
	_motes.explosiveness = 0.9
	_motes.amount = 14
	_motes.lifetime = 1.4
	_motes.direction = Vector3.DOWN
	_motes.spread = 70.0
	_motes.initial_velocity_min = 0.4
	_motes.initial_velocity_max = 1.1
	_motes.gravity = Vector3(0.0, -0.4, 0.0)
	var mote: SphereMesh = SphereMesh.new()
	mote.radius = 0.04
	mote.height = 0.08
	var mote_material: StandardMaterial3D = StandardMaterial3D.new()
	mote_material.albedo_color = MOTE_COLOR
	mote_material.emission_enabled = true
	mote_material.emission = MOTE_COLOR
	mote_material.emission_energy_multiplier = 3.0
	mote.material = mote_material
	_motes.mesh = mote
	_pivot.add_child(_motes)
	CombatDirector.current.card_invoked.connect(_on_card_invoked)


func _exit_tree() -> void:
	var director: CombatDirector = CombatDirector.current
	if director != null and director.card_invoked.is_connected(_on_card_invoked):
		director.card_invoked.disconnect(_on_card_invoked)


func _process(delta: float) -> void:
	_age += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	_swing = move_toward(_swing, 0.0, SWING_DAMPING * delta * maxf(0.2, absf(_swing)))
	_pivot.rotation = Vector3(sin(_age * 1.3) * SWAY + _swing * sin(_age * 7.0), 0.0, cos(_age * 1.1) * SWAY * 0.7)
	if _cooldown > 0.0:
		return
	for member: ActorBase in CombatDirector.current.party_actors():
		var lamp: Vector3 = global_position + Vector3.DOWN * CORD_LENGTH
		var flat: Vector2 = Vector2(member.global_position.x - lamp.x, member.global_position.z - lamp.z)
		if flat.length() <= BRUSH_RADIUS:
			chime()
			return


## Swing, ring and shed motes.
func chime() -> void:
	if _cooldown > 0.0:
		return
	_cooldown = COOLDOWN
	_swing = SWING
	chimes += 1
	_motes.restart()
	AudioCues.play(&"lantern", randf_range(0.9, 1.2), -4.0)


func _on_card_invoked(caster: ActorBase, _action: CombatActionResource, _variant: int) -> void:
	if is_instance_valid(caster) and caster.global_position.distance_to(global_position) <= CARD_RADIUS + CORD_LENGTH:
		chime()


func _cylinder(radius: float, height: float, color: Color, glow: float) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	mesh.material = material
	var node: MeshInstance3D = MeshInstance3D.new()
	node.mesh = mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
