## Small JSON files in user:// (docs/13_PLAYTEST_KAIZEN_UPDATE_PROMPT.md §2.2): the
## machine's settings today. Writes go to a temporary file first and are then
## renamed over the old one, so a crash mid-write never leaves half a file.
## The family's progress save stays PartyProgress's own (a ConfigFile).
class_name SaveManager
extends RefCounted


## The JSON object at `path`, or {} when there is none (or it isn't a JSON object).
static func load_json(path: String) -> Dictionary:
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


## Writes `data` to `path` as pretty JSON. Returns OK or the error.
static func save_json(path: String, data: Dictionary) -> Error:
	if path == "":
		return ERR_FILE_BAD_PATH
	var temporary: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t", true))
	file.close()
	var error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
	return error


## Deletes the file at `path` if there is one (the tests' scratch settings).
static func remove(path: String) -> void:
	if path != "" and FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
