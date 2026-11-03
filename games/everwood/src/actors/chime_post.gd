## A Nursery-Rhyme Chime-Post (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §4.2
## kit_chime_post_diagnostic; 15 GDD §6.2): a 2.6 m carved oak way-post at a
## zone threshold, bridge approach or Hush-Crack trailhead, with a curved
## cross-arm, four painted Scribe Sign vanes and a bronze chime-lantern
## swaying from the arm. A local player walking within 6 m rings it, and its
## place's nursery rhyme unfurls its next couplet on that player's Chime-Post
## ribbon (CrossGrimoireHUD). Each player can ring it again after a while.
## It's only for looks, sound and coaching: each peer reacts to its own players.
class_name ChimePost
extends Node3D

signal rung(player_id: StringName)

const RING_RADIUS: float = 6.0
## Seconds before the same player rings it again.
const COOLDOWN: float = 25.0
const SWAY: float = 0.06
const SWING: float = 0.5
const SWING_DAMPING: float = 1.8

## The place whose rhyme it sings (a MythopoeticAtlas place; empty: the level's home place).
@export var place: String = ""

var rings: int = 0

var _pivot: Node3D
var _cooldowns: Dictionary[StringName, float] = {}
var _swing: float = 0.0
var _age: float = 0.0


func _ready() -> void:
	add_to_group(WorldAtmosphereDirector.LANTERN_GROUP)
	add_child(WorldAssetCatalog.build(WorldVisualCatalog.KIT_CHIME_POST_DIAGNOSTIC))
	_pivot = Node3D.new()
	_pivot.name = "ChimeLantern"
	_pivot.position = Vector3(0.78, 2.36, 0.0)
	add_child(_pivot)
	var lantern: MeshInstance3D = MeshInstance3D.new()
	lantern.name = "Lantern"
	lantern.mesh = WorldAssetCatalog.chime_lantern_mesh()
	lantern.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pivot.add_child(lantern)
	var glow: OmniLight3D = WorldAssetCatalog.light("Light", WorldVisualCatalog.WARM_HEARTH, 0.7, 3.5)
	glow.position = Vector3(0.0, -0.5, 0.0)
	_pivot.add_child(glow)
	_age = position.x * 0.7 + position.z * 1.3


## The zone whose rhyme it sings.
func zone_id() -> StringName:
	var where: String = place
	if where == "":
		var level: LevelBase = get_tree().current_scene as LevelBase if is_inside_tree() else null
		where = level.home_place() if level != null else ""
	return MythopoeticAtlas.zone_for_place(where)


## A Wind-Lantern's warmth (the atmosphere dims it in a hush and flares it in weather).
func set_warmth(warmth: float) -> void:
	var glow: OmniLight3D = _pivot.get_node_or_null("Light") as OmniLight3D if _pivot != null else null
	if glow != null:
		glow.light_energy = 0.7 * warmth


func _process(delta: float) -> void:
	_age += delta
	_swing = move_toward(_swing, 0.0, SWING_DAMPING * delta * maxf(absf(_swing), 0.05))
	_pivot.rotation.z = sin(_age * 1.4) * SWAY + sin(_age * 6.0) * _swing
	for id: StringName in _cooldowns.keys():
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0.0:
			_cooldowns.erase(id)
	if CombatDirector.current == null:
		return
	for member: ActorBase in CombatDirector.current.party_actors():
		if not member.is_local_player() or member.is_companion or _cooldowns.has(member.player_id):
			continue
		var flat: Vector2 = Vector2(member.global_position.x - global_position.x, member.global_position.z - global_position.z)
		if flat.length() <= RING_RADIUS and absf(member.global_position.y - global_position.y) < 4.0:
			ring(member)


## Rings for a player: a soft chime, and their ribbon unfurls this place's next couplet.
func ring(member: ActorBase) -> void:
	rings += 1
	_cooldowns[member.player_id] = COOLDOWN
	_swing = SWING
	AudioCues.play_at(&"chime", global_position + Vector3.UP * 2.0, 1.25, -6.0)
	var zone: StringName = zone_id()
	var hud: PlayerHUD = PlayerHUD.for_actor(get_tree(), member)
	if zone != &"" and hud != null and hud.cross_grimoire != null:
		hud.cross_grimoire.show_rhyme_ribbon(zone, true)
	rung.emit(member.player_id)
