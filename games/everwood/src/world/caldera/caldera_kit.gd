## The Caldera Isles' props and landmarks, built in code from simple shapes
## merged into vertex-coloured meshes (one draw each) in the storybook look:
## piers and causeways, Lantern-Skiffs, huts, ruins, arches and raid seals,
## the far landmarks North Quay looks at (Forge Stacks, Bell-Tower, the
## World-Tree), and the scatter's trees, reeds and stones.
##
## Merging (the add_* functions) is pure; the make_*/solid_* functions build
## nodes on the main thread.
class_name CalderaKit
extends RefCounted

const STONE: Color = Color(0.64, 0.61, 0.56)
const PALE_STONE: Color = Color(0.78, 0.75, 0.68)
const DARK_STONE: Color = Color(0.38, 0.38, 0.4)
const BASALT: Color = Color(0.22, 0.22, 0.25)
const IRONSTONE: Color = Color(0.56, 0.31, 0.2)
const TIMBER: Color = Color(0.46, 0.32, 0.2)
const DARK_TIMBER: Color = Color(0.3, 0.21, 0.14)
const THATCH: Color = Color(0.72, 0.6, 0.36)
const ROOF_RED: Color = Color(0.6, 0.29, 0.22)
const BRASS: Color = Color(0.86, 0.68, 0.3)
const SAFFRON: Color = Color(1.0, 0.78, 0.3)
const SAP_VIOLET: Color = Color(0.56, 0.3, 0.86)
const SNOW: Color = Color(0.94, 0.96, 0.98)
const LEAF: Color = Color(0.36, 0.56, 0.28)
const DARK_LEAF: Color = Color(0.2, 0.38, 0.22)
const SAIL: Color = Color(0.92, 0.88, 0.78)
const RAID_RED: Color = Color(0.72, 0.16, 0.14)
## The Sign colours (06 §2): Amber/Ochre, Sea-Azure, Saffron-Gold, Twilight-Violet.
const IRON_AMBER: Color = Color(0.92, 0.6, 0.18)
const GALE_AZURE: Color = Color(0.36, 0.7, 0.95)
const HEARTH_SAFFRON: Color = Color(1.0, 0.8, 0.28)
const TIDE_VIOLET: Color = Color(0.62, 0.38, 0.92)

static var _vertex_material: ShaderMaterial
static var _species: Dictionary[int, ArrayMesh] = {}
static var _glows: Dictionary[String, StandardMaterial3D] = {}


static func vertex_material() -> ShaderMaterial:
	if _vertex_material == null:
		_vertex_material = StorybookMaterial.vertex_colored()
	return _vertex_material


static func glow(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var key: String = "%s:%.2f" % [color.to_html(), energy]
	if not _glows.has(key):
		_glows[key] = StorybookMaterial.glowing(color, energy)
	return _glows[key]


static func merge() -> LandblockTerrain.MeshMerge:
	return LandblockTerrain.MeshMerge.new()


# --- Merging shapes ----------------------------------------------------------------

static func add_box(into: LandblockTerrain.MeshMerge, center: Vector3, size: Vector3, color: Color, yaw: float = 0.0) -> void:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	into.add_arrays(box.get_mesh_arrays(), Transform3D(Basis(Vector3.UP, yaw), center), color)


static func add_post(into: LandblockTerrain.MeshMerge, foot: Vector3, top_radius: float, bottom_radius: float, height: float, color: Color,
		segments: int = 8) -> void:
	into.add_cylinder(foot + Vector3(0.0, height * 0.5, 0.0), top_radius, bottom_radius, height, color, segments)


static func add_cone(into: LandblockTerrain.MeshMerge, foot: Vector3, radius: float, height: float, color: Color, segments: int = 8) -> void:
	into.add_cylinder(foot + Vector3(0.0, height * 0.5, 0.0), 0.0, radius, height, color, segments)


static func add_sphere(into: LandblockTerrain.MeshMerge, center: Vector3, radius: float, color: Color, squash: float = 1.0, segments: int = 8) -> void:
	var ball: SphereMesh = SphereMesh.new()
	ball.radius = radius
	ball.height = radius * 2.0
	ball.radial_segments = segments
	ball.rings = maxi(3, segments >> 1)
	into.add_arrays(ball.get_mesh_arrays(), Transform3D(Basis.from_scale(Vector3(1.0, squash, 1.0)), center), color)


## A beam from `a` to `b` (square, `thick` wide).
static func add_beam(into: LandblockTerrain.MeshMerge, a: Vector3, b: Vector3, thick: float, color: Color) -> void:
	var length: float = a.distance_to(b)
	if length < 0.01:
		return
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(thick, thick, length)
	var forward: Vector3 = (b - a) / length
	var up: Vector3 = Vector3.UP if absf(forward.y) < 0.95 else Vector3.RIGHT
	into.add_arrays(box.get_mesh_arrays(), Transform3D(Basis.looking_at(forward, up), (a + b) * 0.5), color)


static func mesh_node(node_name: String, from: LandblockTerrain.MeshMerge, at: Vector3 = Vector3.ZERO, shadows: bool = true) -> MeshInstance3D:
	var made: MeshInstance3D = MeshInstance3D.new()
	made.name = node_name
	made.mesh = from.commit()
	made.material_override = vertex_material()
	made.position = at
	if not shadows:
		made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return made


static func solid_box(parent: Node3D, node_name: String, center: Vector3, size: Vector3, yaw: float = 0.0,
		layer: int = ActorBase.LAYER_WORLD) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.collision_layer = layer
	body.collision_mask = 0
	body.position = center
	body.rotation.y = yaw
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Shape"
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	return body


static func solid_cylinder(parent: Node3D, node_name: String, foot: Vector3, radius: float, height: float,
		layer: int = ActorBase.LAYER_WORLD) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.collision_layer = layer
	body.collision_mask = 0
	body.position = foot + Vector3(0.0, height * 0.5, 0.0)
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Shape"
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	shape.shape = cylinder
	body.add_child(shape)
	parent.add_child(body)
	return body


## A world sign (WorldLabelStyle sizes it as it enters the tree).
static func sign_label(parent: Node3D, node_name: String, text: String, at: Vector3, billboard: bool = true) -> Label3D:
	var label: Label3D = Label3D.new()
	label.name = node_name
	label.text = text
	label.position = at
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	label.modulate = Color(1.0, 0.97, 0.88)
	parent.add_child(label)
	return label


static func light(parent: Node3D, node_name: String, at: Vector3, color: Color, energy: float, reach: float) -> OmniLight3D:
	var made: OmniLight3D = OmniLight3D.new()
	made.name = node_name
	made.position = at
	made.light_color = color
	made.light_energy = energy
	made.omni_range = reach
	made.shadow_enabled = false
	parent.add_child(made)
	return made


static func glow_sphere(parent: Node3D, node_name: String, at: Vector3, radius: float, color: Color, energy: float = 2.4) -> MeshInstance3D:
	var made: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.sphere(node_name, radius, at, glow(color, energy)))
	parent.add_child(made)
	return made


## A drifting plume (steam, forge smoke, sea-spray), cheap enough for every peer.
static func plume(parent: Node3D, node_name: String, at: Vector3, color: Color, rise: float, spread: float, amount: int = 18) -> CPUParticles3D:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.name = node_name
	particles.position = at
	particles.amount = amount
	particles.lifetime = 3.2
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = spread
	particles.direction = Vector3.UP
	particles.spread = 14.0
	particles.gravity = Vector3(0.6, rise, 0.2)
	particles.initial_velocity_min = rise * 0.4
	particles.initial_velocity_max = rise * 0.8
	particles.scale_amount_min = 1.4
	particles.scale_amount_max = 3.2
	var puff: SphereMesh = SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	puff.radial_segments = 6
	puff.rings = 3
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.vertex_color_use_as_albedo = true
	puff.material = material
	particles.mesh = puff
	var fade: Gradient = Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 0.0))
	fade.add_point(0.2, Color(1.0, 1.0, 1.0, 0.8))
	fade.set_color(fade.get_point_count() - 1, Color(1.0, 1.0, 1.0, 0.0))
	particles.color_ramp = fade
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(particles)
	return particles


# --- Structures (merged, in the island's frame) ------------------------------------------

## A timber pier from `root` (on the shore) to `head`, deck at `deck_y`, on posts down to the sea floor.
static func add_pier(into: LandblockTerrain.MeshMerge, root: Vector3, head: Vector3, width: float, deck_y: float) -> void:
	var flat: Vector3 = Vector3(head.x - root.x, 0.0, head.z - root.z)
	var yaw: float = atan2(flat.x, flat.z)
	var middle: Vector3 = Vector3((root.x + head.x) * 0.5, deck_y - 0.2, (root.z + head.z) * 0.5)
	add_box(into, middle, Vector3(width, 0.4, flat.length()), TIMBER, yaw)
	var along: Vector3 = flat.normalized()
	var across: Vector3 = Vector3(along.z, 0.0, -along.x)
	var count: int = maxi(2, int(flat.length() / 6.0))
	for index: int in count + 1:
		var at: Vector3 = Vector3(root.x, deck_y, root.z) + along * flat.length() * float(index) / float(count)
		for side: float in [-1.0, 1.0]:
			var post: Vector3 = at + across * side * (width * 0.5 - 0.2)
			add_post(into, post - Vector3(0.0, 12.0, 0.0), 0.22, 0.26, 13.2, DARK_TIMBER, 6)
	# Rails along both sides.
	for side: float in [-1.0, 1.0]:
		var a: Vector3 = Vector3(root.x, deck_y + 0.9, root.z) + across * side * (width * 0.5 - 0.2)
		add_beam(into, a, a + flat, 0.14, TIMBER)


## A dressed-stone causeway (or a low shingle spit) along `out` for `length` from `start`, deck at `deck_y`.
static func add_causeway(into: LandblockTerrain.MeshMerge, start: Vector3, out: Vector3, length: float, width: float, deck_y: float, shingle: bool) -> void:
	var yaw: float = atan2(out.x, out.z)
	var across: Vector3 = Vector3(out.z, 0.0, -out.x)
	var pieces: int = int(length / 8.0)
	for index: int in pieces:
		var center: Vector3 = Vector3(start.x, 0.0, start.z) + out * (8.0 * index + 4.0)
		var tone: Color = (SHINGLE_COLOR if shingle else STONE).lerp(DARK_STONE, 0.12 * float(index % 3))
		# The bank under the deck down to the sea floor, then the deck.
		add_box(into, Vector3(center.x, deck_y - 7.0, center.z), Vector3(width + 3.0, 13.6, 8.1), tone.darkened(0.25), yaw)
		add_box(into, Vector3(center.x, deck_y - 0.2, center.z), Vector3(width, 0.4, 8.05), tone, yaw)
		if not shingle:
			for side: float in [-1.0, 1.0]:
				add_box(into, Vector3(center.x, deck_y + 0.3, center.z) + across * side * (width * 0.5 - 0.3), Vector3(0.6, 0.6, 7.6), PALE_STONE, yaw)
		elif index % 2 == 0:
			for side: float in [-1.0, 1.0]:
				add_sphere(into, Vector3(center.x, deck_y + 0.05, center.z) + across * side * (width * 0.5 - 0.5), 0.6, SHINGLE_COLOR.darkened(0.1), 0.5, 6)


const SHINGLE_COLOR: Color = Color(0.66, 0.63, 0.58)


## A small Lantern-Skiff in its own frame, bow toward -Z: hull, thwarts, mast, a lantern.
static func add_skiff(into: LandblockTerrain.MeshMerge) -> void:
	add_box(into, Vector3(0.0, 0.25, 0.0), Vector3(3.2, 0.7, 9.0), TIMBER)
	add_box(into, Vector3(0.0, 0.25, -4.9), Vector3(2.2, 0.6, 1.2), TIMBER)
	add_box(into, Vector3(0.0, 0.62, 0.0), Vector3(2.8, 0.08, 8.4), Color(0.62, 0.48, 0.3))
	for z: float in [-2.6, 0.0, 2.6]:
		add_box(into, Vector3(0.0, 0.9, z), Vector3(2.8, 0.12, 0.4), DARK_TIMBER)
	add_post(into, Vector3(0.0, 0.6, -1.2), 0.08, 0.12, 5.4, DARK_TIMBER, 6)
	add_box(into, Vector3(0.0, 3.6, -1.0), Vector3(0.1, 3.4, 2.4), SAIL)
	add_post(into, Vector3(0.0, 0.6, -4.6), 0.05, 0.06, 2.2, DARK_TIMBER, 4)
	add_box(into, Vector3(0.0, 2.9, -4.6), Vector3(0.4, 0.5, 0.4), SAFFRON)


## A stone hut with a pitched roof, `size` its footprint and wall height.
static func add_hut(into: LandblockTerrain.MeshMerge, foot: Vector3, size: Vector3, yaw: float, wall: Color, roof: Color) -> void:
	add_box(into, foot + Vector3(0.0, size.y * 0.5, 0.0), size, wall, yaw)
	var ridge: float = size.x * 0.45
	for side: float in [-1.0, 1.0]:
		var offset: Vector3 = Vector3(side * size.x * 0.25, 0.0, 0.0).rotated(Vector3.UP, yaw)
		var slab: BoxMesh = BoxMesh.new()
		slab.size = Vector3(size.x * 0.62, 0.2, size.z + 0.6)
		var tilt: Basis = Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, side * -0.6)
		into.add_arrays(slab.get_mesh_arrays(), Transform3D(tilt, foot + offset + Vector3(0.0, size.y + ridge * 0.42, 0.0)), roof)


## A broken wall of old dressed stone (ruin dressing, never above the 3.2 m sightline).
static func add_ruin_wall(into: LandblockTerrain.MeshMerge, foot: Vector3, length: float, height: float, yaw: float, color: Color, seed_value: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var along: Vector3 = Vector3(sin(yaw), 0.0, cos(yaw))
	var blocks: int = maxi(2, int(length / 1.6))
	for index: int in blocks:
		var tall: float = height * rng.randf_range(0.35, 1.0)
		var at: Vector3 = foot + along * ((float(index) + 0.5) / float(blocks) - 0.5) * length
		add_box(into, at + Vector3(0.0, tall * 0.5, 0.0), Vector3(0.9, tall, length / float(blocks) * 0.96), color.lerp(DARK_STONE, rng.randf() * 0.3), yaw)


## A round-headed arch facing `yaw`, `width` between its piers, `height` to the crown.
static func add_arch(into: LandblockTerrain.MeshMerge, foot: Vector3, width: float, height: float, yaw: float, color: Color) -> void:
	var across: Vector3 = Vector3(cos(yaw), 0.0, -sin(yaw))
	var pier_height: float = height - width * 0.5
	for side: float in [-1.0, 1.0]:
		add_box(into, foot + across * side * (width * 0.5 + 0.6) + Vector3(0.0, pier_height * 0.5, 0.0), Vector3(1.2, pier_height, 1.6), color, yaw)
	var stones: int = 9
	for index: int in stones:
		var angle: float = PI * (float(index) + 0.5) / float(stones)
		var at: Vector3 = foot + across * cos(angle) * (width * 0.5 + 0.6) + Vector3(0.0, pier_height + sin(angle) * (width * 0.5 + 0.6), 0.0)
		add_box(into, at, Vector3(1.1, 1.1, 1.6), color.lightened(0.05 * float(index % 2)), yaw)


## A sealed raid gate's red Sign-seal (a ringed disc and its triangle mark), facing `yaw`.
static func add_raid_seal(into: LandblockTerrain.MeshMerge, center: Vector3, radius: float, yaw: float) -> void:
	var forward: Vector3 = Vector3(sin(yaw), 0.0, cos(yaw))
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.25
	disc.radial_segments = 20
	var face: Basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, PI * 0.5)
	into.add_arrays(disc.get_mesh_arrays(), Transform3D(face, center), PALE_STONE)
	disc.top_radius = radius * 0.8
	disc.bottom_radius = radius * 0.8
	into.add_arrays(disc.get_mesh_arrays(), Transform3D(face, center + forward * 0.08), RAID_RED)
	disc.top_radius = radius * 0.6
	disc.bottom_radius = radius * 0.6
	into.add_arrays(disc.get_mesh_arrays(), Transform3D(face, center + forward * 0.14), PALE_STONE)
	var mark: CylinderMesh = CylinderMesh.new()
	mark.top_radius = 0.0
	mark.bottom_radius = radius * 0.45
	mark.height = radius * 0.7
	mark.radial_segments = 3
	into.add_arrays(mark.get_mesh_arrays(), Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.FORWARD, 0.0), center + forward * 0.2), RAID_RED)


## The Forge Stacks of Iron-Ness: three tall brick chimneys over a long forge-hall.
static func add_forge_stacks(into: LandblockTerrain.MeshMerge, foot: Vector3) -> void:
	add_box(into, foot + Vector3(0.0, 6.0, 0.0), Vector3(34.0, 12.0, 16.0), IRONSTONE.darkened(0.2))
	add_box(into, foot + Vector3(0.0, 13.0, 0.0), Vector3(36.0, 2.0, 18.0), DARK_STONE)
	for index: int in 3:
		var at: Vector3 = foot + Vector3(-12.0 + 12.0 * index, 0.0, -2.0)
		var tall: float = 58.0 + 8.0 * float(index % 2)
		add_post(into, at, 2.2, 3.4, tall, IRONSTONE.lerp(DARK_STONE, 0.3), 10)
		add_post(into, at + Vector3(0.0, tall, 0.0), 2.8, 2.6, 2.0, DARK_STONE, 10)


## Barrow-Eyot's Bell-Tower: a slim stone tower with an open belfry and a spire.
static func add_bell_tower(into: LandblockTerrain.MeshMerge, foot: Vector3) -> void:
	add_box(into, foot + Vector3(0.0, 16.0, 0.0), Vector3(9.0, 32.0, 9.0), PALE_STONE.darkened(0.08))
	for corner: Vector2 in [Vector2(-3.6, -3.6), Vector2(3.6, -3.6), Vector2(-3.6, 3.6), Vector2(3.6, 3.6)]:
		add_box(into, foot + Vector3(corner.x, 36.0, corner.y), Vector3(1.6, 8.0, 1.6), PALE_STONE)
	add_box(into, foot + Vector3(0.0, 40.5, 0.0), Vector3(10.0, 1.2, 10.0), DARK_STONE)
	add_cone(into, foot + Vector3(0.0, 41.0, 0.0), 6.8, 14.0, ROOF_RED.darkened(0.2), 4)
	add_sphere(into, foot + Vector3(0.0, 35.0, 0.0), 2.2, BRASS, 1.1, 10)


## The World-Tree's far silhouette (trunk and a broad crown), for the Crown's impostor.
static func add_world_tree_silhouette(into: LandblockTerrain.MeshMerge, foot: Vector3) -> void:
	add_post(into, foot, 3.2, 6.5, 40.0, Color(0.42, 0.34, 0.26), 10)
	for lobe: Vector4 in [Vector4(-16.0, 34.0, 0.0, 16.0), Vector4(0.0, 38.0, -16.0, 16.0), Vector4(16.0, 34.0, 0.0, 16.0),
			Vector4(0.0, 46.0, 4.0, 15.0), Vector4(0.0, 34.0, 12.0, 12.0)]:
		add_sphere(into, foot + Vector3(lobe.x, lobe.y, lobe.z), lobe.w, LEAF.lerp(DARK_LEAF, 0.3), 0.72, 10)


## A windmill silhouette (the far stand-in for Oakshire Holm's).
static func add_windmill_silhouette(into: LandblockTerrain.MeshMerge, foot: Vector3) -> void:
	add_post(into, foot, 3.2, 5.0, 18.0, PALE_STONE, 10)
	add_cone(into, foot + Vector3(0.0, 18.0, 0.0), 4.2, 5.0, ROOF_RED, 10)
	for blade: int in 4:
		var angle: float = TAU * float(blade) / 4.0 + 0.3
		add_beam(into, foot + Vector3(0.0, 17.0, -4.6), foot + Vector3(cos(angle) * 11.0, 17.0 + sin(angle) * 11.0, -4.6), 1.2, SAIL)


# --- The scatter's meshes ------------------------------------------------------------

## One shared mesh per scatter species (built once, in its own frame, foot at the origin).
static func species_mesh(species: int) -> ArrayMesh:
	if _species.has(species):
		return _species[species]
	var into: LandblockTerrain.MeshMerge = merge()
	match species:
		IslandBuilder.Species.ORCHARD_TREE:
			add_post(into, Vector3.ZERO, 0.16, 0.24, 1.9, TIMBER, 6)
			add_sphere(into, Vector3(0.0, 2.6, 0.0), 1.55, Color(0.42, 0.6, 0.3), 0.8, 8)
			for petal: Vector3 in [Vector3(0.9, 2.9, 0.4), Vector3(-0.7, 3.1, -0.6), Vector3(0.1, 3.4, 0.9), Vector3(-0.4, 2.5, 1.1)]:
				add_sphere(into, petal, 0.26, Color(0.95, 0.42, 0.32), 1.0, 5)
		IslandBuilder.Species.OAK_TREE:
			add_post(into, Vector3.ZERO, 0.32, 0.55, 4.2, Color(0.4, 0.3, 0.22), 7)
			add_sphere(into, Vector3(0.0, 5.6, 0.0), 2.9, LEAF, 0.75, 8)
			add_sphere(into, Vector3(1.6, 4.9, 0.6), 1.9, LEAF.lerp(DARK_LEAF, 0.4), 0.8, 7)
			add_sphere(into, Vector3(-1.4, 5.0, -0.8), 2.0, LEAF.lightened(0.08), 0.8, 7)
		IslandBuilder.Species.PINE_TREE, IslandBuilder.Species.SNOW_PINE:
			var tip: Color = SNOW if species == IslandBuilder.Species.SNOW_PINE else DARK_LEAF.lightened(0.1)
			add_post(into, Vector3.ZERO, 0.16, 0.28, 2.4, DARK_TIMBER, 6)
			add_cone(into, Vector3(0.0, 1.6, 0.0), 2.2, 3.2, DARK_LEAF, 8)
			add_cone(into, Vector3(0.0, 3.4, 0.0), 1.7, 2.8, DARK_LEAF.lerp(tip, 0.3), 8)
			add_cone(into, Vector3(0.0, 5.0, 0.0), 1.1, 2.6, DARK_LEAF.lerp(tip, 0.7), 8)
		IslandBuilder.Species.ASH_TREE:
			add_post(into, Vector3.ZERO, 0.2, 0.32, 3.4, Color(0.52, 0.48, 0.42), 6)
			add_sphere(into, Vector3(0.0, 4.4, 0.0), 2.1, Color(0.5, 0.62, 0.36), 0.9, 8)
		IslandBuilder.Species.REED_CLUMP:
			for blade: int in 6:
				var angle: float = TAU * float(blade) / 6.0
				var tilt: Basis = Basis(Vector3.UP, angle) * Basis(Vector3.RIGHT, 0.18)
				var reed: BoxMesh = BoxMesh.new()
				reed.size = Vector3(0.06, 1.6, 0.06)
				into.add_arrays(reed.get_mesh_arrays(), Transform3D(tilt, Vector3(cos(angle) * 0.25, 0.8, sin(angle) * 0.25)), Color(0.56, 0.58, 0.32))
				add_box(into, Vector3(cos(angle) * 0.3, 1.7, sin(angle) * 0.3), Vector3(0.12, 0.3, 0.12), Color(0.42, 0.3, 0.2))
		IslandBuilder.Species.ROCK:
			add_sphere(into, Vector3(0.0, 0.2, 0.0), 0.7, STONE.darkened(0.1), 0.55, 6)
		IslandBuilder.Species.BOULDER:
			add_sphere(into, Vector3(0.0, 0.6, 0.0), 1.5, STONE.darkened(0.15), 0.7, 7)
			add_sphere(into, Vector3(0.8, 0.4, 0.5), 0.9, STONE, 0.6, 6)
		IslandBuilder.Species.BASALT_SPIRE:
			for column: int in 5:
				var angle: float = TAU * float(column) / 5.0
				add_post(into, Vector3(cos(angle) * 0.9, -0.5, sin(angle) * 0.9), 0.55, 0.62, 3.0 + float(column % 3) * 1.6, BASALT.lightened(0.04 * column), 6)
		IslandBuilder.Species.FERN_TUFT:
			for frond: int in 5:
				var angle: float = TAU * float(frond) / 5.0
				var leaf: BoxMesh = BoxMesh.new()
				leaf.size = Vector3(0.3, 0.05, 1.0)
				into.add_arrays(leaf.get_mesh_arrays(), Transform3D(Basis(Vector3.UP, angle) * Basis(Vector3.RIGHT, -0.5), Vector3(sin(angle) * 0.4, 0.35, cos(angle) * 0.4)), Color(0.32, 0.5, 0.26))
	_species[species] = into.commit()
	return _species[species]
