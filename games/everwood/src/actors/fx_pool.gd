## Keeps finished effects (projectiles, card invocations, footprints) for reuse
## instead of freeing and rebuilding them. It lives under a level's Effects
## node and every effect it ever made is its child, so they are all freed with
## the level: nothing outlives an instance, and nothing is orphaned.
class_name FxPool
extends Node3D

## Kind -> sleeping effects of that kind.
var _idle: Dictionary[StringName, Array] = {}
## Effects built so far (a steady number means reuse is working).
var made_count: int = 0


## A ready effect of `kind`: a sleeping one woken up, or a new one from `make`.
func take(kind: StringName, make: Callable) -> PooledFx:
	var sleeping: Array = _idle.get(kind, [])
	while not sleeping.is_empty():
		var candidate: PooledFx = sleeping.pop_back() as PooledFx
		if is_instance_valid(candidate):
			candidate.wake()
			return candidate
	var fresh: PooledFx = make.call() as PooledFx
	fresh.pool = self
	fresh.pool_kind = kind
	add_child(fresh)
	made_count += 1
	fresh.wake()
	return fresh


func give_back(fx: PooledFx) -> void:
	fx.sleep()
	if not _idle.has(fx.pool_kind):
		_idle[fx.pool_kind] = []
	_idle[fx.pool_kind].append(fx)


## Effects of every kind currently out playing.
func active_count() -> int:
	var count: int = 0
	for child: Node in get_children():
		var fx: PooledFx = child as PooledFx
		if fx != null and fx.in_use:
			count += 1
	return count


func idle_count() -> int:
	var count: int = 0
	for sleeping: Array in _idle.values():
		count += sleeping.size()
	return count
