class_name InchWorm
extends Node3D

# A hungry rainbow inch worm that chases the gnome. It moves one end at a time, the way inch worms
# do: the tail scoots up behind the head, arching the body, then the head reaches forward until
# the body lies flat again. It steers round trees and rocks, turns at most 60° an inch, wades
# slowly through the creek, and if it touches the gnome, the round is over. A bonk on the head
# with the stick rolls it onto its side with ✕ eyes for a while; it gets up a little faster.
# Its body is one smooth, striped tube (red at the head to violet at the tail), rebuilt every
# frame to follow its arch.

const LENGTH := 3.0
const BUNCHED := LENGTH * 0.35 # How close the tail gets to the head when the body arches.
const RADIUS := 0.25
const SEGMENTS := 15 # Stripes.
const MAX_TURN := PI / 3.0 # It turns at most 60° an inch, unless it's steering round something.
const STUN_TIME := 5.0 # Seconds it lies dazed after a bonk.
const STUN_SPEEDUP := 1.05 # Each bonk makes it 5% faster...
const ROLL_SPEED := (PI / 2.0) / 0.25 # It takes a quarter of a second to roll onto its side.
const COLORS := [Color("#ff3b30"), Color("#ff9500"), Color("#ffdd00"), Color("#34c759"), Color("#1e90ff"), Color("#5856d6"), Color("#af52de")]
const RINGS := 64 # Rings round the body, for a smooth tube.
const SIDES := 12

var field: BerryField
var target: Node3D # The gnome.
var top_speed := 0.0 # Its fastest moment, in metres a second. Goes up a little with every bonk.
var max_speed := 0.0 # ...up to this.
var head := Vector3.ZERO # Where each end touches the ground.
var tail := Vector3.ZERO
var stun_time := 0.0
var head_position := Vector3.ZERO # The middle of its head, where it catches and gets bonked.

var _stretching := false
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _step_time := 0.0
var _step_duration := 1.0
var _dodge_side := 1.0
var _roll := 0.0
var _roll_side := 1.0
var _body: MeshInstance3D
var _mesh := ArrayMesh.new()
var _indices := PackedInt32Array()
var _head_pivot: Node3D
var _eyes: Array[Node3D] = []
var _crosses: Array[Node3D] = []


func _ready() -> void:
	top_level = true
	_body = MeshInstance3D.new()
	_body.mesh = _mesh
	_body.material_override = Art.material(Color.WHITE, 0.42, {"vertex_color_use_as_albedo": true, "vertex_color_is_srgb": true, "rim_enabled": true, "rim": 0.45, "rim_tint": 0.5, "clearcoat_enabled": true, "clearcoat": 0.35, "subsurf_scatter_enabled": true, "subsurf_scatter_strength": 0.25})
	add_child(_body)
	for ring in RINGS - 1:
		for side in SIDES:
			var a := ring * (SIDES + 1) + side
			var b := a + SIDES + 1
			_indices.append_array([a, a + 1, b, a + 1, b + 1, b])
	_build_face()


func is_dazed() -> bool:
	return stun_time > 0.0 or _roll > 0.0


# Lie flat at `at_head`, its tail stretched out behind toward `at_tail`, ready to start.
func place(at_head: Vector3, at_tail: Vector3, speed: float, fastest: float) -> void:
	head = at_head
	tail = at_tail
	top_speed = speed
	max_speed = fastest
	stun_time = 0.0
	_roll = 0.0
	_stretching = true # So its first step pulls the tail up.
	_start_step()
	_shape()


# Bonk! It rolls over away from the gnome, its eyes turn to ✕s, and it'll get up a little faster.
func stun() -> void:
	stun_time = STUN_TIME
	var across := Vector3(head.z - tail.z, 0, -(head.x - tail.x))
	_roll_side = -1.0 if (target.global_position - head).dot(across) > 0.0 else 1.0
	top_speed = minf(top_speed * STUN_SPEEDUP, max_speed)


func update(delta: float, moving: bool) -> void:
	stun_time = maxf(stun_time - delta, 0.0)
	var roll_to := PI / 2.0 if stun_time > 0.0 else 0.0
	_roll = move_toward(_roll, roll_to, ROLL_SPEED * delta)
	var dazed := is_dazed()
	for eye in _eyes:
		eye.visible = not dazed
	for cross in _crosses:
		cross.visible = dazed
	if moving and not dazed:
		_step_time += delta
		var progress := minf(_step_time / _step_duration, 1.0)
		var eased := (1.0 - cos(PI * progress)) / 2.0 # Starts slow, speeds up, slows down.
		if _stretching:
			head = _from.lerp(_to, eased)
		else:
			tail = _from.lerp(_to, eased)
		if progress >= 1.0:
			_start_step()
	_shape()


# --- Inching along ---

func _start_step() -> void:
	_stretching = not _stretching
	var facing := atan2(head.x - tail.x, head.z - tail.z)
	if _stretching:
		_from = head
		_choose_reach(facing)
	else:
		# Pull the tail up behind the head.
		_from = tail
		_to = BerryField.keep_in(head - Vector3(sin(facing), 0, cos(facing)) * BUNCHED, RADIUS)
	# Each step speeds up then slows down, and its fastest moment is π/2 times its average speed.
	# Timing it like this makes that fastest moment exactly its top speed, slower in the creek.
	var wading := field.in_water(_from.x, _from.z) or field.in_water(_to.x, _to.z)
	var speed := top_speed * (Creek.SLOWDOWN if wading else 1.0)
	_step_duration = maxf(PI / 2.0 * _from.distance_to(_to) / speed, 0.05)
	_step_time = 0.0


# Where the head reaches to: toward the gnome, turning only a little each step. If something's in
# the way, try turning further left and right until the way is clear, starting with the side it
# dodged to last time, so it doesn't wiggle back and forth.
func _choose_reach(facing: float) -> void:
	var to_gnome := atan2(target.global_position.x - tail.x, target.global_position.z - tail.z)
	var wanted := facing + clampf(angle_difference(facing, to_gnome), -MAX_TURN, MAX_TURN)
	for i in 18:
		var side := _dodge_side if i % 2 == 1 else -_dodge_side
		_reach_toward(wanted + ceili(i / 2.0) * 0.35 * side)
		if _is_clear(tail, _to) and _is_clear(head, _to):
			if i > 0:
				_dodge_side = side
			return
	_reach_toward(wanted) # Boxed in on every side, so just go for it.


func _reach_toward(heading: float) -> void:
	_to = BerryField.keep_in(tail + Vector3(sin(heading), 0, cos(heading)) * LENGTH, RADIUS)


# Can its body lie along the line from `from` to `to` without touching anything?
func _is_clear(from: Vector3, to: Vector3) -> bool:
	for obstacle in field.obstacles:
		var spot: Vector3 = obstacle.position
		var closest := Geometry3D.get_closest_point_to_segment(Vector3(spot.x, 0, spot.z), Vector3(from.x, 0, from.z), Vector3(to.x, 0, to.z))
		if closest.distance_to(Vector3(spot.x, 0, spot.z)) <= obstacle.radius + RADIUS + 0.1:
			return false
	return true


# --- Its body ---

# Bend the body into an arch between its two ends, following the ground (down into the creek, up
# over a bridge). The closer the ends, the taller the arch. Rolled onto its side, the arch tips
# over sideways to lie flat.
func _shape() -> void:
	var gap := tail.distance_to(head)
	var arch := sqrt(maxf(LENGTH * LENGTH - gap * gap, 0.0)) / 2.0
	var facing := atan2(head.x - tail.x, head.z - tail.z)
	var sideways := Vector3(cos(facing), 0, -sin(facing)) * _roll_side
	# The arch, finely, then points spaced evenly along it so the stripes stay even.
	var fine := PackedVector3Array()
	var lengths := PackedFloat32Array([0.0])
	for i in 41:
		var t := i / 40.0
		var bump := arch * sin(PI * t)
		var p := tail.lerp(head, t) + sideways * bump * sin(_roll)
		p.y = field.floor_at(p.x, p.z) + RADIUS + bump * cos(_roll)
		if i > 0:
			lengths.append(lengths[i - 1] + p.distance_to(fine[i - 1]))
		fine.append(p)
	var total := lengths[40]
	var centers := PackedVector3Array()
	var k := 0
	for r in RINGS:
		var want := total * r / (RINGS - 1)
		while k < 39 and lengths[k + 1] < want:
			k += 1
		var span := maxf(lengths[k + 1] - lengths[k], 0.0001)
		centers.append(fine[k].lerp(fine[k + 1], clampf((want - lengths[k]) / span, 0.0, 1.0)))
	_build_body(centers)
	head_position = centers[RINGS - 1] + Vector3(0, RADIUS * 0.25, 0)
	_head_pivot.global_position = head_position
	_head_pivot.global_rotation = Vector3(0, facing, -_roll_side * _roll)


func _build_body(centers: PackedVector3Array) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	for r in RINGS:
		var t := float(r) / (RINGS - 1) # 0 at the tail, 1 at the head.
		var forward := (centers[mini(r + 1, RINGS - 1)] - centers[maxi(r - 1, 0)]).normalized()
		var side := forward.cross(Vector3.UP).normalized()
		if side.length() < 0.5:
			side = Vector3.RIGHT
		var up := side.cross(forward).normalized()
		# Plump all along, rounding off at the tail, swelling a little toward the head.
		var radius := RADIUS * sqrt(clampf(t * 9.0, 0.0, 1.0)) * lerpf(0.92, 1.12, smoothstep(0.75, 1.0, t))
		var stripe: int = (SEGMENTS - 1 - mini(int(t * SEGMENTS), SEGMENTS - 1)) % COLORS.size() # Counted from the head, so the head is red.
		var color: Color = COLORS[stripe]
		for s in SIDES + 1:
			var angle := TAU * s / SIDES
			var normal := side * cos(angle) + up * sin(angle)
			vertices.append(centers[r] + normal * radius)
			normals.append(normal)
			colors.append(color.darkened(0.08 * (0.5 - 0.5 * sin(angle)))) # A little darker underneath.
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = _indices
	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


# The head: a round red head with two shiny black eyes (each with a sparkle), and the ✕ eyes it
# gets when it's bonked.
func _build_face() -> void:
	_head_pivot = Node3D.new()
	_head_pivot.top_level = true
	add_child(_head_pivot)
	_head_pivot.add_child(Art.sphere(RADIUS * 1.25, Art.material(COLORS[0], 0.42, {"rim_enabled": true, "rim": 0.45, "clearcoat_enabled": true, "clearcoat": 0.35})))
	var black := Art.material(Color("#141010"), 0.15, {"metallic_specular": 1.0})
	for side: float in [-1.0, 1.0]:
		var eye := Node3D.new()
		eye.position = Vector3(side * 0.12, 0.12, 0.25)
		eye.add_child(Art.sphere(0.075, black))
		eye.add_child(Art.sphere(0.02, Art.glow_material(Color.WHITE, 0.6), Vector3(-side * 0.02, 0.03, 0.06)))
		_head_pivot.add_child(eye)
		_eyes.append(eye)
		var cross := Node3D.new()
		cross.position = Vector3(side * 0.12, 0.12, 0.29)
		for tilt: float in [PI / 4.0, -PI / 4.0]:
			var stroke := Art.box(Vector3(0.17, 0.04, 0.03), black)
			stroke.rotation.z = tilt
			cross.add_child(stroke)
		cross.visible = false
		_head_pivot.add_child(cross)
		_crosses.append(cross)
