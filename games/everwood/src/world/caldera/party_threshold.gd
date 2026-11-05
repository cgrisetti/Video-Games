## A threshold the whole party walks through together (the Sea-Door into the
## Sap Galleries, and back out): once every standing hero is within `radius`
## for a moment, the host says `crossed` and the level moves the party. A
## glowing ring shows it while it's open.
class_name PartyThreshold
extends Node3D

signal crossed(threshold: PartyThreshold)

const HOLD_TIME: float = 0.8

@export var radius: float = 4.0
@export var enabled: bool = true:
	set(value):
		enabled = value
		if _ring != null:
			_ring.visible = value
## Where the party goes (in the island's frame), and which way they face there.
@export var destination: Vector3 = Vector3.ZERO
@export var destination_yaw: float = 0.0
@export var ring_color: Color = Color(0.96, 0.8, 0.4)

var _held: float = 0.0
var _ring: MeshInstance3D


func _ready() -> void:
	_ring = ShapeKit.no_shadow(ShapeKit.torus("Ring", radius - 0.25, radius, Vector3(0.0, 0.08, 0.0), CalderaKit.glow(ring_color, 1.6)))
	_ring.scale = Vector3(1.0, 0.15, 1.0)
	_ring.visible = enabled
	add_child(_ring)


func _physics_process(delta: float) -> void:
	if not enabled or (NetworkManager.current.is_online() and not NetworkManager.current.is_host()):
		_held = 0.0
		return
	var standing: int = 0
	var inside: int = 0
	for member: ActorBase in CombatDirector.current.party_actors():
		if member.stats.is_downed:
			continue
		standing += 1
		if Vector2(member.global_position.x - global_position.x, member.global_position.z - global_position.z).length() <= radius:
			inside += 1
	if standing == 0 or inside < standing:
		_held = 0.0
		return
	_held += delta
	if _held >= HOLD_TIME:
		_held = -10.0
		crossed.emit(self)
