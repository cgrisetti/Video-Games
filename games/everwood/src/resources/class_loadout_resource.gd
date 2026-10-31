## A playable class (or a boss): its role, stats and posture-driven skill loadout.
## The loadouts themselves are built in code by `ClassLoadouts`.
class_name ClassLoadoutResource
extends Resource

enum Role { TANK, HEALER, DPS, BOSS }

@export var class_id: StringName = &""
@export var display_name: String = ""
@export var role: Role = Role.DPS
@export var body_color: Color = Color.WHITE
@export var stats: CharacterStatsResource
## What each command does from neutral. Combos continue through each action's flow links.
@export var openers: Array[CombatActionResource] = []
## Actions reachable only through flow links (not openers).
@export var combo_actions: Array[CombatActionResource] = []
@export var dodge: CombatActionResource
## Holding L raises an Active Guard instead of firing an L skill.
@export var guard_on_trigger_l: bool = false
## D-Pad binds Soul Tethers to party members (healer).
@export var has_soul_tethers: bool = false
## Short names for the trigger skills, shown in the HUD controls line.
@export var trigger_l_label: String = ""
@export var trigger_r_label: String = ""
@export var ult_label: String = ""


func opener_for(input_command: CombatActionResource.Command) -> CombatActionResource:
	if input_command == CombatActionResource.Command.DODGE:
		return dodge
	for action: CombatActionResource in openers:
		if action.command == input_command:
			return action
	# A directional heavy the class doesn't have falls back to its plain heavy.
	if input_command == CombatActionResource.Command.FORWARD_HEAVY or input_command == CombatActionResource.Command.BACK_HEAVY:
		return opener_for(CombatActionResource.Command.HEAVY)
	return null


func has_opener(input_command: CombatActionResource.Command) -> bool:
	for action: CombatActionResource in openers:
		if action.command == input_command:
			return true
	return false


func action_by_id(action_id: StringName) -> CombatActionResource:
	for action: CombatActionResource in openers:
		if action.action_id == action_id:
			return action
	for action: CombatActionResource in combo_actions:
		if action.action_id == action_id:
			return action
	return null


## The skill `from_action` flows into when `input_command` is pressed, or null.
func flow_link(from_action: CombatActionResource, input_command: int) -> CombatActionResource:
	for link_id: StringName in from_action.flow_links:
		var link: CombatActionResource = action_by_id(link_id)
		if link != null and link.command == input_command:
			return link
	return null


## Every action `from_action` can flow into, in the order they are listed.
func flow_links_of(from_action: CombatActionResource) -> Array[CombatActionResource]:
	var links: Array[CombatActionResource] = []
	for link_id: StringName in from_action.flow_links:
		var link: CombatActionResource = action_by_id(link_id)
		if link != null:
			links.append(link)
	return links
