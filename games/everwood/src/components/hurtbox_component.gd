## The volume that receives hits for an actor. It never looks for anything
## itself; hitboxes find it.
class_name HurtboxComponent
extends Area3D

var actor: ActorBase


func setup(owner_actor: ActorBase, is_boss: bool, radius: float, height: float) -> void:
	actor = owner_actor
	name = "Hurtbox"
	monitoring = false
	monitorable = true
	collision_layer = ActorBase.LAYER_BOSS_HURTBOX if is_boss else ActorBase.LAYER_PLAYER_HURTBOX
	collision_mask = 0
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = height
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = capsule
	collision.position = Vector3(0.0, height * 0.5, 0.0)
	add_child(collision)
