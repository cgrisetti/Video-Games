## One step of a quest (docs/29 §3): what the party must do, counted by the
## QuestManager from what the world reports. Pure data.
##
##   REACH_PLACE   a hero stands inside a place (ActOnePlaces) — target is its POI id
##   TALK_TO       a hero speaks to a townsperson — target is the NPC id
##   CALM          foes calmed (never scattered) — target is a variant id, count how many
##   EVENT         something the world says happened — target is the event id
##                 (a grove cleared, a shrine lit, a bell chain rung, a chamber cleared)
##   BOSS_OUTCOME  a Stag Hunt ended the cooperative way — target is the boss id
##   NPC_RESTORED  a Forged townsperson made whole — target is the NPC id
##   ITEM          the party carries enough of an item — target is the item id
class_name QuestStepResource
extends Resource

enum Kind { REACH_PLACE, TALK_TO, CALM, EVENT, BOSS_OUTCOME, NPC_RESTORED, ITEM }

const KIND_NAMES: Array[String] = ["reach", "talk", "calm", "event", "boss", "restore", "item"]

@export var step_id: StringName = &""
@export var kind: Kind = Kind.EVENT
@export var target: StringName = &""
@export var count: int = 1
## The objective on screen, in the living-room words (Gate 6): "Calm the Bramble-Hounds".
@export var text: String = ""
## Where it happens (a POI id), for the map and the tracker.
@export var place_id: StringName = &""
## What finishing this step opens at once (QuestManager unlock ids), before the quest ends.
@export var grants: Array[StringName] = []


static func make(id: StringName, step_kind: Kind, step_target: StringName, step_text: String, step_count: int = 1,
		step_place: StringName = &"", step_grants: Array[StringName] = []) -> QuestStepResource:
	var made: QuestStepResource = QuestStepResource.new()
	made.step_id = id
	made.kind = step_kind
	made.target = step_target
	made.text = step_text
	made.count = maxi(1, step_count)
	made.place_id = step_place
	made.grants = step_grants
	return made


## Whether a report (kind, target) counts toward this step.
func matches(report_kind: Kind, report_target: StringName) -> bool:
	return report_kind == kind and report_target == target
