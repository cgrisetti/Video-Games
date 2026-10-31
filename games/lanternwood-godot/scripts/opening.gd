@tool
extends Marker3D

# A way out of the Glenn, placed in the Glen scene: drag it along the hedge in the editor to move
# it. Pick its kind, and the game behind it (leave Game empty for a shut "Coming soon" opening).
# It lines itself up with whichever hedge it's nearest and faces into the Glenn.

@export_enum("gate", "arch", "arbor", "trail", "door") var kind := "gate":
	set(value):
		kind = value
		_rebuild()
@export var game := "":
	set(value):
		game = value
		_rebuild()

var side := 0.0 # -1 on the west hedge, 1 on the east, 0 at the far (north) end.
var _model: Node3D


func _ready() -> void:
	set_notify_local_transform(true)
	_rebuild()


func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED and Engine.is_editor_hint():
		_line_up()


func is_open() -> bool:
	return Glen.GAMES.has(game)


func title() -> String:
	return Glen.GAMES[game].title if is_open() else "Coming soon"


# Where to stand to go in: just in front of the opening, on the Glenn side.
func spot() -> Vector3:
	return global_position + global_basis.z * 1.4


func _line_up() -> void:
	var half_x := Glen.HALL_WIDTH / 2.0 - Glen.HEDGE_THICKNESS / 2.0
	var half_z := Glen.HALL_LENGTH / 2.0 - Glen.HEDGE_THICKNESS / 2.0
	var p := position
	side = 0.0 if absf(p.x) < half_x * 0.5 and p.z < -half_z + 4.0 else signf(p.x)
	set_notify_local_transform(false)
	if side == 0.0:
		position = Vector3(0, 0, -half_z)
		rotation = Vector3.ZERO
	else:
		position = Vector3(side * half_x, 0, clampf(p.z, -half_z + 3.0, half_z - 3.0))
		rotation = Vector3(0, -side * PI / 2.0, 0)
	set_notify_local_transform(true)


func _rebuild() -> void:
	if not is_inside_tree():
		return
	_line_up()
	if _model:
		_model.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(name))
	_model = Gates.build(kind, title(), is_open(), rng)
	add_child(_model)
