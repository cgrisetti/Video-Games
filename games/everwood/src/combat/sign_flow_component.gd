## Sign-Flow on a hero ("Coat, Break, Turn!", 14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md
## §2 and §5). The same L, R and L+R postures work two ways, with no card swap:
##
## - Out of combat, holding R or L+R for 120 frames (80 on a Star-Inked Vellum
##   leaf) is the 0-pip Hearth-Rite Tuck: the hero tops up to at least
##   one Resonance Pip, the weapon glows at 1.35x in the socket's Place-Card
##   tint, and the next fight's first landed strike discharges the socket's
##   full Sign and Place-Card bonus (it carries the Sign, stamps its seal and
##   pulses the place's warmth). The blessing fades 15 s into a fight if no
##   strike lands.
## - In combat, landing a physical attack (Light, Heavy, Forward or Back +
##   Heavy) opens a Flow-Link Window: 14 frames, 9 alone in Dread-Chill (a party
##   of one), 18 within 5.5 m of a Lantern-Bearer (The Lantern's Promise).
##   Tapping R (1 pip) or L+R (3 pips) inside it casts at once (no wind-up);
##   tapping L (1 pip) is a Counter-Brace from the L socket. Either way the
##   weapon flares to 2.0x for 600 ms, foes in the 2.5 m Sign ring freeze for
##   110 ms, and the socket's diorama coats the hero: for the coat's time
##   every strike carries its Sign (so it can crack a Glimmer-Spot) and the
##   Place-Card's poise, and a Flow-Link cancel refunds its stamina. A
##   Ward-Mantle also raises a 4 m shelter cone behind the hero; a
##   Lantern-Tether mends whoever the Soul Tether holds.
##
## The Phase 12 Kaizen pass (14 GDD §8) adds the card choreography and each
## role's loop:
## - The Hearth-Rite is the Overhead Pocket Blessing: the hero lowers the
##   weapon, draws a glowing vellum card from the coat pocket, raises it
##   overhead (under 2.5 m) as Sign ink pours down round them, and draws the
##   weapon again glowing. It also grants a Ward Blessing: the first foe that
##   strikes in the next fight does 15% less, until 15 s into it.
## - A Sign-Flow cast is the Offhand Pocket-Draw: the off hand sweeps the card
##   along the weapon as it ignites at 2.0x, and the split-screen camera
##   dolly-pulses 0.35 m toward the hero's shoulder over 120 ms.
## - DPS: L+R (3 pips) while a Weapon-Coat burns spends the coat on a One-and-Done
##   Seal-Breaker: its leaf's 3.2x the weapon's damage, the Sign's detonation,
##   and it cracks whatever lock or gate the foe shows.
## - Tank: a Ward-Mantle soaks 80% of a blow of its own Sign (or any Sign
##   blow Perfect-Guarded), shrugs off the stun and knockback, throws 60 poise
##   back at the attacker and raises the 4 m shelter cone.
## - Support: binding the Soul Tether (or laying a Green Sanctuary) wards
##   allies against their next stun (an Aegis Ward); casting an Ink-Share leaf
##   (R or L+R) lends its Sign for 8 s to everyone on the tether or within
##   10 m, so their physical blows strike in it and crack its locks.
##
## It runs on the hero's own peer; the looks reach every peer through
## CombatDirector.show_sign_coat, and the Sign travels in each strike's event.
class_name SignFlowComponent
extends Node

signal hearth_rite_prepared(socket: int)
signal opening_strike_discharged(scribe_sign: int)
signal sign_flow_cast(socket: int, scribe_sign: int)
signal one_and_done_unleashed(scribe_sign: int)
signal ward_mantle_held(attacker_id: StringName)
signal ink_shared(scribe_sign: int)
signal aegis_ward_spent

## The smoke test's older checks switch Sign-Flow off (like BracedGuardComponent.enabled).
static var enabled: bool = true

## BLESSING is a one-shot look, like FLARE: it plays the Overhead Pocket Blessing and leaves the look as it was.
enum CoatLook { CLEAR, TRAIL_TUCK, FLARE, COAT, BLESSING }

## An engaged foe this close puts the hero in combat.
const COMBAT_RADIUS: float = 18.0
const FRAMES_PER_SECOND: float = 60.0
const HEARTH_RITE_HOLD_FRAMES: int = 120
const STAR_INKED_HOLD_FRAMES: int = 80
## The Hearth-Rite tops the hero up to at least this many pips.
const HEARTH_RITE_PIPS: float = 1.0
const TRAIL_COAT_SCALE: float = 1.35
## Once a fight starts, an undischarged blessing lasts this long.
const TRAIL_COAT_COMBAT_GRACE: float = 15.0
const FLOW_WINDOW_FRAMES: int = 14
const DREAD_CHILL_WINDOW_FRAMES: int = 9
const LANTERNS_PROMISE_WINDOW_FRAMES: int = 18
const LANTERNS_PROMISE_RADIUS: float = 5.5
const SIGN_FLOW_SCALE: float = 2.0
const SIGN_FLOW_FLARE_TIME: float = 0.6
const SIGN_FLOW_HIT_STOP: float = 0.11
const SIGN_RING_RADIUS: float = 2.5
## An R or L+R pressed in the window still counts while the queue carries it to the recovery's cancel point.
const ARMED_PRESS_TIME: float = 0.35
## L reads as a guard a moment after it's pressed (InputComponent's 0.12 s ult chord wait), so its tap may land just after the window.
const GUARD_TAP_GRACE: float = 0.15
const WARD_MANTLE_CONE_RADIUS: float = 4.0
const WARD_MANTLE_CONE_TIME: float = 3.0
const LANTERN_TETHER_HEAL: float = 6.0
## A Place-Card's mending warmth reaches friends this close (Mill-Warmth).
const PLACE_WARMTH_RADIUS: float = 4.0
## The Hearth-Rite's Ward Blessing: the next foe's blows do this much less, until the fight's grace runs out.
const WARD_BLESSING_MITIGATION: float = 0.15
## The One-and-Done Seal-Breaker spends this many pips (the L+R card's own and any short of it).
const ONE_AND_DONE_PIPS: float = 3.0
## A Support's Ink-Share lasts this long and reaches everyone this close (and whoever the Soul Tether holds).
const INK_SHARE_TIME: float = 8.0
const INK_SHARE_RADIUS: float = 10.0
## A Green Sanctuary wards allies this close with an Aegis Ward.
const SANCTUARY_AEGIS_RADIUS: float = 10.0
## A warded blow's stun and shove, which land a moment after the blow, are shrugged off for this long.
const WARD_SHRUG_GRACE: float = 0.3
const WARD_TEXT_COLOR: Color = Color(0.62, 0.8, 1.0)
const AEGIS_TEXT_COLOR: Color = Color(0.75, 1.0, 0.82)
## The physical attacks whose hits open the Flow-Link Window.
const PHYSICAL_COMMANDS: Array[int] = [CombatActionResource.Command.LIGHT, CombatActionResource.Command.HEAVY,
	CombatActionResource.Command.FORWARD_HEAVY, CombatActionResource.Command.BACK_HEAVY]

const Socket = ScribeCardResource.DioramaSocket
const NO_SIGN: int = ScribeSignResource.Sign.NONE

var actor: ActorBase
var is_in_combat: bool = false
## The Hearth-Rite blessing: its socket, Sign, Place-Card and Action-Leaf.
var has_hearth_rite_tuck: bool = false
var opening_strike_empowered: bool = false
var active_trail_coat_sign: int = NO_SIGN
var active_location_card_id: StringName = &""
var active_action_card_id: StringName = &""
var active_socket: int = -1
## Seconds the blessing has left once a fight starts (it waits, full, until then).
var trail_coat_timer: float = 0.0
## The in-combat coat: its Sign, manifestation, time left and diorama numbers.
var coat_sign: int = NO_SIGN
var coat_mode: int = ScribeCardResource.ManifestationMode.WEAPON_COAT
var coat_time_left: float = 0.0
var coat_synergy: Dictionary = {}
## Seconds the Flow-Link Window stays open.
var flow_window_left: float = 0.0

## The Ward Blessing: seconds left once a fight starts (it waits, full, until then), and the foe it's turned toward.
var ward_blessing_left: float = 0.0
var ward_attuned_id: StringName = &""
## A Support's Aegis Ward: the next stun or knockdown is shrugged off.
var aegis_ward: bool = false
## A Support's Ink-Share on this hero: the Sign, seconds left and who lent it.
var shared_party_sign_override: int = NO_SIGN
var ink_share_left: float = 0.0
var ink_share_from: StringName = &""
## The L+R playing now as a One-and-Done (null when none), and what it spends.
var one_and_done_action: CombatActionResource
var warded_hits: int = 0

var _one_and_done_sign: int = NO_SIGN
var _one_and_done_leaf: StringName = &""
var _one_and_dones: int = 0
var _shrug_until: float = -INF
var _warded_this_hit: bool = false
var _trail_synergy: Dictionary = {}
var _armed_command: int = -1
var _armed_left: float = 0.0
var _window_closed_at: float = -INF
var _guard_was: bool = false
var _casts: int = 0


func setup(owner_actor: ActorBase) -> void:
	actor = owner_actor
	name = "SignFlowComponent"


func _ready() -> void:
	actor.action_queue.action_started.connect(_on_action_started)
	actor.action_queue.flow_cancelled.connect(_on_flow_cancelled)
	actor.action_queue.action_finished.connect(_on_action_ended)
	actor.action_queue.action_interrupted.connect(_on_action_ended)
	if actor.input != null:
		actor.input.hearth_rite_held.connect(_on_hearth_rite_held)
	if actor.tether != null:
		actor.tether.tether_changed.connect(_on_tether_changed)


## Every physics tick on the hero's peer (ActorBase calls it after its stats).
func tick(delta: float) -> void:
	var was_in_combat: bool = is_in_combat
	is_in_combat = _scan_for_combat()
	if is_in_combat and not was_in_combat and has_hearth_rite_tuck:
		trail_coat_timer = TRAIL_COAT_COMBAT_GRACE
	if has_hearth_rite_tuck and is_in_combat:
		trail_coat_timer -= delta
		if trail_coat_timer <= 0.0:
			_end_tuck()
	if ward_blessing_left > 0.0 and is_in_combat:
		ward_blessing_left = maxf(0.0, ward_blessing_left - delta)
	if ink_share_left > 0.0:
		ink_share_left -= delta
		if ink_share_left <= 0.0:
			_end_ink_share()
	if coat_time_left > 0.0:
		coat_time_left -= delta
		if coat_time_left <= 0.0:
			_clear_coat()
	if flow_window_left > 0.0:
		flow_window_left -= delta
		if flow_window_left <= 0.0:
			_window_closed_at = CombatDirector.game_time()
	_armed_left = maxf(0.0, _armed_left - delta)
	# L tapped in the window: a Counter-Brace (the guard still goes up, as L is held).
	var guarding: bool = actor.wants_guard
	if guarding and not _guard_was and is_in_combat and _window_is_open(GUARD_TAP_GRACE):
		counter_brace()
	_guard_was = guarding


# --- What's slotted ----------------------------------------------------------

## The diorama in a socket (ArsenalCatalog.compute_diorama_synergy of its leaf and Place-Card).
func socket_synergy(socket: int) -> Dictionary:
	var kit: EquipmentLoadoutResource = actor.loadout.kit
	if kit == null:
		return ArsenalCatalog.current.compute_diorama_synergy(&"", &"")
	return ArsenalCatalog.current.compute_diorama_synergy(kit.socket_leaf_id(socket), kit.place_ids[socket],
		kit.socket_leaf_variant(socket), kit.socket_place_variant(socket))


## How long R or L+R must be held for the Hearth-Rite Tuck: 120 frames, 80 on a Star-Inked Vellum leaf.
func hearth_rite_hold_frames(socket: int) -> int:
	var kit: EquipmentLoadoutResource = actor.loadout.kit
	if kit != null and kit.socket_leaf_variant(socket) == ScribeCardResource.CardVariant.STAR_INKED_VELLUM:
		return STAR_INKED_HOLD_FRAMES
	return HEARTH_RITE_HOLD_FRAMES


func hearth_rite_hold_seconds(socket: int) -> float:
	return hearth_rite_hold_frames(socket) / FRAMES_PER_SECOND


## Whether holding R or L+R now would start the Hearth-Rite.
func can_prepare() -> bool:
	return enabled and not is_in_combat and not actor.stats.is_downed


## The window this hero's hits open now, in frames (Dread-Chill alone, The
## Lantern's Promise near a Lantern-Bearer or held on one's Soul Tether).
func flow_window_frames() -> int:
	for member: ActorBase in CombatDirector.current.alive_party():
		if member.role() != ClassLoadoutResource.Role.HEALER:
			continue
		var tethered: bool = member != actor and member.tether != null and member.tether.tethered_id == actor.player_id
		if tethered or member.global_position.distance_to(actor.global_position) <= LANTERNS_PROMISE_RADIUS:
			return LANTERNS_PROMISE_WINDOW_FRAMES
	if CombatDirector.current.alive_party().size() <= 1:
		return DREAD_CHILL_WINDOW_FRAMES
	return FLOW_WINDOW_FRAMES


## How much further strikes reach while coated (a Place-Card's bonus, e.g. the Gorge Bridge's 0.8 m).
## Another peer's check of the hit allows it within its 3 m of slack.
func coat_reach_bonus() -> float:
	if not enabled or coat_time_left <= 0.0:
		return 0.0
	return coat_synergy.get("bonus_reach_m", 0.0)


func is_flow_window_open() -> bool:
	return flow_window_left > 0.0


func sign_flow_casts() -> int:
	return _casts


# --- State 1: the Hearth-Rite Tuck --------------------------------------

## Out of combat, for free: at least one pip, the 1.35x glow, and an empowered
## opening strike from this socket's diorama. Returns whether it took.
func begin_hearth_rite(socket: int) -> bool:
	if not can_prepare():
		return false
	var synergy: Dictionary = socket_synergy(socket)
	var stats: StatsComponent = actor.stats
	stats.resonance_charge = maxf(stats.resonance_charge, HEARTH_RITE_PIPS)
	stats.resonance_changed.emit(stats.resonance_pips(), stats.resonance_charge)
	_trail_synergy = synergy
	has_hearth_rite_tuck = true
	opening_strike_empowered = true
	active_socket = socket
	active_trail_coat_sign = synergy["scribe_sign"]
	active_location_card_id = synergy["location_card_id"]
	active_action_card_id = synergy["action_card_id"]
	trail_coat_timer = TRAIL_COAT_COMBAT_GRACE
	ward_blessing_left = TRAIL_COAT_COMBAT_GRACE
	ward_attuned_id = &""
	# The Overhead Pocket Blessing plays first; the steady 1.35x glow follows it.
	CombatDirector.current.show_sign_coat(actor, CoatLook.BLESSING, active_trail_coat_sign, synergy["manifestation_mode"],
		active_location_card_id, 0.0)
	CombatDirector.current.show_sign_coat(actor, CoatLook.TRAIL_TUCK, active_trail_coat_sign, synergy["manifestation_mode"],
		active_location_card_id, 0.0)
	var label: String = "INK READY"
	if active_trail_coat_sign != NO_SIGN:
		label += ": %s" % ArsenalCatalog.current.sign_seal(active_trail_coat_sign).display_name.to_upper()
	CombatDirector.current.show_float_text(actor.global_position + Vector3.UP * (actor.body_height() + 0.6), label,
		synergy["ambient_color"], 34)
	AudioCues.play(&"card_chime")
	hearth_rite_prepared.emit(socket)
	return true


## The opening strike of a fight carries the blessing: its Sign (and seal) and the Place-Card's strength.
func _discharge_into(event: CombatEvent) -> void:
	var synergy: Dictionary = _trail_synergy
	event.coat_sign = active_trail_coat_sign
	event.coat_poise = synergy.get("bonus_poise", 0.0)
	event.coat_primes = active_trail_coat_sign != NO_SIGN
	_lend_place(synergy)
	var discharged: int = active_trail_coat_sign
	_end_tuck()
	if discharged != NO_SIGN:
		CombatDirector.current.announce(actor.global_position + Vector3.UP * (actor.body_height() + 0.8), "OPENING STRIKE!",
			ArsenalCatalog.current.sign_seal(discharged).color)
	opening_strike_discharged.emit(discharged)


func _end_tuck() -> void:
	has_hearth_rite_tuck = false
	opening_strike_empowered = false
	active_trail_coat_sign = NO_SIGN
	active_location_card_id = &""
	active_action_card_id = &""
	active_socket = -1
	trail_coat_timer = 0.0
	_trail_synergy = {}
	if coat_time_left <= 0.0:
		CombatDirector.current.show_sign_coat(actor, CoatLook.CLEAR, NO_SIGN, 0, &"", 0.0)


# --- State 2: Sign-Flow in combat ------------------------------------------------

## The hero's strike is about to land (CombatDirector.report_hit, on this peer):
## a physical hit opens the Flow-Link Window, the opening strike discharges the
## Hearth-Rite, and a coat lends its Sign and poise.
func on_strike_landed(action: CombatActionResource, event: CombatEvent) -> void:
	if not enabled:
		return
	var physical: bool = PHYSICAL_COMMANDS.has(action.command)
	if is_in_combat and physical:
		flow_window_left = flow_window_frames() / FRAMES_PER_SECOND
	if action == one_and_done_action:
		event.one_and_done = true
		event.finisher_card_id = _one_and_done_leaf
		event.coat_sign = _one_and_done_sign
		event.coat_poise = 0.0
		return
	if opening_strike_empowered and is_in_combat:
		_discharge_into(event)
	elif coat_time_left > 0.0 and coat_sign != NO_SIGN:
		event.coat_sign = coat_sign
		event.coat_poise = coat_synergy.get("bonus_poise", 0.0)
	elif ink_share_left > 0.0 and shared_party_sign_override != NO_SIGN and physical:
		# A Support's Ink-Share: this physical blow strikes in their Sign.
		event.coat_sign = shared_party_sign_override
		event.coat_poise = 0.0
		event.ink_share_from = ink_share_from


## L tapped in the Flow-Link Window: a Counter-Brace from the L socket (1 pip). Returns whether it went.
func counter_brace() -> bool:
	var kit: EquipmentLoadoutResource = actor.loadout.kit
	if not enabled or kit == null or kit.guard_leaf_id == &"":
		return false
	var cost: float = ScribeCardResource.SOCKET_PIP_COSTS[Socket.GUARD]
	if actor.stats.uses_ink_well():
		cost = float(GrimoireRules.ink_cost(GrimoireRules.SOCKET_L, ArsenalCatalog.current.card(kit.guard_leaf_id), false))
	if actor.stats.resonance_charge < cost:
		return false
	actor.stats.add_resonance(-cost)
	flow_window_left = 0.0
	_cast(Socket.GUARD)
	return true


## A command the hero's controller just issued (ActorBase calls this before
## queueing it): R or L+R pressed in the window will cast as Sign-Flow.
func note_command(command: int) -> void:
	if enabled and is_in_combat and _window_is_open(0.0):
		arm(command)


## The next R or L+R to start casts as Sign-Flow (a press in the window, or a Squire's buffered counter).
func arm(command: int) -> void:
	if command == CombatActionResource.Command.TRIGGER_R_SKILL or command == CombatActionResource.Command.TRIGGER_BOTH_ULT:
		_armed_command = command
		_armed_left = ARMED_PRESS_TIME


## An R or L+R pressed in the window starts: no wind-up, and the socket's
## diorama coats the hero. An L+R while a Weapon-Coat burns is a One-and-Done
## instead; a Support's Ink-Share leaf lends its Sign; a Green Sanctuary wards.
func _on_action_started(action: CombatActionResource, _flowed: bool) -> void:
	if not enabled:
		return
	if action.command == CombatActionResource.Command.TRIGGER_BOTH_ULT and _can_one_and_done(action):
		_begin_one_and_done(action)
		return
	_share_ink_from(action)
	if action.effect == CombatActionResource.Effect.GREEN_SANCTUARY:
		for member: ActorBase in CombatDirector.current.alive_party():
			if member != actor and member.global_position.distance_to(actor.global_position) <= SANCTUARY_AEGIS_RADIUS:
				CombatDirector.current.grant_aegis_ward(actor, member)
	if _armed_left <= 0.0 or action.command != _armed_command:
		return
	_armed_left = 0.0
	_armed_command = -1
	flow_window_left = 0.0
	# 0-frame cast wait: the queue goes straight to the active frames on its next tick.
	actor.action_queue.phase_time = action.windup_time
	_cast(Socket.SKILL if action.command == CombatActionResource.Command.TRIGGER_R_SKILL else Socket.ULT)


## A Flow-Link cancel while coated gives back the Place-Card's stamina (Star-Spark).
func _on_flow_cancelled(_from: CombatActionResource, _to: CombatActionResource) -> void:
	if coat_time_left > 0.0:
		actor.stats.restore_stamina(coat_synergy.get("stamina_refund", 0.0))


func _on_action_ended(action: CombatActionResource) -> void:
	if action != null and action == one_and_done_action:
		one_and_done_action = null


func _on_hearth_rite_held(command: int) -> void:
	begin_hearth_rite(Socket.ULT if command == CombatActionResource.Command.TRIGGER_BOTH_ULT else Socket.SKILL)


## The Sign-Flow cast itself: the flare, the freeze, the ring and the coat.
func _cast(socket: int) -> void:
	var synergy: Dictionary = socket_synergy(socket)
	var scribe_sign: int = synergy["scribe_sign"]
	var mode: int = synergy["manifestation_mode"]
	_casts += 1
	var director: CombatDirector = CombatDirector.current
	var frozen: Array[ActorBase] = []
	for enemy: ActorBase in director.enemies():
		if enemy.is_targetable() and enemy.global_position.distance_to(actor.global_position) <= SIGN_RING_RADIUS + enemy.body_radius():
			frozen.append(enemy)
	director.request_hit_stop(frozen, SIGN_FLOW_HIT_STOP / CombatDirector.BASE_HIT_STOP)
	director.stamp_sign_ring(actor, scribe_sign, SIGN_RING_RADIUS)
	coat_synergy = synergy
	coat_sign = scribe_sign
	coat_mode = mode
	coat_time_left = synergy["coat_duration_sec"]
	director.show_sign_coat(actor, CoatLook.FLARE, scribe_sign, mode, synergy["location_card_id"], SIGN_FLOW_FLARE_TIME)
	director.show_sign_coat(actor, CoatLook.COAT, scribe_sign, mode, synergy["location_card_id"], coat_time_left)
	match mode:
		ScribeCardResource.ManifestationMode.WARD_MANTLE:
			director.spawn_shelter(actor, WARD_MANTLE_CONE_RADIUS, WARD_MANTLE_CONE_TIME)
		ScribeCardResource.ManifestationMode.LANTERN_TETHER:
			var held: ActorBase = actor.tether.tethered_actor() if actor.tether != null else actor.most_hurt_ally(1.01)
			if held != null:
				director.apply_heal(actor, held, LANTERN_TETHER_HEAL)
	_lend_place(synergy)
	var label: String = "%s!" % ScribeCardResource.MODE_NAMES[mode].to_upper()
	if synergy["is_home_ground_harmony"]:
		label += "  HOME-GROUND"
	director.show_float_text(actor.global_position + Vector3.UP * (actor.body_height() + 0.5), label, synergy["ink_color"], 34)
	sign_flow_cast.emit(socket, scribe_sign)


# --- Role asymmetry (14 GDD §8) ------------------------------------------------

## DPS: L+R with a live Weapon-Coat of a Sign, and 3 pips between what it costs and what's left.
func _can_one_and_done(action: CombatActionResource) -> bool:
	return is_in_combat and coat_time_left > 0.0 and coat_sign != NO_SIGN \
		and coat_mode == ScribeCardResource.ManifestationMode.WEAPON_COAT and action.effect == CombatActionResource.Effect.STRIKE \
		and actor.stats.resonance_charge + action.resonance_cost >= ONE_AND_DONE_PIPS - 0.001


## The coat is spent on the Seal-Breaker: every pip it takes, and the L+R's strikes carry it.
func _begin_one_and_done(action: CombatActionResource) -> void:
	var short: float = ONE_AND_DONE_PIPS - float(action.resonance_cost)
	if short > 0.0:
		actor.stats.add_resonance(-short)
	one_and_done_action = action
	_one_and_done_sign = coat_sign
	_one_and_done_leaf = coat_synergy.get("action_card_id", &"")
	_one_and_dones += 1
	if _armed_left > 0.0 and _armed_command == action.command:
		# Pressed in the window: no wind-up either.
		actor.action_queue.phase_time = action.windup_time
	_armed_left = 0.0
	_armed_command = -1
	flow_window_left = 0.0
	var spent: int = _one_and_done_sign
	_clear_coat()
	var director: CombatDirector = CombatDirector.current
	director.show_sign_coat(actor, CoatLook.FLARE, spent, ScribeCardResource.ManifestationMode.WEAPON_COAT, &"", SIGN_FLOW_FLARE_TIME)
	director.show_float_text(actor.global_position + Vector3.UP * (actor.body_height() + 0.5), "ONE-AND-DONE!",
		ArsenalCatalog.current.sign_seal(spent).color, 38)
	one_and_done_unleashed.emit(spent)


func one_and_dones() -> int:
	return _one_and_dones


## Support: an R or L+R card that shares its ink lends its Sign to the party.
func _share_ink_from(action: CombatActionResource) -> void:
	if not is_in_combat or not action.is_card() or not action.is_skill():
		return
	var leaf: ScribeCardResource = ArsenalCatalog.current.card(action.card_id)
	if leaf == null or not leaf.shares_ink() or leaf.scribe_sign == NO_SIGN:
		return
	CombatDirector.current.share_ink(actor, leaf.scribe_sign, INK_SHARE_TIME, INK_SHARE_RADIUS)
	ink_shared.emit(leaf.scribe_sign)


## Support: binding the Soul Tether wards the ally it now holds (their next stun is shrugged off).
func _on_tether_changed(player_id: StringName) -> void:
	var held: ActorBase = CombatDirector.current.get_actor(player_id)
	if enabled and held != null and held != actor:
		CombatDirector.current.grant_aegis_ward(actor, held)


## On this hero's peer: a Support's Ink-Share. Physical blows strike in `scribe_sign` for `seconds`.
func receive_ink_share(scribe_sign: int, seconds: float, from_id: StringName) -> void:
	shared_party_sign_override = scribe_sign
	ink_share_left = seconds
	ink_share_from = from_id
	if coat_time_left <= 0.0 and not has_hearth_rite_tuck:
		CombatDirector.current.show_sign_coat(actor, CoatLook.COAT, scribe_sign, ScribeCardResource.ManifestationMode.WEAPON_COAT, &"", seconds)


func _end_ink_share() -> void:
	ink_share_left = 0.0
	shared_party_sign_override = NO_SIGN
	ink_share_from = &""
	if coat_time_left <= 0.0 and not has_hearth_rite_tuck:
		CombatDirector.current.show_sign_coat(actor, CoatLook.CLEAR, NO_SIGN, 0, &"", 0.0)


## On this hero's peer: a Support's Aegis Ward. The next stun or knockdown is shrugged off.
func receive_aegis_ward() -> void:
	if not aegis_ward:
		CombatDirector.current.show_float_text(actor.global_position + Vector3.UP * (actor.body_height() + 0.4), "BULWARK WARD",
			AEGIS_TEXT_COLOR, 26)
	aegis_ward = true


## A Ward-Mantle is on this hero now.
func is_mantled() -> bool:
	return enabled and coat_time_left > 0.0 and coat_mode == ScribeCardResource.ManifestationMode.WARD_MANTLE


## How much the Ward Blessing takes off the next foe's blows now (0 when it's spent).
func ward_blessing_mitigation() -> float:
	return WARD_BLESSING_MITIGATION if enabled and ward_blessing_left > 0.0 else 0.0


## A foe's blow on this hero, on its peer, before the guard maths (ActorBase.receive_strike):
## the Ward Blessing takes 15% off the first foe's blows, and a Ward-Mantle of the blow's Sign soaks 80%.
func filter_incoming(event: CombatEvent) -> void:
	_warded_this_hit = false
	if not enabled or event.kind != CombatEvent.Kind.STRIKE or event.unavoidable:
		return
	var attacker: ActorBase = actor.get_node_or_null(event.attacker_path) as ActorBase
	if attacker == null or not attacker.is_boss():
		return
	if ward_blessing_left > 0.0:
		if ward_attuned_id == &"":
			ward_attuned_id = attacker.player_id
		if ward_attuned_id == attacker.player_id:
			event.damage *= 1.0 - WARD_BLESSING_MITIGATION
	if is_mantled() and event.scribe_sign != NO_SIGN and event.scribe_sign == coat_sign:
		event.damage *= 1.0 - float(coat_synergy.get("ward_mitigation", 0.0))
		_ward(attacker)


## After the guard maths: a Perfect Guard of any Sign's blow under a Ward-Mantle wards it too.
func after_incoming(event: CombatEvent, outcome: int) -> void:
	if _warded_this_hit or not is_mantled() or event.scribe_sign == NO_SIGN or outcome != StatsComponent.StrikeOutcome.PERFECT_GUARD:
		return
	var attacker: ActorBase = actor.get_node_or_null(event.attacker_path) as ActorBase
	if attacker != null and attacker.is_boss():
		_ward(attacker)


## The Ward-Mantle holds: the stun is shrugged off, poise is thrown back, the shelter cone goes up.
func _ward(attacker: ActorBase) -> void:
	_warded_this_hit = true
	warded_hits += 1
	_shrug_until = CombatDirector.game_time() + WARD_SHRUG_GRACE
	var director: CombatDirector = CombatDirector.current
	director.reflect_poise(actor, attacker, float(coat_synergy.get("ward_reflected_poise", 0.0)))
	if not director.has_zone_from(actor.player_id):
		director.spawn_shelter(actor, WARD_MANTLE_CONE_RADIUS, WARD_MANTLE_CONE_TIME)
	director.show_float_text(actor.global_position + Vector3.UP * (actor.body_height() + 0.5), "INK SHIELD!",
		ArsenalCatalog.current.sign_seal(coat_sign).color, 30)
	ward_mantle_held.emit(attacker.player_id)


## Whether a stun or knockdown on this hero is shrugged off now: just after a
## warded blow, under a coat that grants stun immunity, or by spending an Aegis Ward.
func shrugs_off_stagger() -> bool:
	if not enabled:
		return false
	if CombatDirector.game_time() <= _shrug_until:
		return true
	if coat_time_left > 0.0 and bool(coat_synergy.get("grants_stun_immunity", false)):
		return true
	if aegis_ward:
		aegis_ward = false
		CombatDirector.current.show_float_text(actor.global_position + Vector3.UP * (actor.body_height() + 0.4), "BULWARK!",
			AEGIS_TEXT_COLOR, 30)
		aegis_ward_spent.emit()
		return true
	return false


## What a Place-Card gives the moment its diorama is cast: its warmth mends friends nearby.
func _lend_place(synergy: Dictionary) -> void:
	var warmth: float = synergy.get("bonus_heal", 0.0)
	if warmth <= 0.0:
		return
	for member: ActorBase in CombatDirector.current.alive_party():
		if member.global_position.distance_to(actor.global_position) <= PLACE_WARMTH_RADIUS:
			CombatDirector.current.apply_heal(actor, member, warmth)


## Puts this peer's puppet back to what Sign-Flow shows now (after a Scribery preview).
func restore_look() -> void:
	var director: CombatDirector = CombatDirector.current
	if has_hearth_rite_tuck:
		director.show_sign_coat_here(actor, CoatLook.TRAIL_TUCK, active_trail_coat_sign, _trail_synergy.get("manifestation_mode", 0),
			active_location_card_id, 0.0)
	elif coat_time_left > 0.0:
		director.show_sign_coat_here(actor, CoatLook.COAT, coat_sign, coat_mode, coat_synergy.get("location_card_id", &""), coat_time_left)
	else:
		director.show_sign_coat_here(actor, CoatLook.CLEAR, NO_SIGN, 0, &"", 0.0)


func _clear_coat() -> void:
	coat_time_left = 0.0
	coat_sign = NO_SIGN
	coat_synergy = {}
	if has_hearth_rite_tuck:
		CombatDirector.current.show_sign_coat(actor, CoatLook.TRAIL_TUCK, active_trail_coat_sign, _trail_synergy.get("manifestation_mode", 0),
			active_location_card_id, 0.0)
	elif ink_share_left > 0.0:
		CombatDirector.current.show_sign_coat(actor, CoatLook.COAT, shared_party_sign_override, ScribeCardResource.ManifestationMode.WEAPON_COAT,
			&"", ink_share_left)
	else:
		CombatDirector.current.show_sign_coat(actor, CoatLook.CLEAR, NO_SIGN, 0, &"", 0.0)


## The window is open now, or closed no more than `grace` seconds ago.
func _window_is_open(grace: float) -> bool:
	return flow_window_left > 0.0 or CombatDirector.game_time() - _window_closed_at <= grace


## In combat while an engaged foe stands within COMBAT_RADIUS.
func _scan_for_combat() -> bool:
	if actor.stats.is_downed:
		return false
	for enemy: ActorBase in CombatDirector.current.enemies():
		if enemy.is_engaged() and enemy.is_targetable() and enemy.global_position.distance_to(actor.global_position) <= COMBAT_RADIUS:
			return true
	return false
