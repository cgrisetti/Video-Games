extends Node

# The Top 10 boards, one for each game: the fastest times to pick every raspberry in Berry Rush
# (and, as the other games come over, theirs). Saved between visits in user://scores.cfg (on a
# Mac: ~/Library/Application Support/Godot/app_userdata/Lanternwood). The words are the same as
# the three.js game's.

signal changed(board: String)

const PATH := "user://scores.cfg"
const SIZE := 10
const NAME_LENGTH := 10
const BOARDS := {
	"berry-rush": {
		"title": "Top 10 Raspberry Pickers",
		"lower_is_better": true,
		"no_score": "The inch worm got you! Pick every raspberry to earn a place in the book.",
		"new_best": "A new fastest time: %s! Write your name in the book.",
		"top_ten": "%s is a Top 10 time! Write your name in the book.",
		"not_top_ten": "You picked them all in %s. Not quite a Top 10 time!",
		"saved": "Well picked, %s!",
		"best": "Best time: %s, by %s",
		"no_best": "No best time yet. Be the first!",
	},
}

const TEST_PATH := "user://scores-test.cfg" # The tools (godot --script ...) keep their own, so tests never touch yours.

var _boards := {} # Board -> [{"name", "score"}], best first.
var _path := PATH


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if "--script" in OS.get_cmdline_args():
		_path = TEST_PATH
	var file := ConfigFile.new()
	file.load(_path)
	for board in BOARDS:
		var saved: Array = file.get_value("boards", board, [])
		var list := []
		for entry in saved:
			if entry is Dictionary and entry.get("name") is String and (entry.get("score") is float or entry.get("score") is int):
				list.append({"name": entry.name, "score": float(entry.score)})
		_boards[board] = list.slice(0, SIZE)


func entries(board: String) -> Array:
	return _boards.get(board, [])


func best(board: String) -> Dictionary:
	var list := entries(board)
	return list[0] if not list.is_empty() else {}


# A line about the best score, for the game's card in the Glenn.
func best_line(board: String) -> String:
	var top := best(board)
	if top.is_empty():
		return BOARDS[board].no_best
	return BOARDS[board].best % [format(board, top.score), top.name]


# Would this score make the board?
func qualifies(board: String, score: float) -> bool:
	if score <= 0.0:
		return false
	var list := entries(board)
	return list.size() < SIZE or is_better(board, score, list[-1].score)


func is_better(board: String, a: float, b: float) -> bool:
	return a < b if BOARDS[board].lower_is_better else a > b


# Where a score would go: after every score that's as good or better.
func rank_for(board: String, score: float) -> int:
	var list := entries(board)
	for i in list.size():
		if is_better(board, score, list[i].score):
			return i
	return list.size()


# Write a name in the book. Returns the row it went in (0 is the top).
func add(board: String, name: String, score: float) -> int:
	var clean := name.strip_edges().left(NAME_LENGTH)
	if clean.is_empty():
		clean = "Gnome"
	var rank := rank_for(board, score)
	var list := entries(board)
	list.insert(rank, {"name": clean, "score": score})
	_boards[board] = list.slice(0, SIZE)
	_save()
	changed.emit(board)
	return rank


func reset(board: String) -> void:
	_boards[board] = []
	_save()
	changed.emit(board)


func words(board: String, key: String) -> String:
	return BOARDS[board][key]


func format(board: String, score: float) -> String:
	return format_time(score) if BOARDS[board].lower_is_better else str(int(score))


# A time as "37.4s", or "1:23.4" once it's a minute or more.
static func format_time(time: float) -> String:
	if time < 60.0:
		return "%.1fs" % time
	var tenths := roundi(time * 10.0)
	var minutes := tenths / 600
	return "%d:%04.1f" % [minutes, (tenths - minutes * 600) / 10.0]


func _save() -> void:
	var file := ConfigFile.new()
	for board in _boards:
		file.set_value("boards", board, _boards[board])
	file.save(_path)
