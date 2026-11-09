## The start-up check's own checks (src/autoloads/script_registry_check.gd), run
## by tools/smoke_test.gd before anything else:
##   1  Godot knows every named script: each name a script declares is in its
##      list, at that script's file
##   2  a name the list lacks and a script that moved are both found
##   3  the scan passes over what Godot's own passes over (hidden folders,
##      folders with a .gdignore, another project's folder) and reads a name
##      that follows a long header, but none written after the first member
##   4  the check is the first autoload, has no class_name and names no other
##      script of the project
##   5  the second start keeps the folder, --headless and your own arguments,
##      and a -s run is told to run again
extends RefCounted

const REGISTRY: GDScript = preload("res://src/autoloads/script_registry_check.gd")
const CHECK_PATH: String = "res://src/autoloads/script_registry_check.gd"
const PROBE_DIR: String = "user://script_registry_probe"


func run(_scene_tree: SceneTree, check: Callable) -> void:
	print("  [Scripts] the start-up check that Godot knows every named script")
	var named: Dictionary[String, String] = REGISTRY.declared()
	var known: Dictionary[String, String] = REGISTRY.registered()
	var missing: PackedStringArray = REGISTRY.unregistered_in(named, known)
	check.call(named.size() >= 270 and missing.is_empty() and named.get("EmbershoreBuilder", "") == "res://src/world/caldera/islands/embershore_builder.gd",
		"Godot knows every named script: %d declared, %d in its list, none missing (%s)" % [named.size(), known.size(), ", ".join(missing)])

	var behind: Dictionary[String, String] = known.duplicate()
	behind.erase("GrazingStock")
	behind["SteadingKit"] = "res://src/world/steading_kit.gd"
	behind["LongGone"] = "res://src/long_gone.gd"
	var found: PackedStringArray = REGISTRY.unregistered_in(named, behind)
	check.call(found == PackedStringArray(["GrazingStock", "SteadingKit"]),
		"a name the list lacks and a script that moved are both found, and a name only the list holds is let be (%s)" % ", ".join(found))

	_write_probe()
	var probed: Dictionary[String, String] = REGISTRY.declared(PROBE_DIR)
	_remove_probe()
	check.call(probed.size() == 2 and probed.get("ProbeSeen", "") == PROBE_DIR + "/seen.gd" and probed.get("ProbeLate", "") == PROBE_DIR + "/deep/late.gd",
		"the scan passes over a hidden folder, a .gdignore folder and another project's folder, reads a name under a long header and none after the first member (%s)"
		% ", ".join(PackedStringArray(probed.keys())))

	var source: String = FileAccess.get_file_as_string(CHECK_PATH)
	var named_in_code: PackedStringArray = _project_names_in(source, named)
	var first: String = _first_autoload()
	check.call(first == "ScriptRegistryCheck=\"*%s\"" % CHECK_PATH and not named.values().has(CHECK_PATH) and named_in_code.is_empty(),
		"the check is the first autoload, has no class_name and names no other script of the project (%s; %s)" % [first, ", ".join(named_in_code)])

	var played: PackedStringArray = REGISTRY.restart_arguments(PackedStringArray(), PackedStringArray(["--seat=2"]), "/games/everwood/", false)
	var boot: PackedStringArray = REGISTRY.restart_arguments(PackedStringArray(["--path", "elsewhere", "--headless", "--verbose"]), PackedStringArray(), "/games/everwood/", true)
	check.call(played == PackedStringArray(["--path", "/games/everwood/", "--", "--seat=2"]) and boot == PackedStringArray(["--path", "/games/everwood/", "--headless", "--verbose"])
		and REGISTRY.runs_a_tool(PackedStringArray(["-s", "res://tools/smoke_test.gd"])) and not REGISTRY.runs_a_tool(PackedStringArray(["--verbose"])),
		"the second start keeps the folder, --headless and your own arguments, and a -s run is told to run again (%s)" % " ".join(played))


## The first line of project.godot's [autoload] section.
func _first_autoload() -> String:
	var lines: PackedStringArray = FileAccess.get_file_as_string("res://project.godot").split("\n")
	var at: int = lines.find("[autoload]")
	if at < 0:
		return ""
	for index: int in range(at + 1, lines.size()):
		if not lines[index].strip_edges().is_empty():
			return lines[index].strip_edges()
	return ""


## The project's script names that `source` uses in its code (its comments left out).
func _project_names_in(source: String, named: Dictionary[String, String]) -> PackedStringArray:
	var words: RegEx = RegEx.create_from_string("[A-Za-z_][A-Za-z0-9_]*")
	var used: PackedStringArray = PackedStringArray()
	for line: String in source.split("\n"):
		var code: String = line.get_slice("#", 0)
		for hit: RegExMatch in words.search_all(code):
			if named.has(hit.get_string()) and not used.has(hit.get_string()):
				used.append(hit.get_string())
	return used


func _write_probe() -> void:
	_remove_probe()
	for folder: String in ["", "/deep", "/.hidden", "/ignored", "/other_project"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PROBE_DIR + folder))
	_write("/seen.gd", "class_name ProbeSeen\nextends Node\n")
	_write("/deep/late.gd", "## A long header.\n".repeat(60) + "@tool\nextends Node\nclass_name ProbeLate extends Node\n\nvar x: int = 0\n")
	_write("/deep/after.gd", "extends Node\n\nfunc _ready() -> void:\n\tpass\n\nclass_name ProbeAfter\n")
	_write("/deep/unnamed.gd", "extends Node\n")
	_write("/deep/notes.txt", "class_name ProbeText\n")
	_write("/.hidden/hidden.gd", "class_name ProbeHidden\n")
	_write("/ignored/.gdignore", "")
	_write("/ignored/ignored.gd", "class_name ProbeIgnored\n")
	_write("/other_project/project.godot", "")
	_write("/other_project/other.gd", "class_name ProbeOther\n")


func _write(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(PROBE_DIR + path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)


func _remove_probe() -> void:
	for path: String in ["/seen.gd", "/deep/late.gd", "/deep/after.gd", "/deep/unnamed.gd", "/deep/notes.txt", "/.hidden/hidden.gd", "/ignored/.gdignore",
			"/ignored/ignored.gd", "/other_project/project.godot", "/other_project/other.gd", "/deep", "/.hidden", "/ignored", "/other_project", ""]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROBE_DIR + path))
