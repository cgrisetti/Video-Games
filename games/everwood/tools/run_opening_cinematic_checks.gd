## Runs only the opening film's checks (tools/test_opening_cinematic.gd) in the Caldera Isles,
## against a scratch save and settings file (the checks make their own scratch tales). The full
## smoke test runs them too. Run from games/everwood:
##   godot --headless --path . --fixed-fps 60 -s res://tools/run_opening_cinematic_checks.gd
## Exits 0 when every check passes, 1 otherwise.
extends SceneTree

const CHECKS: GDScript = preload("res://tools/test_opening_cinematic.gd")
const SAVE_PATH: String = "user://opening_cinematic_checks_progress.cfg"
const SETTINGS_PATH: String = "user://opening_cinematic_checks_settings.json"

var _passes: int = 0
var _failures: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("Everwood: the opening film's checks")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	PartyProgress.current.use_save_file(SAVE_PATH)
	SaveManager.remove(SETTINGS_PATH)
	SettingsManager.current.use_settings_file(SETTINGS_PATH)
	CalderaWorldState.current.reset_for_testing()
	change_scene_to_file(CHECKS.CALDERA_SCENE)
	for index: int in 6:
		await physics_frame
	await CHECKS.new().run(self, _check, SAVE_PATH)
	CalderaWorldState.current.reset_for_testing()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	SaveManager.remove(SETTINGS_PATH)
	print("%d passed, %d failed" % [_passes, _failures.size()])
	if _failures.is_empty():
		print("ALL OPENING FILM CHECKS PASSED")
	else:
		print("FAILED: " + "; ".join(_failures))
	quit(0 if _failures.is_empty() else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		_passes += 1
		print("  ok   " + label)
	else:
		_failures.append(label)
		print("  FAIL " + label)
