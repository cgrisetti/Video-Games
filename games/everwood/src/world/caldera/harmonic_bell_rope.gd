## One bell-rope of the Harmonic Bell: light pulls it (the bell counts).
class_name HarmonicBellRope
extends Interactable

var bell: HarmonicBell
var rope_index: int = 0

var _rope: MeshInstance3D
var _dip: float = 0.0


func _ready() -> void:
	reach = 1.6
	var cord: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_post(cord, Vector3(0.0, 0.9, 0.0), 0.06, 0.06, HarmonicBell.BELL_HEIGHT + 1.6, Color(0.82, 0.7, 0.5), 5)
	CalderaKit.add_sphere(cord, Vector3(0.0, 1.0, 0.0), 0.16, CalderaKit.SAFFRON, 1.4, 6)
	_rope = CalderaKit.mesh_node("Cord", cord)
	add_child(_rope)
	CalderaKit.sign_label(self, "Seat", "P%d" % (rope_index + 1), Vector3(0.0, 2.3, 0.0))


func _process(delta: float) -> void:
	if _dip > 0.0:
		_dip = maxf(0.0, _dip - delta * 2.0)
		_rope.position.y = -0.45 * _dip


func prompt_for(_actor: ActorBase) -> String:
	if bell == null or not bell.can_ring():
		return "The bell is still: the Ebb has come" if CalderaWorldState.current.ebb_unlocked else "The bell is out of reach until the stair opens"
	return "light: pull the bell-rope together (%d of %d pulled)" % [bell.pulled_count(), bell.ringers_needed()]


func interact(actor: ActorBase) -> void:
	_dip = 1.0
	if bell != null:
		bell.pull(actor)
