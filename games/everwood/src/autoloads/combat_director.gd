## The Combat Director (autoload).
##
## - Local hit-stop: a landed blow freezes just the attacker and target for
##   60 ms, scaled per action. No global pause, so other split-screen players
##   keep moving.
## - Cross-Class Synergy: a DPS primes the boss (Stagger, Frost, Radiant) and a
##   *teammate* detonates it for a bonus, bigger when the detonator plays a
##   different role.
## - One rule for networked combat: the peer that owns the target applies the
##   effect. Every strike, heal, threat and pull goes through deliver(), which
##   applies it here or sends it to the owner as a validation RPC.
class_name CombatDirector
extends Node

## The live autoload node. Scripts reach it as `CombatDirector.current` rather than by
## its autoload name, so `godot --check-only -s` (which runs before autoloads
## are registered) can still compile them.
static var current: CombatDirector

signal hit_stop_applied(duration: float)
signal hit_resolved(event: CombatEvent, outcome: int)
signal primer_applied(target: ActorBase, primer: int)
signal synergy_detonated(target: ActorBase, primer: int, cross_class: bool, label: String)
signal perfect_guard_landed(defender: ActorBase)
signal telegraph_cast(decal: RaidTelegraphDecal)
## A burst of light and a sound at an actor (every peer emits it for every cue).
signal cue_shown(at: Vector3, cue: StringName)
## Both players behind a detonation were rewarded (on the detonating target's owner).
signal synergy_rewarded(applier_id: StringName, detonator_id: StringName, resonance: float)

## Phase B impact freeze (02_COMBAT_GDD.md §2); each action scales it.
const BASE_HIT_STOP: float = 0.06
const PRIMER_DURATION: float = 8.0
## Detonated by a different role than the one who primed it.
const CROSS_CLASS_MULTIPLIER: float = 1.5
const STAGGER_BONUS_POISE: float = 45.0
const FROST_BONUS_DAMAGE: float = 45.0
const RADIANT_PARTY_HEAL: float = 20.0
const RADIANT_HEAL_RADIUS: float = 10.0
## Hits that land after a flow-cancel fill resonance faster.
const FLOW_RESONANCE_MULTIPLIER: float = 1.5
## Resonance pips each partner in a synergy earns (x CROSS_CLASS_MULTIPLIER across roles).
const SYNERGY_RESONANCE_REWARD: float = 0.5
## Healers fill resonance by healing: pips per point of health restored.
const HEAL_RESONANCE_PER_HP: float = 0.008
const PERFECT_GUARD_RESONANCE: float = 0.5
const PERFECT_GUARD_POISE: float = 50.0
const PERFECT_GUARD_THREAT: float = 250.0
const PERFECT_GUARD_HIT_STOP_SCALE: float = 2.5
const HEAL_THREAT_RATIO: float = 0.5
const TAUNT_THREAT: float = 50.0
## Metres of lag forgiveness when checking a hit reported by another peer.
const VALIDATION_SLACK: float = 3.0
const LIFELINE_LANDING_DISTANCE: float = 1.3
const FLOAT_TEXT_TIME: float = 0.9
const FLOAT_TEXT_RISE: float = 1.4

class PrimerRecord:
	var primer: int = CombatActionResource.Synergy.NONE
	var applier_id: StringName = &""
	var applier_role: int = ClassLoadoutResource.Role.DPS
	var expires_at: float = 0.0

## Where zones, heals and floating text are spawned (the level sets this).
var effects_root: Node3D

var _actors: Dictionary[StringName, ActorBase] = {}
var _bosses: Array[ActorBase] = []
var _primers: Dictionary[int, PrimerRecord] = {}
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
	_actors.clear()
	_bosses.clear()
	_primers.clear()
	_zones.clear()
	_telegraphs.clear()


# --- Registries -----------------------------------------------------------

func register_actor(actor: ActorBase) -> void:
	if actor.is_boss():
		if not _bosses.has(actor):
			_bosses.append(actor)
	else:
		_actors[actor.player_id] = actor


func unregister_actor(actor: ActorBase) -> void:
	_bosses.erase(actor)
	if _actors.has(actor.player_id) and _actors[actor.player_id] == actor:
		_actors.erase(actor.player_id)
	_primers.erase(actor.get_instance_id())


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


func primary_boss() -> ActorBase:
	for boss: ActorBase in _bosses:
		if is_instance_valid(boss):
			return boss
	return null


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


func register_zone(zone: SanctuaryZone) -> void:
	_zones.append(zone)


func unregister_zone(zone: SanctuaryZone) -> void:
	_zones.erase(zone)


## Shadow Sanctuary: allies inside a tank's shield cone take less damage.
func damage_taken_multiplier(actor: ActorBase) -> float:
	var multiplier: float = 1.0
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
func report_hit(attacker: ActorBase, target: ActorBase, action: CombatActionResource, flowed: bool) -> void:
	request_hit_stop([attacker, target], action.hit_stop_scale)
	attacker.stats.add_resonance(action.resonance_gain * (FLOW_RESONANCE_MULTIPLIER if flowed else 1.0))
	if attacker.is_local_player():
		AudioCues.play(&"hit", 1.15 / maxf(0.7, action.hit_stop_scale), -4.0)
	if action.damage > 0.0:
		show_float_text(_above(target), str(roundi(action.damage)), Color(1.0, 0.94, 0.78))
	deliver(CombatEvent.strike_from(attacker, target, action))


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
	var limit: float = event.reach + target.body_radius() + VALIDATION_SLACK
	return attacker.global_position.distance_to(target.global_position) <= limit


func _apply(target: ActorBase, event: CombatEvent, from_remote: bool) -> void:
	match event.kind:
		CombatEvent.Kind.STRIKE:
			_apply_strike(target, event, from_remote)
		CombatEvent.Kind.HEAL:
			var healed: float = target.receive_heal(event.heal)
			if healed > 0.0:
				show_float_text(_above(target), "+%d" % roundi(healed), Color(0.5, 1.0, 0.6))
				AudioCues.play(&"heal", 1.0, -6.0)
				for boss: ActorBase in _bosses:
					deliver(_threat_event(event.attacker_path, event.attacker_player_id, boss, healed * HEAL_THREAT_RATIO, 0.0))
				var healer: ActorBase = get_actor(event.attacker_player_id)
				if healer != null:
					deliver(_reward_event(healer, healed * HEAL_RESONANCE_PER_HP))
		CombatEvent.Kind.REWARD:
			target.stats.add_resonance(event.resonance)
		CombatEvent.Kind.THREAT:
			if target.threat != null:
				if event.duration > 0.0:
					target.threat.taunt(event.attacker_player_id, event.duration)
				else:
					target.threat.add_threat(event.attacker_player_id, event.threat)
		CombatEvent.Kind.PULL:
			target.start_forced_move(event.origin, event.duration)


func _apply_strike(target: ActorBase, event: CombatEvent, from_remote: bool) -> void:
	if target.is_boss():
		if event.detonates:
			_try_detonate(target, event)
		if event.primer != CombatActionResource.Synergy.NONE:
			_apply_primer(target, event)
	var outcome: int = target.receive_strike(event)
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
	counter.threat = PERFECT_GUARD_THREAT
	counter.hit_stop_scale = PERFECT_GUARD_HIT_STOP_SCALE
	counter.origin = defender.global_position
	counter.reach = attacker.body_radius() + 4.0
	deliver(counter)


# --- Cross-Class Synergy --------------------------------------------------

func _apply_primer(target: ActorBase, event: CombatEvent) -> void:
	var record: PrimerRecord = PrimerRecord.new()
	record.primer = event.primer
	record.applier_id = event.attacker_player_id
	record.applier_role = event.attacker_role
	record.expires_at = game_time() + PRIMER_DURATION
	_primers[target.get_instance_id()] = record
	primer_applied.emit(target, event.primer)
	announce(_above(target) + Vector3.UP * 0.6, "%s primed" % synergy_primer_name(event.primer), synergy_color(event.primer))


## Adds the primer's bonus to this hit if a teammate set it up. Primers last 8 s.
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
	var cross_class: bool = record.applier_role != event.attacker_role
	var multiplier: float = CROSS_CLASS_MULTIPLIER if cross_class else 1.0
	match record.primer:
		CombatActionResource.Synergy.STAGGER:
			event.poise_damage += STAGGER_BONUS_POISE * multiplier
		CombatActionResource.Synergy.FROST:
			event.damage += FROST_BONUS_DAMAGE * multiplier
		CombatActionResource.Synergy.RADIANT:
			for member: ActorBase in party_actors():
				if member.global_position.distance_to(target.global_position) <= RADIANT_HEAL_RADIUS:
					deliver(_heal_event(event.attacker_path, event.attacker_player_id, member, RADIANT_PARTY_HEAL * multiplier))
	var label: String = synergy_name(record.primer)
	if cross_class:
		label += "  x%.1f CROSS-CLASS" % multiplier
	synergy_detonated.emit(target, record.primer, cross_class, label)
	announce(_above(target) + Vector3.UP * 0.9, label, synergy_color(record.primer), synergy_sound(record.primer))
	_reward_synergy(record, event, multiplier)


## Both family members behind a detonation earn resonance and get their own
## burst of light in the primer's colour, so everyone sees who teamed up.
func _reward_synergy(record: PrimerRecord, event: CombatEvent, multiplier: float) -> void:
	var amount: float = SYNERGY_RESONANCE_REWARD * multiplier
	for partner_id: StringName in [record.applier_id, event.attacker_player_id]:
		var partner: ActorBase = get_actor(partner_id)
		if partner == null:
			continue
		deliver(_reward_event(partner, amount))
		show_cue(partner, synergy_color(record.primer), &"reward")
		announce(_above(partner), "+%s pip" % _pip_text(amount), synergy_color(record.primer))
	synergy_rewarded.emit(record.applier_id, event.attacker_player_id, amount)


func _pip_text(amount: float) -> String:
	if is_equal_approx(amount, 0.5):
		return "½"
	if is_equal_approx(amount, 0.75):
		return "¾"
	return "%.2f" % amount


func synergy_sound(primer: int) -> StringName:
	match primer:
		CombatActionResource.Synergy.STAGGER:
			return &"synergy_stagger"
		CombatActionResource.Synergy.FROST:
			return &"synergy_frost"
		CombatActionResource.Synergy.RADIANT:
			return &"synergy_radiant"
	return &""


func primer_on(target: ActorBase) -> int:
	if target == null:
		return CombatActionResource.Synergy.NONE
	var key: int = target.get_instance_id()
	if not _primers.has(key) or game_time() > _primers[key].expires_at:
		return CombatActionResource.Synergy.NONE
	return _primers[key].primer


func synergy_primer_name(primer: int) -> String:
	match primer:
		CombatActionResource.Synergy.STAGGER:
			return "Stagger"
		CombatActionResource.Synergy.FROST:
			return "Frost"
		CombatActionResource.Synergy.RADIANT:
			return "Radiant"
	return ""


## What each primer becomes when a teammate detonates it.
func synergy_name(primer: int) -> String:
	match primer:
		CombatActionResource.Synergy.STAGGER:
			return "SHATTERPOINT"
		CombatActionResource.Synergy.FROST:
			return "GLACIAL RUPTURE"
		CombatActionResource.Synergy.RADIANT:
			return "DAWNBURST"
	return ""


func synergy_color(primer: int) -> Color:
	match primer:
		CombatActionResource.Synergy.STAGGER:
			return Color(1.0, 0.62, 0.25)
		CombatActionResource.Synergy.FROST:
			return Color(0.55, 0.85, 1.0)
		CombatActionResource.Synergy.RADIANT:
			return Color(1.0, 0.95, 0.55)
	return Color.WHITE


# --- Support effects ------------------------------------------------------

func taunt_bosses(taunter: ActorBase, duration: float) -> void:
	for boss: ActorBase in _bosses:
		deliver(_threat_event(taunter.get_path(), taunter.player_id, boss, TAUNT_THREAT, duration))
	announce(_above(taunter), "TAUNT!", Color(0.6, 0.75, 1.0))


func apply_heal(healer: ActorBase, target: ActorBase, amount: float) -> void:
	if healer == null or target == null:
		return
	deliver(_heal_event(healer.get_path(), healer.player_id, target, amount))


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
		_spawn_zone.rpc(owner.player_id, shape, owner.global_transform, action.effect_radius, action.effect_duration, action.heal_amount)
	else:
		_spawn_zone(owner.player_id, shape, owner.global_transform, action.effect_radius, action.effect_duration, action.heal_amount)


@rpc("any_peer", "call_local", "reliable")
func _spawn_zone(owner_id: StringName, shape: int, where: Transform3D, radius: float, duration: float, heal_per_second: float) -> void:
	if effects_root == null:
		return
	var zone: SanctuaryZone = SanctuaryZone.new()
	zone.configure(owner_id, shape as SanctuaryZone.Shape, radius, duration, heal_per_second)
	effects_root.add_child(zone)
	zone.global_transform = where


func launch_homing_heal(healer: ActorBase, target: ActorBase, amount: float) -> void:
	if NetworkManager.current.is_online():
		_spawn_homing_heal.rpc(healer.get_path(), target.get_path(), amount)
	else:
		_spawn_homing_heal(healer.get_path(), target.get_path(), amount)


@rpc("any_peer", "call_local", "reliable")
func _spawn_homing_heal(healer_path: NodePath, target_path: NodePath, amount: float) -> void:
	var healer: ActorBase = _actor_at(healer_path)
	var target: ActorBase = _actor_at(target_path)
	if healer == null or target == null or effects_root == null:
		return
	var orb: HomingHeal = HomingHeal.new()
	orb.configure(healer, target, amount)
	effects_root.add_child(orb)
	orb.global_position = healer.global_position + Vector3.UP * 1.5


# --- Floating text --------------------------------------------------------

## Big callouts (synergies, perfect guards) that every peer should see and hear.
func announce(at: Vector3, text: String, color: Color, sound: StringName = &"") -> void:
	if NetworkManager.current.is_online():
		_show_announcement.rpc(at, text, color, sound)
	else:
		_show_announcement(at, text, color, sound)


@rpc("any_peer", "call_local", "reliable")
func _show_announcement(at: Vector3, text: String, color: Color, sound: StringName) -> void:
	show_float_text(at, text, color, 54)
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


func _reward_event(target: ActorBase, pips: float) -> CombatEvent:
	var event: CombatEvent = CombatEvent.new()
	event.kind = CombatEvent.Kind.REWARD
	event.target_path = target.get_path()
	event.attacker_path = target.get_path()
	event.attacker_player_id = target.player_id
	event.resonance = pips
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
