## Ambient wildlife (13_STARTING_ZONE_ENCOUNTER_DESIGN.md §2, family 6): a few
## Golden-Fleece Sheep grazing a meadow, or Red Foxes trotting the weald edge.
## Not fighters, just life: each wanders round the flock's spot on a seeded,
## clock-driven path (the same on every peer), stops to graze, and keeps to the
## ground. Built in code from simple shapes.
class_name AmbientFlock
extends Node3D

enum Kind { SHEEP, FOX }

const FLEECE: Color = Color(0.95, 0.88, 0.62)
const SHEEP_FACE: Color = Color(0.24, 0.22, 0.22)
const FOX_RED: Color = Color(0.86, 0.42, 0.18)
const FOX_WHITE: Color = Color(0.96, 0.94, 0.9)
## Metres a second, and seconds spent grazing at each stop.
const SPEEDS: Array[float] = [0.7, 2.2]
const PAUSES: Array[float] = [4.0, 1.5]

@export var kind: Kind = Kind.SHEEP
@export var count: int = 4
@export var roam_radius: float = 10.0
@export var flock_seed: int = 1

var critters: Array[Node3D] = []
var _stops: Array[PackedVector3Array] = []


func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = flock_seed
	for index: int in count:
		var critter: Node3D = _build_sheep() if kind == Kind.SHEEP else _build_fox()
		critter.name = "%s%d" % ["Sheep" if kind == Kind.SHEEP else "Fox", index + 1]
		add_child(critter)
		critters.append(critter)
		var stops: PackedVector3Array = PackedVector3Array()
		for stop: int in 5:
			var angle: float = rng.randf() * TAU
			stops.append(Vector3(cos(angle), 0.0, sin(angle)) * rng.randf_range(0.5, roam_radius))
		_stops.append(stops)


func _process(_delta: float) -> void:
	var now: float = CombatDirector.game_time() + flock_seed * 3.7
	var speed: float = SPEEDS[kind]
	var pause: float = PAUSES[kind]
	for index: int in critters.size():
		var stops: PackedVector3Array = _stops[index]
		var leg: float = roam_radius * 1.2 / speed + pause
		var cycle: float = fposmod(now + index * 2.3, leg * stops.size())
		var at: int = int(cycle / leg)
		var t: float = clampf((cycle - at * leg) / (leg - pause), 0.0, 1.0)
		var from: Vector3 = stops[at]
		var to: Vector3 = stops[(at + 1) % stops.size()]
		var local: Vector3 = from.lerp(to, smoothstep(0.0, 1.0, t))
		var world: Vector3 = global_position + local
		var critter: Node3D = critters[index]
		critter.global_position = Vector3(world.x, WorldGridConfig.layout.sample_height(world.x, world.z), world.z)
		var heading: Vector3 = to - from
		if heading.length() > 0.1:
			critter.rotation.y = atan2(-heading.x, -heading.z)
		# A little bob as they go, and a dip of the head while they graze.
		(critter.get_child(0) as Node3D).position.y = absf(sin(now * 9.0 + index)) * 0.06 if t < 1.0 else 0.0


func _build_sheep() -> Node3D:
	var root: Node3D = Node3D.new()
	var body: Node3D = Node3D.new()
	root.add_child(body)
	var fleece: Material = StorybookMaterial.make(FLEECE, StorybookMaterial.ACTOR_RIM, Color(1.0, 0.95, 0.8))
	var face: Material = StorybookMaterial.make(SHEEP_FACE)
	body.add_child(ShapeKit.stretched(ShapeKit.sphere("Fleece", 0.42, Vector3(0.0, 0.62, 0.0), fleece), Vector3(0.9, 0.85, 1.25)))
	body.add_child(ShapeKit.sphere("Head", 0.18, Vector3(0.0, 0.72, -0.55), face))
	for corner: Vector2 in [Vector2(-0.18, -0.28), Vector2(0.18, -0.28), Vector2(-0.18, 0.28), Vector2(0.18, 0.28)]:
		body.add_child(ShapeKit.cylinder("Leg", 0.05, 0.05, 0.4, Vector3(corner.x, 0.2, corner.y), face, 6))
	return root


func _build_fox() -> Node3D:
	var root: Node3D = Node3D.new()
	var body: Node3D = Node3D.new()
	root.add_child(body)
	var red: Material = StorybookMaterial.make(FOX_RED, StorybookMaterial.ACTOR_RIM, Color(1.0, 0.8, 0.6))
	var white: Material = StorybookMaterial.make(FOX_WHITE)
	body.add_child(ShapeKit.stretched(ShapeKit.sphere("Body", 0.22, Vector3(0.0, 0.38, 0.0), red), Vector3(0.8, 0.8, 1.7)))
	body.add_child(ShapeKit.sphere("Head", 0.15, Vector3(0.0, 0.46, -0.42), red))
	body.add_child(ShapeKit.tilted(ShapeKit.cone("Snout", 0.07, 0.18, Vector3(0.0, 0.43, -0.58), white), Vector3(-PI * 0.5, 0.0, 0.0)))
	for side: float in [-1.0, 1.0]:
		body.add_child(ShapeKit.cone("Ear", 0.05, 0.12, Vector3(side * 0.08, 0.6, -0.4), red))
	body.add_child(ShapeKit.tilted(ShapeKit.stretched(ShapeKit.sphere("Tail", 0.12, Vector3(0.0, 0.42, 0.48), red), Vector3(0.9, 0.9, 2.2)), Vector3(0.4, 0.0, 0.0)))
	body.add_child(ShapeKit.sphere("TailTip", 0.07, Vector3(0.0, 0.5, 0.72), white))
	for corner: Vector2 in [Vector2(-0.09, -0.18), Vector2(0.09, -0.18), Vector2(-0.09, 0.2), Vector2(0.09, 0.2)]:
		body.add_child(ShapeKit.cylinder("Leg", 0.03, 0.03, 0.28, Vector3(corner.x, 0.14, corner.y), red, 6))
	return root
