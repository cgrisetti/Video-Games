## Miller's Oak (the World-Tree of docs/20 Part II §1.2, renamed in docs/23;
## the class keeps its old name) in The Crown's Summit Glade: the
## tallest thing for 5 km, so a 9-year-old navigates by it from every step on
## the island. A fluted, buttressed trunk; a warm golden spring at its roots;
## three canopy boughs that bloom one per trial (west Amber for the Anvil, north
## Sea-Azure for the Gale, east Twilight-Violet for the Tide) and Saffron
## heart-leaves. Each bough is one shader parameter (world_tree_bough.gdshader,
## `bloom`), shared with the far silhouette every other island shows, so a
## bloom is visible from North Quay the moment it happens.
class_name WorldTree
extends Node3D

signal bough_bloomed(trial: StringName)

const BOUGH_SHADER: Shader = preload("res://src/world/shaders/world_tree_bough.gdshader")
const TRUNK_HEIGHT: float = 36.0
const BLOOM_SECONDS: float = 3.0
## Each bough's centre (in the tree's frame) and radius: west, north, east, then the heart.
## (The northern bough rides highest, so from the south the heart-leaves sit in front of it, not over it.)
const BOUGH_SPOTS: Array[Vector4] = [Vector4(-15.0, 32.0, 2.0, 12.0), Vector4(0.0, 45.0, -10.0, 12.5), Vector4(15.0, 32.0, 2.0, 12.0)]
const HEART_SPOT: Vector4 = Vector4(0.0, 35.0, 8.0, 10.0)

static var _materials: Dictionary[StringName, ShaderMaterial] = {}

var _blooms: Dictionary[StringName, float] = {}


## The shared material of a trial's bough (&"heart" for the heart-leaves).
static func bough_material(trial: StringName) -> ShaderMaterial:
	if _materials.has(trial):
		return _materials[trial]
	var made: ShaderMaterial = ShaderMaterial.new()
	made.shader = BOUGH_SHADER
	var colors: Dictionary[StringName, Color] = {CalderaWorldState.TRIAL_ANVIL: CalderaKit.IRON_AMBER, CalderaWorldState.TRIAL_GALE: CalderaKit.GALE_AZURE,
		CalderaWorldState.TRIAL_TIDE: CalderaKit.TIDE_VIOLET, &"heart": CalderaKit.HEARTH_SAFFRON}
	made.set_shader_parameter(&"bloom_color", colors.get(trial, CalderaKit.HEARTH_SAFFRON))
	made.set_shader_parameter(&"bloom", 1.0 if trial == &"heart" else 0.0)
	if trial == &"heart":
		made.set_shader_parameter(&"leaf_color", Color(0.86, 0.72, 0.3))
		made.set_shader_parameter(&"glow", 0.35)
	_materials[trial] = made
	return made


## The far crown (lobes in the boughs' own materials) for the Crown's horizon silhouette.
static func make_far_crown() -> Node3D:
	var crown: Node3D = Node3D.new()
	crown.name = "WorldTreeFar"
	var trials: Array[StringName] = CalderaWorldState.TRIALS
	for index: int in 3:
		var spot: Vector4 = BOUGH_SPOTS[index]
		var lobe: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.stretched(ShapeKit.sphere("Bough%d" % index, spot.w, Vector3(spot.x, spot.y, spot.z),
			bough_material(trials[index])), Vector3(1.0, 0.7, 1.0)))
		crown.add_child(lobe)
	crown.add_child(ShapeKit.no_shadow(ShapeKit.stretched(ShapeKit.sphere("Heart", HEART_SPOT.w, Vector3(HEART_SPOT.x, HEART_SPOT.y, HEART_SPOT.z),
		bough_material(&"heart")), Vector3(1.0, 0.75, 1.0))))
	return crown


static func _bloom_target(trial: StringName) -> float:
	return 1.0 if CalderaWorldState.current != null and CalderaWorldState.current.trial_complete(trial) else 0.0


func _ready() -> void:
	add_to_group(&"map_glyphs")
	var bark: MeshInstance3D = MeshInstance3D.new()
	bark.name = "Trunk"
	bark.mesh = ShapeKit.make_gnarled_trunk_mesh(TRUNK_HEIGHT, 5.2, 2.0, 5, 41)
	bark.material_override = StorybookMaterial.make(Color(0.44, 0.35, 0.27))
	add_child(bark)
	CalderaKit.solid_cylinder(self, "TrunkBody", Vector3.ZERO, 4.6, 14.0)
	var trials: Array[StringName] = CalderaWorldState.TRIALS
	for index: int in 3:
		var spot: Vector4 = BOUGH_SPOTS[index]
		var bough: MeshInstance3D = MeshInstance3D.new()
		bough.name = "Bough_%s" % String(trials[index]).trim_prefix("trial_")
		bough.mesh = ShapeKit.make_leaf_cloud_crown(Vector3(spot.x, spot.y, spot.z), spot.w, 16, 300 + index, Color(0.55, 0.55, 0.55), Color(1.0, 1.0, 1.0))
		bough.material_override = bough_material(trials[index])
		add_child(bough)
		_blooms[trials[index]] = _bloom_target(trials[index])
		bough_material(trials[index]).set_shader_parameter(&"bloom", _blooms[trials[index]])
	var heart: MeshInstance3D = MeshInstance3D.new()
	heart.name = "HeartLeaves"
	heart.mesh = ShapeKit.make_leaf_cloud_crown(Vector3(HEART_SPOT.x, HEART_SPOT.y, HEART_SPOT.z), HEART_SPOT.w, 14, 377, Color(0.6, 0.6, 0.6), Color(1.0, 1.0, 1.0))
	heart.material_override = bough_material(&"heart")
	add_child(heart)
	# The warm golden spring at its roots.
	var spring: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.cylinder("GoldenSpring", 3.0, 3.0, 0.08, Vector3(7.5, 0.1, 6.0),
		StorybookMaterial.glowing(Color(1.0, 0.82, 0.4), 1.4)))
	add_child(spring)
	CalderaKit.plume(self, "SpringSteam", Vector3(7.5, 0.3, 6.0), Color(1.0, 0.95, 0.85, 0.45), 1.2, 2.0, 12)
	CalderaKit.light(self, "SpringGlow", Vector3(7.5, 1.4, 6.0), Color(1.0, 0.82, 0.42), 2.0, 12.0)
	if CalderaWorldState.current != null:
		CalderaWorldState.current.flag_changed.connect(_on_flag_changed)


func _exit_tree() -> void:
	if CalderaWorldState.current != null and CalderaWorldState.current.flag_changed.is_connected(_on_flag_changed):
		CalderaWorldState.current.flag_changed.disconnect(_on_flag_changed)


## How far a trial's bough has bloomed (0 to 1).
func bloom_of(trial: StringName) -> float:
	return _blooms.get(trial, 0.0)


## Snaps every bough to its flag (tests).
func settle() -> void:
	for trial: StringName in CalderaWorldState.TRIALS:
		_blooms[trial] = _bloom_target(trial)
		bough_material(trial).set_shader_parameter(&"bloom", _blooms[trial])


func _process(delta: float) -> void:
	for trial: StringName in CalderaWorldState.TRIALS:
		var target: float = _bloom_target(trial)
		var now: float = _blooms.get(trial, 0.0)
		if is_equal_approx(now, target):
			continue
		var next: float = move_toward(now, target, delta / BLOOM_SECONDS)
		_blooms[trial] = next
		bough_material(trial).set_shader_parameter(&"bloom", next)


func _on_flag_changed(flag: StringName, value: bool) -> void:
	for trial: StringName in CalderaWorldState.TRIALS:
		if CalderaWorldState.trial_flag(trial) == flag and value:
			bough_bloomed.emit(trial)
