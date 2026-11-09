## Embershore's worked land in pictures (docs/32). Run with a window (not
## headless), from games/everwood:
##   godot --path . -s res://tools/embershore_views.gd
##   godot --path . -s res://tools/embershore_views.gd -- --only=bramblebridge_air,lark_wick --out=/tmp/views
## It boots the Caldera on Embershore with one hero, stands them at each view's
## subject (so the ground, the meadow and the stock there are the near ones),
## looks at it from a free camera and saves docs/images/embershore_worked_land/
## <name>.jpg. It uses a scratch save, never yours, and quits when done.
extends SceneTree

const OUT_DIR: String = "res://docs/images/embershore_worked_land/"
const SAVE_PATH: String = "user://embershore_views_progress.cfg"
const CALDERA_SCENE: String = "res://scenes/worlds/caldera_isles.tscn"
const SIZE: Vector2i = Vector2i(1600, 900)
const SETTLE_FRAMES: int = 90
## Each view: its subject (x, z in Embershore's frame), where the camera stands from it (bearing in degrees, 0 north
## and 90 east, metres out and metres above the subject's ground) and how far over the subject it looks.
const VIEWS: Array[Dictionary] = [
	{"name": "bramblebridge_air", "at": Vector2(-590.0, 215.0), "bearing": 200.0, "out": 150.0, "up": 85.0, "look_up": 0.0},
	{"name": "bramblebridge_green", "at": Vector2(-594.0, 256.0), "bearing": 150.0, "out": 26.0, "up": 7.0, "look_up": 2.0},
	{"name": "orchard_gate", "at": Vector2(-584.0, 182.0), "bearing": 320.0, "out": 16.0, "up": 6.0, "look_up": 1.5},
	{"name": "lark_wick", "at": Vector2(-870.0, -25.0), "steading": "lark_wick", "bearing": 130.0, "out": 48.0, "up": 16.0, "look_up": 2.0},
	{"name": "lark_wick_yard", "at": Vector2(-870.0, -25.0), "steading": "lark_wick", "bearing": 200.0, "out": 17.0, "up": 4.6, "look_up": 1.6},
	{"name": "lark_wick_air", "at": Vector2(-840.0, -40.0), "steading": "lark_wick", "bearing": 180.0, "out": 190.0, "up": 110.0, "look_up": 0.0},
	{"name": "hedged_lane", "at": Vector2(-540.0, 60.0), "bearing": 200.0, "out": 14.0, "up": 3.2, "look_up": 1.6},
	{"name": "barley_green", "at": Vector2(-580.0, -215.0), "steading": "barley_green", "bearing": 160.0, "out": 60.0, "up": 20.0, "look_up": 2.0},
	{"name": "west_valley_air", "at": Vector2(-560.0, -60.0), "bearing": 180.0, "out": 330.0, "up": 210.0, "look_up": 0.0},
	{"name": "clover_hollow", "at": Vector2(-330.0, -95.0), "steading": "clover_hollow", "bearing": 140.0, "out": 44.0, "up": 14.0, "look_up": 2.0},
	{"name": "thistle_crossing", "at": Vector2(-330.0, -235.0), "steading": "thistle_crossing", "bearing": 215.0, "out": 46.0, "up": 14.0, "look_up": 2.0},
	{"name": "otter_crossing", "at": Vector2(-850.0, 215.0), "steading": "otter_crossing", "bearing": 60.0, "out": 50.0, "up": 16.0, "look_up": 2.0},
	{"name": "withy_hollow", "at": Vector2(-215.0, 50.0), "steading": "withy_hollow", "bearing": 330.0, "out": 50.0, "up": 16.0, "look_up": 3.0},
	{"name": "mill_downs", "at": Vector2(20.0, -40.0), "bearing": 170.0, "out": 80.0, "up": 26.0, "look_up": 4.0},
	{"name": "hearthstead_air", "at": Vector2(40.0, -190.0), "bearing": 170.0, "out": 170.0, "up": 100.0, "look_up": 0.0},
	{"name": "hearthstead_street", "at": Vector2(52.0, -186.0), "bearing": 110.0, "out": 24.0, "up": 6.0, "look_up": 2.5},
	{"name": "ewe_green", "at": Vector2(180.0, -200.0), "steading": "ewe_green", "bearing": 150.0, "out": 50.0, "up": 16.0, "look_up": 2.0},
	{"name": "sunward_haven", "at": Vector2(300.0, -285.0), "steading": "sunward_haven", "bearing": 200.0, "out": 44.0, "up": 14.0, "look_up": 2.0},
	{"name": "seal_haven", "at": Vector2(500.0, -235.0), "steading": "seal_haven", "bearing": 150.0, "out": 40.0, "up": 12.0, "look_up": 2.0},
	{"name": "gorse_wick", "at": Vector2(620.0, -180.0), "steading": "gorse_wick", "bearing": 160.0, "out": 52.0, "up": 17.0, "look_up": 2.0},
	{"name": "gorse_wick_air", "at": Vector2(620.0, -180.0), "steading": "gorse_wick", "bearing": 200.0, "out": 210.0, "up": 120.0, "look_up": 0.0},
	{"name": "eel_wick", "at": Vector2(850.0, -240.0), "steading": "eel_wick", "bearing": 210.0, "out": 44.0, "up": 14.0, "look_up": 2.0},
	{"name": "miller_green", "at": Vector2(60.0, -55.0), "steading": "miller_green", "bearing": 230.0, "out": 40.0, "up": 12.0, "look_up": 2.0},
	{"name": "kettle_wick", "at": Vector2(-130.0, -150.0), "steading": "kettle_wick", "bearing": 140.0, "out": 42.0, "up": 13.0, "look_up": 2.0},
	{"name": "plum_wick", "at": Vector2(-470.0, -20.0), "steading": "plum_wick", "bearing": 150.0, "out": 42.0, "up": 13.0, "look_up": 2.0},
	{"name": "stone_walls", "at": Vector2(600.0, -200.0), "bearing": 250.0, "out": 22.0, "up": 4.5, "look_up": 1.4},
	{"name": "sunken_holloway", "at": Vector2(420.0, 150.0), "bearing": 250.0, "out": 20.0, "up": 5.0, "look_up": 2.0},
	{"name": "fallow_hollow", "at": Vector2(345.0, 225.0), "steading": "fallow_hollow", "bearing": 320.0, "out": 46.0, "up": 15.0, "look_up": 2.0},
	{"name": "pine_wood", "at": Vector2(-700.0, 285.0), "bearing": 330.0, "out": 70.0, "up": 24.0, "look_up": 6.0},
	{"name": "orchard", "at": Vector2(-700.0, 20.0), "bearing": 150.0, "out": 34.0, "up": 9.0, "look_up": 2.0},
	{"name": "bramble_ford", "at": Vector2(-800.0, 170.0), "bearing": 40.0, "out": 40.0, "up": 12.0, "look_up": 1.0},
	{"name": "island_air", "at": Vector2(-120.0, -40.0), "bearing": 180.0, "out": 900.0, "up": 620.0, "look_up": 0.0},
]

var _level: CalderaArchipelagoWorld
var _viewport: SubViewport
var _camera: Camera3D
var _out: String = OUT_DIR
var _only: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			_out = argument.trim_prefix("--out=").trim_suffix("/") + "/"
		elif argument.begins_with("--only="):
			_only = argument.trim_prefix("--only=").split(",", false)
	_run.call_deferred()


func _run() -> void:
	print("Everwood: Embershore's worked land in pictures")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(960, 540))
	var out_dir: String = ProjectSettings.globalize_path(_out) if _out.begins_with("res://") else _out
	DirAccess.make_dir_recursive_absolute(out_dir)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	PartyProgress.current.use_save_file(SAVE_PATH)
	PartyProgress.current.apply_full_endgame_kit_for_testing()
	LevelBase.solo_youth_boot = false
	CalderaWorldState.current.reset_for_testing()
	CalderaArchipelagoWorld.use_boot_zone(CalderaArchipelagoWorld.ZONE_EMBERSHORE)
	change_scene_to_file(CALDERA_SCENE)
	await _frames(12)
	_level = current_scene as CalderaArchipelagoWorld
	if _level == null:
		push_error("the Caldera Isles didn't load")
		quit(1)
		return
	await _frames(30)
	_viewport = SubViewport.new()
	_viewport.size = SIZE
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(_viewport)
	_camera = Camera3D.new()
	_camera.fov = 52.0
	_camera.near = 0.3
	_camera.far = 4600.0
	_viewport.add_child(_camera)
	_camera.make_current()
	for view: Dictionary in VIEWS:
		if not _only.is_empty() and not _only.has(String(view["name"])):
			continue
		await _take(view, out_dir)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	quit(0)


func _take(view: Dictionary, out_dir: String) -> void:
	var at: Vector2 = view["at"]
	# A steading's view follows the steading to wherever the worked land's script set it down.
	var builder: EmbershoreBuilder = _level.streamer.builder as EmbershoreBuilder
	if view.has("steading") and builder != null:
		for steading: Variant in builder.settlement.list("steadings"):
			if String((steading as Dictionary).get("id", "")) == String(view["steading"]):
				at = EmbershoreSettlement.at2((steading as Dictionary)["at"])
	var hero: ActorBase = _hero()
	var spot: Vector3 = Vector3(at.x, 0.0, at.y)
	_level.streamer.ensure_ground_at(spot)
	spot.y = _level.streamer.height_at(spot.x, spot.z) + 0.2
	if hero != null:
		hero.place_at(Transform3D(Basis.IDENTITY, spot))
	_level.streamer.load_now([spot])
	var bearing: float = deg_to_rad(float(view["bearing"]))
	# A bearing of 0 stands the camera north of the subject (-Z), 90 east of it (+X).
	var away: Vector3 = Vector3(sin(bearing), 0.0, -cos(bearing)) * float(view["out"])
	var eye: Vector3 = spot + away + Vector3(0.0, float(view["up"]), 0.0)
	eye.y = maxf(eye.y, _level.streamer.builder.height_at(eye.x, eye.z) + 1.6)
	_camera.global_position = eye
	_camera.look_at(spot + Vector3(0.0, float(view["look_up"]), 0.0), Vector3.UP)
	await _frames(SETTLE_FRAMES)
	var image: Image = _viewport.get_texture().get_image()
	image.save_jpg(out_dir + "%s.jpg" % String(view["name"]), 0.9)
	print("  saved %s.jpg" % String(view["name"]))


func _hero() -> ActorBase:
	for actor: ActorBase in _level.party_in_order():
		if actor.is_local_player() and not actor.is_companion:
			return actor
	return null


func _frames(count: int) -> void:
	for index: int in count:
		await physics_frame
