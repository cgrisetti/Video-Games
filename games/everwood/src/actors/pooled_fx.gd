## An effect an FxPool can hand out again (a projectile, a card invocation, a
## footprint). It never frees itself: finish() hands it back to its pool, which
## hides it and stops it processing until the next time it's needed.
class_name PooledFx
extends Node3D

var pool: FxPool
var pool_kind: StringName = &""
var in_use: bool = false


func wake() -> void:
	in_use = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT


func sleep() -> void:
	in_use = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


## Done: back to the pool (or freed, if it was made without one).
func finish() -> void:
	if not in_use:
		return
	if is_instance_valid(pool):
		pool.give_back(self)
	else:
		queue_free()
