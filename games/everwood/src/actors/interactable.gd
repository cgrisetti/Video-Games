## Something in the world a local player uses by walking up and pressing light
## (J / X / □), like the Chime-Shrine. While a player stands within `reach`,
## their actor points at it (ActorBase.interactable), their HUD shows its
## prompt, and light uses it instead of swinging.
class_name Interactable
extends Node3D

@export var reach: float = 2.6


func _physics_process(_delta: float) -> void:
	for member: ActorBase in CombatDirector.current.party_actors():
		if not member.is_local_player():
			continue
		var flat: Vector2 = Vector2(member.global_position.x - global_position.x, member.global_position.z - global_position.z)
		var near: bool = flat.length() <= reach and not member.stats.is_downed
		if near and member.interactable == null:
			member.interactable = self
		elif not near and member.interactable == self:
			member.interactable = null


func _exit_tree() -> void:
	if CombatDirector.current == null:
		return
	for member: ActorBase in CombatDirector.current.party_actors():
		if member.interactable == self:
			member.interactable = null


## The HUD line telling `actor` what pressing light here does.
func prompt_for(_actor: ActorBase) -> String:
	return ""


func interact(_actor: ActorBase) -> void:
	pass
