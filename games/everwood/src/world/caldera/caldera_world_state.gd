## The Caldera Isles' world state (autoload "Caldera";
## docs/20_CALDERA_ATLAS_AND_CROWN_BIBLE.md, the Musk Razor locks): eight
## booleans and the sea level they move, nothing else.
##
##   root_sanctum_cleared   Oakshire Holm's Lv 6 capstone: the trade lanes go
##                          dark and the West Strait, Eel Spit and Salt Road open
##   beacon_iron / _tide / _gale
##                          one flag, three effects: its stall at Hearthstead
##                          Market stocks, its current round The Crown calms,
##                          and its Sign is earned (sign_granted)
##   trial_anvil_complete / _gale_ / _tide_
##                          The Crown's three open-air trials: each blooms one
##                          bough of the World-Tree; all three open the One Stair
##   ebb_unlocked           the Harmonic Bell rung together: the Long Flood ends
##                          and the sea falls from 0 m to -6 m on every isle
##
## can_land_on_crown() and cliff_stair_open() are derived, never stored. The host
## decides every change and tells the other peers; the flags ride in the party's
## save (PartyProgress.caldera_flags). Playtest warps (--boot-zone, F9) set
## `playtest`, and nothing changed while playtesting is saved.
class_name CalderaWorldState
extends Node

signal flag_changed(flag: StringName, value: bool)
signal sea_level_changed(sea_y: float)
signal ebb_started
signal ebb_finished

const ROOT_SANCTUM_CLEARED: StringName = &"root_sanctum_cleared"
const BEACON_IRON: StringName = &"beacon_iron"
const BEACON_TIDE: StringName = &"beacon_tide"
const BEACON_GALE: StringName = &"beacon_gale"
const TRIAL_ANVIL_COMPLETE: StringName = &"trial_anvil_complete"
const TRIAL_GALE_COMPLETE: StringName = &"trial_gale_complete"
const TRIAL_TIDE_COMPLETE: StringName = &"trial_tide_complete"
const EBB_UNLOCKED: StringName = &"ebb_unlocked"
## The eight authoritative booleans, in save-bit order.
const FLAGS: Array[StringName] = [ROOT_SANCTUM_CLEARED, BEACON_IRON, BEACON_TIDE, BEACON_GALE,
	TRIAL_ANVIL_COMPLETE, TRIAL_GALE_COMPLETE, TRIAL_TIDE_COMPLETE, EBB_UNLOCKED]
## A seam's gate id meaning "open once can_land_on_crown()".
const CROWN_LANDING: StringName = &"crown_landing"
## The three Crown trials, by id.
const TRIAL_ANVIL: StringName = &"trial_anvil"
const TRIAL_GALE: StringName = &"trial_gale"
const TRIAL_TIDE: StringName = &"trial_tide"
const TRIALS: Array[StringName] = [TRIAL_ANVIL, TRIAL_GALE, TRIAL_TIDE]

## The Long Flood's sea, and the sea after the Ebb (metres).
const SEA_LEVEL_FLOOD: float = 0.0
const SEA_LEVEL_EBB: float = -6.0
## The Ebb cinematic's length: the sea falls over exactly this long.
const EBB_SECONDS: float = 10.0

## The live autoload node (reach it as CalderaWorldState.current from scripts
## compiled before autoloads, like the other autoloads).
static var current: CalderaWorldState

var root_sanctum_cleared: bool = false
var beacon_iron: bool = false
var beacon_tide: bool = false
var beacon_gale: bool = false
var trial_anvil_complete: bool = false
var trial_gale_complete: bool = false
var trial_tide_complete: bool = false
var ebb_unlocked: bool = false

## Where the sea stands right now (it eases from 0 to -6 over the Ebb).
var sea_level_y: float = SEA_LEVEL_FLOOD
## --boot-zone=crown: the Crown landing is open for playtesting without the Beacons.
var playtest_crown_landing: bool = false
## Set by playtest warps; while it's on, flag changes stay out of the save.
var playtest: bool = false

var _ebb_elapsed: float = -1.0
## The bits last read from or written to the save.
var _saved_bits: int = -1


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


func _ready() -> void:
	_adopt_saved_bits()
	if PartyProgress.current != null:
		PartyProgress.current.progress_changed.connect(_on_progress_changed)
	multiplayer.peer_connected.connect(_on_peer_connected)


func _process(delta: float) -> void:
	if _ebb_elapsed < 0.0:
		return
	_ebb_elapsed += delta
	var t: float = clampf(_ebb_elapsed / EBB_SECONDS, 0.0, 1.0)
	_set_sea(lerpf(SEA_LEVEL_FLOOD, SEA_LEVEL_EBB, smoothstep(0.0, 1.0, t)))
	if t >= 1.0:
		_ebb_elapsed = -1.0
		ebb_finished.emit()


# --- Reading --------------------------------------------------------------

func get_flag(flag: StringName) -> bool:
	return FLAGS.has(flag) and bool(get(flag))


## The eight flags as save bits (bit i is FLAGS[i]).
func bits() -> int:
	var packed: int = 0
	for index: int in FLAGS.size():
		if bool(get(FLAGS[index])):
			packed |= 1 << index
	return packed


## All three Beacons lit: The Crown's currents are calm and its landing opens
## (or a --boot-zone=crown playtest).
func can_land_on_crown() -> bool:
	return (beacon_iron and beacon_tide and beacon_gale) or playtest_crown_landing


## All three trials done: the One Cliff Stair's Resonance Barrier is down.
func cliff_stair_open() -> bool:
	return trial_anvil_complete and trial_gale_complete and trial_tide_complete


## Whether a lane (a seam's gate id) is open.
func lane_open(gate: StringName) -> bool:
	if gate == &"":
		return true
	if gate == CROWN_LANDING:
		return can_land_on_crown()
	return get_flag(gate)


## Whether the party has earned a Scribe Sign at a Beacon (Warm-Hearth is Oakshire Holm's own).
func sign_granted(scribe_sign: int) -> bool:
	match scribe_sign:
		ScribeSignResource.Sign.SIGN_IRON_ROOT:
			return beacon_iron
		ScribeSignResource.Sign.SIGN_STAR_TIDE:
			return beacon_tide
		ScribeSignResource.Sign.SIGN_RIME_GALE:
			return beacon_gale
		ScribeSignResource.Sign.SIGN_WARM_HEARTH:
			return true
	return false


## The trial flag of a trial id (&"" for none).
static func trial_flag(trial: StringName) -> StringName:
	match trial:
		TRIAL_ANVIL:
			return TRIAL_ANVIL_COMPLETE
		TRIAL_GALE:
			return TRIAL_GALE_COMPLETE
		TRIAL_TIDE:
			return TRIAL_TIDE_COMPLETE
	return &""


func trial_complete(trial: StringName) -> bool:
	return get_flag(trial_flag(trial))


func target_sea_level() -> float:
	return SEA_LEVEL_EBB if ebb_unlocked else SEA_LEVEL_FLOOD


## Whether the sea is still falling.
func ebb_in_progress() -> bool:
	return _ebb_elapsed >= 0.0


# --- Changing (host) ------------------------------------------------------

## Sets one flag. Only the host (or a party playing offline) may; returns
## whether it changed. The other peers hear it, and the save keeps it.
func set_flag(flag: StringName, value: bool) -> bool:
	if not FLAGS.has(flag) or not _may_decide():
		return false
	if not _apply(flag, value, true):
		return false
	_persist()
	_broadcast()
	return true


func clear_root_sanctum() -> bool:
	return set_flag(ROOT_SANCTUM_CLEARED, true)


## Lights an island's Beacon (by isle id): its lane, its current and its Sign.
func light_beacon(isle_id: StringName) -> bool:
	var isle: IslandGridResource = CalderaAtlas.isle(isle_id)
	if isle == null or isle.beacon_flag == &"":
		return false
	return set_flag(isle.beacon_flag, true)


func complete_trial(trial: StringName) -> bool:
	var flag: StringName = trial_flag(trial)
	return flag != &"" and set_flag(flag, true)


## The Harmonic Bell rang: the Long Flood ends. The sea falls -6 m over
## EBB_SECONDS on every isle (the level plays the cinematic alongside).
func trigger_the_ebb() -> bool:
	return set_flag(EBB_UNLOCKED, true)


## Puts the sea where the flags say at once (tests, and loading a save mid-ebb).
func settle_sea() -> void:
	_ebb_elapsed = -1.0
	_set_sea(target_sea_level())


## Clears every flag and playtest override without touching the save (tests).
func reset_for_testing() -> void:
	playtest = false
	playtest_crown_landing = false
	for flag: StringName in FLAGS:
		_apply(flag, false, false)
	settle_sea()


# --- Internals ------------------------------------------------------------

func _may_decide() -> bool:
	return NetworkManager.current == null or not NetworkManager.current.is_online() or NetworkManager.current.is_host()


func _apply(flag: StringName, value: bool, animate: bool) -> bool:
	if bool(get(flag)) == value:
		return false
	set(flag, value)
	if flag == EBB_UNLOCKED:
		if value and animate:
			_ebb_elapsed = 0.0
			ebb_started.emit()
		else:
			settle_sea()
	flag_changed.emit(flag, value)
	return true


func _set_sea(sea_y: float) -> void:
	if is_equal_approx(sea_y, sea_level_y):
		return
	sea_level_y = sea_y
	sea_level_changed.emit(sea_y)


func _persist() -> void:
	if playtest or PartyProgress.current == null:
		return
	_saved_bits = bits()
	PartyProgress.current.caldera_flags = _saved_bits
	PartyProgress.current.save()


func _broadcast() -> void:
	if NetworkManager.current == null or not NetworkManager.current.is_online():
		return
	for peer_id: int in multiplayer.get_peers():
		_receive_bits.rpc_id(peer_id, bits(), ebb_in_progress())


@rpc("authority", "call_remote", "reliable")
func _receive_bits(packed: int, ebb_falling: bool) -> void:
	for index: int in FLAGS.size():
		_apply(FLAGS[index], (packed & (1 << index)) != 0, ebb_falling)
	if not ebb_falling:
		settle_sea()


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_receive_bits.rpc_id(peer_id, bits(), false)


## A save was (re)loaded (use_save_file, a fresh boot): take its flags, unless a host decides for us.
func _on_progress_changed() -> void:
	if PartyProgress.current == null or PartyProgress.current.caldera_flags == _saved_bits:
		return
	if NetworkManager.current != null and NetworkManager.current.is_online() and not NetworkManager.current.is_host():
		return
	_adopt_saved_bits()


func _adopt_saved_bits() -> void:
	if PartyProgress.current == null:
		return
	_saved_bits = PartyProgress.current.caldera_flags
	for index: int in FLAGS.size():
		_apply(FLAGS[index], (_saved_bits & (1 << index)) != 0, false)
	settle_sea()
