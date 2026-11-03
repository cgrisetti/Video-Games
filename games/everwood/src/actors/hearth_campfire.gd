## The Warm-Hearth Campfire at the Kindle-Fire, where the party wakes on
## the woodland trailhead south of Honey-Wick: crackling logs in a mossy
## river-stone ring under a cast-iron tripod kettle, travel packs leaning on a
## log seat, and a saffron-gold light (the Sign of Warm-Hearth's) that
## flickers. Stand by it and the whole party is warmed to full health and
## stamina, as at the Water-Shrine; then the fire burns low for a while before
## it can warm again.
##
## The host decides when someone's by the fire and refreshes everyone through
## CombatDirector (each owner restores its own); every peer sees the flare.
## Its rest is remembered (WorldStateDB), like the Water-Shrine's.
class_name HearthCampfire
extends Node3D

signal warmed(by_player_id: StringName)

## Standing this close (flat) is standing by the fire.
const WARM_RADIUS: float = 3.0
## Seconds it burns low before it can warm again (the Water-Shrine's rest).
const REST_TIME: float = WaterShrine.REST_TIME
const RING_RADIUS: float = 1.1
const STONES: int = 11
## The Sign of Warm-Hearth's colour, if the catalog isn't up (the builder's bake).
const HEARTH_GOLD: Color = Color(1.0, 0.76, 0.28)
const FLAME_COLOR: Color = Color(1.0, 0.55, 0.15)
const STONE_COLOR: Color = Color(0.56, 0.56, 0.52)
const MOSS_COLOR: Color = Color(0.34, 0.5, 0.25)
const LOG_COLOR: Color = Color(0.4, 0.27, 0.16)
const ASH_COLOR: Color = Color(0.22, 0.2, 0.19)
const IRON_COLOR: Color = Color(0.2, 0.2, 0.22)
const PACK_COLORS: Array[Color] = [Color(0.48, 0.36, 0.22), Color(0.36, 0.42, 0.3), Color(0.55, 0.3, 0.24)]
const BEDROLL_COLORS: Array[Color] = [Color(0.62, 0.5, 0.36), Color(0.42, 0.46, 0.58)]
const LIGHT_ENERGY: float = 2.4
const LIGHT_RANGE: float = 10.0
## The share of its energy the light's flicker swings.
const FLICKER: float = 0.28
## Burning low (resting), the fire glows this much of its full.
const LOW_BURN: float = 0.35
## The fire's crackle drops this far while it burns low (16 GDD §4.1).
const LOW_CRACKLE_DB: float = -6.0
const TRIPOD_HEIGHT: float = 1.9

## Its WorldStateDB id (10_WORLD_ARCHITECTURE.md §4.2); empty: not remembered.
@export var persist_id: StringName = &""

var resting_left: float = 0.0
var persistence: WorldStateBinding

var _light: OmniLight3D
var _flames: CPUParticles3D
var _embers: CPUParticles3D
## The crackle and kettle bubble (Ambience3D).
var _crackle: AudioStreamPlayer3D
var _core: MeshInstance3D
var _core_material: StandardMaterial3D
var _age: float = 0.0


func _ready() -> void:
	_crackle = AudioDirector.attach_ambience(self, &"hearth_fire", Vector3(0.0, 0.5, 0.0))
	_build_ring()
	_build_fire()
	_build_kettle()
	_build_camp()
	# The ring is knee-high scenery: you walk round it, and cameras see past it.
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "RingBody"
	body.collision_layer = ActorBase.LAYER_LOW_SCENERY
	body.collision_mask = 0
	var ring: CylinderShape3D = CylinderShape3D.new()
	ring.radius = RING_RADIUS + 0.2
	ring.height = 0.5
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.shape = ring
	shape.position = Vector3(0.0, 0.25, 0.0)
	body.add_child(shape)
	add_child(body)
	var sign_label: Label3D = Label3D.new()
	sign_label.name = "Sign"
	sign_label.text = "The Kindle-Fire"
	sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_label.font_size = 36
	sign_label.outline_size = 10
	sign_label.pixel_size = 0.006
	sign_label.modulate = _gold().lightened(0.35)
	sign_label.position = Vector3(0.0, TRIPOD_HEIGHT + 1.3, 0.0)
	add_child(sign_label)


func is_resting() -> bool:
	return resting_left > 0.0


func _process(delta: float) -> void:
	_age += delta
	var burn: float = LOW_BURN if is_resting() else 1.0
	# Three uneven waves make a flicker that never quite repeats.
	var flicker: float = 1.0 + FLICKER * (sin(_age * 7.3) * 0.5 + sin(_age * 13.1 + 1.7) * 0.3 + sin(_age * 2.9 + 0.4) * 0.2)
	_light.light_energy = LIGHT_ENERGY * burn * flicker
	_core.scale = Vector3(1.0, (0.75 + 0.25 * flicker) * (0.55 + 0.45 * burn), 1.0)
	_core_material.emission_energy_multiplier = 2.6 * burn
	_flames.scale_amount_min = 0.6 * burn
	_flames.scale_amount_max = 1.2 * burn
	_embers.emitting = not is_resting()
	_crackle.volume_db = LOW_CRACKLE_DB if is_resting() else 0.0


func _physics_process(delta: float) -> void:
	resting_left = maxf(0.0, resting_left - delta)
	if is_resting() or not NetworkManager.current.is_host() or not InstanceManager.current.is_live():
		return
	for member: ActorBase in CombatDirector.current.party_actors():
		var flat: Vector2 = Vector2(member.global_position.x - global_position.x, member.global_position.z - global_position.z)
		if flat.length() <= WARM_RADIUS and absf(member.global_position.y - global_position.y) < 2.0:
			CombatDirector.current.refresh_party()
			_warm(String(member.player_id))
			for peer_id: int in InstanceManager.current.live_remote_peers():
				_warm.rpc_id(peer_id, String(member.player_id))
			return


## Runs on every peer: the fire flares, the kettle sings, and it burns low.
@rpc("authority", "call_local", "reliable")
func _warm(by_player_id: String) -> void:
	resting_left = REST_TIME
	if persistence != null:
		persistence.save({"rest_until": persistence.db.world_time + REST_TIME})
	AudioCues.play(&"shrine")
	CombatDirector.current.show_float_text(global_position + Vector3.UP * (TRIPOD_HEIGHT + 0.6), "The party is warmed!", _gold().lightened(0.3), 46)
	var burst: CueBurst = CueBurst.new()
	burst.configure(_gold())
	add_child(burst)
	burst.position = Vector3(0.0, 0.6, 0.0)
	warmed.emit(StringName(by_player_id))


## WorldStateDB hands over its line to the store, and the state on record applies at once.
func bind_persistence(binding: WorldStateBinding) -> void:
	persistence = binding
	apply_persisted_state(binding.current_state())


## Burns low until the time on record (none on record: ready).
func apply_persisted_state(state: Dictionary) -> void:
	resting_left = maxf(0.0, float(state.get("rest_until", 0.0)) - persistence.db.world_time) if persistence != null else 0.0


# --- Looks -----------------------------------------------------------------

## Mossy river stones round a bed of ash.
func _build_ring() -> void:
	add_child(ShapeKit.cylinder("Ash", RING_RADIUS - 0.1, RING_RADIUS - 0.1, 0.06, Vector3(0.0, 0.02, 0.0), StorybookMaterial.make(ASH_COLOR), 20))
	var stone: Material = StorybookMaterial.make(STONE_COLOR)
	var moss: Material = StorybookMaterial.make(MOSS_COLOR)
	for index: int in STONES:
		var angle: float = TAU * index / STONES
		var size: float = 0.22 + 0.06 * sin(index * 2.3)
		var rock: MeshInstance3D = _sphere("Stone%d" % index, size, stone)
		rock.position = Vector3(cos(angle) * RING_RADIUS, size * 0.45, sin(angle) * RING_RADIUS)
		rock.scale = Vector3(1.3, 0.75, 1.0)
		rock.rotation.y = -angle
		add_child(rock)
		if index % 3 != 1:
			var cap: MeshInstance3D = _sphere("Moss%d" % index, size * 0.8, moss)
			cap.position = rock.position + Vector3(0.0, size * 0.42, 0.0)
			cap.scale = Vector3(1.2, 0.35, 0.9)
			add_child(cap)


## Logs leaning in a cone, a glowing flame core, flames and embers, and the light.
func _build_fire() -> void:
	var wood: Material = StorybookMaterial.make(LOG_COLOR)
	for index: int in 5:
		var angle: float = TAU * index / 5.0 + 0.3
		var log_node: MeshInstance3D = ShapeKit.cylinder("Log%d" % index, 0.07, 0.09, 1.05, Vector3.ZERO, wood, 10)
		log_node.position = Vector3(cos(angle) * 0.32, 0.3, sin(angle) * 0.32)
		log_node.rotation = Vector3(0.0, -angle, 0.0)
		# Tops lean in over the middle, a little cone of logs.
		log_node.rotate_object_local(Vector3.BACK, 0.62)
		add_child(log_node)
	_core_material = StorybookMaterial.glowing(FLAME_COLOR, 2.6)
	var cone: CylinderMesh = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.34
	cone.height = 0.9
	cone.radial_segments = 10
	cone.material = _core_material
	_core = MeshInstance3D.new()
	_core.name = "Flame"
	_core.mesh = cone
	_core.position = Vector3(0.0, 0.42, 0.0)
	_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_core)
	_flames = _particles("Flames", 26, 0.7, 0.28, Vector2(0.5, 1.1), 0.16, FLAME_COLOR, 2.2)
	_flames.position = Vector3(0.0, 0.25, 0.0)
	add_child(_flames)
	_embers = _particles("Embers", 14, 2.2, 0.35, Vector2(0.8, 1.6), 0.035, _gold(), 3.0)
	_embers.position = Vector3(0.0, 0.5, 0.0)
	add_child(_embers)
	_light = OmniLight3D.new()
	_light.name = "HearthLight"
	_light.light_color = _gold()
	_light.light_energy = LIGHT_ENERGY
	_light.omni_range = LIGHT_RANGE
	_light.shadow_enabled = false
	_light.position = Vector3(0.0, 1.0, 0.0)
	add_child(_light)


## A cast-iron kettle hung on its chain from a tripod over the fire.
func _build_kettle() -> void:
	var iron: Material = StorybookMaterial.make(IRON_COLOR)
	var apex: Vector3 = Vector3(0.0, TRIPOD_HEIGHT, 0.0)
	for index: int in 3:
		var angle: float = TAU * index / 3.0 + 0.5
		var foot: Vector3 = Vector3(cos(angle) * (RING_RADIUS + 0.15), 0.0, sin(angle) * (RING_RADIUS + 0.15))
		var leg: MeshInstance3D = ShapeKit.cylinder("TripodLeg%d" % index, 0.035, 0.035, foot.distance_to(apex), (foot + apex) * 0.5, iron, 6)
		# A cylinder stands along its Y: turn Y to run from the foot up to the apex.
		var along: Vector3 = (apex - foot).normalized()
		var across: Vector3 = along.cross(Vector3.FORWARD).normalized()
		leg.basis = Basis(across, along, across.cross(along))
		add_child(leg)
	add_child(ShapeKit.cylinder("Chain", 0.015, 0.015, 0.75, Vector3(0.0, TRIPOD_HEIGHT - 0.38, 0.0), iron, 6))
	var pot: MeshInstance3D = _sphere("Kettle", 0.26, iron)
	pot.position = Vector3(0.0, TRIPOD_HEIGHT - 0.95, 0.0)
	pot.scale = Vector3(1.0, 0.8, 1.0)
	add_child(pot)
	add_child(ShapeKit.cylinder("KettleLid", 0.16, 0.18, 0.05, Vector3(0.0, TRIPOD_HEIGHT - 0.76, 0.0), iron, 12))


## The party's camp on the west side, away from the trail: a log seat with
## travel packs leaning on it and two bedrolls.
func _build_camp() -> void:
	var wood: Material = StorybookMaterial.make(LOG_COLOR.darkened(0.1))
	var seat: MeshInstance3D = ShapeKit.cylinder("LogSeat", 0.22, 0.24, 2.4, Vector3(-2.5, 0.22, 0.0), wood, 12)
	seat.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	add_child(seat)
	for index: int in PACK_COLORS.size():
		var z: float = (float(index) - 1.0) * 0.8
		var pack: MeshInstance3D = MeshInstance3D.new()
		pack.name = "Pack%d" % index
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(0.32, 0.62, 0.48)
		box.material = StorybookMaterial.make(PACK_COLORS[index])
		pack.mesh = box
		pack.position = Vector3(-2.05, 0.33, z)
		pack.rotation = Vector3(0.0, 0.0, 0.32)
		add_child(pack)
		var roll: MeshInstance3D = ShapeKit.cylinder("PackRoll%d" % index, 0.1, 0.1, 0.5, Vector3(0.0, 0.38, 0.0), StorybookMaterial.make(BEDROLL_COLORS[index % 2]), 10)
		roll.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		pack.add_child(roll)
	for index: int in BEDROLL_COLORS.size():
		var bedroll: MeshInstance3D = ShapeKit.cylinder("Bedroll%d" % index, 0.16, 0.16, 1.7, Vector3(-1.2 + index * 0.4, 0.14, -2.4 + index * 0.1), StorybookMaterial.make(BEDROLL_COLORS[index]), 12)
		bedroll.rotation = Vector3(0.0, 0.25 + index * 0.4, PI * 0.5)
		add_child(bedroll)


func _sphere(sphere_name: String, radius: float, material: Material) -> MeshInstance3D:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 6
	mesh.material = material
	var node: MeshInstance3D = MeshInstance3D.new()
	node.name = sphere_name
	node.mesh = mesh
	return node


func _particles(particles_name: String, amount: int, lifetime: float, spread_radius: float, speed: Vector2, size: float, color: Color, glow: float) -> CPUParticles3D:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.name = particles_name
	particles.amount = amount
	particles.lifetime = lifetime
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = spread_radius
	particles.direction = Vector3.UP
	particles.spread = 18.0
	particles.gravity = Vector3(0.0, 0.4, 0.0)
	particles.initial_velocity_min = speed.x
	particles.initial_velocity_max = speed.y
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.2
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	particles.scale_amount_curve = curve
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	mesh.material = StorybookMaterial.glowing(color, glow)
	particles.mesh = mesh
	return particles


func _gold() -> Color:
	if ArsenalCatalog.current == null:
		return HEARTH_GOLD
	return ArsenalCatalog.current.sign_seal(ScribeSignResource.Sign.SIGN_WARM_HEARTH).color
