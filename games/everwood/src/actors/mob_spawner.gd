## A spawn point for wild creatures (13_STARTING_ZONE_ENCOUNTER_DESIGN.md §1):
## the pack it grows (by Bestiary id), the leash they keep to (18–25 m in the
## open), and their respawn (45–90 s after one falls). One in a fight calls the
## rest of its pack. A patrolling creature (the Crag-Back Cairn-Drake) walks
## `patrol` round the High Road. Placed in an Oakshire Vale landblock by
## tools/build_oakshire_vale.gd; its creatures stream in and out with it.
##
## Every peer grows the same pack in the same order, so node paths match for
## the network; the host runs them and tells the others when one regrows.
class_name MobSpawner
extends Node3D

## Where the pack stands round its spot.
const PACK_SPREAD: float = 2.6

## Shown in tests and telemetry ("Quarry-Wick").
@export var territory: String = ""
## Bestiary variant ids, one per creature, in spawn order.
@export var variant_ids: Array[StringName] = []
@export var leash: float = 20.0
## Seconds before a fallen creature regrows, at random between the two.
@export var respawn_time: Vector2 = Vector2(45.0, 90.0)
## A patroller's round (world positions).
@export var patrol: PackedVector3Array = PackedVector3Array()

var mobs: Array[WildMob] = []
## One of the pack is fighting.
var alert: bool = false

var _respawn_left: Array[float] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Grows the pack. The level calls this when the landblock streams in (after
## CombatDirector is ready for the instance).
func spawn_mobs() -> void:
	if not mobs.is_empty():
		return
	_rng.seed = hash(String(get_path()))
	for index: int in variant_ids.size():
		mobs.append(null)
		_respawn_left.append(-1.0)
		_spawn(index)


func _spawn(index: int) -> void:
	var chosen: MobVariantResource = Bestiary.variant(variant_ids[index])
	if chosen == null:
		push_warning("MobSpawner %s: no creature %s" % [name, variant_ids[index]])
		return
	var mob: WildMob = WildMob.new()
	mob.name = "Mob%d" % (index + 1)
	mob.variant = chosen
	mob.spawner = self
	mob.player_id = StringName("%s_mob_%d" % [String(name).to_snake_case(), index + 1])
	mob.loadout = Bestiary.loadout(chosen)
	mob.set_multiplayer_authority(1)
	var angle: float = TAU * float(index) / maxf(1.0, variant_ids.size())
	var spread: float = 0.0 if variant_ids.size() == 1 else PACK_SPREAD
	var spot: Vector3 = global_position + Vector3(cos(angle), 0.0, sin(angle)) * spread
	spot.y = WorldGridConfig.layout.sample_height(spot.x, spot.z) + 0.05
	add_child(mob)
	mob.spawn_at(Transform3D(Basis(Vector3.UP, angle + PI), spot))
	mobs[index] = mob


func standing_count() -> int:
	var standing: int = 0
	for mob: WildMob in mobs:
		if is_instance_valid(mob) and not mob.stats.is_downed:
			standing += 1
	return standing


func _physics_process(delta: float) -> void:
	if mobs.is_empty():
		return
	var fighting: bool = false
	for mob: WildMob in mobs:
		fighting = fighting or (is_instance_valid(mob) and mob.is_engaged())
	alert = fighting
	if not NetworkManager.current.is_host():
		return
	for index: int in mobs.size():
		var mob: WildMob = mobs[index]
		if not is_instance_valid(mob) or not mob.stats.is_downed:
			continue
		if _respawn_left[index] < 0.0:
			_respawn_left[index] = _rng.randf_range(respawn_time.x, respawn_time.y)
		_respawn_left[index] -= delta
		if _respawn_left[index] <= 0.0 and mob.has_faded():
			_respawn_left[index] = -1.0
			_regrow(index)
			for peer_id: int in InstanceManager.current.live_remote_peers():
				_regrow.rpc_id(peer_id, index)


## A fallen creature's body goes and a fresh one grows in its place (same name, so paths still match).
@rpc("authority", "call_remote", "reliable")
func _regrow(index: int) -> void:
	if index < 0 or index >= mobs.size():
		return
	var old: WildMob = mobs[index]
	if is_instance_valid(old):
		remove_child(old)
		old.queue_free()
	_spawn(index)
