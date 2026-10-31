## Builds the instance scenes from code (Code-First Scene Safety), so nobody
## hand-edits their sub-resources. Re-run after changing anything here:
##   godot --headless --path . --script res://tools/build_levels.gd
##
## - Hub Town (hub_town.tscn): a safe walled plaza with four houses, a fountain,
##   a lantern-lit lane from four spawn pads to the Raid Portal to the Dojo.
## - Dungeon Dojo (dungeon_dojo.tscn): a 44 m greybox arena with low walls, six
##   pillars for cover in a ring round the boss, four spawn pads and an exit
##   portal back to Hub Town.
## Both share the same skeleton (Actors, Telegraphs, Effects, SpawnPoints and
## the split-screen Screens), which LevelBase expects.
extends SceneTree

const HUB_PATH: String = "res://src/levels/hub_town.tscn"
const DOJO_PATH: String = "res://src/levels/dungeon_dojo.tscn"
const HUB_SCRIPT: String = "res://src/levels/hub_town.gd"
const DOJO_SCRIPT: String = "res://src/levels/dungeon_dojo.gd"
const PORTAL_SCRIPT: String = "res://src/actors/raid_portal.gd"
const GRID_SCRIPT: String = "res://src/ui/split_screen_viewport_grid.gd"
const GRID_SHADER: String = "res://src/levels/greybox_grid.gdshader"

const FLOOR_THICKNESS: float = 1.0
const WALL_HEIGHT: float = 1.2
const WALL_THICKNESS: float = 1.0
const SPAWN_SPACING: float = 3.0
const SPAWN_PAD_COLORS: Array[Color] = [
	Color(0.32, 0.52, 0.9), Color(0.34, 0.76, 0.46), Color(0.92, 0.5, 0.22), Color(0.7, 0.45, 0.9),
]
const STONE_COLOR: Color = Color(0.58, 0.56, 0.53)
const WALL_COLOR: Color = Color(0.48, 0.47, 0.46)

# Dungeon Dojo
const DOJO_SIZE: float = 44.0
const PILLAR_COUNT: int = 6
const PILLAR_RING_RADIUS: float = 11.0
const PILLAR_RADIUS: float = 1.1
## Taller than a player (cover) but under the cameras' eye line, so they never wall off a view.
const PILLAR_HEIGHT: float = 3.2
const DOJO_SPAWN_Z: float = 15.0
const BOSS_POSITION: Vector3 = Vector3(0.0, 0.0, -2.0)
const EXIT_PORTAL_POSITION: Vector3 = Vector3(0.0, 0.0, 18.8)
const EXIT_PORTAL_COLOR: Color = Color(0.95, 0.8, 0.4)

# Hub Town
const HUB_SIZE: float = 40.0
const HUB_SPAWN_Z: float = 12.0
const RAID_PORTAL_POSITION: Vector3 = Vector3(0.0, 0.0, -13.0)
const RAID_PORTAL_COLOR: Color = Color(0.55, 0.5, 1.0)
const HOUSE_SIZE: Vector3 = Vector3(6.0, 3.6, 5.0)
const HOUSE_SPOTS: Array[Vector3] = [Vector3(-13.0, 0.0, -9.0), Vector3(13.0, 0.0, -9.0), Vector3(-13.0, 0.0, 7.0), Vector3(13.0, 0.0, 7.0)]
const HOUSE_COLORS: Array[Color] = [Color(0.78, 0.7, 0.58), Color(0.7, 0.74, 0.66), Color(0.74, 0.66, 0.7), Color(0.68, 0.7, 0.78)]
const ROOF_COLOR: Color = Color(0.55, 0.3, 0.26)
const FOUNTAIN_RADIUS: float = 2.2
## Off to the side, so the lane from the spawn pads to the Raid Portal stays clear.
const FOUNTAIN_POSITION: Vector3 = Vector3(-8.5, 0.0, 0.0)
## Lanterns line the lane to the portal.
const LANTERN_SPOTS: Array[Vector3] = [
	Vector3(-5.5, 0.0, -8.0), Vector3(5.5, 0.0, -8.0), Vector3(-5.5, 0.0, 0.0), Vector3(5.5, 0.0, 0.0),
	Vector3(-5.5, 0.0, 8.0), Vector3(5.5, 0.0, 8.0),
]
const LANTERN_COLOR: Color = Color(1.0, 0.8, 0.45)


func _initialize() -> void:
	var results: PackedStringArray = PackedStringArray()
	results.append("%s -> %s" % [HUB_PATH, error_string(_save(_build_hub(), HUB_PATH))])
	results.append("%s -> %s" % [DOJO_PATH, error_string(_save(_build_dojo(), DOJO_PATH))])
	print("build_levels: " + ", ".join(results))
	quit(0 if not ", ".join(results).contains("rror") else 1)


# --- Hub Town -------------------------------------------------------------

func _build_hub() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "HubTown"
	root.set_script(load(HUB_SCRIPT))
	root.add_child(_environment(true))
	root.add_child(_sun())
	var town: Node3D = _node3d("Town")
	root.add_child(town)
	var cobbles: ShaderMaterial = ShaderMaterial.new()
	cobbles.shader = load(GRID_SHADER)
	cobbles.set_shader_parameter(&"base_color", Color(0.55, 0.52, 0.47))
	cobbles.set_shader_parameter(&"minor_color", Color(0.5, 0.47, 0.42))
	cobbles.set_shader_parameter(&"major_color", Color(0.45, 0.42, 0.38))
	_add_floor_and_walls(town, HUB_SIZE, cobbles)
	for index: int in HOUSE_SPOTS.size():
		town.add_child(_house("House%d" % (index + 1), HOUSE_SPOTS[index], HOUSE_COLORS[index]))
	town.add_child(_fountain())
	for index: int in LANTERN_SPOTS.size():
		town.add_child(_lantern("Lantern%d" % (index + 1), LANTERN_SPOTS[index]))
	root.add_child(_portal("RaidPortal", InstanceManager.DUNGEON_DOJO, "Raid: Dojo Warden", RAID_PORTAL_COLOR, RAID_PORTAL_POSITION))
	_add_level_skeleton(root, HUB_SPAWN_Z)
	return root


func _house(house_name: String, where: Vector3, color: Color) -> StaticBody3D:
	var house: StaticBody3D = _box_body(house_name, HOUSE_SIZE, where + Vector3(0.0, HOUSE_SIZE.y * 0.5, 0.0), _material(color))
	var roof_mesh: PrismMesh = PrismMesh.new()
	roof_mesh.size = Vector3(HOUSE_SIZE.x + 0.6, 1.8, HOUSE_SIZE.z + 0.6)
	roof_mesh.material = _material(ROOF_COLOR)
	var roof: MeshInstance3D = MeshInstance3D.new()
	roof.name = "Roof"
	roof.mesh = roof_mesh
	roof.position = Vector3(0.0, HOUSE_SIZE.y * 0.5 + 0.9, 0.0)
	house.add_child(roof)
	var door_mesh: BoxMesh = BoxMesh.new()
	door_mesh.size = Vector3(1.1, 2.0, 0.1)
	door_mesh.material = _material(Color(0.35, 0.24, 0.16))
	var door: MeshInstance3D = MeshInstance3D.new()
	door.name = "Door"
	door.mesh = door_mesh
	# Doors face the middle of the plaza.
	var toward_middle: float = -signf(where.x)
	door.position = Vector3(toward_middle * (HOUSE_SIZE.x * 0.5 + 0.05), -HOUSE_SIZE.y * 0.5 + 1.0, 0.0)
	door.rotation = Vector3(0.0, PI * 0.5, 0.0)
	house.add_child(door)
	return house


func _fountain() -> StaticBody3D:
	var fountain: StaticBody3D = StaticBody3D.new()
	fountain.name = "Fountain"
	fountain.position = FOUNTAIN_POSITION
	fountain.collision_layer = ActorBase.LAYER_WORLD
	fountain.collision_mask = 0
	var basin_shape: CylinderShape3D = CylinderShape3D.new()
	basin_shape.radius = FOUNTAIN_RADIUS
	basin_shape.height = 0.7
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = basin_shape
	collision.position = Vector3(0.0, 0.35, 0.0)
	fountain.add_child(collision)
	fountain.add_child(_cylinder_mesh("Basin", FOUNTAIN_RADIUS, FOUNTAIN_RADIUS, 0.7, 0.35, _material(STONE_COLOR)))
	var water: StandardMaterial3D = _material(Color(0.35, 0.6, 0.9))
	water.emission_enabled = true
	water.emission = Color(0.2, 0.4, 0.7)
	fountain.add_child(_cylinder_mesh("Water", FOUNTAIN_RADIUS - 0.25, FOUNTAIN_RADIUS - 0.25, 0.05, 0.68, water))
	fountain.add_child(_cylinder_mesh("Spout", 0.25, 0.45, 1.8, 0.9, _material(STONE_COLOR)))
	return fountain


func _lantern(lantern_name: String, where: Vector3) -> Node3D:
	var post: Node3D = _node3d(lantern_name)
	post.position = where
	post.add_child(_cylinder_mesh("Post", 0.08, 0.1, 2.4, 1.2, _material(Color(0.25, 0.22, 0.2))))
	var glow: StandardMaterial3D = _material(LANTERN_COLOR)
	glow.emission_enabled = true
	glow.emission = LANTERN_COLOR
	glow.emission_energy_multiplier = 2.5
	var lamp_mesh: SphereMesh = SphereMesh.new()
	lamp_mesh.radius = 0.22
	lamp_mesh.height = 0.44
	lamp_mesh.material = glow
	var lamp: MeshInstance3D = MeshInstance3D.new()
	lamp.name = "Lamp"
	lamp.mesh = lamp_mesh
	lamp.position = Vector3(0.0, 2.5, 0.0)
	post.add_child(lamp)
	return post


# --- Dungeon Dojo ---------------------------------------------------------

func _build_dojo() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "DungeonDojo"
	root.set_script(load(DOJO_SCRIPT))
	root.add_child(_environment(false))
	root.add_child(_sun())
	var arena: Node3D = _node3d("Arena")
	root.add_child(arena)
	var grid_material: ShaderMaterial = ShaderMaterial.new()
	grid_material.shader = load(GRID_SHADER)
	_add_floor_and_walls(arena, DOJO_SIZE, grid_material)
	var stone: StandardMaterial3D = _material(STONE_COLOR)
	for index: int in PILLAR_COUNT:
		var angle: float = TAU * float(index) / PILLAR_COUNT
		var where: Vector3 = BOSS_POSITION + Vector3(cos(angle), 0.0, sin(angle)) * PILLAR_RING_RADIUS
		arena.add_child(_pillar("Pillar%d" % (index + 1), where, stone))
	var boss_spawn: Marker3D = Marker3D.new()
	boss_spawn.name = "BossSpawn"
	boss_spawn.position = BOSS_POSITION
	# Face south, toward the spawn pads.
	boss_spawn.rotation = Vector3(0.0, PI, 0.0)
	boss_spawn.add_child(_pad("Ring", 2.2, Color(0.35, 0.18, 0.2)))
	root.add_child(boss_spawn)
	root.add_child(_portal("ExitPortal", InstanceManager.HUB_TOWN, "Exit: Hub Town", EXIT_PORTAL_COLOR, EXIT_PORTAL_POSITION))
	_add_level_skeleton(root, DOJO_SPAWN_Z)
	return root


# --- Shared pieces --------------------------------------------------------

## Spawn pads, the runtime folders and the split-screen layer every level has.
func _add_level_skeleton(root: Node3D, spawn_z: float) -> void:
	var spawns: Node3D = _node3d("SpawnPoints")
	root.add_child(spawns)
	for index: int in 4:
		var marker: Marker3D = Marker3D.new()
		marker.name = "Spawn%d" % (index + 1)
		marker.position = Vector3((float(index) - 1.5) * SPAWN_SPACING, 0.0, spawn_z)
		marker.add_child(_pad("Pad", 0.8, SPAWN_PAD_COLORS[index]))
		spawns.add_child(marker)
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


func _add_floor_and_walls(parent: Node3D, size: float, floor_material: Material) -> void:
	parent.add_child(_box_body("Floor", Vector3(size, FLOOR_THICKNESS, size), Vector3(0.0, -FLOOR_THICKNESS * 0.5, 0.0), floor_material))
	var half: float = size * 0.5
	var wall_material: StandardMaterial3D = _material(WALL_COLOR)
	parent.add_child(_box_body("WallNorth", Vector3(size, WALL_HEIGHT, WALL_THICKNESS), Vector3(0.0, WALL_HEIGHT * 0.5, -half), wall_material))
	parent.add_child(_box_body("WallSouth", Vector3(size, WALL_HEIGHT, WALL_THICKNESS), Vector3(0.0, WALL_HEIGHT * 0.5, half), wall_material))
	parent.add_child(_box_body("WallWest", Vector3(WALL_THICKNESS, WALL_HEIGHT, size), Vector3(-half, WALL_HEIGHT * 0.5, 0.0), wall_material))
	parent.add_child(_box_body("WallEast", Vector3(WALL_THICKNESS, WALL_HEIGHT, size), Vector3(half, WALL_HEIGHT * 0.5, 0.0), wall_material))


func _portal(portal_name: String, target: StringName, title: String, color: Color, where: Vector3) -> Node3D:
	var portal: Node3D = Node3D.new()
	portal.name = portal_name
	portal.set_script(load(PORTAL_SCRIPT))
	portal.set(&"target_instance", target)
	portal.set(&"title", title)
	portal.set(&"portal_color", color)
	portal.position = where
	return portal


func _save(root: Node, path: String) -> Error:
	_own_all(root, root)
	var packed: PackedScene = PackedScene.new()
	var error: Error = packed.pack(root)
	if error == OK:
		error = ResourceSaver.save(packed, path)
	root.free()
	return error


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


func _cylinder_mesh(mesh_name: String, top: float, bottom: float, height: float, center_y: float, material: Material) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 24
	mesh.material = material
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = mesh_name
	visual.mesh = mesh
	visual.position = Vector3(0.0, center_y, 0.0)
	return visual


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
	var visual: MeshInstance3D = _cylinder_mesh("Mesh", PILLAR_RADIUS * 0.9, PILLAR_RADIUS, PILLAR_HEIGHT, 0.0, material)
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


## A dim dungeon sky for raids; a bright day for the town.
func _environment(daylight: bool) -> WorldEnvironment:
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	if daylight:
		sky_material.sky_top_color = Color(0.32, 0.5, 0.78)
		sky_material.sky_horizon_color = Color(0.7, 0.76, 0.82)
	else:
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
	environment.ambient_light_energy = 1.0 if daylight else 0.8
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
