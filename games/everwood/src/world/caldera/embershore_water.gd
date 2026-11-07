## Embershore's water (docs/27 §4-§5): the River Bramble and the River Dover
## as ribbons of water laid in the beds the generator carved (the surface 0.6 m
## over the bed, flowing downstream along the ribbon), the two springs they rise
## from, the Bramble's weir and the mill race it feeds, and the Deep-Hush, the
## haze that seals the island's south-east edge. Built once per visit by
## EmbershoreBuilder.build_structures.
class_name EmbershoreWater
extends RefCounted

## The ribbon reaches this far past the river's half width, so its edge hides under the bank.
const BANK_MARGIN: float = 0.8
## Water lower than this is the sea's: the ribbon stops there.
const MOUTH_SURFACE: float = 0.15
## Downstream flow, metres a second.
const FLOW: float = 0.7
## The mill race: a stone-lined leat this wide, its water this much over the ground it crosses.
const RACE_WIDTH: float = 1.6
const RACE_LIFT: float = 0.12
## The Deep-Hush's haze curtain: from under the sea to this high, this far either side of its line.
const SEAL_TOP: float = 42.0
const SEAL_COLOR: Color = Color(0.74, 0.8, 0.82, 0.38)


static func build(root: Node3D, builder: EmbershoreBuilder) -> void:
	_build_rivers(root, builder)
	_build_springs(root, builder)
	_build_weir_and_race(root, builder)
	_build_seal(root, builder)


# --- Rivers --------------------------------------------------------------------------------

static func _build_rivers(root: Node3D, builder: EmbershoreBuilder) -> void:
	for river_name: String in ["bramble", "dover"]:
		var points: Array[PackedFloat32Array] = builder.river_points(river_name)
		if points.size() < 2:
			continue
		var ribbon: MeshInstance3D = MeshInstance3D.new()
		ribbon.name = "River_%s" % river_name
		ribbon.mesh = river_ribbon(points, BANK_MARGIN)
		ribbon.material_override = WorldVisualCatalog.water(&"river", Vector2(0.0, FLOW))
		ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(ribbon)
		# The water's voice, every so often along the run.
		var since: float = 60.0
		for index: int in range(1, points.size() - 1):
			since += Vector2(points[index][0], points[index][1]).distance_to(Vector2(points[index - 1][0], points[index - 1][1]))
			if since >= 90.0 and points[index][3] > MOUTH_SURFACE:
				since = 0.0
				AudioDirector.attach_ambience(ribbon, &"water_trickle", Vector3(points[index][0], points[index][3] + 0.3, points[index][1]), -6.0)


## A ribbon of water along a river's points (x, z, bed, surface, width): a strip two
## vertices wide, UV.x across in metres (0 on the centreline) and UV.y along in
## metres from the source, so the water shader's ripples run downstream. It
## breaks where the river meets the sea.
static func river_ribbon(points: Array[PackedFloat32Array], margin: float) -> ArrayMesh:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	var along: float = 0.0
	var count: int = points.size()
	for index: int in count:
		var here: PackedFloat32Array = points[index]
		var at: Vector2 = Vector2(here[0], here[1])
		var before: Vector2 = Vector2(points[maxi(index - 1, 0)][0], points[maxi(index - 1, 0)][1])
		var after: Vector2 = Vector2(points[mini(index + 1, count - 1)][0], points[mini(index + 1, count - 1)][1])
		var direction: Vector2 = (after - before).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2(1.0, 0.0)
		var across: Vector2 = Vector2(-direction.y, direction.x)
		var half: float = here[4] * 0.5 + margin
		if index > 0:
			along += at.distance_to(before)
		var surface: float = here[3]
		for side: float in [-1.0, 1.0]:
			var edge: Vector2 = at + across * half * side
			vertices.append(Vector3(edge.x, surface, edge.y))
			normals.append(Vector3.UP)
			uvs.append(Vector2(half * side, along))
			colors.append(Color(1.0, 1.0, 1.0, 1.0))
		if index > 0 and here[3] > MOUTH_SURFACE and points[index - 1][3] > MOUTH_SURFACE:
			var a: int = (index - 1) * 2
			indices.append_array(PackedInt32Array([a, a + 2, a + 1, a + 1, a + 2, a + 3]))
	var mesh: ArrayMesh = ArrayMesh.new()
	if indices.is_empty():
		return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Whether a river's surface never rises on its way to the sea (docs/27 §5, an acceptance check).
static func is_monotonic(points: Array[PackedFloat32Array]) -> bool:
	for index: int in range(1, points.size()):
		if points[index][3] > points[index - 1][3] + 0.001:
			return false
	return true


# --- Springs -------------------------------------------------------------------------------

static func _build_springs(root: Node3D, builder: EmbershoreBuilder) -> void:
	_spring(root, "BrambleSpring", "The Bramble Spring", builder.landmark(&"bramble_spring"), builder)
	_spring(root, "DoverSpring", "The Dover Spring", builder.landmark(&"dover_spring"), builder)


## A spring: a stone-rimmed pool where a river rises, trickling.
static func _spring(root: Node3D, node_name: String, label: String, at: Vector3, builder: EmbershoreBuilder) -> void:
	if at == Vector3.ZERO:
		return
	var holder: Node3D = Node3D.new()
	holder.name = node_name
	holder.position = Vector3(at.x, 0.0, at.z)
	root.add_child(holder)
	var rim: LandblockTerrain.MeshMerge = CalderaKit.merge()
	for index: int in 11:
		var angle: float = TAU * float(index) / 11.0 + 0.3
		var foot: Vector3 = builder.ground(at.x + cos(angle) * 2.6, at.z + sin(angle) * 2.6)
		CalderaKit.add_sphere(rim, Vector3(cos(angle) * 2.6, foot.y - at.y + 0.15, sin(angle) * 2.6), 0.55, CalderaKit.STONE.darkened(0.08 * float(index % 3)), 0.65, 6)
	holder.add_child(CalderaKit.mesh_node("Rim", rim))
	var pool: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.cylinder("Pool", 2.4, 2.4, 0.08, Vector3(0.0, at.y + 0.18, 0.0),
		WorldVisualCatalog.water(&"pool", Vector2(0.0, 0.1)), 14))
	holder.add_child(pool)
	AudioDirector.attach_ambience(holder, &"water_trickle", Vector3(0.0, at.y + 0.6, 0.0), -4.0)
	CalderaKit.sign_label(holder, "Sign", "%s\nwhere the river rises" % label, Vector3(0.0, at.y + 2.2, 0.0))


# --- The weir and the mill race -------------------------------------------------------------

## The Bramble's weir: a stone sill across the river below the Elder Oak (the Root-Sanctum's
## way out), and the mill race it feeds: a stone-lined leat drawn along the generator's line
## to the watermill's wheel (the ground it crosses is as laid, so the water lies on it).
static func _build_weir_and_race(root: Node3D, builder: EmbershoreBuilder) -> void:
	var weir: Vector3 = builder.landmark(&"bramble_weir")
	if weir == Vector3.ZERO:
		return
	var river: Array[PackedFloat32Array] = builder.river_points("bramble")
	var nearest: PackedFloat32Array = river[0]
	var nearest_index: int = 0
	for index: int in river.size():
		if Vector2(river[index][0], river[index][1]).distance_to(Vector2(weir.x, weir.z)) < Vector2(nearest[0], nearest[1]).distance_to(Vector2(weir.x, weir.z)):
			nearest = river[index]
			nearest_index = index
	var before: PackedFloat32Array = river[maxi(nearest_index - 1, 0)]
	var after: PackedFloat32Array = river[mini(nearest_index + 1, river.size() - 1)]
	var flow: Vector2 = Vector2(after[0] - before[0], after[1] - before[1]).normalized()
	var yaw: float = atan2(flow.x, flow.y)
	var width: float = nearest[4] + 1.6
	var surface: float = nearest[3]
	var stone: LandblockTerrain.MeshMerge = CalderaKit.merge()
	var sill_at: Vector3 = Vector3(nearest[0], surface - 0.25, nearest[1])
	CalderaKit.add_box(stone, sill_at, Vector3(width, 0.9, 1.4), CalderaKit.DARK_STONE, yaw)
	# The two abutments on the banks.
	var across: Vector2 = Vector2(-flow.y, flow.x)
	for side: float in [-1.0, 1.0]:
		var bank: Vector2 = Vector2(nearest[0], nearest[1]) + across * (width * 0.5 + 0.5) * side
		var foot: Vector3 = builder.ground(bank.x, bank.y)
		CalderaKit.add_box(stone, Vector3(bank.x, foot.y + 0.5, bank.y), Vector3(1.2, 1.2, 1.8), CalderaKit.STONE, yaw)
	var weir_node: MeshInstance3D = CalderaKit.mesh_node("BrambleWeir", stone)
	root.add_child(weir_node)
	CalderaKit.solid_box(root, "BrambleWeirSill", sill_at + Vector3(0.0, 0.1, 0.0), Vector3(width, 0.9, 1.4), yaw, ActorBase.LAYER_LOW_SCENERY)
	# White water spilling over the sill's downstream lip.
	var spill: MeshInstance3D = MeshInstance3D.new()
	spill.name = "WeirSpill"
	var sheet: BoxMesh = BoxMesh.new()
	sheet.size = Vector3(width - 0.4, 0.06, 0.9)
	spill.mesh = sheet
	spill.position = sill_at + Vector3(flow.x, 0.5, flow.y) * 1.0 + Vector3(0.0, -0.1, 0.0)
	spill.rotation.y = yaw
	spill.material_override = WorldVisualCatalog.water(&"flat", Vector2(flow.x, flow.y) * 1.4)
	spill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(spill)
	AudioDirector.attach_ambience(weir_node, &"water_trickle", sill_at + Vector3(0.0, 0.8, 0.0), 0.0)
	CalderaKit.sign_label(root, "WeirSign", "The Bramble Weir\nchoked by the Elder Oak's roots: the Root-Sanctum's way out", sill_at + Vector3(0.0, 2.6, 0.0))
	# The race: kerbs and water along the generator's line.
	var race: PackedVector2Array = builder.points_of("mill_race")
	if race.size() < 2:
		return
	var kerbs: LandblockTerrain.MeshMerge = CalderaKit.merge()
	var water: LandblockTerrain.MeshMerge = CalderaKit.merge()
	for index: int in race.size() - 1:
		var a: Vector2 = race[index]
		var b: Vector2 = race[index + 1]
		var pieces: int = int(a.distance_to(b) / 3.0) + 1
		var side_dir: Vector2 = Vector2(-(b - a).y, (b - a).x).normalized()
		for piece: int in pieces:
			var p0: Vector2 = a.lerp(b, float(piece) / float(pieces))
			var p1: Vector2 = a.lerp(b, float(piece + 1) / float(pieces))
			var g0: Vector3 = builder.ground(p0.x, p0.y)
			var g1: Vector3 = builder.ground(p1.x, p1.y)
			var step: Vector2 = p1 - p0
			var tilt: Basis = Basis(Vector3.UP, atan2(step.x, step.y)) * Basis(Vector3.RIGHT, atan2(g0.y - g1.y, step.length()))
			var middle: Vector3 = (g0 + g1) * 0.5
			var slab: BoxMesh = BoxMesh.new()
			slab.size = Vector3(RACE_WIDTH, 0.05, step.length() + 0.3)
			water.add_arrays(slab.get_mesh_arrays(), Transform3D(tilt, middle + Vector3(0.0, RACE_LIFT, 0.0)), Color.WHITE)
			for side: float in [-1.0, 1.0]:
				var kerb: BoxMesh = BoxMesh.new()
				kerb.size = Vector3(0.35, 0.45, step.length() + 0.3)
				var offset: Vector2 = side_dir * (RACE_WIDTH * 0.5 + 0.17) * side
				kerbs.add_arrays(kerb.get_mesh_arrays(), Transform3D(tilt, middle + Vector3(offset.x, RACE_LIFT + 0.1, offset.y)), CalderaKit.STONE.darkened(0.1))
	root.add_child(CalderaKit.mesh_node("MillRaceKerbs", kerbs))
	var leat: MeshInstance3D = MeshInstance3D.new()
	leat.name = "MillRace"
	leat.mesh = water.commit()
	leat.material_override = WorldVisualCatalog.water(&"flat", Vector2(0.0, 0.5))
	leat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(leat)


# --- The Deep-Hush ---------------------------------------------------------------------------

## The boundary seal (docs/27 §4): a standing haze along the island's south-east edge,
## humming low. No wall: the sea beyond it is deep, and the tide carries a party back.
static func _build_seal(root: Node3D, builder: EmbershoreBuilder) -> void:
	var line: PackedVector2Array = builder.points_of("boundary_seal")
	if line.size() < 2:
		return
	var holder: Node3D = Node3D.new()
	holder.name = "DeepHush"
	root.add_child(holder)
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var along: float = 0.0
	for index: int in line.size():
		if index > 0:
			along += line[index].distance_to(line[index - 1])
		vertices.append(Vector3(line[index].x, -8.0, line[index].y))
		vertices.append(Vector3(line[index].x, SEAL_TOP, line[index].y))
		var side: Vector2 = Vector2.ZERO
		if index < line.size() - 1:
			side = (line[index + 1] - line[index]).normalized()
		else:
			side = (line[index] - line[index - 1]).normalized()
		normals.append(Vector3(-side.y, 0.0, side.x))
		normals.append(Vector3(-side.y, 0.0, side.x))
		uvs.append(Vector2(along, 1.0))
		uvs.append(Vector2(along, 0.0))
		if index > 0:
			var a: int = (index - 1) * 2
			indices.append_array(PackedInt32Array([a, a + 1, a + 2, a + 1, a + 3, a + 2]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var haze: MeshInstance3D = MeshInstance3D.new()
	haze.name = "Haze"
	haze.mesh = mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = SEAL_COLOR
	material.emission_enabled = true
	material.emission = Color(0.8, 0.86, 0.9)
	material.emission_energy_multiplier = 0.25
	haze.material_override = material
	haze.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(haze)
	# The hush: a low drone at the seal's middle, heard before it's seen.
	var middle: Vector2 = line[line.size() / 2]
	AudioDirector.attach_ambience(holder, &"gate_drone", Vector3(middle.x, 6.0, middle.y), -10.0)
	CalderaKit.sign_label(holder, "Sign", "The Deep-Hush\nthe First-Quiet lies beyond; the tide turns you back", Vector3(middle.x, 10.0, middle.y))


## Whether a spot lies on the far (south-east) side of the seal's line, within its reach.
static func beyond_seal(line: PackedVector2Array, at: Vector2, reach: float) -> bool:
	if line.size() < 2:
		return false
	var best: float = INF
	var side: float = 0.0
	for index: int in line.size() - 1:
		var a: Vector2 = line[index]
		var b: Vector2 = line[index + 1]
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(at, a, b)
		var gap: float = at.distance_to(closest)
		if gap < best:
			best = gap
			# The island lies north-west of the seal: a point south-east of a segment is beyond it.
			side = (b - a).cross(at - a)
			var inland: float = (b - a).cross(Vector2(a.x - 400.0, a.y - 400.0) - a)
			side = -1.0 if signf(side) == signf(inland) else 1.0
	return best <= reach and side > 0.0
