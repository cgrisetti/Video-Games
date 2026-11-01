## The party's progress (autoload "Progress"): the Dojo Shards earned from raid
## chests, saved between sessions in user://everwood_progress.cfg.
##
## The whole party shares one pouch, like a family purse. The host owns it:
## other peers are shown the host's copy while they're connected and never
## save it, and leaving the host brings their own back.
class_name PartyProgress
extends Node

signal progress_changed

const SAVE_PATH: String = "user://everwood_progress.cfg"

## The live autoload node (see NetworkManager.current for why).
static var current: PartyProgress

var shards: int = 0
## Where progress is saved (the smoke test points this at its own file).
var save_path: String = SAVE_PATH

## True on a client while it shows the host's progress instead of its own.
var _showing_host: bool = false


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


func _ready() -> void:
	load_save()
	multiplayer.peer_connected.connect(_on_peer_connected)
	NetworkManager.current.status_changed.connect(_on_status_changed)


# --- Earning --------------------------------------------------------------

## Adds shards to the party's pouch. Host only; other peers get the new total.
func award_shards(amount: int) -> void:
	if not NetworkManager.current.is_host() or amount <= 0:
		return
	shards += amount
	_commit()


# --- Saving ---------------------------------------------------------------

## Switches to another save file and loads it.
func use_save_file(path: String) -> void:
	save_path = path
	load_save()


func load_save() -> void:
	_showing_host = false
	shards = 0
	var file: ConfigFile = ConfigFile.new()
	if file.load(save_path) == OK:
		shards = maxi(0, int(file.get_value("party", "shards", 0)))
	progress_changed.emit()


func save() -> Error:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("party", "shards", shards)
	return file.save(save_path)


## Saves (unless this is a copy of the host's), tells the game, and shares it.
func _commit() -> void:
	if not _showing_host:
		var error: Error = save()
		if error != OK:
			push_warning("PartyProgress: couldn't save %s (%s)" % [save_path, error_string(error)])
	progress_changed.emit()
	if NetworkManager.current.is_online() and NetworkManager.current.is_host():
		_receive_progress.rpc(_snapshot())


func _snapshot() -> Dictionary:
	return {"shards": shards}


# --- Network --------------------------------------------------------------

func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_receive_progress.rpc_id(peer_id, _snapshot())


@rpc("authority", "call_remote", "reliable")
func _receive_progress(data: Dictionary) -> void:
	_showing_host = true
	shards = int(data.get("shards", 0))
	progress_changed.emit()


func _on_status_changed(_text: String) -> void:
	# Back offline after visiting a host: show our own progress again.
	if _showing_host and not NetworkManager.current.is_online():
		load_save()
