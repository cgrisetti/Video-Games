## A friction isle's Beacon (docs/20 Part I §3: one flag, three effects): a
## stone lighthouse-cairn on the island's sheltered inner shore, its brazier
## cold while the trade lane is dark. Its guardians (a MobSpawner pack beside
## it) must be calmed first; then light kindles it, which sets the island's
## CalderaWorldState flag: its stall at Hearthstead Market stocks, its current
## round The Crown calms, and its Sign is earned.
class_name IslandBeacon
extends Interactable

@export var isle_id: StringName = &""
## The Beacon's guardians (a sibling spawner, never regrowing).
var guards: MobSpawner

var _fire: Node3D
var _label: Label3D


func _ready() -> void:
	reach = 3.4
	add_to_group(&"map_glyphs")
	var tower: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_post(tower, Vector3.ZERO, 2.0, 2.8, 7.0, CalderaKit.PALE_STONE, 10)
	CalderaKit.add_post(tower, Vector3(0.0, 7.0, 0.0), 2.4, 2.2, 0.6, CalderaKit.DARK_STONE, 10)
	CalderaKit.add_post(tower, Vector3(0.0, 7.6, 0.0), 1.3, 0.8, 1.2, CalderaKit.BRASS.darkened(0.3), 10)
	for step: int in 4:
		CalderaKit.add_box(tower, Vector3(0.0, 0.15 + step * 0.3, 3.2 + step * 0.5), Vector3(2.4, 0.3, 0.5), CalderaKit.STONE)
	add_child(CalderaKit.mesh_node("Tower", tower))
	CalderaKit.solid_cylinder(self, "Body", Vector3.ZERO, 2.6, 7.6)
	_fire = Node3D.new()
	_fire.name = "Fire"
	_fire.position = Vector3(0.0, 9.0, 0.0)
	add_child(_fire)
	var isle: IslandGridResource = CalderaAtlas.isle(isle_id)
	var flame: Color = isle.accent_color if isle != null else CalderaKit.SAFFRON
	CalderaKit.glow_sphere(_fire, "Flame", Vector3.ZERO, 1.1, flame.lerp(CalderaKit.SAFFRON, 0.5), 3.2)
	CalderaKit.light(_fire, "Light", Vector3(0.0, 0.6, 0.0), flame.lerp(CalderaKit.SAFFRON, 0.6), 4.0, 40.0)
	CalderaKit.plume(_fire, "Smoke", Vector3(0.0, 1.2, 0.0), Color(0.5, 0.48, 0.46, 0.55), 2.2, 0.6, 10)
	_label = CalderaKit.sign_label(self, "Sign", "", Vector3(0.0, 4.2, 3.6))
	if CalderaWorldState.current != null:
		CalderaWorldState.current.flag_changed.connect(_on_flag_changed)
	_refresh()


func _exit_tree() -> void:
	super._exit_tree()
	if CalderaWorldState.current != null and CalderaWorldState.current.flag_changed.is_connected(_on_flag_changed):
		CalderaWorldState.current.flag_changed.disconnect(_on_flag_changed)


func is_lit() -> bool:
	var isle: IslandGridResource = CalderaAtlas.isle(isle_id)
	return isle != null and CalderaWorldState.current != null and CalderaWorldState.current.get_flag(isle.beacon_flag)


## Whether the guardians are calmed (or there are none, or the Beacon already burns).
func guards_calmed() -> bool:
	if is_lit() or guards == null:
		return true
	return not guards.mobs.is_empty() and guards.standing_count() == 0


func prompt_for(_actor: ActorBase) -> String:
	var isle: IslandGridResource = CalderaAtlas.isle(isle_id)
	if isle == null:
		return ""
	if is_lit():
		return "%s's Beacon burns: the %s is calm" % [isle.display_name, isle.current_name]
	if not guards_calmed():
		return "Calm the Beacon's guardians first (%d stand)" % guards.standing_count()
	return "light: kindle %s's Beacon" % isle.display_name


func interact(_actor: ActorBase) -> void:
	if is_lit():
		return
	if not guards_calmed():
		AudioCues.play(&"refuse")
		return
	AudioCues.play(&"lantern")
	CalderaWorldState.current.light_beacon(isle_id)


func _on_flag_changed(_flag: StringName, _value: bool) -> void:
	_refresh()


func _refresh() -> void:
	var lit: bool = is_lit()
	_fire.visible = lit
	var isle: IslandGridResource = CalderaAtlas.isle(isle_id)
	if isle != null:
		_label.text = "%s's Beacon\n%s" % [isle.display_name, "burning" if lit else "cold: the %s runs wild" % isle.current_name]
