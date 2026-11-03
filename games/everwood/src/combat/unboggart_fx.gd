## What a beaten spirit leaves instead of a body (15_THE_MYTHOPOETIC_LENS.md §6.1,
## Zero-Gore Un-Boggarting), built in code from simple shapes:
## - a release: a white sea-swallow (a Scray's true shape), a brown hedge-wren
##   or a warm path-light rises in a widening spiral, chimes once and fades;
## - a lulled cairn: three mossy stones stacked where the spirit fell, with a
##   tuft of heather on top. A boss's cairn stays; a mob's goes after a while.
class_name UnboggartFx
extends Node3D

enum Kind { RELEASE, CAIRN }

const RELEASE_TIME: float = 2.6
const RELEASE_RISE: float = 6.5
const RELEASE_SPIRAL: float = 1.4
const WING_BEAT: float = 18.0
const CAIRN_GROW_TIME: float = 0.7
const CAIRN_FADE_TIME: float = 1.5
const SWALLOW_COLOR: Color = Color(0.97, 0.97, 0.95)
const WREN_COLOR: Color = Color(0.55, 0.4, 0.26)
const LIGHT_COLOR: Color = Color(1.0, 0.8, 0.42)
const MOSS_COLOR: Color = Color(0.36, 0.5, 0.26)
const STONE_COLOR: Color = Color(0.56, 0.55, 0.52)
const HEATHER_COLOR: Color = Color(0.66, 0.42, 0.66)

var kind: Kind = Kind.RELEASE
var form: HobSpectrumComponent.ReleaseForm = HobSpectrumComponent.ReleaseForm.SEA_SWALLOW
## Seconds a cairn stays before it fades (INF: for good).
var linger: float = INF

var _age: float = 0.0
var _start: Vector3 = Vector3.ZERO
var _wings: Array[Node3D] = []
var _body: Node3D


## Releases a spirit at `at` (world space) under `holder`.
static func release(holder: Node, at: Vector3, chosen: HobSpectrumComponent.ReleaseForm, tint: Color) -> UnboggartFx:
	var fx: UnboggartFx = UnboggartFx.new()
	fx.name = "UnboggartRelease"
	fx.kind = Kind.RELEASE
	fx.form = chosen
	holder.add_child(fx)
	fx.global_position = at
	fx._start = at
	fx._build_release(tint)
	AudioCues.play(&"chime", 1.4, -6.0)
	return fx


## Curls a spirit into a mossy cairn at `at` (world space, on the ground) under `holder`.
static func cairn(holder: Node, at: Vector3, radius: float, tint: Color, stays_for: float) -> UnboggartFx:
	var fx: UnboggartFx = UnboggartFx.new()
	fx.name = "LulledCairn"
	fx.kind = Kind.CAIRN
	fx.linger = stays_for
	holder.add_child(fx)
	fx.global_position = at
	fx._build_cairn(maxf(0.45, radius), tint)
	AudioCues.play(&"bell", 0.55, -8.0)
	return fx


func _process(delta: float) -> void:
	_age += delta
	if kind == Kind.RELEASE:
		var t: float = minf(1.0, _age / RELEASE_TIME)
		var angle: float = t * TAU * 1.5
		global_position = _start + Vector3(cos(angle) * RELEASE_SPIRAL * t, RELEASE_RISE * t * (2.0 - t), sin(angle) * RELEASE_SPIRAL * t)
		rotation.y = -angle
		for index: int in _wings.size():
			_wings[index].rotation.z = sin(_age * WING_BEAT) * 0.7 * (1.0 if index == 0 else -1.0)
		scale = Vector3.ONE * maxf(0.05, 1.0 - maxf(0.0, t - 0.7) / 0.3)
		if t >= 1.0:
			queue_free()
		return
	scale = Vector3.ONE * minf(1.0, _age / CAIRN_GROW_TIME)
	if _age > linger:
		var fade: float = (_age - linger) / CAIRN_FADE_TIME
		position.y = -fade * 0.8
		if fade >= 1.0:
			queue_free()


func _build_release(tint: Color) -> void:
	match form:
		HobSpectrumComponent.ReleaseForm.PATH_LIGHT:
			var glow: Material = StorybookMaterial.glowing(LIGHT_COLOR, 2.2)
			_body = ShapeKit.sphere("PathLight", 0.18, Vector3.ZERO, glow)
			add_child(_body)
			add_child(ShapeKit.sphere("Halo", 0.3, Vector3.ZERO, StorybookMaterial.glowing(Color(LIGHT_COLOR, 0.35), 0.8)))
		_:
			var color: Color = SWALLOW_COLOR if form == HobSpectrumComponent.ReleaseForm.SEA_SWALLOW else WREN_COLOR
			color = color.lerp(tint, 0.15)
			var feathers: Material = StorybookMaterial.glowing(color, 0.6)
			_body = ShapeKit.stretched(ShapeKit.sphere("Bird", 0.12, Vector3.ZERO, feathers), Vector3(0.8, 0.8, 1.6))
			add_child(_body)
			if form == HobSpectrumComponent.ReleaseForm.SEA_SWALLOW:
				# The tern's forked tail.
				for side: float in [-1.0, 1.0]:
					add_child(ShapeKit.tilted(ShapeKit.box("Tail", Vector3(0.03, 0.02, 0.22), Vector3(side * 0.05, 0.0, 0.22), feathers), Vector3(0.0, side * 0.35, 0.0)))
			for side: float in [-1.0, 1.0]:
				var hinge: Node3D = Node3D.new()
				hinge.name = "Wing"
				hinge.position = Vector3(side * 0.08, 0.02, 0.0)
				hinge.add_child(ShapeKit.box("Feathers", Vector3(0.34, 0.02, 0.14), Vector3(side * 0.17, 0.0, 0.0), feathers))
				add_child(hinge)
				_wings.append(hinge)


func _build_cairn(radius: float, tint: Color) -> void:
	var stone: Material = StorybookMaterial.make(STONE_COLOR.lerp(tint, 0.2))
	var moss: Material = StorybookMaterial.make(MOSS_COLOR)
	var sizes: Array[float] = [radius * 1.1, radius * 0.8, radius * 0.55]
	var y: float = 0.0
	for index: int in sizes.size():
		var r: float = sizes[index]
		add_child(ShapeKit.stretched(ShapeKit.sphere("Stone%d" % index, r, Vector3(0.05 * index, y + r * 0.55, -0.04 * index), stone), Vector3(1.0, 0.6, 0.9)))
		y += r * 1.05
	add_child(ShapeKit.stretched(ShapeKit.sphere("Moss", radius * 1.15, Vector3(0.0, radius * 0.35, 0.0), moss), Vector3(1.0, 0.3, 1.0)))
	add_child(ShapeKit.cone("Heather", radius * 0.2, radius * 0.4, Vector3(0.1, y + radius * 0.1, -0.08), StorybookMaterial.make(HEATHER_COLOR)))
