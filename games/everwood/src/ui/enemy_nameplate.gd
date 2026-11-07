## An enemy's floating level and danger badge (13_PLAYTEST_KAIZEN_UPDATE_PROMPT.md
## §2.14): "[Lv. 3]", "[Lv. 4 Rare]", "[Lv. 10 Elite]" over its health dots, so
## a family can tell at a glance whether a fight is for them. Its colour is the
## danger to the party at its trail level: grey well below, green below, cream
## about even, amber a few levels above, red far above (with a skull). A Rare,
## Elite or Boss counts as RANK_WEIGHT levels harder. It shows within
## SHOW_RANGE while the enemy stands, the same size on screen near or far (the
## one label WorldLabelStyle leaves its own look); the Options menu's Gameplay
## tab can hide every badge (SettingsManager.badges_shown()). Bosses wear theirs on the
## HUD's boss bar instead (badge_text, danger_color), where their name is.
class_name EnemyNameplate
extends Label3D

enum Danger { TRIVIAL, EASY, EVEN, TOUGH, DEADLY }
const DANGER_NAMES: Array[String] = ["trivial", "easy", "even", "tough", "deadly"]
const DANGER_COLORS: Array[Color] = [Color(0.68, 0.68, 0.68), Color(0.56, 0.9, 0.48), Color(1.0, 0.95, 0.84), Color(1.0, 0.66, 0.24),
	Color(1.0, 0.3, 0.26)]
## Level gaps (enemy minus party, rank included) where each danger starts.
const EASY_FROM: int = -5
const EVEN_FROM: int = -1
const TOUGH_FROM: int = 3
const DEADLY_FROM: int = 6
## How many levels harder each rank fights.
const RANK_WEIGHT: Dictionary[String, int] = {"": 0, "Rare": 1, "Elite": 2, "Boss": 4}
## What a rank key reads as on screen (25 GDD R7: Great-Boggart, never Elite).
const RANK_SHOWN: Dictionary[String, String] = {"Elite": "Great-Boggart"}
const SKULL: String = "☠"
## Metres from a camera past which the badge is gone.
const SHOW_RANGE: float = 40.0
## Metres above the enemy's name (or its health dots, when it shows no name).
const LIFT_OVER_NAME: float = 1.15
const LIFT_OVER_DOTS: float = 0.72
const FONT_SIZE: int = 40
## With fixed_size, about 26 pixels tall on a 900-pixel-high view.
const SCREEN_PIXEL_SIZE: float = 0.0011

var enemy: ActorBase
var level: int = 1
## "", "Rare", "Elite" or "Boss".
var rank: String = ""


## Puts a badge over an enemy (any peer: it reads only what every copy knows).
static func attach(to: ActorBase, name_shown: bool) -> EnemyNameplate:
	var plate: EnemyNameplate = EnemyNameplate.new()
	plate.name = "LevelBadge"
	plate.enemy = to
	plate.level = level_of(to)
	plate.rank = rank_of(to)
	plate.position = Vector3(0.0, to.body_height() + (LIFT_OVER_NAME if name_shown else LIFT_OVER_DOTS), 0.0)
	to.add_child(plate)
	plate.refresh()
	return plate


func _init() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	# The same size on screen near or far (until SHOW_RANGE), so it reads at a glance.
	fixed_size = true
	font_size = FONT_SIZE
	outline_size = 12
	outline_modulate = Color(0.07, 0.05, 0.04, 0.92)
	pixel_size = SCREEN_PIXEL_SIZE
	# Its foot on the anchor, so near or far it grows upward, clear of the health dots.
	vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	visibility_range_begin = WorldLabelStyle.VISIBLE_FROM_M
	visibility_range_end = SHOW_RANGE
	# The world's labels shrink with distance (WorldLabelStyle); this one keeps its size on screen.
	set_meta(WorldLabelStyle.OWN_STYLE_META, true)


func _process(_delta: float) -> void:
	refresh()


## Shows or hides the badge and colours it for the party's level now.
func refresh() -> void:
	if enemy == null or not is_instance_valid(enemy):
		visible = false
		return
	visible = SettingsManager.badges_shown() and enemy.stats != null and not enemy.stats.is_downed
	if not visible:
		return
	var danger: int = danger_for(level, rank, party_level())
	var shown: String = badge_text(level, rank) + (" " + SKULL if danger == Danger.DEADLY else "")
	if text != shown:
		text = shown
	modulate = DANGER_COLORS[danger]


## "[Lv. 10 Great-Boggart]". The rank keys stay the old words; the screen reads R7's (25 GDD).
static func badge_text(enemy_level: int, enemy_rank: String) -> String:
	var shown: String = RANK_SHOWN.get(enemy_rank, enemy_rank)
	return "[Lv. %d%s]" % [enemy_level, (" " + shown) if shown != "" else ""]


static func danger_for(enemy_level: int, enemy_rank: String, at_party_level: int) -> int:
	var gap: int = enemy_level + int(RANK_WEIGHT.get(enemy_rank, 0)) - at_party_level
	if gap >= DEADLY_FROM:
		return Danger.DEADLY
	if gap >= TOUGH_FROM:
		return Danger.TOUGH
	if gap >= EVEN_FROM:
		return Danger.EVEN
	if gap >= EASY_FROM:
		return Danger.EASY
	return Danger.TRIVIAL


static func danger_color(enemy_level: int, enemy_rank: String) -> Color:
	return DANGER_COLORS[danger_for(enemy_level, enemy_rank, party_level())]


static func party_level() -> int:
	return PartyProgress.current.trail_level() if PartyProgress.current != null else 1


## An enemy's level: a creature's own, a camp's minions' camp, else its encounter's.
static func level_of(foe: ActorBase) -> int:
	var mob: WildMob = foe as WildMob
	if mob != null and mob.variant != null:
		return mob.variant.level
	var minion: WoodlandMinion = foe as WoodlandMinion
	if minion != null and minion.camp != null:
		return minion.camp.level
	var encounter: BossEncounterResource = ArsenalCatalog.current.encounter(foe.glimmer_encounter_id()) if ArsenalCatalog.current != null else null
	return encounter.encounter_level if encounter != null else 1


static func rank_of(foe: ActorBase) -> String:
	var mob: WildMob = foe as WildMob
	if mob != null and mob.variant != null:
		match mob.variant.rank:
			MobVariantResource.Rank.RARE:
				return "Rare"
			MobVariantResource.Rank.ELITE:
				return "Elite"
			MobVariantResource.Rank.BOSS:
				return "Boss"
		return ""
	return "Boss" if foe.is_raid_boss() else ""
