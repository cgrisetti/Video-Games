## How every Label3D in the world reads (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §6.2):
## sized in the world (never fixed to the screen, so a sign shrinks with distance
## like the sign it is), 32 px text with an 8 px outline at 0.0042 m a pixel,
## shown from 1.8 m to 24 m from a camera and fading itself out past that.
## Signs that belong to the world rather than to a character (station signs,
## plaques, place names) sit on their own visual layer, which a PlayerCamera
## drops while its player has a modal open (the Binder, the Scribery, the Atlas).
##
## LevelBase applies it to every Label3D as it enters the tree (watch()), so a
## sign built by any script or baked into a scene reads the same. The one
## exception keeps OWN_STYLE_META: an enemy's level and danger badge
## (EnemyNameplate, 13_PLAYTEST §2.14), held to the screen so it reads at a glance.
class_name WorldLabelStyle
extends RefCounted

const PIXEL_SIZE: float = 0.0042
const FONT_SIZE: int = 32
const OUTLINE_SIZE: int = 8
const VISIBLE_FROM_M: float = 1.8
const VISIBLE_TO_M: float = 24.0
## The fade past VISIBLE_TO_M (and in under VISIBLE_FROM_M).
const FADE_OUT_MARGIN_M: float = 3.0
const FADE_IN_MARGIN_M: float = 0.4
## The visual layer world signs are on (cameras drop it while their modal is open).
const STATION_LABEL_LAYER: int = 12
## Set on a label that's styled (so it's styled once).
const STYLED_META: StringName = &"world_label_styled"
## Set on a label that keeps its own look (only EnemyNameplate).
const OWN_STYLE_META: StringName = &"world_label_own_style"


## Styles one label (sizes, outline, its visibility range and its layer).
static func apply(label: Label3D) -> void:
	if label == null or label.has_meta(OWN_STYLE_META):
		return
	label.fixed_size = false
	label.pixel_size = PIXEL_SIZE
	label.font_size = FONT_SIZE
	label.outline_size = OUTLINE_SIZE
	label.visibility_range_begin = VISIBLE_FROM_M
	label.visibility_range_begin_margin = FADE_IN_MARGIN_M
	label.visibility_range_end = VISIBLE_TO_M
	label.visibility_range_end_margin = FADE_OUT_MARGIN_M
	label.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	label.layers = 1 << (STATION_LABEL_LAYER - 1) if is_station_label(label) else 1
	label.set_meta(STYLED_META, true)


## A world sign rather than a character's nameplate or a passing number: no character carries it.
static func is_station_label(label: Node) -> bool:
	var at: Node = label.get_parent()
	while at != null:
		if at is CharacterBody3D:
			return false
		at = at.get_parent()
	return true


## Styles every Label3D under `root` now, and every one that enters `tree` from now on.
static func watch(tree: SceneTree, root: Node) -> void:
	style_all(root)
	if not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)


static func style_all(root: Node) -> void:
	if root == null:
		return
	for found: Node in root.find_children("*", "Label3D", true, false):
		apply(found as Label3D)
	if root is Label3D:
		apply(root as Label3D)


static func _on_node_added(node: Node) -> void:
	var label: Label3D = node as Label3D
	if label != null:
		# After whoever made it has finished setting it up.
		_apply_later.call_deferred(label)


static func _apply_later(label: Label3D) -> void:
	if is_instance_valid(label):
		apply(label)
