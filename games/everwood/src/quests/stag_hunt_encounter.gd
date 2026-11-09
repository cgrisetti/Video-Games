## A Stag Hunt (the Bible §2; docs/28 §5.4; docs/29 §5): Q03's Furrow Iron-Man
## on the stone bridge, a coordination game played with weapons and cards.
##
##   Rabbit (defect): burn his health to nothing. About 35 s; he scatters into
##   rusted plough-iron (25 Chimes for the Scrap) and 10 minutes later the
##   Rusted Iron-Man rises in his place, angrier: -40 hazard, -15 net utility.
##   Stag (cooperate): fill his posture until he kneels, the Lantern-Bearer rings
##   the Amber Chime ("Hold Blades!": his health locks, his dots glow amber),
##   then every hero in reach pours Deep-Ink at his seal (2 Ink-Drops each)
##   before the Metronome Pendulum's beats run out. About 48 s; his seal turns
##   upright and he bows as a steward (15 Chimes, +120 World Buff, +135 net).
##   Missed, he stands with half his posture back; the strokes already drawn stay.
##
## Built on the guardian on every peer (the director attaches it); the host runs
## it and tells the others what to show. Its health and posture scale with the
## heroes present when he is first engaged, so both paths keep their times.
class_name StagHuntEncounter
extends Node

signal kneeled
signal chime_rung(by: StringName)
signal resolved(branch: StringName, entry: Dictionary)

enum Phase { FIGHTING, KNEELING, AMBER, RESOLVED }

const BRANCH_STAG: StringName = &"stag"
const BRANCH_RABBIT: StringName = &"rabbit"
## The Bible's payoffs (Scrap is paid in Chimes; utility is the design ledger's number).
const RABBIT_SCRAP: int = 25
const RABBIT_HAZARD: int = -40
const RABBIT_NET: int = -15
const RABBIT_SECONDS: float = 35.0
const STAG_SCRAP: int = 15
const STAG_WORLD_BUFF: int = 120
const STAG_NET: int = 135
const STAG_SECONDS: float = 48.0
## How long the World Buff (the mended bridge's speed, the steward's walk) lasts, and when a scatter's Rusted Iron-Man rises.
const WORLD_BUFF_SECONDS: float = 900.0
const RUSTED_RESPAWN_SECONDS: float = 600.0
## The kneel, the chime and the finisher (docs/28 §5.4).
const KNEEL_SECONDS: float = 8.0
## The Metronome Pendulum swings once a beat: the mosaic's dotted quarter at 104 (0.577 s).
const BEAT_SECONDS: float = 60.0 / 104.0
const FINISHER_BEATS: int = 5
const SQUIRE_EXTRA_BEATS: int = 2
const FINISHER_DROPS: int = 2
## Every hero within this of him must pour; the kneel pays them this many drops first (25 GDD R2).
const FINISHER_REACH: float = 9.0
const KNEEL_REFILL: int = 2
## Missed: he stands with this share of his posture back.
const MISSED_POSTURE: float = 0.5
## Health and posture at 1 hero, as a share of 5 heroes' (they scale up to all of it).
const SOLO_SHARE: float = 0.4
const AMBER: Color = Color(1.0, 0.72, 0.18)
const KNEEL_GOLD: Color = Color(1.0, 0.86, 0.42)
const BANNER_TIME: float = 3.5

var boss: WildMob
var boss_id: StringName = &""
var phase: Phase = Phase.FIGHTING
## Who holds the Amber Chime this kneel.
var bearer: StringName = &""
## Heroes who have poured Deep-Ink (they stay poured if the window is missed).
var poured: Dictionary[StringName, bool] = {}
var heroes_at_start: int = 0
var outcome: Dictionary = {}

var chime_point: QuestInteractable
var finisher_point: QuestInteractable

var _engaged_at: float = -1.0
var _window_left: float = 0.0
var _beat_left: float = 0.0
var _beats_left: int = 0
var _warned_low: bool = false


## The encounter on a guardian, or null.
static func of(actor: ActorBase) -> StagHuntEncounter:
	return actor.get_node_or_null(^"StagHuntEncounter") as StagHuntEncounter if actor != null else null


func setup(guardian: WildMob, encounter_boss_id: StringName) -> void:
	boss = guardian
	boss_id = encounter_boss_id
	name = "StagHuntEncounter"


func _ready() -> void:
	chime_point = QuestInteractable.new()
	chime_point.name = "AmberChime"
	chime_point.prompt = "light: HOLD BLADES! (Amber Chime)"
	chime_point.reach = boss.body_radius() + 3.2
	chime_point.available = func() -> bool: return phase == Phase.KNEELING
	chime_point.who = func(actor: ActorBase) -> bool: return actor.player_id == bearer
	chime_point.on_used = ring_chime
	boss.add_child.call_deferred(chime_point)
	finisher_point = QuestInteractable.new()
	finisher_point.name = "DeepInk"
	finisher_point.prompt = "light: DEEP-INK, all together"
	finisher_point.drop_cost = FINISHER_DROPS
	finisher_point.reach = boss.body_radius() + 3.2
	finisher_point.available = func() -> bool: return phase == Phase.AMBER
	finisher_point.who = func(actor: ActorBase) -> bool: return not poured.has(actor.player_id)
	finisher_point.on_used = pour
	boss.add_child.call_deferred(finisher_point)


func _physics_process(delta: float) -> void:
	if boss == null or not is_instance_valid(boss) or not NetworkManager.current.is_host() or phase == Phase.RESOLVED:
		return
	if boss.stats.is_downed:
		var calmed: bool = boss.calming != null and boss.calming.was_calmed
		_resolve(BRANCH_STAG if calmed else BRANCH_RABBIT)
		return
	if _engaged_at < 0.0 and boss.is_engaged():
		_begin()
	match phase:
		Phase.FIGHTING:
			if boss.stats.is_knocked_down():
				force_kneel()
			elif boss.stats.health_ratio() < CalmingComponent.WAVER_HEALTH and not _warned_low and _engaged_at >= 0.0:
				_warned_low = true
				_say("CAREFUL!", "Alf-Wright: You'll scatter him, not save him. Wear his posture down.", Color(0.86, 0.86, 0.84))
		Phase.KNEELING, Phase.AMBER:
			# Hold him down for the whole window.
			boss.stats.knockdown_time_left = maxf(boss.stats.knockdown_time_left, 0.5)
			_window_left -= delta
			if phase == Phase.AMBER:
				_beat_left -= delta
				if _beat_left <= 0.0 and _beats_left > 0:
					_beat_left = BEAT_SECONDS
					_beats_left -= 1
					_pendulum(_beats_left)
			if _window_left <= 0.0:
				_missed()
			elif phase == Phase.KNEELING and _bearer_is_companion() and _window_left <= KNEEL_SECONDS - 1.0:
				ring_chime(bearer)


## The first hero engages him: his health and posture fit the party.
func _begin() -> void:
	_engaged_at = CombatDirector.game_time()
	heroes_at_start = maxi(1, CombatDirector.current.alive_party().size())
	var share: float = lerpf(SOLO_SHARE, 1.0, clampf(float(heroes_at_start - 1) / 4.0, 0.0, 1.0))
	var base: MobVariantResource = boss.variant
	boss.stats.stats.max_health = base.health * share
	boss.stats.health = boss.stats.stats.max_health
	boss.stats.stats.max_poise = base.poise * share
	boss.stats.poise = boss.stats.stats.max_poise
	boss.stats.health_changed.emit(boss.stats.health, boss.stats.stats.max_health)
	_say("THE FURROW IRON-MAN", "Scatter him: 25 Chimes now, he comes back angry in 10 minutes.\nCalm him: wear his posture down, hold blades, finish together.", KNEEL_GOLD)


## Host: his posture broke: he kneels (tests call this directly).
func force_kneel() -> void:
	if phase != Phase.FIGHTING:
		return
	if _engaged_at < 0.0:
		_begin()
	phase = Phase.KNEELING
	_window_left = KNEEL_SECONDS
	boss.stats.knockdown_time_left = KNEEL_SECONDS
	bearer = pick_bearer()
	CombatDirector.current.refill_ink(KNEEL_REFILL, boss.global_position, FINISHER_REACH + 6.0)
	kneeled.emit()
	_say("HE KNEELS!", "%s: light at his seal to HOLD BLADES!" % _name_of(bearer), KNEEL_GOLD)


## Host: the Lantern-Bearer rings the Amber Chime: blades held, the finisher's beats begin.
func ring_chime(by: StringName) -> void:
	if phase != Phase.KNEELING:
		return
	phase = Phase.AMBER
	boss.stats.health_locked = true
	_set_amber(true)
	_window_left = maxf(_window_left, float(_finisher_beats()) * BEAT_SECONDS + 1.0)
	_beats_left = _finisher_beats()
	_beat_left = 0.0
	chime_rung.emit(by)
	AudioCues.play(&"bell")
	_say("HOLD BLADES!", "The Amber Chime rings: everyone, light at his seal for DEEP-INK (2 Ink-Drops)", AMBER)
	_check_all_poured()


## Host: a hero poured Deep-Ink at his seal.
func pour(by: StringName) -> void:
	if phase != Phase.AMBER or poured.has(by):
		return
	poured[by] = true
	CombatDirector.current.show_float_text(boss.global_position + Vector3.UP * (boss.body_height() + 0.8), "✒ %s" % _name_of(by), KNEEL_GOLD, 30)
	_check_all_poured()


func _check_all_poured() -> void:
	if phase != Phase.AMBER:
		return
	for member: ActorBase in heroes_in_reach():
		if not poured.has(member.player_id):
			return
	if poured.is_empty():
		return
	# Every hero in reach wrote a stroke: the seal turns upright and he is calmed.
	if boss.spectrum != null:
		boss.spectrum.turn_seal_upright()
	boss.calming.calm_entity(bearer)


## The heroes who must pour: standing, within reach of him (companions included).
func heroes_in_reach() -> Array[ActorBase]:
	var found: Array[ActorBase] = []
	for member: ActorBase in CombatDirector.current.alive_party():
		if member.global_position.distance_to(boss.global_position) <= FINISHER_REACH + boss.body_radius():
			found.append(member)
	return found


## Who holds the chime: the party's Lantern-Bearer (a seated player first, then a
## companion Mender), else the hero with the most Ink-Drops.
func pick_bearer() -> StringName:
	var lantern: StringName = Callings.FELLOWSHIP_CLASSES[2]
	var companion_bearer: StringName = &""
	var best: StringName = &""
	var best_drops: int = -1
	for member: ActorBase in heroes_in_reach():
		var class_id: StringName = member.loadout.class_id if member.loadout != null else &""
		if class_id == lantern:
			if not member.is_companion:
				return member.player_id
			if companion_bearer == &"":
				companion_bearer = member.player_id
		if member.stats.resonance_pips() > best_drops:
			best_drops = member.stats.resonance_pips()
			best = member.player_id
	return companion_bearer if companion_bearer != &"" else best


func _bearer_is_companion() -> bool:
	var actor: ActorBase = CombatDirector.current.get_actor(bearer)
	return actor != null and actor.is_companion


func _finisher_beats() -> int:
	var beats: int = FINISHER_BEATS
	for member: ActorBase in heroes_in_reach():
		if member.input != null and member.input.assist_mode == InputComponent.AssistMode.SQUIRE_GAMBIT:
			return beats + SQUIRE_EXTRA_BEATS
	return beats


## The window ran out: he stands, half his posture back; the strokes drawn stay.
func _missed() -> void:
	phase = Phase.FIGHTING
	boss.stats.health_locked = false
	_set_amber(false)
	boss.stats.knockdown_time_left = 0.0
	boss.stats.poise = boss.stats.stats.max_poise * MISSED_POSTURE
	boss.stats.poise_changed.emit(boss.stats.poise, boss.stats.stats.max_poise)
	_say("HE'S UP", "Alf-Wright: Once more. You were close.", Color(0.86, 0.86, 0.84))


func _resolve(branch: StringName) -> void:
	phase = Phase.RESOLVED
	boss.stats.health_locked = false
	_set_amber(false)
	var took: float = CombatDirector.game_time() - _engaged_at if _engaged_at >= 0.0 else 0.0
	var stag: bool = branch == BRANCH_STAG
	outcome = {"encounter": String(boss_id), "branch": String(branch), "seconds": snappedf(took, 0.1), "heroes": heroes_at_start,
		"scrap": STAG_SCRAP if stag else RABBIT_SCRAP, "world_buff": STAG_WORLD_BUFF if stag else 0, "hazard": 0 if stag else RABBIT_HAZARD,
		"net_utility": STAG_NET if stag else RABBIT_NET, "unix": int(Time.get_unix_time_from_system())}
	if stag and PartyProgress.current != null:
		# A scatter's Scrap is the guardian's scatter_chimes (CalmingComponent.on_scattered).
		PartyProgress.current.award_chimes(STAG_SCRAP)
	if QuestManager.current != null:
		QuestManager.current.record_stag_hunt(outcome)
		if stag:
			QuestManager.current.report(QuestStepResource.Kind.BOSS_OUTCOME, boss_id)
	if stag:
		_say("THE IRON-MAN WAKES", "MEND. MEND THE BRIDGE.\n+120 World Buff: the bridge mended, +10% speed for 15 minutes", KNEEL_GOLD)
	else:
		_say("SCATTERED", "Alf-Wright: He'll rise again, rusty and cross. Ten minutes, I'd say.", Color(0.8, 0.6, 0.5))
	resolved.emit(branch, outcome)


# --- Showing it on every peer -----------------------------------------------------------

func _say(title: String, line: String, color: Color) -> void:
	if NetworkManager.current.is_online():
		_show_banner.rpc(title, line, color)
	else:
		_show_banner(title, line, color)


@rpc("authority", "call_local", "reliable")
func _show_banner(title: String, line: String, color: Color) -> void:
	var level: LevelBase = get_tree().current_scene as LevelBase if is_inside_tree() else null
	if level == null:
		return
	for hud: PlayerHUD in level.huds.values():
		hud.show_banner(title, line, color, BANNER_TIME)


func _set_amber(on: bool) -> void:
	if NetworkManager.current.is_online():
		_amber_remote.rpc(on)
	else:
		_amber_remote(on)


@rpc("authority", "call_local", "reliable")
func _amber_remote(on: bool) -> void:
	if boss != null and is_instance_valid(boss):
		boss.amber = on


## The Metronome Pendulum: one swing a beat over his head, counting down.
func _pendulum(beats_left: int) -> void:
	var swing: String = "◜ ♪" if beats_left % 2 == 0 else "♪ ◝"
	CombatDirector.current.announce(boss.global_position + Vector3.UP * (boss.body_height() + 1.2), "%s %d" % [swing, beats_left + 1], AMBER)


func _name_of(player_id: StringName) -> String:
	var actor: ActorBase = CombatDirector.current.get_actor(player_id)
	return actor.display_name() if actor != null else "The Lantern-Bearer"
