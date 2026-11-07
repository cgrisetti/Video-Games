## The Wayfarer's map of a level (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §7.1,
## docs/13_PLAYTEST_KAIZEN_UPDATE_PROMPT.md §2.4–2.5): drawn in code onto a
## parchment ImageTexture (no SubViewports, no cameras):
##   parchment  #EFE6D2, a little hill-shaded
##   contours   every 2 m of height, #C9B898
##   roads      #9E7B56 (the flagged Bale-Ways, the footpaths and trails, the cobbled squares)
##   water      #4A9BB8, deeper water darker, its shore inked
##   buildings  #6E473B footprints (every house, mill, pavilion, hut, shrine and desk)
## 512 pixels along its long side in a window, 256 headless.
##
## Two scopes (MapScope): the Zone Map (the island or level the party is on)
## and the World Map (in the Caldera Isles, all five islands in The Sound; on a
## single-map level the whole map, the Zone Map then a close crop of the place
## the hero is in).
##
## The Caldera Isles read their ground straight from each island's builder
## (tile by tile, with only the pads, ramps and paths near each tile), and
## their buildings from the colliders standing on the live island. A legacy
## seamless world (Bramble-Bridge's trail, Oakshire Vale) reads its WorldLayout
## and the footprints its builder listed (cartography.json); a walled instance
## (the hub, the expedition) casts rays down at its colliders. The ground is
## gathered on the main thread; the pixels are painted on a worker thread
## (request_level_map, handed over by poll()) or at once (bake_level_map). Each
## map is baked once and kept.
##
## Its nodes (map_nodes) are what the map names and a way-marker can be set
## on: towns, quest-givers, dungeons and raid doors, crossings, shrines, desks,
## portals, beacons and landmarks. The live things (heroes, Hush-Cracks, the
## way-marker) are drawn over it by the WayfarerMinimapWidget and the WorldMapPanel.
class_name CartographyBaker
extends RefCounted

const PARCHMENT: Color = Color("#EFE6D2")
const CONTOUR: Color = Color("#C9B898")
const ROAD: Color = Color("#9E7B56")
const WATER: Color = Color("#4A9BB8")
const FOOTPRINT: Color = Color("#6E473B")
## The ink line where land meets water.
const SHORE_INK: Color = Color("#2F5D72")
## A contour line every this many metres of height.
const CONTOUR_STEP_M: float = 2.0
## Pixels along the map's long side.
const MAP_SIZE: int = 512
const MAP_SIZE_HEADLESS: int = 256
## A walled instance's ground is read on a grid this many rays along its long side, then smoothed up.
const RAY_GRID: int = 128
## The hill-shade's strength (a share of the parchment's value).
const HILL_SHADE: float = 0.07
## The sea's depth at which its colour is darkest.
const DEEP_WATER_M: float = 24.0
## An island map is painted in square tiles of this many pixels (each reads only the features near it).
const TILE_PX: int = 32
## The World Map reaches this far past the outermost islands.
const WORLD_MARGIN_M: float = 220.0
## On a single-map level, the Zone Map shows this many times the reach of the place the hero is in.
const ZONE_CROP_SCALE: float = 2.6
## Where on the texture the world rectangle it shows is kept (Rect2, x and z).
const META_RECT: StringName = &"world_rect"
## The group the map's glyphs join (shrines, desks, portals, quest-givers, beacons).
const GLYPH_GROUP: StringName = &"map_glyphs"
## The footprint and crack list a level builder writes beside a world's landblocks.
const CARTOGRAPHY_FILE: String = "cartography.json"
## Kit categories drawn as building footprints, and as road (bridges).
const BUILDING_CATEGORIES: Array[StringName] = [&"ARCHITECTURE", &"STATION"]
const ROAD_CATEGORIES: Array[StringName] = [&"BRIDGE"]
## A collider is a building on the map when it's at least this tall and this wide, and no wider than this.
const STRUCTURE_MIN_HEIGHT: float = 1.4
const STRUCTURE_MIN_WIDTH: float = 0.8
const STRUCTURE_MAX_WIDTH: float = 60.0

enum Glyph { SHRINE, DESK, PORTAL, QUEST, BEACON }
enum MapScope { ZONE, WORLD }
## What a map node is (the legend's order).
enum NodeKind { TOWN, QUEST, DUNGEON, SHRINE, DESK, PORTAL, CROSSING, BEACON, LANDMARK, ISLE }
## Each kind's name in the legend (plain words, 08 Gate 6).
const NODE_KIND_NAMES: Array[String] = ["Town", "Quest", "Dungeon or raid door", "Shrine", "Ink desk", "Portal", "Crossing", "Beacon",
	"Landmark", "Island"]
## Place names that make a town, and ones that make a dungeon (the Caldera's places).
const TOWN_WORDS: Array[String] = ["Market", "Quay", "Staithe", "Hall", "Waypost", "Wick", "Stead", "Bridge"]
const DUNGEON_WORDS: Array[String] = ["Sanctum", "Raid", "Sea-Door", "Trial", "Abyss", "Cathedral", "Aerie"]
## The legacy maps' towns (their map zones).
const LEGACY_TOWNS: Array[String] = ["Oakshire-Wick", "Bramble-Bridge", "Honey-Wick"]

static var _cache: Dictionary[StringName, ImageTexture] = {}
static var _waiting: Dictionary[StringName, Array] = {}
static var _tasks: Dictionary[StringName, int] = {}
static var _rects: Dictionary[StringName, Rect2] = {}
## Painted images waiting for the main thread (poll()), guarded by _lock.
static var _results: Dictionary[StringName, Image] = {}
static var _lock: Mutex = Mutex.new()


## The map's size along its long side here (512 in a window, 256 headless).
static func map_size() -> int:
	return MAP_SIZE_HEADLESS if DisplayServer.get_name() == "headless" else MAP_SIZE


## The level's map in a scope, baked now if it isn't yet (then kept).
static func bake_level_map(level: LevelBase, scope: MapScope = MapScope.ZONE) -> ImageTexture:
	var key: StringName = _key(level, scope)
	if _cache.has(key):
		return _cache[key]
	var source: MapSource = MapSource.gather(level, scope)
	var made: ImageTexture = _texture(source.paint(map_size()), source.rect)
	_cache[key] = made
	return made


## The level's map, painted on a worker thread: `done` gets the ImageTexture on
## the main thread, from poll() (which the minimap and the map panel call every frame).
static func request_level_map(level: LevelBase, done: Callable, scope: MapScope = MapScope.ZONE) -> void:
	var key: StringName = _key(level, scope)
	if _cache.has(key):
		done.call(_cache[key])
		return
	if _waiting.has(key):
		_waiting[key].append(done)
		return
	_waiting[key] = [done]
	var source: MapSource = MapSource.gather(level, scope)
	var size: int = map_size()
	_rects[key] = source.rect
	_tasks[key] = WorkerThreadPool.add_task(func() -> void:
		var image: Image = source.paint(size)
		CartographyBaker._lock.lock()
		CartographyBaker._results[key] = image
		CartographyBaker._lock.unlock())


## Hands every map painted since the last call to whoever asked for it (main thread).
static func poll() -> void:
	for key: StringName in _tasks.keys():
		if WorkerThreadPool.is_task_completed(_tasks[key]):
			_collect(key, true)


## Waits for every map still being painted and keeps it (a level leaving, or the game quitting).
static func finish_pending() -> void:
	for key: StringName in _tasks.keys():
		_collect(key, false)
	_waiting.clear()


static func _collect(key: StringName, answer: bool) -> void:
	WorkerThreadPool.wait_for_task_completion(_tasks[key])
	_tasks.erase(key)
	_lock.lock()
	var image: Image = _results.get(key, null)
	_results.erase(key)
	_lock.unlock()
	if image != null:
		_finish(key, image, _rects.get(key, Rect2()), answer)
	_rects.erase(key)


## The kept map of the level in a scope, or null while it's still being painted.
static func cached_map(level: LevelBase, scope: MapScope = MapScope.ZONE) -> ImageTexture:
	return _cache.get(_key(level, scope), null)


## Forgets every baked map (the tests, and a rebuilt level).
static func clear_cache() -> void:
	_cache.clear()


## The world rectangle a map shows (x, z).
static func world_rect(texture: Texture2D) -> Rect2:
	return texture.get_meta(META_RECT, Rect2()) if texture != null else Rect2()


## Where a world spot (x, z) falls on a map, 0 to 1 across and down.
static func world_to_uv(texture: Texture2D, at: Vector2) -> Vector2:
	var rect: Rect2 = world_rect(texture)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Vector2(0.5, 0.5)
	return (at - rect.position) / rect.size


# --- Frames and views ------------------------------------------------------------------

## Whether the level is the Caldera Isles (its islands each have their own frame).
static func is_archipelago(level: LevelBase) -> bool:
	return level is CalderaArchipelagoWorld and (level as CalderaArchipelagoWorld).streamer != null \
		and (level as CalderaArchipelagoWorld).streamer.builder != null


## The island the party is on (Caldera), or &"".
static func active_isle(level: LevelBase) -> StringName:
	return (level as CalderaArchipelagoWorld).streamer.active_isle if is_archipelago(level) else &""


## A spot in the level's own frame (x, z) in a scope's map frame: the World Map
## of the Caldera is The Sound's frame (The Crown at the origin); every other map is the level's own.
static func to_map_frame(level: LevelBase, scope: MapScope, local: Vector2) -> Vector2:
	if scope == MapScope.WORLD and is_archipelago(level):
		return local + CalderaAtlas.isle(active_isle(level)).sound_position
	return local


static func from_map_frame(level: LevelBase, scope: MapScope, at: Vector2) -> Vector2:
	if scope == MapScope.WORLD and is_archipelago(level):
		return at - CalderaAtlas.isle(active_isle(level)).sound_position
	return at


## The world rectangle a scope's view shows (in its map frame), about a hero at `hero_local`.
static func view_rect(level: LevelBase, scope: MapScope, texture: Texture2D, hero_local: Vector2) -> Rect2:
	var whole: Rect2 = world_rect(texture)
	if is_archipelago(level) or scope == MapScope.WORLD or whole.size.x <= 0.0:
		return whole
	# A single-map level's Zone Map: a close crop round the place the hero is in.
	var zone: WorldMapZoneResource = WorldVisualCatalog.map_zone_at(level.instance_id(), hero_local)
	var reach: float = zone.world_radius_m * ZONE_CROP_SCALE if zone != null else minf(whole.size.x, whole.size.y) * 0.4
	reach = minf(reach, minf(whole.size.x, whole.size.y))
	var middle: Vector2 = zone.world_center_xz if zone != null and zone.reach_share(hero_local) <= 1.4 else hero_local
	var crop: Rect2 = Rect2(middle - Vector2.ONE * reach * 0.5, Vector2.ONE * reach)
	crop.position = crop.position.clamp(whole.position, whole.end - crop.size)
	return crop


## The map's title for a scope: where you are, in plain words.
static func map_title(level: LevelBase, scope: MapScope, hero_local: Vector2) -> String:
	if is_archipelago(level):
		var world: CalderaArchipelagoWorld = level as CalderaArchipelagoWorld
		var isle: IslandGridResource = world.streamer.builder.isle
		if scope == MapScope.WORLD:
			return "The Caldera Isles · you are on %s" % isle.display_name
		var place: String = world.streamer.builder.place_name_at(Vector3(hero_local.x, 0.0, hero_local.y))
		return "%s · Lv %d–%d · %s" % [isle.display_name, isle.level_min, isle.level_max, place]
	var zone: WorldMapZoneResource = WorldVisualCatalog.map_zone_at(level.instance_id(), hero_local)
	if scope == MapScope.WORLD or zone == null:
		return level.level_title()
	return "%s · %s" % [level.level_title(), zone.display_name]


# --- Map nodes -------------------------------------------------------------------------------

## What the map names in a scope, and what a way-marker can be set on:
## [{"kind": NodeKind, "label": String, "at": Vector2 (map frame), "isle": StringName,
##   "local": Vector2 (the spot in its island's or level's own frame), "note": String}].
static func map_nodes(level: LevelBase, scope: MapScope) -> Array[Dictionary]:
	var nodes: Array[Dictionary] = []
	if is_archipelago(level):
		if scope == MapScope.WORLD:
			_archipelago_nodes(nodes)
		else:
			_island_nodes(level as CalderaArchipelagoWorld, nodes)
		_quest_nodes(nodes, scope, active_isle(level))
	else:
		for zone: WorldMapZoneResource in WorldVisualCatalog.map_zones(level.instance_id()):
			nodes.append(_node(NodeKind.TOWN if LEGACY_TOWNS.has(zone.display_name) else NodeKind.LANDMARK, zone.display_name,
				zone.world_center_xz, &"", zone.world_center_xz, zone.cooper_sign_title))
	# The live glyphs on the ground here (shrines, desks, portals, quest-givers, beacons).
	if scope == MapScope.ZONE or not is_archipelago(level):
		for found: Dictionary in glyphs(level.get_tree()):
			var kind: NodeKind = _glyph_kind(int(found["glyph"]))
			var at: Vector2 = found["at"]
			nodes.append(_node(kind, String(found.get("label", "")), to_map_frame(level, scope, at), active_isle(level), at, ""))
	return nodes


static func _node(kind: NodeKind, label: String, at: Vector2, isle: StringName, local: Vector2, note: String) -> Dictionary:
	return {"kind": kind, "label": label, "at": at, "isle": isle, "local": local, "note": note}


static func _glyph_kind(glyph: int) -> NodeKind:
	match glyph:
		Glyph.DESK:
			return NodeKind.DESK
		Glyph.PORTAL:
			return NodeKind.PORTAL
		Glyph.QUEST:
			return NodeKind.QUEST
		Glyph.BEACON:
			return NodeKind.BEACON
	return NodeKind.SHRINE


## What kind of node a Caldera place is, by its name.
static func place_kind(place_name: String, isle: IslandGridResource) -> NodeKind:
	for word: String in DUNGEON_WORDS:
		if place_name.contains(word):
			return NodeKind.DUNGEON
	if isle != null and place_name == isle.steading:
		return NodeKind.TOWN
	for word: String in TOWN_WORDS:
		if place_name.contains(word):
			return NodeKind.TOWN
	return NodeKind.LANDMARK


static func _island_nodes(world: CalderaArchipelagoWorld, nodes: Array[Dictionary]) -> void:
	var builder: IslandBuilder = world.streamer.builder
	var isle_id: StringName = world.streamer.active_isle
	for place: Dictionary in builder.places:
		var at: Vector3 = place["at"]
		var spot: Vector2 = Vector2(at.x, at.z)
		var kind: NodeKind = place_kind(String(place["name"]), builder.isle)
		# A crossing's place is drawn as its seam, below.
		if _seam_named(String(place["name"])) != null:
			continue
		nodes.append(_node(kind, String(place["name"]), spot, isle_id, spot, ""))
	for seam: LoadSeamResource in CalderaAtlas.seams_of(isle_id):
		var anchor: Vector3 = seam.anchor(isle_id)
		var other: IslandGridResource = CalderaAtlas.isle(seam.other(isle_id))
		var open: bool = CalderaWorldState.current == null or CalderaWorldState.current.lane_open(seam.gate_flag)
		nodes.append(_node(NodeKind.CROSSING, "%s → %s" % [seam.display_name, other.display_name], Vector2(anchor.x, anchor.z), isle_id,
			Vector2(anchor.x, anchor.z), "" if open else "closed for now"))


## The Caldera's quests: where its next goals wait, from the world's flags (the
## Root-Sanctum, then each island's Beacon, then The Crown's three trials, then
## the Harmonic Bell). The Zone Map shows the ones on this island.
static func quest_goals() -> Array[Dictionary]:
	var goals: Array[Dictionary] = []
	var state: CalderaWorldState = CalderaWorldState.current
	if state == null:
		return goals
	if not state.get_flag(CalderaWorldState.ROOT_SANCTUM_CLEARED):
		goals.append({"isle": CalderaAtlas.ISLE_OAKSHIRE_HOLM, "place": "The Root-Sanctum", "label": "Quest: clear The Root-Sanctum (Lv 6)"})
		return goals
	for isle: IslandGridResource in CalderaAtlas.isles():
		if isle.beacon_flag != &"" and not state.get_flag(isle.beacon_flag):
			goals.append({"isle": isle.isle_id, "place": "%s's Beacon" % isle.display_name, "label": "Quest: light %s's Beacon" % isle.display_name})
	if not goals.is_empty() or not state.can_land_on_crown():
		return goals
	# Each points at its arena (off the Ring Path), named for its shore (docs/23).
	var trial_places: Dictionary[StringName, Array] = {CalderaWorldState.TRIAL_ANVIL: ["The Trial of the Anvil", "Iron Shore"],
		CalderaWorldState.TRIAL_GALE: ["The Trial of the Gale", "Gale Cliffs"], CalderaWorldState.TRIAL_TIDE: ["The Trial of the Tide", "Tide Grottos"]}
	for trial: StringName in CalderaWorldState.TRIALS:
		if not state.trial_complete(trial):
			goals.append({"isle": CalderaAtlas.ISLE_THE_CROWN, "place": trial_places[trial][0], "label": "Quest: the trial at %s" % trial_places[trial][1]})
	if goals.is_empty() and not state.get_flag(CalderaWorldState.EBB_UNLOCKED):
		goals.append({"isle": CalderaAtlas.ISLE_THE_CROWN, "place": "The Summit Glade", "label": "Quest: ring the Harmonic Bell together"})
	return goals


static func _quest_nodes(nodes: Array[Dictionary], scope: MapScope, here: StringName) -> void:
	for goal: Dictionary in quest_goals():
		var isle_id: StringName = goal["isle"]
		if scope == MapScope.ZONE and isle_id != here:
			continue
		var spot: Dictionary = CalderaAtlas.builder_for(isle_id).place(String(goal["place"]))
		if spot.is_empty():
			continue
		var at: Vector3 = spot["at"]
		var local: Vector2 = Vector2(at.x, at.z)
		var shown: Vector2 = local + (CalderaAtlas.isle(isle_id).sound_position if scope == MapScope.WORLD else Vector2.ZERO)
		nodes.append(_node(NodeKind.QUEST, String(goal["label"]), shown, isle_id, local, CalderaAtlas.isle(isle_id).display_name))


static func _seam_named(place_name: String) -> LoadSeamResource:
	for seam: LoadSeamResource in CalderaAtlas.seams():
		if seam.display_name == place_name:
			return seam
	return null


static func _archipelago_nodes(nodes: Array[Dictionary]) -> void:
	for isle: IslandGridResource in CalderaAtlas.isles():
		var builder: IslandBuilder = CalderaAtlas.builder_for(isle.isle_id)
		nodes.append(_node(NodeKind.ISLE, isle.display_name, isle.sound_position, isle.isle_id, Vector2.ZERO,
			"Lv %d–%d · %s" % [isle.level_min, isle.level_max, isle.compass]))
		for place: Dictionary in builder.places:
			var name: String = String(place["name"])
			var kind: NodeKind = place_kind(name, isle)
			if kind == NodeKind.LANDMARK or _seam_named(name) != null:
				continue
			var at: Vector3 = place["at"]
			nodes.append(_node(kind, name, isle.sound_position + Vector2(at.x, at.z), isle.isle_id, Vector2(at.x, at.z), isle.display_name))
	for seam: LoadSeamResource in CalderaAtlas.seams():
		var a: Vector2 = CalderaAtlas.isle(seam.isle_a).sound_position + Vector2(seam.anchor_a.x, seam.anchor_a.z)
		var b: Vector2 = CalderaAtlas.isle(seam.isle_b).sound_position + Vector2(seam.anchor_b.x, seam.anchor_b.z)
		nodes.append(_node(NodeKind.CROSSING, seam.display_name, (a + b) * 0.5, seam.isle_a, Vector2(seam.anchor_a.x, seam.anchor_a.z),
			"%s to %s" % [CalderaAtlas.isle(seam.isle_a).display_name, CalderaAtlas.isle(seam.isle_b).display_name]))


## Where a way-marker on a node leads the hero now, in the level's own frame:
## {"target": Vector2, "via": String}. A node on another island leads to the
## crossing that heads there (straight there, else back toward Miller's Oak).
static func route_to(level: LevelBase, isle_id: StringName, local: Vector2) -> Dictionary:
	var here: StringName = active_isle(level)
	if here == &"" or isle_id == &"" or isle_id == here:
		return {"target": local, "via": ""}
	var best: LoadSeamResource = null
	for seam: LoadSeamResource in CalderaAtlas.seams_of(here):
		if seam.other(here) == isle_id:
			best = seam
			break
		if best == null and seam.other(here) == CalderaAtlas.ISLE_OAKSHIRE_HOLM:
			best = seam
	if best == null:
		return {"target": local, "via": ""}
	var anchor: Vector3 = best.anchor(here)
	return {"target": Vector2(anchor.x, anchor.z), "via": best.display_name}


# --- Glyphs and cracks ---------------------------------------------------------------------

## What a map glyph stands for.
static func glyph_of(node: Node) -> int:
	if node is ScribeDesk or node is ScriberyStation:
		return Glyph.DESK
	if node is RaidPortal or node is PortalApron:
		return Glyph.PORTAL
	if node is TownsfolkNPC:
		return Glyph.QUEST
	if node is IslandBeacon:
		return Glyph.BEACON
	return Glyph.SHRINE


## A glyph's label: a quest-giver's name and title, otherwise the node's own sign if it has one.
static func glyph_label(node: Node) -> String:
	var npc: TownsfolkNPC = node as TownsfolkNPC
	if npc != null:
		return "%s, %s" % [npc.npc_name, npc.title] if npc.title != "" else npc.npc_name
	for property: StringName in [&"title", &"display_name", &"place_name"]:
		if property in node and node.get(property) is String and String(node.get(property)) != "":
			return String(node.get(property))
	match glyph_of(node):
		Glyph.DESK:
			return "Ink desk"
		Glyph.PORTAL:
			return "Portal"
		Glyph.BEACON:
			return "Beacon"
	return "Shrine"


## Every glyph in the tree now: [{"at": Vector2, "glyph": Glyph, "label": String}].
static func glyphs(tree: SceneTree) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	if tree == null:
		return found
	for node: Node in tree.get_nodes_in_group(GLYPH_GROUP):
		var spot: Node3D = node as Node3D
		if spot != null and spot.is_inside_tree():
			found.append({"at": Vector2(spot.global_position.x, spot.global_position.z), "glyph": glyph_of(node), "label": glyph_label(node)})
	return found


## Every Hush-Crack of the level, open or calmed, live or listed by its builder:
## [{"id": StringName, "at": Vector2, "calmed": bool}].
static func cracks(level: LevelBase) -> Array[Dictionary]:
	var listed: Dictionary[StringName, Dictionary] = {}
	var path: String = _cartography_path(level)
	var data: Dictionary = _read_json(path) if path != "" else {}
	var director: WorldAtmosphereDirector = WorldAtmosphereDirector.current
	var world_state: WorldStateDB = level.get(&"world_state") as WorldStateDB if &"world_state" in level else null
	for entry: Variant in data.get("cracks", []):
		var crack: Dictionary = entry as Dictionary
		var id: StringName = StringName(String(crack.get("id", "")))
		var calmed: bool = false
		if director != null and director.has_crack_state(id):
			calmed = director.crack_state(id) != ZoneSuccessionVisualResource.SuccessionState.ZONE_HUSHED
		elif world_state != null and String(crack.get("persist", "")) != "":
			var chunk: Array = crack.get("chunk", [0, 0])
			calmed = bool(world_state.get_entity_state(Vector2i(int(chunk[0]), int(chunk[1])), StringName(String(crack["persist"]))).get("cleared", false))
		listed[id] = {"id": id, "at": Vector2(float(crack.get("x", 0.0)), float(crack.get("z", 0.0))), "calmed": calmed}
	if director != null:
		for live: HushCrackLandmark in director.cracks():
			if is_instance_valid(live) and live.is_inside_tree():
				listed[live.crack_id] = {"id": live.crack_id, "at": Vector2(live.global_position.x, live.global_position.z),
					"calmed": not live.is_hushed()}
	var list: Array[Dictionary] = []
	list.assign(listed.values())
	return list


static func _finish(key: StringName, image: Image, rect: Rect2, answer: bool) -> void:
	var made: ImageTexture = _texture(image, rect)
	_cache[key] = made
	if answer:
		for done: Callable in _waiting.get(key, []):
			var target: Object = done.get_object()
			if done.is_valid() and (target == null or is_instance_valid(target)):
				done.call(made)
	_waiting.erase(key)


static func _texture(image: Image, rect: Rect2) -> ImageTexture:
	var made: ImageTexture = ImageTexture.create_from_image(image)
	made.set_meta(META_RECT, rect)
	return made


## The cache key: the Caldera's Zone Map per island and its World Map; one map per other level.
static func _key(level: LevelBase, scope: MapScope) -> StringName:
	if is_archipelago(level):
		return StringName("caldera:world" if scope == MapScope.WORLD else "caldera:zone:%s" % active_isle(level))
	var layout: StringName = WorldGridConfig.layout.layout_id() if _is_streamed(level) else &"walled"
	return StringName("%s:%s" % [level.instance_id(), layout])


## A legacy seamless world (its ground from WorldGridConfig's layout).
static func _is_streamed(level: LevelBase) -> bool:
	return level is EverwoodWorld or level is OakshireVale


static func _cartography_path(level: LevelBase) -> String:
	return WorldGridConfig.layout.cartography_path() if _is_streamed(level) else ""


static func _read_json(path: String) -> Dictionary:
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


## The building footprints (x, z, width, depth, yaw, road) of every kit under `root`.
static func kit_footprints(root: Node) -> Array[PackedFloat32Array]:
	var found: Array[PackedFloat32Array] = []
	if root == null:
		return found
	for node: Node in root.find_children("*", "WorldKitInstance", true, false):
		var placed: WorldKitInstance = node as WorldKitInstance
		var print_of: PackedFloat32Array = footprint_of(placed, placed.global_transform if placed.is_inside_tree() else Transform3D(Basis.IDENTITY, placed.position))
		if not print_of.is_empty():
			found.append(print_of)
	return found


## One kit's footprint: x, z, width, depth, yaw and 0 (a building) or 1 (a road), or empty for other kits.
static func footprint_of(placed: WorldKitInstance, where: Transform3D) -> PackedFloat32Array:
	var kit: WorldPropKitResource = WorldVisualCatalog.kit(placed.kit_id)
	if kit == null or not (kit.category in BUILDING_CATEGORIES or kit.category in ROAD_CATEGORIES):
		return PackedFloat32Array()
	var size: Vector3 = placed.size if placed.size != Vector3.ZERO else kit.bounding_size
	var scale: Vector3 = where.basis.get_scale()
	var x_axis: Vector3 = where.basis.x
	var yaw: float = atan2(-x_axis.z, x_axis.x)
	return PackedFloat32Array([where.origin.x, where.origin.z, size.x * scale.x, size.z * scale.z, yaw,
		1.0 if kit.category in ROAD_CATEGORIES else 0.0])


## The footprints of the buildings standing under `root` as colliders (huts, halls,
## towers, walls): every StaticBody3D box or cylinder tall enough to be a building.
static func collider_footprints(root: Node) -> Array[PackedFloat32Array]:
	var found: Array[PackedFloat32Array] = []
	if root == null:
		return found
	for node: Node in root.find_children("*", "CollisionShape3D", true, false):
		var shape: CollisionShape3D = node as CollisionShape3D
		if not shape.is_inside_tree() or not shape.get_parent() is StaticBody3D:
			continue
		var where: Transform3D = shape.global_transform
		var scale: Vector3 = where.basis.get_scale()
		var box: BoxShape3D = shape.shape as BoxShape3D
		var cylinder: CylinderShape3D = shape.shape as CylinderShape3D
		var extent: Vector3 = Vector3.ZERO
		if box != null:
			extent = box.size * scale
		elif cylinder != null:
			extent = Vector3(cylinder.radius * 2.0 * scale.x, cylinder.height * scale.y, cylinder.radius * 2.0 * scale.z)
		else:
			continue
		if extent.y < STRUCTURE_MIN_HEIGHT or minf(extent.x, extent.z) < STRUCTURE_MIN_WIDTH or maxf(extent.x, extent.z) > STRUCTURE_MAX_WIDTH:
			continue
		var x_axis: Vector3 = where.basis.x
		found.append(PackedFloat32Array([where.origin.x, where.origin.z, extent.x, extent.z, atan2(-x_axis.z, x_axis.x), 0.0]))
	return found


## What a level's map is drawn from, gathered on the main thread; paint() is pure.
class MapSource:
	extends RefCounted

	var rect: Rect2 = Rect2(0.0, 0.0, 64.0, 64.0)
	## A legacy seamless world's layout (thread-safe), or null.
	var layout: WorldLayout
	## The Caldera's islands in this map's frame: [{"builder": IslandBuilder, "offset": Vector2, "half": float}].
	var isles: Array[Dictionary] = []
	var sea_level: float = 0.0
	## A walled instance's heights on a grid across `rect` (grid_size.x by grid_size.y), NAN where nothing was hit.
	var heights: PackedFloat32Array = PackedFloat32Array()
	var grid_size: Vector2i = Vector2i.ZERO
	## Water rectangles (x, z, width, depth) and paths ({"points": PackedVector2Array, "half_width": float}).
	var water: Array[Rect2] = []
	var paths: Array[Dictionary] = []
	var footprints: Array[PackedFloat32Array] = []
	## The features near the tile being painted (per island), so each sample reads only those.
	var _near: Dictionary = {}

	static func gather(level: LevelBase, scope: MapScope = MapScope.ZONE) -> MapSource:
		var source: MapSource = MapSource.new()
		if CartographyBaker.is_archipelago(level):
			source._gather_archipelago(level as CalderaArchipelagoWorld, scope)
			return source
		source.footprints = CartographyBaker.kit_footprints(level)
		if CartographyBaker._is_streamed(level):
			source.layout = WorldGridConfig.layout
			source.rect = source.layout.map_rect()
			var listed: Dictionary = CartographyBaker._read_json(source.layout.cartography_path())
			for entry: Variant in listed.get("footprints", []):
				var values: Array = entry as Array
				if values.size() >= 6:
					source.footprints.append(PackedFloat32Array(values))
			return source
		source.footprints.append_array(CartographyBaker.collider_footprints(level))
		source.rect = level.map_rect()
		source.paths = level.map_paths()
		source._read_walled(level)
		return source

	## The live island (Zone Map), or all five in The Sound's frame (World Map), and the buildings standing on the live one.
	func _gather_archipelago(world: CalderaArchipelagoWorld, scope: MapScope) -> void:
		sea_level = CalderaWorldState.current.sea_level_y if CalderaWorldState.current != null else 0.0
		if scope == MapScope.ZONE:
			var builder: IslandBuilder = world.streamer.builder
			var half: float = builder.isle.grid_size_m() * 0.5
			isles.append({"builder": builder, "offset": Vector2.ZERO, "half": half})
			rect = Rect2(-half, -half, half * 2.0, half * 2.0)
			footprints = CartographyBaker.collider_footprints(world.streamer.structures)
			return
		var reach: Rect2 = Rect2()
		var started: bool = false
		for isle: IslandGridResource in CalderaAtlas.isles():
			var half: float = isle.grid_size_m() * 0.5
			isles.append({"builder": CalderaAtlas.builder_for(isle.isle_id), "offset": isle.sound_position, "half": half})
			var block: Rect2 = Rect2(isle.sound_position - Vector2.ONE * half, Vector2.ONE * half * 2.0)
			reach = block if not started else reach.merge(block)
			started = true
		rect = reach.grow(CartographyBaker.WORLD_MARGIN_M)

	## Rays straight down at the colliders on a coarse grid, and the water surfaces' extents.
	func _read_walled(level: LevelBase) -> void:
		var long_side: float = maxf(rect.size.x, rect.size.y)
		grid_size = Vector2i(maxi(2, roundi(RAY_GRID * rect.size.x / long_side)), maxi(2, roundi(RAY_GRID * rect.size.y / long_side)))
		heights.resize(grid_size.x * grid_size.y)
		var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state if level.is_inside_tree() else null
		for gz: int in grid_size.y:
			for gx: int in grid_size.x:
				var x: float = rect.position.x + (gx + 0.5) * rect.size.x / grid_size.x
				var z: float = rect.position.y + (gz + 0.5) * rect.size.y / grid_size.y
				var y: float = NAN
				if space != null:
					var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(x, 80.0, z), Vector3(x, -80.0, z), ActorBase.LAYER_WORLD)
					var hit: Dictionary = space.intersect_ray(query)
					if not hit.is_empty():
						y = (hit["position"] as Vector3).y
				heights[gz * grid_size.x + gx] = y
		for node: Node in level.find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = node as MeshInstance3D
			if mesh.mesh == null or mesh.mesh.get_surface_count() == 0 or not mesh.is_visible_in_tree():
				continue
			var material: ShaderMaterial = (mesh.material_override if mesh.material_override != null else mesh.mesh.surface_get_material(0)) as ShaderMaterial
			if material == null or material.shader != WorldVisualCatalog.WATER_SHADER:
				continue
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			water.append(Rect2(box.position.x, box.position.z, box.size.x, box.size.z))

	## Readies the features near one tile of the map (an island map reads only these).
	func _ready_tile(tile: Rect2) -> void:
		_near.clear()
		for index: int in isles.size():
			var entry: Dictionary = isles[index]
			var local: Rect2 = Rect2(tile.position - (entry["offset"] as Vector2), tile.size)
			var half: float = entry["half"]
			if not local.intersects(Rect2(-half, -half, half * 2.0, half * 2.0)):
				continue
			_near[index] = (entry["builder"] as IslandBuilder)._features_near(local.grow(8.0))

	## The island holding a spot (its index in `isles`), or -1 for open sea.
	func _isle_at(x: float, z: float) -> int:
		var best: int = -1
		var best_distance: float = INF
		for index: int in _near:
			var entry: Dictionary = isles[index]
			var local: Vector2 = Vector2(x, z) - (entry["offset"] as Vector2)
			var half: float = entry["half"]
			if absf(local.x) <= half and absf(local.y) <= half and local.length() < best_distance:
				best = index
				best_distance = local.length()
		return best

	func _height(x: float, z: float) -> float:
		if not isles.is_empty():
			var index: int = _isle_at(x, z)
			if index < 0:
				return sea_level - DEEP_WATER_M
			var entry: Dictionary = isles[index]
			var local: Vector2 = Vector2(x, z) - (entry["offset"] as Vector2)
			var near: Array = _near[index]
			return (entry["builder"] as IslandBuilder)._height(local.x, local.y, near[0], near[1])
		if layout != null:
			return layout.sample_height(x, z)
		var gx: float = clampf((x - rect.position.x) / rect.size.x * grid_size.x - 0.5, 0.0, grid_size.x - 1.001)
		var gz: float = clampf((z - rect.position.y) / rect.size.y * grid_size.y - 0.5, 0.0, grid_size.y - 1.001)
		var x0: int = int(gx)
		var z0: int = int(gz)
		var corners: Array[float] = [heights[z0 * grid_size.x + x0], heights[z0 * grid_size.x + x0 + 1],
			heights[(z0 + 1) * grid_size.x + x0], heights[(z0 + 1) * grid_size.x + x0 + 1]]
		var known: float = 0.0
		for value: float in corners:
			if not is_nan(value):
				known = value
		for index: int in corners.size():
			if is_nan(corners[index]):
				corners[index] = known
		var fx: float = gx - x0
		var fz: float = gz - z0
		return lerpf(lerpf(corners[0], corners[1], fx), lerpf(corners[2], corners[3], fx), fz)

	func _feature(x: float, z: float, h: float) -> int:
		if not isles.is_empty():
			if h < sea_level - 0.05:
				return WorldLayout.MapFeature.WATER
			var index: int = _isle_at(x, z)
			if index >= 0:
				var entry: Dictionary = isles[index]
				var local: Vector2 = Vector2(x, z) - (entry["offset"] as Vector2)
				var near: Array = _near[index]
				if (entry["builder"] as IslandBuilder)._path_weight(local.x, local.y, near[2]) > 0.5:
					return WorldLayout.MapFeature.ROAD
			return WorldLayout.MapFeature.GROUND
		if layout != null:
			return layout.map_feature(x, z, h)
		var at: Vector2 = Vector2(x, z)
		for pool: Rect2 in water:
			if pool.has_point(at):
				return WorldLayout.MapFeature.WATER
		for path: Dictionary in paths:
			var points: PackedVector2Array = path["points"]
			var half: float = float(path.get("half_width", 2.0))
			for index: int in points.size() - 1:
				if at.distance_to(Geometry2D.get_closest_point_to_segment(at, points[index], points[index + 1])) < half:
					return WorldLayout.MapFeature.ROAD
		return WorldLayout.MapFeature.GROUND

	## The parchment, `long_side` pixels along its long side (pure: safe on a worker thread).
	func paint(long_side: int) -> Image:
		var aspect: float = rect.size.x / maxf(rect.size.y, 0.001)
		var width: int = long_side if aspect >= 1.0 else maxi(8, roundi(long_side * aspect))
		var height: int = long_side if aspect <= 1.0 else maxi(8, roundi(long_side / aspect))
		var step: Vector2 = Vector2(rect.size.x / width, rect.size.y / height)
		var levels: PackedFloat32Array = PackedFloat32Array()
		levels.resize(width * height)
		var features: PackedByteArray = PackedByteArray()
		features.resize(width * height)
		# Tile by tile, so an island map reads only the features near each tile.
		for tile_y: int in range(0, height, TILE_PX):
			for tile_x: int in range(0, width, TILE_PX):
				var tile: Rect2 = Rect2(rect.position + Vector2(tile_x, tile_y) * step, Vector2(TILE_PX, TILE_PX) * step)
				if not isles.is_empty():
					_ready_tile(tile)
				for py: int in range(tile_y, mini(tile_y + TILE_PX, height)):
					var z: float = rect.position.y + (py + 0.5) * step.y
					for px: int in range(tile_x, mini(tile_x + TILE_PX, width)):
						var x: float = rect.position.x + (px + 0.5) * step.x
						var h: float = _height(x, z)
						levels[py * width + px] = h
						features[py * width + px] = _feature(x, z, h)
		var bytes: PackedByteArray = PackedByteArray()
		bytes.resize(width * height * 4)
		for py: int in height:
			for px: int in width:
				var index: int = py * width + px
				var h: float = levels[index]
				var right: float = levels[py * width + mini(px + 1, width - 1)]
				var below: float = levels[mini(py + 1, height - 1) * width + px]
				var feature: int = features[index]
				var color: Color = PARCHMENT
				# A soft hill-shade, lit from the north-west.
				var slope: float = ((right - h) / step.x + (below - h) / step.y) * 0.5
				color = color.darkened(clampf(slope * 0.6, -1.0, 1.0) * HILL_SHADE) if slope > 0.0 else color.lightened(clampf(-slope * 0.6, 0.0, 1.0) * HILL_SHADE * 0.5)
				match feature:
					WorldLayout.MapFeature.WATER:
						color = WATER.darkened(clampf((sea_level - h) / DEEP_WATER_M, 0.0, 1.0) * 0.32) if not isles.is_empty() else WATER
					WorldLayout.MapFeature.ROAD:
						color = ROAD
				if feature == WorldLayout.MapFeature.WATER:
					# The shore inked where water meets land.
					var shore: bool = false
					for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						var nx: int = clampi(px + offset.x, 0, width - 1)
						var ny: int = clampi(py + offset.y, 0, height - 1)
						shore = shore or features[ny * width + nx] != WorldLayout.MapFeature.WATER
					if shore:
						color = SHORE_INK
				else:
					var band: int = floori(h / CONTOUR_STEP_M)
					if band != floori(right / CONTOUR_STEP_M) or band != floori(below / CONTOUR_STEP_M):
						color = color.lerp(CONTOUR, 0.85) if feature == WorldLayout.MapFeature.GROUND else color.darkened(0.12)
				var at: int = index * 4
				bytes[at] = int(color.r8)
				bytes[at + 1] = int(color.g8)
				bytes[at + 2] = int(color.b8)
				bytes[at + 3] = 255
		for footprint: PackedFloat32Array in footprints:
			_stamp(bytes, width, height, step, footprint)
		var image: Image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, bytes)
		image.generate_mipmaps()
		return image

	## Fills one footprint (x, z, width, depth, yaw, road) into the pixels, at least a pixel across.
	func _stamp(bytes: PackedByteArray, width: int, height: int, step: Vector2, footprint: PackedFloat32Array) -> void:
		var center: Vector2 = Vector2(footprint[0], footprint[1])
		var half: Vector2 = Vector2(maxf(footprint[2] * 0.5, step.x * 0.6), maxf(footprint[3] * 0.5, step.y * 0.6))
		var yaw: float = footprint[4]
		var tint: Color = ROAD if footprint[5] > 0.5 else FOOTPRINT
		var reach: float = half.length()
		var low: Vector2i = Vector2i(floori((center.x - reach - rect.position.x) / step.x), floori((center.y - reach - rect.position.y) / step.y))
		var high: Vector2i = Vector2i(ceili((center.x + reach - rect.position.x) / step.x), ceili((center.y + reach - rect.position.y) / step.y))
		var c: float = cos(yaw)
		var s: float = sin(yaw)
		for py: int in range(maxi(low.y, 0), mini(high.y, height)):
			for px: int in range(maxi(low.x, 0), mini(high.x, width)):
				var dx: float = rect.position.x + (px + 0.5) * step.x - center.x
				var dz: float = rect.position.y + (py + 0.5) * step.y - center.y
				var lx: float = dx * c - dz * s
				var lz: float = dx * s + dz * c
				if absf(lx) <= half.x and absf(lz) <= half.y:
					var at: int = (py * width + px) * 4
					bytes[at] = int(tint.r8)
					bytes[at + 1] = int(tint.g8)
					bytes[at + 2] = int(tint.b8)
