## One combat effect on its way to a target: a strike, a heal, threat, a pull or a reward.
## The Combat Director hands it to whichever peer owns the target, so it turns
## into a plain Dictionary to cross the network.
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
var primer: int = CombatActionResource.Synergy.NONE
var detonates: bool = false
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
	event.attacker_role = attacker.role()
	event.action_id = action.action_id
	event.damage = action.damage
	event.poise_damage = action.poise_damage
	event.threat = action.damage * action.threat_multiplier * attacker.loadout.stats.threat_modifier
	event.primer = action.primer
	event.detonates = action.detonates
	event.hit_stop_scale = action.hit_stop_scale
	event.origin = attacker.global_position
	event.reach = action.reach + action.hit_radius
	return event


func to_dict() -> Dictionary:
	return {
		"kind": kind,
		"attacker_path": attacker_path,
		"target_path": target_path,
		"attacker_player_id": attacker_player_id,
		"attacker_role": attacker_role,
		"action_id": action_id,
		"damage": damage,
		"poise_damage": poise_damage,
		"threat": threat,
		"heal": heal,
		"resonance": resonance,
		"primer": primer,
		"detonates": detonates,
		"hit_stop_scale": hit_stop_scale,
		"duration": duration,
		"origin": origin,
		"reach": reach,
		"unavoidable": unavoidable,
	}


static func from_dict(data: Dictionary) -> CombatEvent:
	var event: CombatEvent = CombatEvent.new()
	event.kind = int(data.get("kind", Kind.STRIKE)) as Kind
	event.attacker_path = NodePath(data.get("attacker_path", NodePath()))
	event.target_path = NodePath(data.get("target_path", NodePath()))
	event.attacker_player_id = StringName(data.get("attacker_player_id", &""))
	event.attacker_role = int(data.get("attacker_role", ClassLoadoutResource.Role.DPS))
	event.action_id = StringName(data.get("action_id", &""))
	event.damage = float(data.get("damage", 0.0))
	event.poise_damage = float(data.get("poise_damage", 0.0))
	event.threat = float(data.get("threat", 0.0))
	event.heal = float(data.get("heal", 0.0))
	event.resonance = float(data.get("resonance", 0.0))
	event.primer = int(data.get("primer", CombatActionResource.Synergy.NONE))
	event.detonates = bool(data.get("detonates", false))
	event.hit_stop_scale = float(data.get("hit_stop_scale", 1.0))
	event.duration = float(data.get("duration", 0.0))
	event.origin = data.get("origin", Vector3.ZERO) as Vector3
	event.reach = float(data.get("reach", 0.0))
	event.unavoidable = bool(data.get("unavoidable", false))
	return event
