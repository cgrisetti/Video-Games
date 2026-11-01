## The brain of an AI companion: a bot that fills a missing Holy Trinity role
## when fewer than 3 people are playing (LevelBase backfills them in raids).
##
## It thinks like a KOTOR Gambit list. Every tick it walks its role's gambits in
## priority order and runs the first one whose condition holds, so staying
## alive beats teamwork, and teamwork beats damage:
##   Tank    evade red · Perfect Guard the swipe · soak gold · taunt it back
##           · ultimate · detonate a primer · attack · follow
##   Healer  evade red · guard the swipe · soak gold · Lifeline a friend out of
##           red · heal the most hurt · Green Sanctuary · detonate · follow
##   DPS     evade red · roll from the swipe · soak gold · ultimate · prime
##           · attack · follow
## Gambits pick where to stand (tanks in front of the boss, DPS at its back,
## healers at range, archers at bow range, everyone near the leader outside a
## fight) and which command to press; the companion walks there and presses it
## like a player. Reach comes from the loadout, so a bot plays any kit.
## Woken minion camps are fought the same way (the guard and taunt gambits
## stay for the boss). Outside a fight the level can send a companion to a
## spot (a Rune-Plate on the Doverslap Gorge Bridge), and a companion left far
## behind on the trail skips ahead to the party.
## Companions belong to the host, so this runs only there.
class_name CompanionAIComponent
extends Node

enum Gambit { EVADE_RED, GUARD_SWIPE, DODGE_SWIPE, SOAK_GOLD, LIFELINE, HEAL, SANCTUARY, TAUNT, ULTIMATE, DETONATE, PRIME, ATTACK, FOLLOW }

const TANK_GAMBITS: Array[Gambit] = [Gambit.EVADE_RED, Gambit.GUARD_SWIPE, Gambit.SOAK_GOLD, Gambit.TAUNT,
	Gambit.ULTIMATE, Gambit.DETONATE, Gambit.ATTACK, Gambit.FOLLOW]
const HEALER_GAMBITS: Array[Gambit] = [Gambit.EVADE_RED, Gambit.GUARD_SWIPE, Gambit.SOAK_GOLD, Gambit.LIFELINE,
	Gambit.HEAL, Gambit.SANCTUARY, Gambit.DETONATE, Gambit.FOLLOW]
const DPS_GAMBITS: Array[Gambit] = [Gambit.EVADE_RED, Gambit.DODGE_SWIPE, Gambit.SOAK_GOLD, Gambit.ULTIMATE,
	Gambit.PRIME, Gambit.ATTACK, Gambit.FOLLOW]
const GAMBIT_NAMES: Array[String] = ["Evade red", "Guard swipe", "Dodge swipe", "Soak gold", "Lifeline", "Heal",
	"Sanctuary", "Taunt", "Ultimate", "Detonate", "Prime", "Attack", "Follow"]

## The backfill fills the party up to this many, missing roles in this order.
const PARTY_TARGET: int = 3
const BACKFILL_ORDER: Array[StringName] = [ClassLoadouts.SHIELD_TANK, ClassLoadouts.SOUL_TETHER_HEALER, ClassLoadouts.DIRECTIONAL_FLOW_DPS]
## Seconds between presses, so a companion acts quickly but not superhumanly.
const COMMAND_INTERVAL: float = 0.25
## Walk out of a red telegraph at once; roll out once it's this full.
const EVADE_ROLL_FILL: float = 0.6
## The tank raises its guard this long before the swipe lands, inside the 200 ms Perfect Guard window.
const PERFECT_GUARD_LEAD: float = 0.12
## The DPS rolls this long before the swipe lands.
const DODGE_LEAD: float = 0.35
const SWIPE_MARGIN: float = 1.0
## The healer heals anyone below this share of health...
const HEAL_BELOW: float = 0.75
## ...and drops a Green Sanctuary when 2+ near it are below this.
const SANCTUARY_BELOW: float = 0.8
## A friend standing in a red telegraph this full gets a Lifeline Pull.
const LIFELINE_FILL: float = 0.5
## Attacks keep this much stamina back for a dodge or a guard...
const STAMINA_RESERVE: float = 30.0
## ...a tank swings more freely to hold threat, but always keeps enough to raise its guard.
const TANK_STAMINA_RESERVE: float = InputComponent.AUTO_GUARD_MIN_STAMINA + 5.0
const TANK_DISTANCE: float = 2.4
const DPS_DISTANCE: float = 2.3
## The DPS stands this many radians round from the boss's face (behind it, to one side).
const DPS_FLANK_ANGLE: float = 2.3
const HEALER_DISTANCE: float = 7.0
const DETONATE_DISTANCE: float = 2.0
## Stepping back from a swipe: this far from the boss is outside its reach.
const SWIPE_SAFE_DISTANCE: float = 6.5
## Inside a soak, the companion holds its spot once it's this far into the circle (share of its radius).
const SOAK_STACK_SHARE: float = 0.6
## A ranged companion stands at this share of its shot's reach from the boss.
const RANGED_POST_SHARE: float = 0.6
## Presses start a little inside an action's full reach.
const REACH_MARGIN: float = 0.3
const FOLLOW_DISTANCE: float = 3.0
## Awake minions this close are fair game.
const FOE_RANGE: float = 20.0
## Left this far behind the leader with nothing to fight: skip ahead to them.
const CATCH_UP_DISTANCE: float = 22.0
const ARRIVE_RADIUS: float = 0.5
## Trying to walk but barely moving for this long (a pillar): sidestep for a moment.
const STUCK_TIME: float = 0.6
const SIDESTEP_TIME: float = 0.5

var actor: ActorBase
## The gambit that won this tick (shown in reports and checked by the smoke test).
var current_gambit: Gambit = Gambit.FOLLOW
## Where the companion is walking to.
var post: Vector3 = Vector3.ZERO
## A spot the level wants it on when there's no fight (a Rune-Plate).
var assigned_post: Vector3 = Vector3.ZERO
var has_assigned_post: bool = false

var _command_cooldown: float = 0.0
var _guarding: bool = false
var _hold_post: bool = false
var _primer_turn: int = 0
var _stuck_time: float = 0.0
var _sidestep_left: float = 0.0
var _sidestep: Vector3 = Vector3.ZERO


func setup(owner_actor: ActorBase) -> void:
	actor = owner_actor
	name = "CompanionAI"


## The classes to backfill for a party whose people play `human_classes`.
## Nobody playing means nobody to help, so no companions.
static func backfill_classes(human_classes: Array[StringName]) -> Array[StringName]:
	var wanted: Array[StringName] = []
	if human_classes.is_empty():
		return wanted
	var open: int = PARTY_TARGET - human_classes.size()
	for class_id: StringName in BACKFILL_ORDER:
		if wanted.size() >= open:
			break
		if not human_classes.has(class_id):
			wanted.append(class_id)
	return wanted


func gambits() -> Array[Gambit]:
	match actor.role():
		ClassLoadoutResource.Role.TANK:
			return TANK_GAMBITS
		ClassLoadoutResource.Role.HEALER:
			return HEALER_GAMBITS
	return DPS_GAMBITS


func gambit_name() -> String:
	return GAMBIT_NAMES[current_gambit]


## Called by the actor every physics tick instead of reading a controller.
func think(delta: float) -> void:
	_command_cooldown = maxf(0.0, _command_cooldown - delta)
	_guarding = false
	_hold_post = false
	post = actor.global_position
	if actor.can_act():
		for gambit: Gambit in gambits():
			if _run(gambit):
				current_gambit = gambit
				break
	actor.wants_guard = _guarding
	actor.move_intent = _steer(delta)
	var foe: ActorBase = _foe()
	_catch_up(foe)
	# Standing in reach of the foe: face it, so swings land.
	if foe != null and actor.move_intent == Vector3.ZERO and not actor.action_queue.is_busy() \
			and _in_reach(foe, CombatActionResource.Command.LIGHT):
		actor.turn_toward(foe.global_position - actor.global_position, actor.loadout.stats.turn_speed * delta)


func _run(gambit: Gambit) -> bool:
	match gambit:
		Gambit.EVADE_RED:
			return _evade_red()
		Gambit.GUARD_SWIPE:
			return _guard_swipe()
		Gambit.DODGE_SWIPE:
			return _dodge_swipe()
		Gambit.SOAK_GOLD:
			return _soak_gold()
		Gambit.LIFELINE:
			return _lifeline()
		Gambit.HEAL:
			return _heal()
		Gambit.SANCTUARY:
			return _sanctuary()
		Gambit.TAUNT:
			return _taunt()
		Gambit.ULTIMATE:
			return _ultimate()
		Gambit.DETONATE:
			return _detonate()
		Gambit.PRIME:
			return _prime()
		Gambit.ATTACK:
			return _attack()
	return _follow()


# --- Gambits (each returns true when it takes this tick) ------------------

## Standing in a red telegraph: walk out, and roll once it's nearly full.
func _evade_red() -> bool:
	var danger: RaidTelegraphDecal = CombatDirector.current.hostile_telegraph_at(actor.global_position, 0.0)
	if danger == null:
		return false
	var away: Vector3 = _flat(actor.global_position - danger.global_position)
	if away.length() < 0.1:
		away = -actor.facing_vector()
	away = away.normalized()
	_set_post(danger.global_position + away * (danger.radius + 1.0))
	if danger.fill_ratio() >= EVADE_ROLL_FILL and actor.stats.stamina >= actor.loadout.dodge.stamina_cost:
		actor.evade_direction = away
		_press(CombatActionResource.Command.DODGE, true)
	return true


## The swipe is coming: hold still and raise the guard. The tank waits for the
## last moment, so it lands a Perfect Guard.
func _guard_swipe() -> bool:
	var boss: BossDummy = _boss_in_fight()
	if boss == null or not boss.swipe_threatens(actor, SWIPE_MARGIN):
		return false
	if actor.stats.stamina < InputComponent.AUTO_GUARD_MIN_STAMINA and not actor.stats.guarding:
		return false
	var lead: float = PERFECT_GUARD_LEAD if actor.loadout.stats.can_perfect_guard else INF
	if actor.stats.guarding or boss.swipe_time_to_hit() <= lead:
		_guarding = true
		if actor.action_queue.is_busy() and actor.action_queue.phase != ActionQueueComponent.Phase.ACTIVE:
			actor.cancel_action()
	_set_post(actor.global_position)
	return true


## The DPS has no guard: it rolls away from the swipe just before it lands.
func _dodge_swipe() -> bool:
	var boss: BossDummy = _boss_in_fight()
	if boss == null or not boss.swipe_threatens(actor, SWIPE_MARGIN):
		return false
	var away: Vector3 = _flat(actor.global_position - boss.global_position).normalized()
	if boss.swipe_time_to_hit() <= DODGE_LEAD and actor.stats.stamina >= actor.loadout.dodge.stamina_cost:
		if actor.action_queue.is_busy() and actor.action_queue.phase != ActionQueueComponent.Phase.ACTIVE:
			actor.cancel_action()
		actor.evade_direction = away
		_press(CombatActionResource.Command.DODGE, true)
	else:
		_set_post(boss.global_position + away * SWIPE_SAFE_DISTANCE)
	return true


## A gold soak is going: stack into it. Once inside, the companion holds its
## spot but can still swing at the boss (lower gambits may press, not move).
func _soak_gold() -> bool:
	var soak: RaidTelegraphDecal = CombatDirector.current.soak_telegraph()
	if soak == null:
		return false
	_set_post(soak.global_position)
	if soak.contains(actor.global_position) and _flat(actor.global_position - soak.global_position).length() < soak.radius * SOAK_STACK_SHARE:
		_hold_post = true
		return false
	return true


## A friend is standing in a red telegraph that's about to go off: yank them out.
func _lifeline() -> bool:
	if actor.tether == null or actor.stats.resonance_pips() < 2:
		return false
	for ally: ActorBase in actor.tether.allies():
		if ally.stats.is_downed:
			continue
		if CombatDirector.current.hostile_telegraph_at(ally.global_position, LIFELINE_FILL) != null:
			actor.tether.bind_actor(ally)
			return _press(CombatActionResource.Command.TRIGGER_BOTH_ULT, true)
	return false


## Tether the most hurt party member (downed ones first) and send a homing heal.
func _heal() -> bool:
	var hurt: ActorBase = actor.most_hurt_ally(HEAL_BELOW)
	var heal: CombatActionResource = actor.loadout.opener_for(CombatActionResource.Command.TRIGGER_R_SKILL)
	if hurt == null or actor.tether == null or heal == null or actor.stats.stamina < heal.stamina_cost:
		return false
	actor.tether.bind_actor(hurt)
	return _press(CombatActionResource.Command.TRIGGER_R_SKILL, false)


## Two or more hurt friends close by: drop a Green Sanctuary ring on them.
func _sanctuary() -> bool:
	var ring: CombatActionResource = actor.loadout.opener_for(CombatActionResource.Command.TRIGGER_R_HOLD)
	if ring == null or actor.stats.resonance_pips() < ring.resonance_cost:
		return false
	var hurt_nearby: int = 0
	for member: ActorBase in CombatDirector.current.alive_party():
		if member.stats.health_ratio() < SANCTUARY_BELOW and member.global_position.distance_to(actor.global_position) <= ring.effect_radius:
			hurt_nearby += 1
	if hurt_nearby < 2:
		return false
	return _press(CombatActionResource.Command.TRIGGER_R_HOLD, false)


## The boss is chasing someone else: taunt it back.
func _taunt() -> bool:
	var boss: BossDummy = _boss_in_fight()
	if boss == null or actor.stats.resonance_pips() < 1:
		return false
	var target: StringName = boss.threat.current_target
	if target == &"" or target == actor.player_id:
		return false
	return _press(CombatActionResource.Command.TRIGGER_R_SKILL, false)


## Three pips and the foe in reach: ultimate.
func _ultimate() -> bool:
	var boss: ActorBase = _foe()
	if boss == null or actor.stats.resonance_pips() < 3 or not _in_reach(boss, CombatActionResource.Command.TRIGGER_BOTH_ULT):
		return false
	return _press(CombatActionResource.Command.TRIGGER_BOTH_ULT, false)


## A teammate primed the foe: close in and cash it in with a heavy.
func _detonate() -> bool:
	var boss: ActorBase = _foe()
	if boss == null or CombatDirector.current.primer_on(boss) == ScribeSignResource.Sign.NONE:
		return false
	var heavy: CombatActionResource = actor.loadout.opener_for(CombatActionResource.Command.HEAVY)
	var stand_off: float = DETONATE_DISTANCE if heavy == null or not heavy.is_projectile() else heavy.reach_distance() * RANGED_POST_SHARE
	_set_post(boss.global_position + _flat(actor.global_position - boss.global_position).normalized() * stand_off)
	if _in_reach(boss, CombatActionResource.Command.HEAVY):
		_press(CombatActionResource.Command.HEAVY, false)
	return true


## No seal on the boss: stamp one for a teammate, cycling through whichever
## Grimoire cards prime (Iron-Root, Rime-Gale and Star-Tide for the starter DPS).
func _prime() -> bool:
	var boss: ActorBase = _foe()
	if boss == null or CombatDirector.current.primer_on(boss) != ScribeSignResource.Sign.NONE or actor.stats.stamina < STAMINA_RESERVE:
		return false
	var primers: Array[int] = []
	for slot: int in InputComponent.PRIMER_SLOTS:
		var card: CombatActionResource = actor.loadout.card_action(slot)
		if card != null and card.primer != ScribeSignResource.Sign.NONE and actor.stats.can_afford(card) and _in_reach(boss, card.command):
			primers.append(card.command)
	if primers.is_empty():
		return false
	_primer_turn = _primer_turn % primers.size()
	if _press(primers[_primer_turn], false):
		_primer_turn = (_primer_turn + 1) % primers.size()
	_set_post(_role_post(boss))
	return true


## Take up the role's spot by the foe and swing when in reach.
func _attack() -> bool:
	var boss: ActorBase = _foe()
	if boss == null:
		return false
	_set_post(_role_post(boss))
	var reserve: float = TANK_STAMINA_RESERVE if actor.role() == ClassLoadoutResource.Role.TANK else STAMINA_RESERVE
	if _in_reach(boss, CombatActionResource.Command.LIGHT) and actor.stats.stamina >= reserve:
		_press(CombatActionResource.Command.LIGHT, false)
	return true


## In a fight the healer keeps its distance; outside one, a companion takes the
## spot the level gave it, or stays near the leader.
func _follow() -> bool:
	var boss: ActorBase = _foe()
	if boss != null:
		var bearing: Vector3 = _flat(actor.global_position - boss.global_position)
		_set_post(boss.global_position + (bearing.normalized() if bearing.length() > 0.1 else boss.facing_vector()) * HEALER_DISTANCE)
		return true
	if has_assigned_post:
		_set_post(assigned_post)
		return true
	var leader: ActorBase = _leader()
	if leader != null:
		var behind: Vector3 = _flat(actor.global_position - leader.global_position)
		if behind.length() > FOLLOW_DISTANCE:
			_set_post(leader.global_position + behind.normalized() * FOLLOW_DISTANCE)
	return true


# --- Helpers --------------------------------------------------------------

## The boss, while a fight is on (engaged, standing, not yet beaten).
func _boss_in_fight() -> BossDummy:
	var boss: BossDummy = CombatDirector.current.primary_boss() as BossDummy
	if boss == null or not boss.engaged or boss.vanquished or boss.stats.is_downed:
		return null
	return boss


## Who to fight: the boss while its fight is on, otherwise the nearest woken
## minion within FOE_RANGE.
func _foe() -> ActorBase:
	var boss: BossDummy = _boss_in_fight()
	if boss != null:
		return boss
	var best: ActorBase = null
	var best_distance: float = FOE_RANGE
	for enemy: ActorBase in CombatDirector.current.enemies():
		if enemy.is_raid_boss() or not enemy.is_engaged() or not enemy.is_targetable():
			continue
		var distance: float = _distance_to(enemy)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


## Far behind the leader (a long trail, a wall in the way, just seated at the
## start while the party is zones ahead) with no fight of its own nearby:
## appear just behind them, out of the way.
func _catch_up(foe: ActorBase) -> void:
	var leader: ActorBase = _leader()
	if leader == null or has_assigned_post or _distance_to(leader) <= CATCH_UP_DISTANCE:
		return
	if foe != null and _distance_to(foe) <= CATCH_UP_DISTANCE:
		return
	var back: Vector3 = _flat(actor.global_position - leader.global_position).normalized()
	actor.place_at(Transform3D(actor.global_basis, leader.global_position + back * FOLLOW_DISTANCE))


## The first standing person in the party (not a companion), who the bots follow.
func _leader() -> ActorBase:
	for member: ActorBase in CombatDirector.current.alive_party():
		if not member.is_companion:
			return member
	return null


## Archers and casters keep their shot's distance; tanks stand in front of the
## boss; melee DPS round its back, on the side they're on.
func _role_post(boss: ActorBase) -> Vector3:
	var bearing_now: Vector3 = _flat(actor.global_position - boss.global_position)
	var light: CombatActionResource = actor.loadout.opener_for(CombatActionResource.Command.LIGHT)
	if light != null and light.is_projectile():
		return boss.global_position + (bearing_now.normalized() if bearing_now.length() > 0.1 else boss.facing_vector()) * light.reach_distance() * RANGED_POST_SHARE
	if actor.role() != ClassLoadoutResource.Role.DPS:
		var bearing: Vector3 = _flat(actor.global_position - boss.global_position)
		return boss.global_position + (bearing.normalized() if bearing.length() > 0.1 else boss.facing_vector()) * TANK_DISTANCE
	var side: float = signf(boss.facing_vector().cross(actor.global_position - boss.global_position).y)
	var flank: Vector3 = boss.facing_vector().rotated(Vector3.UP, DPS_FLANK_ANGLE * (side if side != 0.0 else 1.0))
	return boss.global_position + flank * DPS_DISTANCE


## Presses a command if the companion can act on it now. Urgent presses (rolls,
## Lifeline) skip the pause between presses.
func _press(command: int, urgent: bool) -> bool:
	if not urgent and _command_cooldown > 0.0:
		return false
	var queue: ActionQueueComponent = actor.action_queue
	if queue.is_busy() and (not queue.is_buffer_open() or not queue.buffer.is_empty()):
		return false
	if not actor.can_act():
		return false
	queue.request(command)
	_command_cooldown = COMMAND_INTERVAL
	return true


func _set_post(where: Vector3) -> void:
	if not _hold_post:
		post = Vector3(where.x, actor.global_position.y, where.z)


## Walks toward the post, sidestepping when something blocks the way.
func _steer(delta: float) -> Vector3:
	if _sidestep_left > 0.0:
		_sidestep_left -= delta
		return _sidestep
	var to_post: Vector3 = _flat(post - actor.global_position)
	if to_post.length() <= ARRIVE_RADIUS or not actor.can_act():
		_stuck_time = 0.0
		return Vector3.ZERO
	var wish: Vector3 = to_post.normalized() * clampf(to_post.length() / 1.5, 0.35, 1.0)
	var speed: float = Vector2(actor.velocity.x, actor.velocity.z).length()
	_stuck_time = _stuck_time + delta if speed < 0.5 and actor.state_machine.is_in(&"locomotion") else 0.0
	if _stuck_time > STUCK_TIME:
		_stuck_time = 0.0
		_sidestep_left = SIDESTEP_TIME
		_sidestep = Vector3(-wish.z, 0.0, wish.x).normalized() * (1.0 if randf() < 0.5 else -1.0)
	return wish


func _distance_to(other: ActorBase) -> float:
	return _flat(other.global_position - actor.global_position).length()


## Whether the action `command` starts would reach `target` from here.
func _in_reach(target: ActorBase, command: int) -> bool:
	var action: CombatActionResource = actor.loadout.opener_for(command as CombatActionResource.Command)
	return action != null and _distance_to(target) <= action.reach_distance() + target.body_radius() - REACH_MARGIN


func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)
