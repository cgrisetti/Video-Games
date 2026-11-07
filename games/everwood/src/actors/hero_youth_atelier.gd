## Sculpts the Level 1 youth (21_WINGFEATHER_YOUTH_HERO.md; the Equipment &
## Grimoire doc §2, "The Wingfeather Youth Aesthetic"): a 14-year-old Unsworn
## Wayfarer in homespun, on the same 24-bone HeroRigBuilder skeleton as every
## hero, so the shared clip library, the foot-plant IK and the sockets all work.
##
## The body is sculpted in the rig's own space, slimmer than an adult's round
## the same joints; ActorVisuals then draws the skeleton at
## HeroAppearanceResource.YOUTH_SKELETON_SCALE (a youth about 1.6 m tall). The
## head is sculpted 1.18x round the neck joint and the hands and boots 1.22x
## round the wrist and the sole (Sculpt.warp), so the youth reads from the
## 4.8 m split-screen camera without bending any bone.
##
## "Truth of Materials": nothing rubbery or inflated. Hand-worked homespun
## with real seams, folds, rolled cuffs, a patched knee and a raw-hemmed cape.
##
## The five surfaces keep HeroMeshAtelier.REGIONS' names:
##   mesh_head_heritage     a young face (soft brow planes, big eyes, a small
##                          upturned nose), cupped ears and a wind-tousled mop
##   mesh_torso_coat        the loose linen shirt, the neck, and the breeches' seat
##   mesh_pauldrons_tabard  the leather braces crossed at the back, and the
##                          Fellowship-coloured neckerchief knotted at the throat
##   mesh_limbs_boots       rolled sleeves and bare forearms, big bare hands,
##                          cuffed breeches with a patched knee, striped
##                          stockings and turned-down boots
##   mesh_belt_cloak        the belt and its pouch, the hood folded round the
##                          shoulders, and the short half-cape on Cloak_01..03
class_name HeroYouthAtelier
extends RefCounted

const B = HeroRigBuilder.Bone
## The head scales round the middle of the face, so it grows up and out more than down onto the neck.
const HEAD_PIVOT: Vector3 = Vector3(0.0, 1.52, -0.01)
## The eyes are drawn this much bigger again, round their own centres.
const EYE_SCALE: float = 1.14
## The adult brow (HeroMeshAtelier._eye, everything above BROW_FROM) lifts this far, its inner end further.
const BROW_FROM: float = 1.6135
const BROW_LIFT: float = 0.004
const BROW_INNER_LIFT: float = 0.007
## The shirt, hips to shoulders: (height, half-width, half-depth, centre z).
const SHIRT_RINGS: Array[Vector4] = [
	Vector4(0.94, 0.15, 0.113, 0.0), Vector4(1.02, 0.152, 0.113, -0.004), Vector4(1.1, 0.157, 0.115, -0.008), Vector4(1.18, 0.168, 0.12, -0.012),
	Vector4(1.26, 0.181, 0.124, -0.014), Vector4(1.33, 0.183, 0.12, -0.01), Vector4(1.38, 0.15, 0.104, -0.004), Vector4(1.415, 0.085, 0.078, 0.0),
]
## The cape's hem height (rig space), lifted in raw dags.
const CAPE_HEM: float = 1.0


## The youth's five skinned surfaces, in HeroMeshAtelier.REGIONS order.
static func build_surfaces(look: HeroAppearanceResource) -> Array[ArrayMesh]:
	return [_head(look), _torso(), _braces_scarf(), _limbs(), _belt_cape()]


# --- Helpers ---------------------------------------------------------------------

static func _r(c: Vector3, w: float, d: float, bones: Dictionary, m: float, extra: Dictionary = {}) -> Dictionary:
	return HeroMeshAtelier._r(c, w, d, bones, m, extra)


static func _w(pairs: Array) -> Dictionary:
	return HeroMeshAtelier._w(pairs)


static func _loft(s: HeroMeshAtelier.Sculpt, control: Array[Dictionary], options: Dictionary = {}) -> void:
	HeroMeshAtelier._loft(s, control, options)


## Scales every vertex round `pivot` by `k` (per axis).
static func scale_about(pivot: Vector3, k: Vector3) -> Callable:
	return func(p: Vector3) -> Vector3: return pivot + (p - pivot) * k


## The head's warp: the youth's 1.18x cranium (a touch wider, for a young face).
static func head_warp() -> Callable:
	var k: float = HeroAppearanceResource.YOUTH_HEAD_SCALE
	return scale_about(HEAD_PIVOT, Vector3(k * 1.03, k, k))


## The shirt at a height: Vector3(half-width, half-depth, centre z).
static func shirt_at(y: float) -> Vector3:
	var below: Vector4 = SHIRT_RINGS[0]
	for ring: Vector4 in SHIRT_RINGS:
		if ring.x >= y:
			var u: float = 0.0 if is_equal_approx(ring.x, below.x) else clampf((y - below.x) / (ring.x - below.x), 0.0, 1.0)
			return Vector3(lerpf(below.y, ring.y, u), lerpf(below.z, ring.z, u), lerpf(below.w, ring.w, u))
		below = ring
	return Vector3(below.y, below.z, below.w)


## A point `out` metres off the shirt at a height, `angle` round from the front (+ toward the youth's right, PI the back).
static func shirt_point(y: float, angle: float, out: float) -> Vector3:
	var at: Vector3 = shirt_at(y)
	return Vector3(sin(angle) * (at.x + out), y, at.z - cos(angle) * (at.y + out))


# --- The head ---------------------------------------------------------------------

static func _head(look: HeroAppearanceResource) -> ArrayMesh:
	var s: HeroMeshAtelier.Sculpt = HeroMeshAtelier.Sculpt.new(true)
	var head: Dictionary = _w([B.HEAD, 1.0])
	var warp: Callable = head_warp()
	s.warp = warp
	# A young face, still planed (doc: "clear brow-ridge planes"), but soft: a
	# gentle brow, shallow sockets, full cheeks, smooth temples, a rounded chin.
	var planes_fn: Callable = func(theta: float, _t: float, p: Vector3) -> Vector3:
		var front: float = smoothstep(0.35, 0.85, maxf(0.0, -sin(theta)))
		var side: float = signf(p.x)
		var brow: float = exp(-pow((p.y - 1.628) / 0.012, 2.0)) * exp(-pow(p.x / 0.1, 4.0)) * front
		var socket: float = exp(-pow((p.y - 1.598) / 0.016, 2.0)) * exp(-pow((absf(p.x) - 0.052) / 0.027, 2.0)) * front
		var cheek: float = exp(-pow((p.y - 1.565) / 0.02, 2.0)) * exp(-pow((absf(p.x) - 0.082) / 0.03, 2.0)) * smoothstep(0.1, 0.6, maxf(0.0, -sin(theta)))
		var jaw: float = 1.0 - smoothstep(1.49, 1.54, p.y)
		var moved: Vector3 = p + Vector3(0.0, 0.0, -0.004 * brow + 0.015 * socket - 0.012 * cheek)
		moved.x += side * 0.008 * cheek
		moved.x *= 1.0 - 0.1 * jaw
		return moved
	_loft(s, [
		_r(Vector3(0.0, 1.48, -0.006), 0.058, 0.058, _w([B.NECK, 0.5, B.HEAD, 0.5]), HeroMeshAtelier.MAT_FACE, {"ao": 0.6}),
		_r(Vector3(0.0, 1.507, -0.012), 0.1, 0.102, _w([B.NECK, 0.12, B.HEAD, 0.88]), HeroMeshAtelier.MAT_FACE),
		_r(Vector3(0.0, 1.533, -0.018), 0.12, 0.124, head, HeroMeshAtelier.MAT_FACE),
		_r(Vector3(0.0, 1.56, -0.016), 0.131, 0.134, head, HeroMeshAtelier.MAT_FACE),
		_r(Vector3(0.0, 1.585, -0.01), 0.139, 0.142, head, HeroMeshAtelier.MAT_FACE),
		_r(Vector3(0.0, 1.61, -0.006), 0.143, 0.146, head, HeroMeshAtelier.MAT_FACE),
		_r(Vector3(0.0, 1.635, -0.002), 0.144, 0.147, head, HeroMeshAtelier.MAT_FACE),
		_r(Vector3(0.0, 1.665, 0.004), 0.141, 0.144, head, HeroMeshAtelier.MAT_FACE),
		_r(Vector3(0.0, 1.705, 0.01), 0.126, 0.13, head, HeroMeshAtelier.MAT_FACE),
		_r(Vector3(0.0, 1.735, 0.012), 0.092, 0.096, head, HeroMeshAtelier.MAT_FACE),
		_r(Vector3(0.0, 1.75, 0.012), 0.03, 0.03, head, HeroMeshAtelier.MAT_FACE),
	], {"n": 2.2, "cap_end": true, "sides": 24, "subdiv": 3, "offset_fn": planes_fn, "face_zones": true})
	# A small, upturned nose: a short soft bridge to a round button tip.
	_loft(s, [
		_r(Vector3(0.0, 1.598, -0.142), 0.008, 0.007, head, HeroMeshAtelier.MAT_FACE),
		_r(Vector3(0.0, 1.583, -0.152), 0.009, 0.008, head, HeroMeshAtelier.MAT_FACE),
		_r(Vector3(0.0, 1.57, -0.16), 0.011, 0.009, head, HeroMeshAtelier.MAT_FACE),
	], {"n": 2.6, "sides": 8, "face_zones": true})
	HeroMeshAtelier._ellipsoid(s, Vector3(0.0, 1.566, -0.1615), Vector3(0.017, 0.014, 0.011), head, HeroMeshAtelier.MAT_FACE, Vector3.FORWARD, {},
		{"face_zones": true})
	# The mouth: an easy half-smile pressed into the face, its corners turned up.
	var lip: Dictionary = _w([B.HEAD, 0.6, B.JAW_BEARD, 0.4])
	var mouth: Array[Dictionary] = []
	for index: int in 7:
		var u: float = lerpf(-1.0, 1.0, float(index) / 6.0)
		var x: float = u * 0.024
		var depth: float = -0.1305 * sqrt(maxf(0.0, 1.0 - pow(x / 0.105, 2.0))) - 0.0055
		mouth.append(_r(Vector3(x, 1.519 + 0.0045 * u * u + 0.0012 * u, depth), 0.0032, 0.0026, lip, HeroMeshAtelier.MAT_FACE, {"ao": 0.18}))
	_loft(s, mouth, {"sides": 6, "subdiv": 2, "cap_start": true, "cap_end": true, "side": Vector3.UP, "face_zones": true})
	for side: float in [-1.0, 1.0]:
		# Cupped ears, half under the hair: the rim, and the hollow of the bowl.
		HeroMeshAtelier._ellipsoid(s, Vector3(side * 0.152, 1.596, 0.014), Vector3(0.012, 0.033, 0.024), head, HeroMeshAtelier.MAT_FACE, Vector3.RIGHT * side, {},
			{"face_zones": true})
		HeroMeshAtelier._ellipsoid(s, Vector3(side * 0.159, 1.592, 0.012), Vector3(0.005, 0.019, 0.013), head, HeroMeshAtelier.MAT_FACE, Vector3.RIGHT * side,
			{"ao": 0.3}, {"face_zones": true})
		# Big, bright eyes, drawn larger again round their own centres.
		var eye_center: Vector3 = Vector3(side * 0.052, 1.598, -0.131)
		s.warp = func(p: Vector3) -> Vector3:
			var q: Vector3 = p
			if q.y > BROW_FROM:
				# The brows ride higher, their inner ends most: open and curious, not the adults' set frown.
				q.y += BROW_LIFT + BROW_INNER_LIFT * (1.0 - smoothstep(0.02, 0.075, absf(q.x)))
			return warp.call(eye_center + (q - eye_center) * EYE_SCALE)
		HeroMeshAtelier._eye(s, side, head)
		s.warp = warp
	_hair(s, look)
	return s.commit(&"mesh_head_heritage")


## The wind-tousled mop: a cap of hair with its hairline over the brow, and a
## dozen chunky locks (bangs swept to the youth's left, a cowlick at the crown,
## locks over the ears and at the nape) so the silhouette reads at any pitch.
static func _hair(s: HeroMeshAtelier.Sculpt, _look: HeroAppearanceResource) -> void:
	var head: Dictionary = _w([B.HEAD, 1.0])
	var hair: float = HeroMeshAtelier.MAT_HAIR
	var cap_fn: Callable = func(theta: float, _t: float, p: Vector3) -> Vector3:
		var front: float = smoothstep(0.3, 0.8, maxf(0.0, -sin(theta)))
		# The hairline: low over the temples, up across the forehead.
		var hairline: float = lerpf(1.575, 1.672, front)
		if p.y >= hairline:
			return p
		# Below it the cap tucks inside the head.
		var tuck: float = smoothstep(hairline, hairline - 0.02, p.y)
		return Vector3(p.x * (1.0 - 0.14 * tuck), p.y, lerpf(p.z, p.z * 0.55, tuck))
	_loft(s, [
		_r(Vector3(0.0, 1.548, 0.014), 0.138, 0.146, head, hair, {"ao": 0.6}),
		_r(Vector3(0.0, 1.59, 0.01), 0.152, 0.158, head, hair),
		_r(Vector3(0.0, 1.63, 0.007), 0.156, 0.16, head, hair),
		_r(Vector3(0.0, 1.67, 0.008), 0.153, 0.157, head, hair),
		_r(Vector3(0.0, 1.705, 0.012), 0.139, 0.144, head, hair),
		_r(Vector3(0.0, 1.734, 0.015), 0.11, 0.114, head, hair),
		_r(Vector3(0.0, 1.755, 0.015), 0.066, 0.068, head, hair),
		_r(Vector3(0.0, 1.764, 0.015), 0.016, 0.016, head, hair),
	], {"n": 2.2, "cap_start": true, "cap_end": true, "sides": 22, "subdiv": 2, "offset_fn": cap_fn})
	# [root, direction, length, width, droop]
	var locks: Array[Array] = [
		# The fringe, swept to the youth's left (-X), short enough to show the brows.
		[Vector3(0.075, 1.7, -0.118), Vector3(-0.3, -0.85, -0.38), 0.062, 0.03, 0.012],
		[Vector3(0.035, 1.712, -0.124), Vector3(-0.42, -0.8, -0.36), 0.074, 0.033, 0.014],
		[Vector3(-0.012, 1.712, -0.124), Vector3(-0.52, -0.76, -0.32), 0.07, 0.031, 0.014],
		[Vector3(-0.058, 1.7, -0.114), Vector3(-0.6, -0.74, -0.22), 0.06, 0.028, 0.01],
		# The tousled top and the cowlick at the crown.
		[Vector3(0.05, 1.752, -0.06), Vector3(0.45, 0.18, -0.8), 0.07, 0.036, 0.022],
		[Vector3(-0.045, 1.758, -0.035), Vector3(-0.55, 0.2, -0.65), 0.072, 0.036, 0.024],
		[Vector3(0.0, 1.758, 0.03), Vector3(0.12, 0.4, 0.85), 0.05, 0.03, 0.012],
		[Vector3(0.065, 1.746, 0.065), Vector3(0.65, 0.1, 0.62), 0.066, 0.034, 0.024],
		[Vector3(-0.07, 1.742, 0.07), Vector3(-0.65, 0.08, 0.6), 0.066, 0.034, 0.024],
		# Locks over the ears.
		[Vector3(0.132, 1.662, -0.03), Vector3(0.35, -0.9, -0.22), 0.07, 0.031, 0.008],
		[Vector3(0.14, 1.65, 0.045), Vector3(0.32, -0.9, 0.25), 0.075, 0.033, 0.008],
		[Vector3(-0.132, 1.662, -0.03), Vector3(-0.35, -0.9, -0.22), 0.07, 0.031, 0.008],
		[Vector3(-0.14, 1.65, 0.045), Vector3(-0.32, -0.9, 0.25), 0.075, 0.033, 0.008],
		# The nape.
		[Vector3(0.0, 1.62, 0.148), Vector3(0.0, -0.85, 0.5), 0.07, 0.04, 0.006],
		[Vector3(0.075, 1.62, 0.132), Vector3(0.38, -0.84, 0.4), 0.066, 0.036, 0.006],
		[Vector3(-0.075, 1.62, 0.132), Vector3(-0.38, -0.84, 0.4), 0.066, 0.036, 0.006],
	]
	for entry: Array in locks:
		_lock(s, entry[0], entry[1], entry[2], entry[3], entry[4], head)


## One lock of hair: a flattened, tapering clump from `root` along `dir`, drooping at its tip.
static func _lock(s: HeroMeshAtelier.Sculpt, root: Vector3, dir: Vector3, length: float, width: float, droop: float, bones: Dictionary) -> void:
	var d: Vector3 = dir.normalized()
	var outward: Vector3 = (root - Vector3(0.0, 1.63, 0.0)).normalized()
	var across: Vector3 = outward.cross(d)
	if across.length() < 0.2:
		across = Vector3.RIGHT
	var rings: Array[Dictionary] = []
	for index: int in 4:
		var u: float = float(index) / 3.0
		var center: Vector3 = root + d * length * u + Vector3(0.0, -droop * u * u, 0.0)
		var w: float = width * (1.0 - 0.82 * u)
		rings.append(_r(center, w, w * 0.45, bones, HeroMeshAtelier.MAT_HAIR, {"ao": 0.7 if index == 0 else 1.0, "g": 0.3 * u}))
	_loft(s, rings, {"sides": 6, "subdiv": 2, "cap_end": true, "side": across.normalized(), "proxy": 0.2})


# --- The shirt and the breeches' seat -------------------------------------------------

static func _torso() -> ArrayMesh:
	var s: HeroMeshAtelier.Sculpt = HeroMeshAtelier.Sculpt.new(true)
	# The loose linen shirt: soft vertical folds (a gentle wave in its outline and their shade), blousing over the belt.
	var fold_fn: Callable = func(theta: float, t: float, p: Vector3) -> Vector3:
		var fold: float = sin(theta * 7.0 + 0.6) * (1.0 - smoothstep(0.75, 1.0, t))
		var center_z: float = shirt_at(p.y).z
		var radial: Vector3 = Vector3(p.x, 0.0, p.z - center_z)
		return p + radial.normalized() * 0.0035 * fold if radial.length() > 0.001 else p
	var shade_fn: Callable = func(theta: float, t: float, c: Color) -> Color:
		if absf(c.b - HeroMeshAtelier.MAT_LINEN) > 0.01:
			return c
		return Color(c.r * (0.84 + 0.16 * (0.5 + 0.5 * sin(theta * 7.0 + 0.6))) * (1.0 - 0.12 * (1.0 - smoothstep(0.0, 0.15, t))), c.g, c.b, c.a)
	var shirt: Array[Dictionary] = []
	for ring: Vector4 in SHIRT_RINGS:
		shirt.append(_r(Vector3(0.0, ring.x, ring.w), ring.y, ring.z, HeroMeshAtelier._torso_bones(ring.x), HeroMeshAtelier.MAT_LINEN))
	shirt.append(_r(Vector3(0.0, 1.432, 0.004), 0.057, 0.059, _w([B.CHEST, 0.2, B.NECK, 0.8]), HeroMeshAtelier.MAT_SKIN))
	shirt.append(_r(Vector3(0.0, 1.5, 0.004), 0.054, 0.056, _w([B.NECK, 0.5, B.HEAD, 0.5]), HeroMeshAtelier.MAT_SKIN))
	_loft(s, shirt, {"n": 2.3, "cap_start": true, "sides": 20, "offset_fn": fold_fn, "color_fn": shade_fn})
	# The open collar's two soft points, lying on the collarbones under the neckerchief.
	for side: float in [-1.0, 1.0]:
		_loft(s, [
			_r(shirt_point(1.405, side * 0.55, 0.004), 0.022, 0.003, _w([B.CHEST, 1.0]), HeroMeshAtelier.MAT_LINEN, {"g": 0.6}),
			_r(shirt_point(1.37, side * 0.42, 0.006), 0.016, 0.003, _w([B.CHEST, 1.0]), HeroMeshAtelier.MAT_LINEN, {"g": 0.8}),
			_r(shirt_point(1.345, side * 0.28, 0.006), 0.004, 0.002, _w([B.CHEST, 1.0]), HeroMeshAtelier.MAT_LINEN),
		], {"sides": 6, "subdiv": 2, "cap_start": true, "cap_end": true, "side": Vector3(side, 0.0, 0.0)})
	# The breeches' seat, high-waisted over the tucked shirt, its waistband rolled.
	var seat: Array[Dictionary] = [
		_r(Vector3(0.0, 0.8, 0.012), 0.166, 0.12, _w([B.HIPS, 1.0]), HeroMeshAtelier.MAT_BREECHES, {"ao": 0.6}),
		_r(Vector3(0.0, 0.86, 0.008), 0.172, 0.128, _w([B.HIPS, 1.0]), HeroMeshAtelier.MAT_BREECHES),
		_r(Vector3(0.0, 0.92, 0.004), 0.166, 0.124, _w([B.HIPS, 1.0]), HeroMeshAtelier.MAT_BREECHES),
		_r(Vector3(0.0, 0.968, 0.0), 0.159, 0.12, HeroMeshAtelier._torso_bones(0.968), HeroMeshAtelier.MAT_BREECHES),
		_r(Vector3(0.0, 0.998, 0.0), 0.16, 0.121, HeroMeshAtelier._torso_bones(0.998), HeroMeshAtelier.MAT_BREECHES, {"g": 0.6}),
		_r(Vector3(0.0, 1.006, 0.0), 0.152, 0.114, HeroMeshAtelier._torso_bones(1.006), HeroMeshAtelier.MAT_BREECHES, {"ao": HeroMeshAtelier.UNDER_LIP_AO}),
	]
	_loft(s, seat, {"n": 2.4, "cap_start": true, "sides": 20, "subdiv": 2})
	return s.commit(&"mesh_torso_coat")


# --- Braces and neckerchief --------------------------------------------------------------

static func _braces_scarf() -> ArrayMesh:
	var s: HeroMeshAtelier.Sculpt = HeroMeshAtelier.Sculpt.new(true)
	# Saddle-leather braces: buttoned at the front waistband, up over each
	# shoulder, crossing in an X between the shoulder blades, buttoned at the back.
	for side: float in [-1.0, 1.0]:
		var path: Array[Dictionary] = []
		# [height, angle round from the front, how far off the shirt]
		var stations: Array[Vector3] = [
			Vector3(0.995, side * 0.44, 0.011), Vector3(1.1, side * 0.47, 0.007), Vector3(1.22, side * 0.5, 0.006),
			Vector3(1.32, side * 0.56, 0.007), Vector3(1.375, side * 0.62, 0.008),
		]
		for station: Vector3 in stations:
			path.append(_r(shirt_point(station.x, station.y, station.z), 0.016, 0.0028, HeroMeshAtelier._torso_bones(station.x), HeroMeshAtelier.MAT_LEATHER))
		path.append(_r(Vector3(side * 0.104, 1.418, -0.004), 0.016, 0.0028, _w([B.CHEST, 1.0]), HeroMeshAtelier.MAT_LEATHER, {"g": 0.5}))
		for station: Vector3 in [Vector3(1.375, side * (PI - 0.62), 0.008), Vector3(1.3, side * (PI - 0.42), 0.007), Vector3(1.2, side * (PI - 0.2), 0.008),
				Vector3(1.12, PI, 0.012), Vector3(1.06, -side * (PI - 0.24), 0.008), Vector3(0.995, -side * (PI - 0.42), 0.011)]:
			path.append(_r(shirt_point(station.x, station.y, station.z + (0.004 if side > 0.0 else 0.0)), 0.016, 0.0028,
				HeroMeshAtelier._torso_bones(station.x), HeroMeshAtelier.MAT_LEATHER))
		_loft(s, path, {"n": 5.0, "sides": 8, "subdiv": 3, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT, "proxy": 0.0})
		# Horn buttons where the braces meet the waistband.
		HeroMeshAtelier._stud(s, shirt_point(0.985, side * 0.44, 0.016), shirt_point(0.985, side * 0.44, 1.0) - shirt_point(0.985, side * 0.44, 0.0),
			0.008, _w([B.HIPS, 1.0]), HeroMeshAtelier.MAT_TIMBER)
		HeroMeshAtelier._stud(s, shirt_point(0.985, side * (PI - 0.42), 0.016), shirt_point(0.985, side * (PI - 0.42), 1.0) - shirt_point(0.985, side * (PI - 0.42), 0.0),
			0.008, _w([B.HIPS, 1.0]), HeroMeshAtelier.MAT_TIMBER)
	# The homespun neckerchief in the Fellowship's colour: a rolled band round the throat, a knot, two short tails.
	var neck: Dictionary = _w([B.CHEST, 0.45, B.NECK, 0.55])
	var scarf: float = HeroMeshAtelier.MAT_TUNIC
	_loft(s, [
		_r(Vector3(0.0, 1.405, 0.002), 0.07, 0.07, _w([B.CHEST, 0.8, B.NECK, 0.2]), scarf, {"ao": HeroMeshAtelier.UNDER_LIP_AO}),
		_r(Vector3(0.0, 1.418, 0.002), 0.08, 0.08, neck, scarf, {"g": 0.35}),
		_r(Vector3(0.0, 1.438, 0.004), 0.074, 0.075, neck, scarf, {"g": 0.35}),
		_r(Vector3(0.0, 1.452, 0.006), 0.061, 0.063, _w([B.NECK, 1.0]), scarf, {"ao": HeroMeshAtelier.UNDER_LIP_AO}),
	], {"subdiv": 2, "sides": 18})
	var knot: Vector3 = Vector3(0.014, 1.415, -0.086)
	HeroMeshAtelier._ellipsoid(s, knot, Vector3(0.021, 0.018, 0.015), neck, scarf, Vector3.FORWARD, {"g": 0.4})
	for tail: Array in [[shirt_point(1.37, -0.12, 0.012), shirt_point(1.31, -0.2, 0.014)], [shirt_point(1.375, 0.2, 0.012), shirt_point(1.325, 0.3, 0.013)]]:
		var mid: Vector3 = tail[0]
		var tip: Vector3 = tail[1]
		_loft(s, [
			_r(knot + Vector3(0.0, -0.01, -0.004), 0.017, 0.004, neck, scarf, {"ao": 0.7}),
			_r(mid, 0.016, 0.004, _w([B.CHEST, 1.0]), scarf),
			_r(tip, 0.003, 0.003, _w([B.CHEST, 1.0]), scarf, {"g": 0.6}),
		], {"sides": 6, "subdiv": 2, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT, "n": 3.0})
	return s.commit(&"mesh_pauldrons_tabard")


# --- Arms, hands, legs and boots ------------------------------------------------------------

static func _limbs() -> ArrayMesh:
	var s: HeroMeshAtelier.Sculpt = HeroMeshAtelier.Sculpt.new(true)
	for side: float in [-1.0, 1.0]:
		_arm(s, side)
		_hand(s, side)
		_leg(s, side)
		_boot(s, side)
	return s.commit(&"mesh_limbs_boots")


## The linen sleeve rolled up in a fat cuff above the elbow, and the bare, slim forearm.
static func _arm(s: HeroMeshAtelier.Sculpt, side: float) -> void:
	var clavicle: int = B.CLAVICLE_L if side < 0.0 else B.CLAVICLE_R
	var upper: int = B.UPPER_ARM_L if side < 0.0 else B.UPPER_ARM_R
	var fore: int = B.FOREARM_L if side < 0.0 else B.FOREARM_R
	var hand: int = B.HAND_L if side < 0.0 else B.HAND_R
	var shoulder: Vector3 = HeroRigBuilder.BONE_HEADS[upper]
	var elbow: Vector3 = HeroRigBuilder.BONE_HEADS[fore]
	var wrist: Vector3 = HeroRigBuilder.BONE_HEADS[hand]
	var linen: float = HeroMeshAtelier.MAT_LINEN
	var skin: float = HeroMeshAtelier.MAT_SKIN
	var crease_fn: Callable = func(theta: float, t: float, c: Color) -> Color:
		# The sleeve's soft creases, gathering toward the roll.
		return Color(c.r * (0.86 + 0.14 * cos(theta * 3.0 + t * 9.0)), c.g, c.b, c.a) if absf(c.b - linen) < 0.01 else c
	_loft(s, [
		_r(shoulder + Vector3(-0.016 * side, 0.032, 0.0), 0.062, 0.066, _w([clavicle, 0.4, upper, 0.6]), linen, {"ao": 0.8}),
		_r(shoulder.lerp(elbow, 0.15), 0.066, 0.068, _w([clavicle, 0.1, upper, 0.9]), linen),
		_r(shoulder.lerp(elbow, 0.45), 0.062, 0.063, _w([upper, 1.0]), linen),
		_r(shoulder.lerp(elbow, 0.68), 0.058, 0.059, _w([upper, 1.0]), linen),
		_r(shoulder.lerp(elbow, 0.78), 0.054, 0.055, _w([upper, 0.95, fore, 0.05]), linen, {"ao": 0.75}),
	], {"cap_start": true, "color_fn": crease_fn})
	# The rolled cuff: a fat roll of linen, its folded edge catching the light.
	_loft(s, [
		_r(shoulder.lerp(elbow, 0.74), 0.055, 0.056, _w([upper, 1.0]), linen, {"ao": HeroMeshAtelier.UNDER_LIP_AO}),
		_r(shoulder.lerp(elbow, 0.78), 0.068, 0.069, _w([upper, 1.0]), linen, {"g": 0.7}),
		_r(shoulder.lerp(elbow, 0.84), 0.07, 0.071, _w([upper, 0.95, fore, 0.05]), linen, {"g": 0.5}),
		_r(shoulder.lerp(elbow, 0.89), 0.06, 0.061, _w([upper, 0.9, fore, 0.1]), linen, {"ao": HeroMeshAtelier.UNDER_LIP_AO}),
	], {"subdiv": 2, "sides": 14})
	# The bare forearm, slim and young.
	_loft(s, [
		_r(shoulder.lerp(elbow, 0.82), 0.045, 0.046, _w([upper, 1.0]), skin, {"ao": 0.6}),
		_r(elbow, 0.042, 0.044, _w([upper, 0.5, fore, 0.5]), skin),
		_r(elbow.lerp(wrist, 0.22), 0.043, 0.041, _w([upper, 0.08, fore, 0.92]), skin),
		_r(elbow.lerp(wrist, 0.55), 0.039, 0.035, _w([fore, 1.0]), skin),
		_r(elbow.lerp(wrist, 0.88), 0.033, 0.029, _w([fore, 0.85, hand, 0.15]), skin),
		_r(wrist + Vector3(0.0, 0.004, 0.0), 0.031, 0.027, _w([fore, 0.5, hand, 0.5]), skin),
	], {"side": Vector3.FORWARD})


## A big, bare, capable hand (1.22x): the palm, a four-finger block with knuckle creases, and a thumb.
static func _hand(s: HeroMeshAtelier.Sculpt, side: float) -> void:
	var fore: int = B.FOREARM_L if side < 0.0 else B.FOREARM_R
	var hand: int = B.HAND_L if side < 0.0 else B.HAND_R
	var wrist: Vector3 = HeroRigBuilder.BONE_HEADS[hand]
	var down: Vector3 = HeroRigBuilder.rest_direction(hand)
	var on_hand: Dictionary = _w([hand, 1.0])
	var skin: float = HeroMeshAtelier.MAT_SKIN
	var before: Callable = s.warp
	var k: float = HeroAppearanceResource.YOUTH_EXTREMITY_SCALE
	s.warp = scale_about(wrist, Vector3(k, k, k))
	var knuckle_fn: Callable = func(theta: float, t: float, c: Color) -> Color:
		# Three shallow grooves between the fingers on the back and the palm, past the knuckles.
		if t < 0.62:
			return c
		var across: float = cos(theta)
		var groove: float = 1.0 - 0.35 * exp(-pow(sin(across * PI * 2.0) / 0.25, 2.0)) * absf(across)
		return Color(c.r * groove, c.g, c.b, c.a)
	_loft(s, [
		_r(wrist + down * 0.004, 0.03, 0.026, _w([fore, 0.3, hand, 0.7]), skin),
		_r(wrist + down * 0.03, 0.04, 0.023, on_hand, skin),
		_r(wrist + down * 0.058, 0.044, 0.021, on_hand, skin),
		_r(wrist + down * 0.08, 0.043, 0.02, on_hand, skin, {"g": 0.3}),
		_r(wrist + down * 0.1, 0.039, 0.018, on_hand, skin),
		_r(wrist + down * 0.12, 0.034, 0.016, on_hand, skin),
		_r(wrist + down * 0.133, 0.018, 0.012, on_hand, skin),
	], {"cap_end": true, "side": Vector3.FORWARD, "n": 2.4, "color_fn": knuckle_fn})
	# The thumb, out from the heel of the hand toward the front.
	_loft(s, [
		_r(wrist + down * 0.028 + Vector3(-side * 0.008, 0.0, -0.028), 0.016, 0.015, on_hand, skin),
		_r(wrist + down * 0.058 + Vector3(-side * 0.012, 0.0, -0.05), 0.014, 0.013, on_hand, skin),
		_r(wrist + down * 0.082 + Vector3(-side * 0.013, 0.0, -0.058), 0.009, 0.009, on_hand, skin),
	], {"sides": 8, "cap_end": true})
	s.warp = before


## Russet knee-breeches, full in the thigh and gathered into a cuff below the
## knee (a sage patch on the left knee), then a striped wool stocking.
static func _leg(s: HeroMeshAtelier.Sculpt, side: float) -> void:
	var thigh: int = B.THIGH_L if side < 0.0 else B.THIGH_R
	var shin: int = B.SHIN_L if side < 0.0 else B.SHIN_R
	var x: float = 0.104 * side
	var cloth: float = HeroMeshAtelier.MAT_BREECHES
	var drape_fn: Callable = func(theta: float, t: float, c: Color) -> Color:
		# Soft drape folds down the breeches, deepening toward the gathered cuff.
		return Color(c.r * (0.88 + 0.12 * sin(theta * 4.0 + t * 6.0) * smoothstep(0.3, 1.0, t)), c.g, c.b, c.a)
	_loft(s, [
		_r(Vector3(x * 0.95, 0.93, 0.004), 0.1, 0.101, _w([B.HIPS, 0.7, thigh, 0.3]), cloth, {"ao": 0.7}),
		_r(Vector3(x, 0.84, 0.0), 0.097, 0.097, _w([B.HIPS, 0.25, thigh, 0.75]), cloth),
		_r(Vector3(x, 0.72, -0.004), 0.088, 0.088, _w([thigh, 1.0]), cloth),
		_r(Vector3(x * 1.02, 0.61, -0.008), 0.079, 0.08, _w([thigh, 0.9, shin, 0.1]), cloth),
		_r(Vector3(x * 1.03, 0.52, -0.01), 0.075, 0.077, _w([thigh, 0.5, shin, 0.5]), cloth),
		_r(Vector3(x * 1.04, 0.475, -0.009), 0.08, 0.081, _w([thigh, 0.15, shin, 0.85]), cloth),
		_r(Vector3(x * 1.04, 0.448, -0.007), 0.066, 0.067, _w([shin, 1.0]), cloth, {"ao": 0.7}),
	], {"color_fn": drape_fn})
	# The rolled cuff below the knee.
	HeroMeshAtelier._band(s, Vector3(x * 1.04, 0.448, -0.007), Vector3.DOWN, 0.072, 0.073, 0.026, _w([shin, 1.0]), cloth)
	if side < 0.0:
		# The sage patch on the left knee, stitched square over a worn spot.
		var bones: Dictionary = _w([thigh, 0.5, shin, 0.5])
		var at: Vector3 = Vector3(x * 1.03, 0.53, -0.085)
		_loft(s, [
			_r(at + Vector3(0.0, 0.0, 0.006), 0.032, 0.036, bones, HeroMeshAtelier.MAT_TABARD, {"n": 5.0, "ao": HeroMeshAtelier.UNDER_LIP_AO}),
			_r(at - Vector3(0.0, 0.0, 0.002), 0.031, 0.035, bones, HeroMeshAtelier.MAT_TABARD, {"n": 5.0, "g": 0.35}),
		], {"subdiv": 1, "sides": 12, "cap_end": true, "side": Vector3.RIGHT})
	# The stocking: cream wool, ringed in the Fellowship's colour, into the boot.
	var stocking: float = HeroMeshAtelier.MAT_LINEN
	_loft(s, [
		_r(Vector3(x * 1.04, 0.455, -0.006), 0.054, 0.055, _w([shin, 1.0]), stocking),
		_r(Vector3(x * 1.05, 0.39, -0.002), 0.057, 0.058, _w([shin, 1.0]), stocking),
		_r(Vector3(x * 1.06, 0.31, 0.004), 0.049, 0.05, _w([shin, 1.0]), stocking),
		_r(Vector3(x * 1.07, 0.24, 0.01), 0.043, 0.045, _w([shin, 1.0]), stocking),
	], {"subdiv": 2})
	for y: float in [0.415, 0.38, 0.345]:
		var r: float = 0.058 - absf(y - 0.39) * 0.08
		HeroMeshAtelier._band(s, Vector3(x * 1.05, y, -0.002), Vector3.DOWN, r + 0.002, r + 0.003, 0.014, _w([shin, 1.0]), HeroMeshAtelier.MAT_TUNIC)


## A big turned-down soft-leather boot (1.22x round the sole): a round toe, a
## slouched shaft and a wide cuff folded down to show its paler lining.
static func _boot(s: HeroMeshAtelier.Sculpt, side: float) -> void:
	var shin: int = B.SHIN_L if side < 0.0 else B.SHIN_R
	var foot: int = B.FOOT_L if side < 0.0 else B.FOOT_R
	var x: float = 0.122 * side
	var on_foot: Dictionary = _w([foot, 1.0])
	var before: Callable = s.warp
	var k: float = HeroAppearanceResource.YOUTH_EXTREMITY_SCALE
	s.warp = scale_about(Vector3(x, 0.0, 0.03), Vector3(k, k, k))
	var boot: float = HeroMeshAtelier.MAT_BOOT
	var sole_fn: Callable = func(theta: float, _t: float, c: Color) -> Color:
		return Color(c.r * 0.5, c.g, c.b, c.a) if sin(theta) < -0.6 else c
	_loft(s, [
		_r(Vector3(x, 0.054, 0.068), 0.046, 0.044, _w([shin, 0.15, foot, 0.85]), boot, {"ao": 0.75}),
		_r(Vector3(x, 0.054, 0.028), 0.055, 0.05, on_foot, boot),
		_r(Vector3(x, 0.05, -0.038), 0.056, 0.044, on_foot, boot),
		_r(Vector3(x * 0.99, 0.048, -0.088), 0.053, 0.039, on_foot, boot, {"g": 0.4}),
		_r(Vector3(x * 0.98, 0.05, -0.122), 0.041, 0.031, on_foot, boot, {"g": 0.8}),
		_r(Vector3(x * 0.98, 0.054, -0.138), 0.017, 0.015, on_foot, boot, {"g": 0.9}),
	], {"n": 2.6, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT, "color_fn": sole_fn})
	# The slouched shaft, wrinkling at the ankle.
	var slouch_fn: Callable = func(theta: float, t: float, c: Color) -> Color:
		return Color(c.r * (0.85 + 0.15 * cos(theta * 2.0 + t * 14.0)), c.g, c.b, c.a)
	_loft(s, [
		_r(Vector3(x, 0.07, 0.03), 0.05, 0.054, _w([shin, 0.3, foot, 0.7]), boot),
		_r(Vector3(x, 0.11, 0.022), 0.05, 0.052, _w([shin, 0.75, foot, 0.25]), boot),
		_r(Vector3(x * 1.01, 0.17, 0.014), 0.049, 0.05, _w([shin, 1.0]), boot),
		_r(Vector3(x * 1.01, 0.225, 0.008), 0.05, 0.051, _w([shin, 1.0]), boot),
	], {"subdiv": 2, "color_fn": slouch_fn})
	# The wide cuff folded down over the shaft, its lighter lining out.
	_loft(s, [
		_r(Vector3(x * 1.01, 0.232, 0.008), 0.05, 0.051, _w([shin, 1.0]), HeroMeshAtelier.MAT_LEATHER, {"g": 0.7}),
		_r(Vector3(x * 1.01, 0.236, 0.008), 0.062, 0.063, _w([shin, 1.0]), HeroMeshAtelier.MAT_LEATHER, {"g": 0.9}),
		_r(Vector3(x * 1.01, 0.205, 0.01), 0.066, 0.067, _w([shin, 1.0]), HeroMeshAtelier.MAT_LEATHER),
		_r(Vector3(x * 1.01, 0.18, 0.012), 0.065, 0.066, _w([shin, 1.0]), HeroMeshAtelier.MAT_LEATHER, {"g": 0.5}),
		_r(Vector3(x * 1.01, 0.176, 0.012), 0.054, 0.055, _w([shin, 1.0]), HeroMeshAtelier.MAT_LEATHER, {"ao": HeroMeshAtelier.UNDER_LIP_AO}),
	], {"subdiv": 2, "sides": 16})
	s.warp = before


# --- Belt, hood and cape --------------------------------------------------------------------------

static func _belt_cape() -> ArrayMesh:
	var s: HeroMeshAtelier.Sculpt = HeroMeshAtelier.Sculpt.new(true)
	var hips: Dictionary = _w([B.HIPS, 1.0])
	# A plain leather belt over the waistband, a tin buckle and a small drawstring pouch at the right hip.
	_loft(s, [
		_r(Vector3(0.0, 0.952, 0.0), 0.166, 0.124, hips, HeroMeshAtelier.MAT_LEATHER, {"ao": HeroMeshAtelier.UNDER_LIP_AO}),
		_r(Vector3(0.0, 0.957, 0.0), 0.172, 0.13, hips, HeroMeshAtelier.MAT_LEATHER, {"g": 0.7}),
		_r(Vector3(0.0, 0.983, 0.0), 0.168, 0.128, hips, HeroMeshAtelier.MAT_LEATHER, {"g": 0.7}),
		_r(Vector3(0.0, 0.988, 0.0), 0.162, 0.122, hips, HeroMeshAtelier.MAT_LEATHER, {"ao": HeroMeshAtelier.UNDER_LIP_AO}),
	], {"subdiv": 1, "sides": 22, "n": 2.4})
	HeroMeshAtelier._buckle(s, Vector3(0.0, 0.97, -0.133), hips, Vector3.RIGHT)
	HeroMeshAtelier._ellipsoid(s, Vector3(0.13, 0.915, -0.08), Vector3(0.032, 0.04, 0.026), hips, HeroMeshAtelier.MAT_LEATHER, Vector3.DOWN, {"g": 0.4})
	HeroMeshAtelier._ellipsoid(s, Vector3(0.13, 0.952, -0.082), Vector3(0.02, 0.008, 0.017), hips, HeroMeshAtelier.MAT_ROPE, Vector3.UP)
	_hood_folds(s)
	_cape(s)
	return s.commit(&"mesh_belt_cloak")


## The hood, folded down round the shoulders: a thick roll of wool open at the throat.
static func _hood_folds(s: HeroMeshAtelier.Sculpt) -> void:
	var span: float = 2.25
	var arc_fn: Callable = func(theta: float, t: float, w: float, d: float) -> Vector2:
		var outer: bool = theta < PI
		var phi: float = lerpf(-span, span, theta / PI) if outer else lerpf(span, -span, (theta - PI) / PI)
		var thick: float = lerpf(0.016, 0.026, t)
		var rw: float = w + (thick if outer else -thick)
		var rd: float = d + (thick if outer else -thick)
		return Vector2(rw * sin(phi), rd * cos(phi))
	var chest: Dictionary = _w([B.CHEST, 1.0])
	_loft(s, [
		_r(Vector3(0.0, 1.315, 0.014), 0.198, 0.142, chest, HeroMeshAtelier.MAT_COAT, {"ao": HeroMeshAtelier.UNDER_LIP_AO}),
		_r(Vector3(0.0, 1.355, 0.014), 0.204, 0.142, chest, HeroMeshAtelier.MAT_COAT),
		_r(Vector3(0.0, 1.398, 0.024), 0.17, 0.128, chest, HeroMeshAtelier.MAT_COAT, {"g": 0.4}),
		_r(Vector3(0.0, 1.43, 0.04), 0.125, 0.112, _w([B.CHEST, 0.6, B.NECK, 0.4]), HeroMeshAtelier.MAT_COAT, {"g": 0.75}),
	], {"sides": 28, "subdiv": 2, "section": arc_fn, "proxy": 0.0})
	# The hood itself, lying folded on the upper back.
	HeroMeshAtelier._ellipsoid(s, Vector3(0.0, 1.355, 0.165), Vector3(0.105, 0.066, 0.038), chest, HeroMeshAtelier.MAT_COAT, Vector3.DOWN, {"g": 0.3})


## The short half-cape on Cloak_01..03: heather-blue wool lined in the patch's
## sage, from under the folded hood to the small of the back, its hem left raw in dags.
static func _cape(s: HeroMeshAtelier.Sculpt) -> void:
	var path: Array[Dictionary] = [
		_r(Vector3(0.0, 1.4, 0.118), 0.16, 0.0, _w([B.CHEST, 1.0]), HeroMeshAtelier.MAT_COAT),
		_r(Vector3(0.0, 1.34, 0.145), 0.178, 0.0, _w([B.CHEST, 0.3, B.CLOAK_01, 0.7]), HeroMeshAtelier.MAT_COAT),
		_r(Vector3(0.0, 1.22, 0.163), 0.19, 0.0, _w([B.CLOAK_01, 1.0]), HeroMeshAtelier.MAT_COAT),
		_r(Vector3(0.0, 1.1, 0.178), 0.2, 0.0, _w([B.CLOAK_01, 0.5, B.CLOAK_02, 0.5]), HeroMeshAtelier.MAT_COAT),
		_r(Vector3(0.0, CAPE_HEM, 0.19), 0.206, 0.0, _w([B.CLOAK_01, 0.2, B.CLOAK_02, 0.8]), HeroMeshAtelier.MAT_COAT, {"g": 0.5}),
	]
	var slab_fn: Callable = func(theta: float, _t: float, w: float, _d: float) -> Vector2:
		var arc_radius: float = 0.26
		var reach: float = w / arc_radius
		var thick: float = 0.01
		var outer: bool = theta < PI
		var phi: float = lerpf(-reach, reach, theta / PI) if outer else lerpf(reach, -reach, (theta - PI) / PI)
		var r: float = arc_radius + thick if outer else arc_radius - thick
		return Vector2(r * sin(phi), arc_radius - r * cos(phi))
	var lining_fn: Callable = func(theta: float, _t: float, c: Color) -> Color:
		return c if theta < PI else Color(c.r * 0.85, c.g, HeroMeshAtelier.MAT_TABARD, c.a)
	var hem_fn: Callable = func(theta: float, t: float, p: Vector3) -> Vector3:
		var hem_k: float = smoothstep(0.8, 1.0, t)
		if hem_k <= 0.0:
			return p
		var across: float = 1.0 - absf(1.0 - 2.0 * fmod(theta, PI) / PI)
		return p + Vector3(0.0, 0.028 * maxf(0.0, cos(across * PI * 5.0)) * hem_k, 0.0)
	_loft(s, path, {"sides": 24, "proxy": 0.0, "section": slab_fn, "color_fn": lining_fn, "offset_fn": hem_fn})
