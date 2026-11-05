## The Combat Director (autoload).
##
## - Local hit-stop: a landed blow freezes just the attacker and target for
##   60 ms, scaled per action. No global pause, so other split-screen players
##   keep moving.
## - Scribe Signs (06_WORLD_AND_CALLINGS.md §2, 05 GDD §3.2): a primer card stamps its
##   Sign's seal on the boss and a *teammate's* heavy detonates it. What a
##   detonation does is data on the SignSealResource, applied the same way
##   for every Sign; a different role or a different Sign makes it a
##   cross-harmony (x1.5).
## - Projectiles: the attacker's peer flies the real shot (from the level's
##   FxPool); other peers fly a look-alike named by action id.
## - Scribe Card invocations: every peer shows the card's seal, vellum card and
##   variant flourish (ScribeInvocationFX), named by action id.
## - One rule for networked combat: the peer that owns the target applies the
##   effect. Every strike, heal, threat and pull goes through deliver(), which
##   applies it here or sends it to the owner as a validation RPC.
## - Sign-Flow (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md): a hero's coat lends its
##   Sign and Place-Card poise to each strike (SignFlowComponent fills them in
##   as the hit lands); a foe's Glimmer-Spot judges them and a counter Sign on
##   an open spot is a Bravery Counter. The coats, Sign rings and glints show on
##   every peer from here.
class_name CombatDirector
extends Node

## The live autoload node. Scripts reach it as `CombatDirector.current` rather than by
## its autoload name, so `godot --check-only -s` (which runs before autoloads
## are registered) can still compile them.
static var current: CombatDirector

signal hit_stop_applied(duration: float)
signal hit_resolved(event: CombatEvent, outcome: int)
signal primer_applied(target: ActorBase, primer: int)
## A seal was detonated (every peer emits it: the host resolves it and tells the rest).
signal synergy_detonated(target: ActorBase, primer: int, cross_class: bool, label: String)
signal perfect_guard_landed(defender: ActorBase)
signal telegraph_cast(decal: RaidTelegraphDecal)
## A burst of light and a sound at an actor (every peer emits it for every cue).
signal cue_shown(at: Vector3, cue: StringName)
## Both players behind a detonation were rewarded (on the detonating target's owner).
signal synergy_rewarded(applier_id: StringName, detonator_id: StringName, resonance: float)
## A projectile left an attacker (the real one, or another peer's look-alike).
signal projectile_fired(attacker: ActorBase, action: CombatActionResource)
## A Scribe Card's invocation effect started (on every peer that showed it).
signal card_invoked(caster: ActorBase, action: CombatActionResource, variant: int)
## A Flow-Link Pulse rang round a hero (on every peer).
signal flow_link_shown(actor: ActorBase)
## A foe's Glimmer-Spot opened for `seconds`, with its HUD rhyme ("" once the party knows it), on every peer.
signal glimmer_opened(enemy: ActorBase, seconds: float, rhyme: String)
## A Bravery Counter cracked a foe's Glimmer-Spot (on every peer).
signal bravery_countered(target: ActorBase, scribe_sign: int, label: String)
## A hero's Sign-Flow look changed (SignFlowComponent.CoatLook), on every peer.
signal sign_coat_shown(actor: ActorBase, look: int)
## A Support's Ink-Share went out (14 GDD §8): who shared, the Sign, and who received it.
signal ink_shared(support: ActorBase, scribe_sign: int, recipients: Array[ActorBase])
## A Tank's Ward-Mantle threw poise back at a foe.
signal poise_reflected(defender: ActorBase, attacker: ActorBase, poise: float)

## Phase B impact freeze (02_COMBAT_GDD.md §2); each action scales it.
const BASE_HIT_STOP: float = 0.06
## Sakurai hit-stop by kind of blow (11_COMBAT_ONBOARDING_AND_FEEL_GDD.md §4.2,
## Layer 1): a Light, a Heavy or Un-Inked Flourish, an inked card, a Sign
## detonation. LoadoutComposer sets each hero action's hit_stop_scale from these.
const HIT_STOP_LIGHT: float = 0.05
const HIT_STOP_HEAVY: float = 0.10
const HIT_STOP_CARD: float = 0.14
const HIT_STOP_DETONATION: float = 0.18
const PRIMER_DURATION: float = 8.0
## Detonated by a different role, or a different Sign, than the seal's.
const CROSS_HARMONY_MULTIPLIER: float = 1.5
## Hits that land after a flow-cancel fill resonance faster.
const FLOW_RESONANCE_MULTIPLIER: float = 1.5
## Resonance pips each partner in a detonation earns (x CROSS_HARMONY_MULTIPLIER on a cross-harmony).
const SYNERGY_RESONANCE_REWARD: float = 0.5
## Healers fill resonance by healing: pips per point of health restored.
const HEAL_RESONANCE_PER_HP: float = 0.008
const PERFECT_GUARD_RESONANCE: float = 0.5
const PERFECT_GUARD_POISE: float = 50.0
## Threat a tank's Perfect Guard draws; other classes draw it scaled by their
## threat modifier, so a DPS's Perfect Guard doesn't pull the boss off the tank.
const PERFECT_GUARD_THREAT: float = 250.0
const TANK_THREAT_MODIFIER: float = 3.0
const PERFECT_GUARD_HIT_STOP_SCALE: float = 2.5
## A Perfect Guard's counter reaches the attacker from this far beyond its body.
const PERFECT_GUARD_COUNTER_REACH: float = 4.0
const HEAL_THREAT_RATIO: float = 0.5
const TAUNT_THREAT: float = 50.0
## Metres of lag forgiveness when checking a hit reported by another peer.
const VALIDATION_SLACK: float = 3.0
const LIFELINE_LANDING_DISTANCE: float = 1.3
## Hearth Echo: a heal's bounce reaches allies this close to its target.
const ECHO_RADIUS: float = 8.0
## Shots lean toward a target this close to straight ahead (dot of directions).
const AIM_ASSIST_DOT: float = 0.8
## A plain shot sounds a little higher and quieter than a card shot.
const SHOT_PITCH_PLAIN: float = 1.3
const SHOT_VOLUME_DB: float = -6.0
const FLOAT_TEXT_TIME: float = 0.9
## Big callouts (detonations, Perfect Guards) are drawn at this size.
const ANNOUNCE_TEXT_SIZE: int = 54
const FLOAT_TEXT_RISE: float = 1.4

class PrimerRecord:
	var primer: int = ScribeSignResource.Sign.NONE
	var applier_id: StringName = &""
	var applier_role: int = ClassLoadoutResource.Role.DPS
	var expires_at: float = 0.0

## Where zones, heals and floating text are spawned (the level sets this).
var effects_root: Node3D
## The level's pool for projectiles and card effects (the level sets this).
var fx_pool: FxPool

var _actors: Dictionary[StringName, ActorBase] = {}
var _bosses: Array[ActorBase] = []
var _primers: Dictionary[int, PrimerRecord] = {}
## Every peer's Sign Ring and badge on each primed enemy (SignMark), by the enemy's instance id.
var _marks: Dictionary[int, SignMark] = {}
var _zones: Array[SanctuaryZone] = []
var _telegraphs: Array[RaidTelegraphDecal] = []


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


## Simulated seconds since the game started, counted in physics ticks. Combat
## timing uses this rather than the wall clock, so it stays right under a
## fixed-step headless run and doesn't drift with frame hitches.
static func game_time() -> float:
	return float(Engine.get_physics_frames()) / float(Engine.physics_ticks_per_second)


func reset() -> void:
	fx_pool = null
	_actors.clear()
	_bosses.clear()
	_primers.clear()
	_marks.clear()
	_zones.clear()
	_telegraphs.clear()


# --- Registries -----------------------------------------------------------

func register_actor(actor: ActorBase) -> void:
	if actor.is_boss():
		if not _bosses.has(actor):
			_bosses.append(actor)
		if not actor.went_down.is_connected(_on_enemy_down):
			actor.went_down.connect(_on_enemy_down)
	else:
		_actors[actor.player_id] = actor


func unregister_actor(actor: ActorBase) -> void:
	_bosses.erase(actor)
	if _actors.has(actor.player_id) and _actors[actor.player_id] == actor:
		_actors.erase(actor.player_id)
	_primers.erase(actor.get_instance_id())
	_clear_mark(actor.get_instance_id())


## The trail's XP for a fallen foe (ActorBase.trail_xp: +35 a mob, +200 a boss). The host awards it.
func _on_enemy_down(enemy: ActorBase) -> void:
	PartyProgress.current.award_xp(enemy.trail_xp())


func get_actor(player_id: StringName) -> ActorBase:
	if _actors.has(player_id) and is_instance_valid(_actors[player_id]):
		return _actors[player_id]
	return null


## Every player actor in the raid, in party join order.
func party_actors() -> Array[ActorBase]:
	var members: Array[ActorBase] = []
	for actor: ActorBase in _actors.values():
		if is_instance_valid(actor):
			members.append(actor)
	members.sort_custom(func(a: ActorBase, b: ActorBase) -> bool: return a.party_slot < b.party_slot)
	return members


func alive_party() -> Array[ActorBase]:
	var alive: Array[ActorBase] = []
	for actor: ActorBase in party_actors():
		if not actor.stats.is_downed:
			alive.append(actor)
	return alive


## The instance's raid boss (the Cairnsman), never a minion.
func primary_boss() -> ActorBase:
	for boss: ActorBase in _bosses:
		if is_instance_valid(boss) and boss.is_raid_boss():
			return boss
	return null


## Every enemy here: the raid boss and any minions.
func enemies() -> Array[ActorBase]:
	var found: Array[ActorBase] = []
	for enemy: ActorBase in _bosses:
		if is_instance_valid(enemy):
			found.append(enemy)
	return found


func register_telegraph(decal: RaidTelegraphDecal) -> void:
	_telegraphs.append(decal)
	telegraph_cast.emit(decal)


func unregister_telegraph(decal: RaidTelegraphDecal) -> void:
	_telegraphs.erase(decal)


## A red (dodge-out) telegraph covering `position` that is at least `min_fill` full.
func hostile_telegraph_at(position: Vector3, min_fill: float) -> RaidTelegraphDecal:
	for decal: RaidTelegraphDecal in _telegraphs:
		if is_instance_valid(decal) and decal.is_hostile() and decal.fill_ratio() >= min_fill and decal.contains(position):
			return decal
	return null


## The gold soak circle being cast right now, if there is one.
func soak_telegraph() -> RaidTelegraphDecal:
	for decal: RaidTelegraphDecal in _telegraphs:
		if is_instance_valid(decal) and decal.is_soak() and decal.fill_ratio() < 1.0:
			return decal
	return null


## The blue Gale-Beam lane being cast right now, if there is one.
func beam_telegraph() -> RaidTelegraphDecal:
	for decal: RaidTelegraphDecal in _telegraphs:
		if is_instance_valid(decal) and decal.is_beam() and decal.fill_ratio() < 1.0:
			return decal
	return null


## A Shadow Sanctuary cone that's up right now, if there is one.
func shelter_cone() -> SanctuaryZone:
	for zone: SanctuaryZone in _zones:
		if is_instance_valid(zone) and zone.shape == SanctuaryZone.Shape.CONE:
			return zone
	return null


## Whether `player_id` has a sanctuary of their own up.
func has_zone_from(player_id: StringName) -> bool:
	for zone: SanctuaryZone in _zones:
		if is_instance_valid(zone) and zone.owner_player_id == player_id:
			return true
	return false


func register_zone(zone: SanctuaryZone) -> void:
	_zones.append(zone)


func unregister_zone(zone: SanctuaryZone) -> void:
	_zones.erase(zone)


## Whether a spot is inside any sanctuary that's up (a Shadow Sanctuary cone or a ground ring).
func in_sanctuary(point: Vector3) -> bool:
	for zone: SanctuaryZone in _zones:
		if is_instance_valid(zone) and zone.contains(point):
			return true
	return false


## Behind a shield: inside someone's Shadow Sanctuary cone, or holding one up
## yourself. The Gorge Gale-Jet and the Gale-Beam can't touch you there.
func is_sheltered(actor: ActorBase) -> bool:
	for zone: SanctuaryZone in _zones:
		if is_instance_valid(zone) and zone.shape == SanctuaryZone.Shape.CONE \
				and (zone.owner_player_id == actor.player_id or zone.contains(actor.global_position)):
			return true
	return false


## Shadow Sanctuary: allies inside a tank's shield cone take less damage; a
## four-gate boss behind its Aegis Mantle takes a tenth.
func damage_taken_multiplier(actor: ActorBase) -> float:
	var multiplier: float = 1.0
	if actor.gates != null:
		multiplier *= actor.gates.damage_taken_multiplier()
	for zone: SanctuaryZone in _zones:
		if zone.shape == SanctuaryZone.Shape.CONE and zone.owner_player_id != actor.player_id and zone.contains(actor.global_position):
			multiplier = minf(multiplier, 1.0 - zone.damage_reduction)
	return multiplier


# --- Hit-stop -------------------------------------------------------------

func request_hit_stop(actors: Array[ActorBase], scale: float) -> void:
	var duration: float = BASE_HIT_STOP * scale
	for actor: ActorBase in actors:
		if is_instance_valid(actor):
			actor.apply_hit_stop(duration)
	hit_stop_applied.emit(duration)


# --- Hits -----------------------------------------------------------------

## An attacker's hitbox touched a target. Runs on the attacker's peer: freeze,
## resonance and the damage number happen at once, then the strike goes to
## whoever owns the target.
func report_hit(attacker: ActorBase, target: ActorBase, action: CombatActionResource, flowed: bool, from_projectile: bool = false) -> void:
	# A shot freezes only its target: the archer isn't touching it.
	var frozen: Array[ActorBase] = [target]
	if not from_projectile:
		frozen.append(attacker)
	request_hit_stop(frozen, action.hit_stop_scale)
	attacker.stats.add_resonance(action.resonance_gain * (FLOW_RESONANCE_MULTIPLIER if flowed else 1.0))
	attacker.stats.restore_stamina(action.echo_stamina_on_hit)
	if attacker.is_local_player():
		AudioCues.play_at(&"hit", target.global_position, 1.15 / maxf(0.7, action.hit_stop_scale), -4.0)
	if action.damage > 0.0:
		show_float_text(_above(target), str(roundi(action.damage)), Color(1.0, 0.94, 0.78))
	var event: CombatEvent = CombatEvent.strike_from(attacker, target, action)
	if attacker.sign_flow != null:
		attacker.sign_flow.on_strike_landed(action, event)
	if attacker.combo != null:
		attacker.combo.on_strike_landed(action, event)
	deliver(event)


func deliver(event: CombatEvent) -> void:
	var target: ActorBase = _actor_at(event.target_path)
	if target == null:
		return
	if target.is_multiplayer_authority():
		_apply(target, event, false)
	elif InstanceManager.current.is_peer_live(target.get_multiplayer_authority()):
		# A peer still loading its instance can't be hit (or healed) until it arrives.
		_receive_event.rpc_id(target.get_multiplayer_authority(), event.to_dict())


@rpc("any_peer", "call_remote", "reliable")
func _receive_event(data: Dictionary) -> void:
	var event: CombatEvent = CombatEvent.from_dict(data)
	var target: ActorBase = _actor_at(event.target_path)
	if target == null or not target.is_multiplayer_authority():
		return
	# A strike named by action id takes its numbers from our copy of the attacker.
	if not event.resolve_action(_actor_at(event.attacker_path)):
		return
	if not _is_plausible(event, target, multiplayer.get_remote_sender_id()):
		push_warning("CombatDirector: dropped an implausible %s from peer %d" % [CombatEvent.Kind.keys()[event.kind], multiplayer.get_remote_sender_id()])
		return
	_apply(target, event, true)


## Sanity checks for effects other peers send. Deterministic hitboxes mean no
## dice, but a hit still has to come from the attacker's owner and be in reach.
func _is_plausible(event: CombatEvent, target: ActorBase, sender: int) -> bool:
	var attacker: ActorBase = _actor_at(event.attacker_path)
	if event.kind != CombatEvent.Kind.STRIKE:
		return NetworkManager.current.has_peer(sender)
	if attacker == null or attacker.get_multiplayer_authority() != sender:
		return false
	if event.unavoidable:
		return attacker.is_boss()
	if event.coat_sign != ScribeSignResource.Sign.NONE:
		# A coat's Sign must be one the hero carries, or one a Support of the party lent them.
		var lender: ActorBase = get_actor(event.ink_share_from) if event.ink_share_from != &"" else attacker
		if lender == null or not _diorama_carries(lender, event.coat_sign):
			return false
	if event.combo_id != &"" and not _combo_fits(event):
		return false
	if event.one_and_done and (event.command != CombatActionResource.Command.TRIGGER_BOTH_ULT
			or not _diorama_has_leaf(attacker, event.finisher_card_id)):
		return false
	var limit: float = event.reach + target.body_radius() + VALIDATION_SLACK
	return attacker.global_position.distance_to(target.global_position) <= limit


## Whether one of the attacker's diorama leaves is of this Sign (a coat can only lend a Sign its hero carries).
static func _diorama_carries(attacker: ActorBase, scribe_sign: int) -> bool:
	var kit: EquipmentLoadoutResource = attacker.loadout.kit if attacker.loadout != null else null
	if kit == null:
		return false
	for socket: int in EquipmentLoadoutResource.SOCKET_COUNT:
		var leaf: ScribeCardResource = ArsenalCatalog.current.card(kit.socket_leaf_id(socket))
		if leaf != null and leaf.scribe_sign == scribe_sign:
			return true
	return false


## A combo finisher's claim holds: the form exists, the party knows it, and the strike is its last posture.
static func _combo_fits(event: CombatEvent) -> bool:
	var form: ComboChainResource = ArsenalCatalog.current.combo(event.combo_id)
	if form == null or form.required_level > PartyProgress.current.trail_level():
		return false
	var final: StringName = form.final_token()
	return ComboChainResource.token_for(event.command, false) == final \
		or (final == ComboChainResource.SIDE_HEAVY and event.command == CombatActionResource.Command.HEAVY)


## Whether this Action-Leaf is in one of the attacker's diorama sockets.
static func _diorama_has_leaf(attacker: ActorBase, leaf_id: StringName) -> bool:
	var kit: EquipmentLoadoutResource = attacker.loadout.kit if attacker.loadout != null else null
	if kit == null or leaf_id == &"":
		return false
	for socket: int in EquipmentLoadoutResource.SOCKET_COUNT:
		if kit.socket_leaf_id(socket) == leaf_id:
			return true
	return false


func _apply(target: ActorBase, event: CombatEvent, from_remote: bool) -> void:
	match event.kind:
		CombatEvent.Kind.STRIKE:
			_apply_strike(target, event, from_remote)
		CombatEvent.Kind.HEAL:
			var healed: float = target.receive_heal(event.heal)
			if event.echo > 0.0:
				_echo_heal(target, event)
			if healed > 0.0:
				show_float_text(_above(target), "+%d" % roundi(healed), Color(0.5, 1.0, 0.6))
				AudioCues.play(&"heal", 1.0, -6.0)
				for boss: ActorBase in _bosses:
					if is_instance_valid(boss) and boss.is_engaged():
						deliver(_threat_event(event.attacker_path, event.attacker_player_id, boss, healed * HEAL_THREAT_RATIO, 0.0))
				var healer: ActorBase = get_actor(event.attacker_player_id)
				if healer != null:
					deliver(_reward_event(healer, healed * HEAL_RESONANCE_PER_HP))
		CombatEvent.Kind.REWARD:
			if event.heal > 0.0:
				target.receive_heal(event.heal)
			target.stats.add_resonance(event.resonance)
			target.stats.restore_stamina(event.stamina)
		CombatEvent.Kind.THREAT:
			if target.threat != null:
				if event.duration > 0.0:
					target.threat.taunt(event.attacker_player_id, event.duration)
				else:
					target.threat.add_threat(event.attacker_player_id, event.threat)
		CombatEvent.Kind.PULL:
			# A shove (it names the target as its own source) is knockback: a Ward-Mantle or an
			# Aegis Ward shrugs it off. A friend's Lifeline Pull names the healer, so it still lands.
			if event.attacker_path == event.target_path and target.sign_flow != null and target.sign_flow.shrugs_off_stagger():
				return
			target.start_forced_move(event.origin, event.duration)


func _apply_strike(target: ActorBase, event: CombatEvent, from_remote: bool) -> void:
	if event.coat_sign != ScribeSignResource.Sign.NONE:
		# A coat's Place-Card poise (never more than any Place-Card lends), and a Hearth-Rite opening strike's seal.
		event.coat_poise = clampf(event.coat_poise, 0.0, ArsenalCatalog.current.max_place_poise())
		event.poise_damage += event.coat_poise
		if event.coat_primes and event.primer == ScribeSignResource.Sign.NONE:
			event.primer = event.coat_sign
	if target.is_boss():
		_apply_flourishes(target, event)
		if event.detonates:
			_try_detonate(target, event)
		if event.primer != ScribeSignResource.Sign.NONE:
			_apply_primer(target, event)
	var outcome: int = target.receive_strike(event)
	if outcome == StatsComponent.StrikeOutcome.HIT and event.stun_seconds > 0.0 and not target.stats.is_downed:
		target.stagger(event.stun_seconds)
	match outcome:
		StatsComponent.StrikeOutcome.PERFECT_GUARD:
			_on_perfect_guard(target, event)
		StatsComponent.StrikeOutcome.GUARD_BROKEN:
			announce(_above(target), "GUARD BROKEN", Color(1.0, 0.45, 0.3), &"soak_fail")
	if outcome != StatsComponent.StrikeOutcome.EVADED and outcome != StatsComponent.StrikeOutcome.PERFECT_GUARD:
		if target.threat != null:
			target.threat.add_threat(event.attacker_player_id, event.threat)
		if from_remote and target.stats.last_damage_taken > 0.0:
			show_float_text(_above(target), str(roundi(target.stats.last_damage_taken)), Color(1.0, 0.6, 0.55))
	if from_remote:
		request_hit_stop([target], event.hit_stop_scale)
	hit_resolved.emit(event, outcome)


## A combo finisher and a One-and-Done, on the foe's owner (14 GDD §8): the
## finisher's damage, poise, stun and lock-breaking from its form; the
## Seal-Breaker's 3.2x, its Sign's detonation, and a crack for any lock or gate.
func _apply_flourishes(target: ActorBase, event: CombatEvent) -> void:
	if event.combo_id != &"":
		var form: ComboChainResource = ArsenalCatalog.current.combo(event.combo_id)
		if form != null:
			event.damage *= form.finisher_damage_mult
			event.poise_damage += form.finisher_poise_damage
			event.stun_seconds = maxf(event.stun_seconds, form.stun_duration_sec)
			event.breaks_martial_lock = event.breaks_martial_lock or form.breaks_martial_lock
			event.detonation_radius_mult = maxf(event.detonation_radius_mult, form.detonation_radius_mult)
	if event.one_and_done:
		var leaf: ScribeCardResource = ArsenalCatalog.current.card(event.finisher_card_id)
		event.damage *= leaf.one_and_done_finisher_mult if leaf != null else 1.0
		event.cracks_lock = true
		sign_detonation(target, event, event.coat_sign, "ONE-AND-DONE!")


## A Sign's canonical detonation riding a strike (the One-and-Done's): Shatterpoint's
## poise, Glacial Rupture's burst, Dawnburst's heal or Astral Chorus's stamina
## and pips, reaching as far as the strike's detonation radius allows, with a
## detonation's freeze and its banner on every peer.
func sign_detonation(target: ActorBase, event: CombatEvent, scribe_sign: int, banner: String) -> void:
	if scribe_sign == ScribeSignResource.Sign.NONE:
		return
	var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(scribe_sign)
	event.poise_damage += seal.bonus_poise
	event.damage += seal.bonus_damage
	if seal.bonus_damage > 0.0 and seal.burst_radius > 0.0:
		_burst(target, event, seal.bonus_damage, seal.burst_radius * event.detonation_radius_mult)
	if seal.has_party_effect():
		_bless_party(target, event, seal, 1.0, event.detonation_radius_mult)
	event.hit_stop_scale = maxf(event.hit_stop_scale, HIT_STOP_DETONATION / BASE_HIT_STOP) + seal.bonus_hit_stop
	var label: String = "%s  %s" % [banner, seal.detonation_name]
	if NetworkManager.current.is_online():
		_show_detonation.rpc(target.get_path(), scribe_sign, false, label)
	else:
		_show_detonation(target.get_path(), scribe_sign, false, label)


## A Tank's Ward-Mantle throws `poise` back at the foe whose blow it soaked (like a Perfect Guard's counter).
func reflect_poise(defender: ActorBase, attacker: ActorBase, poise: float) -> void:
	if attacker == null or poise <= 0.0:
		return
	var counter: CombatEvent = CombatEvent.new()
	counter.kind = CombatEvent.Kind.STRIKE
	counter.attacker_path = defender.get_path()
	counter.target_path = attacker.get_path()
	counter.attacker_player_id = defender.player_id
	counter.attacker_role = defender.role()
	counter.poise_damage = poise
	counter.threat = PERFECT_GUARD_THREAT * defender.loadout.stats.threat_modifier / TANK_THREAT_MODIFIER
	counter.origin = defender.global_position
	counter.reach = attacker.body_radius() + PERFECT_GUARD_COUNTER_REACH
	deliver(counter)
	poise_reflected.emit(defender, attacker, poise)


## A Perfect Guard costs nothing, hits the attacker's poise and draws big threat.
func _on_perfect_guard(defender: ActorBase, event: CombatEvent) -> void:
	perfect_guard_landed.emit(defender)
	defender.stats.add_resonance(PERFECT_GUARD_RESONANCE)
	announce(_above(defender), "PERFECT GUARD!  +½ pip", Color(1.0, 0.85, 0.3), &"perfect_guard")
	show_cue(defender, Color(1.0, 0.85, 0.3), &"")
	request_hit_stop([defender], PERFECT_GUARD_HIT_STOP_SCALE)
	var attacker: ActorBase = _actor_at(event.attacker_path)
	if attacker == null:
		return
	var counter: CombatEvent = CombatEvent.new()
	counter.kind = CombatEvent.Kind.STRIKE
	counter.attacker_path = defender.get_path()
	counter.target_path = attacker.get_path()
	counter.attacker_player_id = defender.player_id
	counter.attacker_role = defender.role()
	counter.poise_damage = PERFECT_GUARD_POISE
	counter.threat = PERFECT_GUARD_THREAT * defender.loadout.stats.threat_modifier / TANK_THREAT_MODIFIER
	counter.hit_stop_scale = PERFECT_GUARD_HIT_STOP_SCALE
	counter.origin = defender.global_position
	counter.reach = attacker.body_radius() + PERFECT_GUARD_COUNTER_REACH
	deliver(counter)


# --- Scribe Sign seals ----------------------------------------------------

func _apply_primer(target: ActorBase, event: CombatEvent) -> void:
	var record: PrimerRecord = PrimerRecord.new()
	record.primer = event.primer
	record.applier_id = event.attacker_player_id
	record.applier_role = event.attacker_role
	record.expires_at = game_time() + PRIMER_DURATION
	_primers[target.get_instance_id()] = record
	primer_applied.emit(target, event.primer)
	var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(event.primer)
	announce(_above(target) + Vector3.UP * 0.6, "%s seal" % seal.seal_name, seal.color)
	# Every peer sees the Sign Ring and badge, and knows who primed it (the R prompt reads that).
	if NetworkManager.current.is_online():
		_show_primer.rpc(target.get_path(), event.primer, event.attacker_player_id, event.attacker_role)
	else:
		_show_primer(target.get_path(), event.primer, event.attacker_player_id, event.attacker_role)


## The seal on every peer (11 GDD §4.2, Layer 3): a turning Sign Ring under the
## enemy and a badge over it. Other peers keep a copy of the record for the HUD;
## only the enemy's owner detonates.
@rpc("any_peer", "call_local", "reliable")
func _show_primer(target_path: NodePath, primer: int, applier_id: StringName, applier_role: int) -> void:
	var target: ActorBase = _actor_at(target_path)
	if target == null:
		return
	var key: int = target.get_instance_id()
	if not target.is_multiplayer_authority():
		var record: PrimerRecord = PrimerRecord.new()
		record.primer = primer
		record.applier_id = applier_id
		record.applier_role = applier_role
		record.expires_at = game_time() + PRIMER_DURATION
		_primers[key] = record
	_clear_mark(key)
	if effects_root != null and effects_root.is_inside_tree():
		var mark: SignMark = SignMark.new()
		mark.configure(target, primer, PRIMER_DURATION)
		effects_root.add_child(mark)
		_marks[key] = mark


func _clear_mark(key: int) -> void:
	if _marks.has(key):
		if is_instance_valid(_marks[key]):
			_marks[key].queue_free()
		_marks.erase(key)


## The Sign Ring and badge on an enemy right now, or null.
func sign_mark_on(target: ActorBase) -> SignMark:
	if target == null or not _marks.has(target.get_instance_id()):
		return null
	var mark: SignMark = _marks[target.get_instance_id()]
	return mark if is_instance_valid(mark) and not mark.is_queued_for_deletion() else null


## Adds the seal's detonation to this hit if a teammate stamped it. Seals last
## 8 s. Every Sign goes through the same steps: whatever its seal's data says.
func _try_detonate(target: ActorBase, event: CombatEvent) -> void:
	var key: int = target.get_instance_id()
	if not _primers.has(key):
		return
	var record: PrimerRecord = _primers[key]
	if game_time() > record.expires_at:
		_primers.erase(key)
		return
	# Teammates detonate; the player who primed can't cash in their own primer.
	if record.applier_id == event.attacker_player_id:
		return
	_primers.erase(key)
	var cross: bool = record.applier_role != event.attacker_role \
		or (event.scribe_sign != ScribeSignResource.Sign.NONE and event.scribe_sign != record.primer)
	var multiplier: float = CROSS_HARMONY_MULTIPLIER if cross else 1.0
	var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(record.primer)
	event.poise_damage += seal.bonus_poise * multiplier
	event.damage += seal.bonus_damage * multiplier
	# A detonation freezes for 180 ms (11 GDD §4.2), plus any extra its seal adds.
	event.hit_stop_scale = maxf(event.hit_stop_scale, HIT_STOP_DETONATION / BASE_HIT_STOP) + seal.bonus_hit_stop
	var frozen: Array[ActorBase] = [target]
	var detonator: ActorBase = _actor_at(event.attacker_path)
	if detonator != null and detonator.is_multiplayer_authority():
		frozen.append(detonator)
	request_hit_stop(frozen, event.hit_stop_scale)
	if seal.bonus_damage > 0.0 and seal.burst_radius > 0.0:
		_burst(target, event, seal.bonus_damage * multiplier, seal.burst_radius * event.detonation_radius_mult)
	if seal.has_party_effect():
		_bless_party(target, event, seal, multiplier, event.detonation_radius_mult)
	var label: String = seal.detonation_name
	if cross:
		label += "  x%.1f CROSS-HARMONY" % multiplier
	if NetworkManager.current.is_online():
		_show_detonation.rpc(target.get_path(), record.primer, cross, label)
	else:
		_show_detonation(target.get_path(), record.primer, cross, label)
	_reward_synergy(record, event, multiplier, seal)


## Every peer shows (and signals) a detonation the target's owner resolved.
@rpc("any_peer", "call_local", "reliable")
func _show_detonation(target_path: NodePath, primer: int, cross: bool, label: String) -> void:
	var target: ActorBase = _actor_at(target_path)
	if target == null:
		return
	var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(primer)
	show_float_text(_above(target) + Vector3.UP * 0.9, label, seal.color, ANNOUNCE_TEXT_SIZE)
	if seal.sound != &"":
		AudioCues.play(seal.sound)
	_primers.erase(target.get_instance_id())
	_clear_mark(target.get_instance_id())
	SignMark.shockwave(effects_root, target.global_position, seal.color)
	synergy_detonated.emit(target, primer, cross, label)


## Glacial Rupture's burst: the bonus also hits other enemies near the target.
func _burst(target: ActorBase, event: CombatEvent, damage: float, radius: float) -> void:
	for boss: ActorBase in _bosses:
		if boss == target or not is_instance_valid(boss) or boss.global_position.distance_to(target.global_position) > radius:
			continue
		var splash: CombatEvent = CombatEvent.new()
		splash.kind = CombatEvent.Kind.STRIKE
		splash.attacker_path = event.attacker_path
		splash.target_path = boss.get_path()
		splash.attacker_player_id = event.attacker_player_id
		splash.attacker_role = event.attacker_role
		splash.damage = damage
		splash.origin = target.global_position
		splash.reach = event.reach + radius
		deliver(splash)


## Dawnburst and Astral Chorus: heals, stamina and pips for the party near the target.
func _bless_party(target: ActorBase, event: CombatEvent, seal: ScribeSignResource, multiplier: float, radius_mult: float = 1.0) -> void:
	for member: ActorBase in party_actors():
		if member.global_position.distance_to(target.global_position) > seal.party_radius * radius_mult:
			continue
		if seal.party_heal > 0.0:
			deliver(_heal_event(event.attacker_path, event.attacker_player_id, member, seal.party_heal * multiplier))
		if seal.party_stamina > 0.0 or seal.party_pips > 0.0:
			deliver(_reward_event(member, seal.party_pips * multiplier, seal.party_stamina * multiplier))


## Both family members behind a detonation earn resonance and get their own
## burst of light in the seal's colour, so everyone sees who teamed up.
func _reward_synergy(record: PrimerRecord, event: CombatEvent, multiplier: float, seal: ScribeSignResource) -> void:
	var amount: float = SYNERGY_RESONANCE_REWARD * multiplier
	for partner_id: StringName in [record.applier_id, event.attacker_player_id]:
		var partner: ActorBase = get_actor(partner_id)
		if partner == null:
			continue
		deliver(_reward_event(partner, amount))
		show_cue(partner, seal.color, &"reward")
		announce(_above(partner), "+%s pip" % _pip_text(amount), seal.color)
	synergy_rewarded.emit(record.applier_id, event.attacker_player_id, amount)


func _pip_text(amount: float) -> String:
	if is_equal_approx(amount, 0.5):
		return "½"
	if is_equal_approx(amount, 0.75):
		return "¾"
	return "%.2f" % amount


## Who stamped the seal on `target` (&"" if there's none): teammates detonate it.
func primer_applier(target: ActorBase) -> StringName:
	if primer_on(target) == ScribeSignResource.Sign.NONE:
		return &""
	return _primers[target.get_instance_id()].applier_id


## The Sign whose seal is on `target` right now (CardSign.NONE if none).
func primer_on(target: ActorBase) -> int:
	if target == null:
		return ScribeSignResource.Sign.NONE
	var key: int = target.get_instance_id()
	if not _primers.has(key) or game_time() > _primers[key].expires_at:
		return ScribeSignResource.Sign.NONE
	return _primers[key].primer


# --- Sign-Flow and Glimmer-Spots (14 GDD §2–3) --------------------------------

## A hero's coat look on every peer (SignFlowComponent.CoatLook): the Hearth-Rite's
## 1.35x glow, the 600 ms 2.0x flare, the coat's glow for `seconds`, or none.
func show_sign_coat(actor: ActorBase, look: int, scribe_sign: int, mode: int, place_id: StringName, seconds: float) -> void:
	if NetworkManager.current.is_online():
		_show_sign_coat.rpc(actor.get_path(), look, scribe_sign, mode, place_id, seconds)
	else:
		_show_sign_coat(actor.get_path(), look, scribe_sign, mode, place_id, seconds)


@rpc("any_peer", "call_local", "reliable")
func _show_sign_coat(actor_path: NodePath, look: int, scribe_sign: int, mode: int, place_id: StringName, seconds: float) -> void:
	var actor: ActorBase = _actor_at(actor_path)
	if actor == null:
		return
	var synergy: Dictionary = ArsenalCatalog.current.compute_diorama_synergy(&"", place_id)
	var ink: Color = ArsenalCatalog.current.sign_seal(scribe_sign).color if scribe_sign != ScribeSignResource.Sign.NONE else ArsenalCatalog.UNINKED_INK
	var ambient: Color = synergy["ambient_color"] if place_id != &"" else ink
	if actor.visuals != null:
		actor.visuals.show_sign_coat(look, ink, ambient, mode, seconds)
	sign_coat_shown.emit(actor, look)


## A coat look on this peer only: the Scribery's preview on the shopper's own puppet, and putting it back.
func show_sign_coat_here(actor: ActorBase, look: int, scribe_sign: int, mode: int, place_id: StringName, seconds: float) -> void:
	_show_sign_coat(actor.get_path(), look, scribe_sign, mode, place_id, seconds)


## The 2.5 m Sign ring stamped on the ground under a Sign-Flow cast, on every peer.
func stamp_sign_ring(actor: ActorBase, scribe_sign: int, radius: float) -> void:
	if NetworkManager.current.is_online():
		_stamp_sign_ring.rpc(actor.global_position, scribe_sign, radius)
	else:
		_stamp_sign_ring(actor.global_position, scribe_sign, radius)


@rpc("any_peer", "call_local", "reliable")
func _stamp_sign_ring(at: Vector3, scribe_sign: int, radius: float) -> void:
	var color: Color = ArsenalCatalog.current.sign_seal(scribe_sign).color if scribe_sign != ScribeSignResource.Sign.NONE else ArsenalCatalog.UNINKED_INK
	SignMark.ground_ring(effects_root, at, color, radius)


## A Ward-Mantle's shelter: a Shadow Sanctuary cone (BLUE_BEHIND_TANK) behind the hero.
func spawn_shelter(owner: ActorBase, radius: float, seconds: float) -> void:
	if NetworkManager.current.is_online():
		_spawn_zone.rpc(owner.player_id, SanctuaryZone.Shape.CONE, owner.global_transform, radius, seconds, 0.0, 0.0)
	else:
		_spawn_zone(owner.player_id, SanctuaryZone.Shape.CONE, owner.global_transform, radius, seconds, 0.0, 0.0)


## The foe's owner opened its Glimmer-Spot: every peer shows the glint (and the rhyme, while it's new).
func show_glimmer(enemy: ActorBase, seconds: float, rhyme: String) -> void:
	if NetworkManager.current.is_online():
		_show_glimmer.rpc(enemy.get_path(), seconds, rhyme)
	else:
		_show_glimmer(enemy.get_path(), seconds, rhyme)


@rpc("any_peer", "call_local", "reliable")
func _show_glimmer(enemy_path: NodePath, seconds: float, rhyme: String) -> void:
	var enemy: ActorBase = _actor_at(enemy_path)
	if enemy == null or enemy.glimmer == null:
		return
	enemy.glimmer.show_open(seconds)
	if rhyme == "":
		show_cue(enemy, GlimmerSpotComponent.GLINT_COLOR, &"")
	glimmer_opened.emit(enemy, seconds, rhyme)


## The foe's owner: its next Glimmer-Spot opens in `seconds` (Squires may buffer a counter), on every peer.
func expect_glimmer(enemy: ActorBase, seconds: float) -> void:
	if NetworkManager.current.is_online():
		_expect_glimmer.rpc(enemy.get_path(), seconds)
	else:
		_expect_glimmer(enemy.get_path(), seconds)


@rpc("any_peer", "call_local", "reliable")
func _expect_glimmer(enemy_path: NodePath, seconds: float) -> void:
	var enemy: ActorBase = _actor_at(enemy_path)
	if enemy != null and enemy.glimmer != null:
		enemy.glimmer.expect_opening(seconds)


## A Bravery Counter (on the foe's owner; GlimmerSpotComponent set its poise):
## the Sign's detonation rides on it (Glacial Rupture's burst, Dawnburst's heal,
## Astral Chorus's stamina and pips; Shatterpoint's poise is already in the
## counter), with a detonation's freeze, and every peer sees it.
func bravery_counter(target: ActorBase, event: CombatEvent, scribe_sign: int, encounter: BossEncounterResource, banner: String = "") -> void:
	var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(scribe_sign)
	event.damage += seal.bonus_damage
	if seal.bonus_damage > 0.0 and seal.burst_radius > 0.0:
		_burst(target, event, seal.bonus_damage, seal.burst_radius * event.detonation_radius_mult)
	if seal.has_party_effect():
		_bless_party(target, event, seal, 1.0, event.detonation_radius_mult)
	event.hit_stop_scale = maxf(event.hit_stop_scale, HIT_STOP_DETONATION / BASE_HIT_STOP) + seal.bonus_hit_stop
	var frozen: Array[ActorBase] = [target]
	var counterer: ActorBase = _actor_at(event.attacker_path)
	if counterer != null and counterer.is_multiplayer_authority():
		frozen.append(counterer)
	if counterer != null and counterer.visuals != null:
		counterer.visuals.play_bravery_counter()
	request_hit_stop(frozen, event.hit_stop_scale)
	var label: String = "BRAVERY COUNTER!  %s x%.2f" % [seal.detonation_name if banner == "" else banner, encounter.get_impact_multiplier()]
	if NetworkManager.current.is_online():
		_show_bravery.rpc(target.get_path(), scribe_sign, label)
	else:
		_show_bravery(target.get_path(), scribe_sign, label)


@rpc("any_peer", "call_local", "reliable")
func _show_bravery(target_path: NodePath, scribe_sign: int, label: String) -> void:
	var target: ActorBase = _actor_at(target_path)
	if target == null:
		return
	var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(scribe_sign)
	if target.glimmer != null:
		target.glimmer.close()
	show_float_text(_above(target) + Vector3.UP * 0.9, label, seal.color, ANNOUNCE_TEXT_SIZE)
	if seal.sound != &"":
		AudioCues.play(seal.sound)
	SignMark.shockwave(effects_root, target.global_position, seal.color)
	bravery_countered.emit(target, scribe_sign, label)


# --- Support blessings (14 GDD §8) ------------------------------------------------

enum Blessing { AEGIS_WARD, INK_SHARE }

## A Support's Ink-Share: everyone the Soul Tether holds or within `radius` strikes in `scribe_sign` for `seconds`.
func share_ink(support: ActorBase, scribe_sign: int, seconds: float, radius: float) -> void:
	var held: ActorBase = support.tether.tethered_actor() if support.tether != null else null
	var recipients: Array[ActorBase] = []
	for member: ActorBase in alive_party():
		if member == held or member.global_position.distance_to(support.global_position) <= radius:
			recipients.append(member)
			_send_blessing(member, Blessing.INK_SHARE, scribe_sign, seconds, support.player_id)
	if NetworkManager.current.is_online():
		_show_ink_pulse.rpc(support.get_path(), scribe_sign, radius)
	else:
		_show_ink_pulse(support.get_path(), scribe_sign, radius)
	ink_shared.emit(support, scribe_sign, recipients)


## A Support's Aegis Ward on an ally: their next stun or knockdown is shrugged off.
func grant_aegis_ward(support: ActorBase, ally: ActorBase) -> void:
	_send_blessing(ally, Blessing.AEGIS_WARD, ScribeSignResource.Sign.NONE, 0.0, support.player_id)


func _send_blessing(target: ActorBase, kind: Blessing, scribe_sign: int, seconds: float, from_id: StringName) -> void:
	if target.is_multiplayer_authority():
		_apply_blessing(target, kind, scribe_sign, seconds, from_id)
	elif InstanceManager.current.is_peer_live(target.get_multiplayer_authority()):
		_receive_blessing.rpc_id(target.get_multiplayer_authority(), target.get_path(), kind, scribe_sign, seconds, from_id)


@rpc("any_peer", "call_remote", "reliable")
func _receive_blessing(target_path: NodePath, kind: int, scribe_sign: int, seconds: float, from_id: StringName) -> void:
	var target: ActorBase = _actor_at(target_path)
	var support: ActorBase = get_actor(from_id)
	if target == null or not target.is_multiplayer_authority() or support == null \
			or support.get_multiplayer_authority() != multiplayer.get_remote_sender_id():
		return
	if kind == Blessing.INK_SHARE and not _diorama_carries(support, scribe_sign):
		return
	_apply_blessing(target, kind as Blessing, scribe_sign, minf(seconds, SignFlowComponent.INK_SHARE_TIME), from_id)


func _apply_blessing(target: ActorBase, kind: Blessing, scribe_sign: int, seconds: float, from_id: StringName) -> void:
	if target.sign_flow == null:
		return
	match kind:
		Blessing.INK_SHARE:
			target.sign_flow.receive_ink_share(scribe_sign, seconds, from_id)
		Blessing.AEGIS_WARD:
			target.sign_flow.receive_aegis_ward()


## The Ink-Share on every peer: the Sign pulses down the Soul Tether and rings out round the Support.
@rpc("any_peer", "call_local", "reliable")
func _show_ink_pulse(support_path: NodePath, scribe_sign: int, radius: float) -> void:
	var support: ActorBase = _actor_at(support_path)
	if support == null:
		return
	var color: Color = ArsenalCatalog.current.sign_seal(scribe_sign).color
	if support.tether != null:
		support.tether.pulse(color)
	SignMark.ground_ring(effects_root, support.global_position, color, radius)
	show_float_text(_above(support) + Vector3.UP * 0.5, "INK-SHARE: %s" % ArsenalCatalog.current.sign_seal(scribe_sign).display_name.to_upper(),
		color, 30)


# --- Support effects ------------------------------------------------------

func taunt_bosses(taunter: ActorBase, duration: float) -> void:
	for boss: ActorBase in _bosses:
		deliver(_threat_event(taunter.get_path(), taunter.player_id, boss, TAUNT_THREAT, duration))
	announce(_above(taunter), "TAUNT!", Color(0.6, 0.75, 1.0))


func apply_heal(healer: ActorBase, target: ActorBase, amount: float, echo: float = 0.0) -> void:
	if healer == null or target == null:
		return
	var event: CombatEvent = _heal_event(healer.get_path(), healer.player_id, target, amount)
	event.echo = echo
	deliver(event)


## Hearth Echo: part of a landed heal bounces on to the next most hurt ally near
## the target (once: the bounce itself doesn't echo).
func _echo_heal(target: ActorBase, event: CombatEvent) -> void:
	var next: ActorBase = null
	var lowest: float = 1.0
	for member: ActorBase in party_actors():
		if member == target or member.global_position.distance_to(target.global_position) > ECHO_RADIUS:
			continue
		if member.stats.health_ratio() < lowest:
			lowest = member.stats.health_ratio()
			next = member
	if next != null:
		deliver(_heal_event(event.attacker_path, event.attacker_player_id, next, event.heal * event.echo))


## The Way-Staff's flourish (11 GDD §4.1): the most hurt party member within
## `radius` of the healer (themself included) is mended.
func mend_most_hurt(healer: ActorBase, amount: float, radius: float) -> void:
	var chosen: ActorBase = null
	var lowest: float = 1.0
	for member: ActorBase in alive_party():
		if member.global_position.distance_to(healer.global_position) > radius:
			continue
		if member.stats.health_ratio() < lowest:
			lowest = member.stats.health_ratio()
			chosen = member
	if chosen != null:
		apply_heal(healer, chosen, amount)


## A Flow-Link Pulse's white-gold ring and chime, on every peer.
func show_flow_link(actor: ActorBase) -> void:
	if NetworkManager.current.is_online():
		_show_flow_link.rpc(actor.get_path())
	else:
		_show_flow_link(actor.get_path())


@rpc("any_peer", "call_local", "reliable")
func _show_flow_link(actor_path: NodePath) -> void:
	var actor: ActorBase = _actor_at(actor_path)
	if actor == null:
		return
	if actor.visuals != null:
		actor.visuals.flash_flow_ring()
	if actor.is_local_player():
		AudioCues.play(&"flow", 1.3)
	flow_link_shown.emit(actor)


## Pips and stamina for one player, applied by their owner (a mechanic's reward).
func reward(target: ActorBase, pips: float, stamina: float = 0.0) -> void:
	deliver(_reward_event(target, pips, stamina))


## A Wayfarer's Water-Shrine: everyone back to full health and stamina (each
## owner refreshes its own; no threat, no healer's pips).
func refresh_party() -> void:
	for member: ActorBase in party_actors():
		var event: CombatEvent = _reward_event(member, 0.0, member.stats.stats.max_stamina)
		event.heal = member.stats.stats.max_health
		deliver(event)


## Shoves an actor to `destination` over `duration` (a gust, a torrent's
## knockback); its owner moves it, briefly untouchable on the way.
func shove(target: ActorBase, destination: Vector3, duration: float) -> void:
	var event: CombatEvent = CombatEvent.new()
	event.kind = CombatEvent.Kind.PULL
	event.attacker_path = target.get_path()
	event.attacker_player_id = target.player_id
	event.target_path = target.get_path()
	event.origin = destination
	event.duration = duration
	deliver(event)


func lifeline_pull(healer: ActorBase, target: ActorBase, duration: float) -> void:
	var event: CombatEvent = CombatEvent.new()
	event.kind = CombatEvent.Kind.PULL
	event.attacker_path = healer.get_path()
	event.attacker_player_id = healer.player_id
	event.target_path = target.get_path()
	event.origin = healer.global_position + healer.facing_vector() * LIFELINE_LANDING_DISTANCE
	event.duration = duration
	deliver(event)
	announce(_above(target), "LIFELINE!", Color(0.5, 1.0, 0.65))


func spawn_zone(owner: ActorBase, shape: SanctuaryZone.Shape, action: CombatActionResource) -> void:
	if NetworkManager.current.is_online():
		_spawn_zone.rpc(owner.player_id, shape, owner.global_transform, action.effect_radius, action.effect_duration, action.heal_amount,
			action.zone_stamina_per_second)
	else:
		_spawn_zone(owner.player_id, shape, owner.global_transform, action.effect_radius, action.effect_duration, action.heal_amount,
			action.zone_stamina_per_second)


@rpc("any_peer", "call_local", "reliable")
func _spawn_zone(owner_id: StringName, shape: int, where: Transform3D, radius: float, duration: float, heal_per_second: float,
		stamina_per_second: float) -> void:
	if effects_root == null:
		return
	var zone: SanctuaryZone = SanctuaryZone.new()
	zone.configure(owner_id, shape as SanctuaryZone.Shape, radius, duration, heal_per_second, stamina_per_second)
	effects_root.add_child(zone)
	zone.global_transform = where


func launch_homing_heal(healer: ActorBase, target: ActorBase, amount: float, echo: float = 0.0) -> void:
	if NetworkManager.current.is_online():
		_spawn_homing_heal.rpc(healer.get_path(), target.get_path(), amount, echo)
	else:
		_spawn_homing_heal(healer.get_path(), target.get_path(), amount, echo)


@rpc("any_peer", "call_local", "reliable")
func _spawn_homing_heal(healer_path: NodePath, target_path: NodePath, amount: float, echo: float) -> void:
	var healer: ActorBase = _actor_at(healer_path)
	var target: ActorBase = _actor_at(target_path)
	if healer == null or target == null or effects_root == null:
		return
	var orb: HomingHeal = HomingHeal.new()
	orb.configure(healer, target, amount, echo)
	effects_root.add_child(orb)
	orb.global_position = healer.global_position + Vector3.UP * 1.5


# --- Scribe Card invocations ----------------------------------------------

## A card's wind-up began on its caster's peer: every peer with this instance
## loaded shows its seal, vellum card and variant flourish.
func invoke_card(caster: ActorBase, action: CombatActionResource) -> void:
	_show_invocation(caster, action)
	for peer_id: int in InstanceManager.current.live_remote_peers():
		_show_invocation_copy.rpc_id(peer_id, caster.get_path(), action.action_id)


@rpc("any_peer", "call_remote", "reliable")
func _show_invocation_copy(caster_path: NodePath, action_id: StringName) -> void:
	var caster: ActorBase = _actor_at(caster_path)
	if caster == null or caster.get_multiplayer_authority() != multiplayer.get_remote_sender_id():
		return
	var action: CombatActionResource = caster.loadout.action_by_id(action_id)
	if action != null and action.is_card():
		_show_invocation(caster, action)


func _show_invocation(caster: ActorBase, action: CombatActionResource) -> void:
	if fx_pool == null:
		return
	var kit: EquipmentLoadoutResource = caster.loadout.kit
	var variant: ScribeCardResource.CardVariant = ScribeCardResource.CardVariant.STANDARD
	if kit != null and action.grimoire_slot >= 0:
		variant = kit.lead_variant(action.grimoire_slot)
	var fx: ScribeInvocationFX = fx_pool.take(&"invocation", ScribeInvocationFX.make) as ScribeInvocationFX
	fx.play(caster, ArsenalCatalog.current.sign_seal(action.scribe_sign), variant, action.windup_time, action.is_projectile())
	card_invoked.emit(caster, action, variant)


# --- Projectiles ----------------------------------------------------------

## A ranged strike: the attacker's peer flies the real projectile; every other
## peer with this instance loaded flies a look-alike, named by action id.
func launch_projectile(attacker: ActorBase, action: CombatActionResource, flowed: bool) -> void:
	var origin: Vector3 = RuneProjectile.muzzle_of(attacker)
	var direction: Vector3 = _aim(attacker, origin, action.projectile_range)
	_fire(attacker, action, origin, direction, true, flowed)
	for peer_id: int in InstanceManager.current.live_remote_peers():
		_fire_copy.rpc_id(peer_id, attacker.get_path(), action.action_id, origin, direction)


@rpc("any_peer", "call_remote", "reliable")
func _fire_copy(attacker_path: NodePath, action_id: StringName, origin: Vector3, direction: Vector3) -> void:
	var attacker: ActorBase = _actor_at(attacker_path)
	if attacker == null or attacker.get_multiplayer_authority() != multiplayer.get_remote_sender_id():
		return
	var action: CombatActionResource = attacker.loadout.action_by_id(action_id)
	if action != null and action.is_projectile():
		_fire(attacker, action, origin, direction, false, false)


func _fire(attacker: ActorBase, action: CombatActionResource, origin: Vector3, direction: Vector3, real: bool, flowed: bool) -> void:
	if fx_pool == null:
		return
	var shot: RuneProjectile = fx_pool.take(StringName("shot:%s" % action.projectile_look), _make_projectile.bind(action.projectile_look)) as RuneProjectile
	shot.launch(attacker, action, origin, direction, real, flowed)
	AudioCues.play_at(&"shot", origin, 1.0 if action.is_card() else SHOT_PITCH_PLAIN, SHOT_VOLUME_DB)
	projectile_fired.emit(attacker, action)


func _make_projectile(look_id: StringName) -> RuneProjectile:
	var shot: RuneProjectile = RuneProjectile.new()
	shot.build_look(ArsenalCatalog.current.item(look_id))
	return shot


## Toward the target when it's in range and roughly ahead (children aim
## loosely); otherwise straight where the archer faces.
func _aim(attacker: ActorBase, origin: Vector3, flight_range: float) -> Vector3:
	var forward: Vector3 = attacker.facing_vector()
	var target: ActorBase = attacker.soft_target()
	if target == null:
		return forward
	var to_target: Vector3 = target.global_position + Vector3.UP * target.body_height() * 0.5 - origin
	var flat: Vector3 = Vector3(to_target.x, 0.0, to_target.z)
	if flat.length() < 0.01 or to_target.length() > flight_range + target.body_radius() or forward.dot(flat.normalized()) < AIM_ASSIST_DOT:
		return forward
	return to_target.normalized()


# --- Floating text --------------------------------------------------------

## Big callouts (synergies, perfect guards) that every peer should see and hear.
func announce(at: Vector3, text: String, color: Color, sound: StringName = &"") -> void:
	if NetworkManager.current.is_online():
		_show_announcement.rpc(at, text, color, sound)
	else:
		_show_announcement(at, text, color, sound)


@rpc("any_peer", "call_local", "reliable")
func _show_announcement(at: Vector3, text: String, color: Color, sound: StringName) -> void:
	show_float_text(at, text, color, ANNOUNCE_TEXT_SIZE)
	if sound != &"":
		AudioCues.play(sound)


## A burst of light at an actor, on every peer, with an optional sound.
func show_cue(actor: ActorBase, color: Color, sound: StringName) -> void:
	if NetworkManager.current.is_online():
		_show_cue.rpc(actor.global_position, color, sound)
	else:
		_show_cue(actor.global_position, color, sound)


@rpc("any_peer", "call_local", "reliable")
func _show_cue(at: Vector3, color: Color, sound: StringName) -> void:
	if effects_root != null and effects_root.is_inside_tree():
		var burst: CueBurst = CueBurst.new()
		burst.configure(color)
		effects_root.add_child(burst)
		burst.global_position = at
	if sound != &"":
		AudioCues.play(sound)
	cue_shown.emit(at, sound)


func show_float_text(at: Vector3, text: String, color: Color, size: int = 40) -> void:
	if effects_root == null or not effects_root.is_inside_tree():
		return
	var label: Label3D = Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = size
	label.outline_size = 12
	label.pixel_size = 0.008
	label.modulate = color
	effects_root.add_child(label)
	label.global_position = at
	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", at + Vector3.UP * FLOAT_TEXT_RISE, FLOAT_TEXT_TIME)
	tween.tween_property(label, "modulate:a", 0.0, FLOAT_TEXT_TIME * 0.6).set_delay(FLOAT_TEXT_TIME * 0.4)
	tween.chain().tween_callback(label.queue_free)


# --- Helpers --------------------------------------------------------------

func _actor_at(path: NodePath) -> ActorBase:
	if path.is_empty():
		return null
	return get_node_or_null(path) as ActorBase


func _above(actor: ActorBase) -> Vector3:
	return actor.global_position + Vector3.UP * (actor.body_height() + 0.3)


func _heal_event(healer_path: NodePath, healer_id: StringName, target: ActorBase, amount: float) -> CombatEvent:
	var event: CombatEvent = CombatEvent.new()
	event.kind = CombatEvent.Kind.HEAL
	event.attacker_path = healer_path
	event.attacker_player_id = healer_id
	event.target_path = target.get_path()
	event.heal = amount
	return event


func _reward_event(target: ActorBase, pips: float, stamina: float = 0.0) -> CombatEvent:
	var event: CombatEvent = CombatEvent.new()
	event.kind = CombatEvent.Kind.REWARD
	event.target_path = target.get_path()
	event.attacker_path = target.get_path()
	event.attacker_player_id = target.player_id
	event.resonance = pips
	event.stamina = stamina
	return event


func _threat_event(source_path: NodePath, source_id: StringName, boss: ActorBase, amount: float, taunt_duration: float) -> CombatEvent:
	var event: CombatEvent = CombatEvent.new()
	event.kind = CombatEvent.Kind.THREAT
	event.attacker_path = source_path
	event.attacker_player_id = source_id
	event.target_path = boss.get_path()
	event.threat = amount
	event.duration = taunt_duration
	return event
