## One of the isles' friendly folk (12_WORLD_OAKSHIRE_VALE_GDD.md §5): a sculpted
## storybook figure (StorybookFigure, docs/24 §5) on the heroes' own skeleton, in
## a Calling's look dyed in their colours (a village child as a youth), posed
## from the clip library, running a deterministic idle loop (the same on every
## peer, from the game clock and its seed):
##   QUEST_GIVER  a cloaked figure under a floating gold "!", in a three-quest
##                hub; light shows their quests (quests_offered)
##   VENDOR       an aproned merchant at a stall: weapons, armour, an
##                apothecary, a Chime-Vault banker or a Calling tutor; light
##                opens their wares (wares_requested)
##   GUARD        a Bridge-Warden or Hearth-Guard sentry with spear and shield,
##                glancing left and right from their post
##   VILLAGER     strolls a little round of waypoints, pausing at each
class_name TownsfolkNPC
extends Interactable

signal quests_offered(actor: ActorBase, npc: TownsfolkNPC)
signal wares_requested(actor: ActorBase, npc: TownsfolkNPC)

enum Role { QUEST_GIVER, VENDOR, GUARD, VILLAGER }
enum Wares { NONE, WEAPONS, ARMOR, APOTHECARY, BANKER, CALLING_TUTOR }

const WALK_SPEED: float = 1.1
const PAUSE_TIME: float = 3.2
const GLANCE_TIME: float = 6.0
const GLANCE_ANGLE: float = 0.6
const SKIN: Color = Color(0.95, 0.8, 0.66)
const QUEST_GOLD: Color = Color(1.0, 0.82, 0.25)
const GUARD_STEEL: Color = Color(0.62, 0.64, 0.68)
const APRON_COLOR: Color = Color(0.86, 0.8, 0.66)

@export var role: Role = Role.VILLAGER
@export var npc_name: String = ""
## What they are: "Bowyer", "Bridge-Warden", "Miller".
@export var title: String = ""
## Their quest hub ("Oakshire-Wick").
@export var hub: String = ""
@export var quests: PackedStringArray = PackedStringArray()
@export var wares: Wares = Wares.NONE
## What they sell, in a few words ("Yew Longbows").
@export var wares_note: String = ""
## A villager's round, as world positions on the ground (a guard's post faces route[0] when set).
@export var route: PackedVector3Array = PackedVector3Array()
@export var body_color: Color = Color(0.5, 0.4, 0.6)
@export var accent_color: Color = Color(0.4, 0.3, 0.2)
@export var npc_seed: int = 1

var _body: Node3D
var _figure: StorybookFigure
var _marker: Label3D
var _home: Vector3 = Vector3.ZERO
var _home_yaw: float = 0.0


func _ready() -> void:
	_home = global_position
	_home_yaw = rotation.y
	# Quest-givers are quest locations on the map (CartographyBaker.GLYPH_GROUP, 13_PLAYTEST §2.4).
	if role == Role.QUEST_GIVER:
		add_to_group(&"map_glyphs")
	reach = 2.6 if role == Role.QUEST_GIVER or role == Role.VENDOR else 0.0
	# Only those you can talk to need to watch for players.
	set_physics_process(reach > 0.0)
	_build()


func prompt_for(_actor: ActorBase) -> String:
	match role:
		Role.QUEST_GIVER:
			return "%s, %s · light: hear their %d quests" % [npc_name, title, quests.size()]
		Role.VENDOR:
			return "%s, %s · light: %s" % [npc_name, title, wares_note]
	return ""


func interact(actor: ActorBase) -> void:
	match role:
		Role.QUEST_GIVER:
			quests_offered.emit(actor, self)
		Role.VENDOR:
			wares_requested.emit(actor, self)


func _process(_delta: float) -> void:
	var now: float = CombatDirector.game_time() + npc_seed * 1.37
	match role:
		Role.VILLAGER:
			_stroll(now)
		Role.GUARD:
			rotation.y = _home_yaw + sin(TAU * now / (GLANCE_TIME * 2.0)) * GLANCE_ANGLE * smoothstep(0.3, 0.7, absf(sin(TAU * now / (GLANCE_TIME * 2.0))))
		Role.VENDOR:
			_body.rotation.y = sin(now * 0.8) * 0.15
		Role.QUEST_GIVER:
			_marker.position.y = 2.45 + sin(now * 2.4) * 0.12



## Walk the round: home, then each waypoint, pausing at each, at a stroll.
func _stroll(now: float) -> void:
	var stops: PackedVector3Array = PackedVector3Array([_home])
	stops.append_array(route)
	if stops.size() < 2:
		return
	var legs: PackedFloat32Array = PackedFloat32Array()
	var total: float = 0.0
	for index: int in stops.size():
		var leg: float = stops[index].distance_to(stops[(index + 1) % stops.size()]) / WALK_SPEED + PAUSE_TIME
		legs.append(leg)
		total += leg
	var t: float = fposmod(now, total)
	var at: int = 0
	while t > legs[at] and at < legs.size() - 1:
		t -= legs[at]
		at += 1
	var from: Vector3 = stops[at]
	var to: Vector3 = stops[(at + 1) % stops.size()]
	var walking: float = legs[at] - PAUSE_TIME
	var progress: float = clampf((t - PAUSE_TIME) / maxf(0.01, walking), 0.0, 1.0)
	global_position = from.lerp(to, progress)
	if progress > 0.0 and progress < 1.0:
		var heading: Vector3 = to - from
		rotation.y = atan2(-heading.x, -heading.z)
		_figure.walk_speed = WALK_SPEED
	else:
		_figure.walk_speed = 0.0


func _build() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	_figure = StorybookFigure.new()
	_figure.name = "Figure"
	var picked: Array = _pick_look()
	_figure.build(picked[0], picked[1], body_color, accent_color, float(npc_seed) * 1.37)
	_body.add_child(_figure)
	match role:
		Role.GUARD:
			# A long ash spear in the hand and the banded greatshield on the off forearm.
			var steel: Material = StorybookMaterial.make(GUARD_STEEL, StorybookMaterial.ACTOR_RIM * 0.6)
			var spear: Node3D = Node3D.new()
			spear.name = "Spear"
			spear.add_child(ShapeKit.cylinder("Haft", 0.022, 0.022, 2.3, Vector3(0.0, 0.55, 0.0), StorybookMaterial.make(Color(0.42, 0.3, 0.18)), 6))
			spear.add_child(ShapeKit.cone("Spearhead", 0.05, 0.22, Vector3(0.0, 1.8, 0.0), steel))
			_figure.hold(HeroRigBuilder.MAIN_HAND_SOCKET, spear, HeroMeshAtelier.GRIP_MOUNT)
			_figure.hold(HeroRigBuilder.OFF_HAND_SOCKET, HeroMeshAtelier.build_greatshield(_figure.material), ActorVisuals.SHIELD_ON_FOREARM)
		Role.QUEST_GIVER:
			_marker = Label3D.new()
			_marker.name = "QuestMarker"
			_marker.text = "!"
			_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			_marker.font_size = 96
			_marker.outline_size = 20
			_marker.pixel_size = 0.008
			_marker.modulate = QUEST_GOLD
			_marker.position = Vector3(0.0, 2.45, 0.0)
			add_child(_marker)
	if role == Role.QUEST_GIVER or role == Role.VENDOR or role == Role.GUARD:
		var label: Label3D = Label3D.new()
		label.name = "NameLabel"
		label.text = npc_name if title == "" else "%s\n%s" % [npc_name, title]
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 30
		label.outline_size = 8
		label.pixel_size = 0.006
		label.modulate = QUEST_GOLD.lightened(0.4) if role == Role.QUEST_GIVER else Color(0.92, 0.94, 1.0)
		label.position = Vector3(0.0, 2.05, 0.0)
		label.visibility_range_end = 26.0
		add_child(label)


## [look, coat] for this townsperson, by role, from their seed: guards in the
## Shield-Sworn's kettle-caps and ring-coats, merchants and quest-givers in
## linen, villagers in any Calling's look or, one in three, a village child.
func _pick_look() -> Array:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = npc_seed * 7919 + int(role)
	var ids: Array[StringName] = []
	var coat: StringName = ArsenalCatalog.BRAMBLE_JERKIN
	match role:
		Role.GUARD:
			ids = [&"bridge_warden", &"hearth_guard", &"weald_captain"]
			coat = ArsenalCatalog.IRONWOOD_PLATE
		Role.VENDOR:
			ids = [&"bell_keeper", &"sign_seeker", &"lantern_scribe", &"hearth_guard"]
			coat = ArsenalCatalog.HEARTH_LINEN
		Role.QUEST_GIVER:
			ids = [&"hedge_runner", &"wind_mender", &"iron_woodsman"]
			coat = ArsenalCatalog.HEARTH_LINEN
		_:
			if rng.randf() < 0.34:
				var youth: Array[HeroAppearanceResource] = catalog.youth_appearances()
				return [youth[rng.randi_range(0, youth.size() - 1)], ArsenalCatalog.BRAMBLE_JERKIN]
			ids = [&"iron_woodsman", &"hedge_runner", &"sign_seeker", &"bell_keeper", &"wind_mender", &"bridge_warden", &"lantern_scribe"]
			coat = [ArsenalCatalog.BRAMBLE_JERKIN, ArsenalCatalog.RANGER_LEATHER, ArsenalCatalog.HEARTH_LINEN][rng.randi_range(0, 2)]
	var base: HeroAppearanceResource = catalog.hero_appearance(ids[rng.randi_range(0, ids.size() - 1)])
	var dyes: Array[HeroAppearanceResource] = catalog.heritage_dyes()
	return [base.with_dye(dyes[rng.randi_range(0, dyes.size() - 1)]), coat]
