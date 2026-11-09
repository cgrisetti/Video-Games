## The quest screens' shared words and sums (the talk box, the quest tracker, the quest
## book and the quest-complete card): every quest's story in a young player's words, who
## asked for it, what it gives in plain words, and where the step under way happens from
## a hero's point of view ("The Orchard Gate · 42 m · to your right"), so the four screens
## always say the same thing the same way.
class_name QuestKit
extends RefCounted

## Inside a place's reach reads "You're here!"; under this many metres reads "close by".
const CLOSE_BY: float = 25.0
## The words for a direction, by how far it turns from straight ahead.
const AHEAD_WITHIN: float = 0.45
const BEHIND_PAST: float = 2.4

## What each quest is about, said to an 8-year-old (docs/28's story, in the living-room words).
const STORIES: Dictionary = {
	ActOneQuests.Q01: "The edges of the orchard have gone grey! Master Alf-Wright needs you to calm the Bramble-Hounds and bring the colour back.",
	ActOneQuests.Q02: "Reeve Nokes wants the grey trees chopped down. Dame Tenar-Moss says save them! Clear the bugs from four groves and wake each tree's shrine.",
	ActOneQuests.Q03: "The mill has gone quiet and Miller Hob has gone grey. Calm the thieves in his granary, face the Furrow Iron-Man together, and warm Hob's cold hearth.",
	ActOneQuests.Q04: "The quay bell has lost its tongue, and it is locked in a vault under the sea. Ring the tide out, guard the Old Quay, then ring three bells in the right order.",
	ActOneQuests.Q05: "Grey mist pours from the Elder Oak's roots. Go down into the Root-Sanctum, free the Taproot Stag, then come home for the Great Autumn Feast!",
}
## Who sets each quest going (the townsperson the book shows beside it).
const GIVERS: Dictionary = {
	ActOneQuests.Q01: "Master Alf-Wright",
	ActOneQuests.Q02: "Dame Tenar-Moss",
	ActOneQuests.Q03: "Miller Hob",
	ActOneQuests.Q04: "Master Alf-Wright",
	ActOneQuests.Q05: "Reeve Nokes",
}
## What each thing a quest opens is, in plain words.
const GIFTS: Dictionary = {
	ActOneQuests.UNLOCK_STARTER_WEAPON: "A stick and a buckler",
	ActOneQuests.UNLOCK_CALMING_SEAL: "The Calming Seal card",
	ActOneQuests.UNLOCK_CARD_FUEL: "Your ink well",
	ActOneQuests.UNLOCK_STEM_SOLO_BASSOON: "A new tune on the green",
	ActOneQuests.UNLOCK_SCRIBE_CRAFTING: "Card-making at Alf-Wright's bench",
	ActOneQuests.UNLOCK_BREACHING_SEAL: "The Breaching Seal card",
	ActOneQuests.UNLOCK_DUAL_SLOT: "Your R diamond",
	ActOneQuests.UNLOCK_HEARTH_WARMTH: "The Hearth-Warmth card",
	ActOneQuests.UNLOCK_TIDAL_HOROLOGIUM: "The tide clock",
	ActOneQuests.UNLOCK_FAY_STAR_SEAL: "The Fay-Star Seal card",
	ActOneQuests.UNLOCK_CAUSEWAYS: "The roads to the other isles",
}


static func story(quest: QuestDefinition) -> String:
	return String(STORIES.get(quest.quest_id, quest.full_title)) if quest != null else ""


static func giver(quest: QuestDefinition) -> String:
	return String(GIVERS.get(quest.quest_id, "")) if quest != null else ""


static func gift_name(unlock_id: StringName) -> String:
	return String(GIFTS.get(unlock_id, String(unlock_id).capitalize()))


## Everything finishing a quest gives, in plain words (its steps' gifts, then its own).
static func gifts(quest: QuestDefinition) -> PackedStringArray:
	var words: PackedStringArray = PackedStringArray()
	if quest == null:
		return words
	for step: QuestStepResource in quest.steps:
		for unlock_id: StringName in step.grants:
			words.append(gift_name(unlock_id))
	for unlock_id: StringName in quest.unlocks:
		words.append(gift_name(unlock_id))
	return words


## "Quest 1 of 5".
static func number_line(quest: QuestDefinition) -> String:
	return "Quest %d of %d" % [quest.number, ActOneQuests.ORDER.size()] if quest != null else ""


## The step's count so far ("3 of 6"), or "" for a step done in one go.
static func progress_line(quest_id: StringName, step: QuestStepResource) -> String:
	if step == null or step.count <= 1 or QuestManager.current == null:
		return ""
	return "%d of %d" % [QuestManager.current.count_of(quest_id), step.count]


## Where `step` happens, seen by `actor`:
##   name     the place's name ("The Orchard Gate"), or "" when it has none
##   here     the hero is standing in it
##   metres   how far (-1 when it can't be told: another isle, or no place)
##   turn     radians from where the camera looks (0 ahead, + right), or NAN
##   words    "42 m · to your right", "You're here!", "On Embershore: sail home"
static func where(actor: ActorBase, step: QuestStepResource) -> Dictionary:
	var found: Dictionary = {"name": "", "here": false, "metres": -1.0, "turn": NAN, "words": ""}
	if step == null or step.place_id == &"" or not ActOnePlaces.has_place(step.place_id):
		return found
	found["name"] = ActOnePlaces.display_name(step.place_id)
	if actor == null or not is_instance_valid(actor) or not actor.is_inside_tree():
		return found
	var level: LevelBase = actor.get_tree().current_scene as LevelBase
	if not CartographyBaker.is_archipelago(level):
		return found
	if CartographyBaker.active_isle(level) != CalderaAtlas.ISLE_EMBERSHORE:
		found["words"] = "On Embershore: sail home"
		return found
	var at: Vector3 = actor.global_position
	if ActOnePlaces.contains(step.place_id, at):
		found["here"] = true
		found["metres"] = 0.0
		found["words"] = "You're here!"
		return found
	var middle: Vector3 = ActOnePlaces.centre(step.place_id)
	var gap: Vector2 = Vector2(middle.x - at.x, middle.z - at.z)
	var metres: float = maxf(0.0, gap.length() - ActOnePlaces.reach(step.place_id) * 0.5)
	found["metres"] = metres
	var view: PlayerCamera = level.camera_for_seat(actor.party_slot + 1)
	var yaw: float = view.yaw if view != null else actor.camera_yaw
	var turn: float = turn_toward(yaw, gap)
	found["turn"] = turn
	var how_far: String = "close by" if metres < CLOSE_BY else "%d m" % int(round(metres))
	found["words"] = "%s · %s" % [how_far, direction_words(turn)]
	return found


## Radians from the camera's look (yaw) to a direction on the ground (x, z): 0 ahead, + right.
static func turn_toward(yaw: float, gap: Vector2) -> float:
	if gap.length_squared() < 0.0001:
		return 0.0
	var ahead: Vector2 = Vector2(-sin(yaw), -cos(yaw))
	var right: Vector2 = Vector2(cos(yaw), -sin(yaw))
	var flat: Vector2 = gap.normalized()
	return atan2(flat.dot(right), flat.dot(ahead))


static func direction_words(turn: float) -> String:
	if absf(turn) <= AHEAD_WITHIN:
		return "straight ahead"
	if absf(turn) >= BEHIND_PAST:
		return "behind you"
	return "to your right" if turn > 0.0 else "to your left"


## The step under way as one plain sentence a townsperson can say ("Here's what to do: ...").
static func what_to_do(actor: ActorBase) -> String:
	var quests: QuestManager = QuestManager.current
	var quest: QuestDefinition = quests.active_quest() if quests != null else null
	var step: QuestStepResource = quests.active_step() if quests != null else null
	if quest == null or step == null:
		return "Nothing needs doing just now. Go and explore!"
	var line: String = "Here's what to do: %s." % step.text
	var counted: String = progress_line(quest.quest_id, step)
	if counted != "":
		line += " You've done %s." % counted
	var spot: Dictionary = where(actor, step)
	if bool(spot["here"]):
		line += " And you're in the right place!"
	elif String(spot["name"]) != "":
		line += " Go to %s. Follow the fireflies!" % spot["name"]
	return line


## Sets the firefly trail toward the step under way for this hero (their HUD's way-marker).
## Returns whether there was somewhere to go.
static func show_the_way(hud: PlayerHUD) -> bool:
	var quests: QuestManager = QuestManager.current
	var step: QuestStepResource = quests.active_step() if quests != null else null
	if hud == null or step == null or not ActOnePlaces.has_place(step.place_id):
		return false
	var middle: Vector3 = ActOnePlaces.centre(step.place_id)
	hud.set_waymarker(ActOnePlaces.display_name(step.place_id), CalderaAtlas.ISLE_EMBERSHORE, Vector2(middle.x, middle.z))
	return true
