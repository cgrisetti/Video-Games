## A Hush-Crack in the turf, and the Lulled Cairn it becomes
## (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §2.2, §4.2 kit_hush_crack_and_cairn;
## 18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §5).
## While ZONE_HUSHED it is a dark sunken trench with 7 to 11 jagged slate shards
## leaning out of it and six pale weeping root-tendrils, a slate-violet ring
## breathing round it on the ground and ash motes falling upward, as if gravity
## ran backward; for 22 m round it the First-Quiet drinks the world: 85% of the
## warm colour drains toward ashen slate-indigo under a rim of hoar-rime, the
## wind freezes and the grass lies pressed flat (the WorldAtmosphereDirector
## hands its blight to every world shader; a Lantern-Bearer's halo pushes it
## back). When its camp is cleared (ZONE_RECLAIMED) the blight shrinks away under
## a 2.5 s golden-emerald Reclamation Bloom, the shards sink into the earth and a
## mossy, heather-crowned cairn rises with its Saffron-Gold Way-Lantern, ringed by
## forty-two wildflowers, with fireflies, and the wind comes back. MinionCamp and MobSpawner carry one and tell it when their
## camp is cleared; the state is theirs to remember (WorldStateDB), so a cleared
## camp streams back in as a cairn.
class_name HushCrackLandmark
extends Node3D

signal state_changed(state: int)

const Succession = ZoneSuccessionVisualResource.SuccessionState
const HUSH_RADIUS: float = ZoneBiomeResource.DEFAULT_HUSH_RADIUS_M
const PATH_LIGHT_COLOR: Color = Color(1.0, 0.8, 0.45)
const HUSH_MOTE_COLOR: Color = Color(0.58, 0.64, 0.72, 0.55)
## Ash rising from the fissure (reverse gravity, 18 GDD §5 layer 3): slate-grey flakes drifting up.
const ASH_COLOR: Color = Color(0.36, 0.38, 0.45, 0.8)
const ASH_RISE: float = 0.32
## The breathing ring on the ground round the fissure.
const RING_SHADER: Shader = preload("res://src/world/shaders/hush_ring_pulse.gdshader")
const RING_COLOR: Color = Color(0.42, 0.37, 0.6)
const RING_RADIUS: float = 2.6
const RING_PLANE: float = 6.4
## How far the shards sink into the earth as the cairn rises.
const SHARD_SINK_M: float = 2.1
const FIREFLY_COLOR: Color = Color(1.0, 0.86, 0.4)

## The camp's WorldStateDB id (or its node name): what set_succession_state() calls it.
@export var crack_id: StringName = &""

var state: int = Succession.ZONE_HUSHED
## The blight's reach now (22 m open, shrinking to 0 as it's reclaimed).
var hush_radius: float = HUSH_RADIUS

var _crack: Node3D
var _cairn: Node3D
var _motes: CPUParticles3D
var _ash: CPUParticles3D
var _ring: MeshInstance3D
var _fireflies: CPUParticles3D
var _path_light: OmniLight3D
var _change_left: float = 0.0
var _change_time: float = 1.0


func _enter_tree() -> void:
	if crack_id == &"":
		crack_id = StringName(String(get_parent().name if get_parent() != null else name).to_snake_case())
	var director: WorldAtmosphereDirector = WorldAtmosphereDirector.current
	if director != null:
		director.register_crack(self)


func _exit_tree() -> void:
	var director: WorldAtmosphereDirector = WorldAtmosphereDirector.current
	if director != null:
		director.unregister_crack(self)


func _ready() -> void:
	_crack = WorldAssetCatalog.build(WorldVisualCatalog.KIT_HUSH_CRACK_AND_CAIRN, {"variant": &"CRACK"})
	_crack.name = "Crack"
	add_child(_crack)
	_cairn = WorldAssetCatalog.build(WorldVisualCatalog.KIT_HUSH_CRACK_AND_CAIRN, {"variant": &"CAIRN"})
	_cairn.name = "Cairn"
	add_child(_cairn)
	_motes = _particles("HushMotes", HUSH_MOTE_COLOR, 18, 5.0, Vector3(1.6, 0.1, 0.3), 0.12, 0.05)
	add_child(_motes)
	_ash = _particles("AshMotes", ASH_COLOR, 26, 6.0, Vector3(1.4, 0.05, 0.35), 0.05, 0.035)
	_ash.gravity = Vector3(0.0, ASH_RISE, 0.0)
	_ash.spread = 20.0
	_ash.angular_velocity_min = -60.0
	_ash.angular_velocity_max = 60.0
	_ash.position = Vector3(0.0, -0.2, 0.0)
	var flake: QuadMesh = QuadMesh.new()
	flake.size = Vector2(0.07, 0.05)
	flake.material = (_ash.mesh as SphereMesh).material
	(flake.material as StandardMaterial3D).billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	(flake.material as StandardMaterial3D).emission_energy_multiplier = 0.4
	_ash.mesh = flake
	add_child(_ash)
	_ring = MeshInstance3D.new()
	_ring.name = "HushRing"
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(RING_PLANE, RING_PLANE)
	var ring_material: ShaderMaterial = ShaderMaterial.new()
	ring_material.shader = RING_SHADER
	ring_material.set_shader_parameter(&"ring_color", RING_COLOR)
	ring_material.set_shader_parameter(&"ring_radius", RING_RADIUS)
	ring_material.set_shader_parameter(&"plane_size", RING_PLANE)
	plane.material = ring_material
	_ring.mesh = plane
	_ring.position = Vector3(0.0, 0.06, 0.0)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	_fireflies = _particles("Fireflies", FIREFLY_COLOR, 10, 3.0, Vector3(1.6, 0.6, 1.6), 0.25, 0.04)
	_fireflies.position = Vector3(0.0, 0.8, 0.0)
	add_child(_fireflies)
	_path_light = WorldAssetCatalog.light("PathLight", PATH_LIGHT_COLOR, 0.0, 4.5)
	_path_light.position = Vector3(0.0, 1.6, 0.0)
	add_child(_path_light)
	_show(1.0)


## Moves to a succession state; `live` plays the change (and its bloom), otherwise it's there at once.
func set_state(new_state: int, live: bool) -> void:
	if new_state == state and _change_left <= 0.0:
		_record()
		return
	state = new_state
	var duration: float = WorldVisualCatalog.succession(Succession.ZONE_RECLAIMED).reclamation_bloom_duration_sec
	if live and is_inside_tree() and state != Succession.ZONE_HUSHED:
		_change_time = duration
		_change_left = duration
		var director: WorldAtmosphereDirector = WorldAtmosphereDirector.current
		if director != null:
			director.bloom_at(global_position)
	else:
		_change_left = 0.0
		hush_radius = HUSH_RADIUS if state == Succession.ZONE_HUSHED else 0.0
		if _crack != null:
			_show(1.0)
	_record()
	state_changed.emit(state)


func is_hushed() -> bool:
	return state == Succession.ZONE_HUSHED


func _process(delta: float) -> void:
	if _change_left <= 0.0:
		return
	_change_left = maxf(0.0, _change_left - delta)
	_show(1.0 - _change_left / _change_time)


## Shows the crack (hushed) or the cairn (reclaimed or weathering), `progress` of the way through the change.
func _show(progress: float) -> void:
	var hushed: bool = state == Succession.ZONE_HUSHED
	var shown: float = 0.0 if hushed else ease(progress, 0.5)
	hush_radius = HUSH_RADIUS if hushed else HUSH_RADIUS * (1.0 - progress)
	# The shards sink into the earth as the cairn rises out of it.
	_crack.visible = shown < 0.99
	_crack.scale = Vector3(1.0, maxf(0.01, 1.0 - shown * 0.6), 1.0)
	_crack.position.y = -SHARD_SINK_M * shown
	_cairn.visible = shown > 0.01
	_cairn.scale = Vector3.ONE * maxf(0.01, shown)
	_cairn.position.y = -0.6 * (1.0 - shown)
	_motes.emitting = hushed
	_ash.emitting = hushed
	_ring.visible = shown < 0.99
	((_ring.mesh as PlaneMesh).material as ShaderMaterial).set_shader_parameter(&"strength", 1.0 - shown)
	_fireflies.emitting = not hushed
	_path_light.light_energy = 0.9 * shown


func _record() -> void:
	var director: WorldAtmosphereDirector = WorldAtmosphereDirector.current
	if director != null:
		director.note_state(crack_id, state)


static func _particles(particles_name: String, color: Color, amount: int, lifetime: float, box: Vector3, speed: float, size: float) -> CPUParticles3D:
	var made: CPUParticles3D = CPUParticles3D.new()
	made.name = particles_name
	made.amount = amount
	made.lifetime = lifetime
	made.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	made.emission_box_extents = box
	made.direction = Vector3.UP
	made.spread = 35.0
	made.gravity = Vector3(0.0, 0.03, 0.0)
	made.initial_velocity_min = speed * 0.5
	made.initial_velocity_max = speed
	var mote: SphereMesh = SphereMesh.new()
	mote.radius = size
	mote.height = size * 2.0
	mote.radial_segments = 6
	mote.rings = 3
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = 1.5
	mote.material = material
	made.mesh = mote
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return made
