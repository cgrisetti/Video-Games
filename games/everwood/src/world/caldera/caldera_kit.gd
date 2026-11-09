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
## A landblock with this many trees of one species (or more) is a dense stand (the
## Ariundle Moss-Oaks' 1,308 sessile oaks, docs/27 §8): its trees are grouped into
## DENSE_CELL m cells, each sculpted only within DENSE_ATELIER_RANGE of a camera and
## a stand-in past it, so four cameras in the wood draw a few cells of sculpted oaks
## instead of every oak within ATELIER_RANGE. A sparser stand keeps the full range.
const DENSE_STAND: int = 32
const DENSE_ATELIER_RANGE: float = 96.0
const DENSE_CELL: float = 32.0

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


## A walkable slab from `a` to `b` (its top face through both), `width` across and `thickness` deep: a sloping bridge deck or a stair's flight.
static func solid_slab(parent: Node3D, node_name: String, a: Vector3, b: Vector3, width: float, thickness: float,
		layer: int = ActorBase.LAYER_LOW_SCENERY) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.collision_layer = layer
	body.collision_mask = 0
	var length: float = a.distance_to(b)
	var forward: Vector3 = (b - a) / maxf(length, 0.001)
	var basis: Basis = Basis.looking_at(forward, Vector3.UP)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(width, thickness, length)
	shape.shape = box
	shape.transform = Transform3D(basis, (a + b) * 0.5 - basis.y * thickness * 0.5)
	body.add_child(shape)
	parent.add_child(body)
	return body


## The slab's look: a box of `color` matching solid_slab's shape.
static func add_slab(into: LandblockTerrain.MeshMerge, a: Vector3, b: Vector3, width: float, thickness: float, color: Color) -> void:
	var length: float = a.distance_to(b)
	if length < 0.01:
		return
	var forward: Vector3 = (b - a) / length
	var basis: Basis = Basis.looking_at(forward, Vector3.UP)
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(width, thickness, length)
	into.add_arrays(box.get_mesh_arrays(), Transform3D(basis, (a + b) * 0.5 - basis.y * thickness * 0.5), color)


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


## A windmill silhouette (the far stand-in for Embershore's, on Mill-Downs).
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
			# The same bole and three lobes in fewer facets (docs/32 §9): thirteen hundred of them are in any view of the wood.
			add_post(into, Vector3.ZERO, 0.32, 0.55, 4.8, Color(0.4, 0.3, 0.22), 5)
			add_sphere(into, Vector3(0.0, 6.2, 0.0), 2.9, LEAF, 0.75, 6)
			add_sphere(into, Vector3(1.6, 5.5, 0.6), 1.9, LEAF.lerp(DARK_LEAF, 0.4), 0.8, 6)
			add_sphere(into, Vector3(-1.4, 5.6, -0.8), 2.0, LEAF.lightened(0.08), 0.8, 6)
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
		IslandBuilder.Species.GORSE_BUSH:
			# A dark, dense bush flecked with yellow flowers (Embershore's rim and crags, docs/27 §6).
			add_sphere(into, Vector3(0.0, 0.55, 0.0), 0.9, Color(0.22, 0.34, 0.16), 0.7, 7)
			add_sphere(into, Vector3(0.5, 0.45, 0.3), 0.6, Color(0.26, 0.38, 0.18), 0.7, 6)
			for fleck: Vector3 in [Vector3(0.3, 0.95, 0.4), Vector3(-0.5, 0.9, 0.1), Vector3(0.1, 1.05, -0.5), Vector3(0.7, 0.75, -0.2), Vector3(-0.3, 0.7, 0.7)]:
				add_sphere(into, fleck, 0.12, Color(0.98, 0.84, 0.2), 1.0, 4)
		IslandBuilder.Species.HEATHER_CLUMP:
			# Low purple heather in a loose mat.
			for tuft: int in 4:
				var angle: float = TAU * float(tuft) / 4.0 + 0.4
				add_sphere(into, Vector3(cos(angle) * 0.35, 0.22, sin(angle) * 0.35), 0.34, Color(0.46, 0.3, 0.5), 0.6, 5)
			add_sphere(into, Vector3(0.0, 0.26, 0.0), 0.36, Color(0.56, 0.36, 0.58), 0.6, 5)
		IslandBuilder.Species.ROWAN_TREE:
			# A slim rowan with hanging clusters of red berries (walking sticks and bows come from here).
			add_post(into, Vector3.ZERO, 0.12, 0.2, 3.6, Color(0.5, 0.46, 0.4), 6)
			add_sphere(into, Vector3(0.0, 4.4, 0.0), 1.6, Color(0.44, 0.6, 0.3), 0.8, 7)
			add_sphere(into, Vector3(0.9, 3.9, 0.4), 1.0, Color(0.4, 0.56, 0.28), 0.8, 6)
			for berry: Vector3 in [Vector3(0.8, 3.6, 0.9), Vector3(-0.9, 4.0, 0.5), Vector3(0.2, 3.5, -1.1), Vector3(-0.4, 4.6, -0.8)]:
				add_sphere(into, berry, 0.22, Color(0.86, 0.18, 0.12), 1.0, 5)
		_:
			# The worked land's trees, runs and field pieces (docs/32).
			WorkedLandKit.stand_in(species, into)
	_species[species] = into.commit()
	return _species[species]


# --- The scatter's atelier meshes (docs/13 K4) ----------------------------------------

## The meadow's wildflowers (docs/24 §4), by IslandBuilder.MEADOW_FLOWER_SHARES:
## ox-eye daisies, buttercups, field poppies, cornflowers and cow parsley.
enum Flower { DAISY, BUTTERCUP, POPPY, CORNFLOWER, COW_PARSLEY }
## The meadow's grass and flowers fade by this far from a camera (per pixel, in the
## shader), and each 32 m cell is only drawn within MEADOW_CELL_RANGE of one.
const MEADOW_FADE_M: float = 48.0
const MEADOW_CELL_RANGE: float = 66.0
const MEADOW_GRASS_TIP: Color = Color(0.5, 0.66, 0.29)
const STEM_GREEN: Color = Color(0.36, 0.52, 0.24)
## Blades in a meadow tuft, and how much bigger a wildflower's head is drawn than life (so it reads from the 4.8 m camera).
const MEADOW_BLADES: int = 14
const FLOWER_HEAD_SCALE: float = 1.7
## The bough clusters (docs/24 §5): lobes each, at most this many a tree, and the
## lobes the main crown gives up for them, so a tree stays within 3,200 triangles.
const BOUGH_CLUSTER_LOBES: int = 2
const BOUGH_CLUSTERS_MAX: int = 3
const BOUGH_CLUSTER_LOBE_SHARE: int = 4

static var _flowers: Dictionary[int, ArrayMesh] = {}
static var _meadow_grass: ArrayMesh


## The meadow's grass tuft: a full clump of MEADOW_BLADES broad, arching blades
## (UV.y 1 at the root to 0 at the tip, as the grass shader wants), short in
## the middle of the clump's spread and longer at its heart.
static func meadow_grass_mesh() -> ArrayMesh:
	if _meadow_grass != null:
		return _meadow_grass
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 23
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base: int = 0
	for blade: int in MEADOW_BLADES:
		var angle: float = TAU * float(blade) / float(MEADOW_BLADES) + rng.randf_range(-0.25, 0.25)
		var out: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var heart: float = rng.randf()
		var root: Vector3 = out * heart * 0.12
		var tall: float = lerpf(0.5, 0.24, heart) * rng.randf_range(0.8, 1.2)
		var arch: float = rng.randf_range(0.06, 0.22) * (0.5 + heart)
		var width: float = rng.randf_range(0.05, 0.085)
		var side: Vector3 = out.cross(Vector3.UP).normalized().rotated(Vector3.UP, rng.randf_range(-0.5, 0.5))
		for step: int in 5:
			var t: float = float(step) / 4.0
			var at: Vector3 = root + Vector3.UP * tall * t + out * arch * t * t
			var normal: Vector3 = (Vector3.UP * 0.6 + out * 0.4).normalized()
			for edge: float in [-1.0, 1.0]:
				tool.set_normal(normal)
				tool.set_color(Color.WHITE)
				tool.set_uv(Vector2(0.5 + edge * 0.5, 1.0 - t))
				tool.add_vertex(at + side * width * 0.5 * (1.0 - t * 0.92) * edge)
		for step: int in 4:
			var a: int = base + step * 2
			for corner: int in [a, a + 1, a + 3, a, a + 3, a + 2]:
				tool.add_index(corner)
		base += 10
	_meadow_grass = tool.commit()
	return _meadow_grass


## A wildflower: a crossed pair of stems and leaves, and its head, in vertex colours (sRGB), foot at the origin.
static func meadow_flower_mesh(kind: int) -> ArrayMesh:
	if _flowers.has(kind):
		return _flowers[kind]
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tall: float = [0.34, 0.3, 0.42, 0.38, 0.62][kind]
	# The stem: two crossed tapering ribbons, and a leaf low on it.
	for turn: float in [0.0, PI * 0.5]:
		var across: Vector3 = Vector3(cos(turn), 0.0, sin(turn)) * 0.012
		_flower_quad(tool, [Vector3.ZERO - across, Vector3.ZERO + across, Vector3(0.0, tall, 0.0) + across * 0.4, Vector3(0.0, tall, 0.0) - across * 0.4], STEM_GREEN)
		var leaf_dir: Vector3 = Vector3(cos(turn + 0.6), 0.0, sin(turn + 0.6))
		_flower_quad(tool, [Vector3(0.0, 0.04, 0.0), Vector3(0.0, 0.07, 0.0) + leaf_dir * 0.01, Vector3(0.0, 0.16, 0.0) + leaf_dir * 0.1, Vector3(0.0, 0.1, 0.0) + leaf_dir * 0.08],
			STEM_GREEN.lightened(0.1))
	var head: Vector3 = Vector3(0.0, tall, 0.0)
	var heads: SurfaceTool = SurfaceTool.new()
	heads.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stems: SurfaceTool = tool
	tool = heads
	head = Vector3.ZERO
	match kind:
		Flower.DAISY:
			_petal_ring(tool, head, 10, 0.055, 0.016, 0.15, Color(0.97, 0.96, 0.9))
			_petal_ring(tool, head + Vector3(0.0, 0.006, 0.0), 6, 0.016, 0.012, 0.0, Color(0.95, 0.76, 0.18))
		Flower.BUTTERCUP:
			_petal_ring(tool, head, 5, 0.032, 0.02, 0.7, Color(0.98, 0.8, 0.12))
			_petal_ring(tool, head + Vector3(0.0, 0.004, 0.0), 5, 0.01, 0.008, 0.0, Color(0.9, 0.62, 0.1))
		Flower.POPPY:
			_petal_ring(tool, head, 4, 0.05, 0.04, 0.5, Color(0.86, 0.16, 0.12))
			_petal_ring(tool, head + Vector3(0.0, 0.01, 0.0), 5, 0.012, 0.012, 0.0, Color(0.14, 0.1, 0.1))
		Flower.CORNFLOWER:
			_petal_ring(tool, head, 9, 0.038, 0.01, 0.55, Color(0.3, 0.45, 0.86))
			_petal_ring(tool, head + Vector3(0.0, 0.004, 0.0), 6, 0.012, 0.01, 0.2, Color(0.22, 0.24, 0.6))
		Flower.COW_PARSLEY:
			for spoke: int in 7:
				var a: float = TAU * float(spoke) / 7.0
				var tip: Vector3 = head + Vector3(cos(a) * 0.07, 0.05, sin(a) * 0.07)
				_flower_quad(tool, [head, head + Vector3(0.004, 0.0, 0.0), tip + Vector3(0.004, 0.0, 0.0), tip], STEM_GREEN)
				_petal_ring(tool, tip, 6, 0.018, 0.016, 0.0, Color(0.96, 0.95, 0.88))
	# The head, drawn larger than life, set on top of its stem.
	var head_mesh: ArrayMesh = heads.commit()
	stems.append_from(head_mesh, 0, Transform3D(Basis.from_scale(Vector3.ONE * FLOWER_HEAD_SCALE), Vector3(0.0, tall, 0.0)))
	tool = stems
	tool.generate_normals()
	var mesh: ArrayMesh = tool.commit()
	_flowers[kind] = mesh
	return mesh


static func _flower_quad(tool: SurfaceTool, corners: Array, color: Color) -> void:
	for index: int in [0, 1, 2, 0, 2, 3]:
		tool.set_color(color)
		tool.set_uv(Vector2(0.5, 1.0 - clampf((corners[index] as Vector3).y * 2.0, 0.0, 1.0)))
		tool.add_vertex(corners[index])


## A ring of `count` petals round `center`, each `length` long and `width` wide, cupped up by `cup` (0 flat).
static func _petal_ring(tool: SurfaceTool, center: Vector3, count: int, length: float, width: float, cup: float, color: Color) -> void:
	for petal: int in count:
		var a: float = TAU * float(petal) / float(count)
		var out: Vector3 = Vector3(cos(a), cup, sin(a)).normalized()
		var side: Vector3 = Vector3(-sin(a), 0.0, cos(a)) * width * 0.5
		var tip: Vector3 = center + out * length
		var shade: Color = color.darkened(0.08 * float(petal % 2))
		_flower_quad(tool, [center - side * 0.4, center + side * 0.4, tip + side, tip - side], shade)


## A lived-in clutter set round a home (docs/24 §5): what a family leaves about
## a cottage or an orchard shed: coopered barrels, slatted crates (of apples,
## at an orchard), a split-log woodpile, hessian sacks, flower tubs; each in
## the painted timber and weathered, placed by `seed` round `center` between
## `inner` and `outer` metres out, `pieces` of them.
static func lived_in_clutter(root: Node3D, node_name: String, center: Vector3, seed_value: int, pieces: int, inner: float, outer: float,
		ground_at: Callable, apples: bool = false) -> Node3D:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var holder: Node3D = Node3D.new()
	holder.name = node_name
	root.add_child(holder)
	var timber: Material = WorldVisualCatalog.craft(WorldVisualCatalog.Craft.HEWN_TIMBER, Color(0.6, 0.45, 0.31))
	var dark_timber: Material = WorldVisualCatalog.craft(WorldVisualCatalog.Craft.HEWN_TIMBER, Color(0.42, 0.3, 0.2))
	var iron: Material = StorybookMaterial.make(Color(0.28, 0.27, 0.27))
	var hessian: Material = StorybookMaterial.make(Color(0.72, 0.62, 0.46))
	var bark: Material = StorybookMaterial.make(Color(0.4, 0.3, 0.22))
	var log_end: Material = StorybookMaterial.make(Color(0.82, 0.68, 0.48))
	var apple_red: Material = StorybookMaterial.make(Color(0.78, 0.2, 0.15))
	var apple_gold: Material = StorybookMaterial.make(Color(0.88, 0.66, 0.22))
	var blooms: Array[Material] = [StorybookMaterial.make(Color(0.86, 0.3, 0.4)), StorybookMaterial.make(Color(0.95, 0.85, 0.4)),
		StorybookMaterial.make(Color(0.6, 0.5, 0.86)), StorybookMaterial.make(Color(0.96, 0.95, 0.9))]
	var leaf: Material = StorybookMaterial.make(Color(0.3, 0.5, 0.24))
	for piece: int in pieces:
		var angle: float = rng.randf() * TAU
		var reach: float = rng.randf_range(inner, outer)
		var flat: Vector2 = Vector2(center.x + cos(angle) * reach, center.z + sin(angle) * reach)
		var spot: Node3D = Node3D.new()
		spot.name = "Clutter%d" % piece
		spot.position = ground_at.call(flat.x, flat.y) - Vector3(0.0, 0.03, 0.0) - holder.global_position if holder.is_inside_tree() else ground_at.call(flat.x, flat.y) - Vector3(0.0, 0.03, 0.0)
		spot.rotation.y = rng.randf() * TAU
		holder.add_child(spot)
		var kind: int = rng.randi_range(0, 5) if not apples else [0, 1, 1, 1, 3, 2][rng.randi_range(0, 5)]
		match kind:
			0:
				# A coopered barrel, two iron hoops, a lid; sometimes a second beside it.
				for twin: int in rng.randi_range(1, 2):
					var at: Vector3 = Vector3(twin * 0.66, 0.0, 0.0)
					spot.add_child(ShapeKit.cylinder("Barrel", 0.28, 0.3, 0.86, at + Vector3(0.0, 0.43, 0.0), timber, 12))
					spot.add_child(ShapeKit.cylinder("BarrelBulge", 0.33, 0.33, 0.3, at + Vector3(0.0, 0.43, 0.0), timber, 12))
					for hoop: float in [0.16, 0.7]:
						spot.add_child(ShapeKit.cylinder("Hoop", 0.315, 0.315, 0.05, at + Vector3(0.0, hoop, 0.0), iron, 12))
			1:
				# A slatted crate (heaped with apples at an orchard), now and then two stacked.
				var stack: int = rng.randi_range(1, 2)
				for level: int in stack:
					var lift: float = 0.46 * level
					spot.add_child(ShapeKit.box("Crate", Vector3(0.62, 0.44, 0.48), Vector3(0.0, 0.22 + lift, 0.0), timber))
					for slat: float in [-0.12, 0.0, 0.12]:
						spot.add_child(ShapeKit.box("Slat", Vector3(0.64, 0.035, 0.5), Vector3(0.0, 0.22 + lift + slat, 0.0), dark_timber))
				if apples:
					for apple: int in 9:
						spot.add_child(ShapeKit.sphere("Apple", 0.065, Vector3(rng.randf_range(-0.22, 0.22), 0.46 * stack + 0.04, rng.randf_range(-0.16, 0.16)),
							apple_red if apple % 3 != 0 else apple_gold))
			2:
				# A split-log woodpile against the weather, bark out, pale cut ends.
				for row: int in 3:
					for log: int in 5 - row:
						var at: Vector3 = Vector3((float(log) - (4 - row) * 0.5) * 0.24, 0.12 + row * 0.21, 0.0)
						var piece_log: MeshInstance3D = ShapeKit.cylinder("Log", 0.11, 0.12, 0.9, at, bark, 7)
						piece_log.rotation.x = PI * 0.5
						spot.add_child(piece_log)
						var face: MeshInstance3D = ShapeKit.cylinder("LogEnd", 0.1, 0.1, 0.02, at + Vector3(0.0, 0.0, 0.455), log_end, 7)
						face.rotation.x = PI * 0.5
						spot.add_child(face)
			3:
				# Hessian sacks slumped together.
				for sack: int in rng.randi_range(2, 3):
					var bag: MeshInstance3D = ShapeKit.sphere("Sack", 0.26, Vector3(sack * 0.42, 0.24, rng.randf_range(-0.1, 0.1)), hessian)
					bag.scale = Vector3(0.95, 1.15, 0.8)
					bag.rotation.z = rng.randf_range(-0.25, 0.25)
					spot.add_child(bag)
			4:
				# A flower tub: a half-barrel spilling blooms.
				spot.add_child(ShapeKit.cylinder("Tub", 0.36, 0.3, 0.42, Vector3(0.0, 0.21, 0.0), dark_timber, 12))
				spot.add_child(ShapeKit.sphere("Leaves", 0.36, Vector3(0.0, 0.5, 0.0), leaf))
				for bloom: int in 9:
					var a: float = rng.randf() * TAU
					spot.add_child(ShapeKit.sphere("Bloom", 0.07, Vector3(cos(a) * 0.26, 0.55 + rng.randf() * 0.2, sin(a) * 0.26), blooms[(bloom + seed_value) % blooms.size()]))
			_:
				# A low bench of two stumps and a split plank.
				for leg: float in [-0.5, 0.5]:
					spot.add_child(ShapeKit.cylinder("Stump", 0.14, 0.16, 0.4, Vector3(leg, 0.2, 0.0), bark, 8))
				spot.add_child(ShapeKit.box("Plank", Vector3(1.4, 0.07, 0.3), Vector3(0.0, 0.43, 0.0), timber))
	return holder


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
			# The worked land's trees, runs and field pieces (docs/32); stones and reeds have none.
			made = WorkedLandKit.sculpt(species, parts)
	# A run keeps every triangle: it hands over to its stand-in at RUN_HANDOVER, and a hedge thinned by the
	# engine's levels of detail shows daylight through it.
	if made and WorkedLandKit.RUNS.has(species):
		_atelier[species] = parts.commit()
		return _atelier[species]
	_atelier[species] = _with_lods(parts.commit()) if made else null
	return _atelier[species]


## Where a stand of `count` trees of one species hands its sculpted meshes over to its stand-ins.
static func atelier_range(count: int) -> float:
	return DENSE_ATELIER_RANGE if count >= DENSE_STAND else ATELIER_RANGE


## The same mesh with the engine's own levels of detail on every surface (the same
## vertices, fewer triangles), picked per MultiMesh by how big it draws on screen:
## the cell of trees a camera stands in keeps every triangle, the cells further off
## shed most of theirs, and the materials, colours and sway stay the same.
static func _with_lods(mesh: ArrayMesh) -> ArrayMesh:
	var importer: ImporterMesh = ImporterMesh.new()
	for surface: int in mesh.get_surface_count():
		importer.add_surface(mesh.surface_get_primitive_type(surface), mesh.surface_get_arrays(surface), [], {}, mesh.surface_get_material(surface),
			mesh.surface_get_name(surface))
	importer.generate_lods(25.0, 60.0, [])
	return importer.get_mesh()


## Whether a scatter species shows an atelier mesh near a camera.
static func has_atelier(species: int) -> bool:
	return atelier_mesh(species) != null


## Whether a species is small scatter (no stand-in past SMALL_RANGE, no shadow).
static func is_small(species: int) -> bool:
	return species in [IslandBuilder.Species.ROCK, IslandBuilder.Species.REED_CLUMP, IslandBuilder.Species.FERN_TUFT, IslandBuilder.Species.GORSE_BUSH,
		IslandBuilder.Species.HEATHER_CLUMP] or WorkedLandKit.SMALL.has(species)


## Whether a species is a tree (a dense stand of them is grouped into cells; their stand-ins keep their shadows).
static func is_tree(species: int) -> bool:
	return WorkedLandKit.is_tree(species)


## Where a species' sculpted mesh hands over to its stand-in when its stand isn't dense: a tree's at ATELIER_RANGE,
## a hedge's or a wall's sooner.
static func handover(species: int) -> float:
	if WorkedLandKit.RUNS.has(species):
		return WorkedLandKit.RUN_HANDOVER
	return WorkedLandKit.TREE_HANDOVER if WorkedLandKit.NEW_TREES.has(species) else ATELIER_RANGE


## How far a species is drawn at all (0: at any distance): the small things of the worked land give out sooner.
static func species_reach(species: int) -> float:
	return WorkedLandKit.REACH.get(species, 0.0)


static func casts_shadow(species: int) -> bool:
	return not WorkedLandKit.NO_SHADOW.has(species)


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
	# The main crown gives up a few lobes to the bough clusters, keeping the tree in its triangle budget.
	parts.add_mesh(ShapeKit.make_leaf_cloud_crown(crown_at, tall * 0.3, lobes - BOUGH_CLUSTER_LOBE_SHARE, seed_value, leaves[0], leaves[1], fronds,
		frond_length), Transform3D.IDENTITY, [canopy])
	_bough_clusters(parts, trunk, crown_at, tall * 0.3, seed_value, leaves, canopy)
	return crown_at


## Leaf clusters at the ends of a trunk's boughs (docs/24 §5): the crown breaks
## into lobes and hollows, light between them, instead of one round ball on a pole.
static func _bough_clusters(parts: WorldAssetCatalog.Parts, trunk: ArrayMesh, crown_at: Vector3, radius: float, seed_value: int, leaves: Array,
		canopy: Material) -> void:
	var tips: Variant = trunk.get_meta(ShapeKit.META_BOUGH_TIPS, PackedVector3Array())
	var spots: PackedVector3Array = tips as PackedVector3Array if tips is PackedVector3Array else PackedVector3Array()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value * 31 + 7
	# Fewer than three boughs: clusters round the crown's shoulders instead.
	while spots.size() < 3:
		var a: float = rng.randf() * TAU
		spots.append(crown_at + Vector3(cos(a), rng.randf_range(-0.3, 0.2), sin(a)) * radius * 0.9)
	for index: int in mini(spots.size(), BOUGH_CLUSTERS_MAX):
		var tip: Vector3 = spots[index]
		var out: Vector3 = Vector3(tip.x - crown_at.x, 0.0, tip.z - crown_at.z)
		var lean: Vector3 = out.normalized() if out.length() > 0.05 else Vector3.RIGHT
		var center: Vector3 = crown_at + lean * radius * rng.randf_range(0.65, 0.95) + Vector3(0.0, rng.randf_range(-0.35, 0.25) * radius, 0.0)
		var size: float = radius * rng.randf_range(0.5, 0.68)
		# Never below the combat sightline: a cluster's lowest leaf stays above it.
		center.y = maxf(center.y, ZoneBiomeResource.MAX_OBSTACLE_SIGHTLINE_M + size * 1.1)
		parts.add_mesh(ShapeKit.make_leaf_cloud_crown(center, size, BOUGH_CLUSTER_LOBES, seed_value + 11 * (index + 1), leaves[0], leaves[1], 0, 1.6,
			BOUGH_CLUSTER_LOBES), Transform3D.IDENTITY, [canopy])


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
	parts.add_mesh(ShapeKit.make_leaf_cloud_crown(crown_at, radius * 0.85, 11, 5, leaves[0], leaves[1]), Transform3D.IDENTITY, [canopy])
	_bough_clusters(parts, trunk, crown_at, radius * 0.85, 5, leaves, canopy)
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
