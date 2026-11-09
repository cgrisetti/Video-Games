## Act I, The Fading Margin (Z1_EMB Embershore, Levels 1-6, 0 to 3,800 XP):
## the Narrative & Design Bible's quests Q01 to Q05 as data (docs/28 is their
## script, docs/29 the build), plus the Bible's whole Master Quest Ledger as
## numbers so the level curve can be checked against it.
##
## Ids are the engineering brief's (Q01_LeeShoreAwakening, NPC_AlfWright,
## Boss_FurrowIronMan, Item_LivingCiderResin ...); what shows on screen follows
## Gate 6's living-room words (Ink-Drops, not "Card Fuel pips"; "calm", never "kill").
class_name ActOneQuests
extends RefCounted

const Kind = QuestStepResource.Kind

# --- Quests ------------------------------------------------------------------------------
const Q01: StringName = &"Q01_LeeShoreAwakening"
const Q02: StringName = &"Q02_BlightedCiderBoughs"
const Q03: StringName = &"Q03_SilentMillAndIronMan"
const Q04: StringName = &"Q04_SixShallTurnItBack"
const Q05: StringName = &"Q05_DungeonRootSanctum"
const ORDER: Array[StringName] = [Q01, Q02, Q03, Q04, Q05]

# --- The cast ----------------------------------------------------------------------------
const NPC_ALF_WRIGHT: StringName = &"NPC_AlfWright"
const NPC_REEVE_NOKES: StringName = &"NPC_ReeveNokes"
const NPC_DAME_TENAR_MOSS: StringName = &"NPC_DameTenarMoss"
const NPC_MILLER_HOB: StringName = &"NPC_MillerHob"

# --- Bosses (the Stag Hunts) -------------------------------------------------------------
const BOSS_FURROW_IRON_MAN: StringName = &"Boss_FurrowIronMan"
const BOSS_TAPROOT_STAG: StringName = &"Boss_BlightedTaprootStag"

# --- Things the world reports (QuestStepResource.Kind.EVENT) -----------------------------
const EVENT_GREEN_LIT: StringName = &"green_lit"
const EVENT_GROVE_CLEARED: StringName = &"grove_cleared"
const EVENT_SHRINE_LIT: StringName = &"shrine_lit"
const EVENT_TIDE_EBB: StringName = &"tide_ebb"
const EVENT_EBB_WAVES_HELD: StringName = &"ebb_waves_held"
const EVENT_BELL_CHAIN_RUNG: StringName = &"bell_chain_rung"
const EVENT_SANCTUM_ENTERED: StringName = &"sanctum_entered"
const EVENT_CHAMBER_CLEARED: StringName = &"chamber_cleared"
const EVENT_FEAST_COMPLETE: StringName = &"feast_complete"

# --- Items -------------------------------------------------------------------------------
const ITEM_LIVING_CIDER_RESIN: StringName = &"Item_LivingCiderResin"
const ITEM_WARMTH_EMBER: StringName = &"Item_WarmthEmber"
const RELIC_BRONZE_CARILLON_TONGUE: StringName = &"Relic_BronzeCarillonTongue"

# --- What the quests open ----------------------------------------------------------------
const UNLOCK_STARTER_WEAPON: StringName = &"StarterWeapon"
const UNLOCK_CALMING_SEAL: StringName = &"Card_CalmingSeal"
const UNLOCK_CARD_FUEL: StringName = &"CardFuelReservoir"
const UNLOCK_STEM_SOLO_BASSOON: StringName = &"AudioStem_SoloBassoon"
const UNLOCK_SCRIBE_CRAFTING: StringName = &"System_ScribeCrafting"
const UNLOCK_BREACHING_SEAL: StringName = &"Card_BreachingSeal"
const UNLOCK_DUAL_SLOT: StringName = &"DualActiveSealSlot"
const UNLOCK_HEARTH_WARMTH: StringName = &"Card_HearthWarmth"
const UNLOCK_TIDAL_HOROLOGIUM: StringName = &"HUD_TidalHorologium"
const UNLOCK_FAY_STAR_SEAL: StringName = &"Card_FayStarSeal"
const UNLOCK_CAUSEWAYS: StringName = &"Causeways_Open"

## The Bible's Master Quest Ledger (§5): [number, title, zone, level reached, XP, cumulative XP].
## Q13 reaches Level 14 at 27,650; Q14 caps the spine at 30,500 (PartyProgress.XP_CEILING).
const LEDGER: Array[Array] = [
	[1, "Lee-Shore Awakening", "Z1_EMB", 2, 400, 400],
	[2, "The Blighted Cider-Boughs", "Z1_EMB", 3, 500, 900],
	[3, "The Silent Mill & The Furrow Iron-Man", "Z1_EMB", 4, 700, 1600],
	[4, "Six Shall Turn It Back", "Z1_EMB", 5, 900, 2500],
	[5, "The Root-Sanctum & The Star in the Cake", "Z1_EMB", 6, 1300, 3800],
	[6, "The Bore-Spike Gauntlet", "Z2_IRN", 7, 1600, 5400],
	[7, "Raid A: The Under-Forge", "Z2_IRN", 8, 2000, 7400],
	[8, "Willow-Marsh Barrows", "Z3_BAR", 9, 2400, 9800],
	[9, "Raid C: The Sunken Cathedral", "Z3_BAR", 10, 2800, 12600],
	[10, "Northern Switchbacks", "Z4_RIM", 11, 3400, 16000],
	[11, "Scriptorium of Temptation", "Z4_RIM", 12, 4000, 20000],
	[12, "Raid B: Frost-Peak Aerie", "Z4_RIM", 13, 4800, 24800],
	[13, "The Three Shore Trials", "Z5_CRN", 14, 2850, 27650],
	[14, "The Naming of the Shadow", "Z5_CRN", 14, 2850, 30500],
]

static var _quests: Dictionary[StringName, QuestDefinition] = {}


static func quest(quest_id: StringName) -> QuestDefinition:
	_ensure()
	return _quests.get(quest_id, null)


## Act I's five, in order.
static func all() -> Array[QuestDefinition]:
	_ensure()
	var list: Array[QuestDefinition] = []
	for quest_id: StringName in ORDER:
		list.append(_quests[quest_id])
	return list


## The quest that follows `quest_id` (&"" after Q05).
static func next_after(quest_id: StringName) -> StringName:
	var index: int = ORDER.find(quest_id)
	return ORDER[index + 1] if index >= 0 and index < ORDER.size() - 1 else &""


static func _ensure() -> void:
	if not _quests.is_empty():
		return
	# Q01 · Tolkien, Recovery: wear the hounds down, then calm them; the colour comes back.
	_add(Q01, 1, "Lee-Shore Awakening", "Lee-Shore Awakening & Through the Veil of Mooreeffoc", 1, 2, "Tolkien: Recovery & Mooreeffoc", &"", [
		QuestStepResource.make(&"wake", Kind.REACH_PLACE, ActOnePlaces.LEE_SHORE_ORCHARDS, "Wake in Lee-Shore Orchards", 1, ActOnePlaces.LEE_SHORE_ORCHARDS),
		QuestStepResource.make(&"meet_alf", Kind.TALK_TO, NPC_ALF_WRIGHT, "Speak to Master Alf-Wright at the orchard gate", 1, ActOnePlaces.ORCHARD_GATE,
			[UNLOCK_STARTER_WEAPON, UNLOCK_CALMING_SEAL, UNLOCK_CARD_FUEL]),
		QuestStepResource.make(&"calm_hounds", Kind.CALM, Bestiary.BRAMBLE_HOUND, "Wear down the Bramble-Hounds, then calm them", 6, ActOnePlaces.LEE_SHORE_ORCHARDS),
		QuestStepResource.make(&"green", Kind.REACH_PLACE, ActOnePlaces.HEARTHSTEAD_MARKET, "Bring the colour home to Bramblebridge Green", 1, ActOnePlaces.HEARTHSTEAD_MARKET,
			[UNLOCK_STEM_SOLO_BASSOON]),
	], [])
	# Q02 · Le Guin, Equilibrium: clear the weevils, spare the trees, give the shrines what you carry.
	_add(Q02, 2, "The Blighted Cider-Boughs", "Root, Leaf, Flower, and Seed: The Blighted Cider-Boughs", 2, 3, "Le Guin: Equilibrium & True Being", Q01, [
		QuestStepResource.make(&"argument", Kind.TALK_TO, NPC_DAME_TENAR_MOSS, "Hear out Reeve Nokes and Dame Tenar-Moss at the orchard gate", 1, ActOnePlaces.ORCHARD_GATE),
		QuestStepResource.make(&"groves", Kind.EVENT, EVENT_GROVE_CLEARED, "Clear the Grey-Bark Weevils from the four groves, sparing the trees", 4, ActOnePlaces.APPLE_ORCHARDS),
		QuestStepResource.make(&"shrines", Kind.EVENT, EVENT_SHRINE_LIT, "Pour Ink-Drops into the four Root-Shrines: Ael-Voran", 4, ActOnePlaces.APPLE_ORCHARDS),
		QuestStepResource.make(&"bench", Kind.TALK_TO, NPC_ALF_WRIGHT, "Bring the Living Cider-Resin to Alf-Wright's bench", 1, ActOnePlaces.WRIGHTS_YARD,
			[UNLOCK_SCRIBE_CRAFTING, UNLOCK_BREACHING_SEAL]),
	], [])
	# Q03 · Hobb, Forging, and the Stag Hunt: hold blades, finish together, warm a cold hearth.
	_add(Q03, 3, "The Silent Mill & The Furrow Iron-Man", "The Silent Mill & The Furrow Iron-Man", 3, 4, "Hobb: Forging + the Stag Hunt", Q02, [
		QuestStepResource.make(&"granary", Kind.CALM, Bestiary.ASH_GREMLIN, "Calm the Ash-Grigs raiding Miller Hob's granary", 5, ActOnePlaces.OLD_WATERMILL),
		QuestStepResource.make(&"hob", Kind.TALK_TO, NPC_MILLER_HOB, "Speak to Miller Hob", 1, ActOnePlaces.OLD_WATERMILL),
		QuestStepResource.make(&"bridge", Kind.REACH_PLACE, ActOnePlaces.NORTH_QUAY_BRIDGE, "Go to the stone bridge", 1, ActOnePlaces.NORTH_QUAY_BRIDGE),
		QuestStepResource.make(&"iron_man", Kind.BOSS_OUTCOME, BOSS_FURROW_IRON_MAN, "Wear down the Furrow Iron-Man, hold your blades and finish together", 1,
			ActOnePlaces.NORTH_QUAY_BRIDGE),
		QuestStepResource.make(&"hearth", Kind.NPC_RESTORED, NPC_MILLER_HOB, "Carry the Warmth-Ember to Hob's cold hearth", 1, ActOnePlaces.OLD_WATERMILL),
	], [UNLOCK_DUAL_SLOT, UNLOCK_HEARTH_WARMTH])
	# Q04 · Cooper, the Ebb-Tide: read the verse, beat the tide, ring three bells on the beat.
	_add(Q04, 4, "Six Shall Turn It Back", "Six Shall Turn It Back at the Old Quay", 4, 5, "Cooper: the Ebb-Tide & the six-line verse", Q03, [
		QuestStepResource.make(&"ebb", Kind.EVENT, EVENT_TIDE_EBB, "Ring the tide-bell at North Quay and wait for the sea to fall", 1, ActOnePlaces.NORTH_QUAY),
		QuestStepResource.make(&"waves", Kind.EVENT, EVENT_EBB_WAVES_HELD, "Hold the Old Quay against the tide's kin", 1, ActOnePlaces.OLD_QUAY_EBB_SHELF),
		QuestStepResource.make(&"bells", Kind.EVENT, EVENT_BELL_CHAIN_RUNG, "Ring the three sea-lock bells: deep, then warm, then bright", 1, ActOnePlaces.OLD_QUAY_EBB_SHELF),
		QuestStepResource.make(&"tongue", Kind.ITEM, RELIC_BRONZE_CARILLON_TONGUE, "Carry the Bronze Carillon Tongue out of the vault", 1, ActOnePlaces.OLD_QUAY_EBB_SHELF),
	], [UNLOCK_TIDAL_HOROLOGIUM])
	# Q05 · Tolkien and Le Guin: free the Stag, say its name, and find the star in the cake.
	_add(Q05, 5, "The Root-Sanctum & The Star in the Cake", "Act I Capstone Dungeon: The Root-Sanctum & The Star in the Cake", 5, 6,
		"Tolkien: the lent Fay-Star · Le Guin: True Naming", Q04, [
		QuestStepResource.make(&"descend", Kind.EVENT, EVENT_SANCTUM_ENTERED, "Go down into the Root-Sanctum under the Elder Oak", 1, ActOnePlaces.DUNGEON_ROOT_SANCTUM),
		QuestStepResource.make(&"chambers", Kind.EVENT, EVENT_CHAMBER_CLEARED, "Clear the Sanctum's three root-chambers", 3, ActOnePlaces.DUNGEON_ROOT_SANCTUM),
		QuestStepResource.make(&"stag", Kind.BOSS_OUTCOME, BOSS_TAPROOT_STAG, "Break the Taproot Stag's four chains and name it together", 1, ActOnePlaces.DUNGEON_ROOT_SANCTUM),
		QuestStepResource.make(&"feast", Kind.EVENT, EVENT_FEAST_COMPLETE, "Come to the Great Autumn Feast on Bramblebridge Green", 1, ActOnePlaces.HEARTHSTEAD_MARKET),
	], [UNLOCK_FAY_STAR_SEAL, UNLOCK_CAUSEWAYS])


static func _add(quest_id: StringName, number: int, title: String, full_title: String, from_level: int, to_level: int, counsel: String,
		requires: StringName, steps: Array[QuestStepResource], unlocks: Array[StringName]) -> void:
	var row: Array = LEDGER[number - 1]
	var made: QuestDefinition = QuestDefinition.new()
	made.quest_id = quest_id
	made.number = number
	made.title = title
	made.full_title = full_title
	made.zone_id = ActOnePlaces.ZONE_EMBERSHORE
	made.act = 1
	made.level_from = from_level
	made.level_to = to_level
	made.xp_reward = int(row[4])
	made.cumulative_xp = int(row[5])
	made.counsel = counsel
	made.requires = requires
	made.steps = steps
	made.unlocks = unlocks
	_quests[quest_id] = made
