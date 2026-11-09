## The two-legged kin (docs/30 §7.3), sculpted over the heroes' own 24-bone
## skeleton at its 1.75 m rest (KinFigure scales it to the kin's height), so
## they share the heroes' joints and can borrow their poses: the Ash-Grig (a
## soot-hob with a coal in its belly), the Furrow Iron-Men (plough-iron round a
## cauldron of coals, a bucket for a helm), the Tide-Wight (hooded sea-fret, no
## feet), the Crag-Spriggan (a stone-guard in a moss cloak) and the Bog-Hulk
## (a hunched peat giant).
class_name KinSculptFolk
extends RefCounted

const B = HeroRigBuilder.Bone


static func sculpt(s: HeroMeshAtelier.Sculpt, rig: KinRig, look: StringName) -> void:
	match look:
		KinLooks.ASH_GRIG:
			_ash_grig(s, rig)
		KinLooks.IRON_MAN:
			_iron_man(s, rig, 1.0, &"")
		KinLooks.IRON_FLINGER:
			_iron_man(s, rig, 0.8, &"flinger")
		KinLooks.IRON_GIANT:
			_iron_man(s, rig, 1.12, &"giant")
		KinLooks.SPRIGGAN:
			_spriggan(s, rig)
		KinLooks.BOG_HULK:
			_bog_hulk(s, rig)
		_:
			_tide_wight(s, rig)


## The Maker-Seal plate an Iron-Man wears on his chest (KinFigure turns it): a raised brass triangle, point down.
static func maker_seal_mesh() -> ArrayMesh:
	var s: HeroMeshAtelier.Sculpt = HeroMeshAtelier.Sculpt.new(false)
	var corners: Array[Vector3] = [Vector3(0.0, -0.1, 0.0), Vector3(0.09, 0.06, 0.0), Vector3(-0.09, 0.06, 0.0)]
	for index: int in 3:
		KinSculptor.tube(s, [corners[index], corners[(index + 1) % 3]], [0.018, 0.018], [{0: 1.0}], KinSculptor.MAT_BRASS, {"sides": 6, "subdiv": 1, "extra": {"g": 0.7, "a": 1.0}})
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.005, 0.0), Vector3(0.03, 0.03, 0.018), {0: 1.0}, KinSculptor.MAT_BRASS, Vector3.FORWARD, {"g": 0.9, "a": 1.0})
	return s.commit(&"maker_seal")


# --- Shared parts ---------------------------------------------------------------

## An arm on `side` from inside the shoulder to the wrist: `radii` at the shoulder, elbow and wrist.
static func _arm(s: HeroMeshAtelier.Sculpt, rig: KinRig, side: float, radii: Array, m: float, extra: Dictionary = {}) -> void:
	var clavicle: int = B.CLAVICLE_L if side < 0.0 else B.CLAVICLE_R
	var upper: int = B.UPPER_ARM_L if side < 0.0 else B.UPPER_ARM_R
	var fore: int = B.FOREARM_L if side < 0.0 else B.FOREARM_R
	var hand: int = B.HAND_L if side < 0.0 else B.HAND_R
	var shoulder: Vector3 = rig.heads[upper]
	var elbow: Vector3 = rig.heads[fore]
	var wrist: Vector3 = rig.heads[hand]
	KinSculptor.tube(s, [shoulder + Vector3(-side * 0.06, 0.02, 0.0), shoulder, shoulder.lerp(elbow, 0.5), elbow, elbow.lerp(wrist, 0.5), wrist],
		[radii[0], radii[0], float(radii[0]) * 0.92, radii[1], float(radii[1]) * 0.95, radii[2]],
		[KinSculptor.mix2(clavicle, upper, 0.4), KinSculptor.mix2(clavicle, upper, 0.85), KinSculptor.one(upper), KinSculptor.mix2(upper, fore, 0.5), KinSculptor.one(fore), KinSculptor.mix2(fore, hand, 0.4)], m,
		{"sides": 12, "cap_start": false, "extra": extra})


## A leg from inside the hip to the ankle: `radii` at the hip, knee and ankle.
static func _leg(s: HeroMeshAtelier.Sculpt, rig: KinRig, side: float, radii: Array, m: float) -> void:
	var thigh: int = B.THIGH_L if side < 0.0 else B.THIGH_R
	var shin: int = B.SHIN_L if side < 0.0 else B.SHIN_R
	var foot: int = B.FOOT_L if side < 0.0 else B.FOOT_R
	var hip: Vector3 = rig.heads[thigh]
	var knee: Vector3 = rig.heads[shin]
	var ankle: Vector3 = rig.heads[foot]
	KinSculptor.tube(s, [hip + Vector3(-side * 0.04, 0.06, 0.0), hip, hip.lerp(knee, 0.5), knee, knee.lerp(ankle, 0.5), ankle],
		[radii[0], radii[0], float(radii[0]) * 0.9, radii[1], float(radii[1]) * 0.9, radii[2]],
		[KinSculptor.mix2(B.HIPS, thigh, 0.5), KinSculptor.mix2(B.HIPS, thigh, 0.85), KinSculptor.one(thigh), KinSculptor.mix2(thigh, shin, 0.5), KinSculptor.one(shin), KinSculptor.mix2(shin, foot, 0.4)], m,
		{"sides": 12, "cap_start": false})


## Fingers (and a thumb) off a hand: `count` curled tines `length` long, `thick` at their root.
static func _fingers(s: HeroMeshAtelier.Sculpt, rig: KinRig, side: float, count: int, length: float, thick: float, m: float, vein: float,
		palm: Vector3) -> void:
	var hand: int = B.HAND_L if side < 0.0 else B.HAND_R
	var wrist: Vector3 = rig.heads[hand]
	var down: Vector3 = (rig.tail_of(hand) - wrist).normalized()
	var center: Vector3 = wrist + down * palm.y * 0.9
	KinSculptor.ellipsoid(s, center, palm, KinSculptor.one(hand), m, down, {"a": vein})
	for index: int in count:
		var spread: float = (float(index) - float(count - 1) * 0.5) * palm.z * 0.75
		var base: Vector3 = center + down * palm.y * 0.8 + Vector3(0.0, 0.0, spread)
		KinSculptor.cone(s, base, base + down * length + Vector3(-side * length * 0.12, 0.0, -length * 0.25), thick, KinSculptor.one(hand), m,
			Vector3(0.0, 0.0, -length * 0.18), 6, vein)
	var thumb: Vector3 = center + Vector3(-side * palm.x * 0.6, 0.0, -palm.z * 0.8)
	KinSculptor.cone(s, thumb, thumb + down * length * 0.55 + Vector3(-side * 0.02, 0.0, -length * 0.3), thick * 0.95, KinSculptor.one(hand), m, Vector3.ZERO, 6, vein)


# --- The Ash-Grig ----------------------------------------------------------------

## A little soot-hob: a big round head with long ears and lamp eyes, a pot belly
## with a coal glowing through its cracks, thin limbs, big hands and feet, a tail.
static func _ash_grig(s: HeroMeshAtelier.Sculpt, rig: KinRig) -> void:
	# The head grows big round the neck, and the hands and feet a little (as the youth's do).
	var neck_at: Vector3 = Vector3(0.0, 1.43, -0.01)
	s.warp = func(p: Vector3) -> Vector3:
		var head: float = smoothstep(1.38, 1.47, p.y)
		var q: Vector3 = neck_at + (p - neck_at) * lerpf(1.0, 1.85, head)
		for side: float in [-1.0, 1.0]:
			var wrist: Vector3 = Vector3(side * 0.3, 0.83, -0.01)
			if absf(p.x - wrist.x) < 0.15 and p.y < wrist.y + 0.01 and p.y > 0.55:
				q = q.lerp(wrist + (p - wrist) * 1.4, smoothstep(-0.01, 0.03, wrist.y - p.y))
		var low: float = 1.0 - smoothstep(0.06, 0.13, p.y)
		if low > 0.0:
			var ankle: Vector3 = Vector3(signf(p.x) * 0.12, p.y, 0.02)
			var grown: float = lerpf(1.0, 1.35, low)
			q = Vector3(ankle.x + (q.x - ankle.x) * grown, q.y, ankle.z + (q.z - ankle.z) * grown)
		return q
	KinSculptor.loft(s, [
		KinSculptor.r(Vector3(0.0, 0.83, 0.0), 0.13, 0.12, KinSculptor.one(B.HIPS), KinSculptor.MAT_FUR, {"ao": 0.8}),
		KinSculptor.r(Vector3(0.0, 0.96, -0.025), 0.2, 0.19, KinSculptor.one(B.HIPS), KinSculptor.MAT_FUR),
		KinSculptor.r(Vector3(0.0, 1.1, -0.035), 0.2, 0.19, KinSculptor.mix2(B.SPINE, B.CHEST, 0.3), KinSculptor.MAT_FUR),
		KinSculptor.r(Vector3(0.0, 1.25, 0.0), 0.15, 0.13, KinSculptor.one(B.CHEST), KinSculptor.MAT_FUR),
		KinSculptor.r(Vector3(0.0, 1.37, 0.0), 0.075, 0.07, KinSculptor.mix2(B.CHEST, B.NECK, 0.6), KinSculptor.MAT_FUR),
		KinSculptor.r(Vector3(0.0, 1.44, -0.005), 0.06, 0.06, KinSculptor.mix2(B.NECK, B.HEAD, 0.5), KinSculptor.MAT_FUR),
	], {"sides": 16, "subdiv": 3, "cap_start": true, "cap_end": false})
	# The coal in its belly, glowing through cracks in the soot.
	for crack: Array in [[Vector3(-0.03, 1.05, -0.215), Vector3(0.05, 0.013, 0.03)], [Vector3(0.05, 0.98, -0.21), Vector3(0.035, 0.011, 0.026)],
			[Vector3(0.0, 0.92, -0.2), Vector3(0.055, 0.011, 0.024)], [Vector3(-0.08, 0.96, -0.19), Vector3(0.025, 0.009, 0.022)]]:
		KinSculptor.ellipsoid(s, crack[0], crack[1], KinSculptor.mix2(B.HIPS, B.SPINE, 0.5), KinSculptor.MAT_EMBER, Vector3.RIGHT)
	# The head: round, a pale ashen face, lamp eyes, a small smile, long ears.
	KinSculptor.ellipsoid(s, Vector3(0.0, 1.575, -0.01), Vector3(0.125, 0.115, 0.115), KinSculptor.one(B.HEAD), KinSculptor.MAT_FUR)
	KinSculptor.ellipsoid(s, Vector3(0.0, 1.55, -0.075), Vector3(0.085, 0.065, 0.06), KinSculptor.one(B.HEAD), KinSculptor.MAT_BELLY)
	KinSculptor.ellipsoid(s, Vector3(0.0, 1.555, -0.132), Vector3(0.018, 0.015, 0.014), KinSculptor.one(B.HEAD), KinSculptor.MAT_HIDE, Vector3.FORWARD, {"ao": 0.3, "g": 0.6})
	KinSculptor.tube(s, [Vector3(-0.03, 1.528, -0.118), Vector3(0.0, 1.522, -0.126), Vector3(0.03, 1.528, -0.118)], [0.004, 0.004, 0.004], [KinSculptor.one(B.HEAD)],
		KinSculptor.MAT_HIDE, {"sides": 5, "extra": {"ao": 0.0}})
	for side: float in [-1.0, 1.0]:
		KinSculptor.eye(s, Vector3(side * 0.048, 1.59, -0.098), 0.03, Vector3(side * 0.35, 0.05, -1.0), KinSculptor.one(B.HEAD), true)
		KinSculptor.brow(s, Vector3(side * 0.02, 1.632, -0.106), Vector3(side * 0.08, 1.625, -0.085), 0.011, KinSculptor.one(B.HEAD), KinSculptor.MAT_FUR_ACCENT)
		var ear: Array = [Vector3(side * 0.1, 1.62, 0.0), Vector3(side * 0.18, 1.63, 0.02), Vector3(side * 0.27, 1.6, 0.04), Vector3(side * 0.33, 1.55, 0.05)]
		KinSculptor.tube(s, ear, [0.035, 0.04, 0.03, 0.006], [KinSculptor.one(B.HEAD)], KinSculptor.MAT_FUR, {"sides": 10, "flat": 0.3, "side": Vector3.UP})
		KinSculptor.tube(s, [ear[1] + Vector3(0.0, 0.0, -0.01), ear[2] + Vector3(0.0, 0.0, -0.01)], [0.024, 0.016], [KinSculptor.one(B.HEAD)], KinSculptor.MAT_BELLY,
			{"sides": 8, "flat": 0.25, "side": Vector3.UP, "extra": {"ao": 0.8}})
	# A sacking scarf.
	KinSculptor.loft(s, [KinSculptor.r(Vector3(0.0, 1.38, 0.0), 0.09, 0.085, KinSculptor.mix2(B.CHEST, B.NECK, 0.5), KinSculptor.MAT_CLOTH),
		KinSculptor.r(Vector3(0.0, 1.42, 0.0), 0.085, 0.08, KinSculptor.one(B.NECK), KinSculptor.MAT_CLOTH)], {"sides": 12, "subdiv": 1})
	KinSculptor.blade(s, Vector3(0.05, 1.38, -0.07), Vector3(0.08, 1.2, -0.12), 0.03, KinSculptor.one(B.CHEST), KinSculptor.MAT_CLOTH, Vector3.FORWARD, 0.01)
	# Thin arms, long fingers; thin legs, big three-toed feet; a tail with a tuft.
	for side: float in [-1.0, 1.0]:
		_arm(s, rig, side, [0.052, 0.043, 0.038], KinSculptor.MAT_FUR)
		_fingers(s, rig, side, 3, 0.065, 0.016, KinSculptor.MAT_FUR, 1.0 if side > 0.0 else 0.0, Vector3(0.026, 0.038, 0.034))
		_leg(s, rig, side, [0.07, 0.052, 0.04], KinSculptor.MAT_FUR)
		var foot: int = B.FOOT_L if side < 0.0 else B.FOOT_R
		var ankle: Vector3 = rig.heads[foot]
		KinSculptor.ellipsoid(s, Vector3(ankle.x, 0.045, -0.03), Vector3(0.05, 0.035, 0.08), KinSculptor.one(foot), KinSculptor.MAT_FUR, Vector3.FORWARD)
		for toe: int in 3:
			var base: Vector3 = Vector3(ankle.x + (float(toe) - 1.0) * 0.028, 0.03, -0.1)
			KinSculptor.cone(s, base, base + Vector3((float(toe) - 1.0) * 0.012, -0.01, -0.035), 0.01, KinSculptor.one(foot), KinSculptor.MAT_HORN)
	KinSculptor.tube(s, [Vector3(0.0, 0.9, 0.12), Vector3(0.0, 0.82, 0.24), Vector3(0.0, 0.66, 0.3), Vector3(0.0, 0.52, 0.27)], [0.025, 0.02, 0.016, 0.012],
		[KinSculptor.one(B.HIPS), KinSculptor.one(B.CLOAK_02), KinSculptor.mix2(B.CLOAK_02, B.CLOAK_03, 0.6), KinSculptor.one(B.CLOAK_03)], KinSculptor.MAT_FUR, {"sides": 8, "cap_start": false})
	KinSculptor.ellipsoid(s, Vector3(0.0, 0.48, 0.26), Vector3(0.035, 0.05, 0.035), KinSculptor.one(B.CLOAK_03), KinSculptor.MAT_EMBER, Vector3.UP)


# --- The Furrow Iron-Men ------------------------------------------------------------

## Plough-iron round a cauldron chest (a grate of coals in its front), a bucket helm
## with ember eye-slits, plough-share shoulders, harrow-tine fingers, stove-pipe legs.
## `pot` scales the cauldron; a flinger is slighter with long rake-hands, a giant
## heavier with a plough-blade on its left arm.
static func _iron_man(s: HeroMeshAtelier.Sculpt, rig: KinRig, pot: float, style: StringName) -> void:
	var rings: Array[Dictionary] = []
	for ring: Array in [[0.82, 0.2, 0.19, B.HIPS, 0.7], [0.92, 0.3, 0.28, B.HIPS, 1.0], [1.08, 0.36, 0.34, B.SPINE, 1.0], [1.24, 0.35, 0.33, B.CHEST, 1.0],
			[1.36, 0.3, 0.28, B.CHEST, 1.0], [1.42, 0.26, 0.24, B.CHEST, 0.8]]:
		rings.append(KinSculptor.r(Vector3(0.0, ring[0], 0.0), float(ring[1]) * pot, float(ring[2]) * pot, KinSculptor.one(ring[3]), KinSculptor.MAT_IRON, {"ao": ring[4]}))
	KinSculptor.loft(s, rings, {"sides": 20, "subdiv": 3, "cap_start": true, "cap_end": true})
	# The pot's rim, two rust-bloomed hoops and a row of rivets.
	KinSculptor.loft(s, [KinSculptor.r(Vector3(0.0, 1.415, 0.0), 0.275 * pot, 0.255 * pot, KinSculptor.one(B.CHEST), KinSculptor.MAT_IRON, {"g": 1.0}),
		KinSculptor.r(Vector3(0.0, 1.45, 0.0), 0.28 * pot, 0.26 * pot, KinSculptor.one(B.CHEST), KinSculptor.MAT_IRON, {"g": 1.0})], {"sides": 20, "subdiv": 1})
	for hoop: Array in [[0.95, 0.305], [1.3, 0.335]]:
		KinSculptor.loft(s, [KinSculptor.r(Vector3(0.0, float(hoop[0]) - 0.025, 0.0), float(hoop[1]) * pot, float(hoop[1]) * pot * 0.95, KinSculptor.one(B.SPINE), KinSculptor.MAT_RUST, {"g": 0.5}),
			KinSculptor.r(Vector3(0.0, float(hoop[0]) + 0.025, 0.0), float(hoop[1]) * pot, float(hoop[1]) * pot * 0.95, KinSculptor.one(B.SPINE), KinSculptor.MAT_RUST, {"g": 0.5})],
			{"sides": 20, "subdiv": 1})
	for index: int in 12:
		var angle: float = TAU * float(index) / 12.0
		var at: Vector3 = Vector3(sin(angle) * 0.362 * pot, 1.12, -cos(angle) * 0.342 * pot)
		KinSculptor.ellipsoid(s, at, Vector3(0.018, 0.018, 0.018), KinSculptor.one(B.SPINE), KinSculptor.MAT_IRON, at - Vector3(0.0, 1.12, 0.0), {"g": 0.9})
	# The grate of coals: the Warmth-Ember glowing behind three iron bars in a rust frame.
	var front: float = -0.345 * pot
	KinSculptor.ellipsoid(s, Vector3(0.0, 1.13, front + 0.005), Vector3(0.12 * pot, 0.085, 0.03), KinSculptor.one(B.SPINE), KinSculptor.MAT_EMBER, Vector3.FORWARD)
	for bar: int in 3:
		var x: float = (float(bar) - 1.0) * 0.05 * pot
		KinSculptor.tube(s, [Vector3(x, 1.215, front - 0.03), Vector3(x, 1.045, front - 0.03)], [0.013, 0.013], [KinSculptor.one(B.SPINE)], KinSculptor.MAT_IRON, {"sides": 6, "extra": {"g": 0.6}})
	KinSculptor.tube(s, [Vector3(-0.13 * pot, 1.04, front - 0.012), Vector3(-0.14 * pot, 1.13, front - 0.018), Vector3(-0.13 * pot, 1.22, front - 0.012),
		Vector3(0.0, 1.235, front - 0.025), Vector3(0.13 * pot, 1.22, front - 0.012), Vector3(0.14 * pot, 1.13, front - 0.018), Vector3(0.13 * pot, 1.04, front - 0.012),
		Vector3(0.0, 1.03, front - 0.025), Vector3(-0.13 * pot, 1.04, front - 0.012)], [0.018, 0.018, 0.018, 0.018, 0.018, 0.018, 0.018, 0.018, 0.018],
		[KinSculptor.one(B.SPINE)], KinSculptor.MAT_RUST, {"sides": 6, "extra": {"g": 0.4}})
	# The bucket helm: ember eye-slits, a rivet brow, a handle over the top.
	KinSculptor.loft(s, [KinSculptor.r(Vector3(0.0, 1.46, -0.01), 0.15, 0.15, KinSculptor.one(B.HEAD), KinSculptor.MAT_IRON, {"ao": 0.7}),
		KinSculptor.r(Vector3(0.0, 1.5, -0.01), 0.165, 0.165, KinSculptor.one(B.HEAD), KinSculptor.MAT_IRON),
		KinSculptor.r(Vector3(0.0, 1.72, -0.01), 0.15, 0.15, KinSculptor.one(B.HEAD), KinSculptor.MAT_IRON),
		KinSculptor.r(Vector3(0.0, 1.76, -0.01), 0.158, 0.158, KinSculptor.one(B.HEAD), KinSculptor.MAT_IRON, {"g": 1.0})], {"sides": 18, "subdiv": 2, "cap_end": true})
	for side: float in [-1.0, 1.0]:
		KinSculptor.eye(s, Vector3(side * 0.062, 1.615, -0.158), 0.034, Vector3(side * 0.25, 0.0, -1.0), KinSculptor.one(B.HEAD), true, 0.4)
	KinSculptor.tube(s, [Vector3(-0.12, 1.67, -0.148), Vector3(0.0, 1.66, -0.162), Vector3(0.12, 1.67, -0.148)], [0.016, 0.018, 0.016], [KinSculptor.one(B.HEAD)], KinSculptor.MAT_RUST, {"sides": 6})
	for side: float in [-1.0, 1.0]:
		KinSculptor.ellipsoid(s, Vector3(side * 0.12, 1.672, -0.152), Vector3(0.014, 0.014, 0.014), KinSculptor.one(B.HEAD), KinSculptor.MAT_IRON, Vector3.FORWARD, {"g": 1.0})
	KinSculptor.tube(s, [Vector3(-0.155, 1.74, -0.01), Vector3(-0.11, 1.86, -0.01), Vector3(0.0, 1.91, -0.01), Vector3(0.11, 1.86, -0.01), Vector3(0.155, 1.74, -0.01)],
		[0.011, 0.011, 0.011, 0.011, 0.011], [KinSculptor.one(B.HEAD)], KinSculptor.MAT_BRASS, {"sides": 6, "extra": {"g": 0.6}})
	# Furrow moss grown into its seams and over the rim's back.
	for patch: Array in [[Vector3(-0.2, 0.9, -0.16), Vector3(0.07, 0.025, 0.05)], [Vector3(0.12, 1.44, 0.2), Vector3(0.1, 0.035, 0.07)],
			[Vector3(-0.14, 1.43, 0.17), Vector3(0.07, 0.03, 0.05)], [Vector3(0.24, 0.97, 0.12), Vector3(0.06, 0.025, 0.05)]]:
		var at: Vector3 = (patch[0] as Vector3) * Vector3(pot, 1.0, pot)
		KinSculptor.ellipsoid(s, at, patch[1], KinSculptor.one(B.HIPS if at.y < 1.2 else B.CHEST), KinSculptor.MAT_MOSS, Vector3.FORWARD)
	# Plough-share shoulders.
	for side: float in [-1.0, 1.0]:
		var top: Vector3 = Vector3(side * 0.3 * maxf(pot, 0.9), 1.44, 0.0)
		KinSculptor.ellipsoid(s, top, Vector3(0.17, 0.075, 0.2), KinSculptor.mix2(B.CLAVICLE_L if side < 0.0 else B.CLAVICLE_R, B.UPPER_ARM_L if side < 0.0 else B.UPPER_ARM_R, 0.6),
			KinSculptor.MAT_IRON, Vector3.RIGHT, {"g": 0.4})
		KinSculptor.ellipsoid(s, top + Vector3(side * 0.06, -0.035, 0.0), Vector3(0.14, 0.04, 0.17), KinSculptor.one(B.UPPER_ARM_L if side < 0.0 else B.UPPER_ARM_R),
			KinSculptor.MAT_RUST, Vector3.RIGHT)
	# Arms of iron pipe, rusty elbow-balls, big hands with harrow-tine fingers.
	var arm_r: float = 0.07 if style == &"flinger" else 0.095
	for side: float in [-1.0, 1.0]:
		_arm(s, rig, side, [arm_r, arm_r * 0.85, arm_r * 1.05], KinSculptor.MAT_IRON)
		KinSculptor.ellipsoid(s, rig.heads[B.FOREARM_L if side < 0.0 else B.FOREARM_R], Vector3.ONE * arm_r * 1.05, KinSculptor.one(B.FOREARM_L if side < 0.0 else B.FOREARM_R), KinSculptor.MAT_RUST)
		var tines: float = 0.15 if style == &"flinger" else 0.11
		_fingers(s, rig, side, 3, tines, 0.026, KinSculptor.MAT_IRON, 1.0, Vector3(0.06, 0.075, 0.07))
	if style == &"giant":
		var fore: int = B.FOREARM_L
		var at: Vector3 = rig.middle_of(fore) + Vector3(-0.1, 0.0, -0.02)
		KinSculptor.ellipsoid(s, at, Vector3(0.03, 0.26, 0.18), KinSculptor.one(fore), KinSculptor.MAT_IRON, Vector3.UP, {"g": 0.7})
		KinSculptor.cone(s, at + Vector3(0.0, -0.22, -0.1), at + Vector3(0.0, -0.4, -0.26), 0.06, KinSculptor.one(fore), KinSculptor.MAT_RUST)
	# Stove-pipe legs on plough-share boots.
	for side: float in [-1.0, 1.0]:
		_leg(s, rig, side, [0.12, 0.105, 0.1], KinSculptor.MAT_IRON)
		var shin: int = B.SHIN_L if side < 0.0 else B.SHIN_R
		KinSculptor.ellipsoid(s, rig.heads[shin], Vector3.ONE * 0.11, KinSculptor.one(shin), KinSculptor.MAT_RUST)
		var foot: int = B.FOOT_L if side < 0.0 else B.FOOT_R
		var ankle: Vector3 = rig.heads[foot]
		KinSculptor.ellipsoid(s, Vector3(ankle.x, 0.07, -0.05), Vector3(0.12, 0.07, 0.17), KinSculptor.one(foot), KinSculptor.MAT_IRON, Vector3.FORWARD, {"g": 0.4})
		KinSculptor.ellipsoid(s, Vector3(ankle.x, 0.02, -0.05), Vector3(0.13, 0.025, 0.18), KinSculptor.one(foot), KinSculptor.MAT_RUST, Vector3.FORWARD)
		KinSculptor.ellipsoid(s, Vector3(ankle.x + side * 0.06, 0.12, -0.14), Vector3(0.05, 0.02, 0.04), KinSculptor.one(foot), KinSculptor.MAT_MOSS)


# --- The Tide-Wight ------------------------------------------------------------------

## Sea-fret given a hooded shape: a robe that thins to wisps above the ground (no feet),
## long thin arms in dagged sleeves, lantern eyes in the hood's dark, kelp at the shoulders.
static func _tide_wight(s: HeroMeshAtelier.Sculpt, rig: KinRig) -> void:
	var dag: Callable = func(theta: float, t: float) -> float:
		return 1.0 + smoothstep(0.65, 1.0, t) * 0.14 * sin(theta * 7.0 + 0.6)
	KinSculptor.loft(s, [
		KinSculptor.r(Vector3(0.0, 1.43, 0.0), 0.12, 0.11, KinSculptor.mix2(B.CHEST, B.NECK, 0.5), KinSculptor.MAT_MIST),
		KinSculptor.r(Vector3(0.0, 1.32, 0.01), 0.22, 0.16, KinSculptor.one(B.CHEST), KinSculptor.MAT_MIST),
		KinSculptor.r(Vector3(0.0, 1.12, 0.02), 0.23, 0.17, KinSculptor.mix2(B.SPINE, B.CHEST, 0.5), KinSculptor.MAT_MIST),
		KinSculptor.r(Vector3(0.0, 0.9, 0.03), 0.26, 0.2, KinSculptor.one(B.HIPS), KinSculptor.MAT_MIST),
		KinSculptor.r(Vector3(0.0, 0.6, 0.05), 0.31, 0.25, KinSculptor.mix2(B.HIPS, B.CLOAK_02, 0.4), KinSculptor.MAT_MIST),
		KinSculptor.r(Vector3(0.0, 0.3, 0.07), 0.35, 0.29, KinSculptor.mix2(B.HIPS, B.CLOAK_03, 0.6), KinSculptor.MAT_MIST),
		KinSculptor.r(Vector3(0.0, 0.02, 0.09), 0.37, 0.31, KinSculptor.one(B.CLOAK_03), KinSculptor.MAT_MIST, {"ao": 0.7}),
	], {"sides": 18, "subdiv": 3, "cap_start": false, "cap_end": false, "radius_fn": dag})
	# The hood: a deep cowl, its opening dark, two lantern eyes in it, barnacles on its edge.
	KinSculptor.loft(s, [
		KinSculptor.r(Vector3(0.0, 1.4, 0.03), 0.16, 0.16, KinSculptor.one(B.NECK), KinSculptor.MAT_MIST),
		KinSculptor.r(Vector3(0.0, 1.52, 0.02), 0.175, 0.175, KinSculptor.one(B.HEAD), KinSculptor.MAT_MIST),
		KinSculptor.r(Vector3(0.0, 1.68, 0.035), 0.15, 0.155, KinSculptor.one(B.HEAD), KinSculptor.MAT_MIST),
		KinSculptor.r(Vector3(0.0, 1.79, 0.08), 0.08, 0.09, KinSculptor.one(B.HEAD), KinSculptor.MAT_MIST),
		KinSculptor.r(Vector3(0.0, 1.85, 0.15), 0.02, 0.02, KinSculptor.one(B.HEAD), KinSculptor.MAT_MIST),
	], {"sides": 16, "subdiv": 2, "cap_start": true, "cap_end": true})
	KinSculptor.ellipsoid(s, Vector3(0.0, 1.585, -0.12), Vector3(0.11, 0.13, 0.05), KinSculptor.one(B.HEAD), KinSculptor.MAT_CLOTH, Vector3.FORWARD, {"ao": 0.05})
	KinSculptor.tube(s, [Vector3(-0.12, 1.47, -0.1), Vector3(-0.13, 1.6, -0.13), Vector3(0.0, 1.72, -0.15), Vector3(0.13, 1.6, -0.13), Vector3(0.12, 1.47, -0.1)],
		[0.03, 0.03, 0.03, 0.03, 0.03], [KinSculptor.one(B.HEAD)], KinSculptor.MAT_MIST, {"sides": 8, "extra": {"g": 0.5}})
	for side: float in [-1.0, 1.0]:
		KinSculptor.eye(s, Vector3(side * 0.045, 1.6, -0.15), 0.026, Vector3(side * 0.2, 0.0, -1.0), KinSculptor.one(B.HEAD), true, 0.5)
	for index: int in 3:
		var at: Vector3 = Vector3(-0.1 + index * 0.08, 1.72 - absf(float(index) - 1.0) * 0.05, -0.13)
		KinSculptor.tube(s, [at, at + Vector3(0.0, 0.0, -0.025)], [0.018, 0.011], [KinSculptor.one(B.HEAD)], KinSculptor.MAT_BARNACLE, {"sides": 6, "tip_extra": {"ao": 0.05}})
	KinSculptor.ellipsoid(s, Vector3(0.0, 1.38, -0.12), Vector3(0.04, 0.045, 0.02), KinSculptor.one(B.CHEST), KinSculptor.MAT_SHELL, Vector3.FORWARD, {"g": 0.8})
	# Kelp hanging from the shoulders.
	for side: float in [-1.0, 1.0]:
		for index: int in 4:
			var top: Vector3 = Vector3(side * (0.1 + index * 0.04), 1.4 - index * 0.015, -0.05 + index * 0.05)
			KinSculptor.blade(s, top, top + Vector3(side * 0.04, -0.55 - index * 0.08, -0.02), 0.03, KinSculptor.mix2(B.CHEST, B.CLOAK_01, 0.3), KinSculptor.MAT_LEAF, Vector3.FORWARD, 0.006)
	# Long thin arms in dagged sleeves, pale cold hands.
	for side: float in [-1.0, 1.0]:
		_arm(s, rig, side, [0.065, 0.06, 0.075], KinSculptor.MAT_MIST)
		var fore: int = B.FOREARM_L if side < 0.0 else B.FOREARM_R
		var hand: int = B.HAND_L if side < 0.0 else B.HAND_R
		var wrist: Vector3 = rig.heads[hand]
		KinSculptor.tube(s, [wrist + Vector3.UP * 0.06, wrist + Vector3.DOWN * 0.02], [0.08, 0.1], [KinSculptor.one(fore)], KinSculptor.MAT_MIST,
			{"sides": 12, "cap_start": false, "cap_end": false, "radius_fn": func(theta: float, t: float) -> float: return 1.0 + t * 0.2 * sin(theta * 5.0)})
		_fingers(s, rig, side, 3, 0.11, 0.012, KinSculptor.MAT_HIDE, 1.0 if side > 0.0 else 0.0, Vector3(0.03, 0.045, 0.035))


# --- The Crag-Spriggan ---------------------------------------------------------------

## A squat stone-guard: a boulder of a body, a stone face with glowing eyes, a moss
## cloak, boulder fists, a round stone shield on its left arm and a little brass bell.
static func _spriggan(s: HeroMeshAtelier.Sculpt, rig: KinRig) -> void:
	KinSculptor.loft(s, [
		KinSculptor.r(Vector3(0.0, 0.8, 0.0), 0.22, 0.2, KinSculptor.one(B.HIPS), KinSculptor.MAT_STONE, {"ao": 0.7}),
		KinSculptor.r(Vector3(0.0, 0.94, -0.02), 0.31, 0.27, KinSculptor.one(B.HIPS), KinSculptor.MAT_STONE),
		KinSculptor.r(Vector3(0.0, 1.14, -0.03), 0.35, 0.29, KinSculptor.mix2(B.SPINE, B.CHEST, 0.4), KinSculptor.MAT_STONE),
		KinSculptor.r(Vector3(0.0, 1.32, -0.02), 0.33, 0.26, KinSculptor.one(B.CHEST), KinSculptor.MAT_STONE),
		KinSculptor.r(Vector3(0.0, 1.42, 0.0), 0.22, 0.18, KinSculptor.mix2(B.CHEST, B.NECK, 0.5), KinSculptor.MAT_STONE, {"ao": 0.8}),
	], {"sides": 12, "subdiv": 2, "cap_start": true, "cap_end": true, "n": 2.6})
	KinSculptor.ellipsoid(s, Vector3(0.0, 1.52, -0.05), Vector3(0.15, 0.135, 0.14), KinSculptor.one(B.HEAD), KinSculptor.MAT_STONE, Vector3.UP, {}, {"sides": 8})
	for side: float in [-1.0, 1.0]:
		KinSculptor.eye(s, Vector3(side * 0.055, 1.54, -0.175), 0.03, Vector3(side * 0.3, 0.0, -1.0), KinSculptor.one(B.HEAD), true, 0.45)
		KinSculptor.brow(s, Vector3(side * 0.02, 1.585, -0.18), Vector3(side * 0.12, 1.575, -0.14), 0.03, KinSculptor.one(B.HEAD), KinSculptor.MAT_STONE)
	KinSculptor.ellipsoid(s, Vector3(0.0, 1.66, -0.02), Vector3(0.12, 0.04, 0.1), KinSculptor.one(B.HEAD), KinSculptor.MAT_MOSS)
	# The moss cloak over the shoulders and down the back.
	KinSculptor.loft(s, [
		KinSculptor.r(Vector3(0.0, 1.46, 0.02), 0.3, 0.22, KinSculptor.one(B.CHEST), KinSculptor.MAT_MOSS),
		KinSculptor.r(Vector3(0.0, 1.38, 0.1), 0.36, 0.2, KinSculptor.one(B.CLOAK_01), KinSculptor.MAT_MOSS),
		KinSculptor.r(Vector3(0.0, 1.06, 0.2), 0.36, 0.14, KinSculptor.one(B.CLOAK_02), KinSculptor.MAT_MOSS),
		KinSculptor.r(Vector3(0.0, 0.72, 0.24), 0.34, 0.1, KinSculptor.one(B.CLOAK_03), KinSculptor.MAT_MOSS, {"ao": 0.7}),
	], {"sides": 14, "subdiv": 2, "cap_start": false, "cap_end": true, "radius_fn": func(theta: float, t: float) -> float: return 1.0 + t * 0.1 * sin(theta * 6.0)})
	for side: float in [-1.0, 1.0]:
		_arm(s, rig, side, [0.1, 0.09, 0.09], KinSculptor.MAT_STONE)
		var hand: int = B.HAND_L if side < 0.0 else B.HAND_R
		KinSculptor.ellipsoid(s, rig.heads[hand].lerp(rig.tail_of(hand), 0.4), Vector3(0.11, 0.12, 0.1), KinSculptor.one(hand), KinSculptor.MAT_STONE, Vector3.UP,
			{"a": 1.0 if side > 0.0 else 0.0}, {"sides": 8})
		_leg(s, rig, side, [0.13, 0.12, 0.11], KinSculptor.MAT_STONE)
		var foot: int = B.FOOT_L if side < 0.0 else B.FOOT_R
		KinSculptor.ellipsoid(s, Vector3(rig.heads[foot].x, 0.06, -0.04), Vector3(0.12, 0.06, 0.16), KinSculptor.one(foot), KinSculptor.MAT_STONE, Vector3.FORWARD, {}, {"sides": 8})
	# The round shield on the left forearm, moss round its rim, a brass boss.
	var fore: int = B.FOREARM_L
	var at: Vector3 = rig.middle_of(fore) + Vector3(-0.13, 0.0, -0.04)
	KinSculptor.loft(s, [KinSculptor.r(at + Vector3(0.04, 0.0, 0.0), 0.25, 0.25, KinSculptor.one(fore), KinSculptor.MAT_STONE, {"ao": 0.7}),
		KinSculptor.r(at, 0.27, 0.27, KinSculptor.one(fore), KinSculptor.MAT_STONE, {"g": 0.6}),
		KinSculptor.r(at + Vector3(-0.04, 0.0, 0.0), 0.22, 0.22, KinSculptor.one(fore), KinSculptor.MAT_STONE)], {"sides": 14, "subdiv": 1, "side": Vector3.FORWARD, "cap_start": true, "cap_end": true})
	KinSculptor.ellipsoid(s, at + Vector3(-0.055, 0.0, 0.0), Vector3(0.05, 0.07, 0.07), KinSculptor.one(fore), KinSculptor.MAT_BRASS, Vector3.RIGHT, {"g": 0.9})
	for index: int in 5:
		var angle: float = TAU * float(index) / 5.0 + 0.4
		KinSculptor.ellipsoid(s, at + Vector3(-0.03, sin(angle) * 0.24, cos(angle) * 0.24), Vector3(0.03, 0.06, 0.06), KinSculptor.one(fore), KinSculptor.MAT_MOSS, Vector3.RIGHT)
	KinSculptor.tube(s, [Vector3(0.18, 0.92, -0.18), Vector3(0.2, 0.84, -0.2), Vector3(0.2, 0.76, -0.2), Vector3(0.2, 0.74, -0.2)], [0.02, 0.04, 0.06, 0.06],
		[KinSculptor.one(B.HIPS)], KinSculptor.MAT_BRASS, {"sides": 10, "cap_end": false, "extra": {"g": 0.4}})


# --- The Bog-Hulk Boggart ---------------------------------------------------------------

## A hunched peat-and-moss giant: vast shoulders, a small head low and forward with
## bog-light eyes, long arms ending in bark-knuckled fists, reeds and roots on its back.
static func _bog_hulk(s: HeroMeshAtelier.Sculpt, rig: KinRig) -> void:
	KinSculptor.loft(s, [
		KinSculptor.r(Vector3(0.0, 0.84, 0.06), 0.24, 0.22, KinSculptor.one(B.HIPS), KinSculptor.MAT_MOSS, {"ao": 0.7}),
		KinSculptor.r(Vector3(0.0, 0.94, 0.04), 0.3, 0.26, KinSculptor.one(B.HIPS), KinSculptor.MAT_MOSS),
		KinSculptor.r(Vector3(0.0, 1.1, -0.01), 0.38, 0.31, KinSculptor.one(B.SPINE), KinSculptor.MAT_MOSS),
		KinSculptor.r(Vector3(0.0, 1.28, -0.04), 0.46, 0.35, KinSculptor.one(B.CHEST), KinSculptor.MAT_MOSS),
		KinSculptor.r(Vector3(0.0, 1.42, -0.02), 0.44, 0.32, KinSculptor.one(B.CHEST), KinSculptor.MAT_MOSS),
		KinSculptor.r(Vector3(0.0, 1.5, 0.02), 0.26, 0.22, KinSculptor.mix2(B.CHEST, B.NECK, 0.5), KinSculptor.MAT_MOSS, {"ao": 0.8}),
	], {"sides": 16, "subdiv": 3, "cap_start": true, "cap_end": true, "radius_fn": func(theta: float, t: float) -> float:
		return 1.0 + 0.05 * sin(theta * 5.0 + t * 9.0)})
	# Peat and bark showing through the moss.
	for patch: Array in [[Vector3(0.22, 1.2, -0.3), Vector3(0.12, 0.1, 0.05)], [Vector3(-0.28, 1.06, -0.22), Vector3(0.1, 0.12, 0.05)],
			[Vector3(0.08, 0.96, -0.27), Vector3(0.1, 0.07, 0.04)], [Vector3(-0.1, 1.36, 0.3), Vector3(0.14, 0.1, 0.05)]]:
		var at: Vector3 = patch[0]
		KinSculptor.ellipsoid(s, at, patch[1], KinSculptor.one(B.SPINE if at.y < 1.2 else B.CHEST), KinSculptor.MAT_BARK, Vector3(at.x, 0.0, at.z), {"g": 0.4})
	# The small head, low and forward between the shoulders.
	KinSculptor.ellipsoid(s, Vector3(0.0, 1.5, -0.2), Vector3(0.14, 0.13, 0.14), KinSculptor.one(B.HEAD), KinSculptor.MAT_BARK)
	KinSculptor.ellipsoid(s, Vector3(0.0, 1.43, -0.27), Vector3(0.11, 0.06, 0.08), KinSculptor.one(B.JAW_BEARD), KinSculptor.MAT_MOSS)
	for side: float in [-1.0, 1.0]:
		KinSculptor.eye(s, Vector3(side * 0.055, 1.53, -0.32), 0.03, Vector3(side * 0.35, 0.05, -1.0), KinSculptor.one(B.HEAD), true, 0.5)
		KinSculptor.brow(s, Vector3(side * 0.02, 1.575, -0.33), Vector3(side * 0.11, 1.57, -0.29), 0.025, KinSculptor.one(B.HEAD), KinSculptor.MAT_MOSS)
	# Reeds and bulrushes up its back, bent by the wind; roots hanging off it.
	for index: int in 5:
		var base: Vector3 = Vector3(sin(index * 1.9) * 0.24, 1.36 + float(index % 3) * 0.04, 0.2 + float(index % 2) * 0.05)
		var lean: Vector3 = Vector3(sin(index * 1.9) * 0.12, 0.0, 0.1 + float(index % 2) * 0.06)
		var tall: float = 0.32 + float(index % 3) * 0.08
		var points: Array = [base, base + Vector3.UP * tall * 0.5 + lean * 0.3, base + Vector3.UP * tall + lean]
		KinSculptor.tube(s, points, [0.014, 0.011, 0.007], [KinSculptor.one(B.CHEST)], KinSculptor.MAT_LEAF, {"sides": 5})
		if index % 2 == 0:
			KinSculptor.ellipsoid(s, base + Vector3.UP * tall * 0.86 + lean * 0.8, Vector3(0.022, 0.06, 0.022), KinSculptor.one(B.CHEST), KinSculptor.MAT_BARK, points[2] - points[1])
		else:
			KinSculptor.blade(s, points[1], points[1] + Vector3(lean.x * 2.0, 0.12, lean.z * 2.0 + 0.1), 0.02, KinSculptor.one(B.CHEST), KinSculptor.MAT_LEAF, Vector3.FORWARD, 0.006)
	for index: int in 4:
		var top: Vector3 = Vector3((float(index) - 1.5) * 0.2, 0.92, 0.2)
		KinSculptor.tube(s, [top, top + Vector3(0.02, -0.18, 0.05), top + Vector3(0.05, -0.36, 0.04)], [0.02, 0.014, 0.005], [KinSculptor.one(B.HIPS)], KinSculptor.MAT_THORN, {"sides": 5})
	# Great long arms, fists of bark-knuckled peat to the ground; short thick legs.
	for side: float in [-1.0, 1.0]:
		_arm(s, rig, side, [0.15, 0.14, 0.15], KinSculptor.MAT_MOSS)
		var hand: int = B.HAND_L if side < 0.0 else B.HAND_R
		var fist: Vector3 = rig.tail_of(hand) + Vector3(0.0, -0.06, 0.0)
		KinSculptor.tube(s, [rig.heads[hand], fist], [0.15, 0.17], [KinSculptor.mix2(B.FOREARM_L if side < 0.0 else B.FOREARM_R, hand, 0.6), KinSculptor.one(hand)], KinSculptor.MAT_MOSS,
			{"sides": 12, "cap_start": false})
		KinSculptor.ellipsoid(s, fist + Vector3(0.0, -0.06, -0.02), Vector3(0.17, 0.13, 0.17), KinSculptor.one(hand), KinSculptor.MAT_BARK, Vector3.UP, {"a": 1.0, "g": 0.4})
		_leg(s, rig, side, [0.16, 0.14, 0.13], KinSculptor.MAT_MOSS)
		var foot: int = B.FOOT_L if side < 0.0 else B.FOOT_R
		KinSculptor.ellipsoid(s, Vector3(rig.heads[foot].x, 0.06, -0.04), Vector3(0.14, 0.065, 0.18), KinSculptor.one(foot), KinSculptor.MAT_BARK, Vector3.FORWARD)
