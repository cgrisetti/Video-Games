## Sculpts the kin in code (docs/30_KIN_DESIGN_LANGUAGE.md §3, §6) with the heroes'
## own loft engine (HeroMeshAtelier: superellipse rings along Catmull-Rom spines,
## skinned with up to four bone weights a ring), so a kin is one continuous,
## bending figure like a hero, not a pile of spheres. A kin is one skinned
## surface in one material (storybook_kin_atelier.gdshader) with the ink line as
## its next pass. Each vertex colour says what it is (r AO, g worn edge, b the
## material id below, a the striking part's Sign vein); UV2.x is its height at rest.
## The four families' sculpts live beside it: KinSculptBeasts (four legs),
## KinSculptCrawlers (six), KinSculptFolk (two, on the heroes' skeleton) and
## KinSculptGrowths (stalks and mounds). Identical looks share one mesh.
class_name KinSculptor
extends RefCounted

# Material ids (COLOR.b), in the kin shader's bands.
const MAT_FUR: float = 0.03
const MAT_FUR_ACCENT: float = 0.08
const MAT_HIDE: float = 0.13
const MAT_BELLY: float = 0.18
const MAT_BARK: float = 0.24
const MAT_MOSS: float = 0.28
const MAT_HORN: float = 0.33
const MAT_THORN: float = 0.37
const MAT_SHELL: float = 0.42
const MAT_BARNACLE: float = 0.46
const MAT_IRON: float = 0.51
const MAT_RUST: float = 0.55
const MAT_BRASS: float = 0.59
const MAT_STONE: float = 0.64
const MAT_CLOTH: float = 0.69
const MAT_MIST: float = 0.73
const MAT_SAP: float = 0.78
const MAT_EMBER: float = 0.83
const MAT_PETAL: float = 0.875
const MAT_LEAF: float = 0.905
const MAT_EYE: float = 0.94
const MAT_GLOW_EYE: float = 0.975
const SHADER: Shader = preload("res://src/actors/shaders/storybook_kin_atelier.gdshader")
## Sea-fret dissolves into wisps below this share of a kin's height (the shader's mist_fade_height).
const MIST_FADE_HEIGHT: float = 0.22

static var _meshes: Dictionary[StringName, ArrayMesh] = {}
static var _rigs: Dictionary[StringName, KinRig] = {}
static var _inks: Dictionary[StringName, ShaderMaterial] = {}


## The look's rig at its sculpted size (shared by every kin wearing it).
static func rig(look: StringName) -> KinRig:
	if not _rigs.has(look):
		_rigs[look] = KinRigBuilder.build(KinLooks.spec(look)["frame"])
	return _rigs[look]


## The look's one skinned surface (shared by every kin wearing it).
static func mesh(look: StringName) -> ArrayMesh:
	if _meshes.has(look):
		return _meshes[look]
	var r: KinRig = rig(look)
	var s: HeroMeshAtelier.Sculpt = HeroMeshAtelier.Sculpt.new(true)
	match KinLooks.rig_of(look):
		KinRigBuilder.Rig.QUADRUPED:
			KinSculptBeasts.sculpt(s, r, look)
		KinRigBuilder.Rig.HEXAPOD:
			KinSculptCrawlers.sculpt(s, r, look)
		KinRigBuilder.Rig.BIPED:
			KinSculptFolk.sculpt(s, r, look)
		_:
			KinSculptGrowths.sculpt(s, r, look)
	var made: ArrayMesh = s.commit(StringName("kin_" + String(look)))
	_meshes[look] = made
	return made


## A kin's material: the shader in the variant's three colours and its look's palette, the ink line after it.
static func material(variant: MobVariantResource, look: StringName) -> ShaderMaterial:
	var made: ShaderMaterial = ShaderMaterial.new()
	made.shader = SHADER
	var info: Dictionary = KinLooks.spec(look)
	made.set_shader_parameter(&"main_color", variant.main_color)
	made.set_shader_parameter(&"accent_color", variant.accent_color)
	made.set_shader_parameter(&"eye_color", variant.eye_color)
	made.set_shader_parameter(&"figure_height", float(info["height"]))
	# What the look itself is made of, then the variant's colours where the look takes them.
	var palette: Dictionary = info["palette"]
	for key: Variant in palette:
		made.set_shader_parameter(StringName(key), palette[key])
	match look:
		KinLooks.WEEVIL:
			made.set_shader_parameter(&"bark_color", variant.main_color)
		KinLooks.ASH_GRIG:
			made.set_shader_parameter(&"ember_color", variant.accent_color)
		KinLooks.IRON_MAN, KinLooks.IRON_FLINGER, KinLooks.IRON_GIANT:
			made.set_shader_parameter(&"iron_color", variant.main_color)
			made.set_shader_parameter(&"rust_color", variant.accent_color.darkened(0.35))
			made.set_shader_parameter(&"brass_color", variant.accent_color)
			made.set_shader_parameter(&"ember_color", variant.eye_color)
		KinLooks.TIDE_WIGHT:
			made.set_shader_parameter(&"mist_color", variant.main_color)
		KinLooks.SPRIGGAN:
			made.set_shader_parameter(&"stone_color", variant.main_color)
		KinLooks.ROOT_LURKER:
			made.set_shader_parameter(&"bark_color", variant.main_color)
		KinLooks.BRAMBLE_LASHER:
			made.set_shader_parameter(&"petal_color", variant.accent_color.lightened(0.35))
			made.set_shader_parameter(&"thorn_color", variant.main_color.darkened(0.25))
		KinLooks.SAP_BOGGART:
			made.set_shader_parameter(&"sap_color", variant.main_color)
		KinLooks.TAPROOT_STAG:
			made.set_shader_parameter(&"moss_color", variant.accent_color.darkened(0.2))
		KinLooks.BOG_HULK:
			made.set_shader_parameter(&"moss_color", variant.main_color)
			made.set_shader_parameter(&"bark_color", variant.accent_color.darkened(0.2))
	made.set_shader_parameter(&"rim_color", variant.eye_color.lerp(Color(1.0, 0.9, 0.7), 0.5))
	made.set_shader_parameter(&"rim_strength", StorybookMaterial.ACTOR_RIM * 0.8)
	made.next_pass = ink_for(look)
	return made


## The ink line a look wears: everyone's, or for sea-fret kin one that leaves the wisps at its hem unlined.
static func ink_for(look: StringName) -> ShaderMaterial:
	if look != KinLooks.TIDE_WIGHT:
		return HeroMeshAtelier.ink_material()
	if not _inks.has(look):
		var ink: ShaderMaterial = HeroMeshAtelier.ink_material().duplicate() as ShaderMaterial
		ink.set_shader_parameter(&"mist_cut", float(KinLooks.spec(look)["height"]) * MIST_FADE_HEIGHT)
		_inks[look] = ink
	return _inks[look]


# --- The toolkit ------------------------------------------------------------------

## A ring (HeroMeshAtelier._r): centre, half-width, half-depth, bone weights, material.
static func r(c: Vector3, w: float, d: float, bones: Dictionary, m: float, extra: Dictionary = {}) -> Dictionary:
	return HeroMeshAtelier._r(c, w, d, bones, m, extra)


static func loft(s: HeroMeshAtelier.Sculpt, rings: Array[Dictionary], options: Dictionary = {}) -> void:
	HeroMeshAtelier._loft(s, rings, options)


static func ellipsoid(s: HeroMeshAtelier.Sculpt, center: Vector3, half: Vector3, bones: Dictionary, m: float, axis: Vector3 = Vector3.FORWARD,
		extra: Dictionary = {}, options: Dictionary = {}) -> void:
	HeroMeshAtelier._ellipsoid(s, center, half, bones, m, axis, extra, options)


## One bone's full weight.
static func one(bone: int) -> Dictionary:
	return {bone: 1.0}


## Two bones blended: `u` 0 all `a`, 1 all `b`.
static func mix2(a: int, b: int, u: float) -> Dictionary:
	if a == b:
		return {a: 1.0}
	return {a: 1.0 - u, b: u}


## A tapering tube through `points`, `radii` at each, skinned to `bones` at each
## (Dictionaries), in material `m`. Options as HeroMeshAtelier._loft, plus "flat"
## (depth over width) and "extra" (ring extras) and "tip_extra" (the last ring's).
static func tube(s: HeroMeshAtelier.Sculpt, points: Array, radii: Array, bones: Array, m: float, options: Dictionary = {}) -> void:
	var flat: float = options.get("flat", 1.0)
	var extra: Dictionary = options.get("extra", {})
	var rings: Array[Dictionary] = []
	for index: int in points.size():
		var ring_extra: Dictionary = extra.duplicate()
		if index == points.size() - 1 and options.has("tip_extra"):
			ring_extra.merge(options["tip_extra"], true)
		var radius: float = float(radii[index])
		rings.append(r(points[index], radius, radius * flat, bones[mini(index, bones.size() - 1)], m, ring_extra))
	var loft_options: Dictionary = {"sides": options.get("sides", 10), "subdiv": options.get("subdiv", 2), "cap_start": options.get("cap_start", true),
		"cap_end": options.get("cap_end", true)}
	for key: String in ["side", "section", "radius_fn", "offset_fn", "color_fn", "weight_at", "proxy"]:
		if options.has(key):
			loft_options[key] = options[key]
	loft(s, rings, loft_options)


## A horn, claw, thorn or tusk from `base` to `tip`, bowed by `bend` at its middle.
static func cone(s: HeroMeshAtelier.Sculpt, base: Vector3, tip: Vector3, radius: float, bones: Dictionary, m: float, bend: Vector3 = Vector3.ZERO,
		sides: int = 6, vein: float = 0.0) -> void:
	var mid: Vector3 = base.lerp(tip, 0.5) + bend
	var points: Array = [base, base.lerp(mid, 0.6), mid, mid.lerp(tip, 0.55), tip]
	var radii: Array = [radius, radius * 0.82, radius * 0.58, radius * 0.32, radius * 0.06]
	tube(s, points, radii, [bones], m, {"sides": sides, "subdiv": 1, "cap_end": false, "extra": {"ao": 0.75, "a": vein},
		"tip_extra": {"g": 1.0, "ao": 1.0}})


## A flat leaf or petal from `base` toward `tip`, `half_w` wide, lying across `across`.
static func blade(s: HeroMeshAtelier.Sculpt, base: Vector3, tip: Vector3, half_w: float, bones: Dictionary, m: float, across: Vector3 = Vector3.RIGHT,
		thick: float = 0.012) -> void:
	var points: Array = [base, base.lerp(tip, 0.3), base.lerp(tip, 0.65), tip]
	var widths: Array = [half_w * 0.25, half_w, half_w * 0.8, half_w * 0.08]
	var rings: Array[Dictionary] = []
	for index: int in points.size():
		rings.append(r(points[index], float(widths[index]), thick, bones, m, {"n": 2.0, "g": 0.6 if index == points.size() - 1 else 0.0}))
	loft(s, rings, {"sides": 8, "subdiv": 2, "cap_start": true, "cap_end": true, "side": across})


## A dog-rose (or any five-petalled bloom) facing `facing`: a grey bud until the calm opens it.
static func rose(s: HeroMeshAtelier.Sculpt, center: Vector3, size: float, facing: Vector3, bones: Dictionary, petals: int = 5) -> void:
	var f: Vector3 = facing.normalized()
	var side: Vector3 = f.cross(Vector3.UP if absf(f.y) < 0.9 else Vector3.RIGHT).normalized()
	var up: Vector3 = side.cross(f).normalized()
	for index: int in petals:
		var angle: float = TAU * float(index) / float(petals)
		var out: Vector3 = (side * cos(angle) + up * sin(angle)).normalized()
		blade(s, center + out * size * 0.15, center + out * size + f * size * 0.18, size * 0.42, bones, MAT_PETAL, out.cross(f).normalized(), size * 0.07)
	ellipsoid(s, center + f * size * 0.12, Vector3.ONE * size * 0.22, bones, MAT_LEAF, f, {"g": 1.0})


## An eye: a lens-shaped bulge of radius `radius` looking along `facing`, its
## vertices' UVs its own frame (-1..1 across and up) for the iris, pupil and lid.
static func eye(s: HeroMeshAtelier.Sculpt, center: Vector3, radius: float, facing: Vector3, bones: Dictionary, glows: bool, bulge: float = 0.62) -> void:
	var f: Vector3 = facing.normalized()
	var right: Vector3 = Vector3.UP.cross(f).normalized() if absf(f.y) < 0.95 else Vector3.RIGHT
	if right.length_squared() < 0.5:
		right = Vector3.RIGHT
	var up: Vector3 = f.cross(right).normalized()
	# Right-handed so "up" is up: right = up x forward... keep "up" pointing up the world.
	if up.y < 0.0:
		up = -up
		right = -right
	var m: float = MAT_GLOW_EYE if glows else MAT_EYE
	var rows: int = 7
	var segments: int = 14
	var first: int = s.count
	for i: int in rows + 1:
		var theta: float = PI * float(i) / float(rows)
		for j: int in segments + 1:
			var phi: float = TAU * float(j) / float(segments)
			var radial: Vector3 = right * cos(phi) + up * sin(phi)
			var normal: Vector3 = (f * cos(theta) + radial * sin(theta)).normalized()
			var p: Vector3 = center + f * cos(theta) * radius * bulge + radial * sin(theta) * radius
			var uv: Vector2 = Vector2(cos(phi), sin(phi)) * sin(theta)
			if theta > PI * 0.5:
				uv = uv.normalized() * 1.4 if uv.length() > 0.001 else Vector2(1.4, 0.0)
			s.vertex(p, normal, uv, Vector2(p.y, 0.0), Color(1.0, 0.0, m, 0.0), bones)
	for i: int in rows:
		for j: int in segments:
			var a: int = first + i * (segments + 1) + j
			var b: int = a + 1
			var c: int = a + segments + 1
			var d: int = c + 1
			s.tri(a, c, b)
			s.tri(b, c, d)


## A soft brow ridge over an eye: a short flattened tube along `along`, tilted up at its inner end.
static func brow(s: HeroMeshAtelier.Sculpt, inner: Vector3, outer: Vector3, thick: float, bones: Dictionary, m: float) -> void:
	tube(s, [inner, inner.lerp(outer, 0.5) + Vector3.UP * thick * 0.6, outer], [thick * 0.8, thick, thick * 0.6], [bones], m,
		{"sides": 8, "subdiv": 2, "flat": 0.55, "extra": {"g": 0.5}})


## A position mirrored to the left when `side` is negative.
static func mx(p: Vector3, side: float) -> Vector3:
	return Vector3(p.x * side, p.y, p.z)
