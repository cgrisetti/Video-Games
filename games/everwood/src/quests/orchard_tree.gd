## A grove's oldest cider-bough (Q02; docs/28 §4.3): the tree its Grey-Bark
## Weevils go for. Each weevil gnawing at its trunk takes bark; with none on it
## the tree mends. Felled to nothing (the brief's "Orchard Tree HP at 0"), its
## grove starts again: the tree mends whole and its weevils come back. A ring
## round its foot shows its bark, green to grey.
class_name OrchardTree
extends Node3D

signal felled(tree: OrchardTree)

const GROUP: StringName = &"orchard_trees"
const MAX_BARK: float = 100.0
## How close a weevil must be to gnaw, past the trunk.
const GNAW_REACH: float = 1.8
## Bark each gnawing weevil takes a second, and what the tree mends with none on it.
const GNAW_PER_SECOND: float = 3.0
const MEND_PER_SECOND: float = 2.0
const HEALTHY: Color = Color(0.42, 0.8, 0.36, 0.7)
const BLIGHTED: Color = Color(0.6, 0.6, 0.58, 0.7)

var bark: float = MAX_BARK
var trunk_radius: float = 0.4
## Only a grove under way is gnawed (OrchardGrove turns it on).
var protected: bool = false
var gnawers: int = 0
var times_felled: int = 0

var _ring: MeshInstance3D
var _ring_material: StandardMaterial3D


## The nearest gnawable tree within `within` metres of `at`, or null.
static func nearest(at: Vector3, within: float) -> OrchardTree:
	var tree_root: SceneTree = Engine.get_main_loop() as SceneTree
	if tree_root == null:
		return null
	var best: OrchardTree = null
	var best_distance: float = within
	for node: Node in tree_root.get_nodes_in_group(GROUP):
		var tree: OrchardTree = node as OrchardTree
		if tree == null or not tree.protected:
			continue
		var distance: float = Vector2(tree.global_position.x - at.x, tree.global_position.z - at.z).length()
		if distance <= best_distance:
			best_distance = distance
			best = tree
	return best


func _ready() -> void:
	add_to_group(GROUP)
	_ring_material = StandardMaterial3D.new()
	_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_material.albedo_color = HEALTHY
	_ring = MeshInstance3D.new()
	_ring.name = "BarkRing"
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = trunk_radius + 0.5
	torus.outer_radius = trunk_radius + 0.75
	_ring.mesh = torus
	_ring.scale = Vector3(1.0, 0.2, 1.0)
	_ring.position = Vector3(0.0, 0.08, 0.0)
	_ring.material_override = _ring_material
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	_refresh()


func _physics_process(delta: float) -> void:
	_ring.visible = protected
	if not protected or not NetworkManager.current.is_host():
		return
	gnawers = 0
	for enemy: ActorBase in CombatDirector.current.enemies():
		var mob: WildMob = enemy as WildMob
		if mob == null or mob.stats.is_downed or not mob.variant.targets_trees:
			continue
		var flat: float = Vector2(mob.global_position.x - global_position.x, mob.global_position.z - global_position.z).length()
		if flat <= trunk_radius + mob.body_radius() + GNAW_REACH:
			gnawers += 1
	if gnawers > 0:
		bark -= GNAW_PER_SECOND * float(gnawers) * delta
		if bark <= 0.0:
			bark = MAX_BARK
			times_felled += 1
			felled.emit(self)
	else:
		bark = minf(MAX_BARK, bark + MEND_PER_SECOND * delta)
	_refresh()


## Host: takes bark at once (tests, and a grove's scripted pressure).
func gnaw(amount: float) -> void:
	bark -= amount
	if bark <= 0.0:
		bark = MAX_BARK
		times_felled += 1
		felled.emit(self)
	_refresh()


func _refresh() -> void:
	if _ring_material != null:
		_ring_material.albedo_color = BLIGHTED.lerp(HEALTHY, clampf(bark / MAX_BARK, 0.0, 1.0))
