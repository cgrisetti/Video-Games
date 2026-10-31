class_name BerryEffects
extends Node3D

# Little bursts of fun when a raspberry is picked. The berry squashes, then pops into a spray of
# juicy bits and leaves with a soft ring, and its number floats up, wafting side to side like a
# falling leaf in reverse, and fades away: 1, 2, 3... up to 10 for the golden raspberry, which
# throws twice the juice and a burst of sparkles.

const SQUASH_TIME := 0.16 # How long a berry squashes and swells before it pops.
const BIT_COUNT := 14
const BIT_LIFE := Vector2(0.45, 0.8)
const BIT_GRAVITY := 14.0
const RING_TIME := 0.35
const NUMBER_LIFE := 1.6 # The golden 10 lingers longer.
const NUMBER_RISE := 1.7
const NUMBER_WAFT := 0.14
const BERRY_BITS := [Color("#d8285c"), Color("#e8487a"), Color("#b81e4c")]
const GOLD_BITS := [Color("#ffc93c"), Color("#ffe07a"), Color("#f2a922")]
const SPARKLES := [Color("#ffe27a"), Color("#ffffff"), Color("#ffb3d9")]

var _effects: Array[Dictionary] = [] # Each: {"node", "update": Callable(dt) -> bool, "done": Callable}.
var _rng := RandomNumberGenerator.new()
var _bit_mesh: SphereMesh
var _leaf_mesh: CylinderMesh
var _ring_texture: Dictionary = {}


func _ready() -> void:
	_bit_mesh = SphereMesh.new()
	_bit_mesh.radius = 0.075
	_bit_mesh.height = 0.15
	_bit_mesh.radial_segments = 8
	_bit_mesh.rings = 5
	_leaf_mesh = CylinderMesh.new()
	_leaf_mesh.top_radius = 0.0
	_leaf_mesh.bottom_radius = 0.07
	_leaf_mesh.height = 0.22
	_leaf_mesh.radial_segments = 4


# Pop a picked berry. `number` is how many have been picked, counting this one; `floor` is the
# height of the ground under it; `on_gone` runs once it has popped (to remove or hide it).
func pop(berry: Node3D, number: int, golden: bool, floor: float, on_gone: Callable) -> void:
	var start := berry.scale
	var time := [0.0]
	var burst := [false]
	_effects.append({"update": func(dt: float) -> bool:
		time[0] += dt
		var t: float = minf(time[0] / SQUASH_TIME, 1.0)
		# First half: squash down and spread out. Then pop! and shrink away, stretching up.
		var wide := 1.0 + 0.5 * t if t < 0.5 else 1.25 * sqrt(2.0 - 2.0 * t)
		var tall := 1.0 - 0.5 * t if t < 0.5 else wide * 1.15
		berry.scale = Vector3(start.x * wide, start.y * tall, start.z * wide)
		if t >= 0.5 and not burst[0]:
			burst[0] = true
			_spray(berry.global_position, golden, floor)
		return t < 1.0,
		"done": func() -> void:
			berry.scale = start
			on_gone.call()})
	_float_number(berry.global_position, number, golden)


func clear() -> void:
	for effect in _effects:
		effect.done.call()
	_effects.clear()


func _process(delta: float) -> void:
	for i in range(_effects.size() - 1, -1, -1):
		var effect: Dictionary = _effects[i]
		if not effect.update.call(delta):
			effect.done.call()
			_effects.remove_at(i)


# A spray of juicy bits and a few leaves, a soft ring, and for the golden one, sparkles.
func _spray(center: Vector3, golden: bool, floor: float) -> void:
	var palette: Array = GOLD_BITS if golden else BERRY_BITS
	var count := BIT_COUNT * 2 if golden else BIT_COUNT
	for i in count + (0 if golden else 3):
		var leaf := i >= count
		var bit := MeshInstance3D.new()
		bit.mesh = _leaf_mesh if leaf else _bit_mesh
		bit.material_override = Art.material(Color("#4e8f36"), 0.7) if leaf else Art.material(palette[i % palette.size()], 0.3, {"metallic": 0.5 if golden else 0.0, "clearcoat_enabled": true})
		bit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if leaf:
			bit.scale = Vector3(0.4, 1.0, 1.0)
		add_child(bit)
		bit.global_position = center
		var angle := _rng.randf() * TAU
		var outward := _rng.randf_range(1.8, 3.6) * (1.3 if golden else 1.0)
		var velocity := [Vector3(cos(angle) * outward, _rng.randf_range(1.5, 4.2), sin(angle) * outward)]
		var spin := Vector3(_rng.randfn(), _rng.randfn(), _rng.randfn()) * (12.0 if leaf else 0.0)
		var size := _rng.randf_range(0.7, 1.3)
		var life := _rng.randf_range(BIT_LIFE.x, BIT_LIFE.y) * (1.3 if leaf else 1.0)
		var time := [0.0]
		var shape := bit.scale
		_effects.append({"update": func(dt: float) -> bool:
			time[0] += dt
			velocity[0].y -= BIT_GRAVITY * dt * (0.45 if leaf else 1.0) # Leaves flutter down slower.
			bit.global_position += velocity[0] * dt
			if bit.global_position.y < floor + 0.04:
				bit.global_position.y = floor + 0.04 # Splat, and stay put while it shrinks.
				velocity[0] = Vector3.ZERO
			bit.rotation += spin * dt
			bit.scale = shape * size * maxf(1.0 - pow(time[0] / life, 2.0), 0.0)
			return time[0] < life,
			"done": bit.queue_free})
	# The ring: a soft circle that spreads and fades.
	var ring := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	ring.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_texture = _ring(golden)
	ring.material_override = material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	ring.global_position = center
	var ring_time := [0.0]
	var ring_size := 4.0 if golden else 2.0
	_effects.append({"update": func(dt: float) -> bool:
		ring_time[0] += dt
		var t: float = minf(ring_time[0] / RING_TIME, 1.0)
		ring.scale = Vector3.ONE * (0.3 + ring_size * (1.0 - pow(1.0 - t, 2.0)))
		ring.transparency = t
		return t < 1.0,
		"done": ring.queue_free})
	if golden:
		for i in 14:
			var sparkle := MeshInstance3D.new()
			var gem := SphereMesh.new()
			gem.radius = 0.06
			gem.height = 0.12
			gem.radial_segments = 4
			gem.rings = 2
			sparkle.mesh = gem
			sparkle.material_override = Art.glow_material(SPARKLES[i % 3], 4.0)
			sparkle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(sparkle)
			sparkle.global_position = center
			var drift := Vector3(_rng.randfn(), 0, _rng.randfn()).normalized() * _rng.randf_range(0.6, 1.6)
			drift.y = _rng.randf_range(0.4, 1.4)
			var life := _rng.randf_range(0.9, 1.6)
			var twinkle := _rng.randf() * TAU
			var time := [0.0]
			_effects.append({"update": func(dt: float) -> bool:
				time[0] += dt
				sparkle.global_position += drift * dt
				sparkle.rotation.y += dt * 4.0
				sparkle.scale = Vector3.ONE * (0.6 + 0.4 * sin(time[0] * 14.0 + twinkle)) * (1.0 - time[0] / life)
				return time[0] < life,
				"done": sparkle.queue_free})


# The berry's number floats up, wafting side to side, and fades.
func _float_number(at: Vector3, number: int, golden: bool) -> void:
	var label := Art.label(str(number), 160, Color("#ffd55a") if golden else Color("#fff4f0"))
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 22
	label.outline_modulate = Color("#b8235a") if not golden else Color("#9a6510")
	label.no_depth_test = true
	label.alpha_cut = Label3D.ALPHA_CUT_DISABLED
	label.pixel_size = 0.006
	add_child(label)
	label.global_position = at + Vector3(0, 0.4, 0)
	var life := NUMBER_LIFE * (1.6 if golden else 1.0)
	var time := [0.0]
	var start := label.global_position
	_effects.append({"update": func(dt: float) -> bool:
		time[0] += dt
		var t: float = time[0] / life
		var rise: float = 1.0 - pow(1.0 - t, 2.0)
		label.global_position = start + Vector3(sin(time[0] * 5.0) * NUMBER_WAFT, rise * NUMBER_RISE, 0)
		label.scale = Vector3.ONE * (0.7 + 0.3 * minf(t * 8.0, 1.0)) # A little pop as it appears.
		label.modulate.a = 1.0 - smoothstep(0.55, 1.0, t)
		label.outline_modulate.a = label.modulate.a
		return t < 1.0,
		"done": label.queue_free})


func _ring(golden: bool) -> ImageTexture:
	if _ring_texture.has(golden):
		return _ring_texture[golden]
	var size := 128
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var tint := Color("#ffeca0") if golden else Color("#ffd6e4")
	for y in size:
		for x in size:
			var r := Vector2(x + 0.5 - size / 2.0, y + 0.5 - size / 2.0).length() / (size / 2.0)
			var band := 1.0 - smoothstep(0.0, 0.18, absf(r - 0.85))
			image.set_pixel(x, y, Color(tint, band * 0.9))
	_ring_texture[golden] = ImageTexture.create_from_image(image)
	return _ring_texture[golden]
