## A spirit of the First-Quiet on the Hob-to-Boggart Spectrum
## (15_THE_MYTHOPOETIC_LENS.md §6.1), on every foe: the Doverslap Falls trail's
## woodland kin, Oakshire Vale's six families and the Cairnsman.
##
## - HOB_BENIGN (STATE_CURIOUS): a hob nobody has wronged. Walking within 6 m
##   opens a 180-frame (3 s) parley window; pressing light in it (the Squire
##   Gambit's one button) waves the Truce-Sign: the hob dances (STATE_SOOTHED),
##   the party's pouch gets 25 Chimes and the waver a pip. Striking it breaks
##   the etiquette: it turns boggart (BOGGART_AWOKEN) and fights back.
## - BOGGART_AWOKEN: STATE_SLUMBER until it joins a fight, then STATE_HOSTILE. A
##   Cairn-Drake bellows a 45-frame STATE_CHALLENGE_ROAR first, holding its blow.
## - Beaten, a spirit never leaves a body behind: it's un-boggarted. Released as
##   a white sea-swallow, a hedge-wren or a warm path-light
##   (STATE_UNBOGGART_RELEASE), curled into a mossy cairn (STATE_LULLED_CAIRN),
##   or, a Furrow Iron-Man whose chest Maker-Seal was turned right-way up, bowed
##   into a steward for 600 s (STATE_STEWARD_HELPER). An Iron-Man's seal starts
##   upside-down: a Warm-Hearth strike ("feed him a coal") opens his chest for
##   6 s, and an Iron-Root strike then turns the seal. Beaten with it still
##   upside-down, he sinks back into the furrow to sleep.
##
## The host decides parleys and seal turns and tells the other peers; every
## peer sees a beaten spirit resolve from its synced health.
class_name HobSpectrumComponent
extends Node

signal state_changed(state: SpiritState)
signal soothed(player_id: StringName)
signal unboggarted(resolution: UnboggartResolution)
signal maker_seal_turned(upright: bool)

enum EquilibriumState { HOB_BENIGN, BOGGART_AWOKEN }
enum SpiritState { STATE_CURIOUS, STATE_SOOTHED, STATE_SLUMBER, STATE_CHALLENGE_ROAR, STATE_HOSTILE,
	STATE_UNBOGGART_RELEASE, STATE_LULLED_CAIRN, STATE_STEWARD_HELPER }
## How a beaten spirit is un-boggarted.
enum UnboggartResolution { STATE_UNBOGGART_RELEASE, STATE_LULLED_CAIRN, STATE_STEWARD_HELPER }
## What a released spirit becomes.
enum ReleaseForm { SEA_SWALLOW, HEDGE_WREN, PATH_LIGHT, SINK_TO_SLEEP }

const FRAMES_PER_SECOND: float = 60.0
const PARLEY_RADIUS: float = 6.0
const PARLEY_WINDOW_FRAMES: int = 180
const PARLEY_CHIMES: int = 25
const PARLEY_PIPS: float = 1.0
## A soothed hob dances this long, then wanders again.
const DANCE_TIME: float = 2.4
const DANCE_HOP: float = 0.3
const DANCE_SPIN: float = 9.0
const CHALLENGE_ROAR_FRAMES: int = 45
const STEWARD_HELPER_TIME: float = 600.0
## A Warm-Hearth strike holds an Iron-Man's chest open this long.
const SEAL_EXPOSED_TIME: float = 6.0
## A beaten mob's cairn stays this long (its spawner grows a fresh spirit later).
const CAIRN_LINGER: float = 30.0
const SOOTHE_COLOR: Color = Color(1.0, 0.82, 0.36)
const BOGGART_COLOR: Color = Color(1.0, 0.42, 0.36)
const SEAL_INVERTED_COLOR: Color = Color(0.42, 0.36, 0.32)
const SEAL_EXPOSED_COLOR: Color = Color(1.0, 0.76, 0.28)
const SEAL_UPRIGHT_COLOR: Color = Color(1.0, 0.9, 0.55)

## Parleys and Challenge-Roars. The older smoke checks switch them off: they
## strike curious hobs with light and time the Cairn-Drake's first blow.
static var enabled: bool = true

var actor: ActorBase
var equilibrium: EquilibriumState = EquilibriumState.BOGGART_AWOKEN
var state: SpiritState = SpiritState.STATE_SLUMBER
var resolution: UnboggartResolution = UnboggartResolution.STATE_UNBOGGART_RELEASE
var release_form: ReleaseForm = ReleaseForm.HEDGE_WREN
## Bellows a Challenge-Roar before its first blow.
var roars: bool = false
var has_maker_seal: bool = false
var is_maker_seal_upright: bool = true
var is_maker_seal_exposed: bool = false
## The colour its release or its cairn takes.
var spirit_color: Color = Color(0.92, 0.92, 0.88)
## A beaten boss's cairn stays for good; a mob's for CAIRN_LINGER.
var cairn_stays: bool = false

var _parley: ParleyPoint
var _seal_label: Label3D
var _roar_left: float = 0.0
var _dance_left: float = 0.0
var _exposed_left: float = 0.0
var _steward_left: float = 0.0
var _resolved: bool = false
var _was_engaged: bool = false


func setup(owner_actor: ActorBase) -> void:
	actor = owner_actor
	name = "HobSpectrumComponent"
	owner_actor.configure_spirit(self)
	state = SpiritState.STATE_CURIOUS if equilibrium == EquilibriumState.HOB_BENIGN else SpiritState.STATE_SLUMBER
	if has_maker_seal:
		is_maker_seal_upright = false


func _ready() -> void:
	if equilibrium == EquilibriumState.HOB_BENIGN:
		_parley = ParleyPoint.new()
		_parley.name = "ParleyPoint"
		_parley.spirit = self
		_parley.reach = PARLEY_RADIUS
		actor.add_child.call_deferred(_parley)
	if has_maker_seal:
		_seal_label = Label3D.new()
		_seal_label.name = "MakerSeal"
		_seal_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_seal_label.font_size = 44
		_seal_label.outline_size = 10
		_seal_label.pixel_size = 0.008
		_seal_label.position = Vector3(0.0, actor.body_height() * 0.62, 0.0)
		actor.add_child.call_deferred(_seal_label)
		_refresh_seal()
		CombatDirector.current.hit_resolved.connect(_on_hit_resolved)


func _exit_tree() -> void:
	var director: CombatDirector = CombatDirector.current
	if director != null and director.hit_resolved.is_connected(_on_hit_resolved):
		director.hit_resolved.disconnect(_on_hit_resolved)


func _physics_process(delta: float) -> void:
	if actor == null or actor.stats == null:
		return
	if _resolved:
		if state == SpiritState.STATE_STEWARD_HELPER:
			_steward_left = maxf(0.0, _steward_left - delta)
		return
	if actor.is_beaten():
		_resolve()
		return
	if _exposed_left > 0.0:
		_exposed_left = maxf(0.0, _exposed_left - delta)
		if _exposed_left == 0.0 and NetworkManager.current.is_host():
			_set_seal(false, false)
	if equilibrium == EquilibriumState.HOB_BENIGN:
		if actor.stats.health < actor.stats.stats.max_health - 0.5:
			_turn_boggart()
		elif _dance_left > 0.0:
			_dance(delta)
		return
	var engaged: bool = actor.is_engaged()
	if engaged and not _was_engaged and roars and enabled:
		_roar_left = CHALLENGE_ROAR_FRAMES / FRAMES_PER_SECOND
		_set_state(SpiritState.STATE_CHALLENGE_ROAR)
		AudioCues.play(&"bell", 0.3, -4.0)
		CombatDirector.current.announce(actor.global_position + Vector3.UP * (actor.body_height() + 0.8), "CHALLENGE-ROAR!", BOGGART_COLOR)
	_was_engaged = engaged
	if _roar_left > 0.0:
		_roar_left = maxf(0.0, _roar_left - delta)
		return
	_set_state(SpiritState.STATE_HOSTILE if engaged else SpiritState.STATE_SLUMBER)


## Whether a light press here would wave the Truce-Sign.
func is_parleyable() -> bool:
	return enabled and not _resolved and state == SpiritState.STATE_CURIOUS and not actor.is_beaten()


## True while a soothed hob keeps out of its pack's fights.
func is_soothed() -> bool:
	return state == SpiritState.STATE_SOOTHED


## True through a Challenge-Roar: the spirit holds its blow.
func is_roaring() -> bool:
	return state == SpiritState.STATE_CHALLENGE_ROAR and _roar_left > 0.0


## True while a bowed Iron-Man stands as a steward (his body stays, friendly).
func is_steward() -> bool:
	return state == SpiritState.STATE_STEWARD_HELPER and _steward_left > 0.0


func is_resolved() -> bool:
	return _resolved


# --- Parley (HOB_BENIGN) ----------------------------------------------------------

## A local player waved the Truce-Sign: the host decides.
func request_parley(by: ActorBase) -> void:
	if NetworkManager.current.is_host():
		_host_parley(by.player_id)
	else:
		_ask_parley.rpc_id(1, by.player_id)


@rpc("any_peer", "call_remote", "reliable")
func _ask_parley(player_id: StringName) -> void:
	if NetworkManager.current.is_host():
		_host_parley(player_id)


func _host_parley(player_id: StringName) -> void:
	var by: ActorBase = CombatDirector.current.get_actor(player_id)
	if by == null or not is_parleyable() or _flat_distance(by) > PARLEY_RADIUS + 0.5:
		return
	_soothe(player_id)
	if NetworkManager.current.is_online():
		_soothed_remote.rpc(player_id)
	PartyProgress.current.award_chimes(PARLEY_CHIMES)


@rpc("authority", "call_remote", "reliable")
func _soothed_remote(player_id: StringName) -> void:
	_soothe(player_id)


func _soothe(player_id: StringName) -> void:
	if state == SpiritState.STATE_SOOTHED:
		return
	_set_state(SpiritState.STATE_SOOTHED)
	_dance_left = DANCE_TIME
	var by: ActorBase = CombatDirector.current.get_actor(player_id)
	if by != null and by.is_local_player():
		var stats: StatsComponent = by.stats
		stats.resonance_charge = minf(float(stats.stats.max_resonance_pips), stats.resonance_charge + PARLEY_PIPS)
		stats.resonance_changed.emit(stats.resonance_pips(), stats.resonance_charge)
	CombatDirector.current.announce(actor.global_position + Vector3.UP * (actor.body_height() + 0.6),
		"TRUCE!  +%d CHIMES" % PARLEY_CHIMES, SOOTHE_COLOR, &"chime")
	# The hero who waved it bows (19 GDD §3.3, the Truce-Sign Parley).
	if by != null and by.visuals != null:
		by.visuals.play_truce_sign_parley()
	soothed.emit(player_id)


## A happy hop-and-spin, then still again.
func _dance(delta: float) -> void:
	_dance_left = maxf(0.0, _dance_left - delta)
	var visual: Node3D = actor.visual
	if visual == null:
		return
	if _dance_left > 0.0:
		visual.position.y = absf(sin((DANCE_TIME - _dance_left) * 7.0)) * DANCE_HOP
		visual.rotation.y += DANCE_SPIN * delta
	else:
		visual.position.y = 0.0
		visual.rotation.y = 0.0


## Struck while benign: the hob turns boggart and fights back.
func _turn_boggart() -> void:
	equilibrium = EquilibriumState.BOGGART_AWOKEN
	_dance_left = 0.0
	if actor.visual != null:
		actor.visual.position.y = 0.0
		actor.visual.rotation.y = 0.0
	_set_state(SpiritState.STATE_HOSTILE)
	CombatDirector.current.announce(actor.global_position + Vector3.UP * (actor.body_height() + 0.6), "TURNED BOGGART!", BOGGART_COLOR)


# --- The Maker-Seal (Furrow Iron-Men) ------------------------------------------

func _on_hit_resolved(event: CombatEvent, _outcome: int) -> void:
	if not has_maker_seal or is_maker_seal_upright or _resolved or not NetworkManager.current.is_host():
		return
	if actor.get_node_or_null(event.target_path) != actor:
		return
	var signs: Array[int] = [event.scribe_sign, event.primer, event.coat_sign]
	if is_maker_seal_exposed and signs.has(ScribeSignResource.Sign.SIGN_IRON_ROOT):
		_set_seal(true, false)
	elif signs.has(ScribeSignResource.Sign.SIGN_WARM_HEARTH):
		_set_seal(false, true)


## Host: turns or opens the seal and tells the other peers.
func _set_seal(upright: bool, exposed: bool) -> void:
	_apply_seal(upright, exposed)
	if NetworkManager.current.is_online():
		_seal_remote.rpc(upright, exposed)


@rpc("authority", "call_remote", "reliable")
func _seal_remote(upright: bool, exposed: bool) -> void:
	_apply_seal(upright, exposed)


func _apply_seal(upright: bool, exposed: bool) -> void:
	var turned: bool = upright and not is_maker_seal_upright
	is_maker_seal_upright = upright
	is_maker_seal_exposed = exposed and not upright
	_exposed_left = SEAL_EXPOSED_TIME if is_maker_seal_exposed else 0.0
	_refresh_seal()
	var above: Vector3 = actor.global_position + Vector3.UP * (actor.body_height() + 0.6)
	if turned:
		CombatDirector.current.announce(above, "SEAL TURNED RIGHT-WAY!", SEAL_UPRIGHT_COLOR, &"seal_iron_root")
		maker_seal_turned.emit(true)
	elif is_maker_seal_exposed:
		CombatDirector.current.announce(above, "FED HIM A COAL!", SEAL_EXPOSED_COLOR, &"seal_warm_hearth")


func _refresh_seal() -> void:
	if _seal_label == null:
		return
	_seal_label.text = "▲" if is_maker_seal_upright else "▼"
	if is_maker_seal_upright:
		_seal_label.modulate = SEAL_UPRIGHT_COLOR
	elif is_maker_seal_exposed:
		_seal_label.modulate = SEAL_EXPOSED_COLOR
	else:
		_seal_label.modulate = SEAL_INVERTED_COLOR


# --- Un-Boggarting --------------------------------------------------------------

func _resolve() -> void:
	_resolved = true
	if _parley != null:
		_parley.release_all()
	var final: UnboggartResolution = resolution
	var form: ReleaseForm = release_form
	if final == UnboggartResolution.STATE_STEWARD_HELPER and not is_maker_seal_upright:
		final = UnboggartResolution.STATE_UNBOGGART_RELEASE
		form = ReleaseForm.SINK_TO_SLEEP
	var at: Vector3 = actor.global_position
	var holder: Node = actor.get_parent()
	match final:
		UnboggartResolution.STATE_UNBOGGART_RELEASE:
			_set_state(SpiritState.STATE_UNBOGGART_RELEASE)
			if form != ReleaseForm.SINK_TO_SLEEP and holder != null:
				UnboggartFx.release(holder, at + Vector3.UP * actor.body_height() * 0.6, form, spirit_color)
		UnboggartResolution.STATE_LULLED_CAIRN:
			_set_state(SpiritState.STATE_LULLED_CAIRN)
			if holder != null:
				UnboggartFx.cairn(holder, at, actor.body_radius(), spirit_color, INF if cairn_stays else CAIRN_LINGER)
		UnboggartResolution.STATE_STEWARD_HELPER:
			_set_state(SpiritState.STATE_STEWARD_HELPER)
			_steward_left = STEWARD_HELPER_TIME
			CombatDirector.current.announce(at + Vector3.UP * (actor.body_height() + 0.6), "A STEWARD BOWS!", SEAL_UPRIGHT_COLOR, &"bell")
	unboggarted.emit(final)


func _set_state(next: SpiritState) -> void:
	if next == state:
		return
	state = next
	state_changed.emit(next)


func _flat_distance(other: Node3D) -> float:
	var a: Vector3 = actor.global_position
	var b: Vector3 = other.global_position
	return Vector2(a.x - b.x, a.z - b.z).length()


## The parley's walk-up spot on a curious hob: a local player who walks within
## 6 m gets 180 frames in which light waves the Truce-Sign. Stepping back out
## of reach and in again opens a fresh window.
class ParleyPoint extends Interactable:
	var spirit: HobSpectrumComponent
	## Frames left in each local player's window.
	var windows: Dictionary[StringName, int] = {}

	func _physics_process(_delta: float) -> void:
		for member: ActorBase in CombatDirector.current.party_actors():
			if not member.is_local_player():
				continue
			var flat: Vector2 = Vector2(member.global_position.x - global_position.x, member.global_position.z - global_position.z)
			var near: bool = flat.length() <= reach and not member.stats.is_downed and spirit.is_parleyable()
			if near:
				windows[member.player_id] = int(windows.get(member.player_id, HobSpectrumComponent.PARLEY_WINDOW_FRAMES + 1)) - 1
			else:
				windows.erase(member.player_id)
			var open: bool = near and int(windows.get(member.player_id, 0)) > 0
			if open and member.interactable == null:
				member.interactable = self
			elif not open and member.interactable == self:
				member.interactable = null

	## Frames left in `player_id`'s window (0 when it's shut).
	func window_frames(player_id: StringName) -> int:
		return maxi(0, int(windows.get(player_id, 0)))

	func release_all() -> void:
		windows.clear()
		for member: ActorBase in CombatDirector.current.party_actors():
			if member.interactable == self:
				member.interactable = null

	func prompt_for(member: ActorBase) -> String:
		return "%s: wave the Truce-Sign to the %s (+%d Chimes)" % [member.input.label(InputComponent.ACTION_LIGHT),
			spirit.actor.display_name(), HobSpectrumComponent.PARLEY_CHIMES]

	func interact(member: ActorBase) -> void:
		spirit.request_parley(member)
