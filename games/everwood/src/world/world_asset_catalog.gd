## The world's prop kits, built in code (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §4):
## multi-part architecture, stations, trees and garden pieces in the atelier's
## crafts. Every static part of a kit is merged into one mesh with one surface
## per material (a house is a handful of draw calls, not a hundred), and the
## merged meshes are cached, so twenty oaks of one shape share one mesh.
##
## A curated model wins: res://assets/models/world/<kit_id>_<variant>.glb, then
## <kit_id>.glb, replaces the code-built kit. Scenes don't store the generated
## meshes: they store a WorldKitInstance (kit id and options) that builds here
## when it enters the tree. Actors (ChimeShrine, WaterShrine, ScribeDesk,
## WatermillWheel, ChimePost, HushCrackLandmark) build their static parts here
## and animate their own moving ones.
class_name WorldAssetCatalog
extends RefCounted

const Craft = ProceduralTextureAtelier.Set
const MODEL_FOLDER: String = "res://assets/models/world/"
## Roofs pitch at 42° (§2.1: 38° to 45°).
const ROOF_PITCH_DEG: float = 42.0
const PLINTH_HEIGHT: float = 0.6
const GABLE_STEPS: int = 5
const WINDOW_GLOW: Color = Color("#FFBA66")
const FIELDSTONE: Color = Color(0.68, 0.64, 0.57)
const SHINGLE_SLATE: Color = Color(0.43, 0.49, 0.55)
const SHINGLE_CLAY: Color = Color(0.62, 0.36, 0.27)
const SHINGLE_MOSS: Color = Color(0.4, 0.5, 0.36)
const CEDAR: Color = Color(0.56, 0.36, 0.22)
const BRONZE: Color = Color(0.72, 0.52, 0.26)
const IRON: Color = Color(0.3, 0.3, 0.33)
const BARK: Color = Color(0.36, 0.27, 0.19)
const FLOWER_BOX_COLORS: Array[Color] = [Color(0.95, 0.42, 0.45), Color(0.98, 0.85, 0.35), Color(0.62, 0.48, 0.9), Color(0.98, 0.97, 0.92)]
## A tree's leaves at the bottom of the crown and at its sunlit top, per kind.
const LEAF_COLORS: Dictionary[StringName, Array] = {
	&"kit_tree_moss_oak": [Color(0.2, 0.36, 0.2), Color(0.45, 0.62, 0.3)],
	&"kit_tree_orchard_apple": [Color(0.26, 0.44, 0.22), Color(0.52, 0.68, 0.34)],
	&"kit_tree_weeping_willow": [Color(0.32, 0.46, 0.24), Color(0.62, 0.72, 0.38)],
	&"kit_tree_highland_pine": [Color(0.13, 0.26, 0.18), Color(0.3, 0.44, 0.28)],
}

static var _meshes: Dictionary[String, ArrayMesh] = {}
static var _primitive_arrays: Dictionary[String, Array] = {}


## A kit, by id. Options (all optional): "variant" (StringName), "size"
## (Vector3), "color" and "accent" (Color), "height" (float), "seed" (int),
## "blossom" (bool), "fade" (bool: dither tall parts out of sightlines, on by default for tall kits).
static func build(kit_id: StringName, options: Dictionary = {}) -> Node3D:
	var variant: StringName = options.get("variant", &"")
	var curated: Node3D = load_model(kit_id, variant)
	if curated != null:
		return curated
	var root: Node3D = Node3D.new()
	root.name = "Kit" + String(kit_id).trim_prefix("kit_").to_pascal_case()
	var key: String = "%s:%s" % [kit_id, JSON.stringify(_plain(options))]
	var mesh: ArrayMesh = _meshes.get(key, null)
	if mesh == null:
		var parts: Parts = Parts.new()
		_build_parts(kit_id, options, parts)
		mesh = parts.commit()
		_meshes[key] = mesh
	if mesh.get_surface_count() > 0:
		var shape: MeshInstance3D = MeshInstance3D.new()
		shape.name = "Static"
		shape.mesh = mesh
		root.add_child(shape)
	_add_live_parts(kit_id, options, root)
	return root


## A curated model for the kit (its variant's first), or null.
static func load_model(kit_id: StringName, variant: StringName = &"") -> Node3D:
	var paths: Array[String] = []
	if variant != &"":
		paths.append("%s%s_%s.glb" % [MODEL_FOLDER, kit_id, String(variant).to_lower()])
	paths.append("%s%s.glb" % [MODEL_FOLDER, kit_id])
	for path: String in paths:
		if ResourceLoader.exists(path):
			var scene: PackedScene = load(path) as PackedScene
			if scene != null:
				var art: Node3D = scene.instantiate() as Node3D
				if art != null:
					art.name = "Kit" + String(kit_id).trim_prefix("kit_").to_pascal_case()
					return art
	return null


## Builds the shared meshes of the kits a level shows up front (so streaming never builds one mid-frame).
static func prewarm(kit_ids: Array[StringName]) -> void:
	for kit_id: StringName in kit_ids:
		if WorldVisualCatalog.TREE_KITS.has(kit_id):
			for variant: int in 3:
				build(kit_id, {"seed": variant}).free()
		else:
			build(kit_id).free()


static func cached_mesh_count() -> int:
	return _meshes.size()


## Whether a kit with these options is quick to build now (its mesh is cached, or it's a curated model).
static func is_cached(kit_id: StringName, options: Dictionary = {}) -> bool:
	if _meshes.has("%s:%s" % [kit_id, JSON.stringify(_plain(options))]):
		return true
	var variant: StringName = options.get("variant", &"")
	return ResourceLoader.exists("%s%s.glb" % [MODEL_FOLDER, kit_id]) or (variant != &"" and ResourceLoader.exists("%s%s_%s.glb" % [MODEL_FOLDER, kit_id, String(variant).to_lower()]))


## A static mesh by key, built once by `maker` (a Callable taking a Parts) and shared.
static func shared_mesh(key: String, maker: Callable) -> ArrayMesh:
	var mesh: ArrayMesh = _meshes.get(key, null)
	if mesh == null:
		var parts: Parts = Parts.new()
		maker.call(parts)
		mesh = parts.commit()
		_meshes[key] = mesh
	return mesh


static func _plain(options: Dictionary) -> Dictionary:
	var plain: Dictionary = {}
	for key: Variant in options:
		var value: Variant = options[key]
		plain[key] = var_to_str(value)
	return plain


static func _build_parts(kit_id: StringName, options: Dictionary, parts: Parts) -> void:
	match kit_id:
		WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE:
			_house(parts, options)
		WorldVisualCatalog.KIT_WATERMILL_WHEEL:
			_mill_race(parts, options)
		WorldVisualCatalog.KIT_BRIDGE_STONE_ARCH:
			_stone_arch(parts, options)
		WorldVisualCatalog.KIT_BRIDGE_CARPATHIAN_TRESTLE:
			_trestle(parts, options)
		WorldVisualCatalog.KIT_SCRIBE_DESK_PAVILION:
			_pavilion(parts, options)
		WorldVisualCatalog.KIT_CHIME_SHRINE_PAGODA:
			_pagoda(parts, options)
		WorldVisualCatalog.KIT_CHIME_POST_DIAGNOSTIC:
			_chime_post(parts, options)
		WorldVisualCatalog.KIT_WATER_SHRINE_OASIS:
			_oasis(parts, options)
		WorldVisualCatalog.KIT_HUSH_CRACK_AND_CAIRN:
			if options.get("variant", &"CRACK") == &"CAIRN":
				_cairn(parts, options)
			else:
				_crack(parts, options)
		WorldVisualCatalog.KIT_TREE_MOSS_OAK, WorldVisualCatalog.KIT_TREE_ORCHARD_APPLE, \
				WorldVisualCatalog.KIT_TREE_WEEPING_WILLOW, WorldVisualCatalog.KIT_TREE_HIGHLAND_PINE:
			tree_parts(parts, kit_id, float(options.get("height", 0.0)), int(options.get("seed", 0)), bool(options.get("blossom", false)),
				bool(options.get("fade", true)))
		WorldVisualCatalog.KIT_DRYSTONE_WALL:
			_drystone(parts, options)
		WorldVisualCatalog.KIT_BEE_HIVE:
			_hive(parts, options)
		WorldVisualCatalog.KIT_PUMPKIN_PATCH:
			_pumpkins(parts, options)
		WorldVisualCatalog.KIT_STANDING_STONE:
			_standing_stone(parts, options)
		WorldVisualCatalog.KIT_WIND_LANTERN_POST:
			_lantern_post(parts, options)
		WorldVisualCatalog.KIT_WINDMILL:
			_windmill(parts, options)
		WorldVisualCatalog.KIT_QUARRY_CRANE:
			_crane(parts, options)
		WorldVisualCatalog.KIT_ASHLAR_STACK:
			_ashlar(parts, options)


## The living bits a merged mesh can't be: lights, smoke and glows.
static func _add_live_parts(kit_id: StringName, options: Dictionary, root: Node3D) -> void:
	match kit_id:
		WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE:
			var size: Vector3 = options.get("size", Vector3(6.0, 3.6, 5.0))
			var variant: StringName = options.get("variant", &"VILLAGE_COTTAGE")
			var glow: OmniLight3D = light("WindowGlow", WINDOW_GLOW, 0.55, 3.6)
			glow.position = Vector3(size.x * 0.5 + 0.9, 1.4, 0.0)
			root.add_child(glow)
			var rise: float = _roof_rise(size)
			root.add_child(smoke("Smoke", Vector3(-size.x * 0.25, size.y + rise + 1.0, -(size.z * 0.5 + 0.3) * 0.35),
				14 if variant == &"SMOKING_BAKERY" else 6))
			if variant == &"SMOKING_BAKERY":
				var coals: OmniLight3D = light("OvenGlow", Color(1.0, 0.55, 0.2), 1.1, 3.0)
				coals.position = Vector3(size.x * 0.5 + 1.4, 0.6, -size.z * 0.25)
				root.add_child(coals)
		WorldVisualCatalog.KIT_WIND_LANTERN_POST:
			var lamp: OmniLight3D = light("Light", WorldVisualCatalog.WARM_HEARTH, 0.8, 4.0)
			lamp.position = Vector3(0.45, 2.3, 0.0)
			root.add_child(lamp)
		WorldVisualCatalog.KIT_WINDMILL:
			# The canvas sails turn on their own node (WorldKitInstance spins "Spinner").
			var sails: MeshInstance3D = MeshInstance3D.new()
			sails.name = "Spinner"
			sails.mesh = windmill_sails_mesh()
			sails.position = Vector3(0.0, 8.2, 1.75)
			root.add_child(sails)


# --- Architecture -----------------------------------------------------------------------

## The Bruges/Visby stepped-gable house (§4.1), its gable end and door facing +X:
## a chamfered fieldstone plinth, a timber-framed lime-washed ground storey,
## a jettied upper storey on corbels, brick stepped gables with limestone
## coping, a 42° scalloped shingle roof with a dormer, mullioned windows with
## flower troughs and a brick chimney. Variants: VILLAGE_COTTAGE,
## SMOKING_BAKERY (a domed bread-oven and peel rack), REED_LIGHT_SCRIBERY
## (vellum banners in the four Sign colours and pigment bundles) and
## OAKSHIRE_HOMESTEAD_HALL (an L-plan wing and a wrap-around porch).
static func _house(parts: Parts, options: Dictionary) -> void:
	var size: Vector3 = options.get("size", Vector3(6.0, 3.6, 5.0))
	var tint: Color = options.get("color", Color(0.78, 0.7, 0.58))
	var roof_tint: Color = options.get("accent", SHINGLE_CLAY)
	var variant: StringName = options.get("variant", &"VILLAGE_COTTAGE")
	var w: float = size.x
	var h: float = size.y
	var d: float = size.z
	var storey: float = PLINTH_HEIGHT + (h - PLINTH_HEIGHT) * 0.55
	var plaster: Material = WorldVisualCatalog.craft(Craft.LIME_PLASTER, WorldVisualCatalog.LIME_WASH.lerp(tint, 0.5))
	var plaster_high: Material = WorldVisualCatalog.craft(Craft.LIME_PLASTER, WorldVisualCatalog.LIME_WASH.lerp(tint, 0.42), true)
	var timber: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, WorldVisualCatalog.TIMBER)
	var timber_high: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, WorldVisualCatalog.TIMBER, true)
	var brick: Material = WorldVisualCatalog.craft(Craft.STEPPED_BRICK, WorldVisualCatalog.BRICK, true)
	var coping: Material = WorldVisualCatalog.craft(Craft.COBBLED_FLAGSTONE, WorldVisualCatalog.FLAGSTONE, true, 0.4)
	var stone: Material = WorldVisualCatalog.craft(Craft.COBBLED_FLAGSTONE, FIELDSTONE, false, 0.35)
	var shingle: Material = WorldVisualCatalog.craft(Craft.SCALLOP_SHINGLE, roof_tint, true, 0.25)
	_house_block(parts, Vector3.ZERO, w, h, d, storey, plaster, plaster_high, timber, timber_high, stone)
	_stepped_gables(parts, Vector3.ZERO, w, h, d, brick, coping)
	_gable_roof(parts, Vector3.ZERO, w, h, d, shingle, timber_high)
	var rise: float = _roof_rise(size)
	# A dormer on the south slope.
	var slope_z: float = (d * 0.5 + 0.3) * 0.42
	parts.box(Vector3(1.0, 0.9, 0.9), Vector3(0.4, h + rise * 0.38, slope_z), plaster_high)
	parts.prism(Vector3(1.0, 0.55, 1.25), Vector3(0.4, h + rise * 0.38 + 0.72, slope_z), shingle, Vector3(0.0, PI * 0.5, 0.0))
	parts.box(Vector3(0.5, 0.45, 0.05), Vector3(0.4, h + rise * 0.38, slope_z + 0.46), _glass())
	# The chimney rises through the north slope, above the ridge.
	var chimney_height: float = rise + 1.2
	parts.box(Vector3(0.62, chimney_height, 0.62), Vector3(-w * 0.25, h + chimney_height * 0.5 + 0.2, -(d * 0.5 + 0.3) * 0.35), brick)
	parts.cylinder(0.14, 0.17, 0.35, Vector3(-w * 0.25, h + chimney_height + 0.37, -(d * 0.5 + 0.3) * 0.35), brick, 8)
	# The door with its stone step and brick header, toward the lane.
	var front: float = w * 0.5 + 0.12
	parts.box(Vector3(0.6, 0.3, 1.5), Vector3(front + 0.3, 0.15, 0.0), stone)
	parts.box(Vector3(0.1, 1.85, 1.1), Vector3(front + 0.02, 0.6 + 0.92, 0.0), WorldVisualCatalog.craft(Craft.HEWN_TIMBER, Color(0.42, 0.27, 0.16)))
	parts.box(Vector3(0.14, 0.22, 1.4), Vector3(front + 0.04, 2.5, 0.0), WorldVisualCatalog.craft(Craft.STEPPED_BRICK, WorldVisualCatalog.BRICK))
	# Mullioned windows with flower troughs, front and sides.
	for z: float in [-d * 0.3, d * 0.3]:
		_window(parts, Vector3(front, 1.4, z), Vector3.ZERO, timber)
	_window(parts, Vector3(front, storey + 0.85, 0.0), Vector3.ZERO, timber_high)
	for side: float in [-1.0, 1.0]:
		for x: float in [-w * 0.25, w * 0.25]:
			_window(parts, Vector3(x, 1.4, side * (d * 0.5 + 0.02)), Vector3(0.0, side * PI * 0.5, 0.0), timber)
			_window(parts, Vector3(x, storey + 0.85, side * (d * 0.5 + 0.27)), Vector3(0.0, side * PI * 0.5, 0.0), timber_high)
	match variant:
		&"SMOKING_BAKERY":
			_bakery_oven(parts, w, d)
		&"REED_LIGHT_SCRIBERY":
			_scribery_banners(parts, w, d, storey)
		&"OAKSHIRE_HOMESTEAD_HALL":
			_homestead_wing(parts, w, h, d, storey, plaster, plaster_high, timber, timber_high, stone, brick, coping, shingle)


static func _roof_rise(size: Vector3) -> float:
	return (size.z * 0.5 + 0.3) * tan(deg_to_rad(ROOF_PITCH_DEG))


## A house's walls: plinth, framed ground storey, jettied upper storey on corbels.
static func _house_block(parts: Parts, at: Vector3, w: float, h: float, d: float, storey: float, plaster: Material, plaster_high: Material,
		timber: Material, timber_high: Material, stone: Material) -> void:
	parts.box(Vector3(w + 0.24, PLINTH_HEIGHT, d + 0.24), at + Vector3(0.0, PLINTH_HEIGHT * 0.5, 0.0), stone)
	parts.box(Vector3(w + 0.1, 0.08, d + 0.1), at + Vector3(0.0, PLINTH_HEIGHT + 0.02, 0.0), stone)
	parts.box(Vector3(w - 0.1, storey - PLINTH_HEIGHT, d - 0.1), at + Vector3(0.0, (storey + PLINTH_HEIGHT) * 0.5, 0.0), plaster)
	parts.box(Vector3(w - 0.1, h - storey, d + 0.5), at + Vector3(0.0, (storey + h) * 0.5, 0.0), plaster_high)
	# Corner posts, the sill beam at the jetty and the top plate.
	for x_side: float in [-1.0, 1.0]:
		for z_side: float in [-1.0, 1.0]:
			parts.box(Vector3(0.22, storey - PLINTH_HEIGHT, 0.22), at + Vector3(x_side * (w * 0.5 - 0.06), (storey + PLINTH_HEIGHT) * 0.5, z_side * (d * 0.5 - 0.06)), timber)
			parts.box(Vector3(0.22, h - storey, 0.22), at + Vector3(x_side * (w * 0.5 - 0.06), (storey + h) * 0.5, z_side * (d * 0.5 + 0.2)), timber_high)
	for z_side: float in [-1.0, 1.0]:
		parts.box(Vector3(w, 0.22, 0.24), at + Vector3(0.0, storey, z_side * (d * 0.5 + 0.14)), timber)
		parts.box(Vector3(w, 0.2, 0.24), at + Vector3(0.0, h, z_side * (d * 0.5 + 0.26)), timber_high)
		# Corbels under the jetty, and diagonal oak braces on both storeys.
		var corbels: int = maxi(3, int(w / 1.3))
		for index: int in corbels:
			var x: float = lerpf(-w * 0.5 + 0.3, w * 0.5 - 0.3, float(index) / (corbels - 1))
			parts.box(Vector3(0.18, 0.3, 0.32), at + Vector3(x, storey - 0.22, z_side * (d * 0.5 + 0.1)), timber)
		for x_side: float in [-1.0, 1.0]:
			var outer: float = x_side * (w * 0.5 - 0.15)
			var inner: float = x_side * (w * 0.5 - 1.25)
			parts.beam(at + Vector3(outer, PLINTH_HEIGHT + 0.1, z_side * (d * 0.5 - 0.02)), at + Vector3(inner, storey - 0.1, z_side * (d * 0.5 - 0.02)), 0.14, timber)
			parts.beam(at + Vector3(inner, storey + 0.1, z_side * (d * 0.5 + 0.24)), at + Vector3(outer, h - 0.1, z_side * (d * 0.5 + 0.24)), 0.14, timber_high)
	for x_side: float in [-1.0, 1.0]:
		parts.box(Vector3(0.24, 0.22, d), at + Vector3(x_side * (w * 0.5 - 0.04), storey, 0.0), timber)


## Brick stepped gables with limestone coping at both ends (±X), climbing over the roof.
static func _stepped_gables(parts: Parts, at: Vector3, w: float, h: float, d: float, brick: Material, coping: Material) -> void:
	var rise: float = _roof_rise(Vector3(w, h, d))
	var step_height: float = rise / GABLE_STEPS
	var span: float = d + 0.6
	for x_side: float in [-1.0, 1.0]:
		var x: float = x_side * (w * 0.5 - 0.17)
		for step: int in GABLE_STEPS:
			var width: float = span * (1.0 - float(step) / GABLE_STEPS)
			var y: float = h + step_height * (step + 0.5)
			parts.box(Vector3(0.34, step_height, width), at + Vector3(x, y, 0.0), brick)
			for z_side: float in [-1.0, 1.0]:
				parts.box(Vector3(0.44, 0.1, 0.34), at + Vector3(x, h + step_height * (step + 1) + 0.05, z_side * (width * 0.5 - 0.17)), coping)
		parts.box(Vector3(0.44, 0.1, span * (1.0 / GABLE_STEPS) + 0.1), at + Vector3(x, h + rise + 0.05, 0.0), coping)
		parts.cylinder(0.0, 0.16, 0.5, at + Vector3(x, h + rise + 0.35, 0.0), coping, 4)


## Two shingled slopes between the gables, and a timber ridge.
static func _gable_roof(parts: Parts, at: Vector3, w: float, h: float, d: float, shingle: Material, ridge: Material) -> void:
	var pitch: float = deg_to_rad(ROOF_PITCH_DEG)
	var run: float = d * 0.5 + 0.3
	var rise: float = run * tan(pitch)
	var slope: float = run / cos(pitch) + 0.12
	for z_side: float in [-1.0, 1.0]:
		parts.box(Vector3(w - 0.6, 0.16, slope), at + Vector3(0.0, h + rise * 0.5 + 0.08, z_side * run * 0.5), shingle, Vector3(z_side * pitch, 0.0, 0.0))
	parts.box(Vector3(w - 0.55, 0.14, 0.32), at + Vector3(0.0, h + rise + 0.1, 0.0), ridge)


## A mullioned window glowing warm, a timber cross and sill, and a trough of flowers below.
static func _window(parts: Parts, at: Vector3, rotation: Vector3, timber: Material) -> void:
	var turn: Basis = Basis.from_euler(rotation)
	parts.box(Vector3(0.06, 0.8, 0.62), at, _glass(), rotation)
	parts.box(Vector3(0.08, 0.84, 0.06), at + turn * Vector3(0.03, 0.0, 0.0), timber, rotation)
	parts.box(Vector3(0.08, 0.06, 0.66), at + turn * Vector3(0.03, 0.0, 0.0), timber, rotation)
	parts.box(Vector3(0.24, 0.2, 0.74), at + turn * Vector3(0.12, -0.52, 0.0), timber, rotation)
	for index: int in 3:
		var bloom: Material = WorldVisualCatalog.painted(FLOWER_BOX_COLORS[(index + int(absf(at.z) * 3.0)) % FLOWER_BOX_COLORS.size()])
		parts.sphere(0.11, at + turn * Vector3(0.14, -0.38, (float(index) - 1.0) * 0.22), bloom, Vector3(1.0, 0.8, 1.0), 6)


static func _glass() -> Material:
	return WorldVisualCatalog.glowing(WINDOW_GLOW, 0.9)


## The Smoking Bakery's domed brick oven against the front, glowing coals, and a peel rack.
static func _bakery_oven(parts: Parts, w: float, d: float) -> void:
	var brick: Material = WorldVisualCatalog.craft(Craft.STEPPED_BRICK, WorldVisualCatalog.BRICK)
	var timber: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, WorldVisualCatalog.TIMBER)
	var at: Vector3 = Vector3(w * 0.5 + 0.75, 0.0, -d * 0.25)
	parts.box(Vector3(1.3, 0.75, 1.6), at + Vector3(0.0, 0.375, 0.0), brick)
	parts.sphere(0.78, at + Vector3(0.0, 0.75, 0.0), brick, Vector3(1.0, 0.75, 1.0), 12)
	parts.box(Vector3(0.08, 0.36, 0.56), at + Vector3(0.62, 0.95, 0.0), WorldVisualCatalog.glowing(Color(1.0, 0.5, 0.15), 2.4))
	var rack: Vector3 = Vector3(w * 0.5 + 0.55, 0.0, d * 0.3)
	for z_side: float in [-0.55, 0.55]:
		parts.box(Vector3(0.1, 1.7, 0.1), rack + Vector3(0.0, 0.85, z_side), timber)
	parts.box(Vector3(0.1, 0.08, 1.3), rack + Vector3(0.0, 1.6, 0.0), timber)
	for index: int in 3:
		var z: float = (float(index) - 1.0) * 0.32
		parts.box(Vector3(0.04, 1.1, 0.06), rack + Vector3(0.08, 1.05, z), timber)
		parts.box(Vector3(0.03, 0.32, 0.24), rack + Vector3(0.08, 0.38, z), timber)


## The Reed-Light Scribery's vellum banners in the four Sign colours, and drying pigment bundles.
static func _scribery_banners(parts: Parts, w: float, d: float, storey: float) -> void:
	var timber: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, WorldVisualCatalog.TIMBER)
	var z: float = d * 0.5 + 0.42
	parts.box(Vector3(w - 0.6, 0.08, 0.08), Vector3(0.0, storey - 0.42, z), timber)
	for index: int in WorldVisualCatalog.SIGN_COLORS.size():
		var x: float = lerpf(-w * 0.32, w * 0.32, float(index) / 3.0)
		var vellum: Material = WorldVisualCatalog.glowing(WorldVisualCatalog.SIGN_COLORS[index], 0.25)
		parts.box(Vector3(0.6, 1.05, 0.04), Vector3(x, storey - 1.0, z), vellum)
		parts.box(Vector3(0.62, 0.06, 0.06), Vector3(x, storey - 1.55, z), timber)
	var pigments: Array[Color] = [Color(0.95, 0.68, 0.15), Color(0.72, 0.2, 0.18), Color(0.2, 0.32, 0.7), Color(0.75, 0.78, 0.25), Color(0.55, 0.3, 0.75)]
	for index: int in pigments.size():
		parts.box(Vector3(0.18, 0.5, 0.18), Vector3(w * 0.5 + 0.2, 1.9 - float(index % 2) * 0.15, lerpf(-d * 0.35, d * 0.35, float(index) / 4.0)),
			WorldVisualCatalog.painted(pigments[index]))


## The Oakshire Homestead Hall's L-plan wing behind, and a porch round the front and south side.
static func _homestead_wing(parts: Parts, w: float, h: float, d: float, storey: float, plaster: Material, plaster_high: Material,
		timber: Material, timber_high: Material, stone: Material, brick: Material, coping: Material, shingle: Material) -> void:
	var wing_w: float = w * 0.6
	var wing_d: float = d * 0.85
	var wing: Vector3 = Vector3(-w * 0.5 - wing_w * 0.5 + 0.4, 0.0, -d * 0.5 + wing_d * 0.5 - 0.6)
	_house_block(parts, wing, wing_w, h * 0.9, wing_d, PLINTH_HEIGHT + (h * 0.9 - PLINTH_HEIGHT) * 0.55, plaster, plaster_high, timber, timber_high, stone)
	_stepped_gables(parts, wing, wing_w, h * 0.9, wing_d, brick, coping)
	_gable_roof(parts, wing, wing_w, h * 0.9, wing_d, shingle, timber_high)
	# The porch: a timber deck, posts and a lean-to roof, along the front and the south side.
	var porch_roof: Material = WorldVisualCatalog.craft(Craft.SCALLOP_SHINGLE, SHINGLE_MOSS, true, 0.3)
	parts.box(Vector3(1.8, 0.22, d + 2.0), Vector3(w * 0.5 + 1.0, 0.11, 0.0), timber)
	parts.box(Vector3(w + 2.0, 0.22, 1.8), Vector3(0.0, 0.11, d * 0.5 + 1.0), timber)
	for index: int in 5:
		var z: float = lerpf(-d * 0.5 - 0.8, d * 0.5 + 1.7, float(index) / 4.0)
		parts.box(Vector3(0.18, storey - 0.2, 0.18), Vector3(w * 0.5 + 1.75, (storey - 0.2) * 0.5 + 0.22, z), timber)
	for index: int in 4:
		var x: float = lerpf(-w * 0.5, w * 0.5 + 1.75, float(index) / 3.0)
		parts.box(Vector3(0.18, storey - 0.2, 0.18), Vector3(x, (storey - 0.2) * 0.5 + 0.22, d * 0.5 + 1.75), timber)
	parts.box(Vector3(2.3, 0.12, d + 2.4), Vector3(w * 0.5 + 1.05, storey + 0.35, 0.0), porch_roof, Vector3(0.0, 0.0, -0.32))
	parts.box(Vector3(w + 2.4, 0.12, 2.3), Vector3(0.0, storey + 0.35, d * 0.5 + 1.05), porch_roof, Vector3(0.32, 0.0, 0.0))


## The mill's piers and mill-race flume (the wheel itself is WatermillWheel's): water pours from the flume onto the wheel.
static func _mill_race(parts: Parts, options: Dictionary) -> void:
	var radius: float = float(options.get("height", 2.2))
	var timber: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, WorldVisualCatalog.TIMBER, false, 0.3)
	var stone: Material = WorldVisualCatalog.craft(Craft.COBBLED_FLAGSTONE, FIELDSTONE, false, 0.4)
	for side: float in [-1.0, 1.0]:
		parts.box(Vector3(0.5, radius + 0.6, 0.6), Vector3(0.0, (radius + 0.6) * 0.5 - radius, side * 0.95), stone)
		parts.box(Vector3(0.3, 0.3, 0.3), Vector3(0.0, 0.05, side * 0.8), timber)
	# The flume: a timber trough on trestles carrying water over the wheel's crown.
	var flume_y: float = radius + 0.35
	parts.box(Vector3(radius * 2.2, 0.12, 1.0), Vector3(-radius * 0.9, flume_y - 0.1, 0.0), timber)
	for side: float in [-1.0, 1.0]:
		parts.box(Vector3(radius * 2.2, 0.4, 0.1), Vector3(-radius * 0.9, flume_y + 0.1, side * 0.5), timber)
	for index: int in 3:
		parts.box(Vector3(0.14, flume_y + radius * 0.4, 0.14), Vector3(-radius * (0.6 + 0.6 * index), (flume_y - radius * 0.4) * 0.5 - 0.2, 0.55), timber)
	parts.box(Vector3(radius * 2.0, 0.06, 0.8), Vector3(-radius * 0.9, flume_y + 0.02, 0.0), WorldVisualCatalog.water(&"flat", Vector2(1.2, 0.0)))
	parts.plane(Vector2(0.8, radius * 0.9), Vector3(radius * 0.15, flume_y - radius * 0.45, 0.0), WorldVisualCatalog.water(&"falls", Vector2(0.0, 1.0)),
		Vector3(0.0, 0.0, PI * 0.5 + 0.35))


## The wheel WatermillWheel turns (§4.1): 12 spokes, 24 angled bucket-paddles, iron rim bands; its axis is local Y.
static func watermill_wheel_mesh(radius: float, thickness: float) -> ArrayMesh:
	return shared_mesh("wheel:%.2f:%.2f" % [radius, thickness], func(parts: Parts) -> void:
		var wood: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, WorldVisualCatalog.TIMBER, false, 0.0, true)
		var iron: Material = WorldVisualCatalog.painted(IRON)
		for side: float in [-1.0, 1.0]:
			parts.torus(radius - 0.14, radius, Vector3(0.0, side * thickness * 0.5, 0.0), wood, 32)
			parts.torus(radius - 0.02, radius + 0.03, Vector3(0.0, side * thickness * 0.5, 0.0), iron, 32)
			parts.torus(radius * 0.22, radius * 0.3, Vector3(0.0, side * thickness * 0.5, 0.0), wood, 16)
		parts.cylinder(0.16, 0.16, thickness + 0.9, Vector3.ZERO, iron, 10)
		for index: int in 12:
			var angle: float = TAU * float(index) / 12.0
			for side: float in [-1.0, 1.0]:
				parts.box(Vector3(radius * 0.72, 0.1, 0.1), Vector3(cos(angle), 0.0, sin(angle)) * radius * 0.6 + Vector3(0.0, side * thickness * 0.5, 0.0),
					wood, Vector3(0.0, -angle, 0.0))
		for index: int in 24:
			var angle: float = TAU * float(index) / 24.0
			parts.box(Vector3(0.42, thickness + 0.04, 0.07), Vector3(cos(angle), 0.0, sin(angle)) * (radius - 0.2), wood, Vector3(0.0, -angle - 0.45, 0.0))
	)


## The Bramble-Bridge stone arch's dressing (§4.1; its walkway collider is the level's):
## radiating limestone voussoirs on both faces, a Maker-Seal keystone, coping
## on the low parapets and Wind-Lantern posts at the corners.
static func _stone_arch(parts: Parts, options: Dictionary) -> void:
	# size: the walkway's width, the arch's radius and the distance from the crown to each foot.
	var size: Vector3 = options.get("size", Vector3(4.0, 1.25, 5.2))
	var width: float = size.x
	var radius: float = size.y
	var foot: float = size.z
	var voussoir: Material = WorldVisualCatalog.craft(Craft.COBBLED_FLAGSTONE, WorldVisualCatalog.FLAGSTONE, false, 0.3)
	var dark: Material = WorldVisualCatalog.painted(Color(0.14, 0.16, 0.18))
	for side: float in [-1.0, 1.0]:
		var x: float = side * (width * 0.5 + 0.03)
		for index: int in 11:
			var angle: float = PI * float(index) / 10.0
			var at: Vector3 = Vector3(x, -0.45 + sin(angle) * (radius + 0.22), cos(angle) * (radius + 0.22))
			parts.box(Vector3(0.12, 0.44, 0.34), at, voussoir, Vector3(-(angle - PI * 0.5), 0.0, 0.0))
		parts.box(Vector3(0.16, 0.5, 0.4), Vector3(x + side * 0.02, -0.45 + radius + 0.3, 0.0), voussoir)
		parts.cylinder(0.14, 0.14, 0.04, Vector3(x + side * 0.1, -0.45 + radius + 0.3, 0.0), WorldVisualCatalog.glowing(WorldVisualCatalog.IRON_ROOT, 1.4), 8,
			Vector3(0.0, 0.0, PI * 0.5))
		parts.box(Vector3(0.05, 0.9, 2.4), Vector3(x - side * 0.01, -0.9, 0.0), dark)
	for side: float in [-1.0, 1.0]:
		for end: float in [-1.0, 1.0]:
			_lantern_post_parts(parts, Vector3(side * (width * 0.5 + 0.35), 0.0, end * (foot + 0.35)), side)


## The Dover-Slap trestle's dressing (§4.1): granite piers down into the chasm
## and criss-cross timber trusses under the deck.
static func _trestle(parts: Parts, options: Dictionary) -> void:
	# size: the deck's width, the chasm's depth below it and the span's length.
	var size: Vector3 = options.get("size", Vector3(6.0, 24.0, 15.0))
	var width: float = size.x
	var depth: float = size.y
	var length: float = size.z
	var granite: Material = WorldVisualCatalog.craft(Craft.CRAG_GRANITE, WorldVisualCatalog.GRANITE, false, 0.5)
	var timber: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, WorldVisualCatalog.TIMBER, false, 0.2)
	var iron: Material = WorldVisualCatalog.painted(IRON)
	for end: float in [-1.0, 1.0]:
		for side: float in [-1.0, 1.0]:
			parts.box(Vector3(1.4, depth, 1.4), Vector3(side * (width * 0.5 - 0.4), -depth * 0.5 - 0.6, end * length * 0.5), granite)
	var bays: int = 3
	for side: float in [-1.0, 1.0]:
		var x: float = side * (width * 0.5 - 0.2)
		for bay: int in bays:
			var top: float = -0.7 - bay * 2.4
			var bottom: float = top - 2.4
			parts.beam(Vector3(x, top, -length * 0.5), Vector3(x, bottom, length * 0.5), 0.22, timber)
			parts.beam(Vector3(x, top, length * 0.5), Vector3(x, bottom, -length * 0.5), 0.22, timber)
			parts.box(Vector3(0.24, 0.24, length), Vector3(x, top, 0.0), timber)
		parts.box(Vector3(0.12, 0.12, length + 0.2), Vector3(x, -0.35, 0.0), iron)
	for index: int in 5:
		parts.box(Vector3(width - 0.2, 0.22, 0.24), Vector3(0.0, -0.75, lerpf(-length * 0.5, length * 0.5, float(index) / 4.0)), timber)


## The Armory & Scribe Desk pavilion (§4.2): an open-sided timber pavilion
## (eaves under 3 m, its roof dither-faded), a Scribe Press with its screw-spindle,
## four glowing inkwells in the Sign colours and a weapon rack.
static func _pavilion(parts: Parts, options: Dictionary) -> void:
	var size: Vector3 = options.get("size", Vector3(4.4, 2.9, 3.4))
	var timber: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, WorldVisualCatalog.TIMBER, false, 0.2)
	var timber_high: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, WorldVisualCatalog.TIMBER, true)
	var shingle: Material = WorldVisualCatalog.craft(Craft.SCALLOP_SHINGLE, SHINGLE_SLATE, true, 0.2)
	var stone: Material = WorldVisualCatalog.craft(Craft.COBBLED_FLAGSTONE, WorldVisualCatalog.FLAGSTONE, false, 0.2)
	parts.box(Vector3(size.x + 0.6, 0.16, size.z + 0.6), Vector3(0.0, 0.08, 0.35), stone)
	for x_side: float in [-1.0, 1.0]:
		for z_side: float in [-1.0, 1.0]:
			parts.box(Vector3(0.22, size.y, 0.22), Vector3(x_side * size.x * 0.5, size.y * 0.5, 0.35 + z_side * size.z * 0.5), timber)
			parts.beam(Vector3(x_side * size.x * 0.5, size.y - 0.7, 0.35 + z_side * size.z * 0.5),
				Vector3(x_side * (size.x * 0.5 - 0.6), size.y - 0.05, 0.35 + z_side * size.z * 0.5), 0.12, timber)
	for z_side: float in [-1.0, 1.0]:
		parts.box(Vector3(size.x + 0.3, 0.2, 0.22), Vector3(0.0, size.y, 0.35 + z_side * size.z * 0.5), timber_high)
	var pitch: float = 0.55
	var run: float = size.z * 0.5 + 0.5
	for z_side: float in [-1.0, 1.0]:
		parts.box(Vector3(size.x + 0.9, 0.12, run / cos(pitch) + 0.1), Vector3(0.0, size.y + run * tan(pitch) * 0.5 + 0.1, 0.35 + z_side * run * 0.5),
			shingle, Vector3(z_side * pitch, 0.0, 0.0))
	parts.box(Vector3(size.x + 0.95, 0.14, 0.28), Vector3(0.0, size.y + run * tan(pitch) + 0.12, 0.35), timber_high)
	# The Scribe Press behind the desk: two uprights, a head beam and the screw-spindle.
	var press: Vector3 = Vector3(size.x * 0.3, 0.0, 0.35 + size.z * 0.32)
	for side: float in [-0.4, 0.4]:
		parts.box(Vector3(0.16, 1.9, 0.16), press + Vector3(side, 0.95, 0.0), timber)
	parts.box(Vector3(1.0, 0.2, 0.3), press + Vector3(0.0, 1.85, 0.0), timber)
	parts.cylinder(0.06, 0.06, 0.9, press + Vector3(0.0, 1.3, 0.0), WorldVisualCatalog.painted(IRON), 8)
	parts.box(Vector3(0.7, 0.1, 0.5), press + Vector3(0.0, 0.85, 0.0), timber)
	parts.box(Vector3(0.9, 0.7, 0.6), press + Vector3(0.0, 0.35, 0.0), timber)
	parts.box(Vector3(0.9, 0.06, 0.06), press + Vector3(0.0, 1.55, 0.0), WorldVisualCatalog.painted(IRON))
	# Four inkwells along the desk's back edge.
	for index: int in 4:
		var ink: Material = WorldVisualCatalog.glowing(WorldVisualCatalog.SIGN_COLORS[index], 1.6)
		parts.cylinder(0.06, 0.08, 0.14, Vector3(-0.75 + index * 0.5, 0.97, 0.75), ink, 8)
	# A weapon rack showing the four martial silhouettes.
	var rack: Vector3 = Vector3(-size.x * 0.42, 0.0, 0.35 + size.z * 0.25)
	parts.box(Vector3(0.12, 1.6, 1.4), rack + Vector3(0.0, 0.8, 0.0), timber)
	var steel: Material = WorldVisualCatalog.painted(Color(0.7, 0.72, 0.76))
	parts.box(Vector3(0.06, 1.3, 0.08), rack + Vector3(0.1, 1.0, -0.5), steel)
	parts.box(Vector3(0.08, 0.9, 0.7), rack + Vector3(0.12, 0.9, -0.05), WorldVisualCatalog.craft(Craft.HEWN_TIMBER, Color(0.5, 0.36, 0.22)))
	parts.cylinder(0.03, 0.03, 1.5, rack + Vector3(0.12, 0.95, 0.35), WorldVisualCatalog.craft(Craft.HEWN_TIMBER, Color(0.5, 0.36, 0.22)), 6)
	parts.torus(0.32, 0.38, rack + Vector3(0.14, 1.2, 0.55), WorldVisualCatalog.craft(Craft.HEWN_TIMBER, Color(0.55, 0.4, 0.24)), 12, Vector3(0.0, 0.0, PI * 0.5))


## The Chime-Shrine pagoda (§4.2): an octagonal stone plinth and a carved cedar
## bell-frame (the five chimes are ChimeShrine's own, so they can swing).
static func _pagoda(parts: Parts, options: Dictionary) -> void:
	var size: Vector3 = options.get("size", Vector3(3.2, 3.4, 2.4))
	var stone: Material = WorldVisualCatalog.craft(Craft.COBBLED_FLAGSTONE, WorldVisualCatalog.FLAGSTONE, false, 0.35)
	var cedar: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, CEDAR, false, 0.2)
	var cedar_high: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, CEDAR, true)
	var shingle: Material = WorldVisualCatalog.craft(Craft.SCALLOP_SHINGLE, SHINGLE_MOSS, true, 0.3)
	parts.cylinder(size.x * 0.56, size.x * 0.6, 0.3, Vector3(0.0, 0.15, 0.4), stone, 8)
	parts.cylinder(size.x * 0.5, size.x * 0.52, 0.12, Vector3(0.0, 0.36, 0.4), stone, 8)
	for side: float in [-1.0, 1.0]:
		parts.box(Vector3(0.24, size.y, 0.24), Vector3(side * size.x * 0.46, size.y * 0.5 + 0.3, 0.4), cedar)
		parts.beam(Vector3(side * size.x * 0.46, size.y - 0.5, 0.4), Vector3(side * size.x * 0.26, size.y + 0.25, 0.4), 0.14, cedar_high)
	parts.box(Vector3(size.x + 0.2, 0.26, 0.3), Vector3(0.0, size.y + 0.32, 0.4), cedar_high)
	parts.box(Vector3(size.x * 0.96, 0.12, 0.2), Vector3(0.0, size.y - 0.15, 0.4), cedar)
	# Two tiers of upturned eaves.
	parts.prism(Vector3(size.x + 0.9, 0.7, size.z), Vector3(0.0, size.y + 0.8, 0.4), shingle)
	parts.prism(Vector3(size.x * 0.6, 0.6, size.z * 0.62), Vector3(0.0, size.y + 1.38, 0.4), shingle)
	parts.cylinder(0.0, 0.12, 0.5, Vector3(0.0, size.y + 1.9, 0.4), WorldVisualCatalog.glowing(WorldVisualCatalog.WARM_HEARTH, 0.6), 6)


## A bronze carillon chime (ChimeShrine hangs five, graduated).
static func chime_mesh(length: float) -> ArrayMesh:
	return shared_mesh("chime:%.2f" % length, func(parts: Parts) -> void:
		var bronze: Material = WorldVisualCatalog.craft(-1, BRONZE)
		parts.cylinder(0.006, 0.006, 0.3, Vector3(0.0, -0.15, 0.0), WorldVisualCatalog.painted(IRON), 4)
		parts.cylinder(length * 0.09, length * 0.24, length, Vector3(0.0, -0.3 - length * 0.5, 0.0), bronze, 12)
		parts.sphere(length * 0.07, Vector3(0.0, -0.3 - length * 0.92, 0.0), bronze, Vector3.ONE, 6)
	)


## The Nursery-Rhyme Chime-Post (§4.2): a 2.6 m carved oak way-post with a curved
## cross-arm and four painted Sign vanes (ChimePost hangs its swaying chime-lantern).
static func _chime_post(parts: Parts, _options: Dictionary) -> void:
	var oak: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, WorldVisualCatalog.TIMBER, false, 0.35)
	var stone: Material = WorldVisualCatalog.craft(Craft.COBBLED_FLAGSTONE, FIELDSTONE, false, 0.5)
	parts.cylinder(0.32, 0.4, 0.3, Vector3(0.0, 0.15, 0.0), stone, 8)
	parts.box(Vector3(0.2, 2.6, 0.2), Vector3(0.0, 1.3, 0.0), oak)
	parts.cylinder(0.0, 0.16, 0.3, Vector3(0.0, 2.75, 0.0), oak, 4)
	parts.beam(Vector3(-0.1, 2.25, 0.0), Vector3(0.55, 2.45, 0.0), 0.11, oak)
	parts.beam(Vector3(0.55, 2.45, 0.0), Vector3(0.82, 2.38, 0.0), 0.09, oak)
	for index: int in 4:
		var vane: Material = WorldVisualCatalog.glowing(WorldVisualCatalog.SIGN_COLORS[index], 0.35)
		var y: float = 1.95 - index * 0.32
		var turn: float = -0.5 + index * 0.33
		parts.box(Vector3(0.62, 0.2, 0.04), Vector3(cos(turn) * 0.35, y, sin(turn) * 0.35), vane, Vector3(0.0, -turn, 0.0))


## The chime-lantern hanging from a Chime-Post's arm (ChimePost swings it).
static func chime_lantern_mesh() -> ArrayMesh:
	return shared_mesh("chime_lantern", func(parts: Parts) -> void:
		var bronze: Material = WorldVisualCatalog.craft(-1, BRONZE)
		parts.cylinder(0.01, 0.01, 0.3, Vector3(0.0, -0.15, 0.0), WorldVisualCatalog.painted(IRON), 4)
		parts.cylinder(0.07, 0.15, 0.08, Vector3(0.0, -0.32, 0.0), bronze, 8)
		parts.cylinder(0.11, 0.11, 0.24, Vector3(0.0, -0.48, 0.0), WorldVisualCatalog.glowing(WorldVisualCatalog.WARM_HEARTH, 1.8), 8)
		parts.cylinder(0.15, 0.08, 0.06, Vector3(0.0, -0.63, 0.0), bronze, 8)
		parts.cylinder(0.0, 0.09, 0.22, Vector3(0.0, -0.78, 0.0), bronze, 8)
	)


## The Wayfarer's Water-Shrine oasis (§4.2): a moss-draped stone basin under a
## hipped cedar-shingle roof (under 2.4 m), a carved spout and glowing ferns
## (WaterShrine adds the water it breathes and pours, so it can rest).
static func _oasis(parts: Parts, _options: Dictionary) -> void:
	var stone: Material = WorldVisualCatalog.craft(Craft.COBBLED_FLAGSTONE, Color(0.6, 0.62, 0.56), false, 0.75)
	var cedar: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, CEDAR, false, 0.3)
	var shingle: Material = WorldVisualCatalog.craft(Craft.SCALLOP_SHINGLE, Color(0.38, 0.44, 0.36), false, 0.45)
	var moss: Material = WorldVisualCatalog.craft(Craft.MEADOW_TURF, WorldVisualCatalog.MOSS)
	parts.cylinder(0.95, 1.05, 0.62, Vector3(0.0, 0.31, 0.0), stone, 12)
	parts.torus(0.82, 1.02, Vector3(0.0, 0.6, 0.0), moss, 16)
	for index: int in 5:
		var angle: float = TAU * float(index) / 5.0 + 0.3
		parts.sphere(0.18, Vector3(cos(angle) * 1.0, 0.55, sin(angle) * 1.0), moss, Vector3(1.4, 0.6, 1.0), 6)
	# The carved spout on a stone stele behind the basin.
	parts.box(Vector3(0.5, 1.5, 0.3), Vector3(0.0, 0.75, -1.15), stone)
	parts.cylinder(0.07, 0.1, 0.45, Vector3(0.0, 1.25, -0.88), stone, 8, Vector3(PI * 0.5, 0.0, 0.0))
	for corner: Vector2 in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
		parts.box(Vector3(0.13, 2.0, 0.13), Vector3(corner.x * 1.1, 1.0, corner.y * 1.1), cedar)
	# A hipped roof: four sloping planes meeting at a short ridge.
	parts.box(Vector3(2.8, 0.14, 2.8), Vector3(0.0, 2.02, 0.0), cedar)
	parts.cylinder(0.08, 1.95, 0.4, Vector3(0.0, 2.28, 0.0), shingle, 4, Vector3(0.0, PI * 0.25, 0.0))
	# Blue-green glowing fern clumps round its foot.
	var fern: Material = WorldVisualCatalog.glowing(Color(0.3, 0.75, 0.62), 0.45)
	for index: int in 7:
		var angle: float = TAU * float(index) / 7.0 + 0.2
		var at: Vector3 = Vector3(cos(angle) * 1.5, 0.0, sin(angle) * 1.5)
		for leaf: int in 3:
			var lean: float = angle + (float(leaf) - 1.0) * 0.9
			parts.sphere(0.2, at + Vector3(cos(lean) * 0.16, 0.14 + 0.04 * leaf, sin(lean) * 0.16), fern, Vector3(0.7, 0.4, 1.3), 6)


## A Hush-Crack (§4.2, ZONE_HUSHED): a 3.5 m jagged root-and-earth fissure in the turf.
static func _crack(parts: Parts, _options: Dictionary) -> void:
	var loam: Material = WorldVisualCatalog.craft(Craft.HOLLOW_LOAM, Color(0.3, 0.25, 0.22))
	var dark: Material = WorldVisualCatalog.glowing(Color(0.1, 0.12, 0.16), 0.0)
	var slate: Material = WorldVisualCatalog.glowing(Color(0.55, 0.62, 0.7), 0.35)
	var root: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, BARK)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1717
	var length: float = 3.5
	var segments: int = 7
	for index: int in segments:
		var t: float = float(index) / (segments - 1) - 0.5
		var x: float = t * length
		var z: float = sin(t * 7.0) * 0.28
		var gap: float = 0.32 * (1.0 - absf(t) * 1.5) + 0.06
		parts.box(Vector3(length / segments + 0.12, 0.04, gap), Vector3(x, 0.02, z), dark, Vector3(0.0, rng.randf_range(-0.4, 0.4), 0.0))
		parts.box(Vector3(length / segments, 0.05, gap * 0.35), Vector3(x, 0.03, z), slate, Vector3(0.0, rng.randf_range(-0.3, 0.3), 0.0))
		for side: float in [-1.0, 1.0]:
			parts.box(Vector3(length / segments + 0.2, rng.randf_range(0.18, 0.34), 0.34), Vector3(x, 0.08, z + side * (gap * 0.5 + 0.17)), loam,
				Vector3(rng.randf_range(-0.25, 0.25) * side, rng.randf_range(-0.3, 0.3), side * 0.35))
	for index: int in 4:
		var t: float = rng.randf_range(-0.4, 0.4)
		parts.beam(Vector3(t * length, 0.05, -0.5), Vector3(t * length + rng.randf_range(-0.4, 0.4), 0.32, 0.5), 0.08, root)


## A Lulled Cairn (§4.2, ZONE_RECLAIMED): a mossy, heather-crowned stewardship cairn ringed by golden wildflowers.
static func _cairn(parts: Parts, _options: Dictionary) -> void:
	var granite: Material = WorldVisualCatalog.craft(Craft.CRAG_GRANITE, WorldVisualCatalog.GRANITE, false, 0.7)
	var heather: Material = WorldVisualCatalog.painted(Color(0.62, 0.42, 0.66))
	var gold: Material = WorldVisualCatalog.glowing(Color(0.98, 0.82, 0.3), 0.3)
	var stem: Material = WorldVisualCatalog.painted(Color(0.36, 0.55, 0.28))
	var sizes: Array[float] = [0.7, 0.58, 0.46, 0.34, 0.24]
	var y: float = 0.0
	for index: int in sizes.size():
		var radius: float = sizes[index]
		parts.sphere(radius, Vector3(sin(index * 1.9) * 0.08, y + radius * 0.55, cos(index * 1.9) * 0.08), granite, Vector3(1.0, 0.62, 1.0), 10)
		y += radius * 1.05
	parts.sphere(0.18, Vector3(0.0, y + 0.08, 0.0), heather, Vector3(1.3, 0.6, 1.3), 8)
	for index: int in 14:
		var angle: float = TAU * float(index) / 14.0
		var at: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * (1.2 + 0.25 * float(index % 3))
		parts.box(Vector3(0.03, 0.3, 0.03), at + Vector3(0.0, 0.15, 0.0), stem)
		parts.sphere(0.08, at + Vector3(0.0, 0.32, 0.0), gold, Vector3(1.0, 0.6, 1.0), 6)


# --- Landscape and garden ----------------------------------------------------------------

## A knee-high dry-stone wall (LowScenery, under 0.9 m): stacked, slightly tumbled stones and a coping course.
static func _drystone(parts: Parts, options: Dictionary) -> void:
	var size: Vector3 = options.get("size", Vector3(4.0, 0.8, 0.7))
	var stone: Material = WorldVisualCatalog.craft(Craft.CRAG_GRANITE, options.get("color", FIELDSTONE), false, 0.5)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(options.get("seed", 7))
	var courses: int = maxi(2, int(size.y / 0.28))
	for course: int in courses:
		var x: float = -size.x * 0.5
		while x < size.x * 0.5 - 0.05:
			var length: float = minf(rng.randf_range(0.45, 0.8), size.x * 0.5 - x)
			parts.box(Vector3(length - 0.04, size.y / courses - 0.03, size.z * rng.randf_range(0.85, 1.0)),
				Vector3(x + length * 0.5, (course + 0.5) * size.y / courses, rng.randf_range(-0.04, 0.04)), stone, Vector3(0.0, rng.randf_range(-0.05, 0.05), 0.0))
			x += length
	parts.box(Vector3(size.x, 0.1, size.z * 1.08), Vector3(0.0, size.y + 0.03, 0.0), stone)


## A cedar bee-hive on its stand (two or three boxes and a lid).
static func _hive(parts: Parts, options: Dictionary) -> void:
	var boxes: int = int(options.get("height", 2.0))
	var cedar: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, CEDAR)
	var dark: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, CEDAR.darkened(0.18))
	var lid: Material = WorldVisualCatalog.craft(Craft.SCALLOP_SHINGLE, SHINGLE_MOSS, false, 0.3)
	for leg_x: float in [-0.25, 0.25]:
		parts.box(Vector3(0.08, 0.35, 0.5), Vector3(leg_x, 0.175, 0.0), dark)
	for level: int in boxes:
		parts.box(Vector3(0.56, 0.3, 0.5), Vector3(0.0, 0.5 + level * 0.31, 0.0), cedar if level % 2 == 0 else dark)
	var top: float = 0.35 + boxes * 0.31
	parts.prism(Vector3(0.72, 0.22, 0.64), Vector3(0.0, top + 0.12, 0.0), lid)
	parts.box(Vector3(0.3, 0.04, 0.02), Vector3(0.0, 0.4, 0.26), WorldVisualCatalog.painted(Color(0.12, 0.09, 0.07)))


## Ribbed heirloom pumpkins (Musquée de Provence) on their vines, in a patch `size` across.
static func _pumpkins(parts: Parts, options: Dictionary) -> void:
	var size: Vector3 = options.get("size", Vector3(6.0, 0.8, 4.0))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4242 + int(options.get("seed", 0))
	var soil: Material = WorldVisualCatalog.craft(Craft.HOLLOW_LOAM, Color(0.4, 0.3, 0.22))
	var vine: Material = WorldVisualCatalog.foliage(Color(0.34, 0.52, 0.26), 0.6, 0.15, 1.0)
	var skins: Array[Color] = [Color(0.8, 0.45, 0.2), Color(0.72, 0.4, 0.22), Color(0.85, 0.55, 0.25), Color(0.62, 0.55, 0.38)]
	# Deep enough to sit into rolling ground without floating.
	parts.box(Vector3(size.x, 0.5, size.z), Vector3(0.0, -0.21, 0.0), soil)
	var rows: int = maxi(1, int(size.z / 2.2))
	for row: int in rows:
		var z: float = -size.z * 0.5 + 1.1 + row * 2.2
		parts.box(Vector3(size.x - 1.0, 0.06, 0.12), Vector3(0.0, 0.05, z), vine)
		var x: float = -size.x * 0.5 + 1.0
		while x < size.x * 0.5 - 0.8:
			var radius: float = rng.randf_range(0.28, 0.5)
			var at: Vector3 = Vector3(x, radius * 0.5, z + rng.randf_range(-0.5, 0.5))
			var skin: Material = WorldVisualCatalog.craft(-1, skins[rng.randi() % skins.size()])
			# Ribs: six squashed lobes round the stem.
			for lobe: int in 6:
				var angle: float = TAU * float(lobe) / 6.0
				parts.sphere(radius * 0.55, at + Vector3(cos(angle), 0.0, sin(angle)) * radius * 0.45, skin, Vector3(1.0, 1.1, 1.0), 8)
			parts.cylinder(0.04, 0.06, 0.18, at + Vector3(0.0, radius * 0.6 + 0.06, 0.0), vine, 6)
			parts.sphere(0.3, Vector3(x + rng.randf_range(0.4, 0.7), 0.08, z + rng.randf_range(-0.6, 0.6)), vine, Vector3(1.0, 0.3, 1.0), 6)
			x += rng.randf_range(1.1, 1.7)


## A standing stone carved with a spiral Maker-Seal in the Star-Tide's violet, mossy at its foot.
static func _standing_stone(parts: Parts, options: Dictionary) -> void:
	var size: Vector3 = options.get("size", Vector3(1.4, 4.2, 0.9))
	var granite: Material = WorldVisualCatalog.craft(Craft.CRAG_GRANITE, options.get("color", WorldVisualCatalog.GRANITE), true, 0.6)
	var seal: Material = WorldVisualCatalog.glowing(options.get("accent", WorldVisualCatalog.STAR_TIDE), 1.2)
	parts.box(Vector3(size.x, size.y * 0.7, size.z), Vector3(0.0, size.y * 0.35, 0.0), granite)
	parts.box(Vector3(size.x * 0.82, size.y * 0.32, size.z * 0.9), Vector3(0.04, size.y * 0.84, 0.0), granite, Vector3(0.0, 0.0, 0.06))
	for turn: int in 3:
		parts.torus(0.16 + turn * 0.13, 0.2 + turn * 0.13, Vector3(0.0, size.y * 0.55, size.z * 0.5 + 0.01), seal, 14, Vector3(PI * 0.5, 0.0, 0.0))
	parts.sphere(size.x * 0.7, Vector3(0.0, 0.0, 0.0), WorldVisualCatalog.craft(Craft.MEADOW_TURF, WorldVisualCatalog.MOSS), Vector3(1.0, 0.35, 0.9), 8)


## A Wind-Lantern on its post and bracket (the light is a child of the kit).
static func _lantern_post(parts: Parts, _options: Dictionary) -> void:
	_lantern_post_parts(parts, Vector3.ZERO, 1.0)


## A hillside tower windmill (Wayfarer-Green): a tapering lime-washed tower on a
## fieldstone base and a shingled cap (the sails are a separate, turning part).
static func _windmill(parts: Parts, _options: Dictionary) -> void:
	var plaster: Material = WorldVisualCatalog.craft(Craft.LIME_PLASTER, WorldVisualCatalog.LIME_WASH, true)
	var stone: Material = WorldVisualCatalog.craft(Craft.COBBLED_FLAGSTONE, FIELDSTONE, false, 0.4)
	var timber: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, WorldVisualCatalog.TIMBER, true)
	var shingle: Material = WorldVisualCatalog.craft(Craft.SCALLOP_SHINGLE, SHINGLE_SLATE, true, 0.2)
	parts.cylinder(2.3, 2.5, 1.0, Vector3(0.0, 0.5, 0.0), stone, 10)
	parts.cylinder(1.5, 2.2, 7.0, Vector3(0.0, 4.5, 0.0), plaster, 10)
	parts.cylinder(1.6, 1.6, 0.25, Vector3(0.0, 8.05, 0.0), timber, 10)
	parts.cylinder(0.2, 1.75, 1.6, Vector3(0.0, 9.0, 0.0), shingle, 10)
	parts.cylinder(0.18, 0.18, 1.2, Vector3(0.0, 8.2, 1.2), timber, 8, Vector3(PI * 0.5, 0.0, 0.0))
	parts.box(Vector3(0.9, 1.8, 0.12), Vector3(0.0, 1.9, 2.2), WorldVisualCatalog.craft(Craft.HEWN_TIMBER, Color(0.42, 0.27, 0.16)), Vector3(-0.06, 0.0, 0.0))
	for y: float in [3.6, 5.8]:
		parts.box(Vector3(0.5, 0.6, 0.06), Vector3(0.0, y, 2.05 - (y - 1.0) * 0.08), _glass(), Vector3(-0.08, 0.0, 0.0))


## The windmill's four canvas sails on their lattice stocks (turning about local Z).
static func windmill_sails_mesh() -> ArrayMesh:
	return shared_mesh("windmill_sails", func(parts: Parts) -> void:
		var timber: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, WorldVisualCatalog.TIMBER, true, 0.0, true)
		var canvas: Material = WorldVisualCatalog.craft(Craft.LIME_PLASTER, Color(0.92, 0.88, 0.78), true, 0.0, true)
		parts.cylinder(0.3, 0.3, 0.4, Vector3.ZERO, timber, 8, Vector3(PI * 0.5, 0.0, 0.0))
		for blade: int in 4:
			var angle: float = PI * 0.25 + blade * PI * 0.5
			var out: Vector3 = Vector3(cos(angle), sin(angle), 0.0)
			var across: Vector3 = Vector3(-sin(angle), cos(angle), 0.0)
			parts.beam(Vector3.ZERO, out * 5.2, 0.14, timber)
			parts.box(Vector3(4.0, 1.1, 0.05), out * 3.1 + across * 0.62 + Vector3(0.0, 0.0, 0.08), canvas, Vector3(0.0, 0.0, angle))
	)


## A timber A-frame pulley-crane over the quarry shelves, its hook hanging on a rope.
static func _crane(parts: Parts, _options: Dictionary) -> void:
	var timber: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, WorldVisualCatalog.TIMBER, true, 0.2)
	var rope: Material = WorldVisualCatalog.painted(Color(0.72, 0.62, 0.44))
	var iron: Material = WorldVisualCatalog.painted(IRON)
	for side: float in [-1.0, 1.0]:
		parts.beam(Vector3(-1.6, 0.0, side * 1.2), Vector3(0.0, 5.6, side * 0.25), 0.2, timber)
		parts.beam(Vector3(1.6, 0.0, side * 1.2), Vector3(0.0, 5.6, side * 0.25), 0.2, timber)
		parts.beam(Vector3(-1.0, 1.6, side * 0.9), Vector3(1.0, 1.6, side * 0.9), 0.14, timber)
	parts.box(Vector3(0.3, 0.3, 1.0), Vector3(0.0, 5.7, 0.0), timber)
	parts.beam(Vector3(0.0, 5.7, 0.0), Vector3(2.8, 6.3, 0.0), 0.18, timber)
	parts.cylinder(0.32, 0.32, 0.18, Vector3(2.7, 6.1, 0.0), timber, 10, Vector3(PI * 0.5, 0.0, 0.0))
	parts.cylinder(0.02, 0.02, 3.4, Vector3(2.9, 4.4, 0.0), rope, 4)
	parts.torus(0.08, 0.14, Vector3(2.9, 2.6, 0.0), iron, 8, Vector3(PI * 0.5, 0.0, 0.0))
	parts.cylinder(0.45, 0.5, 0.9, Vector3(-1.2, 0.45, -1.8), timber, 8, Vector3(PI * 0.5, 0.0, 0.0))


## Squared ashlar blocks stacked by the quarry road, carved with the Iron-Root's mark.
static func _ashlar(parts: Parts, options: Dictionary) -> void:
	var granite: Material = WorldVisualCatalog.craft(Craft.CRAG_GRANITE, options.get("color", Color(0.7, 0.68, 0.62)), false, 0.3)
	var mark: Material = WorldVisualCatalog.glowing(WorldVisualCatalog.IRON_ROOT, 1.0)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 333 + int(options.get("seed", 0))
	for row: int in 2:
		for index: int in 3 - row:
			var at: Vector3 = Vector3((index - (2 - row) * 0.5) * 1.0 + rng.randf_range(-0.05, 0.05), 0.42 + row * 0.82, rng.randf_range(-0.08, 0.08))
			parts.box(Vector3(0.96, 0.8, 1.4), at, granite, Vector3(0.0, rng.randf_range(-0.06, 0.06), 0.0))
			parts.box(Vector3(0.3, 0.06, 0.02), at + Vector3(0.0, 0.0, 0.71), mark)
			parts.box(Vector3(0.06, 0.3, 0.02), at + Vector3(0.0, 0.0, 0.71), mark)


static func _lantern_post_parts(parts: Parts, at: Vector3, side: float) -> void:
	var oak: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, WorldVisualCatalog.TIMBER)
	parts.box(Vector3(0.16, 2.7, 0.16), at + Vector3(0.0, 1.35, 0.0), oak)
	parts.beam(at + Vector3(0.0, 2.55, 0.0), at + Vector3(side * 0.5, 2.6, 0.0), 0.08, oak)
	parts.cylinder(0.09, 0.15, 0.28, at + Vector3(side * 0.45, 2.3, 0.0), WorldVisualCatalog.craft(Craft.STEPPED_BRICK, Color(0.72, 0.45, 0.3)), 8)
	parts.cylinder(0.08, 0.08, 0.16, at + Vector3(side * 0.45, 2.3, 0.0), WorldVisualCatalog.glowing(WorldVisualCatalog.WARM_HEARTH, 2.2), 8)


# --- Trees -----------------------------------------------------------------------------

## A hero tree (§4.3): a buttressed root flare, a tapered trunk forking above
## 3.2 m (so the lane below stays clear), and 5 to 9 leaf-cloud clusters whose
## normals point out from the crown's middle (they shade as one soft cloud),
## swaying in the wind and dithering out of a camera's sightline. `height` 0
## picks the kind's usual height.
static func tree_parts(parts: Parts, kind: StringName, height: float, seed_value: int, blossom: bool, fade: bool) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9000 + seed_value * 31 + kind.hash() % 1000
	var bark: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, BARK, false, 0.45)
	var bark_high: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, BARK, fade, 0.3)
	var colors: Array = LEAF_COLORS.get(kind, LEAF_COLORS[WorldVisualCatalog.KIT_TREE_MOSS_OAK])
	var dark: Color = colors[0]
	var light_leaf: Color = colors[1]
	match kind:
		WorldVisualCatalog.KIT_TREE_HIGHLAND_PINE:
			var tall: float = height if height > 0.0 else rng.randf_range(9.0, 12.5)
			_roots(parts, Vector3.ZERO, 0.32, 4, bark, rng)
			parts.cylinder(0.12, 0.34, tall * 0.92, Vector3(0.0, tall * 0.46, 0.0), bark_high, 8)
			var leaves: Material = WorldVisualCatalog.foliage(Color.WHITE, tall, 0.12, 0.0, fade)
			var tiers: int = 4
			for tier: int in tiers:
				var t: float = float(tier) / tiers
				var base: float = lerpf(3.6, tall * 0.8, t)
				var radius: float = lerpf(2.1, 0.8, t) * rng.randf_range(0.9, 1.1)
				parts.foliage_cone(Vector3(0.0, base, 0.0), radius, lerpf(2.6, 1.8, t), dark.lerp(light_leaf, t * 0.6), dark.lerp(light_leaf, 0.5 + t * 0.5), leaves)
		WorldVisualCatalog.KIT_TREE_ORCHARD_APPLE:
			var tall: float = height if height > 0.0 else rng.randf_range(4.6, 5.6)
			parts.cylinder(0.14, 0.22, 2.2, Vector3(0.0, 1.1, 0.0), bark, 8)
			var crown: Vector3 = Vector3(0.0, tall * 0.68, 0.0)
			for fork: int in 3:
				var angle: float = TAU * float(fork) / 3.0 + rng.randf() * 0.5
				parts.beam(Vector3(0.0, 2.0, 0.0), crown + Vector3(cos(angle), -0.3, sin(angle)) * 1.0, 0.12, bark_high)
			var leaves: Material = WorldVisualCatalog.foliage(Color.WHITE, tall, 0.18, 0.0, fade)
			parts.puff_crown(crown, tall * 0.34, 6, dark, light_leaf, leaves, rng, 0.8)
			var dots: Array[Color] = [Color(0.82, 0.18, 0.15), Color(0.9, 0.62, 0.2)]
			if blossom:
				dots = [Color(0.98, 0.96, 0.95), Color(0.97, 0.78, 0.84)]
			for index: int in 16:
				var direction: Vector3 = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.2, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
				parts.foliage_sphere(crown + direction * tall * 0.36, 0.09, dots[index % 2], dots[index % 2], leaves)
		WorldVisualCatalog.KIT_TREE_WEEPING_WILLOW:
			var tall: float = height if height > 0.0 else rng.randf_range(7.5, 9.0)
			_roots(parts, Vector3.ZERO, 0.5, 5, bark, rng)
			parts.cylinder(0.32, 0.5, 4.2, Vector3(0.0, 2.1, 0.0), bark, 10)
			var crown: Vector3 = Vector3(0.0, tall * 0.68, 0.0)
			for fork: int in 3:
				var angle: float = TAU * float(fork) / 3.0 + rng.randf()
				parts.beam(Vector3(0.0, 3.9, 0.0), crown + Vector3(cos(angle), 0.0, sin(angle)) * 1.6, 0.2, bark_high)
			var leaves: Material = WorldVisualCatalog.foliage(Color.WHITE, tall, 0.3, 0.0, fade)
			parts.puff_crown(crown, tall * 0.36, 7, dark, light_leaf, leaves, rng, 0.7)
			# Fronds trailing down round the crown's rim, down to about 3.4 m.
			for index: int in 22:
				var angle: float = TAU * float(index) / 22.0 + rng.randf_range(-0.08, 0.08)
				var reach: float = tall * rng.randf_range(0.3, 0.4)
				var length: float = rng.randf_range(1.0, 1.4)
				var hang: Vector3 = crown + Vector3(cos(angle) * reach, -tall * 0.12 - length, sin(angle) * reach)
				parts.foliage_sphere(hang, 0.2, dark.lerp(light_leaf, 0.2), dark.lerp(light_leaf, 0.55), leaves, Vector3(1.0, length / 0.2, 1.0))
		_:
			var tall: float = height if height > 0.0 else rng.randf_range(8.5, 11.0)
			var girth: float = 0.32 + tall * 0.03
			_roots(parts, Vector3.ZERO, girth, 5, bark, rng)
			var fork_y: float = maxf(3.5, tall * 0.42)
			parts.cylinder(girth * 0.78, girth, fork_y, Vector3(0.0, fork_y * 0.5, 0.0), bark, 10)
			var crown: Vector3 = Vector3(0.0, tall * 0.68, 0.0)
			var limbs: int = 3
			for fork: int in limbs:
				var angle: float = TAU * float(fork) / limbs + rng.randf_range(-0.3, 0.3)
				parts.beam(Vector3(0.0, fork_y - 0.3, 0.0), crown + Vector3(cos(angle), -0.4, sin(angle)) * tall * 0.2, girth * 0.42, bark_high)
			var leaves: Material = WorldVisualCatalog.foliage(Color.WHITE, tall, 0.16, 0.0, fade)
			parts.puff_crown(crown, tall * 0.34, 7 + seed_value % 3, dark, light_leaf, leaves, rng, 0.82)


## Buttress roots flaring from a trunk's foot.
static func _roots(parts: Parts, at: Vector3, girth: float, count: int, bark: Material, rng: RandomNumberGenerator) -> void:
	for index: int in count:
		var angle: float = TAU * float(index) / count + rng.randf_range(-0.25, 0.25)
		var out: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		parts.beam(at + Vector3(0.0, girth * 1.6, 0.0), at + out * girth * 2.4 + Vector3(0.0, -0.05, 0.0), girth * 0.38, bark)


# --- Far stand-ins (the HLOD bakes, §6.1 Ring 2) -------------------------------------------

## A kit's silhouette in a handful of low-poly shapes, for a landblock's HLOD
## proxy: a house's block, gable roofline, stepped gables and chimney; a
## tree's trunk and crown. False (nothing added) for a kit without one.
static func hlod_parts(kit_id: StringName, options: Dictionary, parts: Parts) -> bool:
	match kit_id:
		WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE:
			var size: Vector3 = options.get("size", Vector3(6.0, 3.6, 5.0))
			var tint: Color = options.get("color", Color(0.78, 0.7, 0.58))
			_hlod_house(parts, Vector3.ZERO, size, WorldVisualCatalog.painted(WorldVisualCatalog.LIME_WASH.lerp(tint, 0.5)),
				WorldVisualCatalog.painted(options.get("accent", SHINGLE_CLAY)))
			if options.get("variant", &"") == &"OAKSHIRE_HOMESTEAD_HALL":
				var wing: Vector3 = Vector3(size.x * 0.6, size.y * 0.9, size.z * 0.85)
				_hlod_house(parts, Vector3(-size.x * 0.5 - wing.x * 0.5 + 0.4, 0.0, -size.z * 0.5 + wing.z * 0.5 - 0.6), wing,
					WorldVisualCatalog.painted(WorldVisualCatalog.LIME_WASH.lerp(tint, 0.5)), WorldVisualCatalog.painted(options.get("accent", SHINGLE_CLAY)))
			return true
		WorldVisualCatalog.KIT_TREE_MOSS_OAK, WorldVisualCatalog.KIT_TREE_ORCHARD_APPLE, WorldVisualCatalog.KIT_TREE_WEEPING_WILLOW, \
				WorldVisualCatalog.KIT_TREE_HIGHLAND_PINE:
			var colors: Array = LEAF_COLORS.get(kit_id, LEAF_COLORS[WorldVisualCatalog.KIT_TREE_MOSS_OAK])
			var leaf: Material = WorldVisualCatalog.painted((colors[0] as Color).lerp(colors[1], 0.55))
			var bark: Material = WorldVisualCatalog.painted(BARK)
			var tall: float = float(options.get("height", 0.0))
			if kit_id == WorldVisualCatalog.KIT_TREE_HIGHLAND_PINE:
				tall = tall if tall > 0.0 else 10.5
				parts.cylinder(0.12, 0.34, tall * 0.5, Vector3(0.0, tall * 0.25, 0.0), bark, 5)
				parts.cylinder(0.0, 2.1, tall * 0.75, Vector3(0.0, tall * 0.25 + tall * 0.375, 0.0), leaf, 6)
				return true
			tall = tall if tall > 0.0 else (5.0 if kit_id == WorldVisualCatalog.KIT_TREE_ORCHARD_APPLE else 9.5)
			parts.cylinder(0.25, 0.4, tall * 0.6, Vector3(0.0, tall * 0.3, 0.0), bark, 5)
			parts.sphere(tall * 0.38, Vector3(0.0, tall * 0.68, 0.0), leaf, Vector3(1.15, 0.8, 1.15), 6)
			return true
		WorldVisualCatalog.KIT_STANDING_STONE:
			var size: Vector3 = options.get("size", Vector3(1.4, 4.2, 0.9))
			parts.box(size, Vector3(0.0, size.y * 0.5, 0.0), WorldVisualCatalog.painted(options.get("color", WorldVisualCatalog.GRANITE)))
			return true
		WorldVisualCatalog.KIT_WINDMILL:
			parts.cylinder(1.6, 2.4, 8.0, Vector3(0.0, 4.0, 0.0), WorldVisualCatalog.painted(WorldVisualCatalog.LIME_WASH), 6)
			parts.cylinder(0.2, 1.75, 1.6, Vector3(0.0, 8.8, 0.0), WorldVisualCatalog.painted(SHINGLE_SLATE), 6)
			return true
	return false


static func _hlod_house(parts: Parts, at: Vector3, size: Vector3, walls: Material, roof: Material) -> void:
	var rise: float = _roof_rise(size)
	parts.box(Vector3(size.x, size.y, size.z + 0.3), at + Vector3(0.0, size.y * 0.5, 0.0), walls)
	parts.prism(Vector3(size.z + 0.6, rise, size.x - 0.4), at + Vector3(0.0, size.y + rise * 0.5, 0.0), roof, Vector3(0.0, PI * 0.5, 0.0))
	var brick: Material = WorldVisualCatalog.painted(WorldVisualCatalog.BRICK)
	for side: float in [-1.0, 1.0]:
		parts.prism(Vector3(size.z + 0.6, rise + 0.3, 0.34), at + Vector3(side * (size.x * 0.5 - 0.17), size.y + (rise + 0.3) * 0.5, 0.0), brick, Vector3(0.0, PI * 0.5, 0.0))
	parts.box(Vector3(0.62, rise + 1.2, 0.62), at + Vector3(-size.x * 0.25, size.y + (rise + 1.2) * 0.5 + 0.2, -(size.z * 0.5 + 0.3) * 0.35), brick)


# --- Clutter pieces (MultiMesh instances, scaled per instance) -----------------------------

## A clutter tree's 6 m trunk (centred on its middle) with flared roots.
static func clutter_trunk_mesh() -> ArrayMesh:
	return shared_mesh("clutter_trunk", func(parts: Parts) -> void:
		var bark: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, BARK, false, 0.4)
		parts.cylinder(0.3, 0.45, 6.0, Vector3.ZERO, bark, 8)
		for index: int in 5:
			var angle: float = TAU * float(index) / 5.0 + 0.4
			parts.beam(Vector3(0.0, -2.2, 0.0), Vector3(cos(angle) * 1.1, -3.05, sin(angle) * 1.1), 0.22, bark)
	)


## A clutter tree's crown of leaf-puffs (unit size, centred), shaded grey to white for the instance colour to tint.
static func clutter_crown_mesh() -> ArrayMesh:
	return shared_mesh("clutter_crown", func(parts: Parts) -> void:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 505
		parts.puff_crown(Vector3.ZERO, 1.0, 7, Color(0.6, 0.6, 0.6), Color.WHITE, WorldVisualCatalog.foliage(Color.WHITE, 1.0, 0.25, 0.0, true), rng, 0.85)
	)


## A clutter pine's three tiers of needles (unit height and radius, centred).
static func clutter_pine_mesh() -> ArrayMesh:
	return shared_mesh("clutter_pine", func(parts: Parts) -> void:
		var needles: Material = WorldVisualCatalog.foliage(Color.WHITE, 1.0, 0.15, 0.0, true)
		for tier: int in 3:
			var t: float = float(tier) / 3.0
			parts.foliage_cone(Vector3(0.0, -0.5 + t * 0.55, 0.0), lerpf(1.0, 0.5, t), lerpf(0.55, 0.45, t), Color(0.55, 0.55, 0.55).lerp(Color.WHITE, t * 0.5),
				Color(0.8, 0.8, 0.8).lerp(Color.WHITE, t), needles)
	)


## A clump of reeds (a 1.1 m blade centred on its middle, as the old reed cylinders were).
static func clutter_reed_mesh() -> ArrayMesh:
	return shared_mesh("clutter_reed", func(parts: Parts) -> void:
		var reeds: Material = WorldVisualCatalog.foliage(Color.WHITE, 1.1, 0.5, 1.0, false, ChunkClutterBaker.FADE_DISTANCE)
		parts.blade(Vector3(0.0, -0.55, 0.0), Vector3(0.03, 0.55, 0.0), 0.06, Color(0.6, 0.6, 0.6), Color.WHITE, reeds)
		parts.foliage_sphere(Vector3(0.03, 0.5, 0.0), 0.035, Color(0.45, 0.32, 0.2), Color(0.55, 0.4, 0.25), reeds, Vector3(1.0, 3.0, 1.0))
	)


## A low mound of leaves `radius` across (brambles, heather tufts), for the instance colour to tint.
static func clutter_mound_mesh(radius: float = 0.6) -> ArrayMesh:
	return shared_mesh("clutter_mound:%.2f" % radius, func(parts: Parts) -> void:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 77
		parts.puff_crown(Vector3(0.0, radius * 0.15, 0.0), radius * 1.25, 5, Color(0.62, 0.62, 0.62), Color.WHITE,
			WorldVisualCatalog.foliage(Color.WHITE, 1.0, 0.2, 1.0, false, ChunkClutterBaker.FADE_DISTANCE), rng, 0.7)
	)


# --- Helpers ------------------------------------------------------------------------------

## An OmniLight3D for a kit (no shadows: many small lights stay cheap).
static func light(light_name: String, color: Color, energy: float, reach: float) -> OmniLight3D:
	var made: OmniLight3D = OmniLight3D.new()
	made.name = light_name
	made.light_color = color
	made.light_energy = energy
	made.omni_range = reach
	made.shadow_enabled = false
	return made


## Apple-wood smoke curling up from a chimney.
static func smoke(smoke_name: String, at: Vector3, amount: int) -> CPUParticles3D:
	var made: CPUParticles3D = CPUParticles3D.new()
	made.name = smoke_name
	made.position = at
	made.amount = amount
	made.lifetime = 3.4
	made.direction = Vector3.UP
	made.spread = 12.0
	made.initial_velocity_min = 0.45
	made.initial_velocity_max = 0.75
	made.gravity = Vector3(0.25, 0.12, 0.0)
	made.scale_amount_min = 0.6
	made.scale_amount_max = 1.5
	var puff: SphereMesh = SphereMesh.new()
	puff.radius = 0.28
	puff.height = 0.56
	puff.radial_segments = 8
	puff.rings = 4
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.86, 0.84, 0.8, 0.45)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = material
	made.mesh = puff
	return made


## A primitive's arrays, made once per shape.
static func primitive_arrays(key: String, maker: Callable) -> Array:
	if not _primitive_arrays.has(key):
		var primitive: PrimitiveMesh = maker.call() as PrimitiveMesh
		_primitive_arrays[key] = primitive.get_mesh_arrays()
	return _primitive_arrays[key]


## A kit's static parts, merged as they're added into one surface per material.
class Parts:
	extends RefCounted

	var _surfaces: Dictionary[Material, Surface] = {}
	var _order: Array[Material] = []

	class Surface:
		extends RefCounted
		var vertices: PackedVector3Array = PackedVector3Array()
		var normals: PackedVector3Array = PackedVector3Array()
		var uvs: PackedVector2Array = PackedVector2Array()
		var colors: PackedColorArray = PackedColorArray()
		var indices: PackedInt32Array = PackedInt32Array()

	func _surface(material: Material) -> Surface:
		var found: Surface = _surfaces.get(material, null)
		if found == null:
			found = Surface.new()
			_surfaces[material] = found
			_order.append(material)
		return found

	## Appends a primitive's (or a mesh surface's) arrays, moved by `where`, its vertices tinted `tint` (linear).
	func add_arrays(arrays: Array, where: Transform3D, material: Material, tint: Color = Color.WHITE) -> void:
		var surface: Surface = _surface(material)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var directions: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var coords: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var order: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var turn: Basis = where.basis.inverse().transposed()
		var base: int = surface.vertices.size()
		for index: int in points.size():
			surface.vertices.append(where * points[index])
			surface.normals.append((turn * directions[index]).normalized())
			surface.uvs.append(coords[index] if index < coords.size() else Vector2.ZERO)
			surface.colors.append(tint)
		if order.is_empty():
			for index: int in points.size():
				surface.indices.append(base + index)
		else:
			for index: int in order:
				surface.indices.append(base + index)

	func box(size: Vector3, at: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> void:
		var arrays: Array = WorldAssetCatalog.primitive_arrays("box", func() -> PrimitiveMesh: return BoxMesh.new())
		add_arrays(arrays, Transform3D(Basis.from_euler(rotation) * Basis.from_scale(size), at), material)

	func cylinder(top: float, bottom: float, height: float, at: Vector3, material: Material, segments: int = 10,
			rotation: Vector3 = Vector3.ZERO) -> void:
		var key: String = "cylinder:%.3f:%d" % [top / maxf(bottom, 0.0001) if bottom > 0.0 else -1.0, segments]
		var arrays: Array = WorldAssetCatalog.primitive_arrays(key, func() -> PrimitiveMesh:
			var made: CylinderMesh = CylinderMesh.new()
			made.top_radius = top / bottom if bottom > 0.0 else 1.0
			made.bottom_radius = 1.0 if bottom > 0.0 else 0.0
			made.height = 1.0
			made.radial_segments = segments
			made.rings = 1
			return made)
		var radius: float = bottom if bottom > 0.0 else top
		add_arrays(arrays, Transform3D(Basis.from_euler(rotation) * Basis.from_scale(Vector3(radius, height, radius)), at), material)

	func sphere(radius: float, at: Vector3, material: Material, squash: Vector3 = Vector3.ONE, segments: int = 10) -> void:
		var arrays: Array = WorldAssetCatalog.primitive_arrays("sphere:%d" % segments, func() -> PrimitiveMesh:
			var made: SphereMesh = SphereMesh.new()
			made.radius = 1.0
			made.height = 2.0
			made.radial_segments = segments
			made.rings = maxi(3, int(segments * 0.5))
			return made)
		add_arrays(arrays, Transform3D(Basis.from_scale(squash * radius), at), material)

	func torus(inner: float, outer: float, at: Vector3, material: Material, segments: int = 16, rotation: Vector3 = Vector3.ZERO) -> void:
		var arrays: Array = WorldAssetCatalog.primitive_arrays("torus:%.3f:%.3f:%d" % [inner, outer, segments], func() -> PrimitiveMesh:
			var made: TorusMesh = TorusMesh.new()
			made.inner_radius = inner
			made.outer_radius = outer
			made.rings = segments
			made.ring_segments = 6
			return made)
		add_arrays(arrays, Transform3D(Basis.from_euler(rotation), at), material)

	## A prism (a gable or a little roof): its triangle in X-Y, run along Z.
	func prism(size: Vector3, at: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> void:
		var arrays: Array = WorldAssetCatalog.primitive_arrays("prism", func() -> PrimitiveMesh: return PrismMesh.new())
		add_arrays(arrays, Transform3D(Basis.from_euler(rotation) * Basis.from_scale(size), at), material)

	## A flat quad facing +Y (before `rotation`), with UVs (a waterfall's curtain).
	func plane(size: Vector2, at: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> void:
		var arrays: Array = WorldAssetCatalog.primitive_arrays("plane", func() -> PrimitiveMesh: return PlaneMesh.new())
		add_arrays(arrays, Transform3D(Basis.from_euler(rotation) * Basis.from_scale(Vector3(size.x * 0.5, 1.0, size.y * 0.5)), at), material)

	## A square-section beam from one point to another.
	func beam(from: Vector3, to: Vector3, thickness: float, material: Material) -> void:
		var along: Vector3 = to - from
		var length: float = along.length()
		if length < 0.001:
			return
		var up: Vector3 = along / length
		var side: Vector3 = up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		var depth: Vector3 = side.cross(up)
		var basis: Basis = Basis(side * thickness, up * length, depth * thickness)
		var arrays: Array = WorldAssetCatalog.primitive_arrays("box", func() -> PrimitiveMesh: return BoxMesh.new())
		add_arrays(arrays, Transform3D(basis, (from + to) * 0.5), material)

	## A crown of leaf-puffs round `center`: normals bent out from the middle, colours from `dark` (below) to `light` (above).
	func puff_crown(center: Vector3, radius: float, puffs: int, dark: Color, light: Color, material: Material,
			rng: RandomNumberGenerator, squash: float) -> void:
		for index: int in puffs:
			var direction: Vector3 = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.3, 0.75), rng.randf_range(-1.0, 1.0)).normalized()
			if index == 0:
				direction = Vector3.UP
			var at: Vector3 = center + direction * radius * rng.randf_range(0.32, 0.6)
			var size: float = radius * rng.randf_range(0.48, 0.66)
			_leaf_ball(at, size, center, radius, dark, light, material, Vector3(1.0, squash, 1.0))

	## A tapered grass blade (or leaf, or reed) from `from` to `to`, `width` at its root, shaded root to tip.
	func blade(from: Vector3, to: Vector3, width: float, root: Color, tip: Color, material: Material) -> void:
		var surface: Surface = _surface(material)
		var along: Vector3 = to - from
		var side: Vector3 = along.cross(Vector3.UP).normalized()
		if side.length() < 0.5:
			side = Vector3.RIGHT
		side *= width * 0.5
		var middle: Vector3 = from + along * 0.55
		var facing: Vector3 = side.cross(along).normalized()
		var up: Vector3 = (facing * 0.4 + Vector3.UP * 0.6).normalized()
		var start: int = surface.vertices.size()
		var points: Array[Vector3] = [from - side, from + side, middle + side * 0.6, middle - side * 0.6, to]
		var shades: Array[float] = [0.0, 0.0, 0.55, 0.55, 1.0]
		for index: int in points.size():
			surface.vertices.append(points[index])
			surface.normals.append(up)
			surface.uvs.append(Vector2(0.0, shades[index]))
			surface.colors.append(root.lerp(tip, shades[index]))
		for index: int in [0, 1, 2, 0, 2, 3, 3, 2, 4]:
			surface.indices.append(start + index)

	func foliage_sphere(at: Vector3, radius: float, dark: Color, light: Color, material: Material, squash: Vector3 = Vector3.ONE) -> void:
		_leaf_ball(at, radius, at, radius, dark, light, material, squash)

	## A tier of a pine: a cone of needles, shaded from its axis outward.
	func foliage_cone(base: Vector3, radius: float, height: float, dark: Color, light: Color, material: Material) -> void:
		var arrays: Array = WorldAssetCatalog.primitive_arrays("cone:12", func() -> PrimitiveMesh:
			var made: CylinderMesh = CylinderMesh.new()
			made.top_radius = 0.0
			made.bottom_radius = 1.0
			made.height = 1.0
			made.radial_segments = 12
			made.rings = 2
			return made)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var directions: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var order: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var surface: Surface = _surface(material)
		var start: int = surface.vertices.size()
		for index: int in points.size():
			var point: Vector3 = Vector3(points[index].x * radius, (points[index].y + 0.5) * height, points[index].z * radius) + base
			var outward: Vector3 = Vector3(point.x - base.x, height * 0.35, point.z - base.z).normalized()
			surface.vertices.append(point)
			surface.normals.append((directions[index] * 0.3 + outward * 0.7).normalized())
			surface.uvs.append(Vector2.ZERO)
			surface.colors.append(dark.lerp(light, clampf(points[index].y + 0.5, 0.0, 1.0)))
		for index: int in order:
			surface.indices.append(start + index)

	func _leaf_ball(at: Vector3, size: float, center: Vector3, crown_radius: float, dark: Color, light: Color, material: Material,
			squash: Vector3) -> void:
		var arrays: Array = WorldAssetCatalog.primitive_arrays("sphere:10", func() -> PrimitiveMesh:
			var made: SphereMesh = SphereMesh.new()
			made.radius = 1.0
			made.height = 2.0
			made.radial_segments = 10
			made.rings = 6
			return made)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var directions: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var order: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var surface: Surface = _surface(material)
		var start: int = surface.vertices.size()
		for index: int in points.size():
			var point: Vector3 = at + points[index] * squash * size
			var outward: Vector3 = (point - center).normalized()
			surface.vertices.append(point)
			surface.normals.append((directions[index] * 0.35 + outward * 0.65).normalized())
			surface.uvs.append(Vector2.ZERO)
			var height: float = clampf((point.y - (center.y - crown_radius)) / (crown_radius * 2.0), 0.0, 1.0)
			surface.colors.append(dark.lerp(light, height))
		for index: int in order:
			surface.indices.append(start + index)

	func is_empty() -> bool:
		return _order.is_empty()

	## The merged mesh: one surface per material, in the order the materials first came.
	func commit() -> ArrayMesh:
		var mesh: ArrayMesh = ArrayMesh.new()
		for material: Material in _order:
			var surface: Surface = _surfaces[material]
			if surface.indices.is_empty():
				continue
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = surface.vertices
			arrays[Mesh.ARRAY_NORMAL] = surface.normals
			arrays[Mesh.ARRAY_TEX_UV] = surface.uvs
			arrays[Mesh.ARRAY_COLOR] = surface.colors
			arrays[Mesh.ARRAY_INDEX] = surface.indices
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			mesh.surface_set_material(mesh.get_surface_count() - 1, material)
		return mesh
