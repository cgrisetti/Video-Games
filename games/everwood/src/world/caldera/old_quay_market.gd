## The Old Quay Market on Embershore's north shore, below Hearthstead (docs/20 Part I §2,
## the Council's "10% added back"): the market the grandparents remember, on
## a stone shelf at -4 m under the Long Flood. The Ebb bares it, and its old
## stalls open again with the endgame's Chime and gear merchants, so Oakshire
## is never dead ground after Lv 6.
class_name OldQuayMarket
extends Node3D

var merchants: Array[TownsfolkNPC] = []

var _label: Label3D


func _ready() -> void:
	add_to_group(&"caldera_ebb_reveals")
	add_to_group(&"map_glyphs")
	var stone: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_post(stone, Vector3(0.0, -0.3, 0.0), 20.0, 20.5, 0.4, Color(0.52, 0.54, 0.5), 20)
	for index: int in 3:
		var angle: float = -0.6 + 0.6 * float(index)
		var spot: Vector3 = Vector3(sin(angle) * 12.0, 0.0, cos(angle) * 12.0 - 2.0)
		for corner: Vector2 in [Vector2(-1.8, -1.2), Vector2(1.8, -1.2), Vector2(-1.8, 1.2), Vector2(1.8, 1.2)]:
			CalderaKit.add_post(stone, spot + Vector3(corner.x, 0.0, corner.y), 0.16, 0.2, 2.6, Color(0.44, 0.46, 0.42), 6)
		CalderaKit.add_box(stone, spot + Vector3(0.0, 0.5, -0.6), Vector3(3.8, 1.0, 0.9), Color(0.5, 0.48, 0.44))
		CalderaKit.add_box(stone, spot + Vector3(0.0, 2.65, 0.0), Vector3(4.2, 0.2, 3.0), Color(0.4, 0.42, 0.4))
	for index: int in 8:
		var angle: float = TAU * float(index) / 8.0
		CalderaKit.add_post(stone, Vector3(cos(angle) * 18.5, 0.0, sin(angle) * 18.5), 0.4, 0.5, 1.0, Color(0.42, 0.44, 0.4), 8)
		CalderaKit.add_sphere(stone, Vector3(cos(angle) * 18.5, 0.9, sin(angle) * 18.5), 0.35, Color(0.7, 0.72, 0.66), 0.6, 5)
	add_child(CalderaKit.mesh_node("Paving", stone))
	_label = CalderaKit.sign_label(self, "Sign", "", Vector3(0.0, 4.0, 6.0))
	if CalderaWorldState.current != null:
		CalderaWorldState.current.sea_level_changed.connect(_on_sea_level_changed)
	_refresh()


func _exit_tree() -> void:
	if CalderaWorldState.current != null and CalderaWorldState.current.sea_level_changed.is_connected(_on_sea_level_changed):
		CalderaWorldState.current.sea_level_changed.disconnect(_on_sea_level_changed)


func is_bared() -> bool:
	var state: CalderaWorldState = CalderaWorldState.current
	return state != null and state.ebb_unlocked and state.sea_level_y <= global_position.y - 0.5


func is_submerged() -> bool:
	var state: CalderaWorldState = CalderaWorldState.current
	return state == null or state.sea_level_y > global_position.y


func _on_sea_level_changed(_sea_y: float) -> void:
	_refresh()


func _refresh() -> void:
	var bared: bool = is_bared()
	_label.visible = not is_submerged()
	_label.text = "The Old Quay Market\nbared by the Ebb: Chimes and gear for the raids"
	if bared and merchants.is_empty():
		var specs: Array[Array] = [["Nan Saltmarsh", "Chime-Merchant", TownsfolkNPC.Wares.BANKER, "old Chimes for new upgrades", Vector3(-6.0, 0.0, 9.0)],
			["Corwen Tidewell", "Raid Outfitter", TownsfolkNPC.Wares.ARMOR, "Ring-Coats for the raids", Vector3(6.0, 0.0, 9.0)]]
		for index: int in specs.size():
			var spec: Array = specs[index]
			var npc: TownsfolkNPC = TownsfolkNPC.new()
			npc.name = "Merchant%d" % (index + 1)
			npc.role = TownsfolkNPC.Role.VENDOR
			npc.npc_name = spec[0]
			npc.title = spec[1]
			npc.hub = "The Old Quay Market"
			npc.wares = spec[2]
			npc.wares_note = spec[3]
			npc.body_color = Color(0.36, 0.46, 0.56) if index == 0 else Color(0.5, 0.38, 0.3)
			npc.accent_color = CalderaKit.BRASS
			npc.npc_seed = 71 + index
			npc.position = spec[4]
			add_child(npc)
			merchants.append(npc)
	elif not bared and not merchants.is_empty():
		for npc: TownsfolkNPC in merchants:
			npc.queue_free()
		merchants.clear()
