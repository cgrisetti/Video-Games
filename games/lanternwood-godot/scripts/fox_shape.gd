@tool
class_name FoxShape
extends RefCounted

# The fox's body as one seamless skin. It's described here as rounded pieces (ellipsoids, and
# capsules that taper from one end to the other), each fixed to a joint of the fox's skeleton. The
# pieces melt into each other where they meet (a "smooth union" of distance fields), so there are
# no seams. tools/make_fox.gd bakes them into a single mesh, models/fox_body.res, and the fox
# (fox.gd) wraps it over its Godot skeleton, so the skin bends smoothly at every joint.
#
# How baking works, step by step:
#   1. Measure, on a fine 3D grid, how far each point is from the fox's surface.
#   2. Put a point on the surface in every grid cell the surface passes through, and join them
#      into faces ("surface nets"). Then slide each point exactly onto the surface, which smooths it.
#   3. Tie each point to the joints of the nearest pieces (up to four), so it moves with them.
#   4. Paint it: each piece has a colour, and the colours blend softly where pieces meet, with
#      extra "paint-only" pieces for markings (ear tips, socks, a white tail tip).
# Change a piece here, then run tools/make_fox.gd to bake again.

# The joints, in the order the skeleton has them. Each matches a pivot fox.gd builds.
const BONES := [
	"rig", "body", "neck", "head", "jaw", "ear0", "ear1", "tail", "tail0", "tail1", "tail2", "tail3", "tail4",
	"leg0_upper", "leg0_lower", "leg0_paw", "leg1_upper", "leg1_lower", "leg1_paw",
	"leg2_upper", "leg2_lower", "leg2_paw", "leg3_upper", "leg3_lower", "leg3_paw",
]
const COLORS := {
	"fur": Color("#d9702a"),
	"back": Color("#b95a20"),
	"cream": Color("#f6ead6"),
	"dark": Color("#3a2618"),
	"tip": Color("#fbf6ec"),
}
const CELL := 0.018 # Grid spacing, in metres: smaller is smoother but slower to bake.
const SPREAD := 0.03 # How far a point's tie to a joint reaches across a joint, so the skin bends softly.
const COLOR_SPREAD := 0.012 # How softly colours blend where pieces meet.
const TAIL_WIDTHS := [0.07, 0.12, 0.155, 0.15, 0.12, 0.03]
const TAIL_PIECE := 0.2


# Every piece: which joint it's fixed to, its shape (in that joint's own space), its colour, and
# how softly it melts into the pieces before it ("blend", in metres). "paint" pieces only colour.
static func pieces(leg_lengths: Array) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var ellipsoid := func(bone: String, at: Vector3, radii: Vector3, color: String, blend := 0.0) -> void:
		list.append({"bone": bone, "shape": "ellipsoid", "at": at, "radii": radii, "color": color, "blend": blend})
	var capsule := func(bone: String, from: Vector3, to: Vector3, widths: Vector2, color: String, blend := 0.0, squash := Vector3.ONE) -> void:
		list.append({"bone": bone, "shape": "capsule", "from": from, "to": to, "widths": widths, "color": color, "blend": blend, "squash": squash})
	var paint := func(bone: String, at: Vector3, radii: Vector3, color: String, strength := 1.0) -> void:
		list.append({"bone": bone, "shape": "ellipsoid", "at": at, "radii": radii, "color": color, "paint": true, "strength": strength})

	# The body: a long, rounded barrel, a rump, a cream belly and a fluffy cream chest.
	ellipsoid.call("body", Vector3(0, 0.02, 0.42), Vector3(0.27, 0.25, 0.56), "fur")
	ellipsoid.call("body", Vector3(0, 0.07, -0.02), Vector3(0.19, 0.19, 0.2), "fur", 0.1)
	ellipsoid.call("body", Vector3(0, -0.1, 0.5), Vector3(0.19, 0.13, 0.4), "cream", 0.08)
	ellipsoid.call("body", Vector3(0, -0.03, 0.85), Vector3(0.21, 0.25, 0.19), "cream", 0.1)
	# The neck, rising out of the chest.
	ellipsoid.call("neck", Vector3(0, 0.1, 0.05), Vector3(0.14, 0.2, 0.16), "fur", 0.1)
	ellipsoid.call("neck", Vector3(0, 0.0, 0.13), Vector3(0.11, 0.16, 0.08), "cream", 0.06)
	# The head: a round crown, fluffy cheeks with tufts, and a soft, tapering snout.
	ellipsoid.call("head", Vector3.ZERO, Vector3(0.21, 0.18, 0.2), "fur", 0.08)
	for s: float in [-1.0, 1.0]:
		# A fluffy cheek, swept out into a tuft.
		capsule.call("head", Vector3(s * 0.1, -0.075, 0.07), Vector3(s * 0.23, -0.115, 0.0), Vector2(0.095, 0.035), "cream", 0.09)
	capsule.call("head", Vector3(0, -0.035, 0.1), Vector3(0, -0.06, 0.39), Vector2(0.095, 0.042), "fur", 0.035)
	paint.call("head", Vector3(0, -0.085, 0.27), Vector3(0.07, 0.035, 0.16), "cream") # The white of the muzzle.
	for s: float in [-1.0, 1.0]:
		paint.call("head", Vector3(s * 0.085, 0.1, 0.16), Vector3(0.045, 0.022, 0.03), "cream", 0.8) # Light marks over the eyes.
	# Ears: tall, flat cones with cream inside and dark tips.
	for ear in 2:
		var bone := "ear%d" % ear
		capsule.call(bone, Vector3(0, -0.02, 0), Vector3(0, 0.27, 0), Vector2(0.09, 0.006), "fur", 0.03, Vector3(1, 1, 0.42))
		paint.call(bone, Vector3(0, 0.1, 0.03), Vector3(0.05, 0.09, 0.03), "cream", 0.9)
		paint.call(bone, Vector3(0, 0.25, 0), Vector3(0.07, 0.07, 0.07), "dark")
	# The jaw: its own little piece, so the mouth can open.
	capsule.call("jaw", Vector3.ZERO, Vector3(0, -0.015, 0.27), Vector2(0.08, 0.028), "cream")
	# The tail: a bushy chain, thickest in the middle, with a white tip.
	for i in 5:
		capsule.call("tail%d" % i, Vector3.ZERO, Vector3(0, TAIL_PIECE, 0), Vector2(TAIL_WIDTHS[i], TAIL_WIDTHS[i + 1]), "fur", 0.08 if i == 0 else 0.04)
	paint.call("tail4", Vector3(0, 0.16, 0), Vector3(0.17, 0.15, 0.17), "tip")
	# A darker stripe along the back, the way real foxes have.
	paint.call("body", Vector3(0, 0.22, 0.35), Vector3(0.14, 0.08, 0.55), "back", 0.6)
	# Legs: a shoulder or haunch, a slim upper leg and lower leg, dark stockings and paws.
	for leg in 4:
		var front := leg < 2
		var lengths: Vector2 = leg_lengths[leg]
		var upper := "leg%d_upper" % leg
		var lower := "leg%d_lower" % leg
		var paw := "leg%d_paw" % leg
		if front:
			ellipsoid.call(upper, Vector3(0, -0.06, 0), Vector3(0.085, 0.15, 0.11), "fur", 0.09)
		else:
			ellipsoid.call(upper, Vector3(0, -0.06, 0.01), Vector3(0.11, 0.19, 0.17), "fur", 0.1) # Haunch.
		capsule.call(upper, Vector3(0, -0.05, 0), Vector3(0, -lengths.x, 0), Vector2(0.065, 0.05), "fur", 0.06)
		capsule.call(lower, Vector3.ZERO, Vector3(0, -lengths.y, 0), Vector2(0.05, 0.04), "fur", 0.04)
		ellipsoid.call(paw, Vector3(0, 0.02, 0.035), Vector3(0.052, 0.034, 0.08), "dark", 0.035)
		list.append({"bone": lower, "shape": "capsule", "from": Vector3(0, -lengths.y * 0.38, 0), "to": Vector3(0, -lengths.y - 0.05, 0), "widths": Vector2(0.075, 0.075), "color": "dark", "paint": true, "strength": 1.0, "squash": Vector3.ONE})
	return list


# Bake the skin. `rest` gives each joint's place on the standing fox (in the fox's own space).
# Returns {"body": ArrayMesh tied to the skeleton, "jaw": ArrayMesh in the jaw's own space}.
static func bake(rest: Dictionary, leg_lengths: Array) -> Dictionary:
	var all := pieces(leg_lengths)
	var body: Array[Dictionary] = []
	var jaw: Array[Dictionary] = []
	for piece in all:
		_prepare(piece, rest)
		(jaw if piece.bone == "jaw" else body).append(piece)
	var body_mesh := _mesh(body, true)
	var jaw_mesh := _mesh(jaw, false, (rest["jaw"] as Transform3D).affine_inverse())
	return {"body": body_mesh, "jaw": jaw_mesh}


# Work out, once, what each piece needs to measure distances quickly.
static func _prepare(piece: Dictionary, rest: Dictionary) -> void:
	var joint: Transform3D = rest[piece.bone]
	piece["to_local"] = joint.affine_inverse()
	piece["unit"] = joint.basis.get_scale().x # Joints can be scaled (the head is); distances scale with them.
	piece["bone_index"] = BONES.find(piece.bone)
	var reach: Vector3
	var middle: Vector3
	if piece.shape == "ellipsoid":
		reach = piece.radii
		middle = piece.at
	else:
		var w: Vector2 = piece.widths
		var r := maxf(w.x, w.y)
		middle = (piece.from + piece.to) * 0.5
		reach = ((piece.to - piece.from).abs() * 0.5 + Vector3.ONE * r) * piece.get("squash", Vector3.ONE)
	var box := AABB(middle - reach, reach * 2.0)
	piece["box"] = joint * box


# How far `p` (in the fox's space) is from a piece's surface; negative inside.
static func _distance(piece: Dictionary, p: Vector3) -> float:
	var local: Vector3 = piece.to_local * p
	var d: float
	if piece.shape == "ellipsoid":
		var radii: Vector3 = piece.radii
		var q := local - (piece.at as Vector3)
		var k0 := (q / radii).length()
		var k1 := (q / (radii * radii)).length()
		d = k0 * (k0 - 1.0) / maxf(k1, 0.0001)
	else:
		var squash: Vector3 = piece.squash
		var q := local / squash
		var a: Vector3 = (piece.from as Vector3) / squash
		var ba: Vector3 = (piece.to as Vector3) / squash - a
		var pa := q - a
		var h := clampf(pa.dot(ba) / ba.dot(ba), 0.0, 1.0)
		var w: Vector2 = piece.widths
		d = (pa - ba * h).length() - lerpf(w.x, w.y, h)
		d *= minf(squash.x, minf(squash.y, squash.z))
	return d * piece.unit


static func _smooth_min(a: float, b: float, k: float) -> float:
	if k <= 0.0:
		return minf(a, b)
	var h := maxf(k - absf(a - b), 0.0) / k
	return minf(a, b) - h * h * k * 0.25


# The whole surface's distance at `p`: every shape piece, melted together in order.
static func _surface(shapes: Array[Dictionary], p: Vector3) -> float:
	var d := 1000.0
	for piece in shapes:
		var box: AABB = piece.box
		if not box.grow(piece.blend + 0.05).has_point(p) and d < 0.05:
			continue # Too far away to change anything here.
		d = _smooth_min(d, _distance(piece, p), piece.blend)
	return d


static func _mesh(all: Array[Dictionary], skinned: bool, to_space := Transform3D.IDENTITY) -> ArrayMesh:
	var shapes: Array[Dictionary] = []
	var paints: Array[Dictionary] = []
	for piece in all:
		(paints if piece.get("paint", false) else shapes).append(piece)

	# 1. Distances on a grid round the whole shape.
	var bounds: AABB = shapes[0].box
	for piece in shapes:
		bounds = bounds.merge(piece.box)
	bounds = bounds.grow(0.04)
	var size := Vector3i((bounds.size / CELL).ceil()) + Vector3i.ONE
	var grid := PackedFloat32Array()
	grid.resize(size.x * size.y * size.z)
	grid.fill(1000.0)
	for piece in shapes:
		var box: AABB = piece.box.grow(piece.blend + CELL * 2.0)
		var low := Vector3i(((box.position - bounds.position) / CELL).floor()).clamp(Vector3i.ZERO, size - Vector3i.ONE)
		var high := Vector3i(((box.end - bounds.position) / CELL).ceil()).clamp(Vector3i.ZERO, size - Vector3i.ONE)
		for z in range(low.z, high.z + 1):
			for y in range(low.y, high.y + 1):
				var row := size.x * (y + size.y * z)
				for x in range(low.x, high.x + 1):
					var p := bounds.position + Vector3(x, y, z) * CELL
					grid[row + x] = _smooth_min(grid[row + x], _distance(piece, p), piece.blend)

	# 2. Surface nets: a point in every cell the surface passes through, then faces between them.
	var corners := [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(1, 1, 0), Vector3i(0, 0, 1), Vector3i(1, 0, 1), Vector3i(0, 1, 1), Vector3i(1, 1, 1)]
	var edges := [[0, 1], [2, 3], [4, 5], [6, 7], [0, 2], [1, 3], [4, 6], [5, 7], [0, 4], [1, 5], [2, 6], [3, 7]]
	var point_in := PackedInt32Array()
	point_in.resize(grid.size())
	point_in.fill(-1)
	var points := PackedVector3Array()
	var near := CELL * 2.5
	for z in size.z - 1:
		for y in size.y - 1:
			for x in size.x - 1:
				var index := x + size.x * (y + size.y * z)
				if absf(grid[index]) > near:
					continue
				var values := []
				var inside := 0
				for c in 8:
					var corner: Vector3i = corners[c]
					var value := grid[(x + corner.x) + size.x * ((y + corner.y) + size.y * (z + corner.z))]
					values.append(value)
					if value < 0.0:
						inside += 1
				if inside == 0 or inside == 8:
					continue
				var total := Vector3.ZERO
				var count := 0
				for edge: Array in edges:
					var a: float = values[edge[0]]
					var b: float = values[edge[1]]
					if (a < 0.0) != (b < 0.0):
						var t := a / (a - b)
						total += Vector3(corners[edge[0]]).lerp(Vector3(corners[edge[1]]), t)
						count += 1
				point_in[index] = points.size()
				points.append(bounds.position + (Vector3(x, y, z) + total / count) * CELL)
	var triangles := PackedInt32Array()
	var axes := [Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, 1)]
	var sides := [[Vector3i(0, 1, 0), Vector3i(0, 0, 1)], [Vector3i(0, 0, 1), Vector3i(1, 0, 0)], [Vector3i(1, 0, 0), Vector3i(0, 1, 0)]]
	for z in range(1, size.z - 1):
		for y in range(1, size.y - 1):
			for x in range(1, size.x - 1):
				var here := x + size.x * (y + size.y * z)
				var value := grid[here]
				if absf(value) > near:
					continue
				for a in 3:
					var step: Vector3i = axes[a]
					var other := grid[(x + step.x) + size.x * ((y + step.y) + size.y * (z + step.z))]
					if (value < 0.0) == (other < 0.0):
						continue
					var u: Vector3i = sides[a][0]
					var v: Vector3i = sides[a][1]
					var cells := [Vector3i(x, y, z), Vector3i(x, y, z) - u, Vector3i(x, y, z) - u - v, Vector3i(x, y, z) - v]
					var quad := []
					for cell: Vector3i in cells:
						quad.append(point_in[cell.x + size.x * (cell.y + size.y * cell.z)])
					if -1 in quad:
						continue
					if value < 0.0:
						quad.reverse()
					triangles.append_array([quad[0], quad[1], quad[2], quad[0], quad[2], quad[3]])

	# Slide every point exactly onto the surface, and find which way the surface faces there.
	var normals := PackedVector3Array()
	normals.resize(points.size())
	var e := CELL * 0.25
	for i in points.size():
		var p := points[i]
		var gradient := Vector3.UP
		for step in 3:
			var d := _surface(shapes, p)
			gradient = Vector3(
				_surface(shapes, p + Vector3(e, 0, 0)) - _surface(shapes, p - Vector3(e, 0, 0)),
				_surface(shapes, p + Vector3(0, e, 0)) - _surface(shapes, p - Vector3(0, e, 0)),
				_surface(shapes, p + Vector3(0, 0, e)) - _surface(shapes, p - Vector3(0, 0, e))).normalized()
			p -= gradient * d
		points[i] = p
		normals[i] = gradient
	# Godot draws the side of a triangle whose corners go clockwise: point each one outward.
	for t in range(0, triangles.size(), 3):
		var a := points[triangles[t]]
		var facing := (points[triangles[t + 1]] - a).cross(points[triangles[t + 2]] - a)
		if facing.dot(normals[triangles[t]] + normals[triangles[t + 1]] + normals[triangles[t + 2]]) > 0.0:
			var swap := triangles[t + 1]
			triangles[t + 1] = triangles[t + 2]
			triangles[t + 2] = swap

	# 3 and 4. Tie each point to its nearest joints, and paint it.
	var colors := PackedColorArray()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var rest_uv := PackedVector2Array()
	var rest_uv2 := PackedVector2Array()
	for p in points:
		var distances := []
		var closest := 1000.0
		for piece in shapes:
			var d := _distance(piece, p)
			distances.append(d)
			closest = minf(closest, d)
		var by_bone := {}
		var color := Color(0, 0, 0, 0)
		var color_total := 0.0
		for k in shapes.size():
			var piece: Dictionary = shapes[k]
			var extra: float = distances[k] - closest
			by_bone[piece.bone_index] = by_bone.get(piece.bone_index, 0.0) + exp(-extra / SPREAD)
			var tint := exp(-extra / COLOR_SPREAD)
			color += (COLORS[piece.color] as Color) * tint
			color_total += tint
		color /= color_total
		for piece in paints:
			var amount: float = (1.0 - smoothstep(-0.012, 0.018, _distance(piece, p))) * piece.strength
			color = color.lerp(COLORS[piece.color], amount)
		colors.append(Color(color.srgb_to_linear(), 1.0))
		var ranked := by_bone.keys()
		ranked.sort_custom(func(a: int, b: int) -> bool: return by_bone[a] > by_bone[b])
		var total := 0.0
		for j in 4:
			if j < ranked.size():
				total += by_bone[ranked[j]]
		for j in 4:
			bones.append(ranked[j] if j < ranked.size() else 0)
			weights.append(by_bone[ranked[j]] / total if j < ranked.size() else 0.0)
		rest_uv.append(Vector2(p.x, p.y)) # Where this point is on the standing fox, so the fur
		rest_uv2.append(Vector2(p.z, 0.0)) # texture stays put on the skin as it moves.

	if to_space != Transform3D.IDENTITY:
		for i in points.size():
			points[i] = to_space * points[i]
			normals[i] = (to_space.basis * normals[i]).normalized()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = rest_uv
	arrays[Mesh.ARRAY_TEX_UV2] = rest_uv2
	arrays[Mesh.ARRAY_INDEX] = triangles
	if skinned:
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	print("  baked %d points, %d triangles" % [points.size(), triangles.size() / 3])
	return mesh
