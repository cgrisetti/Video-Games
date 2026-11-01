## One of the twin Scribe Rune-Plates on the Doverslap Gorge Bridge
## (07_EXPEDITION_HUD_AND_ART_GDD.md §3, Zone 2): a stone disc with a ring of
## runes that glows when someone stands on it and burns gold as the gate's
## count fills. CoopGate reads it; every peer lights it from synced positions.
class_name RunePlate
extends Node3D

const RADIUS: float = 1.2
const DARK_COLOR: Color = Color(0.35, 0.33, 0.45)
const LIT_COLOR: Color = Color(0.55, 0.85, 1.0)
const FULL_COLOR: Color = Color(1.0, 0.82, 0.35)

## Someone standing is on it right now.
var occupied: bool = false

var _rune_material: StandardMaterial3D
var _progress: float = 0.0


func _ready() -> void:
	var stone: Material = StorybookMaterial.make(Color(0.55, 0.54, 0.5))
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = RADIUS
	disc.bottom_radius = RADIUS + 0.08
	disc.height = 0.12
	disc.radial_segments = 32
	disc.material = stone
	var slab: MeshInstance3D = MeshInstance3D.new()
	slab.name = "Slab"
	slab.mesh = disc
	slab.position = Vector3(0.0, 0.06, 0.0)
	add_child(slab)
	_rune_material = StandardMaterial3D.new()
	_rune_material.albedo_color = DARK_COLOR
	_rune_material.emission_enabled = true
	_rune_material.emission = DARK_COLOR
	_rune_material.emission_energy_multiplier = 0.4
	for ring: float in [RADIUS * 0.82, RADIUS * 0.45]:
		var torus: TorusMesh = TorusMesh.new()
		torus.inner_radius = ring - 0.05
		torus.outer_radius = ring
		torus.rings = 48
		torus.material = _rune_material
		var rune: MeshInstance3D = MeshInstance3D.new()
		rune.name = "Runes"
		rune.mesh = torus
		rune.position = Vector3(0.0, 0.13, 0.0)
		add_child(rune)


func contains(point: Vector3) -> bool:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length() <= RADIUS and absf(point.y - global_position.y) < 1.5


## Lights the runes: blue while stood on, gold as the hold `progress` (0..1) fills.
func show_state(is_occupied: bool, progress: float) -> void:
	occupied = is_occupied
	_progress = progress
	var color: Color = DARK_COLOR
	if is_occupied:
		color = LIT_COLOR.lerp(FULL_COLOR, clampf(progress, 0.0, 1.0))
	_rune_material.albedo_color = color
	_rune_material.emission = color
	_rune_material.emission_energy_multiplier = 0.4 if not is_occupied else 2.0 + progress * 2.0
