## A few head of stock in a field or a yard (docs/32_EMBERSHORE_THE_WORKED_LAND.md §8):
## Golden-Fleece sheep (docs/13's, with a lamb or two and now and then a dark one),
## belted cattle, yard hens, geese on a green. Not fighters, just life.
##
## Like AmbientFlock, each beast walks a seeded, clock-driven round of stops
## about the flock's home and stands a while at each with its head down (the
## same on every peer), and keeps to the ground. On top of that it is shy: it
## gives way before a hero who walks up to it and drifts back when they have
## gone. The whole flock is two draws (bodies and heads, a MultiMesh each), seen
## from across the valley, and it only moves while a hero is near enough to see it move.
class_name GrazingStock
extends Node3D

enum Kind { SHEEP, CATTLE, HENS, GEESE }

const FLEECE: Color = Color(0.95, 0.9, 0.72)
const DARK_FACE: Color = Color(0.22, 0.2, 0.2)
const HIDE: Color = Color(0.46, 0.27, 0.18)
const BELT: Color = Color(0.93, 0.9, 0.82)
const RUSSET: Color = Color(0.62, 0.34, 0.2)
const GOOSE_WHITE: Color = Color(0.95, 0.95, 0.92)
const BILL: Color = Color(0.92, 0.58, 0.2)
## By kind: metres a second walking, seconds stood at each stop, how near a hero comes before it gives way
## (0: it holds its ground), how far its head drops to graze (radians) and how far it shows.
const SPEED: Array[float] = [0.55, 0.42, 0.8, 0.6]
const PAUSE: Array[float] = [10.0, 14.0, 3.5, 6.0]
const SHY: Array[float] = [5.0, 3.4, 3.2, 0.0]
const GRAZE: Array[float] = [1.05, 0.95, 1.2, 1.25]
const SEEN: Array[float] = [420.0, 480.0, 110.0, 180.0]
## The head's pivot on the body (the neck's root), by kind.
const NECK: Array[Vector3] = [Vector3(0.0, 0.72, 0.4), Vector3(0.0, 1.12, 0.82), Vector3(0.0, 0.3, 0.12), Vector3(0.0, 0.44, 0.22)]
## A flock moves only while a hero is within this far of its home (by kind: a hen's scratching can't be seen from
## across a field), is moved every other physics tick, and is looked at this often while it sleeps.
const AWAKE_RANGE: Array[float] = [70.0, 80.0, 40.0, 50.0]
const SLEEP_CHECK: float = 0.7
const STOPS: int = 5
## Their voices (PastoralVoices, docs/33 §10), by kind: seconds between calls while the flock is awake, how far a call
## carries (metres), how loud, and how high its head is when it calls. A beast startled by a hero calls at once
## (a ewe bleats, a hen clucks); a goose holds its ground and honks at any hero within GOOSE_GUARD.
const CALL_GAP: Array[Vector2] = [Vector2(7.0, 16.0), Vector2(14.0, 30.0), Vector2(3.0, 8.0), Vector2(9.0, 20.0)]
const CALL_REACH: Array[float] = [55.0, 70.0, 30.0, 45.0]
const CALL_DB: Array[float] = [-12.0, -10.0, -16.0, -12.0]
const CALL_HEIGHT: Array[float] = [0.8, 1.3, 0.35, 0.55]
const STARTLE_COOLDOWN: float = 2.5
const GOOSE_GUARD: float = 5.0
## A lamb or a calf is this small or smaller; a calf calls this much higher than its mother.
const YOUNG_SIZE: float = 0.7
const CALF_PITCH: float = 1.35

var kind: Kind = Kind.SHEEP
var count: int = 6
var reach: float = 14.0
var stock_seed: int = 1
## The ground under a spot: (x, z) -> y.
var height: Callable

var _bodies: MultiMesh
var _heads: MultiMesh
var _stops: Array[PackedVector3Array] = []
var _size: PackedFloat32Array = PackedFloat32Array()
var _shy: PackedVector3Array = PackedVector3Array()
var _yaw: PackedFloat32Array = PackedFloat32Array()
## Where each beast stands (kept here too: a headless run's MultiMesh keeps nothing).
var _spots: PackedVector3Array = PackedVector3Array()
var _nap: float = 0.0
var _owed: float = 0.0
## The flock's calls so far, and the last one's voice and take (the checks).
var calls: int = 0
var last_voice: int = -1
var last_take: int = -1
var _voice: AudioStreamPlayer3D
var _call_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _call_left: float = 0.0
var _since_call: float = 99.0
## Which beasts a hero startled this tick, and last tick (a beast calls when it's newly startled).
var _startled_now: PackedByteArray = PackedByteArray()
var _startled_before: PackedByteArray = PackedByteArray()

static var _meshes: Dictionary[int, ArrayMesh] = {}
## Where the party stands, looked up once a physics frame for every flock on the island.
static var _party_at: Array[Vector3] = []
static var _party_frame: int = -1


static func make(what: Kind, head: int, around: float, seed_value: int, ground: Callable) -> GrazingStock:
	var made: GrazingStock = GrazingStock.new()
	made.kind = what
	made.count = head
	made.reach = around
	made.stock_seed = seed_value
	made.height = ground
	return made


func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = stock_seed * 7919 + int(kind)
	_bodies = _multi(_mesh(kind, false), "Bodies", true)
	_heads = _multi(_mesh(kind, true), "Heads", false)
	for index: int in count:
		var stops: PackedVector3Array = PackedVector3Array()
		for stop: int in STOPS:
			var angle: float = rng.randf() * TAU
			stops.append(Vector3(cos(angle), 0.0, sin(angle)) * rng.randf_range(reach * 0.15, reach))
		_stops.append(stops)
		# A lamb among the sheep, a calf among the cattle; a dark sheep in every nine or so.
		var young: bool = (kind == Kind.SHEEP or kind == Kind.CATTLE) and index > 1 and rng.randf() < 0.22
		_size.append(rng.randf_range(0.56, 0.64) if young else rng.randf_range(0.92, 1.08))
		var tint: Color = Color.WHITE.darkened(rng.randf_range(0.0, 0.08))
		if kind == Kind.SHEEP and rng.randf() < 0.11:
			tint = Color(0.34, 0.3, 0.28)
		elif kind == Kind.CATTLE and rng.randf() < 0.3:
			tint = Color(0.62, 0.58, 0.56)
		elif kind == Kind.HENS:
			tint = [Color.WHITE, Color(1.25, 1.2, 1.1), Color(0.6, 0.6, 0.62)][rng.randi_range(0, 2)]
		_bodies.set_instance_color(index, tint)
		_heads.set_instance_color(index, tint if kind != Kind.SHEEP else Color.WHITE)
		_shy.append(Vector3.ZERO)
		_spots.append(Vector3.ZERO)
		_yaw.append(rng.randf() * TAU)
	_startled_now.resize(count)
	_startled_before.resize(count)
	_call_rng.seed = stock_seed * 104729 + int(kind)
	_call_left = _call_rng.randf_range(0.0, CALL_GAP[kind].y)
	_place(0.0, true)


## Where a beast stands right now (the checks).
func where(index: int) -> Vector3:
	return _spots[index]


func _multi(mesh: ArrayMesh, node_name: String, shadows: bool) -> MultiMesh:
	var multi: MultiMesh = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = count
	multi.custom_aabb = AABB(Vector3(-reach - 14.0, -30.0, -reach - 14.0), Vector3(reach * 2.0 + 28.0, 60.0, reach * 2.0 + 28.0))
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = node_name
	node.multimesh = multi
	node.material_override = CalderaKit.vertex_material()
	node.visibility_range_end = SEEN[kind]
	node.visibility_range_end_margin = 20.0
	if not shadows:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return multi


## Moved on the physics tick: the project interpolates physics, and a MultiMesh set from _process isn't.
func _physics_process(delta: float) -> void:
	_nap -= delta
	if _nap > 0.0:
		return
	# Every other tick (flocks take turns by their seed), with both ticks' time.
	_owed += delta
	if (Engine.get_physics_frames() + stock_seed) % 2 != 0:
		return
	var heroes: Array[Vector3] = _heroes_near()
	if heroes.is_empty():
		# Nobody near enough to see them move: stand as they are, and look again in a while.
		_nap = SLEEP_CHECK + 0.05 * float(stock_seed % 7)
		_owed = 0.0
		return
	_place(_owed, false, heroes)
	_call_now(_owed, heroes)
	_owed = 0.0


## The heroes within sight of the flock's home.
func _heroes_near() -> Array[Vector3]:
	var frame: int = Engine.get_physics_frames()
	if _party_frame != frame:
		_party_frame = frame
		_party_at.clear()
		if CombatDirector.current != null:
			for actor: ActorBase in CombatDirector.current.party_actors():
				_party_at.append(actor.global_position)
	var near: Array[Vector3] = []
	var home: Vector3 = global_position
	var sight: float = AWAKE_RANGE[kind] + reach
	for at: Vector3 in _party_at:
		if at.distance_squared_to(home) < sight * sight:
			near.append(at)
	return near


## The flock's voice while it's awake: a call every so often from one beast, at once when a hero startles one,
## and a goose's honk at a hero who comes too near.
func _call_now(delta: float, heroes: Array[Vector3]) -> void:
	_call_left -= delta
	_since_call += delta
	var caller: int = -1
	if _since_call >= STARTLE_COOLDOWN:
		for index: int in count:
			if _startled_now[index] == 1 and _startled_before[index] == 0:
				caller = index
				break
	if caller < 0 and kind == Kind.GEESE and _since_call >= STARTLE_COOLDOWN * 2.0:
		for index: int in count:
			for hero: Vector3 in heroes:
				if Vector2(_spots[index].x - hero.x, _spots[index].z - hero.z).length() < GOOSE_GUARD:
					caller = index
	if caller < 0 and _call_left <= 0.0:
		caller = _call_rng.randi() % maxi(count, 1)
	_startled_before = _startled_now.duplicate()
	if caller >= 0:
		call_out(caller)


## One beast calls (its kind's voice, a lamb's or a calf's if it's young), from where it stands.
func call_out(index: int) -> void:
	var young: bool = _size[index] <= YOUNG_SIZE
	var voice: PastoralVoices.Voice = [PastoralVoices.Voice.SHEEP, PastoralVoices.Voice.CATTLE, PastoralVoices.Voice.HENS,
		PastoralVoices.Voice.GEESE][kind]
	if kind == Kind.SHEEP and young:
		voice = PastoralVoices.Voice.LAMB
	var take: int = _call_rng.randi() % PastoralVoices.TAKES
	var sound: AudioStreamWAV = PastoralVoices.stream(voice, take)
	if sound == null:
		# The voices are still being made: try again in a moment.
		_call_left = 0.5
		return
	_call_left = _call_rng.randf_range(CALL_GAP[kind].x, CALL_GAP[kind].y)
	_since_call = 0.0
	calls += 1
	last_voice = voice
	last_take = take
	if _voice == null:
		_voice = PastoralVoices.player("Voice", CALL_REACH[kind], CALL_DB[kind])
		add_child(_voice)
	_voice.position = _spots[index] - global_position + Vector3(0.0, CALL_HEIGHT[kind] * _size[index], 0.0)
	_voice.stream = sound
	_voice.pitch_scale = CALF_PITCH if kind == Kind.CATTLE and young else 1.0
	if not PastoralVoices.silent():
		_voice.play()


func _place(delta: float, at_once: bool, heroes: Array[Vector3] = []) -> void:
	var now: float = CombatDirector.game_time() + stock_seed * 3.7
	_startled_now.fill(0)
	var speed: float = SPEED[kind]
	var pause: float = PAUSE[kind]
	var home: Vector3 = global_position
	var leg: float = reach * 1.1 / speed + pause
	for index: int in count:
		var stops: PackedVector3Array = _stops[index]
		var cycle: float = fposmod(now + index * 5.3, leg * stops.size())
		var at: int = int(cycle / leg)
		var t: float = clampf((cycle - at * leg) / (leg - pause), 0.0, 1.0)
		var from: Vector3 = stops[at]
		var to: Vector3 = stops[(at + 1) % stops.size()]
		var spot: Vector3 = home + from.lerp(to, smoothstep(0.0, 1.0, t))
		var walking: bool = t > 0.0 and t < 1.0
		# Shy: pushed off by the nearest hero inside its shy ring, easing back after.
		var push: Vector3 = Vector3.ZERO
		var startled: bool = false
		var shy: float = SHY[kind] * _size[index]
		for hero: Vector3 in heroes:
			var away: Vector3 = Vector3(spot.x + _shy[index].x - hero.x, 0.0, spot.z + _shy[index].z - hero.z)
			var gap: float = away.length()
			if shy > 0.0 and gap < shy:
				push += (away / maxf(gap, 0.05)) * (shy - gap) * 1.6
				startled = true
				_startled_now[index] = 1
		var shy_now: Vector3 = _shy[index]
		var target: Vector3 = (shy_now + push).limit_length(shy * 2.2) if startled else Vector3.ZERO
		shy_now = target if at_once else shy_now.lerp(target, clampf(delta * (5.0 if startled else 0.6), 0.0, 1.0))
		_shy[index] = shy_now
		spot += shy_now
		spot.y = float(height.call(spot.x, spot.z)) if height.is_valid() else home.y
		_spots[index] = spot
		# It faces the way it goes: along its round, or away from whoever startled it.
		var heading: Vector3 = (to - from) if walking else Vector3.ZERO
		if startled and push.length() > 0.05:
			heading = push
		if heading.length() > 0.05:
			var want: float = atan2(heading.x, heading.z)
			_yaw[index] = want if at_once else lerp_angle(_yaw[index], want, clampf(delta * 4.0, 0.0, 1.0))
		var size: float = _size[index]
		var hop: float = 0.0
		if (walking or startled) and (kind == Kind.SHEEP or kind == Kind.HENS):
			hop = absf(sin(now * (9.0 if kind == Kind.HENS else 6.0) + index * 1.7)) * 0.05 * size
		var body: Transform3D = Transform3D(Basis(Vector3.UP, _yaw[index]).scaled(Vector3.ONE * size), spot - home + Vector3(0.0, hop, 0.0))
		_bodies.set_instance_transform(index, body)
		# Head down while it stands at a stop, up when it walks or is startled; a hen pecks, a goose looks about.
		var down: float = 0.0
		if not walking and not startled:
			down = GRAZE[kind] * (0.75 + 0.25 * sin(now * (5.0 if kind == Kind.HENS else 1.3) + index * 2.1))
			if kind == Kind.GEESE or kind == Kind.HENS:
				down *= 1.0 if sin(now * 0.7 + index * 1.9) >= 0.0 else 0.0
		_heads.set_instance_transform(index, body * Transform3D(Basis(Vector3.RIGHT, down), NECK[kind]))


# --- The beasts' shapes -----------------------------------------------------------------------------------

## A kind's body (feet at the origin, facing +Z) or its head (its neck's root at the origin), built once.
static func _mesh(what: int, head: bool) -> ArrayMesh:
	var key: int = what * 2 + int(head)
	if _meshes.has(key):
		return _meshes[key]
	var into: LandblockTerrain.MeshMerge = CalderaKit.merge()
	match what:
		Kind.SHEEP:
			if head:
				_blob(into, Vector3(0.0, 0.0, 0.16), Vector3(0.13, 0.14, 0.2), DARK_FACE)
				CalderaKit.add_box(into, Vector3(0.0, 0.07, 0.06), Vector3(0.4, 0.03, 0.06), DARK_FACE)
			else:
				_blob(into, Vector3(0.0, 0.62, -0.04), Vector3(0.35, 0.33, 0.54), FLEECE)
				_blob(into, Vector3(0.0, 0.68, 0.26), Vector3(0.27, 0.25, 0.26), FLEECE.lightened(0.03))
				for z: float in [-0.27, 0.27]:
					CalderaKit.add_box(into, Vector3(-0.15, 0.18, z), Vector3(0.07, 0.36, 0.07), DARK_FACE)
					CalderaKit.add_box(into, Vector3(0.15, 0.18, z), Vector3(0.07, 0.36, 0.07), DARK_FACE)
		Kind.CATTLE:
			if head:
				_blob(into, Vector3(0.0, 0.0, 0.22), Vector3(0.19, 0.2, 0.3), HIDE)
				_blob(into, Vector3(0.0, -0.06, 0.44), Vector3(0.14, 0.12, 0.12), BELT.darkened(0.1))
				for hand: float in [-1.0, 1.0]:
					CalderaKit.add_cone(into, Vector3(hand * 0.18, 0.14, 0.12), 0.045, 0.2, BELT, 5)
					CalderaKit.add_box(into, Vector3(hand * 0.24, 0.04, 0.1), Vector3(0.14, 0.04, 0.08), HIDE.darkened(0.1))
			else:
				_blob(into, Vector3(0.0, 0.98, 0.0), Vector3(0.44, 0.46, 0.92), HIDE)
				_blob(into, Vector3(0.0, 0.98, 0.0), Vector3(0.455, 0.475, 0.32), BELT)
				_blob(into, Vector3(0.0, 1.04, 0.62), Vector3(0.36, 0.38, 0.34), HIDE.darkened(0.05))
				for x: float in [-0.24, 0.24]:
					for z: float in [-0.56, 0.56]:
						CalderaKit.add_box(into, Vector3(x, 0.3, z), Vector3(0.12, 0.6, 0.12), HIDE.darkened(0.15))
				CalderaKit.add_box(into, Vector3(0.0, 0.8, -0.92), Vector3(0.05, 0.6, 0.05), HIDE.darkened(0.2))
		Kind.HENS:
			if head:
				_blob(into, Vector3(0.0, 0.07, 0.03), Vector3(0.055, 0.06, 0.06), RUSSET.lightened(0.08))
				CalderaKit.add_box(into, Vector3(0.0, 0.14, 0.02), Vector3(0.02, 0.05, 0.07), Color(0.86, 0.16, 0.14))
				CalderaKit.add_box(into, Vector3(0.0, 0.06, 0.1), Vector3(0.025, 0.02, 0.05), BILL)
				CalderaKit.add_box(into, Vector3(0.0, 0.01, 0.0), Vector3(0.05, 0.08, 0.05), RUSSET)
			else:
				_blob(into, Vector3(0.0, 0.22, 0.0), Vector3(0.13, 0.13, 0.18), RUSSET)
				_blob(into, Vector3(0.0, 0.32, -0.16), Vector3(0.05, 0.12, 0.08), RUSSET.darkened(0.25))
				for hand: float in [-1.0, 1.0]:
					CalderaKit.add_box(into, Vector3(hand * 0.05, 0.05, 0.0), Vector3(0.02, 0.1, 0.02), BILL)
		Kind.GEESE:
			if head:
				into.add_cylinder(Vector3(0.0, 0.17, 0.02), 0.035, 0.05, 0.36, GOOSE_WHITE, 6)
				_blob(into, Vector3(0.0, 0.37, 0.05), Vector3(0.055, 0.055, 0.08), GOOSE_WHITE)
				CalderaKit.add_box(into, Vector3(0.0, 0.36, 0.15), Vector3(0.04, 0.03, 0.09), BILL)
			else:
				_blob(into, Vector3(0.0, 0.34, 0.0), Vector3(0.18, 0.17, 0.3), GOOSE_WHITE)
				_blob(into, Vector3(0.0, 0.4, -0.26), Vector3(0.1, 0.08, 0.12), GOOSE_WHITE.darkened(0.06))
				for hand: float in [-1.0, 1.0]:
					CalderaKit.add_box(into, Vector3(hand * 0.08, 0.09, 0.0), Vector3(0.03, 0.18, 0.03), BILL)
					CalderaKit.add_box(into, Vector3(hand * 0.08, 0.01, 0.05), Vector3(0.08, 0.02, 0.12), BILL)
	_meshes[key] = into.commit()
	return _meshes[key]


## A rounded lump: a low-poly ball stretched to `radii`.
static func _blob(into: LandblockTerrain.MeshMerge, center: Vector3, radii: Vector3, color: Color) -> void:
	var ball: SphereMesh = SphereMesh.new()
	ball.radius = 1.0
	ball.height = 2.0
	ball.radial_segments = 5
	ball.rings = 2
	into.add_arrays(ball.get_mesh_arrays(), Transform3D(Basis.from_scale(radii), center), color)
