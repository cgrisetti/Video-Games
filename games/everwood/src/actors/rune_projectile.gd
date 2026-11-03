## A shot from a bow or a staff: a weapon's own light or heavy, or a Scribe
## Card channelled through it, which flies wrapped in a spinning ring of its
## Sign's colour (05 GDD §4.3). It flies straight for the action's range and
## stops at walls.
##
## On the attacker's peer it's the real thing: the first hurtbox it touches is
## reported to the CombatDirector, which delivers the strike to whoever owns the
## target. Other peers fly a look-alike that can't hit anything. Pooled: when
## it lands or runs out of range, finish() hands it back to the FxPool.
class_name RuneProjectile
extends PooledFx

## Shots leave the archer this high and this far in front.
const MUZZLE_HEIGHT: float = 1.2
const MUZZLE_FORWARD: float = 0.6
## A card shot's Sign ring.
const RUNE_RING_RADIUS: float = 0.34
const RUNE_RING_THICKNESS: float = 0.05
const RUNE_RING_SPIN: float = 9.0
const RUNE_RING_GLOW: float = 3.0
## Fast shots check for targets at several points per tick so they can't skip one.
const MAX_SUBSTEPS: int = 4
## The smallest gap between those checks (for very thin shots).
const MIN_PROBE_STEP: float = 0.05
const MAX_TOUCHES: int = 8

var attacker: ActorBase
var action: CombatActionResource
## The attacker's peer flies the real shot; other peers fly a copy that can't hit.
var authoritative: bool = false
## Fired out of a flow-cancel (a hit fills resonance faster).
var flowed: bool = false

var _direction: Vector3 = Vector3.FORWARD
var _travelled: float = 0.0
var _touched: Dictionary[int, bool] = {}
var _ring: MeshInstance3D
var _ring_material: StandardMaterial3D
var _probe: SphereShape3D
var _query: PhysicsShapeQueryParameters3D


## Builds the look once, when the pool first makes this shot.
func build_look(look: EquipmentItemResource) -> void:
	name = "RuneProjectile"
	if look != null:
		add_child(PropBuilder.build(look.projectile_parts, null, "Look"))
	_ring_material = StandardMaterial3D.new()
	_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_material.emission_enabled = true
	_ring_material.emission_energy_multiplier = RUNE_RING_GLOW
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = RUNE_RING_RADIUS - RUNE_RING_THICKNESS
	torus.outer_radius = RUNE_RING_RADIUS
	torus.material = _ring_material
	_ring = MeshInstance3D.new()
	_ring.name = "RuneRing"
	_ring.mesh = torus
	# A torus lies flat; stand it up so the shot flies through it.
	_ring.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	_probe = SphereShape3D.new()
	_query = PhysicsShapeQueryParameters3D.new()
	_query.shape = _probe
	_query.collide_with_areas = true
	_query.collide_with_bodies = false


## Where a shot from `from_actor` starts.
static func muzzle_of(from_actor: ActorBase) -> Vector3:
	return from_actor.global_position + Vector3.UP * MUZZLE_HEIGHT + from_actor.facing_vector() * MUZZLE_FORWARD


func launch(from_actor: ActorBase, shot: CombatActionResource, origin: Vector3, direction: Vector3, real: bool, was_flowed: bool) -> void:
	attacker = from_actor
	action = shot
	authoritative = real
	flowed = was_flowed
	_direction = direction.normalized() if direction.length() > 0.01 else from_actor.facing_vector()
	_travelled = 0.0
	_touched.clear()
	global_transform = Transform3D(Basis.looking_at(_direction, Vector3.UP), origin)
	_ring.visible = shot.is_card()
	if _ring.visible:
		var colour: Color = ArsenalCatalog.current.sign_seal(shot.scribe_sign).color
		_ring_material.albedo_color = colour
		_ring_material.emission = colour
	_probe.radius = shot.projectile_radius
	_query.collision_mask = ActorBase.LAYER_PLAYER_HURTBOX if from_actor.is_boss() else ActorBase.LAYER_BOSS_HURTBOX
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(attacker) or action == null:
		finish()
		return
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var from: Vector3 = global_position
	var to: Vector3 = from + _direction * minf(action.projectile_speed * delta, action.projectile_range - _travelled)
	# Walls and pillars stop it.
	if not space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, ActorBase.LAYER_WORLD)).is_empty():
		finish()
		return
	var steps: int = clampi(ceili(from.distance_to(to) / maxf(MIN_PROBE_STEP, action.projectile_radius)), 1, MAX_SUBSTEPS)
	for step: int in steps:
		global_position = from.lerp(to, float(step + 1) / steps)
		if _touch_targets(space):
			return
	_travelled += from.distance_to(to)
	if _ring.visible:
		_ring.rotate_object_local(Vector3.UP, RUNE_RING_SPIN * delta)
	if _travelled >= action.projectile_range - 0.001:
		finish()


## Returns true when the shot stopped on a target.
func _touch_targets(space: PhysicsDirectSpaceState3D) -> bool:
	_query.transform = Transform3D(Basis.IDENTITY, global_position)
	for result: Dictionary in space.intersect_shape(_query, MAX_TOUCHES):
		var hurtbox: HurtboxComponent = result.get("collider") as HurtboxComponent
		if hurtbox == null or hurtbox.actor == null or hurtbox.actor == attacker or hurtbox.actor.stats.is_downed:
			continue
		var key: int = hurtbox.get_instance_id()
		if _touched.has(key):
			continue
		_touched[key] = true
		if authoritative:
			CombatDirector.current.report_hit(attacker, hurtbox.actor, action, flowed, true)
		if not action.pierces:
			finish()
			return true
	return false
