## The party's progress (autoload "Progress"): the Chimes earned on raids (07 GDD
## §1.2) and the upgrades bought with them at Bramble-Bridge's Chime-Shrine, the
## Scribe Card binder (collected copies, by copy key), each class's last kit and Calling,
## and the victories that set the Grimoire level, all saved between sessions
## in user://everwood_progress.cfg. Everything is ids and numbers, so the file
## (or a JSON or SQLite store later) never holds game data, only references.
##
## The party's trail level and XP live here too (the Trail of the Four Signs,
## 11_COMBAT_ONBOARDING_AND_FEEL_GDD.md §5.2): mobs, co-op gates and bosses pay
## XP, and each milestone level grants every Fellowship new gear and cards.
##
## Sign-Flow (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md) keeps two things here too: how
## often the party has seen each boss's Glimmer-Spot open (the windows tighten
## and the HUD rhyme goes quiet as the family learns them), and what the
## Reed-Light Scribery sells: Action-Leaves and Place-Cards for Chimes, and the
## Gilding Press's finer finishes.
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
## The party reached a new trail level, on every peer (the host then grants its milestone).
signal trail_level_reached(level: int)

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
## XP the trail pays the party (11 GDD §5.2).
const XP_PER_MOB: int = 35
const XP_PER_GATE: int = 80
const XP_PER_BOSS: int = 200
## Total XP for each trail level, Level 1 first. One expedition (7 mobs, the
## Gorge gate and the Cairnsman: 525 XP) reaches Level 5 at the Gatehouse; the
## second reaches Level 10 at the Cairnsman.
const LEVEL_XP: Array[int] = [0, 70, 105, 230, 320, 560, 700, 800, 850, 1050]

## The live autoload node (see NetworkManager.current for why).
static var current: PartyProgress

var chimes: int = 0
## Upgrade id -> levels bought.
var levels: Dictionary[StringName, int] = {}
## Card copy key ("rising_drive:shiny_foil") -> copies collected.
var collection: Dictionary[StringName, int] = {}
## Cairnsman wins; each one raises the Grimoire a level (LoadoutComposer).
var victories: int = 0
## The party's trail XP (trail_level reads the level from it).
var xp: int = 0
## Tests only (apply_full_endgame_kit_for_testing): new seats wear the classic
## full kits. Survives load_save, so a test that reloads its save keeps it.
var endgame_kits_for_testing: bool = false
## Class id -> the kit (EquipmentLoadoutResource.to_dict) its players last wore.
var kits: Dictionary[StringName, Dictionary] = {}
## Class id -> the Secondary Calling id its players last chose (&"swift_foot").
var callings: Dictionary[StringName, StringName] = {}
## Encounter id -> Glimmer-Spot openings the party has seen (14 GDD §3, N_seen).
var pattern_seen: Dictionary[StringName, int] = {}
## The Caldera Isles' eight world-state booleans as bits (CalderaWorldState.FLAGS order).
var caldera_flags: int = 0
## The playtest switcher (PlaytestSwitcher, K2) is in use: nothing more is saved this session.
var playtest: bool = false
## While playtesting, the trail level and Grimoire level the switcher chose (0: the party's own).
var playtest_level: int = 0
var playtest_grimoire: int = 0
## The host rolls chest cards with this (the smoke test seeds it).
var drop_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## The host rolls the expedition's finds (the Wayfarer's Chest) with this, so they never shift the boss's drops.
var trail_rng: RandomNumberGenerator = RandomNumberGenerator.new()
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
	if playtest_grimoire > 0:
		return playtest_grimoire
	return LoadoutComposer.grimoire_level(victories)


## The playtest switcher's level and Grimoire for this session (nothing more is saved).
func start_playtest(level: int, grimoire: int) -> void:
	playtest = true
	playtest_level = maxi(1, level)
	playtest_grimoire = clampi(grimoire, 1, LoadoutComposer.MAX_GRIMOIRE_LEVEL)
	progress_changed.emit()


## Tests only: the party's own level and Grimoire again, and saving back on.
func end_playtest() -> void:
	playtest = false
	playtest_level = 0
	playtest_grimoire = 0
	progress_changed.emit()


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


## The Secondary Calling id a class's players last chose (&"" if none was saved).
func calling_for(class_id: StringName) -> StringName:
	return callings.get(class_id, &"")


## Host only: remembers a class's Calling for its next seat (and next session).
func save_calling(class_id: StringName, calling: StringName) -> void:
	if not NetworkManager.current.is_host() or callings.get(class_id, &"") == calling or calling == Callings.UNSWORN_ID:
		return
	callings[class_id] = calling
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


# --- Glimmer-Spots (14 GDD §3) ----------------------------------------------

func pattern_seen_count(encounter_id: StringName) -> int:
	return pattern_seen.get(encounter_id, 0)


## Host only: one more sighting of a boss's Glimmer-Spot. Returns the count now.
func record_pattern_seen(encounter_id: StringName) -> int:
	if not NetworkManager.current.is_host() or encounter_id == &"":
		return pattern_seen_count(encounter_id)
	pattern_seen[encounter_id] = pattern_seen_count(encounter_id) + 1
	_commit()
	return pattern_seen[encounter_id]


# --- The Reed-Light Scribery (14 GDD §6) -------------------------------------

## Whether the party has a copy of a card in this finish (starters are free in Plain Vellum).
func owns_card(card_id: StringName, variant: int = ScribeCardResource.CardVariant.STANDARD) -> bool:
	return LoadoutComposer.owns(ScribeCardResource.copy_key(card_id, variant as ScribeCardResource.CardVariant), 1, collection)


## The finest finish the party owns of a card (-1 if it owns none).
func best_finish(card_id: StringName) -> int:
	for variant: int in range(ScribeCardResource.CardVariant.size() - 1, -1, -1):
		if owns_card(card_id, variant):
			return variant
	return -1


## Whether the Scribery sells this card: its Common Action-Leaves and the Place-Cards.
static func is_scribery_card(card_id: StringName) -> bool:
	var listed: ScribeCardResource = ArsenalCatalog.current.card(card_id)
	if listed == null:
		return false
	return listed.is_place_card() or ArsenalCatalog.current.scribery_leaves().has(listed)


## Chimes for a fresh Plain Vellum copy (an Action-Leaf inscribed, a Place-Card charted).
func scribery_cost(card_id: StringName) -> int:
	var listed: ScribeCardResource = ArsenalCatalog.current.card(card_id)
	return listed.chime_cost if listed != null else 0


## A leaf can be inscribed again (a second copy for another socket); a place is charted once and frames every socket.
func can_inscribe(card_id: StringName) -> bool:
	if not is_scribery_card(card_id) or chimes < scribery_cost(card_id):
		return false
	return not (ArsenalCatalog.current.card(card_id).is_place_card() and owns_card(card_id))


## Buys a Plain Vellum copy at the Scribery. The host checks the price and applies it.
func request_inscribe(card_id: StringName) -> void:
	if NetworkManager.current.is_host():
		_server_inscribe(card_id)
	elif NetworkManager.current.is_online():
		_request_inscribe.rpc_id(1, card_id)


func _server_inscribe(card_id: StringName) -> bool:
	if not can_inscribe(card_id):
		return false
	chimes -= scribery_cost(card_id)
	var key: StringName = ScribeCardResource.copy_key(card_id, ScribeCardResource.CardVariant.STANDARD)
	collection[key] = copies_of(key) + 1
	card_awarded.emit(key)
	_commit()
	return true


@rpc("any_peer", "call_remote", "reliable")
func _request_inscribe(card_id: StringName) -> void:
	if multiplayer.is_server():
		_server_inscribe(card_id)


## The Gilding Press's price to raise a copy one finish (0 when it's already Star-Inked Vellum).
static func gilding_cost(copy_key: StringName) -> int:
	var next: int = ScribeCardResource.copy_variant(copy_key) + 1
	return ScribeCardResource.GILDING_COSTS[next] if next < ScribeCardResource.GILDING_COSTS.size() else 0


## The press gilds an owned Action-Leaf or Place-Card: Plain Vellum to Gilded Leaf, Gilded Leaf to Star-Inked Vellum.
func can_gild(copy_key: StringName) -> bool:
	var listed: ScribeCardResource = ArsenalCatalog.current.card(ScribeCardResource.copy_card_id(copy_key))
	if listed == null or not (listed.is_action_leaf() or listed.is_place_card()):
		return false
	var cost: int = gilding_cost(copy_key)
	return cost > 0 and chimes >= cost and LoadoutComposer.owns(copy_key, 1, collection)


## Presses a finer copy of `copy_key` into the binder (the old copy stays). Host checks and applies.
func request_gild(copy_key: StringName) -> void:
	if NetworkManager.current.is_host():
		_server_gild(copy_key)
	elif NetworkManager.current.is_online():
		_request_gild.rpc_id(1, copy_key)


func _server_gild(copy_key: StringName) -> bool:
	if not can_gild(copy_key):
		return false
	chimes -= gilding_cost(copy_key)
	var finer: StringName = ScribeCardResource.copy_key(ScribeCardResource.copy_card_id(copy_key),
		(ScribeCardResource.copy_variant(copy_key) + 1) as ScribeCardResource.CardVariant)
	collection[finer] = copies_of(finer) + 1
	card_awarded.emit(finer)
	_commit()
	return true


@rpc("any_peer", "call_remote", "reliable")
func _request_gild(copy_key: StringName) -> void:
	if multiplayer.is_server():
		_server_gild(copy_key)


# --- The trail (11 GDD §5) -------------------------------------------------

## The party's trail level, 1 to 10.
func trail_level() -> int:
	if playtest_level > 0:
		return mini(playtest_level, LEVEL_XP.size())
	return level_for_xp(xp)


static func level_for_xp(amount: int) -> int:
	var level: int = 1
	for index: int in LEVEL_XP.size():
		if amount >= LEVEL_XP[index]:
			level = index + 1
	return level


## XP still to earn before the next level (0 at Level 10).
func xp_to_next_level() -> int:
	var level: int = trail_level()
	return 0 if level >= LEVEL_XP.size() else LEVEL_XP[level] - xp


## The Secondary Callings open at Level 10; until then every hero is Unsworn.
func callings_unlocked() -> bool:
	return trail_level() >= ArsenalCatalog.CALLING_LEVEL


## Host only: trail XP for the party (a mob, a gate, a boss). Each level it
## crosses is announced, so the level can grant its milestone.
func award_xp(amount: int) -> void:
	if not NetworkManager.current.is_host() or amount <= 0:
		return
	var before: int = trail_level()
	var gained: int = mini(xp + amount, LEVEL_XP.back())
	if gained == xp:
		return
	xp = gained
	_commit()
	for level: int in range(before + 1, trail_level() + 1):
		trail_level_reached.emit(level)


## The kit a fresh seat of this class wears at the party's trail level: the
## Level 1 kit with every milestone so far auto-slotted (ArsenalCatalog), or
## the classic full kit while apply_full_endgame_kit_for_testing is on.
func trail_kit(class_id: StringName) -> Dictionary:
	if endgame_kits_for_testing:
		return ClassLoadouts.starter_kit(class_id).to_dict()
	return ArsenalCatalog.current.trail_kit_for_role(ClassLoadouts.player_class(class_id).role, trail_level()).to_dict()


## The Iron-Woodsman's boot kit (19 GDD, Stage 1): the Wayfarers' saved kit
## (or the trail's, if none is saved or it no longer fits) in the Hedgerow
## Wool-Mantle with the best Broad-Axe the trail has opened. The Scribe Desk
## changes it as usual; the next boot starts from it again.
func iron_woodsman_kit() -> Dictionary:
	var kit: EquipmentLoadoutResource = EquipmentLoadoutResource.from_dict(trail_kit(ClassLoadouts.SOLO_BOOT_CLASS))
	var saved: Dictionary = kit_for(ClassLoadouts.SOLO_BOOT_CLASS)
	if not saved.is_empty():
		kit = EquipmentLoadoutResource.from_dict(saved)
	kit.armor_id = ClassLoadouts.SOLO_BOOT_ARMOR
	var tier: int = 1
	for index: int in ArsenalCatalog.TIER_LEVELS.size():
		if trail_level() >= ArsenalCatalog.TIER_LEVELS[index]:
			tier = index + 1
	kit.weapon_id = ArsenalCatalog.tier_weapon_id(ClassLoadouts.SOLO_BOOT_WEAPON_TYPE, tier)
	return kit.to_dict()


## Test helper (tools/smoke_test.gd): the party at Level 10, every Calling open,
## and every class in its classic full kit, as before the trail, so the older
## checks measure what they always measured. Never called by the game.
func apply_full_endgame_kit_for_testing() -> void:
	endgame_kits_for_testing = true
	xp = LEVEL_XP.back()
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
	xp = 0
	levels.clear()
	collection.clear()
	kits.clear()
	callings.clear()
	pattern_seen.clear()
	caldera_flags = 0
	var file: ConfigFile = ConfigFile.new()
	if file.load(save_path) == OK:
		# Saves from before the Chimes were called Dojo Shards keep their pouch.
		chimes = maxi(0, int(file.get_value("party", "chimes", file.get_value("party", "shards", 0))))
		victories = maxi(0, int(file.get_value("party", "victories", 0)))
		# A save from before the trail: each Cairnsman win stands for an
		# expedition (Level 5 after one, Level 10 after two), so no gear is lost.
		var migrated: int = [0, LEVEL_XP[4], LEVEL_XP.back()][mini(victories, 2)]
		xp = clampi(int(file.get_value("trail", "xp", migrated)), 0, LEVEL_XP.back())
		for id: StringName in UPGRADES:
			levels[id] = clampi(int(file.get_value("upgrades", String(id), 0)), 0, MAX_UPGRADE_LEVEL)
		_read_collection(file.get_value("cards", "collection", {}) as Dictionary)
		var saved_kits: Dictionary = file.get_value("kits", "by_class", {}) as Dictionary
		for class_id: Variant in saved_kits:
			kits[StringName(str(class_id))] = saved_kits[class_id] as Dictionary
		var saved_callings: Dictionary = file.get_value("callings", "by_class", {}) as Dictionary
		for class_id: Variant in saved_callings:
			var saved: Variant = saved_callings[class_id]
			# A column number from the first Callings build reads back as its id.
			callings[StringName(str(class_id))] = Callings.id_of(int(saved)) if saved is int else StringName(str(saved))
		_read_pattern_seen(file.get_value("glimmer", "seen", {}) as Dictionary)
		caldera_flags = maxi(0, int(file.get_value("caldera", "flags", 0)))
	progress_changed.emit()


func save() -> Error:
	# A playtest session (the switcher) never writes the family's save.
	if playtest:
		return OK
	var file: ConfigFile = ConfigFile.new()
	file.set_value("party", "chimes", chimes)
	file.set_value("party", "victories", victories)
	file.set_value("trail", "xp", xp)
	for id: StringName in UPGRADES:
		file.set_value("upgrades", String(id), level_of(id))
	file.set_value("cards", "collection", _plain_collection())
	var plain_kits: Dictionary = {}
	for class_id: StringName in kits:
		plain_kits[String(class_id)] = kits[class_id]
	file.set_value("kits", "by_class", plain_kits)
	var plain_callings: Dictionary = {}
	for class_id: StringName in callings:
		plain_callings[String(class_id)] = String(callings[class_id])
	file.set_value("callings", "by_class", plain_callings)
	file.set_value("glimmer", "seen", _plain_pattern_seen())
	file.set_value("caldera", "flags", caldera_flags)
	return file.save(save_path)


func _plain_pattern_seen() -> Dictionary:
	var plain: Dictionary = {}
	for id: StringName in pattern_seen:
		plain[String(id)] = pattern_seen[id]
	return plain


func _read_pattern_seen(plain: Dictionary) -> void:
	pattern_seen.clear()
	for id: Variant in plain:
		pattern_seen[StringName(str(id))] = maxi(0, int(plain[id]))


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
	return {"chimes": chimes, "levels": bought, "victories": victories, "xp": xp, "collection": _plain_collection(),
		"glimmer_seen": _plain_pattern_seen()}


# --- Network --------------------------------------------------------------

func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_receive_progress.rpc_id(peer_id, _snapshot())


@rpc("authority", "call_remote", "reliable")
func _receive_progress(data: Dictionary) -> void:
	# Levels crossed while we watch are celebrated; joining a party that's further along isn't.
	var level_before: int = trail_level() if _showing_host else LEVEL_XP.size()
	_showing_host = true
	chimes = int(data.get("chimes", 0))
	var bought: Dictionary = data.get("levels", {})
	for id: StringName in UPGRADES:
		levels[id] = clampi(int(bought.get(String(id), 0)), 0, MAX_UPGRADE_LEVEL)
	victories = maxi(0, int(data.get("victories", 0)))
	xp = clampi(int(data.get("xp", 0)), 0, LEVEL_XP.back())
	_read_collection(data.get("collection", {}) as Dictionary)
	_read_pattern_seen(data.get("glimmer_seen", {}) as Dictionary)
	progress_changed.emit()
	for level: int in range(level_before + 1, trail_level() + 1):
		trail_level_reached.emit(level)


func _on_status_changed(_text: String) -> void:
	# Back offline after visiting a host: show our own progress again.
	if _showing_host and not NetworkManager.current.is_online():
		load_save()
