## One of Hearthstead Market's three lane stalls (docs/20 Part I §1.4, the
## hub-and-spoke economy): the Iron Stall, the Lantern Stall and the
## Provisions Stall. Shuttered and bare while its lane is dark; once its
## island's Beacon is lit it opens bustling (awning up, crates and lamps out, a
## vendor behind the counter whose wares open on light), the shared good the
## whole party walks home to use.
class_name TradeStall
extends Node3D

## The CalderaWorldState flag that stocks it (its island's Beacon).
@export var lane_flag: StringName = &""
@export var stall_name: String = ""
@export var vendor_name: String = ""
@export var vendor_title: String = ""
@export var wares: TownsfolkNPC.Wares = TownsfolkNPC.Wares.NONE
@export var wares_note: String = ""
@export var accent: Color = Color(0.9, 0.6, 0.3)

var vendor: TownsfolkNPC

var _shutters: Node3D
var _stock: Node3D
var _label: Label3D


func _ready() -> void:
	var booth: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_box(booth, Vector3(0.0, 0.5, -0.6), Vector3(4.2, 1.0, 1.0), CalderaKit.TIMBER)
	for corner: Vector2 in [Vector2(-2.0, -1.4), Vector2(2.0, -1.4), Vector2(-2.0, 1.2), Vector2(2.0, 1.2)]:
		CalderaKit.add_post(booth, Vector3(corner.x, 0.0, corner.y), 0.1, 0.12, 2.8, CalderaKit.DARK_TIMBER, 6)
	CalderaKit.add_box(booth, Vector3(0.0, 2.9, 0.0), Vector3(4.6, 0.16, 3.2), CalderaKit.DARK_TIMBER)
	add_child(CalderaKit.mesh_node("Booth", booth))
	CalderaKit.solid_box(self, "Counter", Vector3(0.0, 0.5, -0.6), Vector3(4.2, 1.0, 1.0), 0.0, ActorBase.LAYER_LOW_SCENERY)
	_shutters = Node3D.new()
	_shutters.name = "Shutters"
	add_child(_shutters)
	var boards: LandblockTerrain.MeshMerge = CalderaKit.merge()
	for index: int in 5:
		CalderaKit.add_box(boards, Vector3(-1.7 + index * 0.85, 1.85, -1.15), Vector3(0.78, 1.7, 0.08), CalderaKit.DARK_TIMBER.lerp(CalderaKit.TIMBER, 0.2 * (index % 2)))
	CalderaKit.add_beam(boards, Vector3(-2.1, 1.4, -1.05), Vector3(2.1, 2.4, -1.05), 0.12, CalderaKit.TIMBER)
	_shutters.add_child(CalderaKit.mesh_node("Boards", boards))
	_stock = Node3D.new()
	_stock.name = "Stock"
	add_child(_stock)
	var goods: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_box(goods, Vector3(0.0, 3.05, 0.3), Vector3(4.8, 0.1, 3.6), accent)
	for index: int in 4:
		CalderaKit.add_box(goods, Vector3(-1.5 + index, 1.15, -0.6), Vector3(0.6, 0.3, 0.6), accent.lerp(CalderaKit.TIMBER, 0.5))
	for crate: Vector3 in [Vector3(-2.6, 0.4, 0.6), Vector3(2.6, 0.4, 0.4), Vector3(2.4, 1.1, 0.5)]:
		CalderaKit.add_box(goods, crate, Vector3(0.8, 0.8, 0.8), CalderaKit.TIMBER.lightened(0.1))
	_stock.add_child(CalderaKit.mesh_node("Goods", goods))
	CalderaKit.glow_sphere(_stock, "Lamp", Vector3(1.9, 2.5, 1.1), 0.18, CalderaKit.SAFFRON, 2.6)
	_label = CalderaKit.sign_label(self, "Sign", "", Vector3(0.0, 3.6, 1.2))
	if CalderaWorldState.current != null:
		CalderaWorldState.current.flag_changed.connect(_on_flag_changed)
	_refresh()


func _exit_tree() -> void:
	if CalderaWorldState.current != null and CalderaWorldState.current.flag_changed.is_connected(_on_flag_changed):
		CalderaWorldState.current.flag_changed.disconnect(_on_flag_changed)


func is_stocked() -> bool:
	return CalderaWorldState.current != null and CalderaWorldState.current.get_flag(lane_flag)


func _on_flag_changed(flag: StringName, _value: bool) -> void:
	if flag == lane_flag:
		_refresh()


func _refresh() -> void:
	var stocked: bool = is_stocked()
	_shutters.visible = not stocked
	_stock.visible = stocked
	_label.text = "%s\n%s" % [stall_name, wares_note if stocked else "shuttered: its lane is dark"]
	if stocked and vendor == null:
		vendor = TownsfolkNPC.new()
		vendor.name = "Vendor"
		vendor.role = TownsfolkNPC.Role.VENDOR
		vendor.npc_name = vendor_name
		vendor.title = vendor_title
		vendor.hub = "Hearthstead Market"
		vendor.wares = wares
		vendor.wares_note = wares_note
		vendor.body_color = accent.darkened(0.25)
		vendor.accent_color = CalderaKit.TIMBER
		vendor.npc_seed = hash(stall_name) % 97
		vendor.position = Vector3(0.0, 0.0, -1.6)
		vendor.rotation.y = 0.0
		add_child(vendor)
	elif not stocked and vendor != null:
		vendor.queue_free()
		vendor = null
