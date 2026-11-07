## Simple named shapes for everything built in code: hero puppets, props,
## interactables and scenery (08 Stage 5, the Rule of Three: these were copied
## into a dozen scripts). Each returns a MeshInstance3D at a position with its
## material on the mesh, ready to add as a child.
class_name ShapeKit
extends RefCounted

const SEGMENTS: int = 16


static func box(part_name: String, size: Vector3, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return node(part_name, mesh, where, material)


## A cylinder, or a cone or tapered post when `top` and `bottom` differ.
static func cylinder(part_name: String, top: float, bottom: float, height: float, where: Vector3, material: Material,
		segments: int = SEGMENTS) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = segments
	return node(part_name, mesh, where, material)


## A cone pointing up (+Y).
static func cone(part_name: String, radius: float, height: float, where: Vector3, material: Material) -> MeshInstance3D:
	return cylinder(part_name, 0.0, radius, height, where, material)


static func sphere(part_name: String, radius: float, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = SEGMENTS
	mesh.rings = SEGMENTS / 2
	return node(part_name, mesh, where, material)


static func capsule(part_name: String, radius: float, height: float, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 4
	return node(part_name, mesh, where, material)


static func torus(part_name: String, inner: float, outer: float, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: TorusMesh = TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = SEGMENTS
	mesh.ring_segments = 8
	return node(part_name, mesh, where, material)


## Any primitive mesh as a named, placed node with `material` on the mesh.
static func node(part_name: String, mesh: PrimitiveMesh, where: Vector3, material: Material) -> MeshInstance3D:
	mesh.material = material
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = where
	return instance


## Turns a shape (radians) and hands it back, for one-line placing.
static func tilted(shape: MeshInstance3D, rotation_radians: Vector3) -> MeshInstance3D:
	shape.rotation = rotation_radians
	return shape


## Stretches a shape (a squashed sphere, an oval) and hands it back.
static func stretched(shape: MeshInstance3D, scale: Vector3) -> MeshInstance3D:
	shape.scale = scale
	return shape


## Small parts skip casting shadows.
static func no_shadow(shape: MeshInstance3D) -> MeshInstance3D:
	shape.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return shape


# --- Sculpted geometry (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §3.2, §4) ---
# Each returns an ArrayMesh with normals, UVs and vertex colours (white, shaded
# toward grey where its own contact shadow falls), for a kit to merge with its
# own materials (WorldAssetCatalog.Parts.add_mesh) or to draw on its own.

## Bough tips (and the crown's middle) a gnarled trunk leaves for its leaves, in its own space.
const META_BOUGH_TIPS: StringName = &"bough_tips"
const META_CROWN_CENTER: StringName = &"crown_center"
const TRUNK_RINGS: int = 16
const TRUNK_SIDES: int = 12
const BOUGH_RINGS: int = 6
const BOUGH_SIDES: int = 7
## Boughs fork only above the 3.2 m combat sightline.
const BOUGH_START_M: float = 3.2
## The root-buttresses flare over the trunk's first 1.1 m.
const BUTTRESS_HEIGHT_M: float = 1.1
const BUTTRESS_FLARE: float = 0.48
const BUTTRESS_LOBES: float = 5.0


## A continuous oak trunk (18 §4.1): lofted along a curved Catmull-Rom spine
## from y = -0.2 m to `height`, five flared root-buttresses gripping the earth
## (r(y, θ) = r0(y)·(1 + 0.48·(1 - clamp(y/1.1))²·max(0, cos(5θ + φ)))), and
## `bough_count` tapered boughs forking upward at 32° to 48° from above 3.2 m.
## The bough tips and the crown's middle are in the mesh's metadata.
static func make_gnarled_trunk_mesh(height: float, base_radius: float, top_radius: float, bough_count: int, seed_val: int) -> ArrayMesh:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val * 7919 + 17
	var spine: PackedVector3Array = PackedVector3Array()
	for index: int in 5:
		var t: float = float(index) / 4.0
		var lean: float = 0.0 if index == 0 else rng.randf_range(-0.22, 0.22) * t
		spine.append(Vector3(lean, lerpf(-0.2, height, t), rng.randf_range(-0.22, 0.22) * t))
	var phase: float = rng.randf() * TAU
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var added: Dictionary = {"n": 0}
	var radius_at: Callable = func(y: float, theta: float) -> float:
		var t: float = clampf((y + 0.2) / (height + 0.2), 0.0, 1.0)
		var r0: float = lerpf(base_radius, top_radius, pow(t, 0.8))
		var low: float = 1.0 - clampf(y / BUTTRESS_HEIGHT_M, 0.0, 1.0)
		return r0 * (1.0 + BUTTRESS_FLARE * low * low * maxf(0.0, cos(BUTTRESS_LOBES * theta + phase)))
	_loft(tool, added, spine, TRUNK_RINGS, TRUNK_SIDES, radius_at, true)
	var tips: PackedVector3Array = PackedVector3Array()
	var crown: Vector3 = Vector3.ZERO
	var boughs: int = clampi(bough_count, 0, 6)
	for bough: int in boughs:
		var start_t: float = lerpf(0.0, 1.0, float(bough) / maxf(1.0, boughs - 1.0)) if boughs > 1 else 0.5
		var start_y: float = lerpf(BOUGH_START_M + 0.1, maxf(BOUGH_START_M + 0.4, height * 0.82), start_t)
		var base: Vector3 = _catmull_point(spine, clampf((start_y + 0.2) / (height + 0.2), 0.0, 1.0))
		var azimuth: float = TAU * float(bough) / boughs + rng.randf_range(-0.35, 0.35)
		var elevation: float = deg_to_rad(rng.randf_range(32.0, 48.0))
		var length: float = height * rng.randf_range(0.3, 0.44)
		var out: Vector3 = Vector3(cos(azimuth) * cos(elevation), sin(elevation), sin(azimuth) * cos(elevation))
		var path: PackedVector3Array = PackedVector3Array()
		for step: int in 4:
			var s: float = float(step) / 3.0
			# Each bough curves a little further up as it goes, like an oak limb reaching for the light.
			path.append(base + out * length * s + Vector3.UP * length * 0.16 * s * s)
		var root_r: float = lerpf(base_radius, top_radius, clampf(start_y / height, 0.0, 1.0)) * 0.62
		var bough_radius: Callable = func(_y: float, _theta: float) -> float: return root_r
		_loft(tool, added, path, BOUGH_RINGS, BOUGH_SIDES, bough_radius, false, 0.2)
		tips.append(path[path.size() - 1])
		crown += path[path.size() - 1]
	if tips.is_empty():
		crown = spine[spine.size() - 1]
	else:
		crown /= float(tips.size())
	tool.generate_normals()
	var mesh: ArrayMesh = tool.commit()
	mesh.set_meta(META_BOUGH_TIPS, tips)
	mesh.set_meta(META_CROWN_CENTER, crown)
	return mesh


## A volumetric leaf-cloud crown (18 §4.1): 11 to 18 overlapping, asymmetrically
## scaled icosahedral lobes with ruffled silhouettes in a tiered dome round
## `center`, their normals turned radially out from the crown's middle (so the
## cluster shades as one soft cloud) and coloured from `dark` below to `light`
## on top; `fronds` hanging willow or moss fronds trail from its lower rim.
static func make_leaf_cloud_crown(center: Vector3, radius: float, lobes: int, seed_val: int, dark: Color, light: Color, fronds: int = 0,
		frond_length: float = 1.6, min_lobes: int = 11) -> ArrayMesh:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val * 104729 + 3
	var ico: Array = _icosphere(1)
	var points: PackedVector3Array = ico[0]
	var faces: PackedInt32Array = ico[1]
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: int = clampi(lobes, min_lobes, 18)
	var base_index: int = 0
	for lobe: int in count:
		var tier: float = float(lobe) / float(count)
		# A tiered dome: a ring of lobes low and wide, more above, one on top.
		var azimuth: float = TAU * fposmod(float(lobe) * 0.618034, 1.0) + rng.randf_range(-0.2, 0.2)
		var elevation: float = lerpf(-0.35, 1.2, tier) + rng.randf_range(-0.15, 0.15)
		var direction: Vector3 = Vector3(cos(azimuth) * cos(elevation), sin(elevation), sin(azimuth) * cos(elevation)).normalized()
		var at: Vector3 = center + direction * radius * rng.randf_range(0.34, 0.62)
		var size: float = radius * rng.randf_range(0.36, 0.56) * lerpf(1.12, 0.82, tier)
		var stretch: Vector3 = Vector3(rng.randf_range(0.85, 1.25), rng.randf_range(0.72, 1.0), rng.randf_range(0.85, 1.25))
		var ruffle_seed: float = rng.randf() * 100.0
		for point: Vector3 in points:
			var ruffle: float = 1.0 + 0.17 * sin(point.x * 7.0 + ruffle_seed) * sin(point.y * 6.0 + ruffle_seed * 0.7) * sin(point.z * 8.0)
			var vertex: Vector3 = at + point * stretch * size * ruffle
			var outward: Vector3 = (vertex - center).normalized()
			var shade: float = clampf((vertex.y - (center.y - radius)) / (radius * 2.0), 0.0, 1.0)
			tool.set_normal((outward * 0.78 + point * 0.22).normalized())
			tool.set_color(dark.lerp(light, shade))
			tool.set_uv(Vector2(0.0, 1.0 - shade))
			tool.add_vertex(vertex)
		for index: int in faces:
			tool.add_index(base_index + index)
		base_index += points.size()
	for frond: int in clampi(fronds, 0, 40):
		var angle: float = TAU * float(frond) / maxf(1.0, fronds) + rng.randf_range(-0.1, 0.1)
		var reach: float = radius * rng.randf_range(0.62, 0.9)
		var top: Vector3 = center + Vector3(cos(angle) * reach, -radius * 0.25, sin(angle) * reach)
		var length: float = frond_length * rng.randf_range(0.75, 1.2)
		var side: Vector3 = Vector3(-sin(angle), 0.0, cos(angle)) * radius * 0.07
		var outward: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		for step: int in 4:
			var s0: float = float(step) / 4.0
			var s1: float = float(step + 1) / 4.0
			var a: Vector3 = top + Vector3(0.0, -length * s0, 0.0) + outward * 0.12 * s0 * s0
			var b: Vector3 = top + Vector3(0.0, -length * s1, 0.0) + outward * 0.12 * s1 * s1
			var width0: float = 1.0 - s0 * 0.6
			var width1: float = 1.0 - s1 * 0.6
			var quad: Array[Vector3] = [a - side * width0, a + side * width0, b + side * width1, b - side * width1]
			for corner: int in [0, 1, 2, 0, 2, 3]:
				tool.set_normal((outward + Vector3.UP * 0.3).normalized())
				tool.set_color(dark.lerp(light, 0.35 - 0.25 * s1))
				tool.set_uv(Vector2(0.0, 0.6 + 0.4 * s1))
				tool.add_vertex(quad[corner])
				tool.add_index(base_index)
				base_index += 1
	return tool.commit()


## A lush grass tuft (18 §4.2): `blades` (7 to 9) arched, crossed blades in four
## segments each, tapering to a point. UV.y runs 1 at the root to 0 at the tip,
## so the foliage shader can give the bottom 40% the ground's own colour.
static func make_lush_grass_tuft_mesh(blades: int = 8, seed_val: int = 11) -> ArrayMesh:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: int = clampi(blades, 7, 9)
	var index_base: int = 0
	for blade: int in count:
		var angle: float = TAU * float(blade) / count + rng.randf_range(-0.3, 0.3)
		var out: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var root: Vector3 = out * rng.randf_range(0.0, 0.07)
		var tall: float = rng.randf_range(0.28, 0.5)
		var arch: float = rng.randf_range(0.08, 0.2)
		var width: float = rng.randf_range(0.035, 0.055)
		var side: Vector3 = out.cross(Vector3.UP).normalized()
		var segments: int = 4
		for step: int in segments + 1:
			var s: float = float(step) / segments
			var at: Vector3 = root + Vector3.UP * tall * s + out * arch * s * s
			var half: float = width * 0.5 * (1.0 - s)
			var normal: Vector3 = (Vector3.UP * 0.6 + out * 0.4 * (1.0 - s)).normalized()
			for edge: float in [-1.0, 1.0]:
				tool.set_normal(normal)
				tool.set_color(Color.WHITE)
				tool.set_uv(Vector2(0.5 + edge * 0.5, 1.0 - s))
				tool.add_vertex(at + side * half * edge)
		for step: int in segments:
			var a: int = index_base + step * 2
			for corner: int in [a, a + 1, a + 3, a, a + 3, a + 2]:
				tool.add_index(corner)
		index_base += (segments + 1) * 2
	return tool.commit()


## A sculpted standing stone (18 §4.3): a subdivided icosahedron stretched to
## `size` (its foot at y = 0), its top tapered to 0.55x, cleaved flat by six
## deterministic Voronoi planes (dot(p, n) > d) so it reads as a hewn menhir,
## its ridges softened by shared normals, a little weathered roughness, and a
## darker foot where it meets the ground.
static func make_sculpted_megalith(size: Vector3, seed_val: int) -> ArrayMesh:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val * 31337 + 5
	var ico: Array = _icosphere(2)
	var points: PackedVector3Array = ico[0]
	var faces: PackedInt32Array = ico[1]
	var planes: Array[Vector4] = []
	for cut: int in 6:
		var azimuth: float = TAU * float(cut) / 6.0 + rng.randf_range(-0.4, 0.4)
		var tilt: float = rng.randf_range(-0.35, 0.55) if cut % 3 != 0 else rng.randf_range(0.5, 1.1)
		var normal: Vector3 = Vector3(cos(azimuth) * cos(tilt), sin(tilt), sin(azimuth) * cos(tilt)).normalized()
		planes.append(Vector4(normal.x, normal.y, normal.z, rng.randf_range(0.62, 0.84)))
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point: Vector3 in points:
		var p: Vector3 = point
		for plane: Vector4 in planes:
			var n: Vector3 = Vector3(plane.x, plane.y, plane.z)
			var over: float = p.dot(n) - plane.w
			if over > 0.0:
				p -= n * over
		var up: float = clampf(p.y * 0.5 + 0.5, 0.0, 1.0)
		var taper: float = lerpf(1.0, 0.55, up)
		var rough: float = 1.0 + 0.04 * sin(p.x * 9.0 + seed_val) * sin(p.z * 8.0 + p.y * 5.0)
		var vertex: Vector3 = Vector3(p.x * size.x * 0.5 * taper * rough, (p.y * 0.5 + 0.5) * size.y, p.z * size.z * 0.5 * taper * rough)
		tool.set_color(Color.WHITE.lerp(Color(0.62, 0.62, 0.62), 1.0 - smoothstep(0.0, 0.18, up)))
		tool.set_uv(Vector2(atan2(p.z, p.x) / TAU + 0.5, up))
		tool.add_vertex(vertex)
	for index: int in faces:
		tool.add_index(index)
	tool.generate_normals()
	return tool.commit()


## A sharp slate shard (a Hush-Crack's monolith, 18 §5 layer 3): a megalith
## squeezed thin and tall, cleaved to a jagged point.
static func make_slate_shard(height: float, seed_val: int) -> ArrayMesh:
	return make_sculpted_megalith(Vector3(height * 0.32, height, height * 0.18), seed_val + 900)


## A protruding rock-and-turf lip along an impassable cliff's crest (18 §3.2),
## `length` along x, jutting `depth` out over -z: surface 0 the rock (its ragged
## underside in shadow), surface 1 the turf that overhangs its edge.
static func make_cliff_cornice(length: float, depth: float, seed_val: int) -> ArrayMesh:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val * 65537 + 9
	var columns: int = maxi(3, int(length / 0.8))
	var rock: SurfaceTool = SurfaceTool.new()
	rock.begin(Mesh.PRIMITIVE_TRIANGLES)
	var turf: SurfaceTool = SurfaceTool.new()
	turf.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile: Array[Vector2] = []
	for column: int in columns + 1:
		profile.append(Vector2(depth * rng.randf_range(0.7, 1.15), rng.randf_range(0.45, 0.9)))
	for column: int in columns + 1:
		var x: float = -length * 0.5 + length * float(column) / columns
		var reach: float = profile[column].x
		var thick: float = profile[column].y
		# Rock section, back (in the cliff) to lip: top back, top lip, under lip, under back.
		var ring: Array[Vector3] = [Vector3(x, 0.0, 0.4), Vector3(x, 0.02, -reach), Vector3(x, -thick * 0.55, -reach * 0.88),
			Vector3(x, -thick, 0.1)]
		var shades: Array[float] = [1.0, 0.92, 0.5, 0.42]
		for corner: int in ring.size():
			rock.set_color(Color.WHITE * shades[corner])
			rock.set_uv(Vector2(x * 0.5, float(corner) * 0.33))
			rock.add_vertex(ring[corner])
		var lip: Array[Vector3] = [Vector3(x, 0.05, 0.6), Vector3(x, 0.09, -reach - 0.12), Vector3(x, -0.08, -reach - 0.18)]
		for corner: int in lip.size():
			turf.set_color(Color.WHITE * (1.0 if corner < 2 else 0.7))
			turf.set_uv(Vector2(x * 0.5, float(corner) * 0.5))
			turf.add_vertex(lip[corner])
	for column: int in columns:
		var a: int = column * 4
		var b: int = (column + 1) * 4
		for edge: int in 3:
			for corner: int in [a + edge, b + edge, b + edge + 1, a + edge, b + edge + 1, a + edge + 1]:
				rock.add_index(corner)
		var c: int = column * 3
		var d: int = (column + 1) * 3
		for edge: int in 2:
			for corner: int in [c + edge, d + edge, d + edge + 1, c + edge, d + edge + 1, c + edge + 1]:
				turf.add_index(corner)
	rock.generate_normals()
	turf.generate_normals()
	var mesh: ArrayMesh = rock.commit()
	turf.commit(mesh)
	return mesh


## A flared foundation collar round a `footprint` (x by z, centred) so a building
## looks rooted (18 §4.3): from 0.45 m up its walls it flares 0.45 m out to just
## under the ground, darker (vertex-baked contact shadow) toward its foot.
static func make_ground_contact_skirt(footprint: Vector2) -> ArrayMesh:
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: Vector2 = footprint * 0.5
	var corners: Array[Vector2] = [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]
	var flare: float = 0.45
	var index_base: int = 0
	for side: int in 4:
		var a: Vector2 = corners[side]
		var b: Vector2 = corners[(side + 1) % 4]
		var along: Vector2 = (b - a).normalized()
		var outward: Vector2 = Vector2(along.y, -along.x)
		var steps: int = maxi(2, int(a.distance_to(b) / 0.6))
		for step: int in steps + 1:
			var t: float = float(step) / steps
			var at: Vector2 = a.lerp(b, t)
			# Mitred corners: the outer edge widens along the diagonal there.
			var corner_push: Vector2 = Vector2.ZERO
			if step == 0:
				corner_push = -along * flare
			elif step == steps:
				corner_push = along * flare
			var wobble: float = 0.06 * sin(at.x * 3.1 + at.y * 2.3)
			var top: Vector3 = Vector3(at.x, 0.45, at.y) + Vector3(outward.x, 0.0, outward.y) * 0.02
			var mid: Vector3 = Vector3(at.x, 0.18, at.y) + Vector3(outward.x, 0.0, outward.y) * (flare * 0.5 + wobble)
			var foot: Vector2 = at + outward * (flare + wobble) + corner_push * 0.5
			var low: Vector3 = Vector3(foot.x, -0.05, foot.y)
			var rows: Array[Vector3] = [top, mid, low]
			var shades: Array[float] = [0.88, 0.7, 0.5]
			for row: int in 3:
				tool.set_color(Color.WHITE * shades[row])
				tool.set_uv(Vector2(t, float(row) * 0.5))
				tool.add_vertex(rows[row])
		for step: int in steps:
			var p: int = index_base + step * 3
			var q: int = p + 3
			for corner: int in [p, q, q + 1, p, q + 1, p + 1, p + 1, q + 1, q + 2, p + 1, q + 2, p + 2]:
				tool.add_index(corner)
		index_base += (steps + 1) * 3
	tool.generate_normals()
	return tool.commit()


## Lofts tube rings along a Catmull-Rom path (ring radius from `radius_at`(y, θ)),
## capping the end; `tip_share` tapers a bough's last ring to that share.
## `added["n"]` counts the vertices the tool has so far.
static func _loft(tool: SurfaceTool, added: Dictionary, path: PackedVector3Array, rings: int, sides: int, radius_at: Callable,
		trunk: bool, tip_share: float = 1.0) -> void:
	var start: int = int(added["n"])
	var length: float = 0.0
	for index: int in path.size() - 1:
		length += path[index].distance_to(path[index + 1])
	for ring: int in rings + 1:
		var t: float = float(ring) / rings
		var center: Vector3 = _catmull_point(path, t)
		var ahead: Vector3 = (_catmull_point(path, minf(1.0, t + 0.02)) - _catmull_point(path, maxf(0.0, t - 0.02))).normalized()
		var side_a: Vector3 = ahead.cross(Vector3.FORWARD if absf(ahead.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		var side_b: Vector3 = ahead.cross(side_a).normalized()
		var shrink: float = lerpf(1.0, tip_share, t) if not trunk else 1.0
		for side: int in sides:
			var theta: float = TAU * float(side) / sides
			var r: float = float(radius_at.call(center.y, theta)) * shrink
			var dir: Vector3 = side_a * cos(theta) + side_b * sin(theta)
			var shade: float = 0.62 + 0.38 * smoothstep(-0.2, 1.4, center.y) if trunk else 0.9
			tool.set_color(Color.WHITE * shade)
			tool.set_uv(Vector2(float(side) / sides, t * length * 0.5))
			tool.add_vertex(center + dir * r)
	added["n"] = start + (rings + 1) * sides
	for ring: int in rings:
		for side: int in sides:
			var a: int = start + ring * sides + side
			var b: int = start + ring * sides + (side + 1) % sides
			var c: int = a + sides
			var d: int = b + sides
			for corner: int in [a, c, b, b, c, d]:
				tool.add_index(corner)
	# A cap on the far end (and none at a trunk's foot, under the ground).
	var cap: int = int(added["n"])
	var tip: Vector3 = _catmull_point(path, 1.0)
	tool.set_color(Color.WHITE * 0.8)
	tool.set_uv(Vector2(0.5, length * 0.5))
	tool.add_vertex(tip + (tip - _catmull_point(path, 0.97)).normalized() * 0.02)
	added["n"] = cap + 1
	for side: int in sides:
		var a: int = start + rings * sides + side
		var b: int = start + rings * sides + (side + 1) % sides
		for corner: int in [a, b, cap]:
			tool.add_index(corner)


## A point `t` (0 to 1) along a Catmull-Rom curve through `points`.
static func _catmull_point(points: PackedVector3Array, t: float) -> Vector3:
	var count: int = points.size()
	if count == 1:
		return points[0]
	var span: float = clampf(t, 0.0, 1.0) * (count - 1)
	var index: int = mini(int(span), count - 2)
	var f: float = span - index
	var p0: Vector3 = points[maxi(index - 1, 0)]
	var p1: Vector3 = points[index]
	var p2: Vector3 = points[index + 1]
	var p3: Vector3 = points[mini(index + 2, count - 1)]
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * f + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * f * f + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * f * f * f)


static var _icospheres: Dictionary[int, Array] = {}


## A unit icosphere subdivided `level` times: [points, triangle indices], cached.
static func _icosphere(level: int) -> Array:
	if _icospheres.has(level):
		return _icospheres[level]
	var t: float = (1.0 + sqrt(5.0)) * 0.5
	var points: PackedVector3Array = PackedVector3Array([Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t), Vector3(t, 0, -1), Vector3(t, 0, 1),
		Vector3(-t, 0, -1), Vector3(-t, 0, 1)])
	for index: int in points.size():
		points[index] = points[index].normalized()
	var faces: PackedInt32Array = PackedInt32Array([0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, 1, 5, 9, 5, 11, 4, 11, 10, 2,
		10, 7, 6, 7, 1, 8, 3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9, 4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1])
	for pass_index: int in level:
		var middles: Dictionary[int, int] = {}
		var next: PackedInt32Array = PackedInt32Array()
		for face: int in range(0, faces.size(), 3):
			var corners: Array[int] = [faces[face], faces[face + 1], faces[face + 2]]
			var mids: Array[int] = []
			for edge: int in 3:
				var a: int = corners[edge]
				var b: int = corners[(edge + 1) % 3]
				var key: int = mini(a, b) * 100000 + maxi(a, b)
				if not middles.has(key):
					middles[key] = points.size()
					points.append(((points[a] + points[b]) * 0.5).normalized())
				mids.append(middles[key])
			next.append_array(PackedInt32Array([corners[0], mids[0], mids[2], corners[1], mids[1], mids[0], corners[2], mids[2], mids[1],
				mids[0], mids[1], mids[2]]))
		faces = next
	var made: Array = [points, faces]
	_icospheres[level] = made
	return made
