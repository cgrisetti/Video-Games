## The Caldera Isles' props and landmarks, built in code from simple shapes
## merged into vertex-coloured meshes (one draw each) in the storybook look:
## piers and causeways, Lantern-Skiffs, huts, ruins, arches and raid seals,
## the far landmarks North Quay looks at (Forge Stacks, Bell-Tower, the
## World-Tree), and the scatter's trees, reeds and stones: near a camera the
## trees and ferns are sculpted atelier meshes (atelier_mesh), past it one-draw
## vertex-coloured stand-ins (species_mesh).
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

## Within this distance of a camera (to a landblock's middle) the scatter shows its atelier meshes, past it the stand-ins.
const ATELIER_RANGE: float = 200.0
## The swap's give either way (so standing at the line doesn't flicker).
const ATELIER_MARGIN: float = 14.0
## Small scatter (stones, reeds, ferns) is gone past this distance.
const SMALL_RANGE: float = 220.0

static var _vertex_material: ShaderMaterial
static var _species: Dictionary[int, ArrayMesh] = {}
static var _atelier: Dictionary[int, ArrayMesh] = {}
static var _fruit_arrays: Array = []
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

## One shared one-draw stand-in per scatter species (built once, in its own frame,
## foot at the origin, coloured by vertex for CalderaKit.vertex_material()).
static func species_mesh(species: int) -> ArrayMesh:
	if _species.has(species):
		return _species[species]
	var into: LandblockTerrain.MeshMerge = merge()
	match species:
		IslandBuilder.Species.ORCHARD_TREE:
			add_post(into, Vector3.ZERO, 0.14, 0.24, 3.2, TIMBER, 6)
			add_sphere(into, Vector3(0.0, 4.0, 0.0), 1.75, Color(0.42, 0.6, 0.3), 0.8, 8)
			for petal: Vector3 in [Vector3(1.0, 4.3, 0.4), Vector3(-0.8, 4.5, -0.6), Vector3(0.1, 4.8, 1.0), Vector3(-0.4, 3.8, 1.3)]:
				add_sphere(into, petal, 0.26, Color(0.95, 0.42, 0.32), 1.0, 5)
		IslandBuilder.Species.OAK_TREE:
			add_post(into, Vector3.ZERO, 0.32, 0.55, 4.8, Color(0.4, 0.3, 0.22), 7)
			add_sphere(into, Vector3(0.0, 6.2, 0.0), 2.9, LEAF, 0.75, 8)
			add_sphere(into, Vector3(1.6, 5.5, 0.6), 1.9, LEAF.lerp(DARK_LEAF, 0.4), 0.8, 7)
			add_sphere(into, Vector3(-1.4, 5.6, -0.8), 2.0, LEAF.lightened(0.08), 0.8, 7)
		IslandBuilder.Species.WILLOW_TREE:
			add_post(into, Vector3.ZERO, 0.3, 0.5, 4.4, Color(0.4, 0.32, 0.22), 6)
			add_sphere(into, Vector3(0.0, 5.6, 0.0), 2.9, Color(0.5, 0.62, 0.32), 0.7, 8)
			# The hanging fronds' curtain.
			into.add_cylinder(Vector3(0.0, 4.5, 0.0), 2.5, 3.0, 2.0, Color(0.44, 0.56, 0.28), 10)
		IslandBuilder.Species.PINE_TREE, IslandBuilder.Species.SNOW_PINE:
			var tip: Color = SNOW if species == IslandBuilder.Species.SNOW_PINE else DARK_LEAF.lightened(0.1)
			add_post(into, Vector3.ZERO, 0.16, 0.28, 2.4, DARK_TIMBER, 6)
			add_cone(into, Vector3(0.0, 1.6, 0.0), 2.2, 3.2, DARK_LEAF, 8)
			add_cone(into, Vector3(0.0, 3.4, 0.0), 1.7, 2.8, DARK_LEAF.lerp(tip, 0.3), 8)
			add_cone(into, Vector3(0.0, 5.0, 0.0), 1.1, 2.6, DARK_LEAF.lerp(tip, 0.7), 8)
		IslandBuilder.Species.ASH_TREE:
			add_post(into, Vector3.ZERO, 0.2, 0.34, 4.6, Color(0.52, 0.48, 0.42), 6)
			add_sphere(into, Vector3(0.0, 5.8, 0.0), 2.5, Color(0.5, 0.62, 0.36), 0.85, 8)
			add_sphere(into, Vector3(1.2, 5.2, -0.5), 1.5, Color(0.46, 0.58, 0.34), 0.85, 6)
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


# --- The scatter's atelier meshes (docs/13 K4) ----------------------------------------

## A scatter species' sculpted near mesh in its own materials (null for one that
## has none: reeds and stones), built once, foot at the origin: an oak clump (a
## gnarled moss-oak with hanging moss and ferns at its foot), a slender ash, a
## weeping willow, an orchard apple in fruit, a pine of drooping needle tiers
## (snow on its boughs for the snow pine) and a layered fern. Crowns sway in the
## wind and dither out of a camera's sightline; trunks fork above the 3.2 m
## combat sightline.
static func atelier_mesh(species: int) -> ArrayMesh:
	if _atelier.has(species):
		return _atelier[species]
	var parts: WorldAssetCatalog.Parts = WorldAssetCatalog.Parts.new()
	var made: bool = true
	match species:
		IslandBuilder.Species.OAK_TREE:
			_broadleaf(parts, 9.0, 0.6, 4, 15, WorldAssetCatalog.LEAF_COLORS[WorldVisualCatalog.KIT_TREE_MOSS_OAK], 7, 0.9, 3)
			for fern: int in 3:
				var angle: float = TAU * float(fern) / 3.0 + 0.5
				_layered_fern(parts, Vector3(cos(angle) * 1.5, 0.0, sin(angle) * 1.5), 0.75, 20 + fern)
		IslandBuilder.Species.ASH_TREE:
			_broadleaf(parts, 8.2, 0.42, 3, 12, [Color(0.3, 0.44, 0.22), Color(0.6, 0.7, 0.4)], 0, 0.0, 11)
		IslandBuilder.Species.WILLOW_TREE:
			_willow(parts)
		IslandBuilder.Species.ORCHARD_TREE:
			_orchard_apple(parts)
		IslandBuilder.Species.PINE_TREE, IslandBuilder.Species.SNOW_PINE:
			_tiered_pine(parts, species == IslandBuilder.Species.SNOW_PINE)
		IslandBuilder.Species.FERN_TUFT:
			_layered_fern(parts, Vector3.ZERO, 1.0, 1)
		_:
			made = false
	_atelier[species] = parts.commit() if made else null
	return _atelier[species]


## Whether a scatter species shows an atelier mesh near a camera.
static func has_atelier(species: int) -> bool:
	return atelier_mesh(species) != null


## Whether a species is small scatter (no stand-in past SMALL_RANGE, no shadow).
static func is_small(species: int) -> bool:
	return species in [IslandBuilder.Species.ROCK, IslandBuilder.Species.REED_CLUMP, IslandBuilder.Species.FERN_TUFT]


static func _bark() -> Material:
	return WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.HEWN_TIMBER, WorldAssetCatalog.BARK, true, 0.35)


## A broadleaf: a gnarled trunk `tall` x 0.7 high forking into `boughs` boughs, under
## a leaf-cloud crown of `lobes` lobes (`leaves`: its dark underside and sunlit top)
## with `fronds` hanging moss fronds. Returns the crown's middle.
static func _broadleaf(parts: WorldAssetCatalog.Parts, tall: float, girth: float, boughs: int, lobes: int, leaves: Array, fronds: int,
		frond_length: float, seed_value: int) -> Vector3:
	var trunk: ArrayMesh = ShapeKit.make_gnarled_trunk_mesh(tall * 0.7, girth, girth * 0.42, boughs, seed_value)
	parts.add_mesh(trunk, Transform3D.IDENTITY, [_bark()])
	var crown_at: Vector3 = (trunk.get_meta(ShapeKit.META_CROWN_CENTER) as Vector3) + Vector3(0.0, 0.5, 0.0)
	var canopy: Material = WorldVisualCatalog.canopy(Color.WHITE, tall, 0.16, true)
	parts.add_mesh(ShapeKit.make_leaf_cloud_crown(crown_at, tall * 0.34, lobes, seed_value, leaves[0], leaves[1], fronds, frond_length),
		Transform3D.IDENTITY, [canopy])
	return crown_at


## A weeping willow: a stout leaning trunk under a broad dome whose fronds trail down round its rim, never below 3.4 m.
static func _willow(parts: WorldAssetCatalog.Parts) -> void:
	var tall: float = 8.0
	var trunk: ArrayMesh = ShapeKit.make_gnarled_trunk_mesh(tall * 0.6, 0.56, 0.26, 4, 7)
	parts.add_mesh(trunk, Transform3D.IDENTITY, [_bark()])
	var crown_at: Vector3 = (trunk.get_meta(ShapeKit.META_CROWN_CENTER) as Vector3) + Vector3(0.0, 0.4, 0.0)
	var radius: float = tall * 0.36
	var frond: float = clampf(crown_at.y - radius * 0.25 - 3.4, 0.6, 2.2)
	var leaves: Array = WorldAssetCatalog.LEAF_COLORS[WorldVisualCatalog.KIT_TREE_WEEPING_WILLOW]
	parts.add_mesh(ShapeKit.make_leaf_cloud_crown(crown_at, radius, 14, 7, leaves[0], leaves[1], 26, frond), Transform3D.IDENTITY,
		[WorldVisualCatalog.canopy(Color.WHITE, tall, 0.3, true)])


## An orchard apple: a short forked trunk under a round crown dotted with red and amber apples.
static func _orchard_apple(parts: WorldAssetCatalog.Parts) -> void:
	var tall: float = 5.0
	var trunk: ArrayMesh = ShapeKit.make_gnarled_trunk_mesh(maxf(3.6, tall * 0.72), 0.24, 0.12, 3, 5)
	parts.add_mesh(trunk, Transform3D.IDENTITY, [_bark()])
	var radius: float = tall * 0.36
	var crown_at: Vector3 = (trunk.get_meta(ShapeKit.META_CROWN_CENTER) as Vector3) + Vector3(0.0, 0.3, 0.0)
	crown_at.y = maxf(crown_at.y, ZoneBiomeResource.MAX_OBSTACLE_SIGHTLINE_M + radius * 0.5)
	var leaves: Array = WorldAssetCatalog.LEAF_COLORS[WorldVisualCatalog.KIT_TREE_ORCHARD_APPLE]
	var canopy: Material = WorldVisualCatalog.canopy(Color.WHITE, tall, 0.18, true)
	parts.add_mesh(ShapeKit.make_leaf_cloud_crown(crown_at, radius, 11, 5, leaves[0], leaves[1]), Transform3D.IDENTITY, [canopy])
	if _fruit_arrays.is_empty():
		var ball: SphereMesh = SphereMesh.new()
		ball.radius = 1.0
		ball.height = 2.0
		ball.radial_segments = 6
		ball.rings = 3
		_fruit_arrays = ball.get_mesh_arrays()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 512
	var apples: Array[Color] = [Color(0.82, 0.18, 0.15), Color(0.9, 0.62, 0.2)]
	for index: int in 10:
		var direction: Vector3 = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.2, 0.9), rng.randf_range(-1.0, 1.0)).normalized()
		parts.add_arrays(_fruit_arrays, Transform3D(Basis.from_scale(Vector3.ONE * 0.11), crown_at + direction * radius * 0.95), canopy, apples[index % 2])


## A pine of five drooping needle tiers, wide and low to narrow and high (all above the
## sightline), each a cone of needles ringed by boughs that hang at their tips; snow
## lies along the boughs' ridges for the snow pine.
static func _tiered_pine(parts: WorldAssetCatalog.Parts, snowy: bool) -> void:
	var tall: float = 9.0
	parts.add_mesh(ShapeKit.make_gnarled_trunk_mesh(tall * 0.94, 0.34, 0.08, 0, 4), Transform3D.IDENTITY, [_bark()])
	var needles: Material = WorldVisualCatalog.canopy(Color.WHITE, tall, 0.12, true)
	var leaves: Array = WorldAssetCatalog.LEAF_COLORS[WorldVisualCatalog.KIT_TREE_HIGHLAND_PINE]
	var dark: Color = leaves[0]
	var light: Color = leaves[1]
	var tiers: int = 5
	for tier: int in tiers:
		var t: float = float(tier) / float(tiers - 1)
		var y: float = lerpf(3.9, tall * 0.84, t)
		var radius: float = lerpf(2.5, 0.85, t)
		var droop: float = radius * 0.5
		var top: Color = dark.lerp(light, 0.5 + t * 0.5)
		parts.foliage_cone(Vector3(0.0, y - droop * 0.9, 0.0), radius * 0.6, droop + radius * 0.85, dark.lerp(light, t * 0.4),
			top.lerp(SNOW, 0.55) if snowy else top, needles)
		var boughs: int = 9 - tier
		for bough: int in boughs:
			var angle: float = TAU * float(bough) / float(boughs) + float(tier) * 0.61
			_needle_bough(parts, Vector3(0.0, y, 0.0), angle, radius, droop, dark.lerp(light, t * 0.3), top, snowy, needles)
	parts.foliage_cone(Vector3(0.0, tall * 0.84, 0.0), 0.42, tall * 0.2, dark.lerp(light, 0.6), SNOW if snowy else light, needles)


## One drooping bough: a tapered strip folded along a raised ridge, from the trunk out
## `radius` metres and down `droop` at its tip.
static func _needle_bough(parts: WorldAssetCatalog.Parts, root: Vector3, angle: float, radius: float, droop: float, inner: Color,
		outer: Color, snowy: bool, material: Material) -> void:
	var out: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
	var side: Vector3 = Vector3(-sin(angle), 0.0, cos(angle))
	var points: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	var segments: int = 3
	for step: int in segments + 1:
		var f: float = float(step) / float(segments)
		var center: Vector3 = root + out * lerpf(0.15, radius, f) + Vector3.UP * (-droop * f * f)
		var half: float = radius * 0.32 * (1.0 - 0.8 * f)
		var normal: Vector3 = (Vector3.UP * 0.8 + out * (0.3 + 0.5 * f)).normalized()
		var shade: Color = inner.lerp(outer, f)
		for across: int in 3:
			var lift: float = 0.14 * (1.0 - f) if across == 1 else -0.04
			points.append(center + side * half * float(across - 1) + Vector3.UP * lift)
			normals.append(normal)
			uvs.append(Vector2(0.0, 1.0 - f))
			colors.append(shade.lerp(SNOW, 0.75) if snowy and across == 1 else shade)
	var order: PackedInt32Array = PackedInt32Array()
	for step: int in segments:
		var a: int = step * 3
		for strip: int in 2:
			var p: int = a + strip
			order.append_array(PackedInt32Array([p, p + 3, p + 1, p + 1, p + 3, p + 4]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = order
	parts.add_arrays(arrays, Transform3D.IDENTITY, material)


## A layered fern at `at`: an outer ring of seven long fronds arching out low, an
## inner ring of five shorter, paler ones standing up, each frond's leaflets
## notched along its folded rib. It leans away from heroes brushing through.
static func _layered_fern(parts: WorldAssetCatalog.Parts, at: Vector3, size: float, seed_value: int) -> void:
	var material: Material = WorldVisualCatalog.foliage(Color.WHITE, 1.2, 0.5, 1.0)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7300 + seed_value
	# count, length, rise (radians), droop, dark, light
	var layers: Array[Array] = [
		[7, 1.15, 0.75, 0.85, Color(0.16, 0.3, 0.14), Color(0.4, 0.58, 0.24)],
		[5, 0.8, 1.15, 0.55, Color(0.24, 0.4, 0.18), Color(0.56, 0.72, 0.32)],
	]
	for layer: int in layers.size():
		var spec: Array = layers[layer]
		var count: int = spec[0]
		for frond: int in count:
			var angle: float = TAU * float(frond) / float(count) + float(layer) * 0.45 + rng.randf_range(-0.2, 0.2)
			var length: float = float(spec[1]) * size * rng.randf_range(0.85, 1.15)
			_fern_frond(parts, at, angle, length, float(spec[2]) + rng.randf_range(-0.12, 0.12), float(spec[3]), spec[4], spec[5], material)


static func _fern_frond(parts: WorldAssetCatalog.Parts, root: Vector3, angle: float, length: float, rise: float, droop: float, dark: Color,
		light: Color, material: Material) -> void:
	var out: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
	var side: Vector3 = Vector3(-sin(angle), 0.0, cos(angle))
	var points: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	var segments: int = 6
	for step: int in segments + 1:
		var f: float = float(step) / float(segments)
		var center: Vector3 = root + out * (length * f * cos(rise)) + Vector3.UP * (length * f * sin(rise) - droop * length * f * f)
		# Widest a little below the middle, notched leaflet by leaflet.
		var half: float = length * 0.15 * sin(PI * minf(f * 1.1, 1.0)) * (1.2 if step % 2 == 1 else 0.8)
		var normal: Vector3 = (Vector3.UP * 0.75 + out * 0.35).normalized()
		var shade: Color = dark.lerp(light, f)
		for across: int in 3:
			var lift: float = 0.03 * length if across == 1 else 0.0
			points.append(center + side * half * float(across - 1) + Vector3.UP * lift)
			normals.append(normal)
			uvs.append(Vector2(0.0, 1.0 - f))
			colors.append(shade)
	var order: PackedInt32Array = PackedInt32Array()
	for step: int in segments:
		var a: int = step * 3
		for strip: int in 2:
			var p: int = a + strip
			order.append_array(PackedInt32Array([p, p + 3, p + 1, p + 1, p + 3, p + 4]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = order
	parts.add_arrays(arrays, Transform3D.IDENTITY, material)
