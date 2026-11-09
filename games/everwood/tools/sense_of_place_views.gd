## The Caldera's sense of place in pictures (docs/33). Run with a window (not headless), from games/everwood:
##   godot --path . -s res://tools/sense_of_place_views.gd
##   godot --path . -s res://tools/sense_of_place_views.gd -- --out=/tmp/views
## From North Quay it looks out over The Sound (as a hero sees it, then close on each Friction Isle) with every
## Beacon cold, lights the three (a playtest change, never saved) and looks again. Then it lands on each Friction
## Isle by its Beacon and looks inland over its colour field, comes home to Bramblebridge's green under the
## autumn sun, and walks a hero into the Mill-Downs reveal. Pictures go to docs/images/sense_of_place/. It uses
## a scratch save, never yours, and quits when done.
extends SceneTree

const OUT_DIR: String = "res://docs/images/sense_of_place/"
const SAVE_PATH: String = "user://sense_of_place_views_progress.cfg"
const CALDERA_SCENE: String = "res://scenes/worlds/caldera_isles.tscn"
const SIZE: Vector2i = Vector2i(1600, 900)
const SETTLE_FRAMES: int = 120
## North Quay's pier head, in Embershore's frame, and how high over it the camera stands.
const QUAY: Vector3 = Vector3(42.0, 0.0, -270.0)
const QUAY_EYE_UP: float = 14.0
## The Sound as a hero sees it (the game's field of view), then each isle close.
const WIDE_FOV: float = 62.0
const CLOSE_FOV: float = 16.0
const ISLES: Array[StringName] = [CalderaAtlas.ISLE_IRON_NESS, CalderaAtlas.ISLE_BARROW_EYOT, CalderaAtlas.ISLE_RIME_FIRTH]
## The Mill-Downs reveal is at its height this long after the hero steps in.
const MILL_DOWNS_PEAK_SECONDS: float = 2.5

var _level: CalderaArchipelagoWorld
var _viewport: SubViewport
var _camera: Camera3D
var _out: String = OUT_DIR


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			_out = argument.trim_prefix("--out=").trim_suffix("/") + "/"
	_run.call_deferred()


func _run() -> void:
	print("Everwood: the Caldera's sense of place in pictures")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(960, 540))
	var out_dir: String = ProjectSettings.globalize_path(_out) if _out.begins_with("res://") else _out
	DirAccess.make_dir_recursive_absolute(out_dir)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	PartyProgress.current.use_save_file(SAVE_PATH)
	PartyProgress.current.apply_full_endgame_kit_for_testing()
	LevelBase.solo_youth_boot = false
	var state: CalderaWorldState = CalderaWorldState.current
	state.reset_for_testing()
	# Every change below is a playtest change: nothing reaches a save.
	state.playtest = true
	CalderaArchipelagoWorld.use_boot_zone(CalderaArchipelagoWorld.ZONE_NORTH_QUAY)
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
	_camera.near = 0.3
	_camera.far = CalderaArchipelagoWorld.CAMERA_FAR
	_viewport.add_child(_camera)
	_camera.make_current()
	await _from_the_quay(out_dir, "cold")
	for isle_id: StringName in ISLES:
		state.light_beacon(isle_id)
	await _from_the_quay(out_dir, "lit")
	for isle_id: StringName in ISLES:
		await _on_the_isle(isle_id, out_dir)
	await _autumn_and_home(out_dir)
	state.reset_for_testing()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	quit(0)


func _from_the_quay(out_dir: String, tag: String) -> void:
	_level.travel_to(CalderaAtlas.ISLE_EMBERSHORE, CalderaAtlas.ARRIVE_NORTH_QUAY)
	await _frames(20)
	var eye: Vector3 = QUAY + Vector3(0.0, QUAY_EYE_UP, 0.0)
	var crown: Vector3 = CalderaAtlas.offset_between(CalderaAtlas.ISLE_EMBERSHORE, CalderaAtlas.ISLE_THE_CROWN)
	await _shoot(out_dir, "sound_%s" % tag, eye, crown + Vector3(0.0, 40.0, 0.0), WIDE_FOV)
	if tag != "lit":
		return
	for isle_id: StringName in ISLES:
		var far: Vector3 = CalderaAtlas.offset_between(CalderaAtlas.ISLE_EMBERSHORE, isle_id)
		var beacon: Vector3 = CalderaAtlas.builder_for(isle_id).beacon_spot()
		var aim: Vector3 = far.lerp(far + Vector3(beacon.x, 0.0, beacon.z), 0.6) + Vector3(0.0, 30.0, 0.0)
		await _shoot(out_dir, "far_%s" % String(isle_id).trim_prefix("isle_"), eye, aim, CLOSE_FOV)


func _on_the_isle(isle_id: StringName, out_dir: String) -> void:
	_level.travel_to(isle_id, CalderaAtlas.ARRIVE_BEACON)
	await _frames(40)
	var builder: IslandBuilder = _level.streamer.builder
	var beacon: Vector3 = builder.beacon_spot()
	# Stand inland of the Beacon, look on over the isle toward its middle.
	var inland: Vector3 = Vector3(-beacon.x, 0.0, -beacon.z).normalized()
	var spot: Vector3 = beacon + inland * 60.0
	_level.streamer.ensure_ground_at(spot)
	spot.y = _level.streamer.height_at(spot.x, spot.z)
	_level.streamer.load_now([spot])
	var eye: Vector3 = spot - inland * 14.0 + Vector3(0.0, 9.0, 0.0)
	eye.y = maxf(eye.y, builder.height_at(eye.x, eye.z) + 3.0)
	await _shoot(out_dir, "on_%s" % String(isle_id).trim_prefix("isle_"), eye, spot + inland * 120.0 + Vector3(0.0, 4.0, 0.0), WIDE_FOV)


## Bramblebridge's green under the autumn sun, then the Mill-Downs reveal through the hero's own camera at its height.
func _autumn_and_home(out_dir: String) -> void:
	_level.travel_to(CalderaAtlas.ISLE_EMBERSHORE, CalderaAtlas.ARRIVE_START)
	await _frames(30)
	var green: Vector3 = Vector3(-594.0, 0.0, 256.0)
	green.y = _level.streamer.height_at(green.x, green.z)
	var away: Vector3 = Vector3(sin(deg_to_rad(150.0)), 0.0, -cos(deg_to_rad(150.0))) * 26.0
	await _shoot(out_dir, "autumn_bramblebridge", green + away + Vector3(0.0, 7.0, 0.0), green + Vector3(0.0, 2.0, 0.0), 52.0)
	var reveal: VistaReveal = _level.streamer.structures.find_child("MillDownsReveal", true, false) as VistaReveal
	var hero: ActorBase = _level.party_in_order()[0]
	if reveal == null or hero == null:
		push_error("no Mill-Downs reveal")
		return
	PartyProgress.current.reveals_seen.clear()
	_level.streamer.load_now([reveal.global_position])
	await _frames(20)
	hero.place_at(Transform3D(Basis.IDENTITY, reveal.global_position + Vector3(0.0, 0.4, 0.0)))
	if WorldAtmosphereDirector.current != null:
		WorldAtmosphereDirector.current.settle()
	# Half-way through its five seconds the reveal is at its height.
	await _frames(int(MILL_DOWNS_PEAK_SECONDS * 60.0))
	var view: SubViewport = _level.grid.viewport_for(hero.player_id)
	if view == null:
		push_error("no view for the hero")
		return
	view.get_texture().get_image().save_jpg(out_dir + "mill_downs_reveal.jpg", 0.9)
	print("  saved mill_downs_reveal.jpg")


func _shoot(out_dir: String, picture: String, eye: Vector3, target: Vector3, fov: float) -> void:
	_camera.fov = fov
	_camera.global_position = eye
	_camera.look_at(target, Vector3.UP)
	if WorldAtmosphereDirector.current != null:
		WorldAtmosphereDirector.current.settle()
	await _frames(SETTLE_FRAMES)
	var image: Image = _viewport.get_texture().get_image()
	image.save_jpg(out_dir + "%s.jpg" % picture, 0.9)
	print("  saved %s.jpg" % picture)


func _frames(count: int) -> void:
	for index: int in count:
		await physics_frame
