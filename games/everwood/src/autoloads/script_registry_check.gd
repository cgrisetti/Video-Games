## The start-up check that Godot knows every named script of the project.
##
## Godot keeps a list of the scripts that name themselves with `class_name`
## (.godot/global_script_class_cache.cfg) and brings it up to date only when the
## editor opens or an import runs. Start the game from a terminal just after new
## work has landed and every script that uses a new name fails to compile: no
## island is built, and the hero falls through the sky as a default tank.
##
## This is the first autoload, so it runs before any other script of the game is
## read. It lists the names the scripts declare. If Godot's list lacks one it
## runs the import itself, then starts the game again; a `-s` tool run is told
## to run again instead. Godot hands back only the arguments it didn't use
## itself, so the second start keeps the project path, `--headless` and your own
## arguments, and loses the likes of `--fixed-fps`.
##
## It names no other script of the project, so it compiles whatever state the
## list is in, and it has no `class_name` of its own for the same reason.
extends Node

## Set for the second start, so a list that an import can't mend is tried once, not for ever.
const TRIED_FLAG: String = "EVERWOOD_SCRIPTS_REGISTERED"
## The names an import couldn't register (a script that doesn't parse, say), with their files' dates: left be until the file changes.
const GIVEN_UP_PATH: String = "res://.godot/everwood_unregistered_scripts.txt"
## A script declares its name before its first member: no need to read further than this.
const HEAD_LINES: int = 400
const MEMBER_STARTS: PackedStringArray = ["func ", "static ", "var ", "const ", "signal ", "enum ", "class "]

var _leaving: bool = false
var _exit_code: int = 0


func _init() -> void:
	# An exported game carries its own list; only a run from the project's folder can be behind.
	if not OS.has_feature("editor"):
		return
	var named: Dictionary[String, String] = declared()
	var missing: PackedStringArray = _not_given_up(unregistered_in(named, registered()), named)
	if missing.is_empty():
		return
	var project_dir: String = ProjectSettings.globalize_path("res://")
	var by_hand: String = "godot --headless --path \"%s\" --import" % project_dir
	print("Everwood: Godot hasn't registered %d of the project's named scripts yet (%s)." % [missing.size(), _first_few(missing)])
	if OS.get_environment(TRIED_FLAG) == "1":
		print("Everwood: an import didn't register them (does one of them fail to parse?). Carrying on; expect script errors.")
		_give_up_on(missing, named)
		return
	print("Everwood: registering them now. It takes a few seconds.")
	DisplayServer.window_set_title("Everwood: registering new scripts...")
	var said: Array = []
	var code: int = OS.execute(OS.get_executable_path(), PackedStringArray(["--headless", "--path", project_dir, "--import"]), said, true)
	if code != 0:
		print("Everwood: the import didn't finish (exit %d). Run it by hand, then start again:\n  %s" % [code, by_hand])
		return
	OS.set_environment(TRIED_FLAG, "1")
	_leaving = true
	if runs_a_tool(OS.get_cmdline_args()):
		print("Everwood: done. Run the same command again.")
		_exit_code = 1
	else:
		print("Everwood: done. Starting again.")
		OS.set_restart_on_exit(true, restart_arguments(OS.get_cmdline_args(), OS.get_cmdline_user_args(), project_dir,
			DisplayServer.get_name() == "headless"))
	# This start is over: what the scripts read after this one say about the old list is noise.
	Engine.print_error_messages = false
	AudioServer.set_bus_mute(0, true)


func _enter_tree() -> void:
	if _leaving:
		get_tree().quit(_exit_code)


## Every name a script under `root` declares with `class_name`, and its file. Hidden folders, folders with a
## `.gdignore` and other projects' folders are passed over, as Godot's own scan passes them over.
static func declared(root: String = "res://") -> Dictionary[String, String]:
	var named: Dictionary[String, String] = {}
	_scan(root, named)
	return named


## Godot's list as it read it when this run started: each name and its file.
static func registered() -> Dictionary[String, String]:
	var known: Dictionary[String, String] = {}
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		known[String(entry.get("class", ""))] = String(entry.get("path", ""))
	return known


## The declared names the list lacks, or holds at another file (a script that moved), in order.
static func unregistered_in(named: Dictionary[String, String], known: Dictionary[String, String]) -> PackedStringArray:
	var missing: PackedStringArray = PackedStringArray()
	for script_name: String in named:
		if String(known.get(script_name, "")) != named[script_name]:
			missing.append(script_name)
	missing.sort()
	return missing


## True for a run of one tool script (`-s tools/…`): it is told to run again, since whoever started it is waiting
## on this process and not on a second one.
static func runs_a_tool(arguments: PackedStringArray) -> bool:
	return arguments.has("-s") or arguments.has("--script")


## What the second start is given: the project's folder, `--headless` if this start was, the arguments Godot left
## over and yours after `--`.
static func restart_arguments(arguments: PackedStringArray, user_arguments: PackedStringArray, project_dir: String, headless: bool) -> PackedStringArray:
	var again: PackedStringArray = PackedStringArray(["--path", project_dir])
	if headless:
		again.append("--headless")
	var skip: bool = false
	for argument: String in arguments:
		if skip:
			skip = false
		elif argument == "--path":
			skip = true
		elif argument != "--headless":
			again.append(argument)
	if not user_arguments.is_empty():
		again.append("--")
		again.append_array(user_arguments)
	return again


static func _scan(folder: String, named: Dictionary[String, String]) -> void:
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while not entry.is_empty():
		var path: String = folder.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with(".") and not FileAccess.file_exists(path.path_join(".gdignore")) and not FileAccess.file_exists(path.path_join("project.godot")):
				_scan(path, named)
		elif entry.get_extension() == "gd":
			var script_name: String = _name_declared_in(path)
			if not script_name.is_empty():
				named[script_name] = path
		entry = dir.get_next()
	dir.list_dir_end()


static func _name_declared_in(path: String) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	for index: int in HEAD_LINES:
		if file.eof_reached():
			break
		var line: String = file.get_line()
		if line.begins_with("class_name "):
			return line.trim_prefix("class_name ").strip_edges().get_slice(" ", 0)
		for start: String in MEMBER_STARTS:
			if line.begins_with(start):
				return ""
	return ""


func _first_few(names: PackedStringArray) -> String:
	if names.size() <= 6:
		return ", ".join(names)
	return "%s and %d more" % [", ".join(names.slice(0, 6)), names.size() - 6]


## `missing` without the names an import already failed to register, as long as their files haven't changed since.
func _not_given_up(missing: PackedStringArray, named: Dictionary[String, String]) -> PackedStringArray:
	if missing.is_empty() or not FileAccess.file_exists(GIVEN_UP_PATH):
		return missing
	var given_up: PackedStringArray = FileAccess.get_file_as_string(GIVEN_UP_PATH).split("\n", false)
	var still: PackedStringArray = PackedStringArray()
	for script_name: String in missing:
		if not given_up.has(_given_up_line(script_name, named)):
			still.append(script_name)
	return still


func _give_up_on(missing: PackedStringArray, named: Dictionary[String, String]) -> void:
	var lines: PackedStringArray = PackedStringArray()
	for script_name: String in missing:
		lines.append(_given_up_line(script_name, named))
	var file: FileAccess = FileAccess.open(GIVEN_UP_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(lines) + "\n")


func _given_up_line(script_name: String, named: Dictionary[String, String]) -> String:
	return "%s %d" % [script_name, FileAccess.get_modified_time(named[script_name])]
