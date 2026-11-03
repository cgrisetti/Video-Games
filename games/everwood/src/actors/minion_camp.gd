## A Woodland Minion Camp on the Moss-Oaks trail (07_EXPEDITION_HUD_AND_ART_GDD.md
## §3, Zone 1): a ring of stones round a bramble nest, and the 3 or 4
## WoodlandMinions that sleep in it. The camp wakes when a player comes near or
## any of its minions is hurt, and settles again once the party has gone. When
## every minion is down it's cleared: the level pays the party a few Chimes.
##
## Every peer builds the camp and its minions from the same list, so their node
## paths match for the network; the host runs them and the others see copies.
## Waking and clearing are worked out on every peer from synced positions and
## health, so all agree. A cleared camp is remembered (WorldStateDB): when its
## Landblock streams back in, or a latecomer joins, it stays cleared and empty.
class_name MinionCamp
extends Node3D

signal cleared(camp: MinionCamp)

## A player this close wakes the camp...
const WAKE_RADIUS: float = 9.0
## ...and it settles once nobody standing is within its minions' leash.
const SETTLE_RADIUS: float = WoodlandMinion.LEASH_RADIUS
const SPAWN_RING_RADIUS: float = 2.2
const STONE_RING_RADIUS: float = 3.4
const STONES: int = 9
const STONE_COLOR: Color = Color(0.5, 0.5, 0.47)
const NEST_COLOR: Color = Color(0.3, 0.33, 0.18)

## Shown when it's cleared ("Bramble Hush-Crack").
@export var camp_name: String = "Bramble Hush-Crack"
## WoodlandMinion.Kind of each minion, in spawn order.
@export var kinds: Array[int] = []
## Its WorldStateDB id (10_WORLD_ARCHITECTURE.md §4.2); empty: not remembered.
@export var persist_id: StringName = &""

var minions: Array[WoodlandMinion] = []
var alert: bool = false
var is_cleared: bool = false
var persistence: WorldStateBinding


func _ready() -> void:
	_build_nest()


## Wakes its minions into the world. The level calls this from its setup, after
## CombatDirector is reset for the new instance (a child's _ready runs first,
## and the reset would forget anything registered before it).
func spawn_minions() -> void:
	if not minions.is_empty() or is_cleared:
		return
	for index: int in kinds.size():
		var minion: WoodlandMinion = WoodlandMinion.new()
		minion.name = "Minion%d" % (index + 1)
		minion.kind = kinds[index] as WoodlandMinion.Kind
		minion.camp = self
		minion.player_id = StringName("%s_minion_%d" % [String(name).to_snake_case(), index + 1])
		minion.loadout = ClassLoadouts.woodland_minion(kinds[index])
		minion.set_multiplayer_authority(1)
		add_child(minion)
		var angle: float = TAU * float(index) / kinds.size()
		var spot: Vector3 = global_position + Vector3(cos(angle), 0.0, sin(angle)) * SPAWN_RING_RADIUS
		minion.spawn_at(Transform3D(Basis(Vector3.UP, atan2(cos(angle), sin(angle))), spot))
		minions.append(minion)


func standing_count() -> int:
	var standing: int = 0
	for minion: WoodlandMinion in minions:
		if is_instance_valid(minion) and not minion.stats.is_downed:
			standing += 1
	return standing


func _physics_process(_delta: float) -> void:
	if is_cleared or minions.is_empty():
		return
	var near: bool = false
	var within_leash: bool = false
	for member: ActorBase in CombatDirector.current.alive_party():
		var distance: float = Vector2(member.global_position.x - global_position.x, member.global_position.z - global_position.z).length()
		near = near or distance <= WAKE_RADIUS
		within_leash = within_leash or distance <= SETTLE_RADIUS
	var hurt: bool = false
	for minion: WoodlandMinion in minions:
		if not minion.stats.is_downed and minion.stats.health < minion.stats.stats.max_health - 0.5:
			hurt = true
	if near or (hurt and within_leash):
		alert = true
	elif not within_leash:
		alert = false
	if standing_count() == 0:
		is_cleared = true
		alert = false
		if persistence != null:
			persistence.save({"cleared": true})
		cleared.emit(self)


## WorldStateDB hands over its line to the store, and the state on record applies at once.
func bind_persistence(binding: WorldStateBinding) -> void:
	persistence = binding
	apply_persisted_state(binding.current_state())


## A camp on record as cleared is cleared: no minions spawn and nothing pays out again.
func apply_persisted_state(state: Dictionary) -> void:
	if bool(state.get("cleared", false)) and not is_cleared:
		is_cleared = true
		alert = false


## Stones in a ring and a mound of brambles in the middle, built in code.
func _build_nest() -> void:
	var stone: Material = StorybookMaterial.make(STONE_COLOR)
	for index: int in STONES:
		var angle: float = TAU * float(index) / STONES + 0.2
		var mesh: SphereMesh = SphereMesh.new()
		mesh.radius = 0.32 + 0.08 * float(index % 3)
		mesh.height = mesh.radius * 1.3
		mesh.material = stone
		var node: MeshInstance3D = MeshInstance3D.new()
		node.name = "Stone%d" % index
		node.mesh = mesh
		node.position = Vector3(cos(angle), 0.12, sin(angle)) * STONE_RING_RADIUS
		add_child(node)
	var nest: Material = StorybookMaterial.make(NEST_COLOR)
	for index: int in 4:
		var mesh: SphereMesh = SphereMesh.new()
		mesh.radius = 0.55 - 0.08 * index
		mesh.height = mesh.radius * 1.2
		mesh.material = nest
		var node: MeshInstance3D = MeshInstance3D.new()
		node.name = "Bramble%d" % index
		node.mesh = mesh
		node.position = Vector3(cos(index * 1.7) * 0.4, 0.2 + 0.1 * index, sin(index * 1.7) * 0.4)
		add_child(node)
