## The world's looks by id (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §2, §4,
## §5, §7.1): the seventeen biomes (ZoneBiomeResource) — the six atlas zones,
## Oakshire Vale's village and five petals, and the five places of the
## Bramble-Bridge trail — the world's prop kits (WorldPropKitResource), the
## three looks of Ecological Succession (ZoneSuccessionVisualResource), which
## biome each place we've built wears, and the shared world materials every
## builder and kit paints with (one material per look, so scenes stay small and
## draw calls batch).
## A curated resource wins: res://data/world_visuals/<id>.tres (a biome, a kit,
## or succession_hushed / _reclaimed / _weathering) replaces the one built here.
class_name WorldVisualCatalog
extends RefCounted

const OVERRIDE_FOLDER: String = "res://data/world_visuals/"
const TRIPLANAR_SHADER: Shader = preload("res://src/world/shaders/storybook_world_triplanar.gdshader")
const TRIPLANAR_DOUBLE_SHADER: Shader = preload("res://src/world/shaders/storybook_world_triplanar_double.gdshader")
const TERRAIN_SHADER: Shader = preload("res://src/world/shaders/storybook_terrain_splat.gdshader")
const FOLIAGE_SHADER: Shader = preload("res://src/world/shaders/storybook_foliage_wind.gdshader")
const WATER_SHADER: Shader = preload("res://src/world/shaders/storybook_water_stream.gdshader")

const Craft = ProceduralTextureAtelier.Set
const Sign = ScribeSignResource.Sign
const Succession = ZoneSuccessionVisualResource.SuccessionState

## The Master Palette (§2.3).
const TURF: Color = Color("#5B8C4A")
const MOSS: Color = Color("#436B3C")
const FLAGSTONE: Color = Color("#C8BFA8")
const LOAM: Color = Color("#594636")
const GRANITE: Color = Color("#7A8086")
const TIMBER: Color = Color("#6E4B2E")
const LIME_WASH: Color = Color("#F2ECE1")
const BRICK: Color = Color("#B55A3F")
const ARENA_FLOOR: Color = Color("#8A8E91")
const IRON_ROOT: Color = Color("#D9822B")
const RIME_GALE: Color = Color("#38A3D1")
const WARM_HEARTH: Color = Color("#F2B749")
const STAR_TIDE: Color = Color("#8C52D9")
const SIGN_COLORS: Array[Color] = [IRON_ROOT, RIME_GALE, WARM_HEARTH, STAR_TIDE]
## Moss and heather for the triplanar shader's upward faces.
const MOSS_TOP: Color = Color("#4A733E")
const HEATHER_TOP: Color = Color("#7B587D")
## Sky (§6.2).
const SKY_TOP: Color = Color("#3B78B8")
const SKY_HORIZON: Color = Color("#F5E2C4")
## Water (§3.4).
const WATER_SHALLOW: Color = Color("#52B8B2")
const WATER_DEEP: Color = Color("#1F5E6B")

## The six atlas zones (MythopoeticAtlas).
const TIZZI_WED_GREEN: StringName = &"tizzi_wed_green"
const GULL_WICK_HAVEN: StringName = &"gull_wick_haven"
const BARLEY_BRIDGE_MEADOW: StringName = &"barley_bridge_meadow"
const RUSH_LIGHT_HOLLOW: StringName = &"rush_light_hollow"
const BARROW_CRAG_CROSSING: StringName = &"barrow_crag_crossing"
const SUNKEN_CROWN_FALLS: StringName = &"sunken_crown_falls"
## Oakshire Vale's village and petals.
const OAKSHIRE_WICK: StringName = &"oakshire_wick"
const WAYFARER_GREEN: StringName = &"wayfarer_green"
const PIPPIN_GREEN: StringName = &"pippin_green"
const QUARRY_WICK: StringName = &"quarry_wick"
const BRAMBLE_HOLLOW: StringName = &"bramble_hollow"
const NINE_STONES_CROSSING: StringName = &"nine_stones_crossing"
## The Bramble-Bridge trail.
const HONEY_WICK: StringName = &"honey_wick"
const BRAMBLE_BRIDGE: StringName = &"bramble_bridge"
const MOSS_OAK_HOLLOW: StringName = &"moss_oak_hollow"
const DOVER_SLAP_FALLS: StringName = &"dover_slap_falls"
const RING_OF_THE_CAIRNSMAN: StringName = &"ring_of_the_cairnsman"

## The biome each place we've built wears (the places of MythopoeticAtlas.PLACE_ZONES).
const PLACE_BIOMES: Dictionary[String, StringName] = {
	"Oakshire-Wick": OAKSHIRE_WICK,
	"The Settled Meadow": OAKSHIRE_WICK,
	"Wayfarer-Green": WAYFARER_GREEN,
	"Pippin-Green": PIPPIN_GREEN,
	"Quarry-Wick": QUARRY_WICK,
	"Bramble-Hollow": BRAMBLE_HOLLOW,
	"Nine-Stones-Crossing": NINE_STONES_CROSSING,
	"Honey-Wick": HONEY_WICK,
	"Bramble-Bridge": BRAMBLE_BRIDGE,
	"Moss-Oak-Hollow": MOSS_OAK_HOLLOW,
	"Rush-Light-Hollow": RUSH_LIGHT_HOLLOW,
	"Dover-Slap-Bridge": DOVER_SLAP_FALLS,
	"The Ring of the Cairnsman": RING_OF_THE_CAIRNSMAN,
}
## The biome under each place's score (ZoneMusicProfileResource ids, 16 GDD §4).
const MUSIC_BIOMES: Dictionary[StringName, StringName] = {
	&"honey_wick": HONEY_WICK,
	&"bramble_bridge_square": BRAMBLE_BRIDGE,
	&"moss_oak_hollow": MOSS_OAK_HOLLOW,
	&"dover_slap_falls": DOVER_SLAP_FALLS,
	&"ring_of_the_cairnsman": RING_OF_THE_CAIRNSMAN,
	&"oakshire_vale": OAKSHIRE_WICK,
}
## Moss-Oak-Hollow's sunken lane wears Rush-Light-Hollow's look past this trail z (16 GDD's discord blend runs -54 to -74).
const SUNKEN_LANE_Z: float = -62.0

## The kits (§4), in catalog order.
## The leaf ramp's share of a crown's light, the grass's sunlit tip and its wind-wave (18 GDD §4.1-4.2).
const LEAF_RAMP_SHARE: float = 0.75
const GRASS_TIP: Color = Color("#84BD52")
const GRASS_WAVE_BEND_DEG: float = 28.0
const GRASS_GUST_SHEEN: float = 0.14

const KIT_HOUSE_STEPPED_GABLE: StringName = &"kit_house_stepped_gable"
const KIT_WATERMILL_WHEEL: StringName = &"kit_watermill_wheel"
const KIT_BRIDGE_STONE_ARCH: StringName = &"kit_bridge_stone_arch"
const KIT_BRIDGE_CARPATHIAN_TRESTLE: StringName = &"kit_bridge_carpathian_trestle"
const KIT_SCRIBE_DESK_PAVILION: StringName = &"kit_scribe_desk_pavilion"
const KIT_CHIME_SHRINE_PAGODA: StringName = &"kit_chime_shrine_pagoda"
const KIT_CHIME_POST_DIAGNOSTIC: StringName = &"kit_chime_post_diagnostic"
const KIT_WATER_SHRINE_OASIS: StringName = &"kit_water_shrine_oasis"
const KIT_HUSH_CRACK_AND_CAIRN: StringName = &"kit_hush_crack_and_cairn"
const KIT_TREE_MOSS_OAK: StringName = &"kit_tree_moss_oak"
const KIT_TREE_ORCHARD_APPLE: StringName = &"kit_tree_orchard_apple"
const KIT_TREE_WEEPING_WILLOW: StringName = &"kit_tree_weeping_willow"
const KIT_TREE_HIGHLAND_PINE: StringName = &"kit_tree_highland_pine"
const KIT_DRYSTONE_WALL: StringName = &"kit_drystone_wall"
const KIT_BEE_HIVE: StringName = &"kit_bee_hive"
const KIT_PUMPKIN_PATCH: StringName = &"kit_pumpkin_patch"
const KIT_STANDING_STONE: StringName = &"kit_standing_stone"
const KIT_WIND_LANTERN_POST: StringName = &"kit_wind_lantern_post"
const KIT_WINDMILL: StringName = &"kit_windmill"
const KIT_QUARRY_CRANE: StringName = &"kit_quarry_crane"
const KIT_ASHLAR_STACK: StringName = &"kit_ashlar_stack"
# Phase 18 (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §3.2, §4.3).
const KIT_MARKET_PAVILION: StringName = &"kit_market_pavilion"
const KIT_CLIFF_CORNICE: StringName = &"kit_cliff_cornice"
const KIT_PATH_SLEEPER: StringName = &"kit_path_sleeper"
const KIT_STEPPING_STONE: StringName = &"kit_stepping_stone"
const KIT_GUIDE_POST: StringName = &"kit_guide_post"
const TREE_KITS: Array[StringName] = [KIT_TREE_MOSS_OAK, KIT_TREE_ORCHARD_APPLE, KIT_TREE_WEEPING_WILLOW, KIT_TREE_HIGHLAND_PINE]

static var _biomes: Dictionary[StringName, ZoneBiomeResource] = {}
static var _biome_order: Array[StringName] = []
static var _kits: Dictionary[StringName, WorldPropKitResource] = {}
static var _kit_order: Array[StringName] = []
static var _succession: Dictionary[int, ZoneSuccessionVisualResource] = {}
static var _map_zones: Dictionary[StringName, WorldMapZoneResource] = {}
static var _map_zone_order: Array[StringName] = []
static var _materials: Dictionary[String, Material] = {}


static func biome(id: StringName) -> ZoneBiomeResource:
	_ensure()
	return _biomes.get(id, null)


## The seventeen biomes, atlas zones first, then Oakshire Vale, then the trail.
static func biomes() -> Array[ZoneBiomeResource]:
	_ensure()
	var list: Array[ZoneBiomeResource] = []
	for id: StringName in _biome_order:
		list.append(_biomes[id])
	return list


static func kit(id: StringName) -> WorldPropKitResource:
	_ensure()
	return _kits.get(id, null)


static func kits() -> Array[WorldPropKitResource]:
	_ensure()
	var list: Array[WorldPropKitResource] = []
	for id: StringName in _kit_order:
		list.append(_kits[id])
	return list


static func succession(state: int) -> ZoneSuccessionVisualResource:
	_ensure()
	return _succession.get(state, _succession[Succession.ZONE_HUSHED])


## The biome a place wears (&"" for a place we haven't dressed).
## A place on the Wayfarer's map by id (18 GDD §8.1), or null.
static func map_zone(id: StringName) -> WorldMapZoneResource:
	_ensure()
	return _map_zones.get(id, null)


## Every map place in one instance (InstanceManager id), in registration order; every one when `instance` is &"".
static func map_zones(instance: StringName = &"") -> Array[WorldMapZoneResource]:
	_ensure()
	var list: Array[WorldMapZoneResource] = []
	for id: StringName in _map_zone_order:
		var zone: WorldMapZoneResource = _map_zones[id]
		if instance == &"" or zone.instance_id == instance:
			list.append(zone)
	return list


## The map place a spot (world x, z) is in: the one it lies deepest inside, else the nearest (null in an instance with none).
static func map_zone_at(instance: StringName, at: Vector2) -> WorldMapZoneResource:
	var best: WorldMapZoneResource = null
	var best_share: float = INF
	for zone: WorldMapZoneResource in map_zones(instance):
		var share: float = zone.reach_share(at)
		if share < best_share:
			best_share = share
			best = zone
	return best


static func biome_for_place(place: String) -> StringName:
	return PLACE_BIOMES.get(place, &"")


## The biome under a score (&"" for none).
static func biome_for_music(profile: StringName) -> StringName:
	return MUSIC_BIOMES.get(profile, &"")


# --- Shared world materials ------------------------------------------------------------

## A crafted surface: the atelier's `layer` (ProceduralTextureAtelier.Set) over
## `tint`, projected from three sides; `fade` dithers it out of a camera's
## sightline above 3.2 m; `moss` greens (or with a heather tint, purples) its
## upward faces; `object_space` keeps the pattern on a part that moves.
static func craft(layer: int, tint: Color, fade: bool = false, moss: float = 0.0, object_space: bool = false,
		moss_color: Color = MOSS_TOP) -> ShaderMaterial:
	var key: String = "craft:%d:%s:%s:%.2f:%s:%s" % [layer, tint.to_html(), fade, moss, object_space, moss_color.to_html()]
	if _materials.has(key):
		return _materials[key] as ShaderMaterial
	var made: ShaderMaterial = ShaderMaterial.new()
	made.shader = TRIPLANAR_SHADER
	made.set_shader_parameter(&"albedo", tint)
	made.set_shader_parameter(&"craft_layer", float(layer))
	made.set_shader_parameter(&"triplanar_scale", 1.0 / ProceduralTextureAtelier.TILE_METRES[clampi(layer, 0, 7)] if layer >= 0 else 0.5)
	made.set_shader_parameter(&"normal_strength", 0.55 if layer != Craft.LIME_PLASTER else 0.3)
	made.set_shader_parameter(&"sightline_fade", fade)
	made.set_shader_parameter(&"moss_amount", moss)
	made.set_shader_parameter(&"moss_color", moss_color)
	made.set_shader_parameter(&"use_object_space", object_space)
	made.set_shader_parameter(&"shade_color", Color(0.46, 0.38, 0.42))
	_materials[key] = made
	return made


## The same crafted surface darkened by its mesh's baked vertex shade (ShapeKit's
## sculpted megaliths, cornices and foundation skirts, 18 GDD §4.3).
static func shaded(material: Material) -> Material:
	var crafted: ShaderMaterial = material as ShaderMaterial
	if crafted == null or (crafted.shader != TRIPLANAR_SHADER and crafted.shader != TRIPLANAR_DOUBLE_SHADER):
		return material
	var key: String = "shaded:%d" % crafted.get_instance_id()
	if not _materials.has(key):
		var copy: ShaderMaterial = crafted.duplicate() as ShaderMaterial
		copy.set_shader_parameter(&"vertex_shade", true)
		_materials[key] = copy
	return _materials[key]


## The same crafted surface seen from both sides (ramps, decks); any other material goes to StorybookMaterial.double_sided().
static func double_sided(material: Material) -> Material:
	var crafted: ShaderMaterial = material as ShaderMaterial
	if crafted == null or crafted.shader != TRIPLANAR_SHADER:
		return StorybookMaterial.double_sided(material)
	var key: String = "double:%d" % crafted.get_instance_id()
	if not _materials.has(key):
		var copy: ShaderMaterial = crafted.duplicate() as ShaderMaterial
		copy.shader = TRIPLANAR_DOUBLE_SHADER
		_materials[key] = copy
	return _materials[key]


## A plain painted surface in the world shader (no texture): trims, glass, cloth and the like.
static func painted(tint: Color, fade: bool = false) -> ShaderMaterial:
	return craft(-1, tint, fade)


## A glowing surface (window glass, Sign inlays, embers): `tint` lit from within at `energy`.
static func glowing(tint: Color, energy: float) -> ShaderMaterial:
	var key: String = "glow:%s:%.2f" % [tint.to_html(), energy]
	if _materials.has(key):
		return _materials[key] as ShaderMaterial
	var made: ShaderMaterial = craft(-1, tint).duplicate() as ShaderMaterial
	made.set_shader_parameter(&"glow", Color(tint.r * energy, tint.g * energy, tint.b * energy))
	made.set_shader_parameter(&"rim_strength", 0.0)
	_materials[key] = made
	return made


## The material the builders reach for by colour: which craft a palette colour
## is (warm limestone, brick, lime-wash, timber, slate or clay shingle, granite,
## loam, turf), judged from its hue and value.
static func craft_for_color(tint: Color, fade: bool = false) -> ShaderMaterial:
	return craft(guess_craft(tint), tint, fade, 0.25 if guess_craft(tint) in [Craft.COBBLED_FLAGSTONE, Craft.CRAG_GRANITE] else 0.0)


static func guess_craft(tint: Color) -> int:
	var hue: float = tint.h * 360.0
	var sat: float = tint.s
	var value: float = tint.v
	if sat < 0.12:
		return Craft.LIME_PLASTER if value > 0.86 else Craft.CRAG_GRANITE
	if hue >= 60.0 and hue < 170.0:
		return Craft.MEADOW_TURF if value > 0.3 else Craft.HOLLOW_LOAM
	if hue >= 170.0 and hue < 300.0:
		return Craft.CRAG_GRANITE
	if (hue < 20.0 or hue >= 300.0) and sat > 0.45 and value > 0.45:
		return Craft.STEPPED_BRICK
	if value > 0.82:
		return Craft.LIME_PLASTER
	if sat < 0.32:
		return Craft.COBBLED_FLAGSTONE
	return Craft.HOLLOW_LOAM if sat < 0.47 else Craft.HEWN_TIMBER


## The landscape (Mode B's vertex-coloured landblocks).
static func terrain() -> ShaderMaterial:
	var key: String = "terrain"
	if not _materials.has(key):
		var made: ShaderMaterial = ShaderMaterial.new()
		made.shader = TERRAIN_SHADER
		made.set_shader_parameter(&"shade_color", Color(0.48, 0.42, 0.46))
		_materials[key] = made
	return _materials[key] as ShaderMaterial


## Leaves, grass, ferns and flowers: vertex colours times `tint`, swaying from
## the mesh's root over `sway_height` metres; `brush` leans it from heroes;
## `fade` dithers upper crowns out of sightlines; past `fade_out` metres from
## the camera (0: never) it shrinks away.
static func foliage(tint: Color = Color.WHITE, sway_height: float = 6.0, flex: float = 0.2, brush: float = 0.0,
		fade: bool = false, fade_out: float = 0.0) -> ShaderMaterial:
	var key: String = "foliage:%s:%.2f:%.2f:%.2f:%s:%.0f" % [tint.to_html(), sway_height, flex, brush, fade, fade_out]
	if _materials.has(key):
		return _materials[key] as ShaderMaterial
	var made: ShaderMaterial = ShaderMaterial.new()
	made.shader = FOLIAGE_SHADER
	made.set_shader_parameter(&"albedo", tint)
	made.set_shader_parameter(&"sway_height", sway_height)
	made.set_shader_parameter(&"flex", flex)
	made.set_shader_parameter(&"brush", brush)
	made.set_shader_parameter(&"sightline_fade", fade)
	made.set_shader_parameter(&"fade_out_distance", fade_out)
	made.set_shader_parameter(&"shade_color", Color(0.4, 0.42, 0.4))
	_materials[key] = made
	return made


## A tree's crown: foliage lit in the three-band leaf ramp with the sun's
## backlight through it (18 GDD §4.1), otherwise as foliage().
static func canopy(tint: Color = Color.WHITE, sway_height: float = 6.0, flex: float = 0.2, fade: bool = false,
		fade_out: float = 0.0) -> ShaderMaterial:
	var key: String = "canopy:%s:%.2f:%.2f:%s:%.0f" % [tint.to_html(), sway_height, flex, fade, fade_out]
	if not _materials.has(key):
		var made: ShaderMaterial = foliage(tint, sway_height, flex, 0.0, fade, fade_out).duplicate() as ShaderMaterial
		made.set_shader_parameter(&"leaf_ramp", LEAF_RAMP_SHARE)
		made.set_shader_parameter(&"backlight", 1.0)
		_materials[key] = made
	return _materials[key] as ShaderMaterial


## Lush grass tufts (18 GDD §4.2): roots in the ground's colour (the instance's),
## tips ripening to `tip`, bending up to 28 degrees in the rolling wind-waves with
## a 14% gust sheen, parting from heroes within 1.2 m and shrinking away by `fade_out`.
static func grass_blades(tip: Color = GRASS_TIP, fade_out: float = 95.0) -> ShaderMaterial:
	var key: String = "grass:%s:%.0f" % [tip.to_html(), fade_out]
	if not _materials.has(key):
		var made: ShaderMaterial = foliage(Color.WHITE, 0.5, 0.9, 1.0, false, fade_out).duplicate() as ShaderMaterial
		made.set_shader_parameter(&"grass_blades", true)
		made.set_shader_parameter(&"tip_color", tip)
		made.set_shader_parameter(&"wave_bend_degrees", GRASS_WAVE_BEND_DEG)
		made.set_shader_parameter(&"gust_sheen", GRASS_GUST_SHEEN)
		made.set_shader_parameter(&"backlight", 0.5)
		made.set_shader_parameter(&"dapple", 0.08)
		_materials[key] = made
	return _materials[key] as ShaderMaterial


## Water: &"canal" (a lively flow with foam, over a real bed), &"flat" (painted over a
## solid floor: a village canal, a fountain), &"pool" (still and deep), &"shrine"
## (clear and sparkling, on a basin's top) or &"falls" (a white curtain).
static func water(kind: StringName = &"canal", flow: Vector2 = Vector2(0.0, 0.5)) -> ShaderMaterial:
	var key: String = "water:%s:%.2f:%.2f" % [kind, flow.x, flow.y]
	if _materials.has(key):
		return _materials[key] as ShaderMaterial
	var made: ShaderMaterial = ShaderMaterial.new()
	made.shader = WATER_SHADER
	var shallow: Color = WATER_SHALLOW
	shallow.a = 0.72
	var deep: Color = WATER_DEEP
	deep.a = 0.9
	made.set_shader_parameter(&"shallow_color", shallow)
	made.set_shader_parameter(&"deep_color", deep)
	made.set_shader_parameter(&"flow", flow)
	match kind:
		&"pool":
			made.set_shader_parameter(&"foam_amount", 0.08)
			made.set_shader_parameter(&"depth_fade", 2.2)
			made.set_shader_parameter(&"ripple_scale", 0.6)
		&"shrine":
			made.set_shader_parameter(&"foam_amount", 0.15)
			made.set_shader_parameter(&"fixed_depth", 0.25)
			made.set_shader_parameter(&"ripple_scale", 2.2)
		&"flat":
			made.set_shader_parameter(&"foam_amount", 0.28)
			made.set_shader_parameter(&"fixed_depth", 0.55)
		&"falls":
			made.set_shader_parameter(&"waterfall", true)
			made.set_shader_parameter(&"foam_amount", 0.6)
		_:
			made.set_shader_parameter(&"foam_amount", 0.32)
	_materials[key] = made
	return made


# --- Registration ----------------------------------------------------------------------

static func _ensure() -> void:
	if not _biomes.is_empty():
		return
	_build_biomes()
	_build_kits()
	_build_succession()
	_build_map_zones()


static func _build_biomes() -> void:
	# White meadow daisies, golden buttercups and white clover (18 §4.2: no bright magenta blobs).
	var meadow_flowers: Array[Color] = [Color(0.97, 0.96, 0.9), Color(0.98, 0.82, 0.26), Color(0.93, 0.9, 0.84)]
	var hollow_flowers: Array[Color] = [Color(0.98, 0.85, 0.5), Color(0.55, 0.72, 0.4), Color(0.62, 0.66, 0.9)]
	var heather: Array[Color] = [Color(0.62, 0.42, 0.66), Color(0.74, 0.56, 0.78), Color(0.95, 0.92, 0.84)]
	# The six atlas zones.
	_biome(TIZZI_WED_GREEN, "Tizzi-Wed-Green", Sign.SIGN_WARM_HEARTH, TURF, FLAGSTONE, LOAM, GRANITE,
		Color(1.0, 0.95, 0.86), 1.15, SKY_TOP, SKY_HORIZON, Color(0.9, 0.9, 0.8), 0.0014,
		Vector3i(900, 220, 100), [KIT_TREE_MOSS_OAK, KIT_TREE_ORCHARD_APPLE], meadow_flowers, Color(0.42, 0.6, 0.32))
	_biome(GULL_WICK_HAVEN, "Gull-Wick-Haven", Sign.SIGN_RIME_GALE, Color(0.42, 0.56, 0.38), Color(0.8, 0.78, 0.71), Color(0.5, 0.44, 0.36), GRANITE,
		Color(0.96, 0.97, 0.98), 1.2, Color(0.3, 0.56, 0.8), Color(0.9, 0.93, 0.9), Color(0.82, 0.88, 0.92), 0.0026,
		Vector3i(700, 180, 140), [KIT_TREE_HIGHLAND_PINE], [Color(0.93, 0.62, 0.72), Color(0.97, 0.96, 0.92), Color(0.98, 0.86, 0.4)], Color(0.45, 0.6, 0.4))
	_biome(BARLEY_BRIDGE_MEADOW, "Barley-Bridge-Meadow", Sign.SIGN_IRON_ROOT, Color(0.52, 0.58, 0.3), Color(0.78, 0.7, 0.55), Color(0.58, 0.42, 0.26), GRANITE,
		Color(1.0, 0.92, 0.76), 1.22, Color(0.32, 0.5, 0.74), Color(0.97, 0.88, 0.7), Color(0.92, 0.86, 0.7), 0.0016,
		Vector3i(1000, 260, 90), [KIT_TREE_ORCHARD_APPLE], [Color(0.4, 0.55, 0.92), Color(0.98, 0.84, 0.3), Color(0.96, 0.95, 0.88)], Color(0.56, 0.62, 0.32))
	_biome(RUSH_LIGHT_HOLLOW, "Rush-Light-Hollow", Sign.SIGN_WARM_HEARTH, MOSS, Color(0.6, 0.55, 0.46), LOAM, Color(0.42, 0.45, 0.46),
		Color(0.82, 0.88, 0.9), 0.78, Color(0.2, 0.32, 0.4), Color(0.52, 0.6, 0.58), Color(0.44, 0.55, 0.5), 0.011,
		Vector3i(800, 280, 150), [KIT_TREE_WEEPING_WILLOW, KIT_TREE_MOSS_OAK], hollow_flowers, Color(0.32, 0.5, 0.3))
	_biome(BARROW_CRAG_CROSSING, "Barrow-Crag-Crossing", Sign.SIGN_STAR_TIDE, Color(0.45, 0.5, 0.36), Color(0.7, 0.68, 0.62), Color(0.42, 0.36, 0.3), GRANITE,
		Color(0.98, 0.97, 0.94), 1.2, Color(0.3, 0.5, 0.72), Color(0.86, 0.88, 0.86), Color(0.8, 0.84, 0.86), 0.002,
		Vector3i(600, 240, 150), [KIT_TREE_HIGHLAND_PINE], heather, Color(0.46, 0.54, 0.36))
	_biome(SUNKEN_CROWN_FALLS, "Sunken-Crown-Falls", Sign.SIGN_IRON_ROOT, Color(0.4, 0.54, 0.4), Color(0.76, 0.74, 0.68), LOAM, GRANITE,
		Color(0.94, 0.94, 0.98), 1.05, Color(0.28, 0.44, 0.66), Color(0.86, 0.84, 0.9), Color(0.78, 0.84, 0.86), 0.006,
		Vector3i(800, 200, 130), [KIT_TREE_HIGHLAND_PINE, KIT_TREE_MOSS_OAK], [Color(0.55, 0.4, 0.82), Color(0.96, 0.95, 0.9), Color(0.6, 0.78, 0.92)], Color(0.4, 0.58, 0.38))
	# Oakshire Vale: the village and its five petals.
	_biome(OAKSHIRE_WICK, "Oakshire-Wick", Sign.SIGN_WARM_HEARTH, TURF, FLAGSTONE, LOAM, GRANITE,
		Color(1.0, 0.95, 0.86), 1.15, SKY_TOP, SKY_HORIZON, Color(0.9, 0.89, 0.78), 0.0012,
		Vector3i(1000, 240, 110), [KIT_TREE_MOSS_OAK, KIT_TREE_ORCHARD_APPLE], meadow_flowers, Color(0.42, 0.6, 0.32))
	_biome(WAYFARER_GREEN, "Wayfarer-Green", Sign.SIGN_RIME_GALE, Color(0.4, 0.58, 0.33), Color(0.8, 0.78, 0.7), LOAM, GRANITE,
		Color(1.0, 0.97, 0.9), 1.18, Color(0.3, 0.54, 0.78), Color(0.94, 0.92, 0.84), Color(0.86, 0.9, 0.86), 0.0014,
		Vector3i(1100, 220, 90), [KIT_TREE_ORCHARD_APPLE], [Color(0.98, 0.98, 0.95), Color(0.98, 0.86, 0.36), Color(0.94, 0.7, 0.78)], Color(0.44, 0.62, 0.36))
	_biome(PIPPIN_GREEN, "Pippin-Green", Sign.SIGN_IRON_ROOT, Color(0.5, 0.58, 0.3), FLAGSTONE, Color(0.6, 0.44, 0.26), GRANITE,
		Color(1.0, 0.93, 0.78), 1.2, Color(0.32, 0.52, 0.76), Color(0.97, 0.88, 0.72), Color(0.92, 0.88, 0.74), 0.0015,
		Vector3i(1000, 260, 90), [KIT_TREE_ORCHARD_APPLE], [Color(0.98, 0.84, 0.3), Color(0.4, 0.55, 0.92), Color(0.96, 0.95, 0.88)], Color(0.54, 0.62, 0.32))
	_biome(QUARRY_WICK, "Quarry-Wick", Sign.SIGN_IRON_ROOT, Color(0.46, 0.52, 0.36), Color(0.68, 0.56, 0.42), Color(0.5, 0.42, 0.33), GRANITE,
		Color(0.98, 0.96, 0.9), 1.18, Color(0.3, 0.5, 0.74), Color(0.9, 0.88, 0.82), Color(0.84, 0.84, 0.8), 0.0018,
		Vector3i(500, 120, 150), [KIT_TREE_HIGHLAND_PINE], [Color(0.86, 0.84, 0.46), Color(0.62, 0.42, 0.66), Color(0.95, 0.92, 0.84)], Color(0.48, 0.56, 0.36))
	_biome(BRAMBLE_HOLLOW, "Bramble-Hollow", Sign.SIGN_WARM_HEARTH, MOSS, Color(0.6, 0.55, 0.46), LOAM, Color(0.42, 0.45, 0.46),
		Color(0.9, 0.92, 0.88), 0.92, Color(0.26, 0.42, 0.52), Color(0.72, 0.76, 0.68), Color(0.6, 0.68, 0.6), 0.006,
		Vector3i(800, 280, 150), [KIT_TREE_WEEPING_WILLOW, KIT_TREE_MOSS_OAK], hollow_flowers, Color(0.34, 0.52, 0.3))
	_biome(NINE_STONES_CROSSING, "Nine-Stones-Crossing", Sign.SIGN_STAR_TIDE, Color(0.45, 0.5, 0.38), Color(0.74, 0.72, 0.66), Color(0.42, 0.36, 0.3), GRANITE,
		Color(0.96, 0.94, 0.98), 1.12, Color(0.3, 0.46, 0.72), Color(0.88, 0.84, 0.9), Color(0.8, 0.8, 0.88), 0.0026,
		Vector3i(600, 260, 130), [KIT_TREE_HIGHLAND_PINE], [Color(0.55, 0.4, 0.78), Color(0.62, 0.42, 0.66), Color(0.95, 0.92, 0.84)], Color(0.46, 0.54, 0.38))
	# The Bramble-Bridge trail.
	_biome(HONEY_WICK, "Honey-Wick", Sign.SIGN_WARM_HEARTH, TURF, FLAGSTONE, LOAM, GRANITE,
		Color(1.0, 0.92, 0.78), 1.18, SKY_TOP, Color(0.98, 0.88, 0.72), Color(0.94, 0.88, 0.74), 0.0013,
		Vector3i(1000, 260, 110), [KIT_TREE_MOSS_OAK, KIT_TREE_ORCHARD_APPLE], [Color(0.98, 0.84, 0.3), Color(0.96, 0.95, 0.88), Color(0.95, 0.66, 0.4)], Color(0.44, 0.6, 0.32))
	_biome(BRAMBLE_BRIDGE, "Bramble-Bridge", Sign.SIGN_WARM_HEARTH, TURF, FLAGSTONE, LOAM, GRANITE,
		Color(1.0, 0.95, 0.86), 1.15, SKY_TOP, SKY_HORIZON, Color(0.9, 0.9, 0.8), 0.0013,
		Vector3i(900, 220, 100), [KIT_TREE_MOSS_OAK, KIT_TREE_ORCHARD_APPLE], meadow_flowers, Color(0.42, 0.6, 0.32))
	_biome(MOSS_OAK_HOLLOW, "Moss-Oak-Hollow", Sign.SIGN_IRON_ROOT, MOSS, Color(0.66, 0.62, 0.52), LOAM, Color(0.46, 0.48, 0.47),
		Color(0.96, 0.95, 0.84), 0.98, Color(0.3, 0.5, 0.62), Color(0.84, 0.86, 0.74), Color(0.68, 0.78, 0.64), 0.005,
		Vector3i(900, 300, 140), [KIT_TREE_MOSS_OAK], [Color(0.55, 0.6, 0.92), Color(0.96, 0.95, 0.9), Color(0.5, 0.7, 0.38)], Color(0.36, 0.54, 0.3))
	_biome(DOVER_SLAP_FALLS, "Dover-Slap-Falls", Sign.SIGN_RIME_GALE, Color(0.42, 0.52, 0.38), Color(0.72, 0.7, 0.64), Color(0.44, 0.38, 0.32), GRANITE,
		Color(0.96, 0.97, 1.0), 1.15, Color(0.28, 0.5, 0.76), Color(0.88, 0.9, 0.9), Color(0.84, 0.9, 0.94), 0.0035,
		Vector3i(600, 200, 160), [KIT_TREE_HIGHLAND_PINE], heather, Color(0.42, 0.56, 0.38))
	_biome(RING_OF_THE_CAIRNSMAN, "The Ring of the Cairnsman", Sign.SIGN_STAR_TIDE, Color(0.44, 0.5, 0.38), ARENA_FLOOR, Color(0.42, 0.36, 0.3), GRANITE,
		Color(0.98, 0.96, 0.94), 1.18, Color(0.3, 0.48, 0.74), Color(0.9, 0.86, 0.86), Color(0.82, 0.84, 0.88), 0.0025,
		Vector3i(300, 160, 80), [KIT_TREE_HIGHLAND_PINE], heather, Color(0.44, 0.54, 0.36))


static func _biome(id: StringName, label: String, sign: int, turf: Color, road: Color, hollow: Color, crag: Color,
		sun: Color, sun_energy: float, sky_top: Color, sky_horizon: Color, fog: Color, fog_density: float,
		clutter: Vector3i, trees: Array[StringName], flowers: Array[Color], grass: Color) -> void:
	var override: ZoneBiomeResource = _load_override(id) as ZoneBiomeResource
	if override != null:
		_biomes[id] = override
		_biome_order.append(id)
		return
	var made: ZoneBiomeResource = ZoneBiomeResource.new()
	made.biome_id = id
	made.display_name = label
	var zone: StringName = id if MythopoeticAtlas.zone(id) != null else MythopoeticAtlas.zone_for_place(label)
	var atlas: StewardshipZoneResource = MythopoeticAtlas.zone(zone)
	made.cooper_sign_title = atlas.cooper_sign if atlas != null else ""
	made.primary_scribe_sign = sign
	made.turf_albedo = turf
	made.road_albedo = road
	made.hollow_albedo = hollow
	made.crag_albedo = crag
	made.sun_color = sun
	made.sun_energy = sun_energy
	made.sky_top_color = sky_top
	made.sky_horizon_color = sky_horizon
	made.fog_light_color = fog
	made.fog_density = fog_density
	made.grass_clump_count = clutter.x
	made.wildflower_count = clutter.y
	made.pebble_fungi_count = clutter.z
	var tree_ids: PackedStringArray = PackedStringArray()
	for tree: StringName in trees:
		tree_ids.append(String(tree))
	made.tree_kit_ids = tree_ids
	made.flower_colors = PackedColorArray(flowers)
	made.grass_color = grass
	_biomes[id] = made
	_biome_order.append(id)


static func _build_kits() -> void:
	_kit(KIT_HOUSE_STEPPED_GABLE, "Stepped-Gable House", &"ARCHITECTURE", Vector3(8.0, 9.0, 6.0), false, true)
	_kit(KIT_WATERMILL_WHEEL, "Vellum-Mill Watermill Wheel", &"ARCHITECTURE", Vector3(2.2, 5.0, 5.0), false, true)
	_kit(KIT_BRIDGE_STONE_ARCH, "Bramble-Bridge Stone Arch", &"BRIDGE", Vector3(5.0, 2.4, 12.0), false, false)
	_kit(KIT_BRIDGE_CARPATHIAN_TRESTLE, "Dover-Slap Timber Trestle", &"BRIDGE", Vector3(8.0, 24.0, 30.0), false, false)
	_kit(KIT_SCRIBE_DESK_PAVILION, "Scribe-Desk Pavilion", &"STATION", Vector3(5.0, 3.6, 4.0), false, true)
	_kit(KIT_CHIME_SHRINE_PAGODA, "Chime-Shrine Pagoda", &"STATION", Vector3(3.4, 4.6, 3.4), false, true)
	_kit(KIT_CHIME_POST_DIAGNOSTIC, "Nursery-Rhyme Chime-Post", &"STATION", Vector3(1.6, 2.6, 0.6), false, false)
	_kit(KIT_WATER_SHRINE_OASIS, "Wayfarer's Water-Shrine", &"STATION", Vector3(3.0, 2.4, 3.0), false, false)
	_kit(KIT_HUSH_CRACK_AND_CAIRN, "Hush-Crack and Lulled Cairn", &"LANDSCAPE", Vector3(3.5, 1.4, 3.5), true, false)
	_kit(KIT_TREE_MOSS_OAK, "Moss-Oak", &"TREE", Vector3(9.0, 11.0, 9.0), false, true)
	_kit(KIT_TREE_ORCHARD_APPLE, "Orchard Apple", &"TREE", Vector3(5.0, 5.4, 5.0), false, true)
	_kit(KIT_TREE_WEEPING_WILLOW, "Weeping Willow", &"TREE", Vector3(8.0, 9.0, 8.0), false, true)
	_kit(KIT_TREE_HIGHLAND_PINE, "Highland Pine", &"TREE", Vector3(4.0, 12.0, 4.0), false, true)
	_kit(KIT_DRYSTONE_WALL, "Knee-High Dry-Stone Wall", &"LANDSCAPE", Vector3(4.0, 0.8, 0.7), true, false)
	_kit(KIT_BEE_HIVE, "Cedar Bee-Hive", &"GARDEN", Vector3(0.8, 1.3, 0.8), true, false)
	_kit(KIT_PUMPKIN_PATCH, "Heirloom Pumpkin Patch", &"GARDEN", Vector3(6.0, 0.8, 4.0), true, false)
	_kit(KIT_STANDING_STONE, "Maker-Seal Standing Stone", &"LANDSCAPE", Vector3(1.4, 4.2, 0.9), false, true)
	_kit(KIT_WIND_LANTERN_POST, "Wind-Lantern Post", &"LANDSCAPE", Vector3(0.6, 3.0, 0.6), false, false)
	_kit(KIT_WINDMILL, "Hillside Windmill", &"ARCHITECTURE", Vector3(5.0, 11.0, 5.0), false, true)
	_kit(KIT_QUARRY_CRANE, "Timber Pulley-Crane", &"LANDSCAPE", Vector3(4.0, 6.5, 3.0), false, true)
	_kit(KIT_ASHLAR_STACK, "Iron-Root Ashlar Stack", &"LANDSCAPE", Vector3(3.0, 1.8, 2.0), false, false)
	_kit(KIT_MARKET_PAVILION, "Artisan Market Pavilion", &"ARCHITECTURE", Vector3(3.6, 3.3, 3.0), false, true)
	_kit(KIT_CLIFF_CORNICE, "Crag-Crest Cornice", &"LANDSCAPE", Vector3(6.0, 1.0, 1.8), false, false)
	_kit(KIT_PATH_SLEEPER, "Hewn Log-Sleeper Steps", &"LANDSCAPE", Vector3(2.2, 0.3, 4.0), true, false)
	_kit(KIT_STEPPING_STONE, "Mossy Stepping-Stones", &"LANDSCAPE", Vector3(1.8, 0.25, 4.0), true, false)
	_kit(KIT_GUIDE_POST, "Wayfarer Guide-Post", &"LANDSCAPE", Vector3(0.3, 0.6, 0.3), true, false)


static func _kit(id: StringName, label: String, category: StringName, size: Vector3, low: bool, fade: bool) -> void:
	var override: WorldPropKitResource = _load_override(id) as WorldPropKitResource
	if override != null:
		_kits[id] = override
		_kit_order.append(id)
		return
	var made: WorldPropKitResource = WorldPropKitResource.new()
	made.kit_id = id
	made.display_name = label
	made.category = category
	made.bounding_size = size
	made.is_low_scenery = low
	made.enable_sightline_fade = fade
	made.glb_override_path = "res://assets/models/world/%s.glb" % id
	_kits[id] = made
	_kit_order.append(id)


static func _build_succession() -> void:
	_succession_state(Succession.ZONE_HUSHED, "Hushed", 0.45, 0.35, 0.0, Color(0.62, 0.68, 0.74, 0.7))
	_succession_state(Succession.ZONE_RECLAIMED, "Reclaimed", 0.0, 1.0, 0.0, Color(0.98, 0.84, 0.4, 0.8))
	_succession_state(Succession.ZONE_WEATHERING_EVENT, "Weathering", 0.0, 1.6, 0.6, Color(0.86, 0.9, 0.96, 0.6))


static func _succession_state(state: int, label: String, desaturation: float, warmth: float, weather: float, motes: Color) -> void:
	var file: String = ["succession_hushed", "succession_reclaimed", "succession_weathering"][state]
	var override: ZoneSuccessionVisualResource = _load_override(StringName(file)) as ZoneSuccessionVisualResource
	if override != null:
		_succession[state] = override
		return
	var made: ZoneSuccessionVisualResource = ZoneSuccessionVisualResource.new()
	made.state = state as ZoneSuccessionVisualResource.SuccessionState
	made.display_name = label
	made.hush_desaturation = desaturation
	made.reclamation_bloom_duration_sec = 2.5
	made.lantern_warmth_multiplier = warmth
	made.weathering_frost_or_fog_intensity = weather
	made.mote_color = motes
	_succession[state] = made


# --- The Wayfarer's map (18 GDD §7, §8.1) ----------------------------------------------

## Every map place, per instance, at its world centre. Oakshire Vale's petals
## centre on their camps (OakshireValeLayout.camp_center_2d); the trail's stops
## follow LandblockManifest's zone origins along the corridor at x = 64 (north is -Z).
static func _build_map_zones() -> void:
	const VALE: StringName = &"oakshire_vale"
	const WORLD: StringName = &"everwood_world"
	var petals: PackedStringArray = PackedStringArray(["wayfarer_green", "pippin_green", "quarry_wick", "bramble_hollow", "nine_stones_crossing"])
	_map_zone(OAKSHIRE_WICK, "Oakshire-Wick", VALE, Vector2(768.0, 768.0), 140.0, petals)
	_map_zone(WAYFARER_GREEN, "Wayfarer-Green", VALE, Vector2(736.5, 1218.0), 175.0, PackedStringArray(["oakshire_wick", "pippin_green"]))
	_map_zone(PIPPIN_GREEN, "Pippin-Green", VALE, Vector2(434.9, 378.5), 175.0, PackedStringArray(["oakshire_wick", "bramble_hollow"]))
	_map_zone(QUARRY_WICK, "Quarry-Wick", VALE, Vector2(1184.3, 1012.1), 175.0, PackedStringArray(["oakshire_wick", "wayfarer_green"]))
	_map_zone(BRAMBLE_HOLLOW, "Bramble-Hollow", VALE, Vector2(1040.2, 311.4), 175.0, PackedStringArray(["oakshire_wick", "quarry_wick"]))
	_map_zone(NINE_STONES_CROSSING, "Nine-Stones-Crossing", VALE, Vector2(305.7, 805.1), 175.0, PackedStringArray(["oakshire_wick", "pippin_green"]))
	_map_zone(HONEY_WICK, "Honey-Wick", WORLD, Vector2(64.0, 192.0), 64.0, PackedStringArray(["bramble_bridge"]))
	_map_zone(BRAMBLE_BRIDGE, "Bramble-Bridge", WORLD, Vector2(64.0, 64.0), 64.0, PackedStringArray(["honey_wick", "moss_oak_hollow"]))
	_map_zone(MOSS_OAK_HOLLOW, "Moss-Oak-Hollow", WORLD, Vector2(64.0, -30.0), 40.0, PackedStringArray(["bramble_bridge", "rush_light_hollow"]))
	_map_zone(RUSH_LIGHT_HOLLOW, "Rush-Light-Hollow", WORLD, Vector2(64.0, -92.0), 32.0, PackedStringArray(["moss_oak_hollow", "dover_slap_bridge"]))
	_map_zone(&"dover_slap_bridge", "Dover-Slap-Bridge", WORLD, Vector2(64.0, -168.0), 52.0, PackedStringArray(["rush_light_hollow", "ring_of_the_cairnsman"]))
	_map_zone(RING_OF_THE_CAIRNSMAN, "The Ring of the Cairnsman", WORLD, Vector2(64.0, -262.0), 48.0, PackedStringArray(["dover_slap_bridge"]))
	# The classic instances: the walled hub, and the expedition with its three zones end to end.
	_map_zone(&"hub_bramble_bridge", "Bramble-Bridge", &"hub_town", Vector2(0.0, 0.0), 70.0, PackedStringArray())
	_map_zone(&"expedition_moss_oak_hollow", "Moss-Oak-Hollow", &"dungeon_dojo", Vector2(0.0, 52.0), 40.0,
		PackedStringArray(["expedition_dover_slap_bridge"]))
	_map_zone(&"expedition_dover_slap_bridge", "Dover-Slap-Bridge", &"dungeon_dojo", Vector2(0.0, -5.0), 20.0,
		PackedStringArray(["expedition_moss_oak_hollow", "expedition_ring_of_the_cairnsman"]))
	_map_zone(&"expedition_ring_of_the_cairnsman", "The Ring of the Cairnsman", &"dungeon_dojo", Vector2(0.0, -52.0), 26.0,
		PackedStringArray(["expedition_dover_slap_bridge"]))


static func _map_zone(id: StringName, label: String, instance: StringName, center: Vector2, radius: float, leads_to: PackedStringArray) -> void:
	var override: WorldMapZoneResource = _load_override(StringName("map_%s" % id)) as WorldMapZoneResource
	if override != null:
		_map_zones[id] = override
		_map_zone_order.append(id)
		return
	var made: WorldMapZoneResource = WorldMapZoneResource.new()
	made.zone_id = id
	made.display_name = label
	made.instance_id = instance
	made.world_center_xz = center
	made.world_radius_m = radius
	made.connects_to_zone_ids = leads_to
	var look: ZoneBiomeResource = biome(biome_for_place(label)) if biome_for_place(label) != &"" else _biomes.get(id, null)
	if look == null and label == "Dover-Slap-Bridge":
		look = _biomes.get(DOVER_SLAP_FALLS, null)
	if look != null:
		made.cooper_sign_title = look.cooper_sign_title
		made.primary_scribe_sign = look.primary_scribe_sign
	made.landmark_label_offset = Vector2(0.0, -radius * 0.55)
	_map_zones[id] = made
	_map_zone_order.append(id)


static func _load_override(id: StringName) -> Resource:
	var path: String = "%s%s.tres" % [OVERRIDE_FOLDER, id]
	if not ResourceLoader.exists(path):
		return null
	return load(path)
