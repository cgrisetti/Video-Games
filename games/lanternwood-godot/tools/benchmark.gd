extends SceneTree

# Measures how smoothly the Glenn runs on this computer, with a real window and GPU (not headless).
# Run from this folder:
#   godot --path . --script res://tools/benchmark.gd -- --graphics=high
# Add --area=berry-rush to measure Berry Rush instead (standing at the start, running across the
# field, turning round).
# It plays three short scenes the same way every time (standing at the start, walking up the
# Glenn, turning the camera to the woods) and prints, for each: average frames a second, the
# slowest 1% of frames, how long the GPU and CPU took per frame, and how much was drawn.
# Vsync is off, so the numbers show what the computer can do, not the screen's refresh rate.
# Your saved settings aren't changed.

const WARM_UP := 3.0 # Seconds to let shaders compile before measuring.
const SCENES := [["standing at the start", 4.0], ["walking up the Glenn", 7.0], ["turning to the woods", 4.0]]

var _glen: Node3D
var _menu: CanvasLayer
var _viewport_rid: RID


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var options := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		options[parts[0]] = parts[1] if parts.size() > 1 else ""
	var graphics: String = options.get("graphics", "high")
	var settings: Node = root.get_node("Settings")
	settings.values.graphics = graphics # Straight into the values, so nothing is saved.
	settings.values.music_on = false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_move_to_foreground() # macOS slows down windows that are behind others.
	if options.has("fullscreen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	Engine.max_fps = 0

	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.menu.close()
	_menu = main.menu
	_glen = main.glen
	if options.has("off"):
		_switch_off(options.off.split(","))
	if options.has("scale"): # --scale=0.6 --upscaler=fsr|metalfx: draw the 3D smaller and scale it up.
		root.get_viewport().scaling_3d_scale = float(options.scale)
		root.get_viewport().scaling_3d_mode = {"fsr": Viewport.SCALING_3D_MODE_FSR, "metalfx": Viewport.SCALING_3D_MODE_METALFX_SPATIAL}.get(options.get("upscaler", "fsr"), Viewport.SCALING_3D_MODE_BILINEAR)
	_viewport_rid = root.get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_viewport_rid, true)
	print("Lanternwood benchmark: graphics %s, %s, window %s (screen scale %.0f×), 3D drawn at %dx%d" % [graphics, RenderingServer.get_video_adapter_name(), DisplayServer.window_get_size(), DisplayServer.screen_get_scale(), roundi(DisplayServer.window_get_size().x * root.get_viewport().scaling_3d_scale), roundi(DisplayServer.window_get_size().y * root.get_viewport().scaling_3d_scale)])
	var area_name: String = options.get("area", "glen")
	if area_name != "glen":
		main.go_to(area_name)
		await _seconds(0.1)
		while main._switching:
			await process_frame
	await _seconds(WARM_UP)
	if options.has("shot"): # --shot=path.png saves a picture of the start, to compare looks.
		_menu.close()
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png(options.shot)

	var area: Node3D = main.area
	var gnome: CharacterBody3D = area.gnome
	var camera_rig: Node3D = area.camera_rig
	for scene: Array in SCENES:
		var name: String = scene[0]
		if options.has("only") and not name.contains(options.only):
			continue
		if area_name == "glen":
			_glen.enter()
		else:
			area.restart()
		await _seconds(0.3)
		if name.begins_with("walking"):
			Input.action_press("move_forward")
		if name.begins_with("turning"):
			if area_name == "glen":
				gnome.place(Vector3(0, 0.05, 0), PI)
			camera_rig.reset_view(0.0)
			Input.action_press("look_right")
		var report := await _measure(scene[1])
		Input.action_release("move_forward")
		Input.action_release("look_right")
		# Metal doesn't report GPU time, so it shows as 0 there; frame time minus CPU time is the GPU's share.
		print("  %-24s %5.0f fps   slowest 1%%: %4.0f fps   frame %5.1f ms   GPU %5.2f ms   CPU %5.2f ms   %5d draws   %5.2fM triangles   %4d objects" % [
			name, report.fps, report.low_fps, 1000.0 / report.fps, report.gpu, report.cpu, report.draws, report.triangles / 1e6, report.objects])
	quit()


# For finding what costs the most: --off=ssil,fog lists effects to switch off for this run.
func _switch_off(names: PackedStringArray) -> void:
	var env: Environment = _glen.environment.environment
	for name in names:
		match name:
			"msaa": root.get_viewport().msaa_3d = Viewport.MSAA_DISABLED
			"msaa4": root.get_viewport().msaa_3d = Viewport.MSAA_2X
			"fxaa": root.get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			"ssao": env.ssao_enabled = false
			"ssil": env.ssil_enabled = false
			"fog": env.volumetric_fog_enabled = false
			"glow": env.glow_enabled = false
			"dof": _glen.environment.camera_attributes.dof_blur_far_enabled = false
			"sun-shadows": _glen.sun.shadow_enabled = false
			"soft-shadows": _glen.sun.light_angular_distance = 0.0
			"splits": _glen.sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			"lantern-shadows":
				for light in _glen._lanterns:
					light.shadow_enabled = false
			"lanterns":
				for light in _glen._lanterns:
					light.visible = false
			"grass":
				for patch in _glen._grass_patches:
					patch.visible = false
			"leaves", "leaf-shadows", "all-shadows-but-sun":
				for node in _glen._generated.find_children("*", "GeometryInstance3D", true, false):
					var is_leaves: bool = node.material_override is ShaderMaterial and node.material_override.shader == Art.LEAVES_SHADER
					if name == "leaves" and is_leaves:
						node.visible = false
					elif name == "leaf-shadows" and is_leaves:
						node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			"filter-low": RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
			"filter-hard": RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
			"atlas-2k": RenderingServer.directional_shadow_atlas_set_size(2048, true)
			"shadow-50m": _glen.sun.directional_shadow_max_distance = 50.0
			_:
				print("Don't know how to switch off '%s'" % name)


func _measure(seconds: float) -> Dictionary:
	var frames := PackedFloat64Array()
	var gpu := 0.0
	var cpu := 0.0
	var draws := 0.0
	var triangles := 0.0
	var objects := 0.0
	var start := Time.get_ticks_usec()
	var last := start
	while Time.get_ticks_usec() - start < seconds * 1e6:
		await process_frame
		_menu.close() # The game pauses itself if the window loses focus; keep it going.
		var now := Time.get_ticks_usec()
		frames.append((now - last) / 1000.0)
		last = now
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(_viewport_rid)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(_viewport_rid) + RenderingServer.get_frame_setup_time_cpu()
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		triangles += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		objects += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var count := frames.size()
	var total := 0.0
	for ms in frames:
		total += ms
	var sorted := frames.duplicate()
	sorted.sort()
	var worst := sorted.slice(int(count * 0.99))
	var worst_total := 0.0
	for ms in worst:
		worst_total += ms
	return {
		"fps": 1000.0 * count / total,
		"low_fps": 1000.0 * worst.size() / maxf(worst_total, 0.001),
		"gpu": gpu / count, "cpu": cpu / count,
		"draws": draws / count, "triangles": triangles / count, "objects": objects / count,
	}


func _seconds(seconds: float) -> void:
	await create_timer(seconds).timeout
