## The party's progress (autoload "Progress"): the Dojo Shards earned from raid
## chests and the Hub Town upgrades bought with them at the Shard Vendor, saved
## between sessions in user://everwood_progress.cfg.
##
## The whole party shares one pouch and one set of upgrades, like a family
## purse: every player's base stats grow together. The host owns it: other
## peers are shown the host's copy while they're connected and never save it,
## and leaving the host brings their own back.
class_name PartyProgress
extends Node

signal progress_changed

const SAVE_PATH: String = "user://everwood_progress.cfg"
const MAX_HEALTH: StringName = &"max_health"
const STAMINA_REGEN: StringName = &"stamina_regen"
## What the Shard Vendor sells, in menu order.
const UPGRADES: Array[StringName] = [MAX_HEALTH, STAMINA_REGEN]
## Each level adds this share of the class's own value (+10%).
const UPGRADE_STEP: float = 0.1
const MAX_UPGRADE_LEVEL: int = 5
## Level n costs this many shards times n: 4, 8, 12, 16, 20.
const UPGRADE_BASE_COST: int = 4

## The live autoload node (see NetworkManager.current for why).
static var current: PartyProgress

var shards: int = 0
## Upgrade id -> levels bought.
var levels: Dictionary[StringName, int] = {}
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


# --- Upgrades -------------------------------------------------------------

static func upgrade_name(id: StringName) -> String:
	match id:
		MAX_HEALTH:
			return "Max Health"
		STAMINA_REGEN:
			return "Stamina Regen"
	return String(id)


static func upgrade_blurb(id: StringName) -> String:
	match id:
		MAX_HEALTH:
			return "+%d%% health for the whole party" % roundi(UPGRADE_STEP * 100.0)
		STAMINA_REGEN:
			return "+%d%% faster stamina for the whole party" % roundi(UPGRADE_STEP * 100.0)
	return ""


func level_of(id: StringName) -> int:
	return levels.get(id, 0)


func is_maxed(id: StringName) -> bool:
	return level_of(id) >= MAX_UPGRADE_LEVEL


## Shards the next level costs.
func cost_of(id: StringName) -> int:
	return UPGRADE_BASE_COST * (level_of(id) + 1)


func can_buy(id: StringName) -> bool:
	return UPGRADES.has(id) and not is_maxed(id) and shards >= cost_of(id)


func multiplier(id: StringName) -> float:
	return 1.0 + UPGRADE_STEP * level_of(id)


## Scales a player's stats by the party's upgrades; `base` holds the class's own numbers.
func apply_upgrades(stats: CharacterStatsResource, base: CharacterStatsResource) -> void:
	stats.max_health = base.max_health * multiplier(MAX_HEALTH)
	stats.stamina_regen_per_sec = base.stamina_regen_per_sec * multiplier(STAMINA_REGEN)


## Buys the next level of an upgrade. The host checks the price and applies it.
func request_purchase(id: StringName) -> void:
	if NetworkManager.current.is_host():
		_server_purchase(id)
	elif NetworkManager.current.is_online():
		_request_purchase.rpc_id(1, id)


func _server_purchase(id: StringName) -> bool:
	if not can_buy(id):
		return false
	shards -= cost_of(id)
	levels[id] = level_of(id) + 1
	_commit()
	return true


@rpc("any_peer", "call_remote", "reliable")
func _request_purchase(id: StringName) -> void:
	if multiplayer.is_server():
		_server_purchase(id)


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
	levels.clear()
	var file: ConfigFile = ConfigFile.new()
	if file.load(save_path) == OK:
		shards = maxi(0, int(file.get_value("party", "shards", 0)))
		for id: StringName in UPGRADES:
			levels[id] = clampi(int(file.get_value("upgrades", String(id), 0)), 0, MAX_UPGRADE_LEVEL)
	progress_changed.emit()


func save() -> Error:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("party", "shards", shards)
	for id: StringName in UPGRADES:
		file.set_value("upgrades", String(id), level_of(id))
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
	var bought: Dictionary = {}
	for id: StringName in UPGRADES:
		bought[String(id)] = level_of(id)
	return {"shards": shards, "levels": bought}


# --- Network --------------------------------------------------------------

func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_receive_progress.rpc_id(peer_id, _snapshot())


@rpc("authority", "call_remote", "reliable")
func _receive_progress(data: Dictionary) -> void:
	_showing_host = true
	shards = int(data.get("shards", 0))
	var bought: Dictionary = data.get("levels", {})
	for id: StringName in UPGRADES:
		levels[id] = clampi(int(bought.get(String(id), 0)), 0, MAX_UPGRADE_LEVEL)
	progress_changed.emit()


func _on_status_changed(_text: String) -> void:
	# Back offline after visiting a host: show our own progress again.
	if _showing_host and not NetworkManager.current.is_online():
		load_save()
