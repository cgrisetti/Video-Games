## The Caldera Isles' world state (autoload "Caldera";
## docs/20_CALDERA_ATLAS_AND_CROWN_BIBLE.md, the Musk Razor locks): eight
## booleans and the sea level they move, plus Embershore's two (docs/27 §9),
## nothing else.
##
##   root_sanctum_cleared   Embershore's Lv 6 capstone: the trade lanes go
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
##   wheel_stopped          Embershore's mill-wheel stops once the party reaches
##                          Lv 5 (the Elder Oak's roots choke the weir); it turns
##                          again when the Root-Sanctum is cleared
##   downs_gate_open        Embershore's Downs Gate, opened from the Hearthstead
##                          side, stays open
##
## Act I's timed Ebb-Tide (docs/28 §6.1, docs/29 §4; the Bible's "GlobalTidalClock"): before
## the Harmonic Bell's permanent ebb, ringing North Quay's tide-bell opens a window: the
## sea falls 0 to -6 m over EBB_WINDOW_FALL, stays out EBB_WINDOW_OUT, then floods back
## over EBB_WINDOW_FLOOD. It is never saved; the permanent ebb (ebb_unlocked) wins.
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
## The timed Ebb-Tide window moved on (Tide), on every peer.
signal tide_changed(tide: int)

## The tide's phases in a timed window.
enum Tide { HIGH, EBBING, EBB, FLOODING }

const ROOT_SANCTUM_CLEARED: StringName = &"root_sanctum_cleared"
const BEACON_IRON: StringName = &"beacon_iron"
const BEACON_TIDE: StringName = &"beacon_tide"
const BEACON_GALE: StringName = &"beacon_gale"
const TRIAL_ANVIL_COMPLETE: StringName = &"trial_anvil_complete"
const TRIAL_GALE_COMPLETE: StringName = &"trial_gale_complete"
const TRIAL_TIDE_COMPLETE: StringName = &"trial_tide_complete"
const EBB_UNLOCKED: StringName = &"ebb_unlocked"
const WHEEL_STOPPED: StringName = &"wheel_stopped"
const DOWNS_GATE_OPEN: StringName = &"downs_gate_open"
## The authoritative booleans, in save-bit order (the eight of docs/20, then Embershore's two).
const FLAGS: Array[StringName] = [ROOT_SANCTUM_CLEARED, BEACON_IRON, BEACON_TIDE, BEACON_GALE,
	TRIAL_ANVIL_COMPLETE, TRIAL_GALE_COMPLETE, TRIAL_TIDE_COMPLETE, EBB_UNLOCKED, WHEEL_STOPPED, DOWNS_GATE_OPEN]
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
## Act I's timed window (docs/28 §6.1): the fall, the time out, the flood.
const EBB_WINDOW_FALL: float = 20.0
const EBB_WINDOW_OUT: float = 240.0
const EBB_WINDOW_FLOOD: float = 30.0
const TIDE_NAMES: Array[String] = ["HIGH WATER", "EBBING", "EBB-TIDE", "FLOODING"]

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
var wheel_stopped: bool = false
var downs_gate_open: bool = false

## Where the sea stands right now (it eases from 0 to -6 over the Ebb).
var sea_level_y: float = SEA_LEVEL_FLOOD
## --boot-zone=crown: the Crown landing is open for playtesting without the Beacons.
var playtest_crown_landing: bool = false
## Set by playtest warps; while it's on, flag changes stay out of the save.
var playtest: bool = false

var _ebb_elapsed: float = -1.0
## Seconds into a timed Ebb-Tide window (-1: none).
var _window_elapsed: float = -1.0
var _tide: Tide = Tide.HIGH
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
	_tick_window(delta)
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


## Whether the party has earned a Scribe Sign at a Beacon (Warm-Hearth is Embershore's own).
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
	if ebb_unlocked:
		return SEA_LEVEL_EBB
	return window_sea_level() if _window_elapsed >= 0.0 else SEA_LEVEL_FLOOD


# --- Act I's timed Ebb-Tide (the Tidal Horologium reads these) ----------------------------

## Host: rings the tide out (North Quay's tide-bell). False while a window runs or the sea
## is already out for good.
func start_ebb_window() -> bool:
	if not _may_decide() or ebb_unlocked or _window_elapsed >= 0.0:
		return false
	_window_elapsed = 0.0
	_broadcast_window()
	_tick_window(0.0)
	return true


func tide() -> Tide:
	if ebb_unlocked:
		return Tide.EBB
	return _tide


## Whether the timed window has the sea out (the Old Quay's shelf is dry).
func ebb_window_open() -> bool:
	return tide() == Tide.EBB


## Seconds until the tide's next turn in the window (0 at high water).
func tide_seconds_left() -> float:
	if _window_elapsed < 0.0 or ebb_unlocked:
		return 0.0
	var marks: Array[float] = [EBB_WINDOW_FALL, EBB_WINDOW_FALL + EBB_WINDOW_OUT, EBB_WINDOW_FALL + EBB_WINDOW_OUT + EBB_WINDOW_FLOOD]
	for mark: float in marks:
		if _window_elapsed < mark:
			return mark - _window_elapsed
	return 0.0


## The Tidal Horologium's line: "EBB-TIDE · the flood in 3:12".
func tide_dial_text() -> String:
	if ebb_unlocked:
		return "EBB-TIDE · the Long Flood is over"
	var left: int = ceili(tide_seconds_left())
	var clock: String = "%d:%02d" % [floori(left / 60.0), left % 60]
	match tide():
		Tide.EBBING:
			return "EBBING · the shelf bares in %s" % clock
		Tide.EBB:
			return "EBB-TIDE · the flood in %s" % clock
		Tide.FLOODING:
			return "FLOODING · high water in %s" % clock
	return "HIGH WATER · ring the tide-bell at North Quay"


## Where the sea stands this far into a window.
func window_sea_level() -> float:
	var t: float = _window_elapsed
	if t < EBB_WINDOW_FALL:
		return lerpf(SEA_LEVEL_FLOOD, SEA_LEVEL_EBB, smoothstep(0.0, 1.0, t / EBB_WINDOW_FALL))
	t -= EBB_WINDOW_FALL
	if t < EBB_WINDOW_OUT:
		return SEA_LEVEL_EBB
	t -= EBB_WINDOW_OUT
	return lerpf(SEA_LEVEL_EBB, SEA_LEVEL_FLOOD, smoothstep(0.0, 1.0, clampf(t / EBB_WINDOW_FLOOD, 0.0, 1.0)))


## Tests: jumps a running window forward.
func advance_window_for_testing(seconds: float) -> void:
	if _window_elapsed >= 0.0:
		_tick_window(seconds)


func _tick_window(delta: float) -> void:
	if _window_elapsed < 0.0 or ebb_unlocked:
		return
	_window_elapsed += delta
	var total: float = EBB_WINDOW_FALL + EBB_WINDOW_OUT + EBB_WINDOW_FLOOD
	var next: Tide = Tide.EBBING
	if _window_elapsed >= total:
		next = Tide.HIGH
	elif _window_elapsed >= EBB_WINDOW_FALL + EBB_WINDOW_OUT:
		next = Tide.FLOODING
	elif _window_elapsed >= EBB_WINDOW_FALL:
		next = Tide.EBB
	if _ebb_elapsed < 0.0:
		_set_sea(window_sea_level() if next != Tide.HIGH else SEA_LEVEL_FLOOD)
	if next == Tide.HIGH:
		_window_elapsed = -1.0
	if next != _tide:
		_tide = next
		tide_changed.emit(next)


func _broadcast_window() -> void:
	if NetworkManager.current == null or not NetworkManager.current.is_online():
		return
	for peer_id: int in multiplayer.get_peers():
		_receive_window.rpc_id(peer_id, _window_elapsed)


@rpc("authority", "call_remote", "reliable")
func _receive_window(elapsed: float) -> void:
	_window_elapsed = elapsed
	_tick_window(0.0)


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
	_window_elapsed = -1.0
	_tide = Tide.HIGH
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
		if _window_elapsed >= 0.0:
			_receive_window.rpc_id(peer_id, _window_elapsed)


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
