## A spot in Act I's world a hero walks up to and presses light at (docs/29 §4):
## a Root-Shrine to pour into, a sea-lock's bell, the tide-bell, Hob's hearth,
## the vault door, the Great Cake, a kneeling guardian's seal. The director that
## builds it says when it is open (`available`, read on every peer from the
## quest ledger and the world) and what using it does (`on_used`, on the host).
##
## An Ink-Drop cost is paid from the hero's own well on the hero's own peer
## (the well lives on its owner), then the host hears who used it. Built in
## code the same way on every peer, so its node path matches for the RPC.
class_name QuestInteractable
extends Interactable

signal used(by: StringName)

const REFUSE_COLOR: Color = Color(0.86, 0.8, 0.96)

## The HUD line ("light: ring the Deep bell").
@export var prompt: String = ""
## Ink-Drops a use costs the hero (0 = free).
@export var drop_cost: int = 0
## () -> bool: whether it can be used right now (every peer). Unset means always.
var available: Callable = Callable()
## (by: StringName) -> void, on the host.
var on_used: Callable = Callable()
## (actor: ActorBase) -> bool: who may use it (the Lantern-Bearer's chime). Unset means anyone.
var who: Callable = Callable()
## Host: Ink-Drops each hero has poured here (shrines and finishers read it).
var poured: Dictionary[StringName, int] = {}


func is_open() -> bool:
	if not available.is_valid():
		return true
	return _alive(available) and bool(available.call())


## Whether a callback's owner is still about (a freed encounter's lambdas read as closed).
static func _alive(callback: Callable) -> bool:
	var owner_id: int = callback.get_object_id()
	return owner_id == 0 or is_instance_id_valid(owner_id)


func _physics_process(_delta: float) -> void:
	if not is_open():
		_let_go()
		return
	for member: ActorBase in CombatDirector.current.party_actors():
		if not member.is_local_player():
			continue
		var flat: Vector2 = Vector2(member.global_position.x - global_position.x, member.global_position.z - global_position.z)
		var near: bool = flat.length() <= reach and not member.stats.is_downed and absf(member.global_position.y - global_position.y) <= 6.0 \
			and (not who.is_valid() or (_alive(who) and bool(who.call(member))))
		if near and member.interactable == null:
			member.interactable = self
		elif not near and member.interactable == self:
			member.interactable = null


func prompt_for(actor: ActorBase) -> String:
	if drop_cost > 0 and actor.stats.uses_ink_well() and actor.stats.resonance_pips() < drop_cost:
		return "%s · needs %d Ink-Drop%s (calm a foe to fill your well)" % [prompt, drop_cost, "" if drop_cost == 1 else "s"]
	return prompt if drop_cost <= 0 else "%s · %d Ink-Drop%s" % [prompt, drop_cost, "" if drop_cost == 1 else "s"]


func interact(actor: ActorBase) -> void:
	if not is_open() or (who.is_valid() and not (_alive(who) and bool(who.call(actor)))):
		return
	if drop_cost > 0 and actor.stats.uses_ink_well():
		if actor.stats.resonance_pips() < drop_cost:
			CombatDirector.current.show_float_text(actor.global_position + Vector3.UP * 2.4, "Not enough Ink-Drops", REFUSE_COLOR, 30)
			return
		actor.stats.add_resonance(-float(drop_cost))
	if NetworkManager.current.is_host():
		use_as(actor.player_id)
	else:
		_use_remote.rpc_id(1, String(actor.player_id))


@rpc("any_peer", "call_remote", "reliable")
func _use_remote(by: String) -> void:
	if multiplayer.is_server():
		use_as(StringName(by))


## Host: someone used it (tests call this directly).
func use_as(by: StringName) -> void:
	if not is_open():
		return
	if drop_cost > 0:
		poured[by] = int(poured.get(by, 0)) + drop_cost
	used.emit(by)
	if on_used.is_valid() and _alive(on_used):
		on_used.call(by)


## Host: Ink-Drops poured here by everyone.
func poured_total() -> int:
	var total: int = 0
	for amount: int in poured.values():
		total += amount
	return total


func _let_go() -> void:
	if CombatDirector.current == null:
		return
	for member: ActorBase in CombatDirector.current.party_actors():
		if member.interactable == self:
			member.interactable = null
