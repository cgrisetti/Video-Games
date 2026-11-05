## The Six-Zone Stewardship Atlas (15_THE_MYTHOPOETIC_LENS.md §5) as typed data
## (StewardshipZoneResource) registered by id, and which zone's rhyme each
## place we've built sings on the Chime-Post ribbon (CrossGrimoireHUD).
##   1 Tizzi-Wed-Green       Sign of Wood    Boggart-Kin and Hedgerow-Hobs
##   2 Gull-Wick-Haven       Sign of Water   Sea-Cave Scrays and Gale-Buccas
##   3 Barley-Bridge-Meadow  Sign of Iron    Furrow Iron-Men and Chain-Hounds
##   4 Rush-Light-Hollow     Sign of Fire    Wisp-Boggles and Lob-Clouds
##   5 Barrow-Crag-Crossing  Sign of Stone   Cairn-Drakes, Scree-Worms, Tor-Sleepers
##   6 Sunken-Crown-Falls    Sign of Bronze  Old-Hob-of-the-Hill and the Deep-Hush
class_name MythopoeticAtlas
extends RefCounted

const TIZZI_WED_GREEN: StringName = &"tizzi_wed_green"
const GULL_WICK_HAVEN: StringName = &"gull_wick_haven"
const BARLEY_BRIDGE_MEADOW: StringName = &"barley_bridge_meadow"
const RUSH_LIGHT_HOLLOW: StringName = &"rush_light_hollow"
const BARROW_CRAG_CROSSING: StringName = &"barrow_crag_crossing"
const SUNKEN_CROWN_FALLS: StringName = &"sunken_crown_falls"

## Each built place's zone: Oakshire Vale's village and petals, and the
## Bramble-Bridge trail from Honey-Wick to the Ring of the Cairnsman.
const PLACE_ZONES: Dictionary[String, StringName] = {
	"Oakshire-Wick": TIZZI_WED_GREEN,
	"Wayfarer-Green": TIZZI_WED_GREEN,
	"Pippin-Green": TIZZI_WED_GREEN,
	"Bramble-Hollow": RUSH_LIGHT_HOLLOW,
	"Quarry-Wick": BARLEY_BRIDGE_MEADOW,
	"Nine-Stones-Crossing": BARROW_CRAG_CROSSING,
	"The Settled Meadow": TIZZI_WED_GREEN,
	"Honey-Wick": TIZZI_WED_GREEN,
	"Bramble-Bridge": TIZZI_WED_GREEN,
	"Moss-Oak-Hollow": TIZZI_WED_GREEN,
	"Rush-Light-Hollow": RUSH_LIGHT_HOLLOW,
	"Dover-Slap-Bridge": GULL_WICK_HAVEN,
	"The Ring of the Cairnsman": BARROW_CRAG_CROSSING,
}

const Sign = ScribeSignResource.Sign

static var _zones: Dictionary[StringName, StewardshipZoneResource] = {}
static var _order: Array[StringName] = []


static func zone(id: StringName) -> StewardshipZoneResource:
	_ensure()
	return _zones.get(id, null)


## The six zones, in atlas order.
static func all() -> Array[StewardshipZoneResource]:
	_ensure()
	var list: Array[StewardshipZoneResource] = []
	for id: StringName in _order:
		list.append(_zones[id])
	return list


## The zone whose rhyme `place` sings (&"" for a place outside the atlas).
static func zone_for_place(place: String) -> StringName:
	return PLACE_ZONES.get(place, &"")


static func _ensure() -> void:
	if not _zones.is_empty():
		return
	_add(TIZZI_WED_GREEN, "Tizzi-Wed-Green", "Sign of Wood", [Sign.SIGN_WARM_HEARTH, Sign.SIGN_IRON_ROOT],
		"Hollow oak roots, loose cellar flagstones, dry-stone stiles.", "Boggart-Kin, Nut-Nans and Hedgerow-Hobs",
		["Lift the flagstone, sweep the floor,", "Leave the cream beside the door;",
			"Name the Boggart, lose the plough,", "Tizzi-Wed is flitting now!"],
		{"Leave the cream": Sign.SIGN_WARM_HEARTH, "Name the Boggart": Sign.SIGN_STAR_TIDE, "sweep the floor": Sign.SIGN_IRON_ROOT},
		"Wave the Truce-Sign within 6 m: a curious hob dances (+25 Chimes, +1 pip).")
	_add(GULL_WICK_HAVEN, "Gull-Wick-Haven", "Sign of Water", [Sign.SIGN_RIME_GALE, Sign.SIGN_STAR_TIDE],
		"Flooded fogous, sea-caves, booming tide-wells.", "Sea-Cave Scrays, Shingle-Scrays and Gale-Buccas",
		["When the Scray comes out of the cave,", "Hide the lantern, bar the wave;",
			"Ring the bell on Gull-Wick-Green,", "Or the bridge will never be seen!"],
		{"bar the wave": Sign.SIGN_RIME_GALE, "Ring the bell": Sign.SIGN_STAR_TIDE, "Hide the lantern": Sign.SIGN_WARM_HEARTH},
		"Stand by a Lantern-Bearer to clear the Dread-Chill; a broken Scray flies off a white sea-swallow.")
	_add(BARLEY_BRIDGE_MEADOW, "Barley-Bridge-Meadow", "Sign of Iron", [Sign.SIGN_WARM_HEARTH, Sign.SIGN_IRON_ROOT],
		"Deep plough-furrows, bog-iron pits, rusted ditch-drains.", "Furrow Iron-Men, Chain-Hounds and Scythe-Stalkers",
		["Deep in the furrow the Iron-Man sleeps,", "Under the barley the rust-kettle creeps;",
			"Turn the Seal right-way and feed him a coal,", "Or he'll eat up the bridge and the miller's whole toll!"],
		{"feed him a coal": Sign.SIGN_WARM_HEARTH, "Turn the Seal right-way": Sign.SIGN_IRON_ROOT, "Iron-Man sleeps": Sign.SIGN_STAR_TIDE},
		"Warm-Hearth opens the chest; Iron-Root turns the Maker-Seal; the Iron-Man bows as a steward.")
	_add(RUSH_LIGHT_HOLLOW, "Rush-Light-Hollow", "Sign of Fire", [Sign.SIGN_WARM_HEARTH],
		"Bottomless peat-hags, marsh gas-vents, drowned trunks.", "Wisp-Boggles, Lob-Clouds and Greetin-Bairns",
		["Follow the lantern that dances on peat,", "Down in the Hollow where bog-waters meet;",
			"Light the true candle of tallow and twine,", "Or Lob-in-the-Raincloud will drink up the Sign!"],
		{"Follow the lantern": Sign.SIGN_STAR_TIDE, "Light the true candle": Sign.SIGN_WARM_HEARTH, "bog-waters meet": Sign.SIGN_RIME_GALE},
		"Soul Tethers hold you against the bog; a beaten Wisp-Boggle rises as a warm path-light.")
	_add(BARROW_CRAG_CROSSING, "Barrow-Crag-Crossing", "Sign of Stone", [Sign.SIGN_IRON_ROOT, Sign.SIGN_STAR_TIDE],
		"Prehistoric barrows, split granite tors, old tin-shafts.", "Cairn-Drakes, Scree-Worms, Tor-Sleepers and Crag-Spriggans",
		["Count the stones upon the hill,", "Nine stand up and one lies still;",
			"If the tenth begins to crawl,", "Stack the cairn and mend the wall!"],
		{"Count the stones": Sign.SIGN_STAR_TIDE, "Stack the cairn": Sign.SIGN_IRON_ROOT, "mend the wall": Sign.SIGN_WARM_HEARTH},
		"Answer the 45-frame Challenge-Roar with a Parry & Strike; a broken drake curls into a mossy cairn.")
	_add(SUNKEN_CROWN_FALLS, "Sunken-Crown-Falls", "Sign of Bronze",
		[Sign.SIGN_IRON_ROOT, Sign.SIGN_RIME_GALE, Sign.SIGN_WARM_HEARTH, Sign.SIGN_STAR_TIDE],
		"The First-Crevice at the Great Cataract.", "Old-Hob-of-the-Hill, the Un-Named and the Deep-Hush Hunën",
		["Six Signs joined upon the track,", "Turn the Long Un-Making back;",
			"Speak the name that warms the stone,", "None shall go into the dark alone."],
		{"Six Signs joined": Sign.SIGN_IRON_ROOT, "warms the stone": Sign.SIGN_STAR_TIDE, "Un-Making back": Sign.SIGN_RIME_GALE,
			"None shall go": Sign.SIGN_WARM_HEARTH},
		"All Four Ink-Signs bursting together along the Soul Tether give Old-Hob his true hearth-name back.")


static func _add(id: StringName, label: String, cooper: String, signs: Array[int], crack: String, kin: String,
		lines: Array[String], tints: Dictionary[String, int], payoff: String) -> void:
	var made: StewardshipZoneResource = StewardshipZoneResource.new()
	made.zone_id = id
	made.display_name = label
	made.cooper_sign = cooper
	made.harmony_signs = signs
	made.crack = crack
	made.kin = kin
	made.rhyme_lines = PackedStringArray(lines)
	made.tinted_phrases = tints
	made.payoff = payoff
	_zones[id] = made
	_order.append(id)
