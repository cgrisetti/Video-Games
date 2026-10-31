class_name BerryField
extends Node3D

# Berry Rush's field: a sunken raspberry glade ringed by a hedge, with a creek winding across it,
# two arched footbridges, the woods and far hills beyond, and every round a new scatter of trees
# (which block you), and rocks and logs (which you can jump over or stand on).
# The rules for the field and its obstacles are the same as the three.js game's; the look is new.

const ARENA_SIZE := 40.0
const HEDGE_THICKNESS := 1.2
const HEDGE_HEIGHT := 1.7 # Low enough to see the woods over.
const PLAY_HALF := ARENA_SIZE / 2.0 - HEDGE_THICKNESS # From the middle to the inside of the hedge.
const START_Z := 4.0 # The gnome starts a little south of the middle, on dry land.
const GROUND_SIZE := 110.0
const WOODS_REACH := 46.0
# Obstacles, placed fresh every round.
const TREE_COUNT := 14
const TREE_MIX := ["oak", "oak", "maple", "maple", "poplar", "poplar"] # The rest are pines.
const TREE_SIZES := Vector2(1.0, 1.3) # Smallest and biggest, compared with an ordinary field tree.
const TREE_FADE := 0.7 # How far a tree fades when it's between the camera and the gnome.
const ROCK_COUNT := 12
const ROCK_WIDTHS := Vector2(0.55, 0.75)
const ROCK_HEIGHTS := Vector2(0.55, 0.7)
const LOG_COUNT := 4
const TRUNK_DIAMETER := 0.32
const LOG_THICKNESSES := Vector2(TRUNK_DIAMETER * 1.0, TRUNK_DIAMETER * 1.3)
const LOG_LENGTHS := Vector2(2.0 * 0.75 + 0.3, 3.2 * 1.3 - 0.3)
const OBSTACLE_GAP := 1.2 # Space always left between them, so the gnome can squeeze through.
const START_CLEARING := 4.0 # Nothing this close to where the gnome starts.
# How each kind of tree looks and how much room it takes: [Foliage kind, palette, size, the
# radius you bump into, how far its leaves spread, how tall it is].
const TREES := {
	"oak": ["oak", "oak", 0.62, 0.42, 1.6, 4.4],
	"maple": ["oak", "rust", 0.6, 0.42, 1.5, 4.3], # A red autumn maple.
	"poplar": ["birch", "gold", 0.72, 0.3, 1.0, 4.4], # A yellow tulip poplar.
	"pine": ["pine", "", 0.55, 0.62, 1.1, 3.6],
}
# How much grass grows, for each graphics setting.
const GRASS := {"low": 9000, "medium": 26000, "high": 52000}

var bridges: Array[Dictionary] = []
var obstacles: Array[Dictionary] = [] # Each: {position, radius, height, room}. Worms steer round them.
var lanterns: Array[OmniLight3D] = []
var rng := RandomNumberGenerator.new()

var _railings: Array[Dictionary] = [] # The bridges' sides and lantern posts: they stay put.
var _trees: Array[Dictionary] = []
var _rocks: Array[Node3D] = []
var _logs: Array[Node3D] = []
var _grass_material: ShaderMaterial
var _grass: Array[MultiMeshInstance3D] = []


func _ready() -> void:
	bridges = Creek.bridges()
	var build_rng := RandomNumberGenerator.new()
	build_rng.seed = 41
	var mask := Meadow.path_mask(GROUND_SIZE, _bank_distance, _hedge_distance)
	var ground := Meadow.ground(GROUND_SIZE, mask, height_at, false, 220)
	ground.material_override.set_shader_parameter("dirt_light", Vector3(0.55, 0.46, 0.34))
	ground.material_override.set_shader_parameter("dirt_dark", Vector3(0.33, 0.27, 0.2))
	add_child(ground)
	add_child(_ground_body())
	add_child(_water())
	add_child(Meadow.far_hills(70.0, 150.0, 23))
	_add_hedges(build_rng)
	_add_gate()
	for bridge in bridges:
		_add_bridge(bridge)
	_add_woods(build_rng)
	_add_canes(build_rng)
	add_child(Meadow.flowers(260, Rect2(-PLAY_HALF, -PLAY_HALF, PLAY_HALF * 2.0, PLAY_HALF * 2.0), build_rng, _grass_weight, height_at))
	grow_grass(Settings.get_value("graphics"))
	for i in TREE_COUNT:
		var kind: String = TREE_MIX[i] if i < TREE_MIX.size() else "pine"
		_trees.append(_make_tree(kind, build_rng))


# --- The ground and creek ---

# The height of the ground (grass, banks, creek bed), rising into the woods outside the hedge.
func height_at(x: float, z: float) -> float:
	var outside := maxf(absf(x), absf(z)) - ARENA_SIZE / 2.0
	var rise := smoothstep(2.0, 14.0, outside)
	return Creek.terrain_height(x, z) + rise * (1.4 + 0.8 * sin(x * 0.11 + z * 0.07) * cos(z * 0.09))


# What you'd stand on: the ground, or a bridge.
func floor_at(x: float, z: float) -> float:
	return maxf(height_at(x, z), Creek.ground_height(x, z, bridges))


func in_water(x: float, z: float) -> bool:
	return Creek.ground_height(x, z, bridges) < Creek.WATER_LEVEL and Creek.distance(x, z) < Creek.HALF_WIDTH


func _bank_distance(x: float, z: float) -> float:
	return Creek.distance(x, z) - Creek.HALF_WIDTH - 0.2 # Muddy banks, worn bare.


func _hedge_distance(x: float, z: float) -> float:
	var inside := PLAY_HALF - maxf(absf(x), absf(z))
	return inside if inside > -HEDGE_THICKNESS else INF # Shade at the foot of the hedge, inside only.


# The ground as something solid to walk on, banks and all: a height map, every half metre.
func _ground_body() -> StaticBody3D:
	var spacing := 0.5
	var samples := int(ARENA_SIZE * 1.4 / spacing) + 1
	var shape := HeightMapShape3D.new()
	shape.map_width = samples
	shape.map_depth = samples
	var heights := PackedFloat32Array()
	heights.resize(samples * samples)
	var half := (samples - 1) * spacing / 2.0
	for row in samples:
		for column in samples:
			heights[row * samples + column] = height_at(column * spacing - half, row * spacing - half) / spacing
	shape.map_data = heights
	var body := StaticBody3D.new()
	var holder := CollisionShape3D.new()
	holder.shape = shape
	holder.scale = Vector3.ONE * spacing
	body.add_child(holder)
	return body


# The water: a strip following the creek, from one side of the woods to the other.
func _water() -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 160
	var reach := 60.0
	for i in steps:
		var rows := []
		for k in 2:
			var along := lerpf(-reach, reach, float(i + k) / steps)
			var middle := Creek.middle_at(along)
			var row := []
			for side: float in [-1.0, 1.0]:
				var across := middle + side * (Creek.HALF_WIDTH + 0.3)
				row.append(Vector3((across - along) / sqrt(2.0), Creek.WATER_LEVEL, (across + along) / sqrt(2.0)))
			rows.append(row)
		for corner: Vector3 in [rows[0][0], rows[1][0], rows[1][1], rows[0][0], rows[1][1], rows[0][1]]:
			tool.set_normal(Vector3.UP)
			tool.add_vertex(corner)
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/water.gdshader")
	material.set_shader_parameter("bend_rate", Creek.BEND_RATE)
	var made := Art.instance(tool.commit(), material, Vector3.ZERO, false)
	made.name = "Water"
	return made


# --- Around the edge ---

func _add_hedges(build_rng: RandomNumberGenerator) -> void:
	var half := ARENA_SIZE / 2.0
	var line := half - HEDGE_THICKNESS / 2.0
	var gap := Gates.OPENING / 2.0 + 0.6
	var runs := [
		[Vector3(-half, 0, -line), Vector3(half, 0, -line)],
		[Vector3(-line, 0, -half), Vector3(-line, 0, half)],
		[Vector3(line, 0, -half), Vector3(line, 0, half)],
		[Vector3(-half, 0, line), Vector3(-gap, 0, line)], # The south hedge, either side of the gate.
		[Vector3(gap, 0, line), Vector3(half, 0, line)],
	]
	for run: Array in runs:
		var hedge := Foliage.hedge(run[0], run[1], HEDGE_THICKNESS, HEDGE_HEIGHT * build_rng.randf_range(0.97, 1.05), build_rng)
		add_child(hedge)


# The garden gate you came in by, in the middle of the south hedge, its sign facing out to the woods.
# (To leave, pick "Return to the Glenn" in the pause menu.) Something invisible stops you walking out.
func _add_gate() -> void:
	var gate := Gates.garden_gate("Berry Rush", true)
	gate.position = Vector3(0, 0, ARENA_SIZE / 2.0 - HEDGE_THICKNESS / 2.0)
	add_child(gate)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(Gates.OPENING + 1.2, 3.0, 0.4)
	shape.shape = box
	shape.position = gate.position + Vector3(0, 1.5, 0)
	body.add_child(shape)
	add_child(body)


# The woods all round, outside the hedge: oaks, birches and pines, some in autumn colour.
func _add_woods(build_rng: RandomNumberGenerator) -> void:
	var groves := FastNoiseLite.new()
	groves.seed = 17
	groves.frequency = 0.05
	var spacing := 4.6 / sqrt(_woods_amount())
	var steps := int(WOODS_REACH * 2.0 / spacing)
	for gz in steps:
		for gx in steps:
			var x := -WOODS_REACH + (gx + build_rng.randf_range(0.1, 0.9)) * spacing
			var z := -WOODS_REACH + (gz + build_rng.randf_range(0.1, 0.9)) * spacing
			var outside := maxf(absf(x), absf(z)) - ARENA_SIZE / 2.0
			if outside < 1.4 or Vector2(x, z).length() > WOODS_REACH or Creek.distance(x, z) < Creek.HALF_WIDTH + 0.6:
				continue
			if z > ARENA_SIZE / 2.0 and absf(x) < 9.0 and z < ARENA_SIZE / 2.0 + 14.0:
				continue # Room for the camera behind the gate.
			var grove := groves.get_noise_2d(x, z)
			var kind := "pine" if grove < -0.2 else ("birch" if grove > 0.3 else "oak")
			var palette := ""
			if kind != "pine" and build_rng.randf() < 0.3:
				palette = ["amber", "rust", "gold"][build_rng.randi() % 3]
			var depth := clampf(outside / 18.0, 0.0, 1.0)
			var tree := Foliage.tree(kind, build_rng, lerpf(0.85, 1.3, depth) * build_rng.randf_range(0.85, 1.15), palette)
			tree.position = Vector3(x, height_at(x, z) - 0.1, z)
			tree.rotation.y = build_rng.randf() * TAU
			if outside > 8.0:
				_no_leaf_shadows(tree)
			add_child(tree)


func _woods_amount() -> float:
	return {"low": 0.6, "medium": 0.85, "high": 1.0}.get(Settings.get_value("graphics"), 1.0)


static func _no_leaf_shadows(tree: Node3D) -> void:
	for part: GeometryInstance3D in tree.find_children("*", "GeometryInstance3D", false, false):
		if part.material_override is ShaderMaterial and part.material_override.shader == Art.LEAVES_SHADER:
			part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# Raspberry canes along the inside of the hedge: leafy bushes hung with ripe berries.
func _add_canes(build_rng: RandomNumberGenerator) -> void:
	var berries := MultiMesh.new()
	berries.transform_format = MultiMesh.TRANSFORM_3D
	var berry := SphereMesh.new()
	berry.radius = 0.045
	berry.height = 0.1
	berry.radial_segments = 8
	berry.rings = 5
	berries.mesh = berry
	var spots: Array[Transform3D] = []
	var edge := PLAY_HALF - 0.45
	for i in 34:
		var t := build_rng.randf()
		var wall := build_rng.randi() % 4
		var along := lerpf(-edge, edge, t)
		var at: Vector3 = [Vector3(along, 0, -edge), Vector3(-edge, 0, along), Vector3(edge, 0, along), Vector3(along, 0, edge)][wall]
		if wall == 3 and absf(along) < 3.5:
			continue # Not across the gate.
		if Creek.distance(at.x, at.z) < Creek.HALF_WIDTH + 0.5:
			continue
		var size := build_rng.randf_range(0.6, 0.9)
		var bush := Foliage.bush(build_rng, size, "bush")
		bush.position = at
		add_child(bush)
		for k in build_rng.randi_range(5, 9):
			var dot := Vector3(build_rng.randfn(), build_rng.randf_range(0.2, 1.1), build_rng.randfn()).normalized()
			spots.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * build_rng.randf_range(0.8, 1.3)), at + Vector3(dot.x * 0.6, 0.35 + dot.y * 0.45, dot.z * 0.6) * size))
	berries.instance_count = spots.size()
	for i in spots.size():
		berries.set_instance_transform(i, spots[i])
	var made := MultiMeshInstance3D.new()
	made.multimesh = berries
	made.material_override = Art.material(Color("#c8285a"), 0.35, {"rim_enabled": true, "rim": 0.3, "clearcoat_enabled": true, "clearcoat": 0.6})
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(made)


# --- The bridges ---

# An arched footbridge across the creek: timber planks on stone footings, a railing each side,
# and a lantern at two corners. The deck is solid to walk on; the railings stop you walking off
# the sides (but you can jump over).
func _add_bridge(bridge: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "Bridge"
	root.position = bridge.center
	var span: Vector3 = bridge.span
	root.rotation.y = atan2(span.x, span.z) # The bridge is built running along z.
	add_child(root)
	var length := Creek.BRIDGE_LENGTH
	var width := Creek.BRIDGE_WIDTH
	var planks := 16
	var plank_wood := [Art.bark_material(Color("#a07650"), 2.5), Art.bark_material(Color("#8f6743"), 2.5)]
	var deck := SurfaceTool.new()
	deck.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in planks:
		var along := -length / 2.0 + (i + 0.5) * length / planks
		var plank := Art.box(Vector3(width, 0.08, length / planks - 0.03), plank_wood[i % 2], Vector3(0, Creek.deck_height(along) - 0.04, along))
		plank.rotation.x = atan(PI * Creek.BRIDGE_RISE / length * sin(PI * along / length))
		root.add_child(plank)
	# The deck's walking surface, for the physics: a strip following the arch.
	for i in 24:
		var a := -length / 2.0 + i * length / 24.0
		var b := a + length / 24.0
		var corners := [Vector3(-width / 2.0, Creek.deck_height(a), a), Vector3(width / 2.0, Creek.deck_height(a), a), Vector3(width / 2.0, Creek.deck_height(b), b), Vector3(-width / 2.0, Creek.deck_height(b), b)]
		for k: int in [0, 2, 1, 0, 3, 2]:
			deck.add_vertex(corners[k])
	var body := StaticBody3D.new()
	var surface := CollisionShape3D.new()
	surface.shape = deck.commit().create_trimesh_shape()
	body.add_child(surface)
	root.add_child(body)
	# Stone footings at both ends, where the bridge meets the bank.
	for end: float in [-1.0, 1.0]:
		var footing := Art.instance(Art.blob_mesh(0.5, 0.2, 31 + int(end)), Art.rock_material(Color("#a59c8c"), Color("#5f7a2c")), Vector3(0, -0.15, end * (length / 2.0 - 0.3)))
		footing.scale = Vector3(width * 0.62 / 0.5, 0.45, 0.8)
		root.add_child(footing)
	# Railings: posts and a handrail each side, with legs down into the creek bed.
	var post_wood := Art.bark_material(Color("#6e4a2b"), 3.0)
	for side: float in [-1.0, 1.0]:
		var x := side * (width / 2.0 - 0.06)
		var rail := PackedVector3Array()
		var thickness := PackedFloat32Array()
		for i in 17:
			var along := -length / 2.0 + 0.15 + i / 16.0 * (length - 0.3)
			rail.append(Vector3(x, Creek.deck_height(along) + Creek.RAIL_HEIGHT, along))
			thickness.append(0.045)
		root.add_child(Art.instance(Art.tube_mesh(rail, thickness, 7), post_wood))
		for i in 7:
			var along := -length / 2.0 + 0.15 + i / 6.0 * (length - 0.3)
			var bottom := Creek.deck_height(along) - 0.1
			var top := Creek.deck_height(along) + Creek.RAIL_HEIGHT
			root.add_child(Art.cylinder(0.05, 0.06, top - bottom, post_wood, Vector3(x, (top + bottom) / 2.0, along), 7))
		for end: float in [-1.0, 1.0]:
			var along := end * (Creek.BED_HALF_WIDTH + 0.5)
			var top := Creek.deck_height(along) - 0.08
			root.add_child(Art.cylinder(0.08, 0.09, top + Creek.DEPTH, post_wood, Vector3(side * (width / 2.0 - 0.2), (top - Creek.DEPTH) / 2.0, along), 7))
		# A low wall of the railing's height, for the physics: you can jump it, not walk through it.
		var wall := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.12, Creek.RAIL_HEIGHT + 0.2, length)
		wall.shape = box
		wall.position = Vector3(x, Creek.BRIDGE_RISE * 0.5 + Creek.RAIL_HEIGHT * 0.5, 0)
		body.add_child(wall)
	# Bumpers along the railings and lantern posts, for the inch worms to steer round.
	var flow: Vector3 = bridge.flow
	var count := int(round(length / 0.5))
	for side: float in [-1.0, 1.0]:
		for i in count + 1:
			var along := -length / 2.0 + float(i) / count * length
			var spot: Vector3 = bridge.center + span * along + flow * side * (width / 2.0 - 0.06)
			_railings.append({"position": spot, "radius": 0.1, "height": Creek.deck_height(along) + Creek.RAIL_HEIGHT, "room": 0.1})
	for corner: float in [-1.0, 1.0]:
		var lantern := Props.lantern(false)
		lantern.position = Vector3(corner * (width / 2.0 + 0.22), 0, corner * (length / 2.0 - 0.1))
		lantern.rotation.y = PI if corner > 0.0 else 0.0
		root.add_child(lantern)
		lanterns.append(lantern.get_meta("light"))
		var spot: Vector3 = bridge.center + span * (corner * (length / 2.0 - 0.1)) - flow * (corner * (width / 2.0 + 0.22))
		_railings.append({"position": spot, "radius": 0.12, "height": Props.LANTERN_HEIGHT, "room": 0.12})


# --- Grass ---

func grow_grass(level: String) -> void:
	for patch in _grass:
		patch.queue_free()
	_grass.clear()
	var grass_rng := RandomNumberGenerator.new()
	grass_rng.seed = 5
	var count: int = GRASS.get(level, GRASS.high)
	var inside := int(count * 0.75)
	_grass.assign(Meadow.grass(inside, Rect2(-PLAY_HALF, -PLAY_HALF, PLAY_HALF * 2.0, PLAY_HALF * 2.0), grass_rng, _grass_weight, height_at))
	_grass_material = _grass[0].material_override if not _grass.is_empty() else null
	_grass.append_array(Meadow.grass(count - inside, Rect2(-ARENA_SIZE / 2.0 - 12.0, -ARENA_SIZE / 2.0 - 12.0, ARENA_SIZE + 24.0, ARENA_SIZE + 24.0), grass_rng, _grass_weight, height_at, _grass_material))
	for patch in _grass:
		add_child(patch)


# How thick the grass grows: none in the water, thin on the banks, none under the hedge.
func _grass_weight(x: float, z: float) -> float:
	var hedge := absf(maxf(absf(x), absf(z)) - (ARENA_SIZE / 2.0 - HEDGE_THICKNESS / 2.0))
	if hedge < HEDGE_THICKNESS * 0.6:
		return 0.0
	if Vector2(x, z).length() > WOODS_REACH:
		return 0.0
	return smoothstep(Creek.HALF_WIDTH - 0.35, Creek.HALF_WIDTH + 0.5, Creek.distance(x, z)) # From just above the water line.


# Grass parts round the gnome's feet.
func push_grass(at: Vector3) -> void:
	if _grass_material:
		_grass_material.set_shader_parameter("player_position", at)


# --- Obstacles, new every round ---

func _make_tree(kind: String, build_rng: RandomNumberGenerator) -> Dictionary:
	var spec: Array = TREES[kind]
	var tree := Foliage.tree(spec[0], build_rng, spec[2], spec[1])
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = spec[3]
	cylinder.height = 8.0
	shape.shape = cylinder
	shape.position.y = 4.0
	body.add_child(shape)
	tree.add_child(body)
	tree.visible = false
	add_child(tree)
	var meshes: Array[GeometryInstance3D] = []
	meshes.assign(tree.find_children("*", "GeometryInstance3D", true, false))
	return {"node": tree, "body": body, "block": spec[3], "canopy": spec[4], "height": spec[5], "meshes": meshes, "fade": 0.0}


# Scatter the trees, rocks and logs to new spots, with new sizes, for a new round. Logs go first,
# since long things are the hardest to fit.
func place_obstacles() -> void:
	obstacles.clear()
	obstacles.append_array(_railings)
	for old in _rocks + _logs:
		old.queue_free()
	_rocks.clear()
	_logs.clear()
	for i in LOG_COUNT:
		var log := _place_log()
		if log:
			_logs.append(log)
	for tree in _trees:
		var size := rng.randf_range(TREE_SIZES.x, TREE_SIZES.y)
		var node: Node3D = tree.node
		node.scale = Vector3.ONE * size
		node.rotation.y = rng.randf() * TAU
		var spot := _open_spot(tree.block * size, tree.canopy * size)
		node.visible = spot != Vector3.INF
		(tree.body as StaticBody3D).process_mode = Node.PROCESS_MODE_INHERIT if node.visible else Node.PROCESS_MODE_DISABLED
		if node.visible:
			node.position = Vector3(spot.x, height_at(spot.x, spot.z) - 0.05, spot.z)
			obstacles.append({"position": Vector3(spot.x, 0, spot.z), "radius": tree.block * size, "height": INF, "room": tree.canopy * size})
		tree.size = size
	for i in ROCK_COUNT:
		var width := rng.randf_range(ROCK_WIDTHS.x, ROCK_WIDTHS.y)
		var height := rng.randf_range(ROCK_HEIGHTS.x, ROCK_HEIGHTS.y)
		var spot := _open_spot(0.9 * width, 0.9 * width)
		if spot == Vector3.INF:
			continue
		var rock := Props.rock(rng, width, height * 0.8)
		rock.position = Vector3(spot.x, height_at(spot.x, spot.z), spot.z)
		add_child(rock)
		_rocks.append(rock)
		obstacles.append({"position": Vector3(spot.x, 0, spot.z), "radius": 0.9 * width, "height": 0.93 * height, "room": 0.9 * width})


# Is x, z a good place for something `radius` wide? On dry land inside the hedge, clear of the
# start, the bridges and every other obstacle.
func is_open_spot(x: float, z: float, radius: float) -> bool:
	var half := PLAY_HALF - 1.5
	if absf(x) > half or absf(z) > half:
		return false
	if Vector2(x, z - START_Z).length() < START_CLEARING + radius:
		return false
	if Creek.distance(x, z) < Creek.HALF_WIDTH + radius + 0.5 or Creek.is_near_bridge(x, z, radius + 1.0, bridges):
		return false
	return not is_near_obstacle(x, z, radius + OBSTACLE_GAP)


func is_near_obstacle(x: float, z: float, gap: float) -> bool:
	for obstacle in obstacles:
		var spot: Vector3 = obstacle.position
		if Vector2(spot.x - x, spot.z - z).length() < obstacle.get("room", obstacle.radius) + gap:
			return true
	return false


func _open_spot(radius: float, room: float) -> Vector3:
	var half := PLAY_HALF - 1.5
	for attempt in 100:
		var x := rng.randf_range(-half, half)
		var z := rng.randf_range(-half, half)
		if is_open_spot(x, z, maxf(radius, room)):
			return Vector3(x, 0, z)
	return Vector3.INF


# Lay a log down somewhere open, at a random angle. For the worms it's a row of small circles
# along its length; for the gnome it's a solid log to jump over or stand on.
func _place_log() -> Node3D:
	var length := rng.randf_range(LOG_LENGTHS.x, LOG_LENGTHS.y)
	var thickness := rng.randf_range(LOG_THICKNESSES.x, LOG_THICKNESSES.y)
	var radius := thickness / 2.0
	var reach := length / 2.0 - radius
	var count := int(ceil(2.0 * reach / 0.15))
	var half := PLAY_HALF - 1.5
	for attempt in 100:
		var x := rng.randf_range(-half, half)
		var z := rng.randf_range(-half, half)
		var angle := rng.randf() * PI
		var circles: Array[Vector3] = []
		var fits := true
		for i in count + 1:
			var along := -reach + float(i) / count * 2.0 * reach
			var spot := Vector3(x + cos(angle) * along, 0, z - sin(angle) * along)
			if not is_open_spot(spot.x, spot.z, radius):
				fits = false
				break
			circles.append(spot)
		if not fits:
			continue
		var log := _make_log(length, thickness)
		log.position = Vector3(x, height_at(x, z), z)
		log.rotation.y = angle
		add_child(log)
		for spot in circles:
			obstacles.append({"position": spot, "radius": radius, "height": thickness, "room": radius})
		return log
	return null


# A mossy fallen log: bark round the outside, pale rings at the cut ends, solid to land on.
func _make_log(length: float, thickness: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Log"
	var radius := thickness / 2.0
	var points := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in 7:
		var t := i / 6.0
		points.append(Vector3(lerpf(-length / 2.0, length / 2.0, t), radius + sin(t * PI) * 0.02, rng.randf_range(-0.015, 0.015)))
		radii.append(radius * (1.0 + 0.04 * sin(t * 9.0)))
	root.add_child(Art.instance(Art.tube_mesh(points, radii, 14), Art.bark_material(Color("#5e4a3a"), 1.2)))
	var cut := Art.material(Color("#c9a77c"), 0.9)
	for end: float in [-1.0, 1.0]:
		var face := Art.cylinder(radius * 0.97, radius * 0.97, 0.02, cut, Vector3(end * length / 2.0, radius, 0), 14)
		face.rotation.z = PI / 2.0
		root.add_child(face)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = length
	shape.shape = cylinder
	shape.rotation.z = PI / 2.0
	shape.position.y = radius
	body.add_child(shape)
	root.add_child(body)
	return root


# --- Every frame ---

# Trees between the camera and the gnome (or right over its head) fade, so you never lose sight of it.
func fade_trees(camera: Camera3D, gnome_middle: Vector3, delta: float) -> void:
	for tree in _trees:
		var node: Node3D = tree.node
		if not node.visible:
			continue
		var size: float = tree.get("size", 1.0)
		var spot := node.global_position
		var overhead: bool = Vector2(gnome_middle.x - spot.x, gnome_middle.z - spot.z).length() < tree.canopy * size
		var in_the_way: bool = overhead or _blocks_view(camera.global_position, gnome_middle, spot, tree.canopy * size, tree.height * size)
		var fade: float = move_toward(tree.fade, TREE_FADE if in_the_way else 0.0, delta * 4.0)
		if fade != tree.fade:
			tree.fade = fade
			for mesh: GeometryInstance3D in tree.meshes:
				mesh.set_instance_shader_parameter("fade", fade)


# Is something at `spot`, this wide and tall, between the camera and the gnome?
static func _blocks_view(camera: Vector3, target: Vector3, spot: Vector3, radius: float, height: float) -> bool:
	var line := Vector2(target.x - camera.x, target.z - camera.z)
	var along := Vector2(spot.x - camera.x, spot.z - camera.z).dot(line) / line.length_squared()
	if along <= 0.0 or along >= 1.0:
		return false
	var closest := Vector2(camera.x, camera.z) + line * along
	var line_height := lerpf(camera.y, target.y, along)
	return closest.distance_to(Vector2(spot.x, spot.z)) < radius + 0.5 and line_height < height + spot.y


func flicker_lanterns(time: float) -> void:
	for i in lanterns.size():
		var t := time * 3.0 + i * 1.7
		lanterns[i].light_energy = 1.6 * (0.9 + 0.06 * sin(t * 2.3) + 0.04 * sin(t * 5.1 + 1.0))


# Keep a spot inside the hedge, at least `radius` from it.
static func keep_in(at: Vector3, radius: float) -> Vector3:
	var limit := PLAY_HALF - radius
	return Vector3(clampf(at.x, -limit, limit), at.y, clampf(at.z, -limit, limit))
