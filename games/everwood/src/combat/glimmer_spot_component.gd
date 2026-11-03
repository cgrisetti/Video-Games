## A foe's Glimmer-Spot (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §2–3), played from
## its BossEncounterResource the same way for any foe:
##
## - Tier 1 kin are always open: a strike carrying Iron-Root cracks them for
##   1.25x poise and a brief amber glint, with no text.
## - Tier 2 and 3 foes open the spot during their pattern (open_window: the
##   Cairnsman's roar as he starts a raid cast). It stays open for the
##   encounter's scaled window, tightening 12 frames for each of the party's
##   first five sightings, which PartyProgress remembers. A strike carrying one
##   of the counter Signs while it's open is a Bravery Counter: (60 + 45) poise
##   times the encounter's impact multiplier, and the Sign's detonation; then
##   it closes. On the first two sightings the HUD shows the encounter's rhyme.
## - A Squire (1-Button Gambit Assist) who presses within 90 frames before the
##   opening has the counter buffered: their R fires on its first frame.
##
## The foe's owner opens the window and judges strikes; every peer shows the
## golden glint over the foe while it's open.
class_name GlimmerSpotComponent
extends Node3D

## The smoke test's older checks switch Glimmer-Spots off (like BracedGuardComponent.enabled).
static var enabled: bool = true

## A Squire's press this long before the opening fires on its first frame (90 frames).
const SQUIRE_PREBUFFER_FRAMES: int = 90
const FRAMES_PER_SECOND: float = 60.0
const GLINT_COLOR: Color = Color(1.0, 0.86, 0.36)
const TIER_ONE_GLINT_COLOR: Color = Color(0.93, 0.6, 0.22)
const GLINT_SIZE: float = 0.34
const GLINT_SPIN: float = 2.4
const GLINT_ENERGY: float = 3.5
## An Iron-Root crack on Tier 1 kin glints this long.
const TIER_ONE_GLINT_TIME: float = 0.35

var actor: ActorBase
var encounter: BossEncounterResource
## Bravery Counters landed on this foe (its owner counts them).
var counters_landed: int = 0

var _open_until: float = -INF
## When the foe's owner expects the next opening (game time), for Squire buffering; -INF when none is coming.
var _opens_at: float = -INF
## Squires waiting for the opening: player id -> the game time they pressed.
var _buffered: Dictionary[StringName, float] = {}
var _glint: MeshInstance3D
var _glint_material: StandardMaterial3D
var _flash_left: float = 0.0


func setup(owner_actor: ActorBase, encounter_resource: BossEncounterResource) -> void:
	actor = owner_actor
	encounter = encounter_resource
	name = "GlimmerSpot"


func _ready() -> void:
	_glint_material = StorybookMaterial.glowing(GLINT_COLOR, GLINT_ENERGY)
	_glint_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glint = ShapeKit.no_shadow(ShapeKit.box("Glint", Vector3(GLINT_SIZE, GLINT_SIZE, GLINT_SIZE * 0.3), Vector3.ZERO, _glint_material))
	_glint.visible = false
	add_child(_glint)
	# Chest height, in front of the foe, where its core would be.
	position = Vector3(0.0, actor.body_height() * 0.62, -actor.body_radius() * 0.9)


func _process(delta: float) -> void:
	_flash_left = maxf(0.0, _flash_left - delta)
	var open: bool = is_open() and not encounter.is_always_open()
	_glint.visible = (open or _flash_left > 0.0) and not actor.stats.is_downed
	if _glint.visible:
		var color: Color = GLINT_COLOR if open else TIER_ONE_GLINT_COLOR
		_glint_material.albedo_color = color
		_glint_material.emission = color
		_glint.rotation = Vector3(0.0, _glint.rotation.y + GLINT_SPIN * delta, PI * 0.25)
		var pulse: float = 1.0 + 0.25 * sin(CombatDirector.game_time() * 12.0)
		_glint.scale = Vector3.ONE * pulse


## Open to a counter right now (always, for Tier 1 kin).
func is_open() -> bool:
	if not enabled or encounter == null:
		return false
	return encounter.is_always_open() or CombatDirector.game_time() < _open_until


## Seconds the open window has left (0 when shut).
func time_left() -> float:
	return maxf(0.0, _open_until - CombatDirector.game_time())


## Foe's owner: the pattern begins, so the spot opens for the scaled window.
## Records the sighting and tells every peer. Returns the window in frames (0 if none opened).
func open_window() -> int:
	if not enabled or encounter == null or encounter.is_always_open() or not actor.is_multiplayer_authority():
		return 0
	var progress: PartyProgress = PartyProgress.current
	var frames: int = encounter.get_scaled_glimmer_frames(progress.pattern_seen_count(encounter.encounter_id))
	var seen: int = progress.record_pattern_seen(encounter.encounter_id)
	var rhyme: String = encounter.hud_rhyme_couplet if encounter.shows_rhyme(seen) else ""
	CombatDirector.current.show_glimmer(actor, frames / FRAMES_PER_SECOND, rhyme)
	return frames


## Every peer (CombatDirector's RPC): the window is open for `seconds` from
## now, and the Squires here who buffered their counter fire it on this first frame.
func show_open(seconds: float) -> void:
	_open_until = CombatDirector.game_time() + seconds
	_opens_at = -INF
	_fire_buffered()


## Every peer: a Bravery Counter (or the fight's end) shut the window.
func close() -> void:
	_open_until = -INF


## Every peer (CombatDirector's RPC): the next opening comes in `seconds`, so
## Squires may buffer their counter from 90 frames before it.
func expect_opening(seconds: float) -> void:
	_opens_at = CombatDirector.game_time() + maxf(0.0, seconds)


## Seconds until an announced opening (INF when none is coming).
func seconds_to_opening() -> float:
	return _opens_at - CombatDirector.game_time() if _opens_at > -INF else INF


## Whether a press now can be buffered for the opening (it comes within 90 frames).
func accepts_buffer() -> bool:
	var wait: float = seconds_to_opening()
	return enabled and wait >= 0.0 and wait <= SQUIRE_PREBUFFER_FRAMES / FRAMES_PER_SECOND


## A Squire's counter waits for the opening: their R fires on its first frame.
func buffer_squire_counter(squire: ActorBase) -> bool:
	if not accepts_buffer():
		return false
	_buffered[squire.player_id] = CombatDirector.game_time()
	return true


func is_buffered(player_id: StringName) -> bool:
	return _buffered.has(player_id)


func _fire_buffered() -> void:
	for player_id: StringName in _buffered:
		var squire: ActorBase = CombatDirector.current.get_actor(player_id)
		if squire != null and squire.input != null and not squire.stats.is_downed:
			squire.input.fire_buffered_counter()
	_buffered.clear()


## The foe's owner judges a strike (ActorBase.receive_strike): Tier 1 kin crack
## under Iron-Root; an open spot struck with a counter Sign is a Bravery Counter.
## Returns whether it was one.
func filter_strike(event: CombatEvent) -> bool:
	if not enabled or encounter == null or event.unavoidable:
		return false
	var scribe_sign: int = event.counter_sign()
	if encounter.is_always_open():
		if scribe_sign == ScribeSignResource.Sign.SIGN_IRON_ROOT:
			event.poise_damage *= BossEncounterResource.TIER_1_POISE_MULTIPLIER
			_flash_left = TIER_ONE_GLINT_TIME
		return false
	if not is_open() or not encounter.is_countered_by(scribe_sign):
		return false
	close()
	counters_landed += 1
	event.poise_damage = encounter.bravery_counter_poise()
	CombatDirector.current.bravery_counter(actor, event, scribe_sign, encounter)
	return true
