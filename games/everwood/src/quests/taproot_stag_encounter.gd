## Q05's boss in the Taproot Hall (docs/28 §7.4; docs/29 §5): the Blighted
## Taproot Stag, bound to the taproot by four rusted chains Nokes's workmen
## hammered in. No scatter here: while a chain holds, its health never falls
## under a tenth. The only way through is the calm.
##
##   Each time its posture breaks it kneels (8 s) and the next chain glows. A
##   heavy blow breaks a glowing chain: one from a two-handed weapon carrying
##   the Breaching Seal (Q02's bench), three from a one-hand weapon with it,
##   six without. Chains in order: left foreleg, right foreleg, antlers, chest.
##   Phase 1, Bound: chains 1 and 2. Root-spikes (a red circle) and the
##   Chain-Rattle Charge (a gold soak on the farthest hero).
##   Phase 2, Forging Fog: chain 3. Every 20 s the fog finds a hero and greys
##   one or two of their card sockets over for 15 s (CardFog). The Hearth-
##   Brazier's Hearth-Ward (2 Ink-Drops) clears the fog of everyone within 4 m
##   and keeps it off them for 6 s.
##   Phase 3, the Taproot: chain 4, with Root-Lurkers bursting from the walls.
##   The Naming: the chest chain gone, it sinks down and every hero in reach
##   pours 3 Ink-Drops at the taproot before the beats run out. Its name stands
##   whole (ELDERHART) and it is calmed. Missed, it stands with 60% posture and
##   the next break brings the Naming back.
class_name TaprootStagEncounter
extends Node

signal chain_broken(index: int)
signal phase_changed(phase: int)
signal resolved

enum Phase { BOUND, FOG, TAPROOT, NAMING, RESOLVED }

const CHAINS: int = 4
const CHAIN_NAMES: Array[String] = ["left foreleg", "right foreleg", "antlers", "chest"]
## A chain breaks at this much: a two-hand Breaching heavy gives all of it, a one-hand Breaching heavy a third, a bare heavy a sixth.
const CHAIN_STRENGTH: int = 6
const BREACH_TWO_HAND: int = 6
const BREACH_ONE_HAND: int = 2
const BARE_HEAVY: int = 1
const KNEEL_SECONDS: float = 8.0
const HEALTH_FLOOR: float = 0.10
const FOG_EVERY: float = 20.0
const FOG_SECONDS: float = 15.0
const FOG_SQUIRE_SECONDS: float = 5.0
const WARD_RADIUS: float = 4.0
const WARD_PROOF: float = 6.0
const WARD_DROPS: int = 2
const NAMING_DROPS: int = 3
const NAMING_BEATS: int = 5
const NAMING_MISSED_POSTURE: float = 0.6
const NAMING_REACH: float = 12.0
const KNEEL_REFILL: int = 2
const SPIKE_EVERY: float = 9.0
const SOAK_EVERY: float = 15.0
const SPIKE_RADIUS: float = 3.0
const SPIKE_CAST: float = 1.5
const SPIKE_DAMAGE: float = 18.0
const SOAK_RADIUS: float = 3.0
const SOAK_CAST: float = 2.0
const SOAK_DAMAGE: float = 40.0
const TRUE_NAME: String = "ELDERHART"
const GOLD: Color = Color(1.0, 0.84, 0.42)
const FOG_GREY: Color = Color(0.72, 0.72, 0.7)
const BANNER_TIME: float = 3.5

var boss: WildMob
var boss_id: StringName = &""
var phase: Phase = Phase.BOUND
var chains_broken: int = 0
## The glowing chain's strength spent so far.
var chain_damage: int = 0
var kneeling: bool = false
var naming_point: QuestInteractable
var brazier: QuestInteractable
## Heroes who have poured for the Naming.
var named_by: Dictionary[StringName, bool] = {}
## Hero -> game time their Hearth-Ward proof lasts until.
var ward_proof: Dictionary[StringName, float] = {}
## The hall's spots (set by the Root-Sanctum): its middle, where the brazier stands, where Lurkers burst out.
var hall_centre: Vector3 = Vector3.ZERO
var brazier_at: Vector3 = Vector3.ZERO
var lurker_spots: PackedVector3Array = PackedVector3Array()

var _kneel_left: float = 0.0
var _fog_left: float = FOG_EVERY
var _spike_left: float = SPIKE_EVERY
var _soak_left: float = SOAK_EVERY
var _beat_left: float = 0.0
var _beats_left: int = 0
var _lurkers: MobSpawner
var _chain_meshes: Array[MeshInstance3D] = []
var _rust: Material = StorybookMaterial.make(Color(0.5, 0.32, 0.22))
var _hot: Material = CalderaKit.glow(Color(1.0, 0.94, 0.8), 2.4)
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


static func of(actor: ActorBase) -> TaprootStagEncounter:
	return actor.get_node_or_null(^"TaprootStagEncounter") as TaprootStagEncounter if actor != null else null


func setup(stag: WildMob, encounter_boss_id: StringName, centre: Vector3, brazier_spot: Vector3, lurkers: PackedVector3Array) -> void:
	boss = stag
	boss_id = encounter_boss_id
	hall_centre = centre
	brazier_at = brazier_spot
	lurker_spots = lurkers
	name = "TaprootStagEncounter"
	_rng.seed = 2611


func _ready() -> void:
	boss.stats.health_floor = boss.stats.stats.max_health * HEALTH_FLOOR
	naming_point = QuestInteractable.new()
	naming_point.name = "NamingSeal"
	naming_point.prompt = "light: the NAMING SEAL, say its name together"
	naming_point.drop_cost = NAMING_DROPS
	naming_point.reach = boss.body_radius() + 4.0
	naming_point.available = func() -> bool: return phase == Phase.NAMING
	naming_point.who = func(actor: ActorBase) -> bool: return not named_by.has(actor.player_id)
	naming_point.on_used = pour_name
	boss.add_child.call_deferred(naming_point)
	brazier = QuestInteractable.new()
	brazier.name = "HearthBrazier"
	brazier.prompt = "light: HEARTH-WARD, clear the fog round the brazier"
	brazier.drop_cost = WARD_DROPS
	brazier.reach = 3.0
	brazier.available = func() -> bool: return phase != Phase.RESOLVED
	brazier.on_used = hearth_ward
	brazier.position = brazier_at
	_hall().add_child.call_deferred(brazier)
	CombatDirector.current.hit_resolved.connect(_on_hit_resolved)
	for index: int in CHAINS:
		var link: MeshInstance3D = ShapeKit.cylinder("Chain%d" % index, 0.12, 0.12, 1.0, Vector3.ZERO, _rust, 6)
		link.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_parent().add_child.call_deferred(link)
		_chain_meshes.append(link)


func _physics_process(delta: float) -> void:
	_draw_chains()
	if boss == null or not is_instance_valid(boss) or not NetworkManager.current.is_host() or phase == Phase.RESOLVED:
		return
	if boss.stats.is_downed:
		_resolve()
		return
	if not boss.is_engaged() and not kneeling and phase != Phase.NAMING:
		return
	if phase == Phase.NAMING:
		boss.stats.knockdown_time_left = maxf(boss.stats.knockdown_time_left, 0.5)
		_beat_left -= delta
		if _beat_left <= 0.0:
			_beat_left = StagHuntEncounter.BEAT_SECONDS
			_beats_left -= 1
			CombatDirector.current.announce(boss.global_position + Vector3.UP * (boss.body_height() + 1.2), "♪ %d" % maxi(0, _beats_left + 1), GOLD)
			if _beats_left < 0:
				_naming_missed()
		return
	if kneeling:
		boss.stats.knockdown_time_left = maxf(boss.stats.knockdown_time_left, 0.5)
		_kneel_left -= delta
		if _kneel_left <= 0.0:
			kneeling = false
			boss.stats.knockdown_time_left = 0.0
	elif boss.stats.is_knocked_down():
		force_kneel()
	_attacks(delta)


## Host: its posture broke: it kneels and the next chain glows (tests call this directly).
func force_kneel() -> void:
	if kneeling or phase == Phase.NAMING or phase == Phase.RESOLVED:
		return
	if chains_broken >= CHAINS:
		_begin_naming()
		return
	kneeling = true
	_kneel_left = KNEEL_SECONDS
	chain_damage = 0
	boss.stats.knockdown_time_left = KNEEL_SECONDS
	CombatDirector.current.refill_ink(KNEEL_REFILL, boss.global_position, NAMING_REACH + 8.0)
	_say("IT KNEELS!", "Alf-Wright: There! The %s chain is glowing. Hit the chain, not the stag!" % CHAIN_NAMES[chains_broken], GOLD)


## Host: a heavy blow on the glowing chain: `weapon_type` is the striker's, `breaching` whether they carry the Breaching Seal.
func strike_chain(weapon_type: int, breaching: bool) -> void:
	if not kneeling or chains_broken >= CHAINS:
		return
	var two_hand: bool = weapon_type == EquipmentItemResource.WeaponType.HEAVY_AXE or weapon_type == EquipmentItemResource.WeaponType.STAFF
	chain_damage += (BREACH_TWO_HAND if two_hand else BREACH_ONE_HAND) if breaching else BARE_HEAVY
	if chain_damage < CHAIN_STRENGTH:
		return
	chains_broken += 1
	chain_damage = 0
	kneeling = false
	boss.stats.knockdown_time_left = 0.0
	chain_broken.emit(chains_broken - 1)
	CombatDirector.current.announce(boss.global_position + Vector3.UP * (boss.body_height() + 0.8), "THE %s CHAIN SHATTERS" % CHAIN_NAMES[chains_broken - 1].to_upper(), GOLD, &"bell")
	match chains_broken:
		2:
			_set_phase(Phase.FOG)
			_say("FORGING FOG", "Alf-Wright: Fog forgets. A hearth remembers. Stay close to the brazier.", FOG_GREY)
		3:
			_set_phase(Phase.TAPROOT)
			_raise_lurkers()
		4:
			boss.stats.health_floor = 0.0
			_begin_naming()


func _begin_naming() -> void:
	_set_phase(Phase.NAMING)
	boss.stats.health_locked = true
	boss.stats.knockdown_time_left = KNEEL_SECONDS
	_beats_left = NAMING_BEATS
	_beat_left = 0.0
	_say("THE NAMING", "Alf-Wright: Read it off the root. Say it like you'd wake a friend.\nEveryone: light at the taproot (3 Ink-Drops)", GOLD)
	_check_named()


## Host: a hero poured for the Naming.
func pour_name(by: StringName) -> void:
	if phase != Phase.NAMING or named_by.has(by):
		return
	named_by[by] = true
	_check_named()


func _check_named() -> void:
	if phase != Phase.NAMING or named_by.is_empty():
		return
	for member: ActorBase in CombatDirector.current.alive_party():
		if member.global_position.distance_to(boss.global_position) <= NAMING_REACH and not named_by.has(member.player_id):
			return
	boss.calming.calm_entity(named_by.keys()[0])


func _naming_missed() -> void:
	_set_phase(Phase.TAPROOT)
	named_by.clear()
	boss.stats.health_locked = false
	boss.stats.knockdown_time_left = 0.0
	boss.stats.poise = boss.stats.stats.max_poise * NAMING_MISSED_POSTURE
	boss.stats.poise_changed.emit(boss.stats.poise, boss.stats.stats.max_poise)
	_say("IT RISES", "Alf-Wright: Not yet. Break it once more and say it together.", FOG_GREY)


func _exit_tree() -> void:
	var director: CombatDirector = CombatDirector.current
	if director != null and director.hit_resolved.is_connected(_on_hit_resolved):
		director.hit_resolved.disconnect(_on_hit_resolved)
	# The hall's pieces belong to this fight: the brazier and the Taproot's lurkers go with it.
	if is_instance_valid(brazier):
		brazier.queue_free()
	if is_instance_valid(_lurkers):
		_lurkers.despawn_mobs()
		_lurkers.queue_free()


## Host: a heavy blow on the kneeling stag lands on its glowing chain.
func _on_hit_resolved(event: CombatEvent, _outcome: int) -> void:
	if not kneeling or not NetworkManager.current.is_host() or boss == null or not is_instance_valid(boss):
		return
	if boss.get_node_or_null(event.target_path) != boss:
		return
	var heavy: Array[int] = [CombatActionResource.Command.HEAVY, CombatActionResource.Command.FORWARD_HEAVY, CombatActionResource.Command.BACK_HEAVY]
	if not heavy.has(event.command):
		return
	var striker: ActorBase = CombatDirector.current.get_actor(event.attacker_player_id)
	var weapon_type: int = EquipmentItemResource.WeaponType.LIGHT_SWORD
	if striker != null and striker.loadout != null and striker.loadout.kit != null:
		var weapon: EquipmentItemResource = ArsenalCatalog.current.item(striker.loadout.kit.weapon_id)
		if weapon != null:
			weapon_type = weapon.weapon_type
	var breaching: bool = QuestManager.current != null and QuestManager.current.has_unlock(ActOneQuests.UNLOCK_BREACHING_SEAL)
	strike_chain(weapon_type, breaching)


## Host: the Hearth-Brazier's ward: everyone within its reach is cleared of fog and kept clear a while.
func hearth_ward(_by: StringName) -> void:
	var cleared: Array[String] = []
	for member: ActorBase in CombatDirector.current.alive_party():
		if Vector2(member.global_position.x - brazier.global_position.x, member.global_position.z - brazier.global_position.z).length() <= WARD_RADIUS + brazier.reach:
			ward_proof[member.player_id] = CombatDirector.game_time() + WARD_PROOF
			cleared.append(String(member.player_id))
	_ward_everywhere(PackedStringArray(cleared))
	CombatDirector.current.announce(brazier.global_position + Vector3.UP * 2.6, "HEARTH-WARD: into the light!", Color(0.5, 1.0, 0.6), &"heal")


## Host: the fog finds a hero (tests call this with a hero).
func fog_hero(member: ActorBase) -> void:
	if member == null or float(ward_proof.get(member.player_id, 0.0)) > CombatDirector.game_time():
		return
	var sockets: Array[int] = [GrimoireRules.SOCKET_L, GrimoireRules.SOCKET_R, GrimoireRules.SOCKET_LR]
	var picked: Array[int] = [sockets[_rng.randi_range(0, 2)]]
	if _rng.randf() < 0.5:
		var other: int = sockets[_rng.randi_range(0, 2)]
		if not picked.has(other):
			picked.append(other)
	var squire: bool = member.input != null and member.input.assist_mode == InputComponent.AssistMode.SQUIRE_GAMBIT
	_fog_everywhere(String(member.player_id), PackedInt32Array(picked), FOG_SQUIRE_SECONDS if squire else FOG_SECONDS)
	CombatDirector.current.announce(member.global_position + Vector3.UP * 2.6, "FOGGED: a card greys over", FOG_GREY, &"refuse")


func _attacks(delta: float) -> void:
	var party: Array[ActorBase] = []
	for member: ActorBase in CombatDirector.current.alive_party():
		if member.global_position.distance_to(hall_centre) <= 30.0:
			party.append(member)
	if party.is_empty():
		return
	_spike_left -= delta
	if _spike_left <= 0.0:
		_spike_left = SPIKE_EVERY * (0.8 if phase == Phase.TAPROOT else 1.0)
		var under: ActorBase = party[_rng.randi_range(0, party.size() - 1)]
		_telegraph(RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT, under.global_position, SPIKE_RADIUS, SPIKE_CAST)
	_soak_left -= delta
	if _soak_left <= 0.0:
		_soak_left = SOAK_EVERY * (0.8 if phase == Phase.TAPROOT else 1.0)
		var farthest: ActorBase = party[0]
		for member: ActorBase in party:
			if member.global_position.distance_to(boss.global_position) > farthest.global_position.distance_to(boss.global_position):
				farthest = member
		_telegraph(RaidTelegraphDecal.Kind.GOLD_PARTY_SOAK, farthest.global_position, SOAK_RADIUS, SOAK_CAST)
	if phase == Phase.FOG or phase == Phase.TAPROOT:
		_fog_left -= delta
		if _fog_left <= 0.0:
			_fog_left = FOG_EVERY
			fog_hero(party[_rng.randi_range(0, party.size() - 1)])


func _telegraph(kind: RaidTelegraphDecal.Kind, at: Vector3, radius: float, cast: float) -> void:
	if NetworkManager.current.is_online():
		_cast_decal.rpc(int(kind), at, radius, cast)
	else:
		_cast_decal(int(kind), at, radius, cast)


@rpc("authority", "call_local", "reliable")
func _cast_decal(kind: int, at: Vector3, radius: float, cast: float) -> void:
	var root: Node3D = CombatDirector.current.effects_root
	if root == null or not root.is_inside_tree():
		return
	var decal: RaidTelegraphDecal = RaidTelegraphDecal.new()
	decal.configure(kind as RaidTelegraphDecal.Kind, radius, cast, null)
	root.add_child(decal)
	decal.global_position = at
	AudioCues.play(&"telegraph", 1.1)
	if NetworkManager.current.is_host():
		decal.resolved.connect(_on_decal_resolved)


func _on_decal_resolved(decal: RaidTelegraphDecal, inside: Array[ActorBase]) -> void:
	if boss == null or not is_instance_valid(boss) or boss.stats.is_downed or inside.is_empty():
		return
	var share: float = SOAK_DAMAGE / float(inside.size()) if decal.kind == RaidTelegraphDecal.Kind.GOLD_PARTY_SOAK else SPIKE_DAMAGE
	for member: ActorBase in inside:
		var event: CombatEvent = CombatEvent.new()
		event.kind = CombatEvent.Kind.STRIKE
		event.attacker_path = boss.get_path()
		event.target_path = member.get_path()
		event.attacker_player_id = boss.player_id
		event.damage = share
		event.poise_damage = 10.0
		event.origin = decal.global_position
		CombatDirector.current.deliver(event)


func _raise_lurkers() -> void:
	if lurker_spots.is_empty() or _lurkers != null:
		return
	_lurkers = MobSpawner.new()
	_lurkers.name = "HallLurkers"
	var ids: Array[StringName] = []
	for _spot: Vector3 in lurker_spots:
		ids.append(Bestiary.ROOT_LURKER)
	_lurkers.variant_ids = ids
	_lurkers.leash = 30.0
	_lurkers.respawn_time = Vector2(1.0e9, 1.0e9)
	_lurkers.own_floor = true
	_lurkers.position = lurker_spots[0]
	_hall().add_child(_lurkers)
	_lurkers.spawn_mobs()


## What the hall's pieces hang from: the Sanctum (the Stag's spawner's parent, at the isle's origin).
func _hall() -> Node:
	if boss != null and boss.spawner != null and boss.spawner.get_parent() != null:
		return boss.spawner.get_parent()
	return get_parent()


func _resolve() -> void:
	_set_phase(Phase.RESOLVED)
	boss.stats.health_locked = false
	if QuestManager.current != null and boss.calming != null and boss.calming.was_calmed:
		QuestManager.current.report(QuestStepResource.Kind.BOSS_OUTCOME, boss_id)
		QuestManager.current.record_stag_hunt({"encounter": String(boss_id), "branch": String(StagHuntEncounter.BRANCH_STAG), "chains": chains_broken,
			"heroes": named_by.size(), "unix": int(Time.get_unix_time_from_system())})
	_say(TRUE_NAME, "Its name stands whole. The grey blows off its hide; golden sap surges up the taproot.", GOLD)
	resolved.emit()


func _set_phase(next: Phase) -> void:
	if next == phase:
		return
	phase = next
	phase_changed.emit(int(next))


func _draw_chains() -> void:
	if boss == null or not is_instance_valid(boss) or _chain_meshes.is_empty():
		return
	for index: int in _chain_meshes.size():
		var link: MeshInstance3D = _chain_meshes[index]
		if not link.is_inside_tree():
			continue
		link.visible = index >= chains_broken and phase != Phase.RESOLVED
		if not link.visible:
			continue
		var angle: float = TAU * float(index) / float(CHAINS) + 0.4
		var from: Vector3 = boss.global_position + Vector3(cos(angle) * boss.body_radius(), 0.9 + 0.5 * float(index), sin(angle) * boss.body_radius())
		var to: Vector3 = hall_centre + Vector3(cos(angle) * 1.2, 1.4, sin(angle) * 1.2)
		var span: Vector3 = to - from
		if span.length() < 0.1:
			continue
		link.global_position = (from + to) * 0.5
		link.global_basis = Basis(Quaternion(Vector3.UP, span.normalized())) * Basis.from_scale(Vector3(1.0, span.length(), 1.0))
		var glowing: bool = kneeling and index == chains_broken
		link.material_override = _hot if glowing else _rust


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


func _fog_everywhere(player_id: String, sockets: PackedInt32Array, seconds: float) -> void:
	if NetworkManager.current.is_online():
		_fog_remote.rpc(player_id, sockets, seconds)
	else:
		_fog_remote(player_id, sockets, seconds)


@rpc("authority", "call_local", "reliable")
func _fog_remote(player_id: String, sockets: PackedInt32Array, seconds: float) -> void:
	var picked: Array[int] = []
	for socket: int in sockets:
		picked.append(socket)
	CardFog.fog(StringName(player_id), picked, seconds)


func _ward_everywhere(player_ids: PackedStringArray) -> void:
	if NetworkManager.current.is_online():
		_ward_remote.rpc(player_ids)
	else:
		_ward_remote(player_ids)


@rpc("authority", "call_local", "reliable")
func _ward_remote(player_ids: PackedStringArray) -> void:
	for player_id: String in player_ids:
		CardFog.clear(StringName(player_id))
	if brazier != null and brazier.is_inside_tree():
		RecoveryBurst.bloom(brazier.get_parent(), brazier.global_position, WARD_RADIUS)
