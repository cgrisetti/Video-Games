## Q05's dungeon, the Root-Sanctum (docs/28 §7; docs/29 §4): carved seamlessly
## under the Elder Oak's roots like The Crown's Sap Galleries, not a separate
## instance. The party walks into the door's ring together (a PartyThreshold)
## and comes out the same way 26 m below, and leaves by the weir.
##
##   Chamber 1, the Sap-Gallery (introduction): a long root tunnel, amber sap
##   in its walls; Root-Lurkers and Sap-Boggarts in three pulls.
##   Chamber 2, the Two Valves (the twist): two Sap-Boggart Great-Boggarts
##   asleep in the sap-river's valve-knots, which must both be calmed within
##   3 s of each other (8 s for a hero alone); miss it and the first re-greys.
##   Chamber 3, the Taproot Hall's Root-Lurkers, calmed before the Stag wakes.
##   Then the boss: the Blighted Taproot Stag (TaprootStagEncounter).
##
## Each chamber is clear when every foe in it is down (calmed or scattered; in
## here nothing grows back). Its rooms are boxes the same on every peer.
class_name RootSanctum
extends Node3D

signal chamber_cleared(index: int)
signal stag_calmed

## The Sanctum's floor and roof (Embershore's ground above it is 7.8 m or higher).
const FLOOR_Y: float = -12.0
const ROOM_HEIGHT: float = 7.0
const WALL: float = 1.0
## The rooms, as (min x, max x, min z, max z) in Embershore's frame.
const GALLERY: Rect2 = Rect2(-157.0, 200.0, 10.0, 30.0)
const VALVES: Rect2 = Rect2(-172.0, 182.0, 26.0, 18.0)
const HALL: Rect2 = Rect2(-208.0, 154.0, 36.0, 36.0)
## Where the party arrives inside, and where the hall's exit ring stands.
const ARRIVAL: Vector3 = Vector3(-152.0, FLOOR_Y + 0.2, 226.0)
const EXIT_AT: Vector3 = Vector3(-203.0, FLOOR_Y + 0.05, 159.0)
const TAPROOT_AT: Vector3 = Vector3(-190.0, FLOOR_Y, 172.0)
const STAG_AT: Vector3 = Vector3(-182.0, FLOOR_Y, 172.0)
const BRAZIER_AT: Vector3 = Vector3(-190.0, FLOOR_Y, 157.0)
## The two valves must be calmed this close together (a hero alone has longer).
const VALVE_WINDOW: float = 3.0
const VALVE_WINDOW_SOLO: float = 8.0
const SAP_AMBER: Color = Color(0.96, 0.72, 0.3)
const ROOT_BROWN: Color = Color(0.36, 0.28, 0.22)
const EARTH: Color = Color(0.3, 0.26, 0.22)

var entrance: PartyThreshold
var exit_ring: PartyThreshold
## Chamber index (0, 1, 2) -> its spawners.
var chambers: Array[Array] = [[], [], []]
var cleared: Array[bool] = [false, false, false]
var stag_spawner: MobSpawner
var stag_encounter: TaprootStagEncounter
var valve_spawners: Array[MobSpawner] = []

var _valve_first_at: float = -1.0
var _valve_first: int = -1
var _woke: bool = false


func build(door: Vector3) -> void:
	name = "RootSanctum"
	_rooms()
	entrance = PartyThreshold.new()
	entrance.name = "SanctumDoor"
	entrance.radius = 4.5
	entrance.position = door + Vector3(0.0, 0.05, 0.0)
	entrance.destination = ARRIVAL
	entrance.destination_yaw = PI
	entrance.ring_color = Color(0.62, 0.86, 0.5)
	entrance.enabled = false
	add_child(entrance)
	exit_ring = PartyThreshold.new()
	exit_ring.name = "SanctumExit"
	exit_ring.radius = 3.5
	exit_ring.position = EXIT_AT
	exit_ring.ring_color = CalderaKit.HEARTH_SAFFRON
	exit_ring.enabled = false
	add_child(exit_ring)
	# Chamber 1: three pulls down the gallery.
	_chamber_spawner(0, "GalleryPull1", Vector3(-152.0, FLOOR_Y, 219.0), [Bestiary.ROOT_LURKER, Bestiary.ROOT_LURKER])
	_chamber_spawner(0, "GalleryPull2", Vector3(-152.0, FLOOR_Y, 211.0), [Bestiary.SAP_ELEMENTAL, Bestiary.ROOT_LURKER])
	_chamber_spawner(0, "GalleryPull3", Vector3(-152.0, FLOOR_Y, 204.0), [Bestiary.SAP_ELEMENTAL])
	# Chamber 2: the two valve-knots, 14 m apart.
	for index: int in 2:
		var valve: MobSpawner = _chamber_spawner(1, "Valve%d" % (index + 1), Vector3(-166.0 + 14.0 * index, FLOOR_Y, 190.0), [Bestiary.SAP_ELEMENTAL_GREAT])
		valve_spawners.append(valve)
	# Chamber 3: the hall's Root-Lurkers in its corners.
	_chamber_spawner(2, "HallLurkersNorth", Vector3(-203.0, FLOOR_Y, 185.0), [Bestiary.ROOT_LURKER, Bestiary.ROOT_LURKER])
	_chamber_spawner(2, "HallLurkersEast", Vector3(-177.0, FLOOR_Y, 159.0), [Bestiary.ROOT_LURKER])
	stag_spawner = MobSpawner.new()
	stag_spawner.name = "TaprootStag"
	stag_spawner.territory = "The Taproot Hall"
	stag_spawner.variant_ids = [Bestiary.TAPROOT_STAG]
	stag_spawner.leash = 30.0
	stag_spawner.respawn_time = Vector2(1.0e9, 1.0e9)
	stag_spawner.own_floor = true
	stag_spawner.position = STAG_AT
	add_child(stag_spawner)


## Whether the party is anywhere in the Sanctum (its rooms, under the ground).
static func contains(at: Vector3) -> bool:
	if at.y > FLOOR_Y + ROOM_HEIGHT + 1.0 or at.y < FLOOR_Y - 3.0:
		return false
	var flat: Vector2 = Vector2(at.x, at.z)
	return GALLERY.grow(1.0).has_point(flat) or VALVES.grow(1.0).has_point(flat) or HALL.grow(1.0).has_point(flat)


## Grows the chambers' foes (the director calls this as the party goes in).
func wake() -> void:
	if _woke:
		return
	_woke = true
	for index: int in chambers.size():
		if cleared[index]:
			continue
		for spawner: MobSpawner in chambers[index]:
			spawner.spawn_mobs()


## Lets them go again (the party left, or the Sanctum is done).
func sleep() -> void:
	_woke = false
	for chamber: Array in chambers:
		for spawner: MobSpawner in chamber:
			spawner.despawn_mobs()
	stag_spawner.despawn_mobs()
	stag_encounter = null


func _physics_process(_delta: float) -> void:
	if not _woke or not NetworkManager.current.is_host():
		return
	_watch_valves()
	for index: int in chambers.size():
		if cleared[index]:
			continue
		var down: bool = true
		for spawner: MobSpawner in chambers[index]:
			if spawner.mobs.is_empty() or spawner.standing_count() > 0:
				down = false
		if down:
			mark_cleared(index)
	if cleared[2] and stag_spawner.mobs.is_empty():
		_raise_stag()


## Host: a chamber is clear (tests call this directly).
func mark_cleared(index: int) -> void:
	if cleared[index]:
		return
	cleared[index] = true
	var names: Array[String] = ["THE SAP-GALLERY IS CLEAR", "THE SAP RUNS AGAIN", "THE HALL FALLS QUIET"]
	CombatDirector.current.announce(ARRIVAL + Vector3.UP * 3.0 if index == 0 else TAPROOT_AT + Vector3.UP * 6.0, names[index], SAP_AMBER, &"bell")
	chamber_cleared.emit(index)
	if QuestManager.current != null:
		QuestManager.current.report(QuestStepResource.Kind.EVENT, ActOneQuests.EVENT_CHAMBER_CLEARED)


## Host: the Stag wakes once the hall's lurkers are calmed.
func _raise_stag() -> void:
	stag_spawner.spawn_mobs()
	var stag: WildMob = stag_spawner.mobs[0] if not stag_spawner.mobs.is_empty() else null
	if stag == null:
		return
	attach_encounter(stag)


## Every peer: the Stag's encounter (the director calls this as it appears on a client too).
func attach_encounter(stag: WildMob) -> void:
	if TaprootStagEncounter.of(stag) != null:
		stag_encounter = TaprootStagEncounter.of(stag)
		return
	var lurkers: PackedVector3Array = PackedVector3Array([Vector3(-206.0, FLOOR_Y, 170.0), Vector3(-174.0, FLOOR_Y, 186.0)])
	stag_encounter = TaprootStagEncounter.new()
	stag_encounter.setup(stag, ActOneQuests.BOSS_TAPROOT_STAG, TAPROOT_AT, BRAZIER_AT, lurkers)
	stag_encounter.resolved.connect(_on_stag_resolved)
	stag.add_child(stag_encounter)


func _on_stag_resolved() -> void:
	exit_ring.enabled = true
	stag_calmed.emit()


## The Two Valves: both calmed within the window, or the first one re-greys.
func _watch_valves() -> void:
	if cleared[1] or valve_spawners.size() < 2:
		return
	var down: Array[bool] = []
	for spawner: MobSpawner in valve_spawners:
		down.append(not spawner.mobs.is_empty() and spawner.standing_count() == 0)
	if down[0] and down[1]:
		return
	var now: float = CombatDirector.game_time()
	for index: int in 2:
		if down[index] and _valve_first < 0:
			_valve_first = index
			_valve_first_at = now
	if _valve_first < 0:
		return
	var solo: bool = CombatDirector.current.alive_party().size() <= 1
	if now - _valve_first_at > (VALVE_WINDOW_SOLO if solo else VALVE_WINDOW):
		# Too slow: the first valve-knot re-greys and its Sap-Boggart wakes again.
		var first: MobSpawner = valve_spawners[_valve_first]
		first._regrow(0)
		for peer_id: int in InstanceManager.current.live_remote_peers():
			first._regrow.rpc_id(peer_id, 0)
		first.mobs[0].calming.was_calmed = false
		CombatDirector.current.announce(first.global_position + Vector3.UP * 3.0, "TOO SLOW: the valve re-greys. Two hands, two valves, one breath.", Color(0.7, 0.7, 0.68), &"refuse")
		_valve_first = -1
		_valve_first_at = -1.0


func _chamber_spawner(chamber: int, spawner_name: String, at: Vector3, ids: Array[StringName]) -> MobSpawner:
	var spawner: MobSpawner = MobSpawner.new()
	spawner.name = spawner_name
	spawner.territory = "The Root-Sanctum"
	spawner.variant_ids = ids
	spawner.leash = 22.0
	# Nothing grows back in the Sanctum: a scatter is gone for good.
	spawner.respawn_time = Vector2(1.0e9, 1.0e9)
	spawner.own_floor = true
	spawner.position = at
	add_child(spawner)
	chambers[chamber].append(spawner)
	return spawner


# --- The rooms --------------------------------------------------------------------------

func _rooms() -> void:
	var stone: LandblockTerrain.MeshMerge = CalderaKit.merge()
	for room: Rect2 in [GALLERY, VALVES, HALL]:
		var middle: Vector3 = Vector3(room.get_center().x, FLOOR_Y, room.get_center().y)
		_slab(stone, "Floor", middle - Vector3(0.0, 0.3, 0.0), Vector3(room.size.x + WALL * 2.0, 0.6, room.size.y + WALL * 2.0), EARTH)
		_slab(stone, "Roof", middle + Vector3(0.0, ROOM_HEIGHT + 0.3, 0.0), Vector3(room.size.x + WALL * 2.0, 0.6, room.size.y + WALL * 2.0), ROOT_BROWN)
	# Walls, with the doorways between rooms left open (gallery south into the valves, valves west into the hall).
	_wall_x(stone, GALLERY.position.x, GALLERY.position.y, GALLERY.end.y, [])
	_wall_x(stone, GALLERY.end.x, GALLERY.position.y, GALLERY.end.y, [])
	_wall_z(stone, GALLERY.end.y, GALLERY.position.x, GALLERY.end.x, [])
	_wall_z(stone, VALVES.end.y, VALVES.position.x, VALVES.end.x, [Vector2(GALLERY.position.x, GALLERY.end.x)])
	_wall_z(stone, VALVES.position.y, VALVES.position.x, VALVES.end.x, [])
	_wall_x(stone, VALVES.end.x, VALVES.position.y, VALVES.end.y, [])
	_wall_x(stone, VALVES.position.x, VALVES.position.y, VALVES.end.y, [Vector2(184.0, 190.0)])
	_wall_x(stone, HALL.position.x, HALL.position.y, HALL.end.y, [])
	_wall_x(stone, HALL.end.x, HALL.position.y, HALL.end.y, [Vector2(184.0, 190.0)])
	_wall_z(stone, HALL.position.y, HALL.position.x, HALL.end.x, [])
	_wall_z(stone, HALL.end.y, HALL.position.x, HALL.end.x, [])
	add_child(CalderaKit.mesh_node("SanctumStone", stone))
	# The taproot: a great root pillar from floor to roof, and the dry ink-spring at its foot.
	var root: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_post(root, TAPROOT_AT, 1.8, 1.4, ROOM_HEIGHT, ROOT_BROWN.lightened(0.1), 14)
	for index: int in 8:
		var angle: float = TAU * float(index) / 8.0
		CalderaKit.add_beam(root, TAPROOT_AT + Vector3(cos(angle) * 6.0, 0.0, sin(angle) * 6.0), TAPROOT_AT + Vector3(cos(angle) * 1.4, ROOM_HEIGHT, sin(angle) * 1.4), 0.6, ROOT_BROWN)
	add_child(CalderaKit.mesh_node("Taproot", root))
	CalderaKit.solid_cylinder(self, "TaprootBody", TAPROOT_AT + Vector3(0.0, ROOM_HEIGHT * 0.5, 0.0), 1.8, ROOM_HEIGHT)
	# The brazier, and the sap glowing in the walls.
	add_child(ShapeKit.cylinder("BrazierBowl", 0.7, 0.4, 0.8, BRAZIER_AT + Vector3(0.0, 0.4, 0.0), StorybookMaterial.make(Color(0.34, 0.3, 0.26)), 10))
	CalderaKit.glow_sphere(self, "BrazierFlame", BRAZIER_AT + Vector3(0.0, 1.0, 0.0), 0.45, CalderaKit.HEARTH_SAFFRON, 2.4)
	CalderaKit.light(self, "BrazierLight", BRAZIER_AT + Vector3(0.0, 2.0, 0.0), CalderaKit.HEARTH_SAFFRON, 2.0, 12.0)
	for spot: Vector3 in [Vector3(-152.0, FLOOR_Y, 222.0), Vector3(-152.0, FLOOR_Y, 207.0), Vector3(-159.0, FLOOR_Y, 191.0), TAPROOT_AT + Vector3(0.0, 0.0, 10.0), TAPROOT_AT + Vector3(-10.0, 0.0, -6.0)]:
		CalderaKit.light(self, "SapLight%d" % get_child_count(), spot + Vector3(0.0, 4.5, 0.0), SAP_AMBER, 1.6, 16.0)
	CalderaKit.sign_label(self, "SanctumSign", "The Root-Sanctum\nthe Sap-Gallery runs down to the Taproot Hall", ARRIVAL + Vector3(0.0, 3.2, -2.0))


func _slab(merge: LandblockTerrain.MeshMerge, label: String, at: Vector3, size: Vector3, color: Color) -> void:
	CalderaKit.add_box(merge, at, size, color)
	CalderaKit.solid_box(self, "%s%d" % [label, get_child_count()], at, size)


## A wall along x = `x` from z0 to z1, leaving `gaps` (z ranges) open.
func _wall_x(merge: LandblockTerrain.MeshMerge, x: float, z0: float, z1: float, gaps: Array) -> void:
	for piece: Vector2 in _pieces(z0, z1, gaps):
		var at: Vector3 = Vector3(x, FLOOR_Y + ROOM_HEIGHT * 0.5, (piece.x + piece.y) * 0.5)
		var size: Vector3 = Vector3(WALL, ROOM_HEIGHT, piece.y - piece.x)
		CalderaKit.add_box(merge, at, size, ROOT_BROWN.lightened(0.05))
		CalderaKit.solid_box(self, "WallX%d" % get_child_count(), at, size)


## A wall along z = `z` from x0 to x1, leaving `gaps` (x ranges) open.
func _wall_z(merge: LandblockTerrain.MeshMerge, z: float, x0: float, x1: float, gaps: Array) -> void:
	for piece: Vector2 in _pieces(x0, x1, gaps):
		var at: Vector3 = Vector3((piece.x + piece.y) * 0.5, FLOOR_Y + ROOM_HEIGHT * 0.5, z)
		var size: Vector3 = Vector3(piece.y - piece.x, ROOM_HEIGHT, WALL)
		CalderaKit.add_box(merge, at, size, ROOT_BROWN.lightened(0.05))
		CalderaKit.solid_box(self, "WallZ%d" % get_child_count(), at, size)


## The stretches of [from, to] left after cutting out the gaps.
static func _pieces(from: float, to: float, gaps: Array) -> Array[Vector2]:
	var pieces: Array[Vector2] = []
	var start: float = from
	var sorted: Array = gaps.duplicate()
	sorted.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	for gap: Vector2 in sorted:
		if gap.x > start + 0.1:
			pieces.append(Vector2(start, minf(gap.x, to)))
		start = maxf(start, gap.y)
	if to > start + 0.1:
		pieces.append(Vector2(start, to))
	return pieces
