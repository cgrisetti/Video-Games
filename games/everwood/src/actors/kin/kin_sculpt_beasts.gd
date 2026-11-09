## The four-legged kin (docs/30 §7.1), sculpted on KinRigBuilder's QUADRUPED
## skeleton at their own size: one continuous body lofted rump to head, legs
## that bend at shoulder, elbow, hip, knee and hock, big readable paws and
## heads, and the one thing each is made of: the Bramble-Hound's hackles of
## bramble and dog-rose, the Padfoot's ruff, the Bristle-Hob's crest and tusks,
## the Puddle-Bucca's lily-leaf cap, the Taproot Stag's root antlers and moss
## mantle, the Cairn-Drake's crag shell and bell.
class_name KinSculptBeasts
extends RefCounted



static func sculpt(s: HeroMeshAtelier.Sculpt, rig: KinRig, look: StringName) -> void:
	match look:
		KinLooks.HOUND:
			_canine(s, rig, false)
		KinLooks.BRISTLE_HOB:
			_boar(s, rig)
		KinLooks.PUDDLE_BUCCA:
			_toad(s, rig)
		KinLooks.TAPROOT_STAG:
			_stag(s, rig)
		KinLooks.CAIRN_DRAKE:
			_drake(s, rig)
		_:
			_canine(s, rig, true)


# --- Shared parts ---------------------------------------------------------------

## The body's rings rump to head: each [centre, half-width, half-depth, bone weights, material].
static func _body(s: HeroMeshAtelier.Sculpt, rings: Array, sides: int = 16) -> void:
	var made: Array[Dictionary] = []
	for index: int in rings.size():
		var ring: Array = rings[index]
		var extra: Dictionary = {"ao": 0.8 if index == 0 or index == rings.size() - 1 else 1.0}
		if ring.size() > 5:
			extra.merge(ring[5], true)
		made.append(KinSculptor.r(ring[0], ring[1], ring[2], ring[3], ring[4], extra))
	KinSculptor.loft(s, made, {"sides": sides, "subdiv": 3, "cap_start": true, "cap_end": true})


## Weights along the back by how far forward a point is: Hips, Spine, Chest, Neck.
static func _back(rig: KinRig, z: float) -> Dictionary:
	var hips: float = rig.heads[rig.b(&"Hips")].z
	var spine: float = rig.heads[rig.b(&"Spine")].z
	var chest: float = rig.heads[rig.b(&"Chest")].z
	var neck: float = rig.heads[rig.b(&"Neck")].z
	if z >= hips:
		return KinSculptor.one(rig.b(&"Hips"))
	if z >= spine:
		return KinSculptor.mix2(rig.b(&"Hips"), rig.b(&"Spine"), inverse_lerp(hips, spine, z))
	if z >= chest:
		return KinSculptor.mix2(rig.b(&"Spine"), rig.b(&"Chest"), inverse_lerp(spine, chest, z))
	if z >= neck:
		return KinSculptor.mix2(rig.b(&"Chest"), rig.b(&"Neck"), inverse_lerp(chest, neck, z))
	return KinSculptor.one(rig.b(&"Neck"))


## A foreleg on `side`: from inside the shoulder down to a paw (`paw` half-extents, 0 for a hoof).
static func _foreleg(s: HeroMeshAtelier.Sculpt, rig: KinRig, side: float, radii: Array, paw: Vector3, m: float, foot_m: float,
		claws: float = 0.0) -> void:
	var sx: String = "L" if side < 0.0 else "R"
	var upper: int = rig.b(StringName("Upper_F" + sx))
	var fore: int = rig.b(StringName("Fore_F" + sx))
	var paw_bone: int = rig.b(StringName("Paw_F" + sx))
	var chest: int = rig.b(&"Chest")
	var shoulder: Vector3 = rig.heads[upper]
	var elbow: Vector3 = rig.heads[fore]
	var wrist: Vector3 = rig.heads[paw_bone]
	var toe: Vector3 = rig.tail_of(paw_bone)
	var inner: Vector3 = Vector3(shoulder.x * 0.55, shoulder.y + float(radii[0]) * 0.7, shoulder.z)
	KinSculptor.tube(s, [inner, shoulder, shoulder.lerp(elbow, 0.5), elbow, elbow.lerp(wrist, 0.5), wrist],
		[radii[0], radii[0], radii[1], radii[2], radii[3], radii[4]],
		[KinSculptor.one(chest), KinSculptor.mix2(chest, upper, 0.7), KinSculptor.one(upper), KinSculptor.mix2(upper, fore, 0.5), KinSculptor.one(fore), KinSculptor.mix2(fore, paw_bone, 0.5)], m,
		{"sides": 12, "cap_start": false, "flat": 1.1})
	_foot(s, wrist, toe, paw, paw_bone, foot_m, claws, side, float(radii[4]), m)


## A hind leg: a heavy thigh to the knee, the shank back to the hock, the cannon down to a paw.
static func _hindleg(s: HeroMeshAtelier.Sculpt, rig: KinRig, side: float, radii: Array, paw: Vector3, m: float, foot_m: float,
		claws: float = 0.0) -> void:
	var sx: String = "L" if side < 0.0 else "R"
	var thigh: int = rig.b(StringName("Thigh_H" + sx))
	var shank: int = rig.b(StringName("Shank_H" + sx))
	var hock: int = rig.b(StringName("Hock_H" + sx))
	var paw_bone: int = rig.b(StringName("Paw_H" + sx))
	var hips: int = rig.b(&"Hips")
	var hip: Vector3 = rig.heads[thigh]
	var knee: Vector3 = rig.heads[shank]
	var hock_at: Vector3 = rig.heads[hock]
	var fetlock: Vector3 = rig.heads[paw_bone]
	var toe: Vector3 = rig.tail_of(paw_bone)
	var inner: Vector3 = Vector3(hip.x * 0.5, hip.y + float(radii[0]) * 0.5, hip.z + float(radii[0]) * 0.2)
	KinSculptor.tube(s, [inner, hip, hip.lerp(knee, 0.55), knee, knee.lerp(hock_at, 0.5), hock_at, hock_at.lerp(fetlock, 0.5), fetlock],
		[radii[0], radii[0], radii[1], radii[2], radii[3], radii[4], radii[5], radii[5]],
		[KinSculptor.one(hips), KinSculptor.mix2(hips, thigh, 0.7), KinSculptor.one(thigh), KinSculptor.mix2(thigh, shank, 0.5), KinSculptor.one(shank), KinSculptor.mix2(shank, hock, 0.5), KinSculptor.one(hock),
			KinSculptor.mix2(hock, paw_bone, 0.5)], m, {"sides": 12, "cap_start": false, "flat": 1.15})
	_foot(s, fetlock, toe, paw, paw_bone, foot_m, claws, side, float(radii[5]), m)


## A paw (soft, round, a little big) or, with `paw` zero, a hoof under a short pastern.
static func _foot(s: HeroMeshAtelier.Sculpt, ankle: Vector3, toe: Vector3, paw: Vector3, bone: int, m: float, claws: float, side: float,
		leg_r: float = 0.05, fur_m: float = KinSculptor.MAT_FUR) -> void:
	var w: Dictionary = KinSculptor.one(bone)
	if paw == Vector3.ZERO:
		var ground: Vector3 = Vector3(lerpf(ankle.x, toe.x, 0.3), toe.y, lerpf(ankle.z, toe.z, 0.3))
		var hoof_top: Vector3 = ground + Vector3.UP * leg_r * 1.7
		KinSculptor.tube(s, [ankle, ankle.lerp(hoof_top, 0.5), hoof_top], [leg_r, leg_r * 0.85, leg_r * 0.92], [w], fur_m,
			{"sides": 10, "cap_start": false, "cap_end": false})
		KinSculptor.tube(s, [hoof_top + Vector3.UP * leg_r * 0.15, ground + Vector3.UP * leg_r * 0.25, ground], [leg_r * 0.95, leg_r * 1.18, leg_r * 1.12],
			[w], m, {"sides": 10, "extra": {"ao": 0.8, "g": 0.3}})
		return
	var center: Vector3 = Vector3(ankle.lerp(toe, 0.55).x, toe.y + paw.y * 0.9, ankle.lerp(toe, 0.55).z)
	KinSculptor.ellipsoid(s, center, paw, w, m, (toe - ankle) * Vector3(1.0, 0.0, 1.0), {"ao": 0.85})
	if claws > 0.0:
		var fwd: Vector3 = ((toe - ankle) * Vector3(1.0, 0.0, 1.0)).normalized()
		var across: Vector3 = Vector3.UP.cross(fwd).normalized()
		for index: int in 3:
			var off: float = (float(index) - 1.0) * paw.x * 0.55
			var base: Vector3 = center + fwd * paw.z * 0.85 + across * off + Vector3.DOWN * paw.y * 0.3
			KinSculptor.cone(s, base, base + fwd * claws + Vector3.DOWN * claws * 0.5, claws * 0.32, w, KinSculptor.MAT_HORN)


## A tail along Tail_1..3 with `radii` at its root, two middles and tip, its tip in `tip_m`.
static func _tail(s: HeroMeshAtelier.Sculpt, rig: KinRig, radii: Array, m: float, tip_m: float) -> void:
	var t1: int = rig.b(&"Tail_1")
	var t2: int = rig.b(&"Tail_2")
	var t3: int = rig.b(&"Tail_3")
	var root: Vector3 = rig.heads[t1] + Vector3.FORWARD * float(radii[0]) * 0.8
	KinSculptor.tube(s, [root, rig.heads[t1], rig.heads[t2], rig.heads[t3], rig.tail_of(t3)], radii,
		[KinSculptor.mix2(rig.b(&"Hips"), t1, 0.5), KinSculptor.one(t1), KinSculptor.mix2(t1, t2, 0.5), KinSculptor.mix2(t2, t3, 0.6), KinSculptor.one(t3)], m,
		{"sides": 10, "cap_start": false})
	if tip_m != m:
		KinSculptor.ellipsoid(s, rig.heads[t3].lerp(rig.tail_of(t3), 0.6), Vector3.ONE * float(radii[2]) * 1.15, KinSculptor.one(t3), tip_m,
			rig.tail_of(t3) - rig.heads[t3])


## An ear: a flat leaf from its base to its tip, its hollow paler in front.
static func _ear(s: HeroMeshAtelier.Sculpt, rig: KinRig, side: float, width: float, m: float, inner_m: float) -> void:
	var bone: int = rig.b(&"Ear_L" if side < 0.0 else &"Ear_R")
	var base: Vector3 = rig.heads[bone]
	var tip: Vector3 = rig.tail_of(bone)
	var head: int = rig.b(&"Head")
	KinSculptor.tube(s, [base + Vector3.DOWN * width * 0.3, base, base.lerp(tip, 0.45), tip], [width * 0.7, width, width * 0.8, width * 0.08],
		[KinSculptor.mix2(head, bone, 0.5), KinSculptor.one(bone), KinSculptor.one(bone), KinSculptor.one(bone)], m, {"sides": 10, "flat": 0.32, "extra": {"g": 0.2}})
	var hollow: Vector3 = Vector3.FORWARD * width * 0.22
	KinSculptor.tube(s, [base.lerp(tip, 0.1) + hollow, base.lerp(tip, 0.45) + hollow, base.lerp(tip, 0.85) + hollow], [width * 0.55, width * 0.55, width * 0.1],
		[KinSculptor.one(bone)], inner_m, {"sides": 8, "flat": 0.25, "extra": {"ao": 0.75}})


## A bramble cane arching from `a` to `b` along the back, `lift` above it, thorns along it and roses where asked.
static func _cane(s: HeroMeshAtelier.Sculpt, rig: KinRig, a: Vector3, b: Vector3, lift: float, radius: float, roses: Array) -> void:
	var points: Array = []
	var bones: Array = []
	for index: int in 6:
		var u: float = float(index) / 5.0
		var p: Vector3 = a.lerp(b, u) + Vector3.UP * sin(u * PI) * lift
		points.append(p)
		bones.append(_back(rig, p.z))
	KinSculptor.tube(s, points, [radius, radius * 1.1, radius, radius, radius * 0.9, radius * 0.7], bones, KinSculptor.MAT_THORN, {"sides": 7, "subdiv": 2})
	for index: int in [1, 2, 3, 4]:
		var u: float = (float(index) + 0.5) / 5.0
		var p: Vector3 = a.lerp(b, u) + Vector3.UP * sin(u * PI) * lift
		var out: Vector3 = Vector3(signf(p.x + 0.0001) * 0.6, 1.0, 0.25 if index % 2 == 0 else -0.25).normalized()
		KinSculptor.cone(s, p, p + out * radius * 3.6, radius * 0.9, _back(rig, p.z), KinSculptor.MAT_THORN)
	for u: float in roses:
		var p: Vector3 = a.lerp(b, u) + Vector3.UP * (sin(u * PI) * lift + radius * 1.4)
		KinSculptor.rose(s, p, radius * 4.2, Vector3(signf(p.x + 0.0001) * 0.4, 1.0, -0.3), _back(rig, p.z))


# --- The Bramble-Hound and the Padfoot -------------------------------------------

## A hedge-hound: lean, deep-chested and long-legged; a Padfoot is shaggier, heavier-pawed and maned.
static func _canine(s: HeroMeshAtelier.Sculpt, rig: KinRig, padfoot: bool) -> void:
	var hips: int = rig.b(&"Hips")
	var spine: int = rig.b(&"Spine")
	var chest: int = rig.b(&"Chest")
	var neck: int = rig.b(&"Neck")
	var head: int = rig.b(&"Head")
	var jaw: int = rig.b(&"Jaw")
	var bulk: float = 1.1 if padfoot else 1.0
	var hz: float = rig.heads[head].z
	var hy: float = rig.heads[head].y
	_body(s, [
		[Vector3(0.0, 0.63, 0.53), 0.07 * bulk, 0.07, KinSculptor.one(hips), KinSculptor.MAT_FUR],
		[Vector3(0.0, 0.64, 0.45), 0.135 * bulk, 0.15, KinSculptor.one(hips), KinSculptor.MAT_FUR],
		[Vector3(0.0, 0.64, 0.32), 0.15 * bulk, 0.155, KinSculptor.one(hips), KinSculptor.MAT_FUR],
		[Vector3(0.0, 0.68, 0.14), 0.13 * bulk, 0.13, KinSculptor.mix2(hips, spine, 0.6), KinSculptor.MAT_FUR],
		[Vector3(0.0, 0.665, -0.02), 0.15 * bulk, 0.175, KinSculptor.mix2(spine, chest, 0.4), KinSculptor.MAT_FUR],
		[Vector3(0.0, 0.62, -0.18), 0.165 * bulk, 0.2, KinSculptor.one(chest), KinSculptor.MAT_FUR],
		[Vector3(0.0, 0.68, -0.3), 0.145 * bulk, 0.18, KinSculptor.mix2(chest, neck, 0.3), KinSculptor.MAT_FUR],
		[Vector3(0.0, 0.79, -0.37), 0.1 * bulk, 0.11, KinSculptor.one(neck), KinSculptor.MAT_FUR],
		[Vector3(0.0, 0.88, hz + 0.03), 0.085, 0.09, KinSculptor.mix2(neck, head, 0.5), KinSculptor.MAT_FUR],
		[Vector3(0.0, hy, hz - 0.01), 0.07, 0.07, KinSculptor.one(head), KinSculptor.MAT_FUR],
	])
	# The pale bib and belly.
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.6, -0.33), Vector3(0.11 * bulk, 0.15, 0.07), KinSculptor.mix2(chest, neck, 0.3), KinSculptor.MAT_FUR_ACCENT, Vector3.UP)
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.53, 0.02), Vector3(0.1 * bulk, 0.06, 0.22), KinSculptor.mix2(spine, chest, 0.4), KinSculptor.MAT_FUR_ACCENT, Vector3.FORWARD)
	# The head: a round skull, cheeks, a muzzle and a dark nose; the jaw drops on its own bone.
	KinSculptor.ellipsoid(s, Vector3(0.0, hy + 0.025, hz - 0.05), Vector3(0.1, 0.095, 0.115), KinSculptor.one(head), KinSculptor.MAT_FUR)
	for side: float in [-1.0, 1.0]:
		KinSculptor.ellipsoid(s, Vector3(side * 0.062, hy - 0.035, hz - 0.1), Vector3(0.052, 0.05, 0.075), KinSculptor.one(head), KinSculptor.MAT_FUR_ACCENT if padfoot else KinSculptor.MAT_FUR)
	KinSculptor.tube(s, [Vector3(0.0, hy - 0.02, hz - 0.08), Vector3(0.0, hy - 0.04, hz - 0.2), Vector3(0.0, hy - 0.05, hz - 0.3)], [0.068, 0.052, 0.036],
		[KinSculptor.one(head)], KinSculptor.MAT_FUR, {"sides": 12, "flat": 0.85, "cap_start": false})
	KinSculptor.ellipsoid(s, Vector3(0.0, hy - 0.044, hz - 0.315), Vector3(0.032, 0.024, 0.022), KinSculptor.one(head), KinSculptor.MAT_HORN, Vector3.FORWARD, {"g": 0.8})
	KinSculptor.tube(s, [Vector3(0.0, hy - 0.07, hz - 0.1), Vector3(0.0, hy - 0.09, hz - 0.22), Vector3(0.0, hy - 0.085, hz - 0.29)], [0.048, 0.036, 0.022],
		[KinSculptor.one(jaw)], KinSculptor.MAT_FUR_ACCENT, {"sides": 10, "flat": 0.6, "cap_start": false})
	for side: float in [-1.0, 1.0]:
		KinSculptor.eye(s, Vector3(side * 0.06, hy + 0.035, hz - 0.115), 0.031, Vector3(side * 0.55, 0.12, -1.0), KinSculptor.one(head), false)
		KinSculptor.brow(s, Vector3(side * 0.03, hy + 0.075, hz - 0.12), Vector3(side * 0.088, hy + 0.068, hz - 0.09), 0.014, KinSculptor.one(head), KinSculptor.MAT_FUR_ACCENT)
		_ear(s, rig, side, 0.05 if padfoot else 0.045, KinSculptor.MAT_FUR, KinSculptor.MAT_FUR_ACCENT)
	# Legs, big soft paws, a tail.
	var paw: Vector3 = Vector3(0.058, 0.04, 0.075) if padfoot else Vector3(0.048, 0.034, 0.066)
	for side: float in [-1.0, 1.0]:
		_foreleg(s, rig, side, [0.07 * bulk, 0.058 * bulk, 0.042, 0.034, 0.03], paw, KinSculptor.MAT_FUR, KinSculptor.MAT_FUR, 0.022)
		_hindleg(s, rig, side, [0.095 * bulk, 0.085 * bulk, 0.05, 0.04, 0.032, 0.028], paw, KinSculptor.MAT_FUR, KinSculptor.MAT_FUR, 0.022)
	if padfoot:
		# A great ruff round the neck and a brush of a tail.
		KinSculptor.tube(s, [Vector3(0.0, 0.66, -0.2), Vector3(0.0, 0.76, -0.33), Vector3(0.0, 0.85, -0.42)], [0.19, 0.18, 0.12],
			[KinSculptor.one(chest), KinSculptor.mix2(chest, neck, 0.5), KinSculptor.one(neck)], KinSculptor.MAT_FUR_ACCENT, {"sides": 14, "flat": 1.1})
		_tail(s, rig, [0.05, 0.08, 0.095, 0.08, 0.02], KinSculptor.MAT_FUR_ACCENT, KinSculptor.MAT_FUR_ACCENT)
	else:
		_tail(s, rig, [0.05, 0.048, 0.042, 0.03, 0.01], KinSculptor.MAT_FUR, KinSculptor.MAT_FUR)
		# Brambles for hackles: four canes arching along the spine, thorned, budding dog-roses.
		_cane(s, rig, Vector3(0.03, 0.78, 0.42), Vector3(-0.02, 0.8, 0.18), 0.08, 0.013, [0.5])
		_cane(s, rig, Vector3(-0.03, 0.8, 0.26), Vector3(0.02, 0.83, 0.0), 0.09, 0.013, [])
		_cane(s, rig, Vector3(0.025, 0.83, 0.06), Vector3(-0.02, 0.82, -0.2), 0.1, 0.014, [0.45])
		_cane(s, rig, Vector3(-0.025, 0.82, -0.12), Vector3(0.015, 0.92, -0.38), 0.08, 0.012, [0.7])


# --- The Bristle-Hob ------------------------------------------------------------

static func _boar(s: HeroMeshAtelier.Sculpt, rig: KinRig) -> void:
	var hips: int = rig.b(&"Hips")
	var spine: int = rig.b(&"Spine")
	var chest: int = rig.b(&"Chest")
	var neck: int = rig.b(&"Neck")
	var head: int = rig.b(&"Head")
	var jaw: int = rig.b(&"Jaw")
	_body(s, [
		[Vector3(0.0, 0.5, 0.47), 0.1, 0.1, KinSculptor.one(hips), KinSculptor.MAT_FUR],
		[Vector3(0.0, 0.5, 0.38), 0.22, 0.22, KinSculptor.one(hips), KinSculptor.MAT_FUR],
		[Vector3(0.0, 0.51, 0.18), 0.26, 0.26, KinSculptor.mix2(hips, spine, 0.6), KinSculptor.MAT_FUR],
		[Vector3(0.0, 0.52, -0.04), 0.27, 0.27, KinSculptor.mix2(spine, chest, 0.5), KinSculptor.MAT_FUR],
		[Vector3(0.0, 0.54, -0.24), 0.25, 0.27, KinSculptor.one(chest), KinSculptor.MAT_FUR],
		[Vector3(0.0, 0.56, -0.38), 0.2, 0.21, KinSculptor.mix2(chest, neck, 0.6), KinSculptor.MAT_FUR],
		[Vector3(0.0, 0.56, -0.47), 0.16, 0.17, KinSculptor.mix2(neck, head, 0.5), KinSculptor.MAT_FUR],
	])
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.36, 0.0), Vector3(0.18, 0.08, 0.3), KinSculptor.mix2(spine, chest, 0.4), KinSculptor.MAT_FUR_ACCENT)
	# The head: a wedge of skull running into a long snout, a pink disc at its end.
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.58, -0.53), Vector3(0.15, 0.15, 0.14), KinSculptor.one(head), KinSculptor.MAT_FUR)
	KinSculptor.tube(s, [Vector3(0.0, 0.54, -0.58), Vector3(0.0, 0.49, -0.7), Vector3(0.0, 0.45, -0.79)], [0.11, 0.085, 0.07],
		[KinSculptor.one(head)], KinSculptor.MAT_FUR, {"sides": 12, "flat": 0.9, "cap_start": false, "cap_end": false})
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.448, -0.8), Vector3(0.074, 0.064, 0.026), KinSculptor.one(head), KinSculptor.MAT_BELLY, Vector3.FORWARD, {"g": 0.4})
	for side: float in [-1.0, 1.0]:
		KinSculptor.ellipsoid(s, Vector3(side * 0.026, 0.45, -0.823), Vector3(0.013, 0.018, 0.006), KinSculptor.one(head), KinSculptor.MAT_HIDE, Vector3.FORWARD, {"ao": 0.1})
	KinSculptor.tube(s, [Vector3(0.0, 0.47, -0.58), Vector3(0.0, 0.43, -0.7), Vector3(0.0, 0.42, -0.76)], [0.07, 0.055, 0.04],
		[KinSculptor.one(jaw)], KinSculptor.MAT_FUR_ACCENT, {"sides": 10, "flat": 0.6, "cap_start": false})
	for side: float in [-1.0, 1.0]:
		# Upcurled tusks off the lower jaw: they carry the blow's Sign.
		KinSculptor.cone(s, Vector3(side * 0.06, 0.44, -0.71), Vector3(side * 0.12, 0.56, -0.76), 0.024, KinSculptor.one(jaw), KinSculptor.MAT_HORN, Vector3(side * 0.035, -0.02, -0.04), 6, 1.0)
		KinSculptor.eye(s, Vector3(side * 0.088, 0.63, -0.6), 0.03, Vector3(side * 0.7, 0.2, -1.0), KinSculptor.one(head), false)
		KinSculptor.brow(s, Vector3(side * 0.05, 0.67, -0.62), Vector3(side * 0.12, 0.665, -0.57), 0.02, KinSculptor.one(head), KinSculptor.MAT_FUR_ACCENT)
		_ear(s, rig, side, 0.05, KinSculptor.MAT_FUR, KinSculptor.MAT_BELLY)
	# The bristle crest from crown to back.
	for index: int in 10:
		var z: float = -0.56 + float(index) * 0.07
		var top: float = 0.7 + 0.08 * sin(clampf(inverse_lerp(-0.56, 0.1, z), 0.0, 1.0) * PI * 0.8) + (0.06 if z > -0.5 else 0.0)
		var tall: float = lerpf(0.13, 0.05, float(index) / 9.0)
		var bones: Dictionary = KinSculptor.one(head) if z < -0.48 else _back(rig, z)
		KinSculptor.blade(s, Vector3(0.0, top - 0.04, z), Vector3(0.0, top + tall, z + 0.06), 0.035, bones, KinSculptor.MAT_FUR_ACCENT, Vector3.FORWARD, 0.014)
	for side: float in [-1.0, 1.0]:
		_foreleg(s, rig, side, [0.1, 0.085, 0.06, 0.05, 0.045], Vector3.ZERO, KinSculptor.MAT_FUR, KinSculptor.MAT_HIDE)
		_hindleg(s, rig, side, [0.13, 0.11, 0.07, 0.055, 0.048, 0.045], Vector3.ZERO, KinSculptor.MAT_FUR, KinSculptor.MAT_HIDE)
	_tail(s, rig, [0.025, 0.022, 0.02, 0.015, 0.005], KinSculptor.MAT_FUR, KinSculptor.MAT_FUR_ACCENT)


# --- The Puddle-Bucca -------------------------------------------------------------

static func _toad(s: HeroMeshAtelier.Sculpt, rig: KinRig) -> void:
	var hips: int = rig.b(&"Hips")
	var spine: int = rig.b(&"Spine")
	var chest: int = rig.b(&"Chest")
	var neck: int = rig.b(&"Neck")
	var head: int = rig.b(&"Head")
	var jaw: int = rig.b(&"Jaw")
	_body(s, [
		[Vector3(0.0, 0.33, 0.42), 0.16, 0.1, KinSculptor.one(hips), KinSculptor.MAT_HIDE],
		[Vector3(0.0, 0.37, 0.3), 0.34, 0.2, KinSculptor.one(hips), KinSculptor.MAT_HIDE],
		[Vector3(0.0, 0.4, 0.1), 0.41, 0.24, KinSculptor.mix2(hips, spine, 0.6), KinSculptor.MAT_HIDE],
		[Vector3(0.0, 0.42, -0.1), 0.4, 0.23, KinSculptor.mix2(spine, chest, 0.6), KinSculptor.MAT_HIDE],
		[Vector3(0.0, 0.46, -0.26), 0.36, 0.19, KinSculptor.mix2(chest, neck, 0.6), KinSculptor.MAT_HIDE],
		[Vector3(0.0, 0.47, -0.42), 0.31, 0.13, KinSculptor.mix2(neck, head, 0.7), KinSculptor.MAT_HIDE],
		[Vector3(0.0, 0.46, -0.54), 0.2, 0.08, KinSculptor.one(head), KinSculptor.MAT_HIDE],
	], 18)
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.3, 0.0), Vector3(0.34, 0.13, 0.36), KinSculptor.mix2(spine, chest, 0.5), KinSculptor.MAT_BELLY)
	# The wide lower jaw (it gapes on its own bone) and a dark lip line.
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.39, -0.44), Vector3(0.28, 0.055, 0.15), KinSculptor.one(jaw), KinSculptor.MAT_BELLY, Vector3.FORWARD, {"ao": 0.7})
	KinSculptor.tube(s, [Vector3(-0.27, 0.43, -0.36), Vector3(-0.14, 0.425, -0.52), Vector3(0.0, 0.425, -0.565), Vector3(0.14, 0.425, -0.52), Vector3(0.27, 0.43, -0.36)],
		[0.012, 0.014, 0.014, 0.014, 0.012], [KinSculptor.one(head)], KinSculptor.MAT_HIDE, {"sides": 6, "extra": {"ao": 0.0}})
	for side: float in [-1.0, 1.0]:
		var ear: int = rig.b(&"Ear_L" if side < 0.0 else &"Ear_R")
		# Eyes up on the brow in their own bulges (the ear bones carry them).
		KinSculptor.ellipsoid(s, Vector3(side * 0.15, 0.6, -0.33), Vector3(0.09, 0.08, 0.09), KinSculptor.mix2(head, ear, 0.7), KinSculptor.MAT_HIDE, Vector3.UP)
		KinSculptor.eye(s, Vector3(side * 0.165, 0.645, -0.39), 0.06, Vector3(side * 0.45, 0.35, -1.0), KinSculptor.one(ear), false)
		KinSculptor.brow(s, Vector3(side * 0.11, 0.69, -0.38), Vector3(side * 0.22, 0.68, -0.33), 0.018, KinSculptor.one(ear), KinSculptor.MAT_HIDE)
		_foreleg(s, rig, side, [0.07, 0.06, 0.045, 0.04, 0.035], Vector3(0.07, 0.022, 0.08), KinSculptor.MAT_HIDE, KinSculptor.MAT_BELLY)
		_hindleg(s, rig, side, [0.12, 0.11, 0.08, 0.06, 0.045, 0.04], Vector3(0.09, 0.024, 0.14), KinSculptor.MAT_HIDE, KinSculptor.MAT_BELLY)
	# A lily-leaf cap with a little white flower.
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.62, -0.2), Vector3(0.21, 0.014, 0.19), KinSculptor.mix2(chest, head, 0.6), KinSculptor.MAT_LEAF, Vector3.FORWARD, {"g": 0.4})
	KinSculptor.rose(s, Vector3(0.06, 0.645, -0.16), 0.05, Vector3(0.2, 1.0, 0.1), KinSculptor.mix2(chest, head, 0.6), 6)


# --- The Blighted Taproot Stag ----------------------------------------------------

static func _stag(s: HeroMeshAtelier.Sculpt, rig: KinRig) -> void:
	var hips: int = rig.b(&"Hips")
	var spine: int = rig.b(&"Spine")
	var chest: int = rig.b(&"Chest")
	var neck: int = rig.b(&"Neck")
	var head: int = rig.b(&"Head")
	var jaw: int = rig.b(&"Jaw")
	_body(s, [
		[Vector3(0.0, 1.88, 0.98), 0.16, 0.18, KinSculptor.one(hips), KinSculptor.MAT_FUR],
		[Vector3(0.0, 1.9, 0.82), 0.33, 0.37, KinSculptor.one(hips), KinSculptor.MAT_FUR],
		[Vector3(0.0, 1.93, 0.48), 0.35, 0.39, KinSculptor.mix2(hips, spine, 0.5), KinSculptor.MAT_FUR],
		[Vector3(0.0, 1.95, 0.08), 0.37, 0.43, KinSculptor.mix2(spine, chest, 0.4), KinSculptor.MAT_FUR],
		[Vector3(0.0, 1.92, -0.3), 0.39, 0.48, KinSculptor.one(chest), KinSculptor.MAT_FUR],
		[Vector3(0.0, 2.04, -0.56), 0.32, 0.4, KinSculptor.mix2(chest, neck, 0.4), KinSculptor.MAT_FUR],
		[Vector3(0.0, 2.27, -0.74), 0.21, 0.27, KinSculptor.one(neck), KinSculptor.MAT_FUR],
		[Vector3(0.0, 2.5, -0.87), 0.16, 0.2, KinSculptor.mix2(neck, head, 0.4), KinSculptor.MAT_FUR],
		[Vector3(0.0, 2.68, -0.97), 0.14, 0.15, KinSculptor.one(head), KinSculptor.MAT_FUR],
	])
	KinSculptor.ellipsoid(s, Vector3(0.0, 1.56, 0.05), Vector3(0.28, 0.12, 0.6), KinSculptor.mix2(spine, chest, 0.4), KinSculptor.MAT_FUR_ACCENT)
	KinSculptor.ellipsoid(s, Vector3(0.0, 1.92, -0.72), Vector3(0.2, 0.3, 0.12), KinSculptor.mix2(chest, neck, 0.5), KinSculptor.MAT_FUR_ACCENT, Vector3.UP)
	# The head: a long, noble face, a dark muzzle, soft gold spirit eyes.
	KinSculptor.ellipsoid(s, Vector3(0.0, 2.75, -1.05), Vector3(0.16, 0.17, 0.2), KinSculptor.one(head), KinSculptor.MAT_FUR)
	KinSculptor.tube(s, [Vector3(0.0, 2.7, -1.15), Vector3(0.0, 2.6, -1.36), Vector3(0.0, 2.54, -1.48)], [0.12, 0.09, 0.07], [KinSculptor.one(head)], KinSculptor.MAT_FUR,
		{"sides": 12, "flat": 1.0, "cap_start": false})
	KinSculptor.ellipsoid(s, Vector3(0.0, 2.54, -1.5), Vector3(0.065, 0.055, 0.045), KinSculptor.one(head), KinSculptor.MAT_HORN, Vector3.FORWARD, {"g": 0.7})
	KinSculptor.tube(s, [Vector3(0.0, 2.6, -1.14), Vector3(0.0, 2.52, -1.32), Vector3(0.0, 2.5, -1.42)], [0.08, 0.06, 0.04], [KinSculptor.one(jaw)], KinSculptor.MAT_FUR_ACCENT,
		{"sides": 10, "flat": 0.6, "cap_start": false})
	for side: float in [-1.0, 1.0]:
		KinSculptor.eye(s, Vector3(side * 0.13, 2.8, -1.14), 0.052, Vector3(side * 0.75, 0.1, -1.0), KinSculptor.one(head), true)
		KinSculptor.brow(s, Vector3(side * 0.07, 2.88, -1.15), Vector3(side * 0.17, 2.87, -1.08), 0.03, KinSculptor.one(head), KinSculptor.MAT_FUR)
		_ear(s, rig, side, 0.09, KinSculptor.MAT_FUR, KinSculptor.MAT_FUR_ACCENT)
		_antler(s, rig, side)
	# A mantle of moss over the withers and down the neck, strands of it hanging.
	for index: int in 7:
		var u: float = float(index) / 6.0
		var at: Vector3 = Vector3(0.0, 2.3, -0.42).lerp(Vector3(0.0, 2.62, -0.86), u) + Vector3(sin(index * 2.4) * 0.08, 0.0, 0.0)
		KinSculptor.ellipsoid(s, at, Vector3(0.3 - u * 0.12, 0.12, 0.2), _back(rig, at.z) if at.z > rig.heads[neck].z else KinSculptor.mix2(neck, head, u * 0.5), KinSculptor.MAT_MOSS)
	for side: float in [-1.0, 1.0]:
		for index: int in 4:
			var top: Vector3 = Vector3(side * (0.26 + index * 0.02), 2.25 - index * 0.04, -0.3 - index * 0.12)
			KinSculptor.blade(s, top, top + Vector3(side * 0.06, -0.45 - index * 0.06, 0.02), 0.05, _back(rig, top.z), KinSculptor.MAT_MOSS, Vector3.FORWARD, 0.015)
	for side: float in [-1.0, 1.0]:
		_foreleg(s, rig, side, [0.22, 0.17, 0.1, 0.075, 0.062], Vector3.ZERO, KinSculptor.MAT_FUR, KinSculptor.MAT_HORN)
		_hindleg(s, rig, side, [0.28, 0.23, 0.13, 0.09, 0.07, 0.062], Vector3.ZERO, KinSculptor.MAT_FUR, KinSculptor.MAT_HORN)
		# The rusted cuffs of the chains Nokes's men drove in (docs/28 §7.4).
		var wrist: Vector3 = rig.heads[rig.b(&"Paw_FL" if side < 0.0 else &"Paw_FR")]
		var fore: int = rig.b(&"Fore_FL" if side < 0.0 else &"Fore_FR")
		KinSculptor.tube(s, [wrist + Vector3.UP * 0.2, wrist + Vector3.UP * 0.32], [0.1, 0.1], [KinSculptor.one(fore)], KinSculptor.MAT_RUST, {"sides": 12, "extra": {"g": 0.6}})
	KinSculptor.tube(s, [Vector3(0.0, 1.95, -0.12), Vector3(0.0, 1.95, -0.26)], [0.42, 0.42], [KinSculptor.one(chest)], KinSculptor.MAT_RUST, {"sides": 18, "flat": 1.14, "extra": {"g": 0.5}})
	_tail(s, rig, [0.08, 0.08, 0.07, 0.05, 0.015], KinSculptor.MAT_FUR_ACCENT, KinSculptor.MAT_FUR_ACCENT)


## A root antler: a bark beam sweeping up and out, three tines, moss tufts and rootlets hanging.
static func _antler(s: HeroMeshAtelier.Sculpt, rig: KinRig, side: float) -> void:
	var head: Dictionary = KinSculptor.one(rig.b(&"Head"))
	var beam: Array = [Vector3(side * 0.09, 2.86, -1.0), Vector3(side * 0.22, 3.08, -0.96), Vector3(side * 0.42, 3.28, -0.88),
		Vector3(side * 0.6, 3.46, -0.78), Vector3(side * 0.72, 3.6, -0.6)]
	KinSculptor.tube(s, beam, [0.075, 0.065, 0.055, 0.04, 0.012], [head], KinSculptor.MAT_BARK, {"sides": 9, "extra": {"a": 1.0}, "tip_extra": {"g": 1.0}})
	var tines: Array = [[1, Vector3(side * 0.0, 0.36, -0.16)], [2, Vector3(side * 0.12, 0.34, 0.02)], [3, Vector3(side * -0.06, 0.3, -0.12)]]
	for tine: Array in tines:
		var from: Vector3 = beam[int(tine[0])]
		KinSculptor.cone(s, from, from + (tine[1] as Vector3), 0.04, head, KinSculptor.MAT_BARK, Vector3(side * 0.04, 0.0, 0.0), 7, 1.0)
	for index: int in [1, 3]:
		KinSculptor.ellipsoid(s, beam[index] + Vector3.UP * 0.03, Vector3(0.08, 0.05, 0.07), head, KinSculptor.MAT_MOSS)
	for index: int in [1, 2, 3]:
		var from: Vector3 = (beam[index] as Vector3).lerp(beam[index + 1], 0.4)
		KinSculptor.tube(s, [from, from + Vector3(side * 0.02, -0.16, 0.0), from + Vector3(side * 0.05, -0.32 - index * 0.04, 0.03)], [0.016, 0.012, 0.004],
			[head], KinSculptor.MAT_THORN, {"sides": 5, "subdiv": 2})


# --- The Crag-Back Cairn-Drake ------------------------------------------------------

static func _drake(s: HeroMeshAtelier.Sculpt, rig: KinRig) -> void:
	var hips: int = rig.b(&"Hips")
	var spine: int = rig.b(&"Spine")
	var chest: int = rig.b(&"Chest")
	var neck: int = rig.b(&"Neck")
	var head: int = rig.b(&"Head")
	var jaw: int = rig.b(&"Jaw")
	_body(s, [
		[Vector3(0.0, 0.98, 1.1), 0.26, 0.24, KinSculptor.one(hips), KinSculptor.MAT_HIDE],
		[Vector3(0.0, 1.0, 0.8), 0.55, 0.42, KinSculptor.one(hips), KinSculptor.MAT_HIDE],
		[Vector3(0.0, 1.04, 0.2), 0.62, 0.48, KinSculptor.mix2(hips, spine, 0.7), KinSculptor.MAT_HIDE],
		[Vector3(0.0, 1.04, -0.4), 0.58, 0.46, KinSculptor.mix2(spine, chest, 0.7), KinSculptor.MAT_HIDE],
		[Vector3(0.0, 1.04, -0.8), 0.38, 0.34, KinSculptor.mix2(chest, neck, 0.6), KinSculptor.MAT_HIDE],
		[Vector3(0.0, 1.08, -1.1), 0.28, 0.26, KinSculptor.mix2(neck, head, 0.5), KinSculptor.MAT_HIDE],
	])
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.72, 0.0), Vector3(0.48, 0.2, 0.9), KinSculptor.mix2(spine, chest, 0.5), KinSculptor.MAT_BELLY)
	KinSculptor.ellipsoid(s, Vector3(0.0, 1.12, -1.32), Vector3(0.26, 0.22, 0.28), KinSculptor.one(head), KinSculptor.MAT_HIDE)
	KinSculptor.tube(s, [Vector3(0.0, 1.06, -1.42), Vector3(0.0, 1.0, -1.66), Vector3(0.0, 0.97, -1.84)], [0.2, 0.16, 0.12], [KinSculptor.one(head)], KinSculptor.MAT_HIDE,
		{"sides": 12, "flat": 0.8, "cap_start": false})
	KinSculptor.tube(s, [Vector3(0.0, 0.92, -1.36), Vector3(0.0, 0.88, -1.6), Vector3(0.0, 0.88, -1.76)], [0.16, 0.12, 0.08], [KinSculptor.one(jaw)], KinSculptor.MAT_BELLY,
		{"sides": 10, "flat": 0.55, "cap_start": false})
	for side: float in [-1.0, 1.0]:
		KinSculptor.eye(s, Vector3(side * 0.18, 1.24, -1.48), 0.06, Vector3(side * 0.8, 0.15, -1.0), KinSculptor.one(head), true)
		KinSculptor.brow(s, Vector3(side * 0.1, 1.33, -1.5), Vector3(side * 0.27, 1.32, -1.38), 0.05, KinSculptor.one(head), KinSculptor.MAT_STONE)
		_ear(s, rig, side, 0.08, KinSculptor.MAT_STONE, KinSculptor.MAT_HIDE)
		_foreleg(s, rig, side, [0.24, 0.2, 0.17, 0.15, 0.14], Vector3(0.17, 0.08, 0.2), KinSculptor.MAT_HIDE, KinSculptor.MAT_STONE, 0.06)
		_hindleg(s, rig, side, [0.28, 0.24, 0.18, 0.16, 0.15, 0.14], Vector3(0.17, 0.08, 0.2), KinSculptor.MAT_HIDE, KinSculptor.MAT_STONE, 0.06)
	# The crag shell: stacked stones along the back, moss on their tops.
	for index: int in 7:
		var z: float = lerpf(0.95, -0.75, float(index) / 6.0)
		var top: Vector3 = Vector3(sin(index * 2.1) * 0.12, 1.42 + 0.06 * sin(float(index) / 6.0 * PI), z)
		KinSculptor.ellipsoid(s, top, Vector3(0.34, 0.2, 0.26), _back(rig, z), KinSculptor.MAT_STONE, Vector3.UP, {"g": 0.4})
		KinSculptor.ellipsoid(s, top + Vector3(0.0, 0.16, 0.0), Vector3(0.2, 0.06, 0.16), _back(rig, z), KinSculptor.MAT_MOSS, Vector3.UP)
	# The bell at its throat, on a rope.
	KinSculptor.tube(s, [Vector3(-0.2, 0.92, -1.12), Vector3(0.0, 0.84, -1.2), Vector3(0.2, 0.92, -1.12)], [0.025, 0.025, 0.025], [KinSculptor.one(neck)], KinSculptor.MAT_CLOTH, {"sides": 6})
	KinSculptor.tube(s, [Vector3(0.0, 0.84, -1.2), Vector3(0.0, 0.72, -1.2), Vector3(0.0, 0.58, -1.2), Vector3(0.0, 0.54, -1.2)], [0.05, 0.1, 0.15, 0.15],
		[KinSculptor.one(neck)], KinSculptor.MAT_BRASS, {"sides": 14, "cap_end": false, "extra": {"g": 0.4}})
	_tail(s, rig, [0.26, 0.2, 0.13, 0.07, 0.02], KinSculptor.MAT_HIDE, KinSculptor.MAT_STONE)
