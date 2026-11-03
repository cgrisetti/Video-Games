## A Hush-Crack in the turf, and the Lulled Cairn it becomes
## (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §2.2, §4.2 kit_hush_crack_and_cairn).
## While ZONE_HUSHED it is a jagged root-and-earth fissure breathing slow
## slate-grey hush-motes, and the turf for 18 m round it greys toward slate
## (the WorldAtmosphereDirector hands its hush to every world shader). When its
## camp is cleared (ZONE_RECLAIMED) the hush shrinks away under a 2.5 s
## golden-emerald Reclamation Bloom, the fissure sinks, and a mossy,
## heather-crowned cairn rises ringed by golden flowers, with a warm path-light
## and fireflies. MinionCamp and MobSpawner carry one and tell it when their
## camp is cleared; the state is theirs to remember (WorldStateDB), so a cleared
## camp streams back in as a cairn.
class_name HushCrackLandmark
extends Node3D

signal state_changed(state: int)

const Succession = ZoneSuccessionVisualResource.SuccessionState
const HUSH_RADIUS: float = ZoneBiomeResource.DEFAULT_HUSH_RADIUS_M
const PATH_LIGHT_COLOR: Color = Color(1.0, 0.8, 0.45)
const HUSH_MOTE_COLOR: Color = Color(0.58, 0.64, 0.72, 0.55)
const FIREFLY_COLOR: Color = Color(1.0, 0.86, 0.4)

## The camp's WorldStateDB id (or its node name): what set_succession_state() calls it.
@export var crack_id: StringName = &""

var state: int = Succession.ZONE_HUSHED
## The hush's reach now (18 m open, shrinking to 0 as it's reclaimed).
var hush_radius: float = HUSH_RADIUS

var _crack: Node3D
var _cairn: Node3D
var _motes: CPUParticles3D
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
	_crack.visible = shown < 0.99
	_crack.scale = Vector3(1.0, maxf(0.01, 1.0 - shown), 1.0)
	_crack.position.y = -0.3 * shown
	_cairn.visible = shown > 0.01
	_cairn.scale = Vector3.ONE * maxf(0.01, shown)
	_motes.emitting = hushed
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
