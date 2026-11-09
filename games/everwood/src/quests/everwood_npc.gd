## One of Act I's named townsfolk (docs/28 §2.1; docs/29 §6): Master Alf-Wright,
## Reeve Nokes, Dame Tenar-Moss and Miller Hob. A TownsfolkNPC who speaks:
## light opens the talk box on that hero's screen (TalkBox), which stays up
## until they say goodbye, and hearing the last line tells the QuestManager
## they were spoken to. What they say comes from the director (`dialogue`), from the quest
## under way, so the same person says new things as the story moves.
##
## Forged and Restored (Hobb's "Forging"): a Forged townsperson stands grey,
## speaks flat, and keeps their services shut (a vendor's wares); restored, the
## colour floods back with a Recovery burst and their services open. Hob
## starts Forged and is restored by the party's Hearth-Warmth in Q03.
class_name EverwoodNPC
extends TownsfolkNPC

signal spoken_to(actor: ActorBase, npc: EverwoodNPC)
signal restored(npc: EverwoodNPC)

enum NpcState { RESTORED, FORGED }

const NAME_GOLD: Color = Color(1.0, 0.88, 0.56)
const FORGED_GREY: Color = Color(0.66, 0.66, 0.64)
## How grey a Forged townsperson's colours go (0 = untouched, 1 = all grey).
const FORGED_GREYING: float = 0.85

## The brief's id: &"NPC_MillerHob".
@export var npc_id: StringName = &""
@export var npc_state: NpcState = NpcState.RESTORED
## () -> PackedStringArray: what they say right now (each line "SPEAKER: words" or plain words).
var dialogue: Callable = Callable()
## Their true colours (a Forged townsperson wears them greyed).
var true_body_color: Color = Color.WHITE
var true_accent_color: Color = Color.WHITE

var _line_index: Dictionary[StringName, int] = {}
var _colors_set: bool = false
var _mist: MeshInstance3D


## Before it enters the tree: its true colours, and whether it starts Forged (greyed).
func set_colors(body: Color, accent: Color, forged: bool) -> void:
	true_body_color = body
	true_accent_color = accent
	npc_state = NpcState.FORGED if forged else NpcState.RESTORED
	body_color = _greyed(body) if forged else body
	accent_color = _greyed(accent) if forged else accent
	_colors_set = true


func _ready() -> void:
	if not _colors_set:
		set_colors(body_color, accent_color, npc_state == NpcState.FORGED)
	super._ready()
	# Anyone with lines can be spoken to, whatever their role.
	reach = 2.8
	set_physics_process(true)
	_mist = ShapeKit.no_shadow(ShapeKit.cylinder("ForgedMist", 1.1, 1.3, 0.5, Vector3(0.0, 0.25, 0.0), _mist_material(), 16))
	_mist.visible = npc_state == NpcState.FORGED
	add_child(_mist)


func _process(delta: float) -> void:
	super._process(delta)
	# The gold "!" shows only while the step under way wants this townsperson.
	if _marker != null and QuestManager.current != null:
		var step: QuestStepResource = QuestManager.current.active_step()
		_marker.visible = step != null and step.target == npc_id


func is_forged() -> bool:
	return npc_state == NpcState.FORGED


## A vendor's wares and a quest-giver's quests open only once they're whole.
func services_open() -> bool:
	return not is_forged()


func prompt_for(_actor: ActorBase) -> String:
	if is_forged():
		return "%s, %s · light: speak (he stares through you)" % [npc_name, title]
	return "%s, %s · light: speak" % [npc_name, title]


func interact(actor: ActorBase) -> void:
	var lines: PackedStringArray = current_lines()
	if lines.is_empty():
		if services_open() and role == Role.VENDOR:
			wares_requested.emit(actor, self)
		return
	# The talk box on this hero's screen (TalkBox): it stays up until they say goodbye.
	var hud: PlayerHUD = PlayerHUD.for_actor(get_tree(), actor) if is_inside_tree() else null
	if hud != null:
		var open: TalkBox = hud.talk_box()
		if open != null and open.npc == self:
			open.next_line()
		else:
			hud.open_talk(self)
		return
	# No screen for this hero (a scripted run): the lines are heard one press at a time.
	var index: int = _line_index.get(actor.player_id, 0)
	if index >= lines.size():
		index = 0
	index += 1
	_line_index[actor.player_id] = index
	if index >= lines.size():
		_line_index[actor.player_id] = 0
		heard_all(actor)


func current_lines() -> PackedStringArray:
	return dialogue.call() if dialogue.is_valid() else PackedStringArray()


## The hero has heard everything this townsperson had to say: that counts as speaking to them.
func heard_all(actor: ActorBase) -> void:
	spoken_to.emit(actor, self)
	if QuestManager.current != null:
		QuestManager.current.report(QuestStepResource.Kind.TALK_TO, npc_id)


## A line split into who says it and what they say: "NOKES: Chop them!" is Nokes speaking;
## a plain line is `speaker`'s own.
static func parse_line(line: String, speaker: String) -> PackedStringArray:
	var colon: int = line.find(": ")
	if colon > 0 and colon < 24 and line.substr(0, colon) == line.substr(0, colon).to_upper():
		return PackedStringArray([_title_case(line.substr(0, colon)), line.substr(colon + 2)])
	return PackedStringArray([speaker, line])


## "TENAR-MOSS" reads "Tenar-Moss".
static func _title_case(shout: String) -> String:
	var out: String = ""
	var start: bool = true
	for index: int in shout.length():
		var letter: String = shout[index]
		out += letter.to_upper() if start else letter.to_lower()
		start = letter == "-" or letter == " " or letter == "'"
	return out


## The townsperson standing with this one whose name holds `speaker` ("Tenar-Moss" finds
## Dame Tenar-Moss), so a two-hander shows the right face; null for this one or none.
func talk_partner(speaker: String) -> EverwoodNPC:
	if speaker == npc_name or get_parent() == null:
		return null
	var wanted: String = speaker.to_lower()
	for node: Node in get_parent().get_children():
		var other: EverwoodNPC = node as EverwoodNPC
		if other != null and other != self and other.npc_name.to_lower().contains(wanted):
			return other
	return null


## Host: the colour floods back (Hob's hearth, docs/28 §5.6), on every peer.
func restore() -> void:
	if not is_forged():
		return
	if NetworkManager.current.is_online() and NetworkManager.current.is_host():
		_restore_everywhere.rpc()
	else:
		_restore_everywhere()


@rpc("authority", "call_local", "reliable")
func _restore_everywhere() -> void:
	set_state(NpcState.RESTORED)
	if is_inside_tree():
		RecoveryBurst.bloom(get_parent(), global_position, 8.0)
	restored.emit(self)


## Sets the state without ceremony (loading a save where Hob was already cured).
func set_state(next: NpcState) -> void:
	if next == npc_state:
		return
	npc_state = next
	body_color = _greyed(true_body_color) if is_forged() else true_body_color
	accent_color = _greyed(true_accent_color) if is_forged() else true_accent_color
	if _mist != null:
		_mist.visible = is_forged()
	if _figure != null and is_instance_valid(_figure):
		_figure.queue_free()
		_figure = StorybookFigure.new()
		_figure.name = "Figure"
		var picked: Array = _pick_look()
		_figure.build(picked[0], picked[1], body_color, accent_color, float(npc_seed) * 1.37)
		_body.add_child(_figure)


static func _greyed(color: Color) -> Color:
	var grey: float = color.get_luminance()
	return color.lerp(Color(grey, grey, grey), FORGED_GREYING)


static func _mist_material() -> StandardMaterial3D:
	var made: StandardMaterial3D = StandardMaterial3D.new()
	made.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	made.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	made.albedo_color = Color(0.78, 0.78, 0.76, 0.28)
	return made
