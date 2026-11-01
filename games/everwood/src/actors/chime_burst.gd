## Chimes scattering from a chest or a cleared camp (07 GDD §1.2): gleaming
## brass octagons pop up, hang for a moment, then magnetize into the party's
## satchels, each landing with the two-note brass bell. Presentation only: the
## host has already paid the Chimes into the party pouch.
class_name ChimeBurst
extends Node3D

## Coins shown, however many Chimes were paid (a big chest would be a blizzard).
const MAX_COINS: int = 10
const COIN_SIZE: float = 0.32
const POP_SPEED: float = 5.5
const POP_SPREAD: float = 2.4
const GRAVITY: float = 12.0
## Seconds the coins fly freely before they home in.
const SCATTER_TIME: float = 0.55
## Seconds from homing in to landing in a satchel.
const HOME_TIME: float = 0.45
const SPIN_SPEED: float = 9.0
## Coins land this high on their catcher (about the belt).
const SATCHEL_HEIGHT: float = 1.0

var _coins: Array[MeshInstance3D] = []
var _velocities: Array[Vector3] = []
var _catchers: Array[Node3D] = []
var _home_from: Array[Vector3] = []
var _age: float = 0.0
var _chimed: int = 0


## `count` coins pop out here and fly to `catchers` in turn (no catchers: they just fade).
func configure(count: int, catchers: Array[Node3D]) -> void:
	_catchers = catchers
	for index: int in clampi(count, 1, MAX_COINS):
		var coin: MeshInstance3D = ChimeCoin.make(COIN_SIZE)
		coin.name = "Coin%d" % index
		coin.rotation = Vector3(randf() * TAU, randf() * TAU, 0.0)
		add_child(coin)
		_coins.append(coin)
		var angle: float = TAU * float(index) / maxf(1.0, float(count)) + randf() * 0.4
		_velocities.append(Vector3(cos(angle) * POP_SPREAD * randf_range(0.5, 1.0), POP_SPEED * randf_range(0.8, 1.2), sin(angle) * POP_SPREAD * randf_range(0.5, 1.0)))
		_home_from.append(Vector3.ZERO)


func _ready() -> void:
	name = "ChimeBurst"


func _process(delta: float) -> void:
	_age += delta
	for index: int in _coins.size():
		var coin: MeshInstance3D = _coins[index]
		if not coin.visible:
			continue
		coin.rotate_y(SPIN_SPEED * delta)
		if _age < SCATTER_TIME or _catchers.is_empty():
			_velocities[index].y -= GRAVITY * delta
			coin.position += _velocities[index] * delta
			_home_from[index] = coin.global_position
			if _catchers.is_empty() and _age >= SCATTER_TIME + HOME_TIME:
				coin.visible = false
			continue
		var catcher: Node3D = _catchers[index % _catchers.size()]
		if not is_instance_valid(catcher):
			coin.visible = false
			continue
		var t: float = clampf((_age - SCATTER_TIME) / HOME_TIME, 0.0, 1.0)
		var goal: Vector3 = catcher.global_position + Vector3.UP * SATCHEL_HEIGHT
		coin.global_position = _home_from[index].lerp(goal, t * t)
		coin.scale = Vector3.ONE * (COIN_SIZE / (ChimeCoin.RADIUS * 2.0)) * (1.0 - t * 0.6)
		if t >= 1.0:
			coin.visible = false
			# One bell per coin would be a din: the first few ring, rising in pitch.
			if _chimed < 3:
				AudioCues.play(&"chime", 1.0 + 0.12 * _chimed)
				_chimed += 1
	if _age >= SCATTER_TIME + HOME_TIME + 0.1:
		queue_free()
