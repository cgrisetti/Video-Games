## A walkable seam's corridor as one island builds it (Skin A: the West
## Strait's dressed-stone causeway, Eel Spit's low shingle spit): the whole
## 128 m from this island's shore out into The Sound, so wherever a hero
## stands on it when the seam swaps islands, the same corridor is under
## them on the other side. Deck and kerbs have colliders (the kerbs on the
## low-scenery layer); a LaneGate bars the shore end while the lane is dark,
## and lanterns line the way into the sea-mist.
class_name CalderaCauseway
extends RefCounted

const WIDTH: float = 7.0
const SPIT_WIDTH: float = 9.0
const KERB_HEIGHT: float = 0.7


static func build(root: Node3D, seam: LoadSeamResource, isle_id: StringName) -> Node3D:
	var holder: Node3D = Node3D.new()
	holder.name = "Causeway_%s" % String(seam.seam_id).trim_prefix("seam_")
	root.add_child(holder)
	var anchor: Vector3 = seam.anchor(isle_id)
	var out: Vector3 = seam.out_direction(isle_id)
	var width: float = SPIT_WIDTH if seam.shingle else WIDTH
	var yaw: float = atan2(out.x, out.z)
	var across: Vector3 = Vector3(out.z, 0.0, -out.x)
	var stone: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_causeway(stone, anchor - out * 6.0, out, seam.length_m + 6.0, width, anchor.y, seam.shingle)
	holder.add_child(CalderaKit.mesh_node("Deck", stone))
	var middle: Vector3 = anchor + out * (seam.length_m * 0.5 - 3.0)
	var run: float = seam.length_m + 6.0
	CalderaKit.solid_box(holder, "DeckBody", Vector3(middle.x, anchor.y - 0.25, middle.z), Vector3(width, 0.5, run), yaw, ActorBase.LAYER_LOW_SCENERY)
	for side: float in [-1.0, 1.0]:
		var kerb: Vector3 = middle + across * side * (width * 0.5 + 0.3) + Vector3(0.0, anchor.y + KERB_HEIGHT * 0.5, 0.0)
		kerb.y = anchor.y + KERB_HEIGHT * 0.5
		CalderaKit.solid_box(holder, "Kerb%s" % ("L" if side < 0.0 else "R"), kerb, Vector3(0.6, KERB_HEIGHT, run), yaw, ActorBase.LAYER_LOW_SCENERY)
	# The far end, deep in the mist: a low wall, so nobody walks off the corridor's end.
	CalderaKit.solid_box(holder, "FarEnd", anchor + out * (seam.length_m + 0.3) + Vector3(0.0, KERB_HEIGHT * 0.5, 0.0),
		Vector3(width + 1.2, KERB_HEIGHT, 0.6), yaw, ActorBase.LAYER_LOW_SCENERY)
	var gate: LaneGate = LaneGate.new()
	gate.name = "LaneGate"
	gate.seam_id = seam.seam_id
	gate.width = width
	gate.position = anchor + out * 6.0
	gate.rotation.y = yaw
	holder.add_child(gate)
	for index: int in 4:
		var s: float = 18.0 + 30.0 * float(index)
		for side: float in [-1.0, 1.0]:
			var post: Vector3 = anchor + out * s + across * side * (width * 0.5 + 0.3)
			holder.add_child(WorldKitInstance.make("Lantern%d%s" % [index, "L" if side < 0.0 else "R"], WorldVisualCatalog.KIT_WIND_LANTERN_POST,
				Vector3(post.x, anchor.y, post.z), yaw))
	return holder
