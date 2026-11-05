## A warm spring on The Crown's Ring Path (docs/20 Part II §1.8: "warm springs
## are checkpoints", fed by the dome's heat): stepping within 6 m makes it
## where that hero gets back up when downed, and sends a gentle Warm-Hearth
## pulse through the party nearby (+20 HP), no more than once in a while.
## Existing systems only: the spawn point, CombatDirector heals, a call-out.
class_name WarmSpring
extends Node3D

signal warmed(actor: ActorBase)

const RADIUS: float = 6.0
const HEAL: float = 20.0
## The pulse reaches party members this far from the spring (Dawnburst's 10 m).
const PULSE_RADIUS: float = 10.0
const COOLDOWN: float = 20.0

@export var spring_name: String = ""
## A plain respawn anchor (the Waypost's lantern) shows no pool and sends no pulse.
@export var show_pool: bool = true
@export var heals: bool = true

var pulses: int = 0

var _inside: Dictionary[StringName, bool] = {}
var _cooldown_left: float = 0.0


func _ready() -> void:
	add_to_group(&"map_glyphs")
	if not show_pool:
		return
	var pool: LandblockTerrain.MeshMerge = CalderaKit.merge()
	for index: int in 14:
		var angle: float = TAU * float(index) / 14.0
		CalderaKit.add_sphere(pool, Vector3(cos(angle) * 4.2, 0.1, sin(angle) * 4.2), 0.7, CalderaKit.STONE.darkened(0.1 * float(index % 3)), 0.6, 6)
	add_child(CalderaKit.mesh_node("Rim", pool))
	var water: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.cylinder("Water", 3.9, 3.9, 0.08, Vector3(0.0, 0.12, 0.0),
		StorybookMaterial.glowing(Color(0.62, 0.86, 0.84), 0.6)))
	add_child(water)
	CalderaKit.plume(self, "Steam", Vector3(0.0, 0.4, 0.0), Color(0.96, 0.96, 0.94, 0.5), 1.4, 2.6, 16)
	CalderaKit.light(self, "Glow", Vector3(0.0, 1.0, 0.0), Color(1.0, 0.86, 0.6), 1.2, 9.0)
	CalderaKit.sign_label(self, "Sign", "%s\nwarm spring: a checkpoint" % spring_name, Vector3(0.0, 2.4, 0.0))


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	for member: ActorBase in CombatDirector.current.party_actors():
		if member.stats.is_downed:
			continue
		var flat: Vector2 = Vector2(member.global_position.x - global_position.x, member.global_position.z - global_position.z)
		var inside: bool = flat.length() <= RADIUS
		var was: bool = _inside.get(member.player_id, false)
		_inside[member.player_id] = inside
		if inside and not was:
			_warm(member)


func _warm(actor: ActorBase) -> void:
	if actor.is_multiplayer_authority():
		var column: float = float(actor.party_slot % 4) - 1.5
		actor.spawn_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(column * 1.6, 0.3, RADIUS * 0.6))
	warmed.emit(actor)
	if not heals or _cooldown_left > 0.0 or not (NetworkManager.current == null or NetworkManager.current.is_host() or not NetworkManager.current.is_online()):
		return
	_cooldown_left = COOLDOWN
	pulses += 1
	for member: ActorBase in CombatDirector.current.party_actors():
		if not member.stats.is_downed and member.global_position.distance_to(global_position) <= PULSE_RADIUS:
			CombatDirector.current.apply_heal(actor, member, HEAL)
	CombatDirector.current.announce(global_position + Vector3.UP * 2.0, "%s: warm spring, +%d" % [spring_name, int(HEAL)],
		CalderaKit.HEARTH_SAFFRON, &"heal")
