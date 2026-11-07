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
## A REWARD's resonance is Ink-Drops back into the well (25 GDD R2), not a swing's pip.
var ink_refill: bool = false
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
## Sign-Flow (14 GDD §2, §5): the Sign a coat (or a Hearth-Rite opening strike)
## lends this strike, so even a plain Light can crack a Glimmer-Spot. These
## travel with an action-id strike: they belong to the attacker's coat, not the action.
var coat_sign: int = ScribeSignResource.Sign.NONE
## The framing Place-Card's bonus poise (capped by the target's owner).
var coat_poise: float = 0.0
## A Hearth-Rite opening strike: it also stamps its Sign's seal.
var coat_primes: bool = false
## The Phase 12 Kaizen pass (14 GDD §8), also the attacker's state, travelling
## with an action-id strike: the combo form this strike finishes (its numbers
## come from ArsenalCatalog on the target's owner), a One-and-Done Seal-Breaker
## (the Weapon-Coat leaf whose finisher multiplier it uses), and a Support whose
## Ink-Share lent coat_sign.
var combo_id: StringName = &""
var one_and_done: bool = false
var finisher_card_id: StringName = &""
var ink_share_from: StringName = &""
## The Seal-and-Tuck Grimoire: the seal card whose Pocket-Pull coat this strike
## carries (its multiplier is read from the card on the target's owner), whether
## an Under-Card Tuck rides it, and whether it is the pull's own blow (the burst).
var seal_card_id: StringName = &""
var seal_tuck: bool = false
var seal_burst: bool = false
## Worked out on the target's owner from the above (never sent): a stun to
## land, whether it cracks a martial lock or any lock or gate, and how far a
## Sign detonation riding it reaches.
var stun_seconds: float = 0.0
var breaks_martial_lock: bool = false
var cracks_lock: bool = false
var detonation_radius_mult: float = 1.0


## The Sign this strike counters a Glimmer-Spot with: a coat's, else its own seal or Sign.
func counter_sign() -> int:
	if coat_sign != ScribeSignResource.Sign.NONE:
		return coat_sign
	return primer if primer != ScribeSignResource.Sign.NONE else scribe_sign


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
	if coat_sign != ScribeSignResource.Sign.NONE:
		data.merge({"coat_sign": coat_sign, "coat_poise": coat_poise, "coat_primes": coat_primes})
	if ink_share_from != &"":
		data["ink_share_from"] = ink_share_from
	if combo_id != &"":
		data["combo_id"] = combo_id
	if one_and_done:
		data.merge({"one_and_done": true, "finisher_card_id": finisher_card_id})
	if seal_card_id != &"":
		data.merge({"seal_card_id": seal_card_id, "seal_tuck": seal_tuck, "seal_burst": seal_burst})
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
		"ink_refill": ink_refill,
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
	event.ink_refill = bool(data.get("ink_refill", false))
	event.stamina = float(data.get("stamina", 0.0))
	event.echo = float(data.get("echo", 0.0))
	event.primer = int(data.get("primer", ScribeSignResource.Sign.NONE))
	event.scribe_sign = int(data.get("scribe_sign", ScribeSignResource.Sign.NONE))
	event.detonates = bool(data.get("detonates", false))
	event.hit_stop_scale = float(data.get("hit_stop_scale", 1.0))
	event.duration = float(data.get("duration", 0.0))
	event.reach = float(data.get("reach", 0.0))
	event.unavoidable = bool(data.get("unavoidable", false))
	event.coat_sign = clampi(int(data.get("coat_sign", ScribeSignResource.Sign.NONE)), 0, ScribeSignResource.Sign.size() - 1)
	event.coat_poise = maxf(0.0, float(data.get("coat_poise", 0.0)))
	event.coat_primes = bool(data.get("coat_primes", false))
	event.ink_share_from = StringName(data.get("ink_share_from", &""))
	event.combo_id = StringName(data.get("combo_id", &""))
	event.one_and_done = bool(data.get("one_and_done", false))
	event.finisher_card_id = StringName(data.get("finisher_card_id", &""))
	event.seal_card_id = StringName(data.get("seal_card_id", &""))
	event.seal_tuck = bool(data.get("seal_tuck", false))
	event.seal_burst = bool(data.get("seal_burst", false))
	return event
