class_name BerryCompass
extends Control

# The berry compass: when a raspberry is off the screen (behind a tree, across the creek, behind
# you), a little berry badge sits at the edge of the screen in its direction, with a pointer. Only
# the nearest few show, and they're soft, so you still plan your own route: the compass just saves
# you hunting for the last berry. The golden raspberry gets a bigger gold badge.

const SHOWN := 3 # How many off-screen berries get a badge (the nearest).
const MARGIN := 58.0 # How far in from the edge of the screen the badges sit...
const BOTTOM := 104.0 # ...and from the bottom, above the controls.
const RADIUS := 20.0
const PAPER := Color("#fbf4df")
const INK := Color("#8b6a43")
const BERRY := Color("#c8325f")
const GOLD := Color("#e8b030")

var camera: Camera3D
var berries: Array[Node3D] = []
var golden: Node3D # Only while it's out.
var from: Vector3 # Where the gnome is, for "nearest".

var _badges: Array = [] # Each: [where on screen, which way it points, how close (0-1), golden].


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	_badges.clear()
	if camera == null or not camera.is_inside_tree():
		queue_redraw()
		return
	var off := []
	for berry in berries:
		if is_instance_valid(berry) and not _on_screen(berry.global_position):
			off.append(berry)
	off.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.global_position.distance_to(from) < b.global_position.distance_to(from))
	for berry: Node3D in off.slice(0, SHOWN):
		_add_badge(berry.global_position, false)
	if golden and golden.visible and not _on_screen(golden.global_position):
		_add_badge(golden.global_position, true)
	queue_redraw()


func _on_screen(at: Vector3) -> bool:
	if camera.is_position_behind(at):
		return false
	var spot := camera.unproject_position(at)
	return get_viewport_rect().grow(-MARGIN * 0.5).has_point(spot)


# Put a badge on the edge of the screen, in the direction of `at`.
func _add_badge(at: Vector3, is_golden: bool) -> void:
	var screen := get_viewport_rect().size
	var area := Rect2(MARGIN, MARGIN, screen.x - MARGIN * 2.0, screen.y - MARGIN - BOTTOM)
	var middle := area.get_center()
	var local := camera.global_transform.affine_inverse() * at
	var direction := Vector2(local.x, -local.y)
	if local.z < 0.0:
		direction = camera.unproject_position(at) - middle # In front: exactly where it would be on screen.
	elif absf(direction.x) < 1.0:
		direction.y = absf(direction.y) + 1.0 # Right behind: along the bottom.
	if direction.length() < 0.001:
		direction = Vector2.DOWN
	direction = direction.normalized()
	var half := area.size / 2.0
	var reach := minf(half.x / maxf(absf(direction.x), 0.001), half.y / maxf(absf(direction.y), 0.001))
	var closeness := 1.0 - smoothstep(4.0, 30.0, at.distance_to(from))
	_badges.append([middle + direction * reach, direction, closeness, is_golden])


func _draw() -> void:
	for badge: Array in _badges:
		var at: Vector2 = badge[0]
		var direction: Vector2 = badge[1]
		var golden_badge: bool = badge[3]
		var size := RADIUS * (1.35 if golden_badge else 1.0) * lerpf(0.85, 1.1, badge[2])
		var alpha := lerpf(0.55, 0.95, badge[2]) if not golden_badge else 1.0
		# The pointer, then the paper badge, then the berry.
		var tip := at + direction * (size + 11.0)
		var side := direction.orthogonal() * size * 0.55
		draw_colored_polygon(PackedVector2Array([tip, at + direction * size * 0.6 + side, at + direction * size * 0.6 - side]), Color(INK, alpha))
		draw_circle(at, size + 2.0, Color(INK, alpha))
		draw_circle(at, size, Color(GOLD.lightened(0.55) if golden_badge else PAPER, alpha))
		_draw_berry(at, size * 0.62, Color(GOLD if golden_badge else BERRY, alpha))


# A little raspberry: round drupelets under a green cap.
func _draw_berry(at: Vector2, size: float, color: Color) -> void:
	var dots := [Vector2(0, -0.35), Vector2(-0.42, -0.1), Vector2(0.42, -0.1), Vector2(-0.22, 0.28), Vector2(0.22, 0.28), Vector2(0, 0.62), Vector2(0, 0.05)]
	for dot: Vector2 in dots:
		draw_circle(at + dot * size, size * 0.36, color)
		draw_circle(at + dot * size + Vector2(-0.1, -0.12) * size, size * 0.12, Color(1, 1, 1, color.a * 0.45))
	var leaf := Color("#4e8f36", color.a)
	for angle: float in [-0.9, 0.0, 0.9]:
		var stem := at + Vector2(0, -0.72) * size
		draw_colored_polygon(PackedVector2Array([stem, stem + Vector2(sin(angle) - 0.18, -cos(angle)) * size * 0.45, stem + Vector2(sin(angle) + 0.18, -cos(angle)) * size * 0.45]), leaf)
