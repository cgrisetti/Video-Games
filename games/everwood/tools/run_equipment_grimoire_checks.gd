## Runs only the Seal-and-Tuck Grimoire's 3-Stage Verification Suite
## (tools/test_equipment_grimoire_suite.gd) in the Caldera Isles, with a party
## of three, against a scratch save. The full smoke test runs it too, last.
## Run from games/everwood:
##   godot --headless --path . --fixed-fps 60 -s res://tools/run_equipment_grimoire_checks.gd
## Exits 0 when every check passes, 1 otherwise.
extends SceneTree

const CHECKS: GDScript = preload("res://tools/test_equipment_grimoire_suite.gd")
const CALDERA_CHECKS: GDScript = preload("res://tools/test_caldera_isles.gd")
const SAVE_PATH: String = "user://equipment_grimoire_checks_progress.cfg"
## The machine's settings too: the checks never read or write the real settings file.
const SETTINGS_PATH: String = "user://equipment_grimoire_checks_settings.json"
## Fake pads (high indices, so a real pad plugged in can't collide).
const FAKE_PADS: Array[int] = [6, 7]

var _passes: int = 0
var _failures: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("Everwood: the Seal-and-Tuck Grimoire's 3-Stage Verification Suite")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	PartyProgress.current.use_save_file(SAVE_PATH)
	SaveManager.remove(SETTINGS_PATH)
	SettingsManager.current.use_settings_file(SETTINGS_PATH)
	PartyProgress.current.apply_full_endgame_kit_for_testing()
	LevelBase.solo_iron_woodsman_boot = false
	CalderaWorldState.current.reset_for_testing()
	change_scene_to_file(CALDERA_CHECKS.CALDERA_SCENE)
	for index: int in 6:
		await physics_frame
	for pad: int in FAKE_PADS:
		NetworkManager.current.request_local_player(pad, NetworkManager.ANY_CLASS, InputComponent.AssistMode.ADVENTURER)
	for index: int in 30:
		await physics_frame
	await CHECKS.new().run(self, _check)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	SaveManager.remove(SETTINGS_PATH)
	print("%d passed, %d failed" % [_passes, _failures.size()])
	if _failures.is_empty():
		print("ALL 3 VERIFICATION GATES PASSED")
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
