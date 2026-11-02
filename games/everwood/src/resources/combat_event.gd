## One combat effect on its way to a target: a strike, a heal, threat, a pull or a reward.
## The Combat Director hands it to whichever peer owns the target, so it turns
## into a plain Dictionary to cross the network.
##
## A strike from an action travels as the action's id only: the target's owner
## looks the numbers up in its own copy of the attacker's compiled loadout
## (every peer composes the same kit into the same actions), so packets stay
## small and a peer can't claim more than its action does. Strikes with no
## action (telegraphs, Perfect Guard counters) carry their numbers.
class_name CombatEvent
extends RefCounted

enum Kind { STRIKE, HEAL, THREAT, PULL, REWARD }

var kind: Kind = Kind.STRIKE
var attacker_path: NodePath = NodePath()
var target_path: NodePath = NodePath()
var attacker_player_id: StringName = &""
var attacker_role: int = ClassLoadoutResource.Role.DPS
var action_id: StringName = &""
var damage: float = 0.0
var poise_damage: float = 0.0
var threat: float = 0.0
var heal: float = 0.0
## Resonance pips granted (REWARD).
var resonance: float = 0.0
## Stamina restored (REWARD: Astral Chorus).
var stamina: float = 0.0
## A heal's Hearth Echo: this share bounces on to the next most hurt ally.
var echo: float = 0.0
var primer: int = ScribeSignResource.Sign.NONE
## The striking action's own Sign (a detonation by a different Sign is a cross-harmony).
var scribe_sign: int = ScribeSignResource.Sign.NONE
var detonates: bool = false
## The posture that threw the strike (CombatActionResource.Command): a Flank
## Breach needs a directional Heavy, R or L+R. Read from the action, so it never travels.
var command: int = -1
var hit_stop_scale: float = 1.0
## Taunt lock or pull time, in seconds.
var duration: float = 0.0
## Where the effect came from: guard direction for strikes, destination for pulls.
var origin: Vector3 = Vector3.ZERO
## Reach the attacker claimed, used to sanity-check hits from other peers.
var reach: float = 0.0
## Ground telegraphs: only position matters, so guards and i-frames don't help.
var unavoidable: bool = false


static func strike_from(attacker: ActorBase, target: ActorBase, action: CombatActionResource) -> CombatEvent:
	var event: CombatEvent = CombatEvent.new()
	event.kind = Kind.STRIKE
	event.attacker_path = attacker.get_path()
	event.target_path = target.get_path()
	event.attacker_player_id = attacker.player_id
	event.origin = attacker.global_position
	event.fill_from_action(attacker, action)
	return event


## The strike's numbers, read from the action (on whichever peer applies it).
func fill_from_action(attacker: ActorBase, action: CombatActionResource) -> void:
	attacker_role = attacker.role()
	action_id = action.action_id
	damage = action.damage
	poise_damage = action.poise_damage
	threat = action.damage * action.threat_multiplier * attacker.loadout.stats.threat_modifier
	primer = action.primer
	scribe_sign = action.scribe_sign
	detonates = action.detonates
	command = action.command
	hit_stop_scale = action.hit_stop_scale
	reach = action.reach_distance()


## A strike named by action id: true once its numbers are filled in from the
## attacker's loadout here; false if this peer doesn't know the action.
func resolve_action(attacker: ActorBase) -> bool:
	if kind != Kind.STRIKE or action_id == &"":
		return true
	if attacker == null or attacker.loadout == null:
		return false
	var action: CombatActionResource = attacker.loadout.action_by_id(action_id)
	if action == null:
		return false
	fill_from_action(attacker, action)
	return true


func to_dict() -> Dictionary:
	var data: Dictionary = {
		"kind": kind,
		"attacker_path": attacker_path,
		"target_path": target_path,
		"attacker_player_id": attacker_player_id,
		"origin": origin,
	}
	if kind == Kind.STRIKE and action_id != &"":
		data["action_id"] = action_id
		return data
	data.merge({
		"attacker_role": attacker_role,
		"damage": damage,
		"poise_damage": poise_damage,
		"threat": threat,
		"heal": heal,
		"resonance": resonance,
		"stamina": stamina,
		"echo": echo,
		"primer": primer,
		"scribe_sign": scribe_sign,
		"detonates": detonates,
		"hit_stop_scale": hit_stop_scale,
		"duration": duration,
		"reach": reach,
		"unavoidable": unavoidable,
	})
	return data


static func from_dict(data: Dictionary) -> CombatEvent:
	var event: CombatEvent = CombatEvent.new()
	event.kind = int(data.get("kind", Kind.STRIKE)) as Kind
	event.attacker_path = NodePath(data.get("attacker_path", NodePath()))
	event.target_path = NodePath(data.get("target_path", NodePath()))
	event.attacker_player_id = StringName(data.get("attacker_player_id", &""))
	event.origin = data.get("origin", Vector3.ZERO) as Vector3
	event.action_id = StringName(data.get("action_id", &""))
	event.attacker_role = int(data.get("attacker_role", ClassLoadoutResource.Role.DPS))
	event.damage = float(data.get("damage", 0.0))
	event.poise_damage = float(data.get("poise_damage", 0.0))
	event.threat = float(data.get("threat", 0.0))
	event.heal = float(data.get("heal", 0.0))
	event.resonance = float(data.get("resonance", 0.0))
	event.stamina = float(data.get("stamina", 0.0))
	event.echo = float(data.get("echo", 0.0))
	event.primer = int(data.get("primer", ScribeSignResource.Sign.NONE))
	event.scribe_sign = int(data.get("scribe_sign", ScribeSignResource.Sign.NONE))
	event.detonates = bool(data.get("detonates", false))
	event.hit_stop_scale = float(data.get("hit_stop_scale", 1.0))
	event.duration = float(data.get("duration", 0.0))
	event.reach = float(data.get("reach", 0.0))
	event.unavoidable = bool(data.get("unavoidable", false))
	return event
