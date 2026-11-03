## The weapon or spell volume that is live during Phase B. It reports each
## hurtbox it overlaps once per action: if it touches, it hits (no dice rolls).
class_name HitboxComponent
extends Area3D

signal hurtbox_hit(hurtbox: HurtboxComponent)

## Hitbox centre height above the actor's feet.
const HIT_HEIGHT: float = 1.0

var actor: ActorBase
var active: bool = false

var _shape: SphereShape3D
var _already_hit: Dictionary[int, bool] = {}


func setup(owner_actor: ActorBase, hits_boss: bool) -> void:
	actor = owner_actor
	name = "Hitbox"
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = ActorBase.LAYER_BOSS_HURTBOX if hits_boss else ActorBase.LAYER_PLAYER_HURTBOX
	_shape = SphereShape3D.new()
	_shape.radius = 1.0
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = _shape
	add_child(collision)


func activate(action: CombatActionResource) -> void:
	_shape.radius = action.hit_radius
	# A Sign-Flow coat framed by Dover-Slap-Falls reaches further (14 GDD §4.2, Gorge-Draft).
	var coat_reach: float = actor.sign_flow.coat_reach_bonus() if actor.sign_flow != null else 0.0
	position = Vector3(0.0, HIT_HEIGHT, -(action.reach + coat_reach))
	_already_hit.clear()
	active = true


func deactivate() -> void:
	active = false


## Called every physics tick while active. Overlaps update once per tick, so
## polling is steadier than enter/exit signals for short active windows.
func poll() -> void:
	if not active:
		return
	for area: Area3D in get_overlapping_areas():
		var hurtbox: HurtboxComponent = area as HurtboxComponent
		if hurtbox == null or hurtbox.actor == actor or hurtbox.actor == null:
			continue
		var key: int = hurtbox.get_instance_id()
		if _already_hit.has(key):
			continue
		_already_hit[key] = true
		hurtbox_hit.emit(hurtbox)
