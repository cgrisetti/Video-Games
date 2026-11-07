## The living picture behind the title (docs/22_TITLE_SCREEN_AND_TALES.md §2):
## Oakshire Holm's orchard knoll at golden hour above The Sound, the Level 1
## youth standing on its crest in the easy idle, the cape stirring, apple
## trees in fruit, motes drifting in the low sun, and across the water The
## Crown and Miller's Oak in the haze. Built in code from the game's own
## parts: the storybook sky, the cel materials, the atelier orchard trees and
## the youth's sculpt and clips. The camera breathes slowly.
class_name TitleDiorama
extends Node3D

## Golden hour: the sky's four colours, the haze and the low warm sun.
const SKY_TOP: Color = Color(0.34, 0.53, 0.8)
const SKY_HORIZON: Color = Color(0.98, 0.85, 0.64)
const GROUND_HORIZON: Color = Color(0.84, 0.78, 0.64)
const GROUND_BOTTOM: Color = Color(0.36, 0.4, 0.34)
const HAZE: Color = Color(0.93, 0.84, 0.7)
const SUN_COLOR: Color = Color(1.0, 0.89, 0.72)
const SEA_COLOR: Color = Color(0.27, 0.5, 0.56)
const SEA_LEVEL: float = -2.4
## The knoll: its crest height, how wide it is, and where it falls to the shore (toward -Z).
const KNOLL_HEIGHT: float = 2.0
const KNOLL_RADIUS: float = 15.0
const SHORE_Z: float = -30.0
const GROUND_SIZE: float = 140.0
const GROUND_STEPS: int = 70
## Where the youth stands and which way the camera looks from.
const HERO_AT: Vector2 = Vector2(0.8, 1.6)
const CAMERA_AT: Vector3 = Vector3(0.2, 0.0, 5.9)
const CAMERA_LIFT: float = 0.95
const CAMERA_FOV: float = 38.0
const LOOK_AT: Vector3 = Vector3(-1.6, 2.45, -8.0)
## The camera's slow breath: how far it drifts and how long a breath takes.
const SWAY_REACH: Vector3 = Vector3(0.35, 0.12, 0.2)
const SWAY_SECONDS: float = 14.0
## The orchard: apple trees round the knoll (x, z), kept clear of the wordmark's side of the sky.
## Ferns in the foreground grass (x, z).
const FERNS: Array[Vector2] = [Vector2(-3.2, 2.6), Vector2(-5.5, 0.8), Vector2(-1.4, 3.6), Vector2(2.8, 3.2), Vector2(4.2, 1.2), Vector2(-7.5, 3.0),
	Vector2(3.6, -1.6), Vector2(-4.4, -2.4), Vector2(6.5, 3.6), Vector2(-2.2, 0.4)]
const ORCHARD: Array[Vector2] = [Vector2(7.5, -3.0), Vector2(11.0, 3.5), Vector2(4.5, -9.5), Vector2(15.0, -6.0), Vector2(-13.0, -12.0),
	Vector2(-19.0, -4.0), Vector2(9.0, -15.0), Vector2(21.0, 1.0)]
## The Crown across the water (x, z, height, radius), between the wordmark and
## the youth, and the far isles low on the horizon.
const CROWN: Vector4 = Vector4(-200.0, -1400.0, 120.0, 210.0)
const FAR_ISLES: Array[Vector4] = [Vector4(-700.0, -1300.0, 28.0, 260.0), Vector4(520.0, -1500.0, 40.0, 300.0), Vector4(-260.0, -900.0, 14.0, 140.0)]
const DISTANT_STONE: Color = Color(0.42, 0.46, 0.6)
const DISTANT_MEADOW: Color = Color(0.5, 0.6, 0.55)

var camera: Camera3D
var hero: Node3D
var skeleton: Skeleton3D
var kinematics: StorybookKinematicsModifier3D
var _age: float = 0.0
var _hero_look: HeroAppearanceResource


func _ready() -> void:
	_build_world()
	_build_ground()
	_build_far()
	_build_orchard()
	_build_hero()
	_build_motes()
	camera = Camera3D.new()
	camera.name = "TitleCamera"
	camera.fov = CAMERA_FOV
	camera.far = 3000.0
	add_child(camera)
	camera.current = true
	_place_camera(0.0)


func _process(delta: float) -> void:
	_age += delta
	_place_camera(_age)
	_pose_hero(delta)


## The ground's height at (x, z): the knoll, a gentle roll, and the fall to the shore.
static func ground_height(x: float, z: float) -> float:
	var knoll: float = KNOLL_HEIGHT * exp(-(x * x + z * z) / (2.0 * KNOLL_RADIUS * KNOLL_RADIUS))
	var roll: float = 0.35 * sin(x * 0.11 + 0.6) * cos(z * 0.09 - 0.3) + 0.15 * sin(x * 0.27 + z * 0.21)
	var shore: float = smoothstep(SHORE_Z, SHORE_Z - 22.0, z) * 5.5
	return knoll + roll - shore


func _place_camera(t: float) -> void:
	var phase: float = TAU * t / SWAY_SECONDS
	var sway: Vector3 = Vector3(sin(phase) * SWAY_REACH.x, sin(phase * 2.0 + 0.7) * SWAY_REACH.y, cos(phase) * SWAY_REACH.z)
	var at: Vector3 = CAMERA_AT + Vector3(0.0, ground_height(CAMERA_AT.x, CAMERA_AT.z) + CAMERA_LIFT, 0.0) + sway
	camera.position = at
	camera.look_at(LOOK_AT + Vector3(sway.x * 0.4, 0.0, 0.0), Vector3.UP)


func _build_world() -> void:
	var environment: Environment = Environment.new()
	var sky: Sky = Sky.new()
	var procedural: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	procedural.sky_top_color = SKY_TOP
	procedural.sky_horizon_color = SKY_HORIZON
	procedural.ground_horizon_color = GROUND_HORIZON
	procedural.ground_bottom_color = GROUND_BOTTOM
	sky.sky_material = procedural
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	StorybookSky.install(environment)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.9
	# Toon shading washes out under ACES; the game uses Filmic.
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = HAZE
	environment.fog_density = 0.0007
	environment.fog_aerial_perspective = 0.55
	environment.fog_sky_affect = 0.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.35
	environment.glow_bloom = 0.05
	var world: WorldEnvironment = WorldEnvironment.new()
	world.name = "TitleEnvironment"
	world.environment = environment
	add_child(world)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "LowSun"
	sun.light_color = SUN_COLOR
	sun.light_energy = 1.25
	sun.rotation_degrees = Vector3(-26.0, 38.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)


## The knoll and the meadow round it, falling to a pale shore, in the cel shader's vertex colours.
func _build_ground() -> void:
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step: float = GROUND_SIZE / float(GROUND_STEPS)
	var half: float = GROUND_SIZE * 0.5
	for i: int in GROUND_STEPS + 1:
		for j: int in GROUND_STEPS + 1:
			var x: float = -half + float(i) * step
			var z: float = -half + float(j) * step + 20.0
			var h: float = ground_height(x, z)
			var meadow: float = 0.5 + 0.5 * sin(x * 0.31 + z * 0.17) * cos(z * 0.23 - x * 0.07)
			var green: Color = Color(0.42, 0.6, 0.25).lerp(Color(0.56, 0.68, 0.3), meadow)
			var sand: float = smoothstep(SEA_LEVEL + 1.4, SEA_LEVEL + 0.2, h)
			tool.set_color(green.lerp(Color(0.84, 0.77, 0.58), sand))
			tool.set_uv(Vector2(x, z))
			tool.add_vertex(Vector3(x, h, z))
	for i: int in GROUND_STEPS:
		for j: int in GROUND_STEPS:
			var a: int = i * (GROUND_STEPS + 1) + j
			var b: int = a + 1
			var c: int = a + GROUND_STEPS + 1
			var d: int = c + 1
			# Godot's front faces wind clockwise seen from above.
			tool.add_index(a)
			tool.add_index(c)
			tool.add_index(b)
			tool.add_index(b)
			tool.add_index(c)
			tool.add_index(d)
	tool.generate_normals()
	var ground: MeshInstance3D = MeshInstance3D.new()
	ground.name = "Knoll"
	ground.mesh = tool.commit()
	ground.material_override = StorybookMaterial.vertex_colored()
	add_child(ground)
	var sea: MeshInstance3D = MeshInstance3D.new()
	sea.name = "TheSound"
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(5000.0, 5000.0)
	sea.mesh = plane
	var water: StandardMaterial3D = StandardMaterial3D.new()
	water.albedo_color = SEA_COLOR
	water.roughness = 0.42
	water.metallic_specular = 0.7
	sea.material_override = water
	sea.position = Vector3(0.0, SEA_LEVEL, -1500.0)
	add_child(sea)


## The Crown and Miller's Oak across The Sound, and the far isles, softened by the haze.
func _build_far() -> void:
	var stone: ShaderMaterial = StorybookMaterial.make(DISTANT_STONE)
	var meadow: ShaderMaterial = StorybookMaterial.make(DISTANT_MEADOW)
	# The Crown: a broad dome and two shoulders, lumpy as an old caldera rim.
	_mound("TheCrown", CROWN, stone)
	_mound("CrownShoulder", Vector4(CROWN.x - CROWN.w * 0.55, CROWN.y + 40.0, CROWN.z * 0.62, CROWN.w * 0.6), stone)
	_mound("CrownShoulder", Vector4(CROWN.x + CROWN.w * 0.6, CROWN.y - 30.0, CROWN.z * 0.5, CROWN.w * 0.55), stone)
	var crest: Vector3 = Vector3(CROWN.x, SEA_LEVEL + CROWN.z, CROWN.y)
	var trunk: MeshInstance3D = MeshInstance3D.new()
	trunk.name = "WorldTreeTrunk"
	var bole: CylinderMesh = CylinderMesh.new()
	bole.top_radius = 3.0
	bole.bottom_radius = 7.0
	bole.height = 46.0
	trunk.mesh = bole
	trunk.material_override = StorybookMaterial.make(Color(0.46, 0.4, 0.38))
	trunk.position = crest + Vector3(0.0, 14.0, 0.0)
	add_child(trunk)
	for crown: Vector4 in [Vector4(0.0, 48.0, 0.0, 30.0), Vector4(-20.0, 40.0, 6.0, 20.0), Vector4(22.0, 42.0, -4.0, 21.0)]:
		var leaves: MeshInstance3D = MeshInstance3D.new()
		leaves.name = "WorldTreeCrown"
		var ball: SphereMesh = SphereMesh.new()
		ball.radius = crown.w
		ball.height = crown.w * 1.5
		leaves.mesh = ball
		leaves.material_override = StorybookMaterial.make(Color(0.62, 0.7, 0.42))
		leaves.position = crest + Vector3(crown.x, crown.y, crown.z)
		add_child(leaves)
	for isle: Vector4 in FAR_ISLES:
		_mound("FarIsle", isle, meadow)


## A conical isle at (x, z), `height` tall and `radius` wide at the waterline.
func _mound(mound_name: String, at: Vector4, material: Material) -> void:
	var mound: MeshInstance3D = MeshInstance3D.new()
	mound.name = mound_name
	var cone: CylinderMesh = CylinderMesh.new()
	cone.top_radius = at.w * 0.3
	cone.bottom_radius = at.w
	cone.height = at.z
	cone.radial_segments = 24
	mound.mesh = cone
	mound.material_override = material
	mound.position = Vector3(at.x, SEA_LEVEL + at.z * 0.5, at.y)
	add_child(mound)


func _build_orchard() -> void:
	var apple: ArrayMesh = CalderaKit.atelier_mesh(IslandBuilder.Species.ORCHARD_TREE)
	if apple == null:
		return
	for index: int in ORCHARD.size():
		var spot: Vector2 = ORCHARD[index]
		var tree: MeshInstance3D = MeshInstance3D.new()
		tree.name = "AppleTree"
		tree.mesh = apple
		tree.position = Vector3(spot.x, ground_height(spot.x, spot.y) - 0.05, spot.y)
		tree.rotation.y = float(index) * 1.7
		tree.scale = Vector3.ONE * (0.85 + 0.08 * float(index % 3))
		add_child(tree)
	var fern: ArrayMesh = CalderaKit.atelier_mesh(IslandBuilder.Species.FERN_TUFT)
	if fern == null:
		return
	for index: int in FERNS.size():
		var spot: Vector2 = FERNS[index]
		var tuft: MeshInstance3D = MeshInstance3D.new()
		tuft.name = "Fern"
		tuft.mesh = fern
		tuft.position = Vector3(spot.x, ground_height(spot.x, spot.y) - 0.03, spot.y)
		tuft.rotation.y = float(index) * 2.3
		tuft.scale = Vector3.ONE * (0.7 + 0.12 * float(index % 4))
		add_child(tuft)


## The Level 1 youth on the crest, turned a little toward the camera, in the easy idle.
func _build_hero() -> void:
	_hero_look = ArsenalCatalog.current.youth_appearance_for_seat(ClassLoadouts.DIRECTIONAL_FLOW_DPS, 0)
	hero = Node3D.new()
	hero.name = "Youth"
	var foot: Vector3 = Vector3(HERO_AT.x, ground_height(HERO_AT.x, HERO_AT.y), HERO_AT.y)
	hero.position = foot
	var toward: Vector3 = (CAMERA_AT + Vector3(-3.2, 0.0, 0.0)) - foot
	hero.rotation.y = atan2(-toward.x, -toward.z)
	add_child(hero)
	skeleton = HeroRigBuilder.build_hero_skeleton()
	skeleton.scale = Vector3.ONE * HeroAppearanceResource.YOUTH_SKELETON_SCALE
	hero.add_child(skeleton)
	var material: ShaderMaterial = HeroMeshAtelier.hero_material(_hero_look, _hero_look.patch_color)
	var meshes: Array[ArrayMesh] = HeroMeshAtelier.build_hero_surfaces(_hero_look, ArsenalCatalog.BRAMBLE_JERKIN)
	for index: int in meshes.size():
		var surface: MeshInstance3D = MeshInstance3D.new()
		surface.name = ActorVisuals.REGION_NODES[index]
		surface.mesh = meshes[index]
		surface.skin = HeroRigBuilder.skin_of(skeleton)
		surface.material_override = material
		skeleton.add_child(surface)
		surface.skeleton = surface.get_path_to(skeleton)
	var satchel: Node3D = HeroMeshAtelier.build_scribe_satchel(material)
	satchel.position = ActorVisuals.YOUTH_SATCHEL_AT
	HeroRigBuilder.socket(skeleton, HeroRigBuilder.HIP_SATCHEL_SOCKET).add_child(satchel)
	kinematics = StorybookKinematicsModifier3D.new()
	kinematics.name = "StorybookKinematics"
	kinematics.move_speed = 6.6
	skeleton.add_child(kinematics)
	_pose_hero(0.0)


func _pose_hero(delta: float) -> void:
	if skeleton == null:
		return
	var frames: float = float(HeroCombatAnimator.clip_info(HeroCombatAnimator.YOUTH_IDLE).get("frames", 240))
	var frame: float = fmod(_age * HeroCombatAnimator.FPS, frames)
	var pose: Dictionary = HeroCombatAnimator.sample_pose(HeroCombatAnimator.YOUTH_IDLE, frame)
	var rotations: Array = pose["rotations"]
	for bone: int in HeroRigBuilder.BONE_COUNT:
		skeleton.set_bone_pose_rotation(bone, rotations[bone])
	skeleton.set_bone_pose_position(HeroRigBuilder.Bone.HIPS, HeroRigBuilder.local_rests()[HeroRigBuilder.Bone.HIPS].origin + (pose["hips"] as Vector3))
	skeleton.set_bone_pose_scale(HeroRigBuilder.Bone.HIPS, pose["scale"])
	# A sea breeze off The Sound lifts the cape.
	kinematics.wind = Vector4(0.85, 0.0, 0.53, 0.55 + 0.25 * sin(_age * 0.7))
	skeleton.advance(delta)


## Motes drifting up in the low sun: thistledown and the first fireflies.
func _build_motes() -> void:
	var motes: CPUParticles3D = CPUParticles3D.new()
	motes.name = "Motes"
	motes.amount = 70
	motes.lifetime = 9.0
	motes.preprocess = 9.0
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	# Behind the youth, never between the lens and the picture.
	motes.emission_box_extents = Vector3(9.0, 1.4, 3.5)
	motes.position = Vector3(-1.0, KNOLL_HEIGHT + 0.6, -3.5)
	motes.direction = Vector3(0.3, 1.0, 0.0)
	motes.spread = 40.0
	motes.gravity = Vector3(0.12, 0.05, 0.0)
	motes.initial_velocity_min = 0.05
	motes.initial_velocity_max = 0.22
	motes.scale_amount_min = 0.5
	motes.scale_amount_max = 1.3
	var dot: SphereMesh = SphereMesh.new()
	dot.radius = 0.025
	dot.height = 0.05
	dot.radial_segments = 6
	dot.rings = 3
	dot.material = StorybookMaterial.glowing(Color(1.0, 0.86, 0.5), 2.4)
	motes.mesh = dot
	add_child(motes)
