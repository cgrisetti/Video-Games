## The tales on this machine (docs/22_TITLE_SCREEN_AND_TALES.md): each New Game
## writes its own save file in user://saves/, and Continue lists them, newest
## played first. The family's save from before the title screen
## (PartyProgress.SAVE_PATH) is listed too, so no progress is left behind.
##
## A save file is PartyProgress's ConfigFile; its [hero] section holds the
## hero's name and when the tale was begun and last played.
class_name SaveSlots
extends RefCounted

const SLOT_FOLDER: String = "user://saves/"
const MAX_NAME_LENGTH: int = 16
## What the family's older save is called when it has no hero's name yet.
const FAMILY_TALE_NAME: String = "The Family Tale"
## Names to suggest for a new hero: short, warm, easy to say aloud.
const SUGGESTED_NAMES: Array[String] = [
	"Wren", "Pip", "Tamsin", "Bram", "Hazel", "Robin", "Ned", "Elsie", "Tobin", "Posy", "Fenn", "Mabry", "Hollis", "Ivy", "Jory", "Nell",
]

## Where the tales live (tests point it at a scratch folder) and the family's older save.
static var folder: String = SLOT_FOLDER
static var family_save: String = PartyProgress.SAVE_PATH


## A hero's name made tidy: letters, spaces, hyphens and apostrophes, trimmed, at most MAX_NAME_LENGTH.
static func clean_name(raw: String) -> String:
	var kept: String = ""
	for index: int in raw.length():
		var c: String = raw[index]
		if c == " " or c == "-" or c == "'" or (c.to_upper() != c.to_lower()):
			kept += c
	while kept.contains("  "):
		kept = kept.replace("  ", " ")
	return kept.strip_edges().left(MAX_NAME_LENGTH).strip_edges()


## A name to suggest, different from `previous` when it can be.
static func suggest_name(rng: RandomNumberGenerator, previous: String = "") -> String:
	var pick: String = SUGGESTED_NAMES[rng.randi_range(0, SUGGESTED_NAMES.size() - 1)]
	if pick == previous:
		pick = SUGGESTED_NAMES[(SUGGESTED_NAMES.find(pick) + 1) % SUGGESTED_NAMES.size()]
	return pick


## A fresh save file's path for a new tale: the hero's name and the moment it began, so two Wrens never share a file.
static func new_slot_path(hero: String) -> String:
	var slug: String = clean_name(hero).to_lower().replace(" ", "_").replace("'", "").replace("-", "_")
	if slug == "":
		slug = "hero"
	var path: String = "%s%s_%d.cfg" % [folder, slug, int(Time.get_unix_time_from_system())]
	var suffix: int = 2
	while FileAccess.file_exists(path):
		path = "%s%s_%d_%d.cfg" % [folder, slug, int(Time.get_unix_time_from_system()), suffix]
		suffix += 1
	return path


## Makes sure the tales' folder exists.
static func ensure_folder() -> Error:
	return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))


## Every tale, newest played first: {path, name, level, chimes, last_played, family}.
static func list() -> Array[Dictionary]:
	var tales: Array[Dictionary] = []
	var dir: DirAccess = DirAccess.open(folder)
	if dir != null:
		for file_name: String in dir.get_files():
			if file_name.get_extension() == "cfg":
				var tale: Dictionary = summary(folder.path_join(file_name))
				if not tale.is_empty():
					tales.append(tale)
	if family_save != "" and FileAccess.file_exists(family_save):
		var family: Dictionary = summary(family_save)
		if not family.is_empty():
			family["family"] = true
			if str(family["name"]) == "":
				family["name"] = FAMILY_TALE_NAME
			tales.append(family)
	tales.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["last_played"]) > int(b["last_played"]))
	return tales


## One save file's summary ({} if it can't be read).
static func summary(path: String) -> Dictionary:
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		return {}
	var last_played: int = int(file.get_value("hero", "last_played", 0))
	if last_played <= 0:
		last_played = int(FileAccess.get_modified_time(path))
	return {
		"path": path,
		"name": str(file.get_value("hero", "name", "")),
		"level": PartyProgress.level_for_xp(int(file.get_value("trail", "xp", 0))),
		"chimes": maxi(0, int(file.get_value("party", "chimes", 0))),
		"last_played": last_played,
		"family": false,
	}


## "just now", "5 minutes ago", "3 hours ago", "yesterday", "4 days ago", or a date.
static func when_text(unix: int, now: int = -1) -> String:
	var at: int = int(Time.get_unix_time_from_system()) if now < 0 else now
	var gap: int = maxi(0, at - unix)
	if gap < 90:
		return "just now"
	if gap < 3600:
		return "%d minutes ago" % roundi(gap / 60.0)
	if gap < 86400:
		var hours: int = roundi(gap / 3600.0)
		return "an hour ago" if hours == 1 else "%d hours ago" % hours
	if gap < 172800:
		return "yesterday"
	if gap < 604800:
		return "%d days ago" % int(gap / 86400.0)
	var date: Dictionary = Time.get_date_dict_from_unix_time(unix)
	return "%d %s %d" % [int(date["day"]), ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][int(date["month"]) - 1], int(date["year"])]
