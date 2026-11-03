## One architectural or landscape kit (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md
## §4, §7.1 B): what it is, how big, whether it's knee-high scenery the
## cameras look past (the LowScenery layer), whether its upper parts fade out of
## a camera's sightline, and where a curated model would replace it.
## Pure data; WorldVisualCatalog registers them and WorldAssetCatalog builds them.
class_name WorldPropKitResource
extends Resource

@export var kit_id: StringName = &"kit_house_stepped_gable"
@export var display_name: String = "Stepped-Gable House"
## &"ARCHITECTURE", &"STATION", &"BRIDGE", &"TREE", &"LANDSCAPE" or &"GARDEN".
@export var category: StringName = &"ARCHITECTURE"
@export var bounding_size: Vector3 = Vector3(8.0, 7.5, 6.0)
@export var is_low_scenery: bool = false ## True for <= 0.9m walls/rails on LowScenery layer
@export var enable_sightline_fade: bool = true ## Dither-fades geometry > 3.2m when blocking camera
@export var glb_override_path: String = "res://assets/models/world/kit_house_stepped_gable.glb"
