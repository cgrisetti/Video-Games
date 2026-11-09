## Embershore's screenshots and performance report (docs/27 §12). Run with a
## window (not headless), from games/everwood:
##   godot --path . -s res://tools/embershore_screenshots.gd
## It boots the Caldera on Embershore with four local players, walks them to the
## seven stages of the corridor and saves a screenshot of the split-screen view at
## each (docs/images/embershore/NN_<stage>.jpg), renders the whole island from
## straight above as an orthographic plate to set beside the generator's
## terrain.jpg (00_ortho.jpg), and writes the frame times it measured at every
## stage with four viewports to docs/images/embershore/perf.md. It uses a scratch
## save, never yours, and quits when done.
extends SceneTree

const OUT_DIR: String = "res://docs/images/embershore/"
const SAVE_PATH: String = "user://embershore_screenshots_progress.cfg"
const CALDERA_SCENE: String = "res://scenes/worlds/caldera_isles.tscn"
const FAKE_PADS: Array[int] = [6, 7, 8]
const SETTLE_FRAMES: int = 150
const SAMPLE_FRAMES: int = 180
## The seven stages (docs/27 §7): where the party stands and where P1's camera looks, in Embershore's frame.
const STAGES: Array[Dictionary] = [
	{"name": "bramblebridge", "at": Vector2(-593.0, 250.0), "look": Vector2(-589.0, 213.0)},
	{"name": "moss_oaks", "at": Vector2(-283.0, 150.0), "look": Vector2(-189.0, 167.0)},
	{"name": "sunken_holloway", "at": Vector2(300.0, 150.0), "look": Vector2(600.0, 63.0)},
	{"name": "doverslap_bridge", "at": Vector2(686.7, -40.0), "look": Vector2(686.7, -97.0)},
	{"name": "coast_road", "at": Vector2(467.0, -265.0), "look": Vector2(273.0, -321.0)},
	{"name": "hearthstead", "at": Vector2(39.0, -180.0), "look": Vector2(39.0, -237.0)},
	{"name": "mill_downs", "at": Vector2(35.0, -120.0), "look": Vector2(20.5, -27.0)},
]

var _level: CalderaArchipelagoWorld
var _report: PackedStringArray = PackedStringArray()
## `-- --stages=bramblebridge,coast_road` measures only those; `--out=/some/folder` writes there instead (a trial run).
var _only: PackedStringArray = PackedStringArray()
var _out: String = OUT_DIR


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--stages="):
			_only = argument.trim_prefix("--stages=").split(",", false)
		elif argument.begins_with("--out="):
			_out = argument.trim_prefix("--out=").trim_suffix("/") + "/"
	print("Everwood: Embershore's screenshots and performance report")
	await _windowed_1080p()
	DirAccess.make_dir_recursive_absolute(_out_path())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	PartyProgress.current.use_save_file(SAVE_PATH)
	PartyProgress.current.apply_full_endgame_kit_for_testing()
	LevelBase.solo_youth_boot = false
	CalderaWorldState.current.reset_for_testing()
	CalderaArchipelagoWorld.use_boot_zone(CalderaArchipelagoWorld.ZONE_EMBERSHORE)
	change_scene_to_file(CALDERA_SCENE)
	await _frames(10)
	_level = current_scene as CalderaArchipelagoWorld
	if _level == null:
		push_error("the Caldera Isles didn't load")
		quit(1)
		return
	for pad: int in FAKE_PADS:
		NetworkManager.current.request_local_player(pad, NetworkManager.ANY_CLASS, InputComponent.AssistMode.ADVENTURER)
	await _frames(30)
	_report.append("# Embershore: four-player split-screen performance\n")
	_report.append("Measured by tools/embershore_screenshots.gd at %s, window %s (vsync off), %d local players, %d frames a stage after %d to settle.\n"
		% [Time.get_datetime_string_from_system(), str(DisplayServer.window_get_size()), _party().size(), SAMPLE_FRAMES, SETTLE_FRAMES])
	_report.append("| Stage | FPS | process ms | physics ms | draw calls | primitives | near / mid / far landblocks |")
	_report.append("| :-- | --: | --: | --: | --: | --: | :-- |")
	for index: int in STAGES.size():
		var stage: Dictionary = STAGES[index]
		if not _only.is_empty() and not _only.has(String(stage["name"])):
			continue
		await _stand(stage["at"], stage["look"])
		await _frames(SETTLE_FRAMES)
		var sample: Dictionary = await _sample()
		var counts: Dictionary = _level.streamer.counts()
		_report.append("| %s | %.0f | %.2f | %.2f | %d | %d | %d / %d / %d |" % [String(stage["name"]), sample["fps"], sample["process_ms"], sample["physics_ms"],
			int(sample["draw_calls"]), int(sample["primitives"]), int(counts["near"]), int(counts["mid"]), int(counts["far"])])
		_save_screen("%02d_%s.jpg" % [index + 1, String(stage["name"])])
	if _only.is_empty():
		await _ortho_plate()
	var file: FileAccess = FileAccess.open(_out_path() + "perf.md", FileAccess.WRITE)
	file.store_string("\n".join(_report) + "\n")
	file.close()
	print("\n".join(_report))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	quit(0)


## The same 1920 x 1080 frame on any screen and whatever the family's Options say, and no
## vsync, so the frame rate isn't pinned to the monitor's refresh. Leaving their fullscreen
## takes macOS a moment: the window reads as windowed while it animates out, settles back into
## desktop fullscreen, and a size set meanwhile is lost, so this keeps asking until the window
## has read windowed at 1920 x 1080 for forty frames. Nothing here is saved to the Options.
func _windowed_1080p() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var steady: int = 0
	for attempt: int in 120:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			steady = 0
		elif DisplayServer.window_get_size() != Vector2i(1920, 1080):
			DisplayServer.window_set_size(Vector2i(1920, 1080))
			steady = 0
		else:
			steady += 1
			if steady >= 8:
				return
		await _frames(5)
	push_warning("the window wouldn't take 1920 x 1080 (it is %s, mode %d)" % [str(DisplayServer.window_get_size()), DisplayServer.window_get_mode()])


func _party() -> Array[ActorBase]:
	var members: Array[ActorBase] = []
	for actor: ActorBase in _level.party_in_order():
		if actor.is_local_player() and not actor.is_companion:
			members.append(actor)
	return members


func _stand(at: Vector2, look: Vector2) -> void:
	var seat: int = 0
	var facing: Vector2 = (look - at).normalized()
	var across: Vector2 = Vector2(-facing.y, facing.x)
	for actor: ActorBase in _party():
		var spot2: Vector2 = at + across * ((float(seat % 4) - 1.5) * 1.8)
		var spot: Vector3 = Vector3(spot2.x, 0.0, spot2.y)
		_level.streamer.ensure_ground_at(spot)
		spot.y = _level.streamer.height_at(spot.x, spot.z) + 0.2
		actor.place_at(Transform3D(Basis(Vector3.UP, atan2(-facing.x, -facing.y)), spot))
		var camera: PlayerCamera = _level.grid.camera_for(actor.player_id)
		if camera != null:
			camera.yaw = atan2(-facing.x, -facing.y)
			camera.set_pitch_degrees(16.0)
		seat += 1
	_level.streamer.load_now([_level.tether_centroid()])
	await _frames(2)


func _sample() -> Dictionary:
	var fps: float = 0.0
	var process_ms: float = 0.0
	var physics_ms: float = 0.0
	var draws: float = 0.0
	var primitives: float = 0.0
	for index: int in SAMPLE_FRAMES:
		await process_frame
		fps += Engine.get_frames_per_second()
		process_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var n: float = float(SAMPLE_FRAMES)
	return {"fps": fps / n, "process_ms": process_ms / n, "physics_ms": physics_ms / n, "draw_calls": draws / n, "primitives": primitives / n}


func _out_path() -> String:
	return ProjectSettings.globalize_path(_out) if _out.begins_with("res://") else _out


func _save_screen(file_name: String) -> void:
	var image: Image = root.get_viewport().get_texture().get_image()
	image.save_jpg(_out_path() + file_name, 0.86)
	print("  saved %s" % file_name)


## The island from straight above, 2,048 x 1,024 m, as the generator's terrain.jpg sees it.
func _ortho_plate() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(2048, 1024)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = 1024.0
	camera.near = 1.0
	camera.far = 2000.0
	camera.position = Vector3(0.0, 900.0, 0.0)
	camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	viewport.add_child(camera)
	camera.make_current()
	# Bring every landblock's mid ground in round the middle, so the plate has more than the far stand-ins.
	await _frames(12)
	var image: Image = viewport.get_texture().get_image()
	image.save_jpg(_out_path() + "00_ortho.jpg", 0.9)
	print("  saved 00_ortho.jpg (set beside world/embershore/gen/terrain.jpg)")
	viewport.queue_free()


func _frames(count: int) -> void:
	for index: int in count:
		await physics_frame
