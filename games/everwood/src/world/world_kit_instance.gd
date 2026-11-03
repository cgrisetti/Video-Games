## A placed world kit (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §4): a scene stores
## only the kit's id and options, and the kit builds itself from
## WorldAssetCatalog when it enters the tree (sharing the catalog's cached
## meshes), so the level files stay small and a curated .glb dropped into
## res://assets/models/world/ shows up everywhere the kit stands.
## A kit whose mesh is already cached appears at once; a new one waits its turn
## in a queue the WorldAtmosphereDirector works through a slice at a time
## (BUILD_BUDGET_USEC a frame), so a landblock streaming in never stalls a frame.
class_name WorldKitInstance
extends Node3D

@export var kit_id: StringName = &""
@export var variant: StringName = &""
@export var size: Vector3 = Vector3.ZERO
@export var tint: Color = Color(0.0, 0.0, 0.0, 0.0)
@export var accent: Color = Color(0.0, 0.0, 0.0, 0.0)
@export var height: float = 0.0
@export var seed_value: int = 0
@export var blossom: bool = false
@export var fade: bool = true
## Radians a second the kit's "Spinner" part turns about its local Z (a windmill's sails).
@export var spin_speed: float = 0.0

## Microseconds of kit building a frame.
const BUILD_BUDGET_USEC: int = 1500

## Build every kit the moment it enters the tree (the level builders, whose HLOD bakes read them at once).
static var immediate: bool = false
static var _waiting: Array[WorldKitInstance] = []

var kit: Node3D
var _spinner: Node3D


static func make(node_name: String, id: StringName, where: Vector3, yaw: float = 0.0, values: Dictionary = {}) -> WorldKitInstance:
	var made: WorldKitInstance = WorldKitInstance.new()
	made.name = node_name
	made.kit_id = id
	made.position = where
	made.rotation = Vector3(0.0, yaw, 0.0)
	for key: Variant in values:
		made.set(key, values[key])
	return made


func _ready() -> void:
	set_process(false)
	if kit != null or kit_id == &"":
		return
	if immediate or WorldAssetCatalog.is_cached(kit_id, options()):
		build()
	else:
		_waiting.append(self)


## Builds the kit now (if it isn't built).
func build() -> void:
	if kit != null or kit_id == &"":
		return
	kit = WorldAssetCatalog.build(kit_id, options())
	add_child(kit)
	_spinner = kit.get_node_or_null("Spinner") as Node3D
	set_process(_spinner != null and spin_speed != 0.0)


## Builds waiting kits for up to `budget_usec` (at least one); returns how many it built.
static func build_waiting(budget_usec: int = BUILD_BUDGET_USEC) -> int:
	var start: int = Time.get_ticks_usec()
	var built: int = 0
	while not _waiting.is_empty():
		var next: WorldKitInstance = _waiting.pop_front()
		if not is_instance_valid(next) or not next.is_inside_tree() or next.kit != null:
			continue
		next.build()
		built += 1
		if Time.get_ticks_usec() - start >= budget_usec:
			break
	return built


static func waiting_count() -> int:
	return _waiting.size()


func _process(delta: float) -> void:
	_spinner.rotate_object_local(Vector3.BACK, spin_speed * delta)


## The options WorldAssetCatalog.build() takes, from what's set here.
func options() -> Dictionary:
	var made: Dictionary = {}
	if variant != &"":
		made["variant"] = variant
	if size != Vector3.ZERO:
		made["size"] = size
	if tint.a > 0.0:
		made["color"] = tint
	if accent.a > 0.0:
		made["accent"] = accent
	if height > 0.0:
		made["height"] = height
	if seed_value != 0:
		made["seed"] = seed_value
	if blossom:
		made["blossom"] = true
	if not fade:
		made["fade"] = false
	return made
