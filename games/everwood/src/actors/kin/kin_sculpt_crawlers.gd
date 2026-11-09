## The six-legged kin (docs/30 §7.2), sculpted on KinRigBuilder's HEXAPOD
## skeleton: the Grey-Bark Weevil's domed bark wing-cases and long curved snout,
## the Barnacle Scuttler's crusted shell and two great claws, the Thorn-Tail's
## coat of thorns and the tail it carries curled over its back.
class_name KinSculptCrawlers
extends RefCounted



static func sculpt(s: HeroMeshAtelier.Sculpt, rig: KinRig, look: StringName) -> void:
	match look:
		KinLooks.WEEVIL:
			_weevil(s, rig)
		KinLooks.BARNACLE:
			_barnacle(s, rig)
		_:
			_thorn_tail(s, rig)


## Weights along the body by how far forward a point is: Abdomen, Body, Head.
static func _along(rig: KinRig, z: float) -> Dictionary:
	var abdomen: float = rig.heads[rig.b(&"Abdomen")].z
	var body: float = rig.heads[rig.b(&"Body")].z
	var head: float = rig.heads[rig.b(&"Head")].z
	if z >= abdomen:
		return KinSculptor.one(rig.b(&"Abdomen"))
	if z >= body:
		return KinSculptor.mix2(rig.b(&"Abdomen"), rig.b(&"Body"), inverse_lerp(abdomen, body, z))
	if z >= head:
		return KinSculptor.mix2(rig.b(&"Body"), rig.b(&"Head"), inverse_lerp(body, head, z))
	return KinSculptor.one(rig.b(&"Head"))


## The six legs: coxa, tibia and foot bones, from inside the body to a pointed or padded foot.
static func _legs(s: HeroMeshAtelier.Sculpt, rig: KinRig, radii: Array, m: float, foot_m: float, skip_front: bool = false) -> void:
	var body: int = rig.b(&"Body")
	for pair: int in [1, 2, 3]:
		if skip_front and pair == 1:
			continue
		for side: float in [-1.0, 1.0]:
			var tag: String = ("L%d" if side < 0.0 else "R%d") % pair
			var coxa: int = rig.b(StringName("Coxa_" + tag))
			var tibia: int = rig.b(StringName("Tibia_" + tag))
			var foot: int = rig.b(StringName("Foot_" + tag))
			var hip: Vector3 = rig.heads[coxa]
			var knee: Vector3 = rig.heads[tibia]
			var ankle: Vector3 = rig.heads[foot]
			var toe: Vector3 = rig.tail_of(foot)
			var inner: Vector3 = Vector3(hip.x * 0.4, hip.y + 0.02, hip.z)
			KinSculptor.tube(s, [inner, hip, hip.lerp(knee, 0.5), knee, knee.lerp(ankle, 0.5), ankle],
				[radii[0], radii[0], radii[0] * 0.95, radii[1], radii[1] * 0.9, radii[2]],
				[KinSculptor.one(body), KinSculptor.mix2(body, coxa, 0.6), KinSculptor.one(coxa), KinSculptor.mix2(coxa, tibia, 0.5), KinSculptor.one(tibia), KinSculptor.mix2(tibia, foot, 0.5)], m,
				{"sides": 8, "cap_start": false, "extra": {"g": 0.15}})
			KinSculptor.tube(s, [ankle, ankle.lerp(toe, 0.5), toe], [radii[2], float(radii[2]) * 0.8, float(radii[2]) * 0.35], [KinSculptor.one(foot)], foot_m,
				{"sides": 8, "cap_start": false, "tip_extra": {"g": 0.8}})


# --- The Grey-Bark Weevil ---------------------------------------------------------

static func _weevil(s: HeroMeshAtelier.Sculpt, rig: KinRig) -> void:
	var head: int = rig.b(&"Head")
	var snout: int = rig.b(&"Snout")
	var body: int = rig.b(&"Body")
	# The wing-cases: one domed bark shell, a seam down the middle, ridged plates either side.
	var shell: Array = [[0.48, 0.25, 0.06, 0.05], [0.43, 0.29, 0.17, 0.13], [0.3, 0.32, 0.22, 0.185], [0.14, 0.33, 0.225, 0.19],
		[0.02, 0.31, 0.18, 0.15], [-0.05, 0.29, 0.12, 0.1]]
	var rings: Array[Dictionary] = []
	for ring: Array in shell:
		rings.append(KinSculptor.r(Vector3(0.0, ring[1], ring[0]), ring[2], ring[3], _along(rig, ring[0]), KinSculptor.MAT_BARK, {"ao": 0.85 if ring == shell[0] else 1.0}))
	KinSculptor.loft(s, rings, {"sides": 18, "subdiv": 3, "cap_start": true, "cap_end": true})
	var seam: Array = []
	var seam_bones: Array = []
	for ring: Array in shell.slice(1, 5):
		seam.append(Vector3(0.0, float(ring[1]) + float(ring[3]) - 0.004, ring[0]))
		seam_bones.append(_along(rig, ring[0]))
	KinSculptor.tube(s, seam, [0.008, 0.009, 0.009, 0.008], seam_bones, KinSculptor.MAT_BARK, {"sides": 6, "extra": {"ao": 0.05}})
	for side: float in [-1.0, 1.0]:
		for lane: int in 3:
			var out: float = 0.35 + lane * 0.22
			var points: Array = []
			var bones: Array = []
			for ring: Array in shell.slice(1, 5):
				var angle: float = out * PI * 0.5
				points.append(Vector3(side * float(ring[2]) * sin(angle) * 0.98, float(ring[1]) + float(ring[3]) * cos(angle) * 0.98, ring[0]))
				bones.append(_along(rig, ring[0]))
			KinSculptor.tube(s, points, [0.014, 0.018, 0.018, 0.012], bones, KinSculptor.MAT_BARK, {"sides": 6, "flat": 0.6, "extra": {"g": 0.55}})
	# Lichen and a little moss in the bark's hollows.
	KinSculptor.ellipsoid(s, Vector3(0.07, 0.48, 0.2), Vector3(0.06, 0.02, 0.07), _along(rig, 0.2), KinSculptor.MAT_MOSS, Vector3.FORWARD)
	KinSculptor.ellipsoid(s, Vector3(-0.09, 0.45, 0.32), Vector3(0.045, 0.018, 0.05), _along(rig, 0.32), KinSculptor.MAT_MOSS, Vector3.FORWARD)
	# The thorax and head, the long curved snout with its little jaws at the end.
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.27, -0.08), Vector3(0.11, 0.095, 0.09), KinSculptor.one(body), KinSculptor.MAT_BARK)
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.295, -0.2), Vector3(0.09, 0.085, 0.09), KinSculptor.one(head), KinSculptor.MAT_BARK)
	KinSculptor.tube(s, [Vector3(0.0, 0.3, -0.25), Vector3(0.0, 0.295, -0.35), Vector3(0.0, 0.27, -0.46), Vector3(0.0, 0.21, -0.56), Vector3(0.0, 0.15, -0.63)],
		[0.058, 0.05, 0.043, 0.037, 0.034], [KinSculptor.one(head), KinSculptor.mix2(head, snout, 0.6), KinSculptor.one(snout)], KinSculptor.MAT_SHELL,
		{"sides": 10, "cap_start": false, "extra": {"a": 1.0}})
	for side: float in [-1.0, 1.0]:
		KinSculptor.cone(s, Vector3(side * 0.016, 0.14, -0.645), Vector3(side * 0.03, 0.105, -0.675), 0.016, KinSculptor.one(snout), KinSculptor.MAT_HORN, Vector3.ZERO, 5, 1.0)
		var antenna: int = rig.b(&"Antenna_L" if side < 0.0 else &"Antenna_R")
		var base: Vector3 = rig.heads[antenna]
		var tip: Vector3 = rig.tail_of(antenna)
		var elbow: Vector3 = base.lerp(tip, 0.4) + Vector3(side * 0.03, -0.03, 0.0)
		KinSculptor.tube(s, [base, elbow, tip], [0.014, 0.012, 0.01], [KinSculptor.mix2(snout, antenna, 0.5), KinSculptor.one(antenna)], KinSculptor.MAT_SHELL, {"sides": 6})
		KinSculptor.ellipsoid(s, tip, Vector3(0.024, 0.034, 0.024), KinSculptor.one(antenna), KinSculptor.MAT_SHELL, tip - elbow, {"g": 0.6})
		KinSculptor.eye(s, Vector3(side * 0.07, 0.32, -0.24), 0.04, Vector3(side * 1.0, 0.15, -0.6), KinSculptor.one(head), false)
		KinSculptor.brow(s, Vector3(side * 0.04, 0.362, -0.26), Vector3(side * 0.1, 0.355, -0.22), 0.014, KinSculptor.one(head), KinSculptor.MAT_BARK)
	_legs(s, rig, [0.044, 0.036, 0.028], KinSculptor.MAT_SHELL, KinSculptor.MAT_HORN)


# --- The Barnacle Scuttler ---------------------------------------------------------

static func _barnacle(s: HeroMeshAtelier.Sculpt, rig: KinRig) -> void:
	var body: int = rig.b(&"Body")
	var head: int = rig.b(&"Head")
	var shell: Array = [[0.31, 0.34, 0.18, 0.07], [0.22, 0.38, 0.37, 0.13], [0.04, 0.4, 0.44, 0.165], [-0.12, 0.39, 0.41, 0.15],
		[-0.23, 0.37, 0.31, 0.11], [-0.3, 0.36, 0.16, 0.07]]
	var rings: Array[Dictionary] = []
	for ring: Array in shell:
		rings.append(KinSculptor.r(Vector3(0.0, ring[1], ring[0]), ring[2], ring[3], _along(rig, ring[0]), KinSculptor.MAT_SHELL, {"n": 2.6}))
	KinSculptor.loft(s, rings, {"sides": 20, "subdiv": 3, "cap_start": true, "cap_end": true})
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.3, -0.02), Vector3(0.32, 0.07, 0.26), KinSculptor.one(body), KinSculptor.MAT_BELLY, Vector3.FORWARD)
	# A scalloped front rim.
	for index: int in 5:
		var x: float = (float(index) - 2.0) * 0.07
		var at: Vector3 = Vector3(x, 0.4, -0.29 + absf(x) * 0.45)
		KinSculptor.cone(s, at, at + Vector3(x * 0.25, 0.02, -0.06), 0.03, KinSculptor.one(head), KinSculptor.MAT_SHELL)
	# The barnacles: chalky cones with dark mouths, crowded on the shell's crown.
	var spots: Array = [Vector3(0.0, 0.0, 0.0), Vector3(0.14, 0.0, 0.06), Vector3(-0.13, 0.0, 0.1), Vector3(0.08, 0.0, -0.12), Vector3(-0.1, 0.0, -0.08),
		Vector3(0.22, 0.0, -0.04), Vector3(-0.22, 0.0, 0.02), Vector3(0.04, 0.0, 0.18), Vector3(-0.04, 0.0, -0.2)]
	for index: int in spots.size():
		var spot: Vector3 = spots[index]
		var lift: float = 0.4 + 0.165 * sqrt(maxf(0.0, 1.0 - pow(spot.x / 0.44, 2.0) - pow((spot.z - 0.04) / 0.3, 2.0)))
		var size: float = 0.034 + 0.016 * float((index * 7) % 3) / 2.0
		var base: Vector3 = Vector3(spot.x, lift - 0.01, spot.z)
		KinSculptor.tube(s, [base, base + Vector3.UP * size * 1.2, base + Vector3.UP * size * 1.05], [size, size * 0.62, size * 0.36], [_along(rig, spot.z)],
			KinSculptor.MAT_BARNACLE, {"sides": 8, "cap_start": false, "tip_extra": {"ao": 0.02}})
	# Kelp draped over the shell's edges.
	for side: float in [-1.0, 1.0]:
		KinSculptor.blade(s, Vector3(side * 0.2, 0.52, 0.08), Vector3(side * 0.46, 0.22, 0.16), 0.035, _along(rig, 0.1), KinSculptor.MAT_LEAF, Vector3.FORWARD, 0.006)
	# Eyes up on stalks.
	for side: float in [-1.0, 1.0]:
		var stalk: int = rig.b(&"Antenna_L" if side < 0.0 else &"Antenna_R")
		var base: Vector3 = rig.heads[stalk]
		var tip: Vector3 = rig.tail_of(stalk)
		KinSculptor.tube(s, [base + Vector3.DOWN * 0.03, base, tip], [0.02, 0.018, 0.016], [KinSculptor.mix2(head, stalk, 0.5), KinSculptor.one(stalk)], KinSculptor.MAT_SHELL, {"sides": 8, "cap_end": false})
		KinSculptor.eye(s, tip + Vector3.UP * 0.02, 0.04, Vector3(side * 0.35, 0.25, -1.0), KinSculptor.one(stalk), false, 0.9)
		# Mouthparts under the rim.
		KinSculptor.cone(s, Vector3(side * 0.035, 0.33, -0.3), Vector3(side * 0.02, 0.27, -0.34), 0.016, KinSculptor.one(head), KinSculptor.MAT_HORN)
	# The two great claws (the first pair), then four walking legs.
	for side: float in [-1.0, 1.0]:
		var tag: String = "L1" if side < 0.0 else "R1"
		var coxa: int = rig.b(StringName("Coxa_" + tag))
		var tibia: int = rig.b(StringName("Tibia_" + tag))
		var foot: int = rig.b(StringName("Foot_" + tag))
		var hip: Vector3 = rig.heads[coxa]
		var knee: Vector3 = rig.heads[tibia]
		var wrist: Vector3 = rig.heads[foot]
		var tip: Vector3 = rig.tail_of(foot)
		KinSculptor.tube(s, [Vector3(hip.x * 0.5, hip.y, hip.z), hip, knee, wrist], [0.05, 0.05, 0.048, 0.055],
			[KinSculptor.one(body), KinSculptor.mix2(body, coxa, 0.6), KinSculptor.mix2(coxa, tibia, 0.5), KinSculptor.mix2(tibia, foot, 0.5)], KinSculptor.MAT_SHELL, {"sides": 10, "cap_start": false})
		var dir: Vector3 = (tip - wrist).normalized()
		var palm: Vector3 = wrist.lerp(tip, 0.38)
		KinSculptor.ellipsoid(s, palm, Vector3(0.1, 0.08, 0.14), KinSculptor.one(foot), KinSculptor.MAT_SHELL, dir, {"g": 0.3, "a": 1.0})
		var across: Vector3 = Vector3.UP.cross(dir).normalized()
		KinSculptor.cone(s, palm + dir * 0.08 + Vector3.UP * 0.03, tip + dir * 0.04 + Vector3.UP * 0.04, 0.05, KinSculptor.one(foot), KinSculptor.MAT_SHELL, across * side * -0.025, 7, 1.0)
		KinSculptor.cone(s, palm + dir * 0.07 - Vector3.UP * 0.035, tip - Vector3.UP * 0.04, 0.042, KinSculptor.one(foot), KinSculptor.MAT_SHELL, across * side * -0.02, 7, 1.0)
	_legs(s, rig, [0.042, 0.035, 0.027], KinSculptor.MAT_SHELL, KinSculptor.MAT_HORN, true)


# --- The Thorn-Tail Hedgerow-Hob ----------------------------------------------------

static func _thorn_tail(s: HeroMeshAtelier.Sculpt, rig: KinRig) -> void:
	var head: int = rig.b(&"Head")
	var snout: int = rig.b(&"Snout")
	var t1: int = rig.b(&"Tail_1")
	var t2: int = rig.b(&"Tail_2")
	var body: Array = [[0.33, 0.3, 0.09, 0.08], [0.22, 0.34, 0.23, 0.2], [0.02, 0.36, 0.27, 0.23], [-0.15, 0.34, 0.22, 0.19], [-0.25, 0.31, 0.13, 0.12]]
	var rings: Array[Dictionary] = []
	for ring: Array in body:
		rings.append(KinSculptor.r(Vector3(0.0, ring[1], ring[0]), ring[2], ring[3], _along(rig, ring[0]), KinSculptor.MAT_FUR))
	KinSculptor.loft(s, rings, {"sides": 16, "subdiv": 3, "cap_start": true, "cap_end": true})
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.22, 0.0), Vector3(0.2, 0.08, 0.24), KinSculptor.one(rig.b(&"Body")), KinSculptor.MAT_FUR_ACCENT)
	# A coat of thorns, swept back.
	for index: int in 26:
		var u: float = fmod(float(index) * 0.618, 1.0)
		var v: float = float(index) / 25.0
		var z: float = lerpf(0.26, -0.12, v)
		var angle: float = lerpf(-1.25, 1.25, u)
		var radius_x: float = 0.25 * sqrt(maxf(0.0, 1.0 - pow((z - 0.04) / 0.32, 2.0)))
		var base: Vector3 = Vector3(sin(angle) * radius_x, 0.35 + cos(angle) * radius_x * 0.85, z)
		var out: Vector3 = Vector3(sin(angle) * 0.8, cos(angle) * 0.9 + 0.2, 0.7).normalized()
		KinSculptor.cone(s, base, base + out * 0.13, 0.018, _along(rig, z), KinSculptor.MAT_THORN)
	# A pale little face, a button nose, round ears.
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.3, -0.27), Vector3(0.11, 0.1, 0.09), KinSculptor.one(head), KinSculptor.MAT_FUR_ACCENT)
	KinSculptor.tube(s, [Vector3(0.0, 0.29, -0.31), Vector3(0.0, 0.265, -0.4), Vector3(0.0, 0.25, -0.45)], [0.065, 0.042, 0.03], [KinSculptor.one(head), KinSculptor.one(snout)],
		KinSculptor.MAT_FUR_ACCENT, {"sides": 10, "cap_start": false})
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.252, -0.465), Vector3(0.022, 0.018, 0.016), KinSculptor.one(snout), KinSculptor.MAT_HIDE, Vector3.FORWARD, {"ao": 0.05, "g": 0.6})
	for side: float in [-1.0, 1.0]:
		KinSculptor.eye(s, Vector3(side * 0.055, 0.33, -0.325), 0.034, Vector3(side * 0.55, 0.15, -1.0), KinSculptor.one(head), false)
		KinSculptor.brow(s, Vector3(side * 0.03, 0.37, -0.33), Vector3(side * 0.085, 0.365, -0.3), 0.012, KinSculptor.one(head), KinSculptor.MAT_FUR)
		var ear: int = rig.b(&"Antenna_L" if side < 0.0 else &"Antenna_R")
		KinSculptor.ellipsoid(s, rig.heads[ear].lerp(rig.tail_of(ear), 0.4), Vector3(0.035, 0.04, 0.015), KinSculptor.one(ear), KinSculptor.MAT_FUR, Vector3.UP)
	# The thorny tail curled over its back, a white hedge-flower at its tip.
	var tail: Array = [Vector3(0.0, 0.36, 0.26), rig.heads[t1], rig.heads[t1].lerp(rig.heads[t2], 0.5) + Vector3(0.0, 0.0, 0.05), rig.heads[t2],
		rig.heads[t2].lerp(rig.tail_of(t2), 0.5) + Vector3(0.0, 0.04, 0.0), rig.tail_of(t2)]
	KinSculptor.tube(s, tail, [0.06, 0.055, 0.048, 0.04, 0.032, 0.018], [_along(rig, 0.26), KinSculptor.one(t1), KinSculptor.mix2(t1, t2, 0.5), KinSculptor.one(t2), KinSculptor.one(t2), KinSculptor.one(t2)],
		KinSculptor.MAT_FUR, {"sides": 10, "cap_start": false, "extra": {"a": 1.0}})
	for index: int in 6:
		var u: float = (float(index) + 0.5) / 6.0
		var at: Vector3 = (tail[mini(int(u * 5.0), 4)] as Vector3).lerp(tail[mini(int(u * 5.0) + 1, 5)], fmod(u * 5.0, 1.0))
		var out: Vector3 = Vector3(0.6 if index % 2 == 0 else -0.6, 0.5, 0.6).normalized()
		KinSculptor.cone(s, at, at + out * 0.08, 0.014, KinSculptor.one(t1 if u < 0.4 else t2), KinSculptor.MAT_THORN, Vector3.ZERO, 6, 1.0)
	KinSculptor.rose(s, rig.tail_of(t2) + Vector3(0.0, 0.0, -0.02), 0.045, Vector3(0.0, 0.3, -1.0), KinSculptor.one(t2))
	_legs(s, rig, [0.038, 0.032, 0.026], KinSculptor.MAT_HIDE, KinSculptor.MAT_HIDE)
