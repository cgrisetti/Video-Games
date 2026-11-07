## The Seal-and-Tuck Grimoire on a hero (docs/everwood_equipment_grimoire_architecture.md
## Part II §4-§6.7): the doc's player combat controller, as a component beside
## SignFlowComponent and ComboChainComponent (composition over inheritance).
##
## It keeps the hero's PlayerLoadoutResource: the material tier its True Level
## forged, its youth silhouette, and the 7-Card Hand (3 seals pressed onto the
## gear, 4 invocations on L, R and L+R). Until the Binder has a stamping bench
## the hand is the role's default, trimmed to what the progression stage has
## opened (ArsenalCatalog.default_seal_loadout); set_loadout takes a chosen one.
##
## What it does in play, every peer reading the same ids:
## - Passive seals: a Weapon Seal adds its flat bonus to every strike and its
##   posture multiplier; a seal of the blow's Sign takes its ward off the blow
##   (filter_incoming) and shrugs the stun off (shrugs_off_stagger); a stride
##   seal quickens the hero (move_speed_mult).
## - The Pocket-Pull: a landed physical hit opens an 18-frame (0.30 s) window.
##   An L, R or L+R Sign-Flow cast in it pulls the slot's seal card from the
##   pouch (the flourish on every peer through trigger_pocket_pull_rpc), coats
##   the hero's strikes in the card's multiplier for its duration, and lands its
##   posture burst on the first blow. try_trigger_pocket_pull_invocation is
##   the same thing by hand (the Squire Gambit and the checks); the L+R Grand
##   Invocation and the Under-Card Tucks wait for their stage.
## - The Graduated APM gate: which directional postures a stage allows
##   (is_directional_attack_unlocked). The shipped trail hands out Forward and
##   Back cards at Level 1 (11 GDD §5.2), so the posture gate is a switch
##   (graduated_apm_enabled, off by default); the slot gates are always on.
## - The 1-Button Gambit Assist: a Squire's button fires the pull when the
##   window is open and the pips are there, and the pull fires by itself when
##   the pips are full (execute_one_button_gambit).
##
## Network (Gate 4): sync_loadout_rpc carries the hand as Strings and ints;
## trigger_pocket_pull_rpc carries a card id and two ints. Each peer derives the
## same default hand from the roster and the party's level, so a late copy
## looks right before the first message lands.
class_name EquipmentSealComponent
extends Node

signal loadout_changed(loadout: PlayerLoadoutResource)
signal pocket_pull_invoked(card_id: StringName, trigger_slot: int, has_tuck: bool)
signal pocket_pull_refused(trigger_slot: int, reason: String)

## The directional postures the Graduated APM ladder gates (§6.7).
enum DirectionalAttack { NEUTRAL_LIGHT = 0, NEUTRAL_HEAVY = 1, FORWARD_HEAVY_LUNGE = 2, BACK_HEAVY_EVADE = 3, SIDE_LIGHT_FLANK = 4 }

## The smoke test's older checks switch the live seals off (like SignFlowComponent.enabled);
## the seal checks switch them on. Off, nothing here changes a number, a look or a window.
static var enabled: bool = true
## The posture gate: Forward+Heavy and Back+Heavy from Stage 2, the sideways flank from Stage 3.
## Off by default, because the trail hands out the Forward and Back cards at Level 1.
static var graduated_apm_enabled: bool = false

## The Pocket-Pull's Flow-Link window: 18 frames at 60 fps.
const FLOW_LINK_WINDOW_SEC: float = 0.30
const FLOW_LINK_WINDOW_FRAMES: int = 18
## The first blow within this long of a pull carries its posture burst.
const BURST_GRACE_SEC: float = 0.6
## A warded blow's stun, which lands a moment after it, is shrugged off for this long.
const SHRUG_GRACE_SEC: float = 0.3
## The stages that open the Under-Card Tucks and the L+R Grand Invocation.
const TUCK_STAGE: int = PlayerLoadoutResource.STAGE_CONVERGENCE
const GRAND_INVOCATION_STAGE: int = PlayerLoadoutResource.STAGE_APEX
const REASON_NO_WINDOW: String = "NO_FLOW_LINK_OR_PIPS"
const REASON_EMPTY: String = "EMPTY_SLOT"
const REASON_PIPS: String = "INSUFFICIENT_PIPS"
const REASON_LOCKED: String = "SLOT_LOCKED"
const REASON_DISABLED: String = "SEALS_DISABLED"
const GAMBIT_ACTION: StringName = &"ACTION_GAMBIT_STRIKE"
const PULL_TEXT_SIZE: int = 28
## Which trigger each Sign-Flow socket pulls from (ScribeCardResource.DioramaSocket order: L Guard, R Skill, L+R Ult).
const SOCKET_TRIGGERS: Array[int] = [PlayerLoadoutResource.TriggerSlot.L, PlayerLoadoutResource.TriggerSlot.R, PlayerLoadoutResource.TriggerSlot.L_AND_R]

var actor: ActorBase
## The hand: tier, silhouette, 3 seals and 4 invocations.
var loadout: PlayerLoadoutResource
## Where on the ladder the hero plays (1 to 4), from its True Level (or debug_stage_override).
var progression_stage: int = PlayerLoadoutResource.STAGE_HOMESTEAD
var true_level: int = 1
## A playtest's stage, forcing the ladder (0: from the level).
var debug_stage_override: int = 0
## A Squire Gambit's button and auto-fire are routed here (ActorBase.apply_assist_mode).
var input_gambit_assist: bool = false
## Seconds the Pocket-Pull window has left.
var flow_link_timer: float = 0.0
## The coat a pull left on the hero's strikes: its card, its tuck, and the seconds and burst it has left.
var active_card_id: StringName = &""
var active_tuck: bool = false
var active_left: float = 0.0
var burst_left: float = 0.0
## What the last pull (or refusal) returned, for the HUD and the checks.
var last_invocation: Dictionary = {}

var _custom_hand: bool = false
var _received_from_owner: bool = false
var _shrug_until: float = -INF
var _window_fired: bool = false
var _invocations: int = 0
var _refusals: int = 0
var _warded_blows: int = 0


func setup(owner_actor: ActorBase) -> void:
	actor = owner_actor
	name = "EquipmentSealComponent"


func _ready() -> void:
	if actor.sign_flow != null:
		actor.sign_flow.sign_flow_cast.connect(_on_sign_flow_cast)
	var progress: PartyProgress = PartyProgress.current
	if progress != null:
		progress.progress_changed.connect(_on_progress_changed)
		progress.trail_level_reached.connect(_on_trail_level_reached)
	_derive_hand()
	# The actor's authority is set once its components are built; the first broadcast waits for it.
	_broadcast_loadout.call_deferred()


func _exit_tree() -> void:
	var progress: PartyProgress = PartyProgress.current
	if progress == null:
		return
	if progress.progress_changed.is_connected(_on_progress_changed):
		progress.progress_changed.disconnect(_on_progress_changed)
	if progress.trail_level_reached.is_connected(_on_trail_level_reached):
		progress.trail_level_reached.disconnect(_on_trail_level_reached)


## Every physics tick on the hero's peer (ActorBase calls it after the combo forms).
func tick(delta: float) -> void:
	if flow_link_timer > 0.0:
		flow_link_timer = maxf(0.0, flow_link_timer - delta)
	if active_left > 0.0:
		active_left -= delta
		if active_left <= 0.0:
			_end_coat()
	burst_left = maxf(0.0, burst_left - delta)
	# The Gambit Assist: with the pips full and the window open, the pull fires by itself.
	if enabled and input_gambit_assist and is_flow_window_open() and not _window_fired and actor.stats != null \
			and actor.stats.resonance_pips() >= actor.stats.stats.max_resonance_pips:
		var assist: Dictionary = execute_one_button_gambit()
		var command: int = int(assist.get("command", -1))
		if command >= 0 and actor.input != null:
			actor.input.command_issued.emit(command)


# --- The hand --------------------------------------------------------------------

## Works the hand out again (a new kit, a new level) and shows it: the role's
## default by stage, or a chosen hand trimmed to the stage. Broadcasts it.
func refresh() -> void:
	_derive_hand()
	_broadcast_loadout()


## A hand the hero chose (the Binder's bench, a playtest): trimmed to the stage, shown and broadcast.
func set_loadout(chosen: PlayerLoadoutResource) -> void:
	loadout = chosen.copy() if chosen != null else null
	_custom_hand = loadout != null
	_received_from_owner = false
	_derive_hand()
	_broadcast_loadout()


## Returns the hand to its role's default by stage.
func clear_custom_loadout() -> void:
	_custom_hand = false
	refresh()


## Dresses the hero's puppet in the hand: the youth silhouette, the tier and the seals.
func apply_visuals() -> void:
	if not enabled or loadout == null or actor == null or actor.visuals == null or not actor.visuals.has_rig():
		return
	actor.visuals.apply_wingfeather_youth_proportions(loadout.body_type)
	actor.visuals.apply_equipment_tier_and_seals(ArsenalCatalog.current, loadout)


## The hero's Renown Rank (the banner's readout of its True Level).
func renown_rank() -> int:
	return ArsenalCatalog.compute_renown_from_true_level(true_level)


## The tier the hero wears, or null.
func tier() -> EquipmentTierResource:
	return ArsenalCatalog.current.get_tier(loadout.equipped_tier_id) if loadout != null else null


func _derive_hand() -> void:
	true_level = clampi(PartyProgress.current.trail_level() if PartyProgress.current != null else 1, 1, ArsenalCatalog.MAX_TRUE_LEVEL)
	progression_stage = debug_stage_override if debug_stage_override > 0 else PlayerLoadoutResource.stage_for_true_level(true_level)
	if _received_from_owner and loadout != null:
		apply_visuals()
		loadout_changed.emit(loadout)
		return
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	if _custom_hand and loadout != null:
		loadout.trim_to_stage(progression_stage, true_level)
	else:
		var compiled: ClassLoadoutResource = actor.loadout
		var weapon_type: int = compiled.weapon.weapon_type if compiled.weapon != null else EquipmentItemResource.WeaponType.LIGHT_SWORD
		var calling: CallingResource = Callings.calling(compiled.class_id, compiled.calling)
		var calling_id: StringName = calling.calling_id if calling != null else compiled.class_id
		var kept_body: int = loadout.body_type if loadout != null else -1
		loadout = catalog.default_seal_loadout(compiled.class_id, actor.role(), weapon_type, calling_id, true_level, actor.party_slot, debug_stage_override)
		if kept_body >= 0:
			loadout.body_type = kept_body as PlayerLoadoutResource.YouthBodyType
	apply_visuals()
	loadout_changed.emit(loadout)


func _on_progress_changed() -> void:
	if is_instance_valid(actor):
		refresh()


func _on_trail_level_reached(_level: int) -> void:
	if is_instance_valid(actor):
		refresh()


# --- The Graduated APM gate (§5.2, §6.7) -----------------------------------------------

## Whether a directional posture is open at the hero's stage: the lunge and the
## evade from Stage 2, the sideways flank from Stage 3 (always, with the gate off).
func is_directional_attack_unlocked(attack: DirectionalAttack) -> bool:
	if not graduated_apm_enabled or not enabled:
		return true
	match attack:
		DirectionalAttack.NEUTRAL_LIGHT, DirectionalAttack.NEUTRAL_HEAVY:
			return true
		DirectionalAttack.FORWARD_HEAVY_LUNGE, DirectionalAttack.BACK_HEAVY_EVADE:
			return progression_stage >= PlayerLoadoutResource.STAGE_FIRST_FRICTION
		DirectionalAttack.SIDE_LIGHT_FLANK:
			return progression_stage >= PlayerLoadoutResource.STAGE_CONVERGENCE
	return false


## A pressed posture, as the gate lets it through: a locked Forward or Back heavy falls back to the plain heavy.
func gate_command(command: int) -> int:
	match command:
		CombatActionResource.Command.FORWARD_HEAVY:
			return command if is_directional_attack_unlocked(DirectionalAttack.FORWARD_HEAVY_LUNGE) else CombatActionResource.Command.HEAVY
		CombatActionResource.Command.BACK_HEAVY:
			return command if is_directional_attack_unlocked(DirectionalAttack.BACK_HEAVY_EVADE) else CombatActionResource.Command.HEAVY
	return command


## Whether a trigger pulls at the hero's stage: L from Stage 1, R from Stage 2, L+R from Stage 4.
func is_trigger_slot_unlocked(trigger_slot: int) -> bool:
	return PlayerLoadoutResource.trigger_open_at_stage(trigger_slot, progression_stage)


func tucks_unlocked() -> bool:
	return progression_stage >= TUCK_STAGE


## The seal card a trigger would pull, or null.
func card_for_trigger(trigger_slot: int) -> ScribeCardResource:
	if loadout == null:
		return null
	var card: ScribeCardResource = ArsenalCatalog.current.get_card(loadout.primary_for_trigger(trigger_slot))
	return card if card != null and card.is_seal_card() else null


# --- Passive seals (§4.1) ---------------------------------------------------------------

## How much the stamped seals take off a blow of `incoming_sign` (&"SIGN_STAR_TIDE"), together, up to the cap.
func get_passive_ward_mitigation(incoming_sign: StringName) -> float:
	if not enabled or loadout == null:
		return 0.0
	var ward: float = 0.0
	for seal_id: StringName in loadout.seal_card_ids():
		var seal_card: ScribeCardResource = ArsenalCatalog.current.get_card(seal_id)
		if seal_card != null and seal_card.wards_against(incoming_sign):
			ward += seal_card.passive_ward_mitigation
	return clampf(ward, 0.0, ArsenalCatalog.WARD_CAP)


## Whether a stamped seal shrugs off the stun of a blow of `incoming_sign`.
func grants_stun_immunity_against(incoming_sign: StringName) -> bool:
	if not enabled or loadout == null:
		return false
	for seal_id: StringName in loadout.seal_card_ids():
		var seal_card: ScribeCardResource = ArsenalCatalog.current.get_card(seal_id)
		if seal_card != null and seal_card.wards_against(incoming_sign) and seal_card.grants_sign_stun_immunity:
			return true
	return false


## The doc's full reckoning of a foe's blow: the tier's armour for the hand's weight class, the
## seals' wards against its Sign and whether one shrugs the stun off (ArsenalCatalog.evaluate_incoming_hit).
func evaluate_incoming_hit(catalog: ArsenalCatalog, raw_damage: int, incoming_sign: StringName) -> Dictionary:
	return catalog.evaluate_incoming_hit(loadout, raw_damage, incoming_sign)


## A Weapon Seal's flat bonus on every strike.
func passive_flat_damage_bonus() -> int:
	if not enabled or loadout == null:
		return 0
	var weapon_seal: ScribeCardResource = ArsenalCatalog.current.get_card(loadout.weapon_seal_card_id)
	return weapon_seal.passive_flat_damage_bonus if weapon_seal != null else 0


## The strongest posture-break multiplier among the seals.
func passive_posture_break_mult() -> float:
	if not enabled or loadout == null:
		return 1.0
	return ArsenalCatalog.current.posture_break_mult_of(loadout)


## The longest stride among the seals (a Rime-Gale swiftness seal on the mantle: 1.15x).
func move_speed_mult() -> float:
	if not enabled or loadout == null:
		return 1.0
	var mult: float = 1.0
	for seal_id: StringName in loadout.seal_card_ids():
		var seal_card: ScribeCardResource = ArsenalCatalog.current.get_card(seal_id)
		if seal_card != null:
			mult = maxf(mult, seal_card.passive_move_speed_mult)
	return mult


## A foe's blow on this hero, on its peer, before the guard maths (ActorBase.receive_strike):
## a seal of the blow's Sign takes its ward off and shrugs the stun that follows.
func filter_incoming(event: CombatEvent) -> void:
	if not enabled or loadout == null or event.kind != CombatEvent.Kind.STRIKE:
		return
	var incoming: int = event.counter_sign()
	if incoming == ScribeSignResource.Sign.NONE:
		return
	var sign_id: StringName = ScribeSignResource.id_of(incoming)
	var ward: float = get_passive_ward_mitigation(sign_id)
	if ward > 0.0:
		event.damage *= 1.0 - ward
		_warded_blows += 1
	if grants_stun_immunity_against(sign_id):
		_shrug_until = CombatDirector.game_time() + SHRUG_GRACE_SEC


## Whether a stun or shove on this hero is shrugged off now (just after a warded blow of a sealed Sign).
func shrugs_off_stagger() -> bool:
	return enabled and CombatDirector.game_time() <= _shrug_until


## Blows a seal's ward has softened on this hero.
func warded_blows() -> int:
	return _warded_blows


# --- The Pocket-Pull (§4.2, §6.7) --------------------------------------------------------

## The hero's strike is about to land (CombatDirector.report_hit, on this peer): a physical hit opens
## the Pocket-Pull window, and a live coat marks the strike with its card (and its first blow's burst).
func on_strike_landed(action: CombatActionResource, event: CombatEvent) -> void:
	if not enabled:
		return
	var in_combat: bool = actor.sign_flow.is_in_combat if actor.sign_flow != null else true
	if in_combat and SignFlowComponent.PHYSICAL_COMMANDS.has(action.command):
		flow_link_timer = FLOW_LINK_WINDOW_SEC
		_window_fired = false
	if active_left > 0.0 and active_card_id != &"":
		event.seal_card_id = active_card_id
		event.seal_tuck = active_tuck
		event.seal_burst = burst_left > 0.0
		burst_left = 0.0


## What this hero's seals do to a strike it threw, on the foe's owner (CombatDirector._apply_strike):
## the Weapon Seal's flat bonus and posture multiplier, and a live pull's coat (1.2x more under a
## tuck), with its posture burst on the first blow. Everything is read from ids every peer holds.
func shape_outgoing(event: CombatEvent) -> void:
	if not enabled or loadout == null or event.kind != CombatEvent.Kind.STRIKE:
		return
	if event.damage > 0.0:
		event.damage += float(passive_flat_damage_bonus())
	event.poise_damage *= passive_posture_break_mult()
	if event.seal_card_id == &"" or not loadout.has_active_card(event.seal_card_id):
		return
	var card: ScribeCardResource = ArsenalCatalog.current.get_card(event.seal_card_id)
	if card == null or not card.is_seal_card():
		return
	event.damage *= card.active_damage_mult
	if event.seal_tuck:
		event.damage *= ScribeCardResource.TUCK_SYNERGY_DAMAGE_MULT
	if event.seal_burst:
		event.poise_damage += card.active_posture_damage_bonus * (ScribeCardResource.TUCK_SYNERGY_POSTURE_MULT if event.seal_tuck else 1.0)


func is_flow_window_open() -> bool:
	return flow_link_timer > 0.0


## A coat from a pull is on the hero's strikes right now.
func is_coated() -> bool:
	return active_left > 0.0 and active_card_id != &""


## Pulls the card in a trigger's slot by hand (the doc's controller call): it needs the
## 18-frame window open, the pips for the card and the slot open at this stage. Spends
## the pips, plays the flourish on every peer, coats the hero's strikes and returns
## what the pull did ({"success", "card_id", "action_id", "damage", "posture_damage",
## "manifestation_mode", "has_tuck", "trigger_slot"}, or {"success": false, "reason"}).
func try_trigger_pocket_pull_invocation(trigger_slot: int) -> Dictionary:
	if not enabled or loadout == null:
		return _refuse(trigger_slot, REASON_DISABLED)
	if flow_link_timer <= 0.0 or actor.stats.resonance_pips() <= 0:
		return _refuse(trigger_slot, REASON_NO_WINDOW)
	if not is_trigger_slot_unlocked(trigger_slot):
		return _refuse(trigger_slot, REASON_LOCKED)
	return _invoke(trigger_slot, true)


## The 1-Button Gambit Assist (§5.2, §6.7): with the window open and the pips in hand, the
## Squire's button pulls the L card (or R's, which rides the R cast it returns as "command");
## otherwise it leaves the swing to the Squire's picker ("handled": false, no command).
func execute_one_button_gambit() -> Dictionary:
	var answer: Dictionary = {"success": true, "card_id": &"", "action_id": GAMBIT_ACTION, "damage": 0, "command": -1, "handled": false}
	if not enabled or loadout == null or not is_flow_window_open() or actor.stats.resonance_pips() <= 0:
		return answer
	for trigger_slot: int in [PlayerLoadoutResource.TriggerSlot.L, PlayerLoadoutResource.TriggerSlot.R]:
		var card: ScribeCardResource = card_for_trigger(trigger_slot)
		if card == null or not is_trigger_slot_unlocked(trigger_slot) or actor.stats.resonance_pips() < card.resonance_pip_cost:
			continue
		if trigger_slot == PlayerLoadoutResource.TriggerSlot.R:
			var skill: CombatActionResource = actor.loadout.opener_for(CombatActionResource.Command.TRIGGER_R_SKILL)
			if skill != null and actor.stats.can_afford(skill):
				# The R press casts as Sign-Flow in the window, and the pull rides that cast.
				answer["command"] = CombatActionResource.Command.TRIGGER_R_SKILL
				answer["card_id"] = card.card_id
				answer["action_id"] = card.active_action_id
				return answer
		var pulled: Dictionary = _invoke(trigger_slot, true)
		if bool(pulled.get("success", false)):
			pulled["command"] = -1
			pulled["handled"] = true
			return pulled
	return answer


## Pulls this hero has made, and refusals.
func invocations() -> int:
	return _invocations


func refusals() -> int:
	return _refusals


## A Sign-Flow cast in the window (R, L+R, or L's Counter-Brace): the slot's seal card rides it.
func _on_sign_flow_cast(socket: int, _scribe_sign: int) -> void:
	if not enabled or socket < 0 or socket >= SOCKET_TRIGGERS.size():
		return
	var trigger_slot: int = SOCKET_TRIGGERS[socket]
	if card_for_trigger(trigger_slot) == null or not is_trigger_slot_unlocked(trigger_slot):
		return
	_invoke(trigger_slot, false)


## The pull itself: the pips (when charged here), the coat, the flourish everywhere, the trail's ink.
func _invoke(trigger_slot: int, charge_pips: bool) -> Dictionary:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var primary_id: StringName = loadout.primary_for_trigger(trigger_slot)
	if trigger_slot == PlayerLoadoutResource.TriggerSlot.L_AND_R and progression_stage < GRAND_INVOCATION_STAGE:
		primary_id = &""
	if primary_id == &"":
		return _refuse(trigger_slot, REASON_EMPTY)
	var card: ScribeCardResource = catalog.get_card(primary_id)
	if card == null or not card.is_seal_card():
		return _refuse(trigger_slot, REASON_EMPTY)
	if charge_pips:
		if actor.stats.resonance_pips() < card.resonance_pip_cost:
			return _refuse(trigger_slot, REASON_PIPS)
		actor.stats.add_resonance(-float(card.resonance_pip_cost))
	flow_link_timer = 0.0
	_window_fired = true
	var tuck_id: StringName = loadout.tuck_for_trigger(trigger_slot)
	var has_tuck: bool = tuck_id != &"" and tucks_unlocked()
	active_card_id = primary_id
	active_tuck = has_tuck
	active_left = card.active_buff_duration_sec
	burst_left = BURST_GRACE_SEC
	_invocations += 1
	var damage: int = catalog.evaluate_hit_damage(loadout, true, true, primary_id, has_tuck)
	var posture: float = card.active_posture_damage_bonus * (ScribeCardResource.TUCK_SYNERGY_POSTURE_MULT if has_tuck else 1.0)
	_show_pocket_pull(primary_id, trigger_slot, has_tuck)
	if actor.trail != null:
		actor.trail.set_ink_override(card.ink_primary_color, active_left)
	if actor.is_local_player():
		AudioCues.play(&"card_chime", 1.15, -8.0)
	CombatDirector.current.show_float_text(actor.global_position + Vector3.UP * (actor.body_height() + 0.9), "POCKET-PULL!",
		card.ink_primary_color.lightened(0.2), PULL_TEXT_SIZE)
	last_invocation = {
		"success": true,
		"card_id": primary_id,
		"action_id": card.active_action_id,
		"damage": damage,
		"posture_damage": posture,
		"manifestation_mode": int(card.manifestation_mode),
		"has_tuck": has_tuck,
		"trigger_slot": trigger_slot,
	}
	pocket_pull_invoked.emit(primary_id, trigger_slot, has_tuck)
	return last_invocation


func _refuse(trigger_slot: int, reason: String) -> Dictionary:
	_refusals += 1
	last_invocation = {"success": false, "reason": reason, "trigger_slot": trigger_slot}
	pocket_pull_refused.emit(trigger_slot, reason)
	return last_invocation


func _end_coat() -> void:
	active_card_id = &""
	active_tuck = false
	active_left = 0.0
	burst_left = 0.0


## The flourish on this peer, and on every other peer with the hero loaded.
func _show_pocket_pull(card_id: StringName, trigger_slot: int, has_tuck: bool) -> void:
	_play_pocket_pull_here(card_id, trigger_slot, has_tuck)
	if NetworkManager.current.is_online() and actor.is_multiplayer_authority():
		for peer_id: int in InstanceManager.current.live_remote_peers():
			trigger_pocket_pull_rpc.rpc_id(peer_id, card_id, trigger_slot, 1 if has_tuck else 0)


func _play_pocket_pull_here(card_id: StringName, trigger_slot: int, _has_tuck: bool) -> void:
	if actor.visuals != null:
		actor.visuals.play_pocket_pull_flourish(ArsenalCatalog.current, card_id, trigger_slot)


# --- Network (Gate 4): ids and ints only --------------------------------------------------

func _broadcast_loadout() -> void:
	if loadout == null or not is_inside_tree() or not actor.is_multiplayer_authority():
		return
	if not NetworkManager.current.is_online() or not InstanceManager.current.is_live():
		return
	var data: Dictionary = loadout.to_network_dict()
	for peer_id: int in InstanceManager.current.live_remote_peers():
		sync_loadout_rpc.rpc_id(peer_id, data)


## The owner's hand, as Strings and ints (PlayerLoadoutResource.to_network_dict).
@rpc("authority", "call_remote", "reliable")
func sync_loadout_rpc(data: Dictionary) -> void:
	if loadout == null:
		loadout = PlayerLoadoutResource.new()
	loadout.from_network_dict(data)
	_received_from_owner = true
	_custom_hand = false
	apply_visuals()
	loadout_changed.emit(loadout)


## The owner pulled a card: its id, the trigger (an int) and whether a tuck rode it (0 or 1).
@rpc("authority", "call_remote", "reliable")
func trigger_pocket_pull_rpc(card_id: StringName, trigger_slot: int, has_tuck: int) -> void:
	if ArsenalCatalog.current.get_card(card_id) == null:
		return
	_play_pocket_pull_here(card_id, clampi(trigger_slot, 0, SOCKET_TRIGGERS.size() - 1), has_tuck != 0)
	pocket_pull_invoked.emit(card_id, trigger_slot, has_tuck != 0)
