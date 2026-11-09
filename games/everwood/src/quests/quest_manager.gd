## The Quest & Milestone Manager (autoload "Quests"; docs/29 §3): plays the
## Master Quest Ledger's quests one at a time, step by step, from what the
## world reports, and pays what each one opens.
##
## The host decides everything. Any peer may report (a calm, a place reached,
## a word with a townsperson); a client's report goes to the host, which counts
## it against the step under way. The ledger itself lives in PartyProgress
## (quest_log, unlocks, items, stag_hunts), so it is saved with the party and
## shared with every peer like the rest of the party's progress, and a playtest
## session (PartyProgress.playtest) never writes it.
##
## XP: a quest's ledger XP is its whole budget. Calms during it pay their own
## XP as they happen (PartyProgress.XP_PER_MOB); handing the quest in tops the
## party up to the quest's cumulative XP (Q01: 400, Q05: 3,800), or pays a
## quarter of its XP when the party is already past it. So finishing Q01 is
## Level 2 and finishing Q05 is Level 6, however many foes were calmed.
class_name QuestManager
extends Node

signal quest_started(quest_id: StringName)
signal step_advanced(quest_id: StringName, step_index: int)
signal step_progressed(quest_id: StringName, count: int, needed: int)
signal quest_completed(quest_id: StringName)
signal unlocked(unlock_id: StringName)
## Anything in the ledger changed (on every peer, also when the host's copy arrives).
signal ledger_changed

enum QuestState { LOCKED, ACTIVE, COMPLETE }

const Kind = QuestStepResource.Kind
## A hand-in pays at least this share of the quest's XP.
const MIN_HAND_IN_SHARE: float = 0.25

static var current: QuestManager

var _last_seen: Dictionary = {}


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


func _ready() -> void:
	if PartyProgress.current != null:
		PartyProgress.current.progress_changed.connect(_on_progress_changed)
	_last_seen = _ledger().duplicate(true)


# --- Reading --------------------------------------------------------------------------

func state_of(quest_id: StringName) -> QuestState:
	var entry: Dictionary = _ledger().get(String(quest_id), {})
	return int(entry.get("state", QuestState.LOCKED)) as QuestState


func step_of(quest_id: StringName) -> int:
	return int((_ledger().get(String(quest_id), {}) as Dictionary).get("step", 0))


func count_of(quest_id: StringName) -> int:
	return int((_ledger().get(String(quest_id), {}) as Dictionary).get("count", 0))


func is_complete(quest_id: StringName) -> bool:
	return state_of(quest_id) == QuestState.COMPLETE


## The quest under way (&"" when none is: before Act I starts, or after Q05).
func active_quest_id() -> StringName:
	for quest_id: StringName in ActOneQuests.ORDER:
		if state_of(quest_id) == QuestState.ACTIVE:
			return quest_id
	return &""


func active_quest() -> QuestDefinition:
	var quest_id: StringName = active_quest_id()
	return ActOneQuests.quest(quest_id) if quest_id != &"" else null


func active_step() -> QuestStepResource:
	var quest: QuestDefinition = active_quest()
	return quest.step_at(step_of(quest.quest_id)) if quest != null else null


## Whether the step under way is this one (`step_id` of the active quest).
func is_on_step(quest_id: StringName, step_id: StringName) -> bool:
	var step: QuestStepResource = active_step()
	return active_quest_id() == quest_id and step != null and step.step_id == step_id


## Whether Act I has begun (Q01 started or further).
func act_one_started() -> bool:
	return state_of(ActOneQuests.Q01) != QuestState.LOCKED


func has_unlock(unlock_id: StringName) -> bool:
	return PartyProgress.current != null and PartyProgress.current.has_unlock(unlock_id)


func item_count(item_id: StringName) -> int:
	return PartyProgress.current.item_count(item_id) if PartyProgress.current != null else 0


## The tracker's line: "Q01 · Lee-Shore Awakening\nWear down the Bramble-Hounds, then calm them (3/6)".
func tracker_line() -> String:
	var quest: QuestDefinition = active_quest()
	if quest == null:
		return ""
	var step: QuestStepResource = quest.step_at(step_of(quest.quest_id))
	if step == null:
		return quest.label()
	var line: String = step.text
	if step.count > 1:
		line += " (%d/%d)" % [count_of(quest.quest_id), step.count]
	return "%s\n%s" % [quest.label(), line]


# --- Reporting (any peer) -------------------------------------------------------------

## The world says something happened: a calm (target = the variant), a place
## reached, a townsperson spoken to, an event, a boss's outcome. Counted by the
## host against the step under way; anything else is ignored.
func report(kind: Kind, target: StringName, amount: int = 1) -> void:
	if amount <= 0:
		return
	if _may_decide():
		_apply_report(kind, target, amount)
	else:
		_report_remote.rpc_id(1, int(kind), String(target), amount)


@rpc("any_peer", "call_remote", "reliable")
func _report_remote(kind: int, target: String, amount: int) -> void:
	if multiplayer.is_server():
		_apply_report(kind as Kind, StringName(target), amount)


# --- Changing (host) ------------------------------------------------------------------

## Starts Act I (Q01) if the party hasn't yet. Host only; true when it started it.
func start_act_one() -> bool:
	if not _may_decide() or act_one_started():
		return false
	_set_entry(ActOneQuests.Q01, QuestState.ACTIVE, 0, 0)
	_commit()
	quest_started.emit(ActOneQuests.Q01)
	_settle_step(ActOneQuests.Q01)
	return true


## Gives the party items (Living Cider-Resin from a shrine, the Warmth-Ember, the relic).
func add_item(item_id: StringName, amount: int = 1) -> void:
	if not _may_decide() or PartyProgress.current == null or amount == 0:
		return
	var key: String = String(item_id)
	PartyProgress.current.items[key] = maxi(0, int(PartyProgress.current.items.get(key, 0)) + amount)
	_commit()
	var quest_id: StringName = active_quest_id()
	if quest_id != &"":
		_settle_step(quest_id)


## A small saved mark the world keeps for itself (a grove cleared, the bridge mended),
## kept with the quest items under "mark:" so it rides in the same save and sync.
func mark(key: StringName) -> int:
	return item_count(StringName("mark:%s" % key))


func set_mark(key: StringName, value: int) -> void:
	if not _may_decide() or PartyProgress.current == null or mark(key) == value:
		return
	PartyProgress.current.items["mark:%s" % key] = value
	_commit()


## Opens something (a card, a slot, a system), once.
func grant(unlock_id: StringName) -> void:
	if not _may_decide() or PartyProgress.current == null or has_unlock(unlock_id):
		return
	PartyProgress.current.unlocks.append(String(unlock_id))
	_commit()
	unlocked.emit(unlock_id)


## Keeps a Stag Hunt's outcome in the ledger (StagHuntEncounter): which branch, how long it
## took, and its payoffs (Scrap is paid in Chimes; the utilities are the Bible's design numbers).
func record_stag_hunt(entry: Dictionary) -> void:
	if not _may_decide() or PartyProgress.current == null:
		return
	PartyProgress.current.stag_hunts.append(entry.duplicate())
	_commit()


## Tests and the Developer Tools: every quest before `quest_id` done (no XP paid), `quest_id`
## under way at its first step, and what the earlier quests opened, opened.
func jump_to(quest_id: StringName) -> void:
	if not _may_decide() or ActOneQuests.quest(quest_id) == null:
		return
	for earlier: StringName in ActOneQuests.ORDER:
		if earlier == quest_id:
			break
		_set_entry(earlier, QuestState.COMPLETE, ActOneQuests.quest(earlier).steps.size(), 0)
		for step: QuestStepResource in ActOneQuests.quest(earlier).steps:
			for unlock_id: StringName in step.grants:
				_grant_quietly(unlock_id)
		for unlock_id: StringName in ActOneQuests.quest(earlier).unlocks:
			_grant_quietly(unlock_id)
	_set_entry(quest_id, QuestState.ACTIVE, 0, 0)
	var after: StringName = ActOneQuests.next_after(quest_id)
	while after != &"":
		_ledger().erase(String(after))
		after = ActOneQuests.next_after(after)
	_commit()
	quest_started.emit(quest_id)
	_settle_step(quest_id)


## Clears the whole ledger without touching the save (tests).
func reset_for_testing() -> void:
	if PartyProgress.current == null:
		return
	PartyProgress.current.quest_log = {}
	PartyProgress.current.unlocks = PackedStringArray()
	PartyProgress.current.items = {}
	PartyProgress.current.stag_hunts.clear()
	_last_seen = {}
	ledger_changed.emit()


# --- Internals ------------------------------------------------------------------------

func _apply_report(kind: Kind, target: StringName, amount: int) -> void:
	var quest_id: StringName = active_quest_id()
	if quest_id == &"":
		return
	var quest: QuestDefinition = ActOneQuests.quest(quest_id)
	var step: QuestStepResource = quest.step_at(step_of(quest_id))
	if step == null or not step.matches(kind, target):
		return
	var counted: int = mini(count_of(quest_id) + amount, step.count)
	_set_entry(quest_id, QuestState.ACTIVE, step_of(quest_id), counted)
	if counted >= step.count:
		_finish_step(quest_id)
	else:
		_commit()
		step_progressed.emit(quest_id, counted, step.count)


func _finish_step(quest_id: StringName) -> void:
	var quest: QuestDefinition = ActOneQuests.quest(quest_id)
	var index: int = step_of(quest_id)
	var step: QuestStepResource = quest.step_at(index)
	for unlock_id: StringName in step.grants:
		_grant_quietly(unlock_id)
	if index + 1 >= quest.steps.size():
		_complete(quest_id)
		return
	_set_entry(quest_id, QuestState.ACTIVE, index + 1, 0)
	_commit()
	for unlock_id: StringName in step.grants:
		unlocked.emit(unlock_id)
	step_advanced.emit(quest_id, index + 1)
	_settle_step(quest_id)


## A step whose condition already holds when it begins (an item already carried) finishes at once.
func _settle_step(quest_id: StringName) -> void:
	var step: QuestStepResource = ActOneQuests.quest(quest_id).step_at(step_of(quest_id))
	if step != null and step.kind == Kind.ITEM and item_count(step.target) >= step.count:
		_set_entry(quest_id, QuestState.ACTIVE, step_of(quest_id), step.count)
		_finish_step(quest_id)


func _complete(quest_id: StringName) -> void:
	var quest: QuestDefinition = ActOneQuests.quest(quest_id)
	_set_entry(quest_id, QuestState.COMPLETE, quest.steps.size(), 0)
	for unlock_id: StringName in quest.unlocks:
		_grant_quietly(unlock_id)
	var after: StringName = ActOneQuests.next_after(quest_id)
	if after != &"" and state_of(after) == QuestState.LOCKED:
		_set_entry(after, QuestState.ACTIVE, 0, 0)
	_commit()
	# The hand-in: up to the ledger's cumulative XP for this quest, or a quarter of it if the party is past.
	var progress: PartyProgress = PartyProgress.current
	if progress != null:
		progress.award_xp(hand_in_xp(quest, progress.xp))
	for step: QuestStepResource in quest.steps:
		for unlock_id: StringName in step.grants:
			if step == quest.steps.back():
				unlocked.emit(unlock_id)
	for unlock_id: StringName in quest.unlocks:
		unlocked.emit(unlock_id)
	quest_completed.emit(quest_id)
	if after != &"" and state_of(after) == QuestState.ACTIVE:
		quest_started.emit(after)
		_settle_step(after)


## What handing a quest in pays a party that has `party_xp`.
static func hand_in_xp(quest: QuestDefinition, party_xp: int) -> int:
	return maxi(quest.cumulative_xp - party_xp, int(round(float(quest.xp_reward) * MIN_HAND_IN_SHARE)))


func _grant_quietly(unlock_id: StringName) -> void:
	if PartyProgress.current != null and not has_unlock(unlock_id):
		PartyProgress.current.unlocks.append(String(unlock_id))


func _set_entry(quest_id: StringName, state: QuestState, step: int, count: int) -> void:
	if PartyProgress.current == null:
		return
	PartyProgress.current.quest_log[String(quest_id)] = {"state": int(state), "step": step, "count": count}


func _ledger() -> Dictionary:
	return PartyProgress.current.quest_log if PartyProgress.current != null else {}


func _commit() -> void:
	if PartyProgress.current != null:
		PartyProgress.current.commit_quests()
	_last_seen = _ledger().duplicate(true)
	ledger_changed.emit()


func _may_decide() -> bool:
	return NetworkManager.current == null or not NetworkManager.current.is_online() or NetworkManager.current.is_host()


## The party's progress changed (a save loaded, or the host's copy arrived): tell the HUD.
func _on_progress_changed() -> void:
	if _ledger() == _last_seen:
		return
	_last_seen = _ledger().duplicate(true)
	ledger_changed.emit()
