## The Wayfarer's Water-Shrine midway down the Sunken Holloway
## (07_EXPEDITION_HUD_AND_ART_GDD.md §3, Zone 1): a mossy spring basin under a
## tiny shingled roof, breathing mist. Walk through the mist and the whole
## party is restored to full health and stamina; then the spring rests for a
## while (its water dims) before it can bless again.
##
## The host decides when someone's in the mist and refreshes everyone through
## CombatDirector (each owner restores its own); every peer sees the blessing.
## Its rest is remembered (WorldStateDB, by the store's shared clock), so it's
## still resting when its Landblock streams back in or a latecomer arrives.
class_name WaterShrine
extends Node3D

signal blessed(by_player_id: StringName)

## Standing this close (in the mist) is touching it.
const TOUCH_RADIUS: float = 1.9
## Seconds before it can bless again.
const REST_TIME: float = 40.0
const BASIN_RADIUS: float = 0.9
const BASIN_HEIGHT: float = 0.6
const ROOF_HEIGHT: float = 2.4
const STONE_COLOR: Color = Color(0.5, 0.53, 0.47)
const MOSS_COLOR: Color = Color(0.32, 0.48, 0.24)
const WOOD_COLOR: Color = Color(0.4, 0.28, 0.17)
const SHINGLE_COLOR: Color = Color(0.3, 0.36, 0.3)
const WATER_COLOR: Color = Color(0.35, 0.75, 0.95)
const MIST_COLOR: Color = Color(0.8, 0.95, 1.0, 0.35)

## Its WorldStateDB id (10_WORLD_ARCHITECTURE.md §4.2); empty: not remembered.
@export var persist_id: StringName = &""

var resting_left: float = 0.0
var persistence: WorldStateBinding

var _water: StandardMaterial3D
var _mist: CPUParticles3D
var _glow: OmniLight3D


func _ready() -> void:
	var stone: Material = _material(STONE_COLOR, 0.0)
	add_child(ShapeKit.cylinder("Basin", BASIN_RADIUS, BASIN_RADIUS, BASIN_HEIGHT, Vector3(0.0, BASIN_HEIGHT * 0.5, 0.0), stone, 20))
	add_child(ShapeKit.cylinder("Moss", BASIN_RADIUS + 0.06, BASIN_RADIUS + 0.06, 0.12, Vector3(0.0, BASIN_HEIGHT - 0.04, 0.0), _material(MOSS_COLOR, 0.0), 20))
	_water = StorybookMaterial.glowing(WATER_COLOR, 1.2)
	add_child(ShapeKit.cylinder("Water", BASIN_RADIUS - 0.12, BASIN_RADIUS - 0.12, 0.05, Vector3(0.0, BASIN_HEIGHT + 0.01, 0.0), _water, 20))
	var wood: Material = _material(WOOD_COLOR, 0.0)
	for corner: Vector2 in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
		add_child(ShapeKit.cylinder("Post", 0.07, 0.07, ROOF_HEIGHT, Vector3(corner.x * 1.0, ROOF_HEIGHT * 0.5, corner.y * 1.0), wood, 20))
	var roof_mesh: PrismMesh = PrismMesh.new()
	roof_mesh.size = Vector3(2.7, 0.9, 2.7)
	roof_mesh.material = _material(SHINGLE_COLOR, 0.0)
	var roof: MeshInstance3D = MeshInstance3D.new()
	roof.name = "Roof"
	roof.mesh = roof_mesh
	roof.position = Vector3(0.0, ROOF_HEIGHT + 0.45, 0.0)
	add_child(roof)
	_mist = CPUParticles3D.new()
	_mist.name = "Mist"
	_mist.position = Vector3(0.0, BASIN_HEIGHT + 0.1, 0.0)
	_mist.amount = 18
	_mist.lifetime = 2.4
	_mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_mist.emission_sphere_radius = BASIN_RADIUS
	_mist.direction = Vector3.UP
	_mist.spread = 25.0
	_mist.initial_velocity_min = 0.15
	_mist.initial_velocity_max = 0.4
	_mist.gravity = Vector3(0.0, 0.12, 0.0)
	_mist.scale_amount_min = 0.6
	_mist.scale_amount_max = 1.3
	var puff: SphereMesh = SphereMesh.new()
	puff.radius = 0.3
	puff.height = 0.6
	var puff_material: StandardMaterial3D = StandardMaterial3D.new()
	puff_material.albedo_color = MIST_COLOR
	puff_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = puff_material
	_mist.mesh = puff
	add_child(_mist)
	_glow = OmniLight3D.new()
	_glow.name = "Glow"
	_glow.light_color = WATER_COLOR
	_glow.light_energy = 1.4
	_glow.omni_range = 4.5
	_glow.position = Vector3(0.0, 1.2, 0.0)
	add_child(_glow)
	var sign_label: Label3D = Label3D.new()
	sign_label.name = "Sign"
	sign_label.text = "Wayfarer's Water-Shrine"
	sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_label.font_size = 40
	sign_label.outline_size = 10
	sign_label.pixel_size = 0.009
	sign_label.modulate = WATER_COLOR.lightened(0.4)
	sign_label.position = Vector3(0.0, ROOF_HEIGHT + 1.4, 0.0)
	add_child(sign_label)


func is_resting() -> bool:
	return resting_left > 0.0


func _physics_process(delta: float) -> void:
	resting_left = maxf(0.0, resting_left - delta)
	var ready_glow: float = 0.25 if is_resting() else 1.0
	_water.emission_energy_multiplier = 1.2 * ready_glow
	_glow.light_energy = 1.4 * ready_glow
	_mist.emitting = not is_resting()
	if is_resting() or not NetworkManager.current.is_host() or not InstanceManager.current.is_live():
		return
	for member: ActorBase in CombatDirector.current.party_actors():
		var flat: Vector2 = Vector2(member.global_position.x - global_position.x, member.global_position.z - global_position.z)
		if flat.length() <= TOUCH_RADIUS and absf(member.global_position.y - global_position.y) < 2.0:
			CombatDirector.current.refresh_party()
			_bless(String(member.player_id))
			for peer_id: int in InstanceManager.current.live_remote_peers():
				_bless.rpc_id(peer_id, String(member.player_id))
			return


## Runs on every peer: the spring flares, chimes and rests.
@rpc("authority", "call_local", "reliable")
func _bless(by_player_id: String) -> void:
	resting_left = REST_TIME
	if persistence != null:
		persistence.save({"rest_until": persistence.db.world_time + REST_TIME})
	AudioCues.play(&"shrine")
	CombatDirector.current.show_float_text(global_position + Vector3.UP * (ROOF_HEIGHT + 0.6), "The party is refreshed!", WATER_COLOR.lightened(0.3), 46)
	var burst: CueBurst = CueBurst.new()
	burst.configure(WATER_COLOR)
	add_child(burst)
	burst.position = Vector3(0.0, BASIN_HEIGHT + 0.3, 0.0)
	blessed.emit(StringName(by_player_id))


## WorldStateDB hands over its line to the store, and the state on record applies at once.
func bind_persistence(binding: WorldStateBinding) -> void:
	persistence = binding
	apply_persisted_state(binding.current_state())


## Rests until the time on record (none on record: ready).
func apply_persisted_state(state: Dictionary) -> void:
	resting_left = maxf(0.0, float(state.get("rest_until", 0.0)) - persistence.db.world_time) if persistence != null else 0.0


## The storybook cel look, or a glowing material when `glow` is above zero.
func _material(color: Color, glow: float) -> Material:
	return StorybookMaterial.glowing(color, glow) if glow > 0.0 else StorybookMaterial.make(color)
