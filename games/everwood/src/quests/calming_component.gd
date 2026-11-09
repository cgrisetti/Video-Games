## The Act I calming rule on one foe (docs/29 §5; the brief's "Core Calming &
## Card Fuel Hook"), for every Bestiary kin with `calm_rule`:
##
##   Worn down, it wavers: its health under a quarter (WAVER_HEALTH) or its
##   posture broken (knocked down). A hero who walks up and presses light then
##   plays their Calming Seal on it instead of a swing (this is an Interactable,
##   so the HUD shows "light: CALM"). CalmEntity: the Recovery burst blooms, the
##   spirit is released, and the CombatDirector pays the calm as it always has
##   (Ink-Drops into the wells nearby, XP, Ink-Binding Marks) and the quests
##   count it.
##
##   Burnt to nothing instead, it only scatters (KillEntity in the brief's
##   words, though nothing is ever slain, Gate 3): a few Chimes, no Ink-Drops,
##   no XP, and its spawner grows it again.
##
## A Stag Hunt's guardian keeps the rule but is never offered the plain calm:
## its encounter calms it with the party's finisher (calm_entity).
##
## Why light and not the brief's "Seal card hit" or docs/28's held R: R's hold is
## the Sign-Flow's Hearth-Rite and only waits out of combat; light at a
## wavering foe is one button every hero already has (docs/29 §5).
class_name CalmingComponent
extends Interactable

signal calmed(by: StringName)
signal scattered

const WAVER_HEALTH: float = 0.25
## How far past its body a hero may stand to calm it.
const REACH_PAD: float = 1.8
const CALM_GOLD: Color = Color(1.0, 0.84, 0.4)
const SCATTER_GREY: Color = Color(0.7, 0.7, 0.68)
## The Recovery burst (docs/28 §3.5): a watercolour ring this wide, over this long.
const BURST_RADIUS: float = 6.0
const BURST_TIME: float = 1.5
const BURST_GREEN: Color = Color(0.46, 0.78, 0.34)

var mob: WildMob
## Offered the plain calm (a Stag Hunt guardian is not: its finisher calms it).
var offers_calm: bool = true
## Set the moment it is calmed (before it goes down), so the director pays a calm, not a scatter.
var was_calmed: bool = false
var calmed_by: StringName = &""


## The component on an actor, or null.
static func of(actor: ActorBase) -> CalmingComponent:
	if actor == null:
		return null
	return actor.get_node_or_null(^"CalmingComponent") as CalmingComponent


func setup(owner_mob: WildMob) -> void:
	mob = owner_mob
	name = "CalmingComponent"
	reach = owner_mob.body_radius() + REACH_PAD
	offers_calm = owner_mob.variant.rank != MobVariantResource.Rank.BOSS


func is_wavering() -> bool:
	if mob == null or mob.stats == null or mob.stats.is_downed or was_calmed:
		return false
	return mob.stats.health_ratio() < WAVER_HEALTH or mob.stats.is_knocked_down()


## Whether the party may calm yet: Q01 hands out the Calming Seal at Alf-Wright's
## word; a party that never began Act I (the older checks, the legacy maps) always may.
static func seal_in_hand() -> bool:
	var quests: QuestManager = QuestManager.current
	return quests == null or not quests.act_one_started() or quests.has_unlock(ActOneQuests.UNLOCK_CALMING_SEAL)


func _physics_process(delta: float) -> void:
	if not offers_calm or not is_wavering():
		_let_go()
		return
	super._physics_process(delta)


func prompt_for(_actor: ActorBase) -> String:
	if not seal_in_hand():
		return "%s wavers · speak to Master Alf-Wright for a Calming Seal" % mob.variant.display_name
	return "light: CALM the %s (Calming Seal)" % mob.variant.display_name


func interact(actor: ActorBase) -> void:
	if not seal_in_hand() or not is_wavering():
		return
	if NetworkManager.current.is_host():
		calm_entity(actor.player_id)
	else:
		_request_calm.rpc_id(1, String(actor.player_id))


@rpc("any_peer", "call_remote", "reliable")
func _request_calm(by: String) -> void:
	if multiplayer.is_server() and is_wavering():
		calm_entity(StringName(by))


## Host: CalmEntity. The burst on every peer, the quests' count, and the spirit
## released (the director pays Ink-Drops, XP and Marks as for any calm).
func calm_entity(by: StringName) -> void:
	if was_calmed or mob == null or mob.stats.is_downed:
		return
	was_calmed = true
	calmed_by = by
	_let_go()
	if NetworkManager.current.is_online():
		_show_burst.rpc()
	else:
		_show_burst()
	CombatDirector.current.announce(mob.global_position + Vector3.UP * (mob.body_height() + 0.6), "CALMED", CALM_GOLD, &"bell")
	if QuestManager.current != null:
		QuestManager.current.report(QuestStepResource.Kind.CALM, mob.variant.variant_id)
	calmed.emit(by)
	mob.stats.knock_out()


## Host: the director found it beaten without a calm: it scatters.
func on_scattered() -> void:
	if was_calmed:
		return
	_let_go()
	if mob.variant.scatter_chimes > 0 and PartyProgress.current != null:
		PartyProgress.current.award_chimes(mob.variant.scatter_chimes)
	CombatDirector.current.announce(mob.global_position + Vector3.UP * (mob.body_height() + 0.6), "SCATTERED", SCATTER_GREY, &"refuse")
	scattered.emit()


func _let_go() -> void:
	if CombatDirector.current == null:
		return
	for member: ActorBase in CombatDirector.current.party_actors():
		if member.interactable == self:
			member.interactable = null


@rpc("authority", "call_local", "reliable")
func _show_burst() -> void:
	if mob == null or not mob.is_inside_tree():
		return
	# Its grey cracks and washes off, its dog-roses open, and it shakes itself (docs/30 §5).
	mob.on_calm_burst()
	var holder: Node = mob.get_parent()
	if holder != null:
		RecoveryBurst.bloom(holder, mob.global_position, BURST_RADIUS)
