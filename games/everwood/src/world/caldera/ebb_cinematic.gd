## The Ebb (docs/20 Part II §1.5; the Council's "10% added back"): ten
## seconds across the archipelago as the Harmonic Bell's chime parts the
## Star-Tide and the sea falls six metres on every isle. One full-screen
## camera over the live world (the other isles are their horizon
## silhouettes), cutting between four shots while CalderaWorldState lowers the
## sea: the bell in the World-Tree, the Sound to the north-west, the Sea-Door
## bared on the east shore, and back over the water toward home.
class_name EbbCinematic
extends CanvasLayer

signal finished

const LAYER: int = 60
const SHOTS: int = 4
const LETTERBOX: float = 0.1
const CAMERA_FAR: float = 6000.0

var elapsed: float = 0.0
var shot_index: int = -1

var _world: World3D
var _crown: Vector3 = Vector3.ZERO
var _home: Vector3 = Vector3.ZERO
var _viewport: SubViewport
var _camera: Camera3D
var _title: Label


## `crown` and `home` are The Crown's and Embershore's offsets in the live island's frame.
func setup(world: World3D, crown: Vector3, home: Vector3) -> void:
	_world = world
	_crown = crown
	_home = home


func _ready() -> void:
	layer = LAYER
	var container: SubViewportContainer = SubViewportContainer.new()
	container.name = "View"
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(container)
	_viewport = SubViewport.new()
	_viewport.name = "Viewport"
	_viewport.world_3d = _world
	_viewport.size = Vector2i(get_viewport().get_visible_rect().size)
	container.add_child(_viewport)
	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.far = CAMERA_FAR
	_camera.fov = 60.0
	_viewport.add_child(_camera)
	_camera.current = true
	for top: bool in [true, false]:
		var bar: ColorRect = ColorRect.new()
		bar.color = Color(0.0, 0.0, 0.0)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.anchor_left = 0.0
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if top else 1.0 - LETTERBOX
		bar.anchor_bottom = LETTERBOX if top else 1.0
		add_child(bar)
	_title = Label.new()
	_title.text = "THE LONG FLOOD ENDS\nthe sea falls six metres on every isle"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.anchor_left = 0.0
	_title.anchor_right = 1.0
	_title.anchor_top = 1.0 - LETTERBOX - 0.12
	_title.anchor_bottom = 1.0 - LETTERBOX
	_title.add_theme_font_size_override(&"font_size", 30)
	_title.add_theme_color_override(&"font_color", CalderaKit.HEARTH_SAFFRON)
	_title.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0))
	_title.add_theme_constant_override(&"outline_size", 8)
	_title.modulate.a = 0.0
	add_child(_title)
	_frame(0.0)


func _process(delta: float) -> void:
	elapsed += delta
	_frame(elapsed)
	if elapsed >= CalderaWorldState.EBB_SECONDS:
		finished.emit()
		queue_free()


func _frame(at: float) -> void:
	var length: float = CalderaWorldState.EBB_SECONDS / float(SHOTS)
	shot_index = clampi(int(at / length), 0, SHOTS - 1)
	var t: float = smoothstep(0.0, 1.0, clampf((at - shot_index * length) / length, 0.0, 1.0))
	var tree: Vector3 = _crown + CrownHeartCragBuilder.WORLD_TREE_AT
	var bell: Vector3 = _crown + CrownHeartCragBuilder.BELL_AT
	var door: Vector3 = _crown + CrownHeartCragBuilder.SEA_DOOR_AT
	var from: Vector3
	var to: Vector3
	var look: Vector3
	match shot_index:
		0:
			from = bell + Vector3(34.0, 4.0, 44.0)
			to = bell + Vector3(6.0, 12.0, 54.0)
			look = tree + Vector3(0.0, 24.0, 0.0)
		1:
			from = _crown + Vector3(-260.0, 150.0, 380.0)
			to = _crown + Vector3(-560.0, 210.0, 160.0)
			look = _crown + Vector3(-1400.0, 30.0, -900.0)
		2:
			from = door + Vector3(60.0, 5.0, 34.0)
			to = door + Vector3(34.0, 2.0, 8.0)
			look = door + Vector3(-10.0, 1.0, 0.0)
		_:
			from = _crown + Vector3(30.0, 180.0, 300.0)
			to = _crown + Vector3(10.0, 260.0, 720.0)
			look = _home
	_camera.global_position = from.lerp(to, t)
	_camera.look_at(look, Vector3.UP)
	_title.modulate.a = clampf((at - 1.5) / 1.0, 0.0, 1.0) * clampf((CalderaWorldState.EBB_SECONDS - at) / 0.8, 0.0, 1.0)
