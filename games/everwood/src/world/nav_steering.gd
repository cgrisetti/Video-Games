## Walking somewhere by the navigation map (ChunkNavBuilder): which way to
## head now to reach a goal, following a path around walls, banks and
## ledges, across chunk seams. Close goals, open ground with no mesh yet, and
## goals off the mesh (a Rune-Plate's edge) are walked to straight, as before.
## Companions and woodland minions each keep one.
class_name NavSteering
extends RefCounted

## Goals nearer than this are walked to directly.
const DIRECT_RANGE: float = 4.0
## A fresh path at most this often, or sooner if the goal moves this far.
const REPATH_TIME: float = 0.5
const REPATH_DISTANCE: float = 1.5
## A corner counts as reached this close (flat distance).
const CORNER_RADIUS: float = 0.7
## A path that starts further than this from the walker is no use (it's off the mesh).
const OFF_MESH: float = 2.0

var _path: PackedVector3Array = PackedVector3Array()
var _corner: int = 0
var _goal: Vector3 = Vector3.INF
var _repath_left: float = 0.0


## The flat unit direction toward `goal` for `walker` this tick (zero once there).
func direction(walker: Node3D, goal: Vector3, delta: float) -> Vector3:
	var straight: Vector3 = _flat(goal - walker.global_position)
	if straight.length() <= DIRECT_RANGE:
		_path = PackedVector3Array()
		return straight.normalized()
	_repath_left -= delta
	if _repath_left <= 0.0 or _goal.distance_to(goal) > REPATH_DISTANCE:
		_repath(walker, goal)
	while _corner < _path.size() and _flat(_path[_corner] - walker.global_position).length() <= CORNER_RADIUS:
		_corner += 1
	if _corner >= _path.size():
		return straight.normalized()
	return _flat(_path[_corner] - walker.global_position).normalized()


## Whether it's following a path right now (rather than walking straight).
func is_following_path() -> bool:
	return _corner < _path.size()


func _repath(walker: Node3D, goal: Vector3) -> void:
	_goal = goal
	_repath_left = REPATH_TIME
	_corner = 0
	_path = ChunkNavBuilder.path_between(walker.get_world_3d().navigation_map, walker.global_position, goal)
	if not _path.is_empty() and _flat(_path[0] - walker.global_position).length() > OFF_MESH:
		_path = PackedVector3Array()


static func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)
