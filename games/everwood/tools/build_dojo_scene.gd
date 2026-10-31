## Builds src/levels/dungeon_dojo.tscn from code (Code-First Scene Safety), so
## nobody hand-edits the scene file's sub-resources. Re-run after changing it:
##   godot --headless --path . --script res://tools/build_dojo_scene.gd
## The arena: a 44 m greybox floor with low walls, six pillars for cover in a
## ring round the boss, four spawn pads to the south and the boss in the middle.
extends SceneTree

const OUTPUT_PATH: String = "res://src/levels/dungeon_dojo.tscn"
const LEVEL_SCRIPT: String = "res://src/levels/dungeon_dojo.gd"
const GRID_SCRIPT: String = "res://src/ui/split_screen_viewport_grid.gd"
const GRID_SHADER: String = "res://src/levels/greybox_grid.gdshader"

const ARENA_SIZE: float = 44.0
const FLOOR_THICKNESS: float = 1.0
const WALL_HEIGHT: float = 1.2
const WALL_THICKNESS: float = 1.0
const PILLAR_COUNT: int = 6
const PILLAR_RING_RADIUS: float = 11.0
const PILLAR_RADIUS: float = 1.1
## Taller than a player (cover) but under the cameras' eye line, so they never wall off a view.
const PILLAR_HEIGHT: float = 3.2
const SPAWN_Z: float = 15.0
const SPAWN_SPACING: float = 3.0
const BOSS_POSITION: Vector3 = Vector3(0.0, 0.0, -2.0)
const SPAWN_PAD_COLORS: Array[Color] = [
	Color(0.32, 0.52, 0.9), Color(0.34, 0.76, 0.46), Color(0.92, 0.5, 0.22), Color(0.7, 0.45, 0.9),
]
const STONE_COLOR: Color = Color(0.58, 0.56, 0.53)
const WALL_COLOR: Color = Color(0.48, 0.47, 0.46)


func _initialize() -> void:
	var root: Node3D = Node3D.new()
	root.name = "DungeonDojo"
	root.set_script(load(LEVEL_SCRIPT))

	root.add_child(_environment())
	root.add_child(_sun())

	var arena: Node3D = _node3d("Arena")
	root.add_child(arena)
	var grid_material: ShaderMaterial = ShaderMaterial.new()
	grid_material.shader = load(GRID_SHADER)
	arena.add_child(_box_body("Floor", Vector3(ARENA_SIZE, FLOOR_THICKNESS, ARENA_SIZE), Vector3(0.0, -FLOOR_THICKNESS * 0.5, 0.0), grid_material))
	var half: float = ARENA_SIZE * 0.5
	var wall_material: StandardMaterial3D = _material(WALL_COLOR)
	arena.add_child(_box_body("WallNorth", Vector3(ARENA_SIZE, WALL_HEIGHT, WALL_THICKNESS), Vector3(0.0, WALL_HEIGHT * 0.5, -half), wall_material))
	arena.add_child(_box_body("WallSouth", Vector3(ARENA_SIZE, WALL_HEIGHT, WALL_THICKNESS), Vector3(0.0, WALL_HEIGHT * 0.5, half), wall_material))
	arena.add_child(_box_body("WallWest", Vector3(WALL_THICKNESS, WALL_HEIGHT, ARENA_SIZE), Vector3(-half, WALL_HEIGHT * 0.5, 0.0), wall_material))
	arena.add_child(_box_body("WallEast", Vector3(WALL_THICKNESS, WALL_HEIGHT, ARENA_SIZE), Vector3(half, WALL_HEIGHT * 0.5, 0.0), wall_material))
	var stone: StandardMaterial3D = _material(STONE_COLOR)
	for index: int in PILLAR_COUNT:
		var angle: float = TAU * float(index) / PILLAR_COUNT
		var where: Vector3 = BOSS_POSITION + Vector3(cos(angle), 0.0, sin(angle)) * PILLAR_RING_RADIUS
		arena.add_child(_pillar("Pillar%d" % (index + 1), where, stone))

	var spawns: Node3D = _node3d("SpawnPoints")
	root.add_child(spawns)
	for index: int in 4:
		var marker: Marker3D = Marker3D.new()
		marker.name = "Spawn%d" % (index + 1)
		marker.position = Vector3((float(index) - 1.5) * SPAWN_SPACING, 0.0, SPAWN_Z)
		marker.add_child(_pad("Pad", 0.8, SPAWN_PAD_COLORS[index]))
		spawns.add_child(marker)

	var boss_spawn: Marker3D = Marker3D.new()
	boss_spawn.name = "BossSpawn"
	boss_spawn.position = BOSS_POSITION
	# Face south, toward the spawn pads.
	boss_spawn.rotation = Vector3(0.0, PI, 0.0)
	boss_spawn.add_child(_pad("Ring", 2.2, Color(0.35, 0.18, 0.2)))
	root.add_child(boss_spawn)

	root.add_child(_node3d("Actors"))
	root.add_child(_node3d("Telegraphs"))
	root.add_child(_node3d("Effects"))

	var screens: CanvasLayer = CanvasLayer.new()
	screens.name = "Screens"
	root.add_child(screens)
	var grid: Control = Control.new()
	grid.name = "Grid"
	grid.set_script(load(GRID_SCRIPT))
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screens.add_child(grid)
	var banner: Label = Label.new()
	banner.name = "Banner"
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.offset_top = 6.0
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override(&"font_size", 15)
	banner.add_theme_color_override(&"font_outline_color", Color.BLACK)
	banner.add_theme_constant_override(&"outline_size", 6)
	banner.modulate = Color(1.0, 1.0, 1.0, 0.85)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screens.add_child(banner)

	_own_all(root, root)
	var packed: PackedScene = PackedScene.new()
	var error: Error = packed.pack(root)
	if error == OK:
		error = ResourceSaver.save(packed, OUTPUT_PATH)
	print("build_dojo_scene: %s -> %s" % [OUTPUT_PATH, error_string(error)])
	root.free()
	quit(0 if error == OK else 1)


func _own_all(node: Node, scene_root: Node) -> void:
	for child: Node in node.get_children():
		child.owner = scene_root
		_own_all(child, scene_root)


func _node3d(node_name: String) -> Node3D:
	var node: Node3D = Node3D.new()
	node.name = node_name
	return node


func _material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material


func _box_body(body_name: String, size: Vector3, where: Vector3, material: Material) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = body_name
	body.position = where
	body.collision_layer = ActorBase.LAYER_WORLD
	body.collision_mask = 0
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	body.add_child(collision)
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = "Mesh"
	visual.mesh = mesh
	body.add_child(visual)
	return body


func _pillar(body_name: String, where: Vector3, material: Material) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = body_name
	body.position = where + Vector3(0.0, PILLAR_HEIGHT * 0.5, 0.0)
	body.collision_layer = ActorBase.LAYER_WORLD
	body.collision_mask = 0
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = PILLAR_RADIUS
	shape.height = PILLAR_HEIGHT
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	body.add_child(collision)
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = PILLAR_RADIUS * 0.9
	mesh.bottom_radius = PILLAR_RADIUS
	mesh.height = PILLAR_HEIGHT
	mesh.radial_segments = 16
	mesh.material = material
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = "Mesh"
	visual.mesh = mesh
	body.add_child(visual)
	return body


func _pad(pad_name: String, radius: float, color: Color) -> MeshInstance3D:
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.04
	disc.radial_segments = 32
	disc.material = _material(color)
	var pad: MeshInstance3D = MeshInstance3D.new()
	pad.name = pad_name
	pad.mesh = disc
	pad.position = Vector3(0.0, 0.02, 0.0)
	return pad


func _environment() -> WorldEnvironment:
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.16, 0.2, 0.3)
	sky_material.sky_horizon_color = Color(0.45, 0.47, 0.52)
	sky_material.ground_horizon_color = Color(0.3, 0.3, 0.32)
	sky_material.ground_bottom_color = Color(0.12, 0.12, 0.14)
	var sky: Sky = Sky.new()
	sky.sky_material = sky_material
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.8
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.glow_enabled = true
	environment.glow_intensity = 0.6
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = environment
	return world_environment


func _sun() -> DirectionalLight3D:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(35.0), 0.0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.95, 0.88)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	return sun
