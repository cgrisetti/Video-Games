## The party's progress (autoload "Progress"): the Chimes earned on raids (07 GDD
## §1.2) and the upgrades bought with them at Bramblebridge's Chime-Shrine, the
## Scribe Card binder (collected copies, by copy key), each class's last kit,
## and the victories that set the Grimoire level, all saved between sessions
## in user://everwood_progress.cfg. Everything is ids and numbers, so the file
## (or a JSON or SQLite store later) never holds game data, only references.
##
## The whole party shares one pouch and one set of upgrades, like a family
## purse: every player's base stats grow together. The host owns it: other
## peers are shown the host's copy while they're connected and never save it,
## and leaving the host brings their own back.
class_name PartyProgress
extends Node

signal progress_changed
## A card copy joined the binder (on the host, which awards cards).
signal card_awarded(copy_key: StringName)

const SAVE_PATH: String = "user://everwood_progress.cfg"
## Command line: --save=PATH plays from another save file (tests and demos use
## one, so they never touch the family's real progress).
const SAVE_ARG: String = "--save="
const MAX_HEALTH: StringName = &"max_health"
const STAMINA_REGEN: StringName = &"stamina_regen"
## What the Chime-Shrine sells, in menu order.
const UPGRADES: Array[StringName] = [MAX_HEALTH, STAMINA_REGEN]
## Each level adds this share of the class's own value (+10%).
const UPGRADE_STEP: float = 0.1
const MAX_UPGRADE_LEVEL: int = 5
## Level n costs this many Chimes times n: 4, 8, 12, 16, 20.
const UPGRADE_BASE_COST: int = 4

## The live autoload node (see NetworkManager.current for why).
static var current: PartyProgress

var chimes: int = 0
## Upgrade id -> levels bought.
var levels: Dictionary[StringName, int] = {}
## Card copy key ("rising_drive:shiny_foil") -> copies collected.
var collection: Dictionary[StringName, int] = {}
## Cairnsman wins; each one raises the Grimoire a level (LoadoutComposer).
var victories: int = 0
## Class id -> the kit (EquipmentLoadoutResource.to_dict) its players last wore.
var kits: Dictionary[StringName, Dictionary] = {}
## The host rolls chest cards with this (the smoke test seeds it).
var drop_rng: RandomNumberGenerator = RandomNumberGenerator.new()
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
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(SAVE_ARG):
			save_path = arg.trim_prefix(SAVE_ARG)
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


## Chimes the next level costs.
func cost_of(id: StringName) -> int:
	return UPGRADE_BASE_COST * (level_of(id) + 1)


func can_buy(id: StringName) -> bool:
	return UPGRADES.has(id) and not is_maxed(id) and chimes >= cost_of(id)


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
	chimes -= cost_of(id)
	levels[id] = level_of(id) + 1
	_commit()
	return true


@rpc("any_peer", "call_remote", "reliable")
func _request_purchase(id: StringName) -> void:
	if multiplayer.is_server():
		_server_purchase(id)


# --- Scribe Cards and the Grimoire ----------------------------------------

func grimoire_level() -> int:
	return LoadoutComposer.grimoire_level(victories)


func copies_of(copy_key: StringName) -> int:
	return collection.get(copy_key, 0)


## The kit a class's players last wore ({} if none was saved).
func kit_for(class_id: StringName) -> Dictionary:
	return kits.get(class_id, {})


## Host only: remembers a class's kit for its next seat (and next session).
func save_kit(class_id: StringName, kit: Dictionary) -> void:
	if not NetworkManager.current.is_host() or kits.get(class_id, {}) == kit:
		return
	kits[class_id] = kit.duplicate(true)
	_commit()


## Host only: a win over the Cairnsman.
func record_victory() -> void:
	if not NetworkManager.current.is_host():
		return
	victories += 1
	_commit()


## Host only: a card copy for the binder (a chest drop).
func award_card(copy_key: StringName) -> void:
	if not NetworkManager.current.is_host() or ArsenalCatalog.current.card(ScribeCardResource.copy_card_id(copy_key)) == null:
		return
	collection[copy_key] = copies_of(copy_key) + 1
	card_awarded.emit(copy_key)
	_commit()


# --- Earning --------------------------------------------------------------

## Adds Chimes to the party's pouch. Host only; other peers get the new total.
func award_chimes(amount: int) -> void:
	if not NetworkManager.current.is_host() or amount <= 0:
		return
	chimes += amount
	_commit()


# --- Saving ---------------------------------------------------------------

## Switches to another save file and loads it.
func use_save_file(path: String) -> void:
	save_path = path
	load_save()


func load_save() -> void:
	_showing_host = false
	chimes = 0
	victories = 0
	levels.clear()
	collection.clear()
	kits.clear()
	var file: ConfigFile = ConfigFile.new()
	if file.load(save_path) == OK:
		# Saves from before the Chimes were called Dojo Shards keep their pouch.
		chimes = maxi(0, int(file.get_value("party", "chimes", file.get_value("party", "shards", 0))))
		victories = maxi(0, int(file.get_value("party", "victories", 0)))
		for id: StringName in UPGRADES:
			levels[id] = clampi(int(file.get_value("upgrades", String(id), 0)), 0, MAX_UPGRADE_LEVEL)
		_read_collection(file.get_value("cards", "collection", {}) as Dictionary)
		var saved_kits: Dictionary = file.get_value("kits", "by_class", {}) as Dictionary
		for class_id: Variant in saved_kits:
			kits[StringName(str(class_id))] = saved_kits[class_id] as Dictionary
	progress_changed.emit()


func save() -> Error:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("party", "chimes", chimes)
	file.set_value("party", "victories", victories)
	for id: StringName in UPGRADES:
		file.set_value("upgrades", String(id), level_of(id))
	file.set_value("cards", "collection", _plain_collection())
	var plain_kits: Dictionary = {}
	for class_id: StringName in kits:
		plain_kits[String(class_id)] = kits[class_id]
	file.set_value("kits", "by_class", plain_kits)
	return file.save(save_path)


## The binder with plain String keys (for save files and RPCs).
func _plain_collection() -> Dictionary:
	var plain: Dictionary = {}
	for key: StringName in collection:
		plain[String(key)] = collection[key]
	return plain


## Reads a binder back, dropping copies of cards this build doesn't have.
func _read_collection(plain: Dictionary) -> void:
	collection.clear()
	for key: Variant in plain:
		var copy_key: StringName = StringName(str(key))
		if ArsenalCatalog.current.card(ScribeCardResource.copy_card_id(copy_key)) != null:
			collection[copy_key] = maxi(0, int(plain[key]))


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
	return {"chimes": chimes, "levels": bought, "victories": victories, "collection": _plain_collection()}


# --- Network --------------------------------------------------------------

func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_receive_progress.rpc_id(peer_id, _snapshot())


@rpc("authority", "call_remote", "reliable")
func _receive_progress(data: Dictionary) -> void:
	_showing_host = true
	chimes = int(data.get("chimes", 0))
	var bought: Dictionary = data.get("levels", {})
	for id: StringName in UPGRADES:
		levels[id] = clampi(int(bought.get(String(id), 0)), 0, MAX_UPGRADE_LEVEL)
	victories = maxi(0, int(data.get("victories", 0)))
	_read_collection(data.get("collection", {}) as Dictionary)
	progress_changed.emit()


func _on_status_changed(_text: String) -> void:
	# Back offline after visiting a host: show our own progress again.
	if _showing_host and not NetworkManager.current.is_online():
		load_save()
