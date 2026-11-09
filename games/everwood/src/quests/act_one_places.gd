## Act I's places on Embershore (Z1_EMB; docs/29 §4): the brief's POI ids,
## each pinned to a real spot on today's isle (docs/27's local frame) with the
## elevation band it really stands on and the band the Bible gave it.
##
## The Creative Director chose (2026-11-09) to fit Act I to today's Embershore
## rather than reshape it, so several of the Bible's places stand in on other
## ground (docs/28 §9):
##   POI_LeeShoreOrchards     the orchard north of Bramblebridge's stone bridge
##                            (the old "Heirloom Orchards"); the Level 1 spawn is
##                            at its south gate on the lane
##   POI_HearthsteadMarket    Bramblebridge green: the Feast green, the Atelier's
##                            bench is next door in the wright's yard (Embershore's
##                            Hearthstead is the Lv 5 town, 900 m east)
##   POI_AppleOrchards        the same orchard's four groves; the Bible's terraces
##                            at +15 / +25 / +35 / +45 m are 7 to 18 m here
##   POI_NorthQuayBridge      Bramblebridge's stone bridge, 90 m from the mill
##   POI_Dungeon_RootSanctum  under the Elder Oak (the Bible's "Great Oak of Hearthstead")
class_name ActOnePlaces
extends RefCounted

const ZONE_EMBERSHORE: StringName = &"Z1_EMB"

const LEE_SHORE_ORCHARDS: StringName = &"POI_LeeShoreOrchards"
const ORCHARD_GATE: StringName = &"POI_OrchardGate"
const HEARTHSTEAD_MARKET: StringName = &"POI_HearthsteadMarket"
const WRIGHTS_YARD: StringName = &"POI_WrightsYard"
const APPLE_ORCHARDS: StringName = &"POI_AppleOrchards"
const GROVE_ROOT: StringName = &"POI_Grove_Root"
const GROVE_LEAF: StringName = &"POI_Grove_Leaf"
const GROVE_FLOWER: StringName = &"POI_Grove_Flower"
const GROVE_SEED: StringName = &"POI_Grove_Seed"
const OLD_WATERMILL: StringName = &"POI_OldWatermill"
const NORTH_QUAY_BRIDGE: StringName = &"POI_NorthQuayBridge"
const HEARTHSTEAD: StringName = &"POI_Hearthstead"
const NORTH_QUAY: StringName = &"POI_NorthQuay"
const OLD_QUAY_EBB_SHELF: StringName = &"POI_OldQuay_EbbShelf"
const ELDER_OAK: StringName = &"POI_ElderOak"
const DUNGEON_ROOT_SANCTUM: StringName = &"POI_Dungeon_RootSanctum"
const WEIR: StringName = &"POI_Weir"

## The four groves, in the order Q02 asks for them (Root, Leaf, Flower, Seed).
const GROVES: Array[StringName] = [GROVE_ROOT, GROVE_LEAF, GROVE_FLOWER, GROVE_SEED]

## The Level 1 spawn: the lane at the orchard's south gate, facing into the orchard.
const SPAWN_AT: Vector2 = Vector2(-584.0, 182.0)
const SPAWN_FACING: Vector2 = Vector2(-0.53, -0.85)

## Each place: on-screen name, centre (x, nominal y, z) in Embershore's frame, reach (m),
## the real ground band (min, max y) and the Bible's elevation (m; NAN where it gave none).
const PLACES: Dictionary = {
	LEE_SHORE_ORCHARDS: {"name": "Lee-Shore Orchards", "at": Vector3(-637.0, 16.0, 97.0), "reach": 190.0, "band": Vector2(5.7, 18.5), "bible": 15.0},
	ORCHARD_GATE: {"name": "The Orchard Gate", "at": Vector3(-586.0, 12.0, 192.0), "reach": 16.0, "band": Vector2(9.0, 15.0), "bible": 15.0},
	HEARTHSTEAD_MARKET: {"name": "Bramblebridge Green", "at": Vector3(-593.9, 17.0, 257.7), "reach": 22.0, "band": Vector2(15.0, 18.0), "bible": 0.0},
	WRIGHTS_YARD: {"name": "The Wright's Yard", "at": Vector3(-638.3, 17.8, 259.4), "reach": 14.0, "band": Vector2(16.0, 19.0), "bible": 0.0},
	APPLE_ORCHARDS: {"name": "The Apple Orchards", "at": Vector3(-637.0, 16.0, 97.0), "reach": 190.0, "band": Vector2(5.7, 18.5), "bible": 15.0},
	GROVE_ROOT: {"name": "The Root Grove", "at": Vector3(-770.0, 7.1, 148.0), "reach": 26.0, "band": Vector2(5.7, 10.7), "bible": 15.0},
	GROVE_LEAF: {"name": "The Leaf Grove", "at": Vector3(-505.0, 17.0, 178.0), "reach": 26.0, "band": Vector2(10.9, 18.0), "bible": 25.0},
	GROVE_FLOWER: {"name": "The Flower Grove", "at": Vector3(-604.0, 16.9, 73.0), "reach": 24.0, "band": Vector2(16.1, 17.0), "bible": 35.0},
	GROVE_SEED: {"name": "The Seed Grove", "at": Vector3(-705.0, 18.0, 5.0), "reach": 26.0, "band": Vector2(17.0, 18.5), "bible": 45.0},
	OLD_WATERMILL: {"name": "The Old Watermill", "at": Vector3(-512.0, 12.2, 259.4), "reach": 22.0, "band": Vector2(9.0, 14.0), "bible": 15.0},
	NORTH_QUAY_BRIDGE: {"name": "The Stone Bridge", "at": Vector3(-589.0, 6.5, 213.3), "reach": 18.0, "band": Vector2(6.0, 11.0), "bible": 0.0},
	HEARTHSTEAD: {"name": "Hearthstead", "at": Vector3(39.2, 22.2, -194.6), "reach": 95.0, "band": Vector2(18.0, 26.0), "bible": 0.0},
	NORTH_QUAY: {"name": "North Quay", "at": Vector3(37.55, 1.6, -247.0), "reach": 26.0, "band": Vector2(-0.6, 2.0), "bible": 0.0},
	OLD_QUAY_EBB_SHELF: {"name": "The Old Quay", "at": Vector3(39.0, -4.5, -252.6), "reach": 24.0, "band": Vector2(-6.0, -4.5), "bible": -6.0},
	ELDER_OAK: {"name": "The Elder Oak", "at": Vector3(-189.4, 15.2, 167.2), "reach": 34.0, "band": Vector2(12.0, 17.0), "bible": 0.0},
	DUNGEON_ROOT_SANCTUM: {"name": "The Root-Sanctum", "at": Vector3(-146.8, 13.8, 233.8), "reach": 10.0, "band": Vector2(-12.0, 14.0), "bible": 0.0},
	WEIR: {"name": "The Bramble Weir", "at": Vector3(-453.4, 6.1, 212.3), "reach": 18.0, "band": Vector2(4.0, 8.0), "bible": 0.0},
}


static func has_place(place_id: StringName) -> bool:
	return PLACES.has(place_id)


static func display_name(place_id: StringName) -> String:
	return String((PLACES.get(place_id, {}) as Dictionary).get("name", String(place_id)))


static func centre(place_id: StringName) -> Vector3:
	return (PLACES.get(place_id, {}) as Dictionary).get("at", Vector3.ZERO)


static func reach(place_id: StringName) -> float:
	return float((PLACES.get(place_id, {}) as Dictionary).get("reach", 0.0))


## The real ground band (min y, max y) the place stands on.
static func band(place_id: StringName) -> Vector2:
	return (PLACES.get(place_id, {}) as Dictionary).get("band", Vector2.ZERO)


## The Bible's elevation for it (its +15 / +25 / +35 / +45 m tiers, the -6 m shelf).
static func bible_elevation(place_id: StringName) -> float:
	return float((PLACES.get(place_id, {}) as Dictionary).get("bible", 0.0))


## Whether a spot (Embershore's frame) is inside a place: within its reach on the
## ground, and within its band (with 4 m of slack) up and down. The Root-Sanctum's
## band reaches down under the Elder Oak.
static func contains(place_id: StringName, at: Vector3) -> bool:
	if not PLACES.has(place_id):
		return false
	var middle: Vector3 = centre(place_id)
	if Vector2(at.x - middle.x, at.z - middle.z).length() > reach(place_id):
		return false
	var heights: Vector2 = band(place_id)
	return at.y >= heights.x - 4.0 and at.y <= heights.y + 4.0


## Every place a spot is inside, in registry order.
static func places_at(at: Vector3) -> Array[StringName]:
	var found: Array[StringName] = []
	for place_id: Variant in PLACES:
		if contains(StringName(place_id), at):
			found.append(StringName(place_id))
	return found
