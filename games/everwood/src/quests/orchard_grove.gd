## One of Q02's four groves in Lee-Shore Orchards (docs/28 §4.1, §4.3, §4.4):
## Root, Leaf, Flower or Seed. While Q02 asks for the groves, its clutch of
## Grey-Bark Weevils comes up and goes for the grove's oldest tree; calming the
## whole clutch while the tree stands clears it (a tree gnawed to nothing
## starts the grove again). Once every grove is clear, its Root-Shrine opens:
## each hero in reach pours Ink-Drops (3 apiece) and the shrine speaks
## Ael-Voran, the grove blooms and drops Living Cider-Resin.
##
## Its state is a saved mark (QuestManager.mark): 0 waiting, 1 clear, 2 lit.
class_name OrchardGrove
extends Node3D

const CLEAR: int = 1
const LIT: int = 2
## Ink-Drops a shrine needs from each hero in reach.
const DROPS_PER_HERO: int = 3
## Who counts as "in reach" of a shrine when it fills.
const SHRINE_REACH: float = 9.0
## Living Cider-Resin a lit shrine gives.
const RESIN_PER_SHRINE: int = 3
const BLOOM_RADIUS: float = 18.0
const SHRINE_GOLD: Color = Color(1.0, 0.82, 0.36)

var grove_id: StringName = &""
## The clutch: Bestiary ids, in spawn order.
var clutch: Array[StringName] = []
var tree: OrchardTree
var shrine: QuestInteractable
var spawner: MobSpawner

var _counted: Dictionary[int, bool] = {}
var _calms: int = 0
var _shrine_glow: MeshInstance3D


func setup(id: StringName, weevils: Array[StringName], oldest_tree: Vector3) -> void:
	grove_id = id
	clutch = weevils
	name = "Grove_%s" % String(id).trim_prefix("POI_Grove_")
	tree = OrchardTree.new()
	tree.name = "OldestTree"
	tree.position = oldest_tree - position
	add_child(tree)
	shrine = QuestInteractable.new()
	shrine.name = "RootShrine"
	shrine.prompt = "light: pour an Ink-Drop into the Root-Shrine (Ael-Voran)"
	shrine.drop_cost = 1
	shrine.reach = 2.8
	shrine.position = tree.position + Vector3(1.6, 0.0, 1.0)
	shrine.available = _shrine_open
	shrine.on_used = _on_poured
	add_child(shrine)
	var stone: MeshInstance3D = ShapeKit.cylinder("ShrineStone", 0.55, 0.7, 0.9, Vector3(0.0, 0.45, 0.0), StorybookMaterial.make(Color(0.46, 0.5, 0.42)), 10)
	shrine.add_child(stone)
	_shrine_glow = ShapeKit.no_shadow(ShapeKit.cylinder("CupMarks", 0.42, 0.42, 0.04, Vector3(0.0, 0.92, 0.0), CalderaKit.glow(SHRINE_GOLD, 1.6), 12))
	_shrine_glow.visible = false
	shrine.add_child(_shrine_glow)
	tree.felled.connect(_on_tree_felled)


func state() -> int:
	return QuestManager.current.mark(grove_id) if QuestManager.current != null else 0


## Whether Q02 wants this grove's weevils up now.
func wants_weevils() -> bool:
	var quests: QuestManager = QuestManager.current
	return quests != null and quests.is_on_step(ActOneQuests.Q02, &"groves") and state() < CLEAR


func _shrine_open() -> bool:
	var quests: QuestManager = QuestManager.current
	return quests != null and quests.is_on_step(ActOneQuests.Q02, &"shrines") and state() == CLEAR


func _physics_process(_delta: float) -> void:
	var wanted: bool = wants_weevils()
	tree.protected = wanted
	_shrine_glow.visible = state() == LIT or _shrine_open()
	if wanted and spawner == null:
		_raise_clutch()
	elif not wanted and spawner != null:
		_drop_clutch()
	if spawner == null or not NetworkManager.current.is_host():
		return
	for mob: WildMob in spawner.mobs:
		if not is_instance_valid(mob) or mob.calming == null or not mob.calming.was_calmed:
			continue
		var key: int = mob.get_instance_id()
		if _counted.has(key):
			continue
		_counted[key] = true
		_calms += 1
	if _calms >= clutch.size():
		_cleared()


func _raise_clutch() -> void:
	spawner = MobSpawner.new()
	spawner.name = "Weevils"
	spawner.territory = ActOnePlaces.display_name(grove_id)
	spawner.variant_ids = clutch
	spawner.leash = 24.0
	spawner.respawn_time = Vector2(20.0, 30.0)
	add_child(spawner)
	spawner.global_position = tree.global_position + Vector3(5.0, 0.0, 0.0)
	spawner.spawn_mobs()
	_counted.clear()
	_calms = 0


func _drop_clutch() -> void:
	if spawner != null:
		spawner.despawn_mobs()
		spawner.queue_free()
		spawner = null


## Host: the tree was gnawed to nothing: the grove starts again.
func _on_tree_felled(_tree: OrchardTree) -> void:
	if not NetworkManager.current.is_host() or spawner == null:
		return
	CombatDirector.current.announce(tree.global_position + Vector3.UP * 4.0, "THE TREE GOES GREY: the weevils come again", Color(0.7, 0.7, 0.66), &"refuse")
	_drop_clutch()


## Host: the whole clutch calmed with the tree standing.
func _cleared() -> void:
	if state() >= CLEAR:
		return
	_drop_clutch()
	QuestManager.current.set_mark(grove_id, CLEAR)
	CombatDirector.current.announce(tree.global_position + Vector3.UP * 4.0, "%s IS CLEAR" % ActOnePlaces.display_name(grove_id).to_upper(), SHRINE_GOLD, &"bell")
	QuestManager.current.report(QuestStepResource.Kind.EVENT, ActOneQuests.EVENT_GROVE_CLEARED)


## Host: a hero poured a drop; when every hero in reach has given their share, the shrine speaks.
func _on_poured(_by: StringName) -> void:
	var heroes: int = 0
	for member: ActorBase in CombatDirector.current.party_actors():
		if not member.stats.is_downed and member.global_position.distance_to(shrine.global_position) <= SHRINE_REACH:
			heroes += 1
	if shrine.poured_total() < DROPS_PER_HERO * maxi(1, heroes):
		return
	light_shrine()


## Host: Ael-Voran (tests call this directly).
func light_shrine() -> void:
	if state() != CLEAR:
		return
	QuestManager.current.set_mark(grove_id, LIT)
	shrine.poured.clear()
	CombatDirector.current.announce(shrine.global_position + Vector3.UP * 3.0, "AEL-VORAN", SHRINE_GOLD, &"bell")
	if NetworkManager.current.is_online():
		_bloom.rpc()
	else:
		_bloom()
	QuestManager.current.add_item(ActOneQuests.ITEM_LIVING_CIDER_RESIN, RESIN_PER_SHRINE)
	QuestManager.current.report(QuestStepResource.Kind.EVENT, ActOneQuests.EVENT_SHRINE_LIT)


@rpc("authority", "call_local", "reliable")
func _bloom() -> void:
	RecoveryBurst.bloom(self, tree.global_position, BLOOM_RADIUS)
