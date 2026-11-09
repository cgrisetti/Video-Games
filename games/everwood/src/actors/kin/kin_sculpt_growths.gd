## The kin that grow (docs/30 §7.4): stalks on KinRigBuilder's STALK skeleton
## (the Root-Lurker, a knotted root reared out of the wall; the Bramble-Lasher, a
## bundle of canes under a great wild rose) and mounds on its BLOB skeleton (the
## Sap-Boggart, a slumped heap of grey sap with an amber heart; the Spore-Puff
## Lob, a mushroom-lob under a spotted puffball).
class_name KinSculptGrowths
extends RefCounted



static func sculpt(s: HeroMeshAtelier.Sculpt, rig: KinRig, look: StringName) -> void:
	match look:
		KinLooks.ROOT_LURKER:
			_root_lurker(s, rig)
		KinLooks.BRAMBLE_LASHER:
			_bramble_lasher(s, rig)
		KinLooks.SAP_BOGGART:
			_sap_boggart(s, rig)
		_:
			_spore_lob(s, rig)


## The stalk's points base to head and each one's bone.
static func _stalk_path(rig: KinRig) -> Array:
	var points: Array = [rig.heads[rig.b(&"Base")]]
	var bones: Array = [KinSculptor.one(rig.b(&"Base"))]
	for index: int in 5:
		var bone: int = rig.b(StringName("Stalk_%d" % (index + 1)))
		points.append(rig.heads[bone])
		bones.append(KinSculptor.one(bone))
	points.append(rig.heads[rig.b(&"Head")])
	bones.append(KinSculptor.one(rig.b(&"Head")))
	return [points, bones]


## A whip on `side`: root, middle and tip, `radii` along it, its outer half carrying the Sign.
static func _whip(s: HeroMeshAtelier.Sculpt, rig: KinRig, side: float, radii: Array, m: float, thorns: bool) -> void:
	var tag: String = "L" if side < 0.0 else "R"
	var one: int = rig.b(StringName("Whip_%s1" % tag))
	var two: int = rig.b(StringName("Whip_%s2" % tag))
	var parent: int = rig.parents[one]
	var root: Vector3 = rig.heads[one]
	var mid: Vector3 = rig.heads[two]
	var tip: Vector3 = rig.tail_of(two)
	var points: Array = [root + Vector3(-side * 0.06, 0.0, 0.0), root, root.lerp(mid, 0.5) + Vector3.UP * 0.04, mid, mid.lerp(tip, 0.5), tip]
	KinSculptor.tube(s, points, radii, [KinSculptor.mix2(parent, one, 0.4), KinSculptor.one(one), KinSculptor.one(one), KinSculptor.mix2(one, two, 0.5), KinSculptor.one(two), KinSculptor.one(two)], m,
		{"sides": 8, "cap_start": false, "color_fn": func(_theta: float, t: float, c: Color) -> Color: return Color(c.r, c.g, c.b, smoothstep(0.35, 0.6, t))})
	if thorns:
		for index: int in 5:
			var u: float = 0.2 + float(index) * 0.16
			var at: Vector3 = mid.lerp(tip, (u - 0.5) * 2.0) if u > 0.5 else root.lerp(mid, u * 2.0)
			var out: Vector3 = Vector3(side * 0.3, 1.0 if index % 2 == 0 else -0.6, 0.4).normalized()
			KinSculptor.cone(s, at, at + out * 0.06, 0.012, KinSculptor.one(two if u > 0.5 else one), KinSculptor.MAT_THORN, Vector3.ZERO, 5, 1.0)


# --- The Root-Lurker ------------------------------------------------------------------

static func _root_lurker(s: HeroMeshAtelier.Sculpt, rig: KinRig) -> void:
	var path: Array = _stalk_path(rig)
	var points: Array = path[0]
	var head: int = rig.b(&"Head")
	KinSculptor.tube(s, points, [0.28, 0.24, 0.21, 0.19, 0.18, 0.17, 0.18], path[1], KinSculptor.MAT_BARK,
		{"sides": 14, "cap_start": false, "cap_end": false, "radius_fn": func(theta: float, t: float) -> float:
			return 1.0 + 0.1 * sin(theta * 3.0 + t * 11.0) + 0.08 * smoothstep(0.42, 0.5, t) * (1.0 - smoothstep(0.5, 0.58, t))})
	# Knots along the root, moss in its hollows.
	for index: int in [1, 3, 4]:
		var at: Vector3 = (points[index] as Vector3) + Vector3(0.12 if index % 2 == 0 else -0.12, 0.0, -0.06)
		KinSculptor.ellipsoid(s, at, Vector3(0.07, 0.06, 0.07), path[1][index], KinSculptor.MAT_BARK, at - (points[index] as Vector3), {"g": 0.5})
	KinSculptor.ellipsoid(s, (points[2] as Vector3) + Vector3(-0.1, 0.0, 0.1), Vector3(0.09, 0.07, 0.06), path[1][2], KinSculptor.MAT_MOSS)
	# Roots spreading over the ground from its foot.
	for index: int in 6:
		var angle: float = TAU * float(index) / 6.0 + 0.3
		var out: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		KinSculptor.tube(s, [Vector3(0.0, 0.18, 0.0) + out * 0.1, out * 0.32 + Vector3.UP * 0.06, out * 0.6 + Vector3.UP * 0.02, out * 0.82],
			[0.09, 0.06, 0.035, 0.008], [KinSculptor.one(rig.b(&"Base"))], KinSculptor.MAT_BARK, {"sides": 7, "cap_start": false})
	# The head: a great knot with a bark brow, two glowing eyes and a crack of a mouth.
	var at: Vector3 = rig.heads[head] + Vector3(0.0, 0.08, -0.03)
	KinSculptor.ellipsoid(s, at, Vector3(0.25, 0.25, 0.23), KinSculptor.one(head), KinSculptor.MAT_BARK, Vector3.UP, {}, {"sides": 12})
	KinSculptor.ellipsoid(s, at + Vector3(0.0, 0.21, 0.03), Vector3(0.15, 0.07, 0.13), KinSculptor.one(head), KinSculptor.MAT_MOSS)
	for side: float in [-1.0, 1.0]:
		KinSculptor.eye(s, at + Vector3(side * 0.09, 0.04, -0.21), 0.046, Vector3(side * 0.35, 0.05, -1.0), KinSculptor.one(head), true, 0.5)
		KinSculptor.brow(s, at + Vector3(side * 0.03, 0.11, -0.235), at + Vector3(side * 0.19, 0.095, -0.17), 0.042, KinSculptor.one(head), KinSculptor.MAT_BARK)
		KinSculptor.blade(s, at + Vector3(side * 0.06, 0.24, 0.0), at + Vector3(side * 0.24, 0.4, 0.08), 0.08, KinSculptor.one(head), KinSculptor.MAT_LEAF, Vector3.FORWARD, 0.008)
	KinSculptor.tube(s, [at + Vector3(-0.1, -0.09, -0.205), at + Vector3(0.0, -0.115, -0.228), at + Vector3(0.1, -0.09, -0.205)], [0.014, 0.016, 0.014],
		[KinSculptor.one(head)], KinSculptor.MAT_BARK, {"sides": 6, "extra": {"ao": 0.0, "a": 1.0}})
	for side: float in [-1.0, 1.0]:
		_whip(s, rig, side, [0.07, 0.07, 0.06, 0.048, 0.032, 0.008], KinSculptor.MAT_BARK, false)


# --- The Bramble-Lasher Hob ------------------------------------------------------------

static func _bramble_lasher(s: HeroMeshAtelier.Sculpt, rig: KinRig) -> void:
	var path: Array = _stalk_path(rig)
	var points: Array = path[0]
	var head: int = rig.b(&"Head")
	# Three canes twisted up together, thorned, leafing.
	for cane: int in 3:
		var twisted: Array = []
		for index: int in points.size():
			var angle: float = TAU * float(cane) / 3.0 + float(index) * 0.9
			twisted.append((points[index] as Vector3) + Vector3(cos(angle), 0.0, sin(angle)) * 0.07)
		KinSculptor.tube(s, twisted, [0.06, 0.055, 0.05, 0.045, 0.042, 0.04, 0.035], path[1], KinSculptor.MAT_THORN, {"sides": 8, "cap_start": false})
		for index: int in [1, 2, 3, 4, 5]:
			var at: Vector3 = twisted[index]
			var out: Vector3 = (at - (points[index] as Vector3)).normalized() + Vector3.UP * 0.4
			KinSculptor.cone(s, at, at + out.normalized() * 0.07, 0.014, path[1][index], KinSculptor.MAT_THORN)
	for index: int in 6:
		var at: Vector3 = points[1 + index % 5]
		var out: Vector3 = Vector3(cos(index * 2.3), 0.25, sin(index * 2.3)).normalized()
		KinSculptor.blade(s, at + out * 0.06, at + out * 0.3 + Vector3.UP * 0.05, 0.07, path[1][1 + index % 5], KinSculptor.MAT_LEAF, Vector3.UP, 0.008)
	# Roots in a tangle at its foot.
	for index: int in 5:
		var angle: float = TAU * float(index) / 5.0
		var out: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		KinSculptor.tube(s, [Vector3(0.0, 0.14, 0.0), out * 0.25 + Vector3.UP * 0.05, out * 0.5], [0.06, 0.035, 0.008], [KinSculptor.one(rig.b(&"Base"))], KinSculptor.MAT_THORN,
			{"sides": 6, "cap_start": false})
	# The bloom: a great wild rose turned to the heroes, one golden eye in its heart.
	var bloom: Vector3 = rig.heads[head] + Vector3(0.0, 0.12, -0.06)
	KinSculptor.ellipsoid(s, bloom + Vector3(0.0, 0.0, 0.06), Vector3(0.14, 0.14, 0.1), KinSculptor.one(head), KinSculptor.MAT_LEAF, Vector3.FORWARD)
	KinSculptor.rose(s, bloom, 0.32, Vector3(0.0, 0.15, -1.0), KinSculptor.one(head), 7)
	KinSculptor.rose(s, bloom + Vector3(0.0, 0.0, -0.04), 0.2, Vector3(0.0, 0.15, -1.0), KinSculptor.one(head), 5)
	KinSculptor.eye(s, bloom + Vector3(0.0, 0.01, -0.1), 0.07, Vector3(0.0, 0.1, -1.0), KinSculptor.one(head), true, 0.55)
	for side: float in [-1.0, 1.0]:
		_whip(s, rig, side, [0.05, 0.05, 0.044, 0.036, 0.026, 0.006], KinSculptor.MAT_THORN, true)


# --- The Sap-Boggart -------------------------------------------------------------------

static func _sap_boggart(s: HeroMeshAtelier.Sculpt, rig: KinRig) -> void:
	var base: int = rig.b(&"Base")
	var belly: int = rig.b(&"Belly")
	var crown: int = rig.b(&"Crown")
	var cap: int = rig.b(&"Cap")
	KinSculptor.loft(s, [
		KinSculptor.r(Vector3(0.0, 0.1, 0.0), 0.42, 0.4, KinSculptor.one(base), KinSculptor.MAT_SAP, {"ao": 0.6}),
		KinSculptor.r(Vector3(0.0, 0.22, 0.0), 0.52, 0.48, KinSculptor.one(base), KinSculptor.MAT_SAP),
		KinSculptor.r(Vector3(0.0, 0.52, -0.02), 0.5, 0.46, KinSculptor.mix2(base, belly, 0.8), KinSculptor.MAT_SAP),
		KinSculptor.r(Vector3(0.0, 0.84, -0.03), 0.42, 0.38, KinSculptor.mix2(belly, crown, 0.5), KinSculptor.MAT_SAP),
		KinSculptor.r(Vector3(0.0, 1.1, -0.03), 0.32, 0.3, KinSculptor.one(crown), KinSculptor.MAT_SAP),
		KinSculptor.r(Vector3(0.0, 1.3, -0.04), 0.2, 0.19, KinSculptor.mix2(crown, cap, 0.6), KinSculptor.MAT_SAP),
		KinSculptor.r(Vector3(0.0, 1.42, -0.04), 0.08, 0.08, KinSculptor.one(cap), KinSculptor.MAT_SAP),
	], {"sides": 18, "subdiv": 3, "cap_start": true, "cap_end": true, "radius_fn": func(theta: float, t: float) -> float:
		return 1.0 + 0.06 * sin(theta * 3.0 + t * 7.0) + 0.04 * sin(theta * 5.0 - t * 4.0)})
	# What it has swallowed: twigs, leaves, a pebble.
	for twig: Array in [[Vector3(0.08, 1.32, 0.0), Vector3(0.22, 1.62, 0.06)], [Vector3(-0.1, 1.28, -0.02), Vector3(-0.2, 1.52, -0.1)],
			[Vector3(0.0, 1.38, 0.06), Vector3(0.02, 1.7, 0.14)]]:
		KinSculptor.cone(s, twig[0], twig[1], 0.025, KinSculptor.one(cap), KinSculptor.MAT_BARK, Vector3(0.02, 0.0, 0.0))
	KinSculptor.blade(s, Vector3(0.2, 1.62, 0.06), Vector3(0.32, 1.7, 0.02), 0.04, KinSculptor.one(cap), KinSculptor.MAT_LEAF, Vector3.UP, 0.006)
	KinSculptor.blade(s, Vector3(-0.3, 0.6, -0.36), Vector3(-0.42, 0.5, -0.38), 0.05, KinSculptor.one(belly), KinSculptor.MAT_LEAF, Vector3.FORWARD, 0.006)
	KinSculptor.ellipsoid(s, Vector3(0.28, 0.32, -0.42), Vector3(0.06, 0.05, 0.05), KinSculptor.one(base), KinSculptor.MAT_STONE)
	# Amber eyes under a heavy brow of sap; a slow, sad droop of a mouth.
	for side: float in [-1.0, 1.0]:
		KinSculptor.eye(s, Vector3(side * 0.12, 1.06, -0.315), 0.066, Vector3(side * 0.3, 0.05, -1.0), KinSculptor.one(crown), true, 0.5)
		KinSculptor.brow(s, Vector3(side * 0.04, 1.15, -0.315), Vector3(side * 0.22, 1.14, -0.25), 0.045, KinSculptor.one(crown), KinSculptor.MAT_SAP)
	KinSculptor.tube(s, [Vector3(-0.1, 0.9, -0.385), Vector3(0.0, 0.925, -0.41), Vector3(0.1, 0.9, -0.385)], [0.014, 0.016, 0.014], [KinSculptor.one(crown)], KinSculptor.MAT_SAP,
		{"sides": 6, "extra": {"ao": 0.05}})
	# Stubby arms ending in soft mitts that drip; stubby feet.
	for side: float in [-1.0, 1.0]:
		var tag: String = "L" if side < 0.0 else "R"
		var one: int = rig.b(StringName("Arm_%s1" % tag))
		var two: int = rig.b(StringName("Arm_%s2" % tag))
		var shoulder: Vector3 = rig.heads[one]
		var elbow: Vector3 = rig.heads[two]
		var hand: Vector3 = rig.tail_of(two)
		KinSculptor.tube(s, [shoulder + Vector3(-side * 0.12, 0.02, 0.02), shoulder, elbow, hand], [0.15, 0.14, 0.12, 0.11],
			[KinSculptor.mix2(belly, one, 0.5), KinSculptor.one(one), KinSculptor.mix2(one, two, 0.5), KinSculptor.one(two)], KinSculptor.MAT_SAP, {"sides": 12, "cap_start": false,
				"extra": {"a": 1.0 if side > 0.0 else 0.0}})
		KinSculptor.cone(s, hand + Vector3.DOWN * 0.06, hand + Vector3(0.0, -0.24, -0.02), 0.035, KinSculptor.one(two), KinSculptor.MAT_SAP)
		var foot: int = rig.b(StringName("Foot_" + tag))
		KinSculptor.ellipsoid(s, rig.heads[foot].lerp(rig.tail_of(foot), 0.6), Vector3(0.11, 0.07, 0.15), KinSculptor.one(foot), KinSculptor.MAT_SAP, Vector3.FORWARD)
	# Drips down its front.
	var drip_1: int = rig.b(&"Drip_1")
	var drip_2: int = rig.b(&"Drip_2")
	var top: Vector3 = rig.heads[drip_1]
	var tip: Vector3 = rig.tail_of(drip_2)
	KinSculptor.tube(s, [top + Vector3(0.0, 0.06, 0.06), top, rig.heads[drip_2], tip], [0.06, 0.05, 0.035, 0.02], [KinSculptor.one(belly), KinSculptor.one(drip_1), KinSculptor.one(drip_2), KinSculptor.one(drip_2)],
		KinSculptor.MAT_SAP, {"sides": 10, "cap_start": false})
	KinSculptor.ellipsoid(s, tip + Vector3.DOWN * 0.03, Vector3(0.035, 0.05, 0.035), KinSculptor.one(drip_2), KinSculptor.MAT_SAP, Vector3.UP)


# --- The Spore-Puff Lob ---------------------------------------------------------------

static func _spore_lob(s: HeroMeshAtelier.Sculpt, rig: KinRig) -> void:
	var base: int = rig.b(&"Base")
	var belly: int = rig.b(&"Belly")
	var crown: int = rig.b(&"Crown")
	var cap: int = rig.b(&"Cap")
	KinSculptor.loft(s, [
		KinSculptor.r(Vector3(0.0, 0.08, 0.0), 0.28, 0.28, KinSculptor.one(base), KinSculptor.MAT_BELLY, {"ao": 0.6}),
		KinSculptor.r(Vector3(0.0, 0.25, 0.0), 0.31, 0.3, KinSculptor.one(base), KinSculptor.MAT_BELLY),
		KinSculptor.r(Vector3(0.0, 0.58, 0.0), 0.29, 0.28, KinSculptor.one(belly), KinSculptor.MAT_BELLY),
		KinSculptor.r(Vector3(0.0, 0.9, 0.0), 0.25, 0.24, KinSculptor.one(crown), KinSculptor.MAT_BELLY),
		KinSculptor.r(Vector3(0.0, 1.06, 0.0), 0.21, 0.2, KinSculptor.one(crown), KinSculptor.MAT_BELLY, {"ao": 0.5}),
	], {"sides": 16, "subdiv": 2, "cap_start": true, "cap_end": false})
	# The puffball cap: dark gills under it, pale spots on it; it carries the blow's Sign.
	KinSculptor.loft(s, [
		KinSculptor.r(Vector3(0.0, 1.0, 0.0), 0.2, 0.2, KinSculptor.one(cap), KinSculptor.MAT_HIDE, {"ao": 0.15}),
		KinSculptor.r(Vector3(0.0, 1.06, 0.0), 0.5, 0.5, KinSculptor.one(cap), KinSculptor.MAT_HIDE, {"ao": 0.3}),
		KinSculptor.r(Vector3(0.0, 1.1, 0.0), 0.56, 0.56, KinSculptor.one(cap), KinSculptor.MAT_SHELL, {"g": 0.6, "a": 1.0}),
		KinSculptor.r(Vector3(0.0, 1.28, 0.0), 0.56, 0.56, KinSculptor.one(cap), KinSculptor.MAT_SHELL, {"a": 1.0}),
		KinSculptor.r(Vector3(0.0, 1.44, 0.0), 0.44, 0.44, KinSculptor.one(cap), KinSculptor.MAT_SHELL, {"a": 1.0}),
		KinSculptor.r(Vector3(0.0, 1.54, 0.0), 0.2, 0.2, KinSculptor.one(cap), KinSculptor.MAT_SHELL, {"a": 1.0}),
		KinSculptor.r(Vector3(0.0, 1.57, 0.0), 0.04, 0.04, KinSculptor.one(cap), KinSculptor.MAT_SHELL, {"a": 1.0}),
	], {"sides": 20, "subdiv": 2, "cap_start": true, "cap_end": true})
	for index: int in 9:
		var angle: float = float(index) * 2.4
		var lift: float = 0.2 + float(index % 3) * 0.22
		var at: Vector3 = Vector3(cos(angle) * 0.56 * cos(lift), 1.3 + sin(lift) * 0.26, sin(angle) * 0.56 * cos(lift))
		KinSculptor.ellipsoid(s, at, Vector3(0.06, 0.02, 0.06), KinSculptor.one(cap), KinSculptor.MAT_BELLY, at - Vector3(0.0, 1.2, 0.0))
	# A round little face on the stalk.
	for side: float in [-1.0, 1.0]:
		KinSculptor.eye(s, Vector3(side * 0.09, 0.86, -0.236), 0.055, Vector3(side * 0.35, 0.05, -1.0), KinSculptor.one(crown), false)
		KinSculptor.brow(s, Vector3(side * 0.04, 0.92, -0.235), Vector3(side * 0.13, 0.915, -0.2), 0.014, KinSculptor.one(crown), KinSculptor.MAT_HIDE)
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.8, -0.255), Vector3(0.03, 0.025, 0.02), KinSculptor.one(crown), KinSculptor.MAT_BELLY, Vector3.FORWARD, {"g": 0.5})
	KinSculptor.tube(s, [Vector3(-0.05, 0.74, -0.24), Vector3(0.0, 0.728, -0.25), Vector3(0.05, 0.74, -0.24)], [0.008, 0.009, 0.008], [KinSculptor.one(crown)], KinSculptor.MAT_HIDE,
		{"sides": 5, "extra": {"ao": 0.0}})
	for side: float in [-1.0, 1.0]:
		var tag: String = "L" if side < 0.0 else "R"
		var one: int = rig.b(StringName("Arm_%s1" % tag))
		var two: int = rig.b(StringName("Arm_%s2" % tag))
		KinSculptor.tube(s, [rig.heads[one] + Vector3(-side * 0.08, 0.0, 0.0), rig.heads[one], rig.heads[two], rig.tail_of(two)], [0.08, 0.075, 0.065, 0.06],
			[KinSculptor.mix2(belly, one, 0.5), KinSculptor.one(one), KinSculptor.mix2(one, two, 0.5), KinSculptor.one(two)], KinSculptor.MAT_BELLY, {"sides": 10, "cap_start": false})
		var foot: int = rig.b(StringName("Foot_" + tag))
		KinSculptor.ellipsoid(s, rig.heads[foot].lerp(rig.tail_of(foot), 0.6), Vector3(0.09, 0.06, 0.12), KinSculptor.one(foot), KinSculptor.MAT_BELLY, Vector3.FORWARD)
