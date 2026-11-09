## A quest on the Master Quest Ledger (the Narrative & Design Bible §5; docs/29):
## its place on the 14-level spine, the literary counsel it carries, its steps
## in order, and what finishing it opens. Pure data; ActOneQuests builds Act I's
## five and the QuestManager plays them.
class_name QuestDefinition
extends Resource

## The brief's id: &"Q01_LeeShoreAwakening".
@export var quest_id: StringName = &""
## Its number on the ledger (1 for Q01).
@export var number: int = 1
## On screen: "Lee-Shore Awakening".
@export var title: String = ""
## The Bible's full title, for the ledger and the design docs.
@export var full_title: String = ""
## The Bible's zone code: Z1_EMB is Embershore.
@export var zone_id: StringName = &"Z1_EMB"
@export var act: int = 1
@export var level_from: int = 1
@export var level_to: int = 2
## The ledger's XP for this quest, and the party's total once it is done.
@export var xp_reward: int = 0
@export var cumulative_xp: int = 0
## The literary counsel it carries ("Tolkien: Recovery").
@export var counsel: String = ""
## The quest before it (&"" for the first).
@export var requires: StringName = &""
@export var steps: Array[QuestStepResource] = []
## What finishing it opens (QuestManager unlock ids).
@export var unlocks: Array[StringName] = []


func step_at(index: int) -> QuestStepResource:
	return steps[index] if index >= 0 and index < steps.size() else null


## "Q01 · Lee-Shore Awakening".
func label() -> String:
	return "Q%02d · %s" % [number, title]
