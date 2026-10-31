@tool
class_name Creek
extends RefCounted

# Berry Rush's creek: it winds across the field from the north-east corner to the south-west, with
# sloping banks down to a stony bed, and two arched footbridges over it. Wading through it slows
# you (and the inch worms) to 60%. The numbers and shape are the same as the three.js game's, so the
# field plays the same; the look (water, banks, bridges) is new.
#
# `along` measures distance down the field's north-east to south-west diagonal; `across` measures
# sideways from it, growing toward the south-east. The creek's middle wanders across as it goes.

const OFFSET := -5.5 # How far the creek's middle line sits north-west of the middle of the field.
const WIGGLE := 2.5 # How far it bends from side to side...
const WIGGLE_LENGTH := 26.0 # ...and how far along one whole bend takes.
const BED_HALF_WIDTH := 1.1 # Half the width of the flat creek bed.
const BANK_WIDTH := 1.5 # How wide each sloping bank is.
const DEPTH := 0.6 # How far the bed sits below the grass.
const WATER_LEVEL := -0.28
const HALF_WIDTH := BED_HALF_WIDTH + BANK_WIDTH # From the middle to the top of a bank.
const SLOWDOWN := 0.6 # Speed while wading.
# The bridges sit this far along the creek from the middle of the field (negative is north-east).
const BRIDGE_SPOTS := [-9.0, 13.0]
const BRIDGE_LENGTH := HALF_WIDTH * 2.0 + 1.6
const BRIDGE_WIDTH := 1.9
const BRIDGE_RISE := 0.8 # How high the middle of a bridge arches above the grass.
const RAIL_HEIGHT := 0.55

const BEND_RATE := TAU / WIGGLE_LENGTH


static func middle_at(along: float) -> float:
	return OFFSET + WIGGLE * sin(BEND_RATE * along)


# How far a spot is from the middle of the creek.
static func distance(x: float, z: float) -> float:
	var along := (z - x) / sqrt(2.0)
	var across := (x + z) / sqrt(2.0)
	var lean := WIGGLE * BEND_RATE * cos(BEND_RATE * along)
	return absf(across - middle_at(along)) / sqrt(1.0 + lean * lean)


# The ground's height at a spot, not counting bridges: 0 on the grass, down to -DEPTH on the bed.
static func terrain_height(x: float, z: float) -> float:
	var d := distance(x, z)
	if d >= HALF_WIDTH:
		return 0.0
	return -DEPTH * (1.0 - smoothstep(BED_HALF_WIDTH, HALF_WIDTH, d))


# Where each bridge stands: its middle, which way it spans the creek, and which way the water flows.
static func bridges() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for spot: float in BRIDGE_SPOTS:
		var middle := middle_at(spot)
		var center := Vector3((middle - spot) / sqrt(2.0), 0, (middle + spot) / sqrt(2.0))
		var lean := WIGGLE * BEND_RATE * cos(BEND_RATE * spot)
		var flow := Vector3(lean - 1.0, 0, lean + 1.0).normalized()
		var span := Vector3(flow.z, 0, -flow.x) # Straight across the creek.
		list.append({"center": center, "span": span, "flow": flow})
	return list


# The height of a bridge's deck, `along` it from its middle.
static func deck_height(along: float) -> float:
	return BRIDGE_RISE * cos(PI * along / BRIDGE_LENGTH)


# A spot as distances along a bridge and sideways from its middle line.
static func on_bridge(bridge: Dictionary, x: float, z: float) -> Vector2:
	var offset := Vector3(x, 0, z) - (bridge.center as Vector3)
	return Vector2(offset.dot(bridge.span), offset.dot(bridge.flow))


# The height of whatever you'd stand on: grass, the creek bed, or a bridge.
static func ground_height(x: float, z: float, bridge_list: Array[Dictionary]) -> float:
	var height := terrain_height(x, z)
	for bridge in bridge_list:
		var local := on_bridge(bridge, x, z)
		if absf(local.x) < BRIDGE_LENGTH / 2.0 and absf(local.y) < BRIDGE_WIDTH / 2.0:
			height = maxf(height, deck_height(local.x))
	return height


static func is_near_bridge(x: float, z: float, margin: float, bridge_list: Array[Dictionary]) -> bool:
	for bridge in bridge_list:
		var local := on_bridge(bridge, x, z)
		if absf(local.x) < BRIDGE_LENGTH / 2.0 + margin and absf(local.y) < BRIDGE_WIDTH / 2.0 + margin:
			return true
	return false
