## Dynamic 1-to-4 player split-screen. Each local player gets a SubViewport,
## and every SubViewport renders the same World3D: one scene, one Jolt physics
## space, one set of actors, seen through up to four cameras.
##   1 player   full screen
##   2 players  side by side
##   3 players  2 x 2, the fourth cell shows a top-down raid view
##   4 players  2 x 2
## While a film plays before split-screen starts (the opening prologue, docs/31), one player's
## view can be spotlit: it alone fills the screen and the others wait, hidden, until it's cleared.
class_name SplitScreenViewportGrid
extends Control

signal layout_changed(view_count: int)

const MAX_VIEWS: int = 4
const CELL_GAP: int = 4
const GAP_COLOR: Color = Color(0.05, 0.05, 0.06)
const OVERVIEW_POSITION: Vector3 = Vector3(0.0, 34.0, 26.0)
const OVERVIEW_LOOK_AT: Vector3 = Vector3(0.0, 0.0, 2.0)
const OVERVIEW_FOV: float = 55.0

var world: World3D

var _grid: GridContainer
var _cells: Dictionary[StringName, Control] = {}
var _cameras: Dictionary[StringName, PlayerCamera] = {}
var _overlays: Dictionary[StringName, Control] = {}
var _viewports: Dictionary[StringName, SubViewport] = {}
var _overview_cell: Control
## The one view filling the screen while a film plays (docs/31), or &"" for the usual split.
var spotlight: StringName = &""


func _ready() -> void:
	# A render-scale change in the Options menu reaches every view (SettingsManager).
	add_to_group(SettingsManager.GRID_GROUP)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "Gaps"
	backdrop.color = GAP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	_grid = GridContainer.new()
	_grid.name = "Cells"
	_grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid.add_theme_constant_override(&"h_separation", CELL_GAP)
	_grid.add_theme_constant_override(&"v_separation", CELL_GAP)
	add_child(_grid)
	backdrop.visible = false


## Every view renders this world. The level passes in its own World3D.
func set_world(shared_world: World3D) -> void:
	world = shared_world
	for viewport: SubViewport in _viewports.values():
		viewport.world_3d = world


func view_count() -> int:
	return _cells.size()


func has_view(player_id: StringName) -> bool:
	return _cells.has(player_id)


func camera_for(player_id: StringName) -> PlayerCamera:
	return _cameras[player_id] if _cameras.has(player_id) else null


## A full-cell Control above the player's view, for their HUD.
func overlay_for(player_id: StringName) -> Control:
	return _overlays[player_id] if _overlays.has(player_id) else null


func viewport_for(player_id: StringName) -> SubViewport:
	return _viewports[player_id] if _viewports.has(player_id) else null


## Shows only `player_id`'s view, full screen (a film before split-screen starts); &"" brings the split back.
func set_spotlight(player_id: StringName) -> void:
	spotlight = player_id
	_relayout()


## How many views are on screen now (one while a view is spotlit).
func shown_view_count() -> int:
	return 1 if _spotlit() else _cells.size()


func _spotlit() -> bool:
	return spotlight != &"" and _cells.has(spotlight)


func viewports() -> Array[SubViewport]:
	var list: Array[SubViewport] = []
	list.assign(_viewports.values())
	return list


## Every view's 3D render scale (the Options menu's Render Scale).
func apply_render_scale(scale: float) -> void:
	for viewport: SubViewport in _viewports.values():
		viewport.scaling_3d_scale = scale


## Settings: Craft textures (the mipmap bias every view draws its textures at).
func apply_texture_bias(bias: float) -> void:
	for viewport: SubViewport in _viewports.values():
		viewport.texture_mipmap_bias = bias


func add_player_view(actor: ActorBase) -> Control:
	if _cells.has(actor.player_id):
		return _overlays[actor.player_id]
	if _cells.size() >= MAX_VIEWS:
		push_warning("SplitScreenViewportGrid: already showing %d views" % MAX_VIEWS)
		return null
	var camera: PlayerCamera = PlayerCamera.new()
	camera.follow(actor)
	var cell: Control = _make_cell("View_%s" % actor.player_id, camera)
	var overlay: Control = Control.new()
	overlay.name = "Overlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(overlay)
	_cells[actor.player_id] = cell
	_cameras[actor.player_id] = camera
	_overlays[actor.player_id] = overlay
	_viewports[actor.player_id] = camera.get_parent() as SubViewport
	_grid.add_child(cell)
	_relayout()
	return overlay


func remove_player_view(player_id: StringName) -> void:
	if not _cells.has(player_id):
		return
	_cells[player_id].queue_free()
	_grid.remove_child(_cells[player_id])
	_cells.erase(player_id)
	_cameras.erase(player_id)
	_overlays.erase(player_id)
	_viewports.erase(player_id)
	if spotlight == player_id:
		spotlight = &""
	_relayout()


func _make_cell(cell_name: String, camera: Camera3D) -> Control:
	var cell: Control = Control.new()
	cell.name = cell_name
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cell.clip_contents = true
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var container: SubViewportContainer = SubViewportContainer.new()
	container.name = "Screen"
	container.stretch = true
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport: SubViewport = SubViewport.new()
	viewport.name = "Viewport"
	viewport.own_world_3d = false
	viewport.world_3d = world
	viewport.handle_input_locally = false
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.scaling_3d_scale = SettingsManager.current.render_scale if SettingsManager.current != null else 1.0
	viewport.audio_listener_enable_3d = _cells.is_empty()
	viewport.add_child(camera)
	container.add_child(viewport)
	cell.add_child(container)
	return cell


func _relayout() -> void:
	var count: int = _cells.size()
	var spotlit: bool = _spotlit()
	for player_id: StringName in _cells:
		_cells[player_id].visible = not spotlit or player_id == spotlight
	if spotlit:
		count = 1
	_grid.columns = 1 if count <= 1 else 2
	(get_node("Gaps") as ColorRect).visible = count > 1
	if count == 3:
		if _overview_cell == null:
			_overview_cell = _make_overview_cell()
			_grid.add_child(_overview_cell)
		_grid.move_child(_overview_cell, -1)
	elif _overview_cell != null:
		_overview_cell.queue_free()
		_grid.remove_child(_overview_cell)
		_overview_cell = null
	layout_changed.emit(count)


## The spare fourth cell with three players: a raid-wide view from above.
func _make_overview_cell() -> Control:
	var camera: Camera3D = Camera3D.new()
	camera.name = "OverviewCamera"
	camera.fov = OVERVIEW_FOV
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	# The camera sits directly under its SubViewport, so its local transform is its world transform.
	camera.transform = Transform3D(Basis.looking_at(OVERVIEW_LOOK_AT - OVERVIEW_POSITION, Vector3.UP), OVERVIEW_POSITION)
	camera.current = true
	var cell: Control = _make_cell("RaidView", camera)
	var label: Label = Label.new()
	label.text = "Raid view"
	label.position = Vector2(14.0, 10.0)
	label.add_theme_font_size_override(&"font_size", 20)
	label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	label.add_theme_constant_override(&"outline_size", 6)
	cell.add_child(label)
	return cell
