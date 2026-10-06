@tool
class_name Glen
extends Node3D

# The Glenn: a long, lantern-lit forest path between tall hedges, with games behind the gates,
# archways and openings along its sides, and the old garden door to the Bramble Maze at the far
# end. It's the hub of Lanternwood: walk up to an opening and a prompt appears; press F (□ on a
# controller) to see what's there, and press it again to go in.
#
# The openings, the gnome, the fox, the sun and the sky are placed in scenes/glen.tscn, so you
# can move them in the editor. Everything else (hedges, woods, grass, lanterns, rocks) grows
# from the numbers below each time the Glen loads, in the editor too.

signal play_requested(game: String)

# Tweak these to change the Glenn.
const HALL_WIDTH := 18.0
const HALL_LENGTH := 72.0 # It runs north and south, so the camera looks down its length.
const HEDGE_THICKNESS := 1.4
const HEDGE_HEIGHT := 2.5
const START_Z := 30.0 # The gnome starts near the south end and walks north.
const PATH_SWAY := 1.6 # How far the forest path winds from side to side...
const PATH_BEND := 28.0 # ...and how far along it one whole wind takes.
const PATH_HALF_WIDTH := 1.25
const LANTERN_SPACING := 9.0 # A lantern beside the path this often, on alternate sides.
const ROCK_COUNT := 7
const INTERACT_RANGE := 2.3 # How close to an opening the gnome has to be to go in.
const FINGERPOST_BEFORE := 2.6 # How far before each game's side path its finger-post stands.
const WOODS_REACH := 46.0 # How far out the woods go.
const WORLD_SIZE := 130.0 # The ground's width.
const SEED := 23 # Change for a different arrangement of trees, rocks and flowers.
# How much grows, for each graphics setting.
const DETAIL := {
	"low": {"grass": 14000, "flowers": 120, "fireflies": 40, "leaves": 20, "woods": 0.6},
	"medium": {"grass": 40000, "flowers": 260, "fireflies": 80, "leaves": 40, "woods": 0.85},
	"high": {"grass": 80000, "flowers": 420, "fireflies": 140, "leaves": 70, "woods": 1.0},
}

# The games, as the openings describe them.
const GAMES := {
	"berry-rush": {
		"title": "Berry Rush",
		"blurb": "Pick all 9 raspberries, then follow the fox to the golden one. Watch out for the inch worms!",
	},
	"bramble-maze": {
		"title": "Bramble Maze",
		"blurb": "Find your way out of a tall hedge maze, a new one every time. Lanterns light up where you've been.",
	},
	"gnome-crossing": {
		"title": "Gnome Crossing",
		"blurb": "Hop over creeks and deer trails as far as you can go. Night is falling behind you, so keep hopping!",
	},
}

const HALF_X := HALL_WIDTH / 2.0
const HALF_Z := HALL_LENGTH / 2.0
const INNER_X := HALF_X - HEDGE_THICKNESS # From the middle to the inside of the hedges.
const INNER_Z := HALF_Z - HEDGE_THICKNESS

var hud: Node # Set by main.gd: shows prompts, cards and messages.

var _openings: Array = []
var _lanterns: Array[OmniLight3D] = []
var _grass_material: ShaderMaterial
var _near: Node = null # The opening the gnome is standing at, if any.
var _offering: Node = null # The opening whose game card is showing, waiting for a second press.
var _time := 0.0
var _edge_noise := FastNoiseLite.new()

@onready var gnome: CharacterBody3D = $Gnome
@onready var fox: CharacterBody3D = $Fox
@onready var camera_rig: Node3D = $CameraRig
@onready var environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun
@onready var _generated: Node3D = $Generated
@onready var _air: Node3D = $Air


func _ready() -> void:
	_edge_noise.seed = SEED
	_edge_noise.frequency = 0.35
	for child in $Openings.get_children():
		_openings.append(child)
	build()
	if Engine.is_editor_hint():
		return
	fox.friend = gnome
	fox.keep_in = Rect2(-INNER_X + 0.4, -INNER_Z + 0.4, INNER_X * 2.0 - 0.8, INNER_Z * 2.0 - 0.8)
	camera_rig.target = gnome
	Settings.changed.connect(func(name: String) -> void: if name == "graphics": apply_graphics(true))
	apply_graphics(false)


# Arrive at the south end, or (coming back from a game) in front of that game's opening.
func enter(from := "") -> void:
	var back: Node = null
	for opening in _openings:
		if opening.game == from and from != "":
			back = opening
	if back:
		var at: Vector3 = back.spot()
		gnome.place(at, back.rotation.y)
	else:
		gnome.place(Vector3(path_x(START_Z), 0.05, START_Z), PI)
	fox.place(gnome.global_position + Vector3(-fox.SIDE_GAP, 0, 0.6))
	camera_rig.reset_view(0.0)
	_near = null
	_close_card()
	if hud:
		hud.show_banner("The Glenn", "Lanternwood")


# --- The layout ---

# The middle of the winding forest path at a point along the Glenn.
static func path_x(z: float) -> float:
	return PATH_SWAY * sin(z / PATH_BEND * TAU)


# How far a spot is from the nearest path's edge (the forest path, or a side path to an opening).
# The edges wander a little, the way a worn path does.
func path_distance(x: float, z: float) -> float:
	var distance := absf(x - path_x(z)) - PATH_HALF_WIDTH
	if z > HALF_Z + 2.0 or z < -HALF_Z:
		distance = INF # The forest path stops at the ends.
	for opening in _openings:
		var from: Vector3 = opening.position
		var inward: Vector3 = opening.basis.z
		var branch_from := Vector3(path_x(from.z) if opening.side != 0.0 else 0.0, 0, from.z if opening.side != 0.0 else from.z + 4.0)
		var branch_to := from - inward * 7.0
		var closest := Geometry3D.get_closest_point_to_segment(Vector3(x, 0, z), branch_from, branch_to)
		distance = minf(distance, Vector2(closest.x - x, closest.z - z).length() - PATH_HALF_WIDTH * 0.6)
	return distance + _edge_noise.get_noise_2d(x, z) * 0.45


# How far a spot inside the Glenn is from the foot of the nearest hedge (for the shade there).
func hedge_distance(x: float, z: float) -> float:
	if absf(x) > HALF_X or absf(z) > HALF_Z:
		return INF
	return minf(INNER_X - absf(x), INNER_Z - absf(z))


# How far a spot is outside the hedges (negative inside).
static func outside_distance(x: float, z: float) -> float:
	return maxf(absf(x) - HALF_X, absf(z) - HALF_Z)


func ground_height(x: float, z: float) -> float:
	var rise := smoothstep(2.0, 14.0, outside_distance(x, z))
	return rise * 0.6 # Roughly; the ground rolls a little more than this out in the woods.


# --- Building it all ---

func build() -> void:
	for child in _generated.get_children():
		child.queue_free()
	for child in _air.get_children():
		child.queue_free()
	_lanterns.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var detail: Dictionary = DETAIL[_graphics()]

	var mask := Meadow.path_mask(WORLD_SIZE, path_distance, hedge_distance)
	_add(Meadow.ground(WORLD_SIZE, mask, outside_distance))
	_add(Meadow.far_hills(68.0, 150.0, SEED))
	_grow_grass(detail)
	_add(Meadow.flowers(detail.flowers, Rect2(-WOODS_REACH, -WOODS_REACH, WOODS_REACH * 2.0, WOODS_REACH * 2.0), rng, _grass_weight, ground_height))
	_add_hedges(rng)
	_add_woods(rng, detail.woods)
	_add_path_things(rng)
	_add_undergrowth(rng)
	_air.add_child(Atmosphere.fireflies(detail.fireflies))
	_air.add_child(Atmosphere.falling_leaves(detail.leaves))


func _add(node: Node3D) -> Node3D:
	_generated.add_child(node)
	return node


func _graphics() -> String:
	return "medium" if Engine.is_editor_hint() else Settings.get_value("graphics")


# How thick the grass grows at a spot: none on the paths, short at their edges, none under
# the hedges.
func _grass_weight(x: float, z: float) -> float:
	if outside_distance(x, z) > -HEDGE_THICKNESS and outside_distance(x, z) < 0.3:
		return 0.0 # Under the hedge.
	if Vector2(x, z).length() > WOODS_REACH + 4.0:
		return 0.0
	return smoothstep(-0.1, 1.2, path_distance(x, z))


func _grow_grass(detail: Dictionary) -> void:
	for child in _generated.get_children():
		if child.name.begins_with("Grass"):
			child.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 1
	# Most of the grass goes inside the Glenn, where you walk; the rest out round the edges.
	var inside: int = int(detail.grass * 0.65)
	var tufts := Meadow.grass(inside, Rect2(-HALF_X, -HALF_Z, HALL_WIDTH, HALL_LENGTH), rng, _grass_weight, ground_height)
	tufts.append_array(Meadow.grass(detail.grass - inside, Rect2(-HALF_X - 14.0, -HALF_Z - 14.0, HALL_WIDTH + 28.0, HALL_LENGTH + 28.0), rng, _grass_weight, ground_height))
	for tuft in tufts:
		_add(tuft)
	_grass_material = tufts[0].material_override if not tufts.is_empty() else null


# The hedges round the Glenn, with gaps where the openings are.
func _add_hedges(rng: RandomNumberGenerator) -> void:
	var line_x := HALF_X - HEDGE_THICKNESS / 2.0
	var line_z := HALF_Z - HEDGE_THICKNESS / 2.0
	var gap := Gates.OPENING / 2.0 + 0.55
	var walls := [
		[Vector3(-line_x, 0, HALF_Z), Vector3(-line_x, 0, -HALF_Z), -1.0],
		[Vector3(line_x, 0, HALF_Z), Vector3(line_x, 0, -HALF_Z), 1.0],
		[Vector3(-HALF_X, 0, -line_z), Vector3(HALF_X, 0, -line_z), 0.0],
		[Vector3(-HALF_X, 0, line_z), Vector3(HALF_X, 0, line_z), 2.0],
	]
	for wall in walls:
		var from: Vector3 = wall[0]
		var to: Vector3 = wall[1]
		var length := from.distance_to(to)
		var along := (to - from) / length
		# Where along this wall the gaps are.
		var cuts := []
		for opening in _openings:
			if opening.side == wall[2]:
				var at: float = (opening.position - from).dot(along)
				cuts.append([at - gap, at + gap])
		cuts.sort_custom(func(a, b): return a[0] < b[0])
		var start := 0.0
		for cut in cuts + [[length, length]]:
			if cut[0] - start > 0.3:
				# The south end, behind the camera, is a low garden hedge, so it doesn't block the view.
				var height := (1.1 if wall[2] == 2.0 else HEDGE_HEIGHT) * rng.randf_range(0.97, 1.05)
				_add(Foliage.hedge(from + along * start, from + along * cut[0], HEDGE_THICKNESS, height, rng))
			start = cut[1]


# The woods all round: groves of oaks, birches and pines, with autumn colour here and there.
func _add_woods(rng: RandomNumberGenerator, amount: float) -> void:
	var groves := FastNoiseLite.new()
	groves.seed = SEED
	groves.frequency = 0.045
	var glades := FastNoiseLite.new()
	glades.seed = SEED + 5
	glades.frequency = 0.08
	var spacing := 4.4 / sqrt(amount)
	var steps := int(WOODS_REACH * 2.0 / spacing)
	for gz in steps:
		for gx in steps:
			var x := -WOODS_REACH + (gx + rng.randf_range(0.1, 0.9)) * spacing
			var z := -WOODS_REACH + (gz + rng.randf_range(0.1, 0.9)) * spacing
			var back := outside_distance(x, z)
			if back < 1.6 or Vector2(x, z).length() > WOODS_REACH:
				continue
			if path_distance(x, z) < 1.6:
				continue # Keep the side paths clear, so they lead off into the trees.
			if z > HALF_Z - 2.0 and z < HALF_Z + 16.0 and absf(x) < HALF_X + 8.0:
				continue # Room for the camera behind the start.
			if glades.get_noise_2d(x, z) > 0.45:
				continue # Leave a sunny glade.
			var depth := clampf(back / 20.0, 0.0, 1.0) # 0 by the hedge, 1 deep in the woods.
			var grove := groves.get_noise_2d(x, z)
			var kind := "pine" if grove < -0.25 else ("birch" if grove > 0.3 else "oak")
			var palette := ""
			if kind != "pine" and rng.randf() < 0.28:
				palette = ["amber", "rust", "gold"][rng.randi() % 3]
			var size := lerpf(0.85, 1.35, depth) * rng.randf_range(0.85, 1.15)
			var made := Foliage.tree(kind, rng, size, palette)
			made.position = Vector3(x, ground_height(x, z) - 0.1, z)
			made.rotation.y = rng.randf() * TAU
			_add(made)


# Along the path: lanterns, finger-posts to the games, and rocks to jump on.
func _add_path_things(rng: RandomNumberGenerator) -> void:
	var side := 1.0
	var z := HALF_Z - 6.0
	var shadowed := 0
	while z > -HALF_Z + 4.0:
		var clear := true
		for opening in _openings:
			if opening.side != 0.0 and absf(opening.position.z - z) < 3.5:
				clear = false
		if clear:
			# The nearest few lanterns cast shadows; the rest just glow (shadows cost a lot).
			var lantern := Props.lantern(shadowed < 3 and _graphics() == "high")
			shadowed += 1
			lantern.position = Vector3(path_x(z) + side * (PATH_HALF_WIDTH + 0.7), 0, z)
			lantern.rotation.y = 0.0 if side < 0.0 else PI # Hanging out over the path.
			_add(lantern)
			_lanterns.append(lantern.get_meta("light"))
		z -= LANTERN_SPACING
		side = -side
	for opening in _openings:
		if not opening.is_open() or opening.side == 0.0:
			continue
		var post_z: float = opening.position.z + FINGERPOST_BEFORE
		var post := Props.fingerpost(opening.title(), opening.side)
		post.position = Vector3(path_x(post_z) + opening.side * (PATH_HALF_WIDTH + 0.45), 0, post_z)
		_add(post)
	for i in ROCK_COUNT:
		# Along the hedges, spread down the Glenn, never in front of an opening.
		var rock_z := HALF_Z - 4.0 - (i + 0.5) / ROCK_COUNT * (HALL_LENGTH - 10.0)
		var rock_side := 1.0 if i % 2 == 0 else -1.0
		var blocked := false
		for opening in _openings:
			if opening.side == rock_side and absf(opening.position.z - rock_z) < 4.0:
				blocked = true
		if blocked:
			continue
		var width := 0.6 + 0.3 * fmod(i * 0.618, 1.0)
		var height := 0.55 + 0.25 * fmod(i * 0.382, 1.0)
		var rock := Props.rock(rng, width, height)
		rock.position = Vector3(rock_side * (INNER_X - 1.1 - fmod(i * 0.618, 1.0) * 1.2), 0, rock_z)
		_add(rock)


# Ferns, toadstools and pumpkins at the foot of the hedges, and bushes outside them.
func _add_undergrowth(rng: RandomNumberGenerator) -> void:
	for i in 70:
		var west := rng.randf() < 0.5
		var z := rng.randf_range(-INNER_Z + 1.0, INNER_Z - 1.0)
		var x := (INNER_X - rng.randf_range(0.2, 0.9)) * (-1.0 if west else 1.0)
		if _near_opening(x, z, 2.2) or path_distance(x, z) < 0.6:
			continue
		var roll := rng.randf()
		var made: Node3D
		if roll < 0.6:
			made = Foliage.fern(rng, rng.randf_range(0.8, 1.3))
		elif roll < 0.85:
			made = Props.mushrooms(rng)
		else:
			made = Props.pumpkin(rng, rng.randf_range(0.7, 1.3))
		made.position = Vector3(x, 0, z)
		made.rotation.y = rng.randf() * TAU
		_add(made)
	# A little pile of pumpkins by each open gate, like a harvest welcome.
	for opening in _openings:
		if not opening.is_open():
			continue
		for k in rng.randi_range(2, 3):
			var pumpkin := Props.pumpkin(rng, rng.randf_range(0.8, 1.4))
			var across: Vector3 = opening.basis.x * (Gates.OPENING / 2.0 + 0.9 + k * 0.45) * (1.0 if k % 2 == 0 else -1.0)
			pumpkin.position = opening.position + opening.basis.z * (HEDGE_THICKNESS / 2.0 + 0.4) + across
			_add(pumpkin)
	# Bushes and stumps just outside the hedges, so the woods start with an untidy edge.
	for i in 90:
		var angle := rng.randf() * TAU
		var x := cos(angle) * 60.0
		var z := sin(angle) * 60.0
		var scale := minf((HALF_X + rng.randf_range(0.6, 3.5)) / absf(x), (HALF_Z + rng.randf_range(0.6, 3.5)) / absf(z))
		x *= scale
		z *= scale
		if path_distance(x, z) < 1.2 or (z > HALF_Z - 1.0 and absf(x) < HALF_X + 3.0):
			continue
		var made := Foliage.bush(rng, rng.randf_range(0.8, 1.4), "bush" if rng.randf() < 0.8 else "amber") if rng.randf() < 0.85 else Props.stump(rng)
		made.position = Vector3(x, ground_height(x, z), z)
		_add(made)


func _near_opening(x: float, z: float, distance: float) -> bool:
	for opening in _openings:
		if Vector2(opening.position.x - x, opening.position.z - z).length() < distance:
			return true
	return false


# --- Graphics settings ---

# Turn the expensive effects up or down. Low still looks like Lanternwood, just simpler.
func apply_graphics(regrow: bool) -> void:
	var level := _graphics()
	var env := environment.environment
	env.ssao_enabled = level != "low"
	env.ssil_enabled = level == "high"
	env.volumetric_fog_enabled = level != "low"
	env.glow_enabled = true
	env.sdfgi_enabled = false # Lovely, but too slow for the size of the woods.
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0 if level == "high" else (55.0 if level == "medium" else 35.0)
	RenderingServer.directional_shadow_atlas_set_size(4096 if level == "high" else 2048, true)
	get_viewport().msaa_3d = Viewport.MSAA_4X if level == "high" else (Viewport.MSAA_2X if level == "medium" else Viewport.MSAA_DISABLED)
	if regrow:
		_grow_grass(DETAIL[level])
		for child in _air.get_children():
			child.queue_free()
		_air.add_child(Atmosphere.fireflies(DETAIL[level].fireflies))
		_air.add_child(Atmosphere.falling_leaves(DETAIL[level].leaves))


# --- Every frame ---

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	# Lanterns flicker gently, each in its own rhythm.
	for i in _lanterns.size():
		var t := _time * 3.0 + i * 1.7
		_lanterns[i].light_energy = 1.6 * (0.9 + 0.06 * sin(t * 2.3) + 0.04 * sin(t * 5.1 + 1.0))
	if _grass_material:
		_grass_material.set_shader_parameter("player_position", gnome.global_position)
	_air.global_position = Vector3(gnome.global_position.x, 0, gnome.global_position.z)
	gnome.camera_yaw = camera_rig.yaw
	_update_openings()


# Walking up to an opening shows its prompt; walking away puts away its card too.
func _update_openings() -> void:
	var here := _opening_at()
	if here != _near:
		_near = here
		if _offering and _offering != _near:
			_close_card()
		_show_prompt()


# F (or □): at an opening, the first press shows what's there and the second goes in.
# Anywhere else, the gnome swings its stick, just for fun.
func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event.is_action_pressed("interact"):
		if _offering:
			_play(_offering)
		elif _near and _near.is_open():
			_open_card(_near)
		elif _near:
			hud.show_toast("This way isn't open yet. Come back soon!")
		elif gnome.swing_stick():
			Sound.play_swing()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("back") and _offering:
		_close_card()
		get_viewport().set_input_as_handled()


# Esc puts away the game card before it would open the pause menu. True if there was one.
func dismiss() -> bool:
	if not _offering:
		return false
	_close_card()
	return true


func _opening_at() -> Node:
	var best: Node = null
	var best_distance := INTERACT_RANGE
	for opening in _openings:
		var spot: Vector3 = opening.spot()
		var distance := Vector2(gnome.global_position.x - spot.x, gnome.global_position.z - spot.z).length()
		if distance < best_distance:
			best = opening
			best_distance = distance
	return best


func _show_prompt() -> void:
	if not hud:
		return
	if _near and not _offering:
		hud.show_prompt(_near.title())
	else:
		hud.hide_prompt()


func _open_card(opening: Node) -> void:
	_offering = opening
	Sound.play_pop()
	hud.show_card(GAMES[opening.game])
	_show_prompt()


func _close_card() -> void:
	_offering = null
	if hud:
		hud.hide_card()
	_show_prompt()


func _play(opening: Node) -> void:
	var game: String = opening.game
	_close_card()
	play_requested.emit(game)
