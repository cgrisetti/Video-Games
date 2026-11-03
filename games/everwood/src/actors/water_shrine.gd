## The Wayfarer's Water-Shrine midway down Rush-Light-Hollow
## (07_EXPEDITION_HUD_AND_ART_GDD.md §3, Zone 1; the oasis of
## 17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §4.2): a moss-draped stone basin
## under a tiny hipped cedar-shingle roof, a carved spout pouring clear water,
## glowing blue-green ferns and water-striders, breathing mist. Walk through
## the mist and the whole party is restored to full health and stamina; then
## the spring rests for a while (its pour thins, its mist and glow drop) before
## it can bless again.
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
## The spring trickles quieter while it rests.
const RESTING_TRICKLE_DB: float = -6.0
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

var _water: ShaderMaterial
var _pour: MeshInstance3D
var _striders: CPUParticles3D
var _mist: CPUParticles3D
var _glow: OmniLight3D
var _trickle: AudioStreamPlayer3D


func _ready() -> void:
	# Standing by the spring lifts the Holloway's hush into a harp oasis (16 GDD §4.3).
	add_to_group(AudioDirector.OASIS_GROUP)
	_trickle = AudioDirector.attach_ambience(self, &"water_trickle", Vector3(0.0, BASIN_HEIGHT, 0.0))
	# The oasis: basin, moss, stele and spout, cedar posts, hipped roof and ferns.
	add_child(WorldAssetCatalog.build(WorldVisualCatalog.KIT_WATER_SHRINE_OASIS))
	# Its own water, so it can dim while it rests.
	_water = (WorldVisualCatalog.water(&"shrine") as ShaderMaterial).duplicate() as ShaderMaterial
	add_child(ShapeKit.cylinder("Water", BASIN_RADIUS - 0.08, BASIN_RADIUS - 0.08, 0.04, Vector3(0.0, BASIN_HEIGHT - 0.02, 0.0), _water, 20))
	var pour_mesh: PlaneMesh = PlaneMesh.new()
	pour_mesh.size = Vector2(0.16, 0.62)
	pour_mesh.material = WorldVisualCatalog.water(&"falls", Vector2(0.0, 1.2))
	_pour = MeshInstance3D.new()
	_pour.name = "Pour"
	_pour.mesh = pour_mesh
	_pour.position = Vector3(0.0, 0.95, -0.66)
	_pour.rotation = Vector3(PI * 0.5 - 0.25, 0.0, 0.0)
	_pour.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_pour)
	_striders = CPUParticles3D.new()
	_striders.name = "WaterStriders"
	_striders.position = Vector3(0.0, BASIN_HEIGHT + 0.02, 0.0)
	_striders.amount = 4
	_striders.lifetime = 3.0
	_striders.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_striders.emission_sphere_radius = BASIN_RADIUS * 0.6
	_striders.direction = Vector3(1.0, 0.0, 0.0)
	_striders.spread = 180.0
	_striders.gravity = Vector3.ZERO
	_striders.initial_velocity_min = 0.1
	_striders.initial_velocity_max = 0.25
	var strider: BoxMesh = BoxMesh.new()
	strider.size = Vector3(0.07, 0.01, 0.03)
	strider.material = WorldVisualCatalog.painted(Color(0.18, 0.16, 0.14))
	_striders.mesh = strider
	add_child(_striders)
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
	sign_label.position = Vector3(0.0, ROOF_HEIGHT + 1.2, 0.0)
	add_child(sign_label)


func is_resting() -> bool:
	return resting_left > 0.0


func _physics_process(delta: float) -> void:
	resting_left = maxf(0.0, resting_left - delta)
	var ready_glow: float = 0.25 if is_resting() else 1.0
	_water.set_shader_parameter(&"foam_amount", 0.15 * ready_glow)
	_water.set_shader_parameter(&"flow", Vector2(0.0, 0.3 * ready_glow))
	_pour.scale = Vector3(0.35 if is_resting() else 1.0, 1.0, 1.0)
	_glow.light_energy = 1.4 * ready_glow
	_mist.emitting = not is_resting()
	_striders.emitting = not is_resting()
	_trickle.volume_db = RESTING_TRICKLE_DB if is_resting() else 0.0
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
