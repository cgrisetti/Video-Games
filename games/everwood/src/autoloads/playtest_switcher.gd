## The playtest switcher (Phase 12 Kaizen, K2): one press steps a hero through
## a test matrix of Callings at trail Levels 3, 7 and 12, so a playtester can
## try each role at each stage without grinding. F2 on the keyboard; on a pad,
## hold Share (Create / View) and tap the D-Pad → (next) or ← (back).
##
## Each step re-seats the hero's Fellowship, gives it the Calling (below
## Level 10 too: this is a test), the trail's kit for that level (its weapon
## tier and its cards) and a Grimoire level to match, then shows a toast
## ("Debug Switch: Bridge-Warden Lv 7"). The trail tops out at Level 10, so
## Level 12 wears Level 10's gear. From the first step on the session is a
## playtest: PartyProgress saves nothing more (the family's save stays as it was).
## The host decides, like every seat change.
class_name PlaytestSwitcher
extends RefCounted

## [Calling id, trail level] in order.
const MATRIX: Array[Array] = [
	[&"bridge_warden", 3], [&"bridge_warden", 7], [&"bridge_warden", 12],
	[&"hedge_runner", 3], [&"hedge_runner", 7], [&"hedge_runner", 12],
	[&"bell_keeper", 3], [&"bell_keeper", 7], [&"bell_keeper", 12],
]
## The Grimoire level each step plays at (by its trail level).
const GRIMOIRE_FOR_LEVEL: Dictionary[int, int] = {3: 1, 7: 2, 12: 4}
const TOAST_TIME: float = 2.5
const TOAST_COLOR: Color = Color(0.62, 0.9, 1.0)

## Each device's place in the matrix (-1 before its first press).
static var _cursor: Dictionary[int, int] = {}


static func entry(index: int) -> Dictionary:
	var row: Array = MATRIX[posmod(index, MATRIX.size())]
	var calling: CallingResource = _calling(row[0])
	return {"calling_id": row[0], "level": int(row[1]), "calling": calling,
		"class_id": calling.fellowship_class_id if calling != null else &"", "secondary_id": calling.secondary_id if calling != null else &""}


static func cursor(device_id: int) -> int:
	return _cursor.get(device_id, -1)


static func reset() -> void:
	_cursor.clear()


## The toast for a step.
static func toast_text(index: int) -> String:
	var step: Dictionary = entry(index)
	var calling: CallingResource = step["calling"]
	return "Debug Switch: %s Lv %d" % [calling.display_name if calling != null else String(step["calling_id"]), int(step["level"])]


## Steps `device_id`'s hero `step` places through the matrix (host or offline). Returns the toast, or why not.
static func step_hero(level: LevelBase, device_id: int, step: int) -> String:
	var network: NetworkManager = NetworkManager.current
	if network.is_online() and not network.is_host():
		return "The Debug Switch works on the host's screen"
	var seat: PartyMember = network.member(PartyMember.make_player_id(network.local_peer_id(), device_id))
	if seat == null:
		return ""
	var index: int = posmod(cursor(device_id) + step, MATRIX.size()) if cursor(device_id) >= 0 or step > 0 else MATRIX.size() - 1
	_cursor[device_id] = index
	var wanted: Dictionary = entry(index)
	var shown_level: int = wanted["level"]
	PartyProgress.current.start_playtest(shown_level, GRIMOIRE_FOR_LEVEL.get(shown_level, 1))
	if CalderaWorldState.current != null:
		CalderaWorldState.current.playtest = true
	var class_id: StringName = wanted["class_id"]
	if seat.class_id != class_id:
		network.update_local_player(device_id, class_id, seat.assist_mode)
	var role: int = ClassLoadouts.player_class(class_id).role
	var kit: Dictionary = ArsenalCatalog.current.trail_kit_for_role(role, PartyProgress.current.trail_level()).to_dict()
	network.grant_seat(seat.player_id, kit, wanted["secondary_id"])
	return toast_text(index)


static func _calling(id: StringName) -> CallingResource:
	for calling: CallingResource in ArsenalCatalog.current.callings():
		if calling.calling_id == id:
			return calling
	return null
