## One local player's HUD, drawn over their split-screen cell: the boss's
## health, poise, cast and aggro along the top, and the Cross-Grimoire HUD
## bottom-centre (CrossGrimoireHUD: health, stamina, pips, Chimes and every
## move's slot, readable by shape and colour). A big banner in the middle marks
## moments the whole party shares (a victory, the loot). Next to the
## Chime-Shrine or the Scribe Desk a prompt says what light does, and their
## menus open over this view.
##
## Sign-Flow (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md) adds the Grimoire Binder (a
## tap of Tab / View, out of combat) and the Reed-Light Scribery's counter,
## both over this view, and a boss's Glimmer-Spot rhyme under its frame while
## the party is still learning it.
class_name PlayerHUD
extends Control

## Every PlayerHUD joins this group, so a station can find the one for its player.
const GROUP: StringName = &"player_huds"
const RHYME_COLOR: Color = Color(1.0, 0.86, 0.45)

const MARGIN: float = 14.0
const BOSS_BAR_WIDTH: float = 0.56
const FONT_SIZE: int = 17
const SMALL_FONT_SIZE: int = 13
## Act I's Tidal Horologium (docs/29 §7); the quest tracker is its own page (QuestTracker).
const QUEST_FONT_SIZE: int = 15
## The tide dial's line, as a share of the view's height (under the quest tracker).
const TIDE_DIAL_TOP: float = 0.64
const TIDE_DIAL_COLOR: Color = Color(0.7, 0.88, 1.0)
## The tide dial shows within this of North Quay (docs/28 §6.5: 300 m of the quays).
const TIDE_DIAL_REACH: float = 300.0
const HEALTH_COLOR: Color = Color(0.85, 0.22, 0.24)
const POISE_COLOR: Color = Color(0.95, 0.65, 0.25)
const CAST_COLOR: Color = Color(0.75, 0.55, 1.0)
## The Gale-Beam's callout, in the beam's blue.
const CALLOUT_COLOR: Color = Color(0.62, 0.82, 1.0)
const CALLOUT_SIZE: int = 24
const BAR_BACK: Color = Color(0.06, 0.06, 0.08, 0.75)
## The boss's bars show once it's in the fight or within this many metres.
const BOSS_BAR_RANGE: float = 36.0
## Room left for the level's banner when this cell touches the top of the screen.
const BANNER_CLEARANCE: float = 52.0
const FLASH_TIME: float = 0.6
const BANNER_TITLE_SIZE: int = 44
## Pixels between the boss frame and a banner moved down under it.
const BANNER_GAP: float = 8.0
## Real seconds for the banner to fade in (it ignores slow motion).
const BANNER_FADE_TIME: float = 0.3
## A new trail level's banner, in the Wayfarer Pennant's Saffron-Gold.
const MILESTONE_COLOR: Color = Color(0.98, 0.72, 0.18)
const MILESTONE_BANNER_TIME: float = 3.0
## How long a banner that waited for the quest-complete card stays up.
const BANNER_AFTER_CARD_TIME: float = 4.5

var actor: ActorBase
## The bottom-centre cross of move slots and gauges.
var cross_grimoire: CrossGrimoireHUD

var _top_panel: VBoxContainer
var _boss_label: Label
var _boss_health: ProgressBar
var _boss_poise: ProgressBar
var _cast_bar: ProgressBar
var _cast_label: Label
var _callout_label: Label
var _aggro_label: Label
var _flow_label: Label
var _banner: VBoxContainer
var _banner_title: Label
var _banner_subtitle: Label
var _prompt_label: Label
## Act I (docs/29 §7): the quest tracker (QuestTracker, right of the view), and the Tidal Horologium once Q04 opens it.
var quest_tracker: QuestTracker
var _tide_label: Label
## The "QUEST COMPLETE!" card while it's up, and the banners waiting for it to go.
var _quest_card: QuestCompleteCard
var _waiting_banners: Array[Array] = []
## The menu open over this view (the Chime-Shrine's or the Scribe Desk's).
var _menu: Control
var _flow_flash_left: float = 0.0
var _rhyme_label: Label
var _rhyme_left: float = 0.0
## The Nursery Rhyme Diagnostic Ribbon's Sign badges (14 GDD §8): one per Sign that cracks the spot now.
var _rhyme_badges: HBoxContainer
## The Wayfarer's minimap, top-right (18 GDD §7.2).
var minimap: WayfarerMinimapWidget
## The place pinned on the Atlas (x, z), and the firefly trail leading there (18 GDD §7.3).
var pinned_target_xz: Vector2 = Vector2.INF
var trail_guide: WayfarerTrailGuideFX
## The way-marker set on the map: {"label", "isle", "local", "via"} ({} for none).
var waymarker: Dictionary = {}


func setup(target_actor: ActorBase) -> void:
	actor = target_actor


func _ready() -> void:
	name = "PlayerHUD"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A deck card found in play springs up on every player's screen (CardReveal, 25 GDD §7).
	if PartyProgress.current != null:
		PartyProgress.current.card_awarded.connect(_on_card_awarded)

	var top: VBoxContainer = VBoxContainer.new()
	top.anchor_left = 0.5 - BOSS_BAR_WIDTH * 0.5
	top.anchor_right = 0.5 + BOSS_BAR_WIDTH * 0.5
	top.offset_top = MARGIN
	top.add_theme_constant_override(&"separation", 3)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	_top_panel = top
	_boss_label = _label(FONT_SIZE)
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_boss_label)
	_boss_health = _bar(HEALTH_COLOR, 14.0)
	top.add_child(_boss_health)
	_boss_poise = _bar(POISE_COLOR, 5.0)
	top.add_child(_boss_poise)
	_cast_label = _label(SMALL_FONT_SIZE)
	_cast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_cast_label)
	_cast_bar = _bar(CAST_COLOR, 8.0)
	top.add_child(_cast_bar)
	_aggro_label = _label(SMALL_FONT_SIZE)
	_aggro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_aggro_label)
	# What to do about the Gale-Beam, on screen under the boss frame (a sign in
	# the world would sit right on the frame from a camera behind the party).
	_callout_label = _label(CALLOUT_SIZE)
	_callout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_callout_label.modulate = CALLOUT_COLOR
	_callout_label.visible = false
	top.add_child(_callout_label)
	# A Glimmer-Spot's rhyme (14 GDD §3), on the first sightings only.
	_rhyme_label = _label(CALLOUT_SIZE - 4)
	_rhyme_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rhyme_label.modulate = RHYME_COLOR
	_rhyme_label.visible = false
	top.add_child(_rhyme_label)
	_rhyme_badges = HBoxContainer.new()
	_rhyme_badges.name = "RhymeBadges"
	_rhyme_badges.alignment = BoxContainer.ALIGNMENT_CENTER
	_rhyme_badges.add_theme_constant_override(&"separation", 14)
	_rhyme_badges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rhyme_badges.visible = false
	top.add_child(_rhyme_badges)

	cross_grimoire = CrossGrimoireHUD.new()
	cross_grimoire.setup(actor)
	add_child(cross_grimoire)

	minimap = WayfarerMinimapWidget.new()
	minimap.setup(actor, _level())
	add_child(minimap)
	if _level() != null and not _level().wants_minimap():
		# The Caldera Isles navigate by landmarks alone (the Musk Razor): no minimap there.
		minimap.visible = false
		minimap.process_mode = Node.PROCESS_MODE_DISABLED

	# "FLOW" pops up mid-screen when a buffered follow-up skips the recovery.
	_flow_label = _label(30)
	_flow_label.anchor_left = 0.5
	_flow_label.anchor_right = 0.5
	_flow_label.anchor_top = 0.42
	_flow_label.anchor_bottom = 0.42
	_flow_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_flow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flow_label.modulate = Color(0.6, 0.85, 1.0, 0.0)
	add_child(_flow_label)

	_banner = VBoxContainer.new()
	_banner.name = "Banner"
	_banner.anchor_left = 0.06
	_banner.anchor_right = 0.94
	_banner.anchor_top = 0.2
	_banner.anchor_bottom = 0.2
	_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	_banner.alignment = BoxContainer.ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	add_child(_banner)
	_banner_title = _label(BANNER_TITLE_SIZE)
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_title)
	_banner_subtitle = _label(FONT_SIZE)
	_banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.add_child(_banner_subtitle)

	_prompt_label = _label(FONT_SIZE)
	_prompt_label.anchor_left = 0.5
	_prompt_label.anchor_right = 0.5
	_prompt_label.anchor_top = 0.52
	_prompt_label.anchor_bottom = 0.52
	_prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.modulate = Color(0.75, 0.9, 1.0)
	_prompt_label.visible = false
	add_child(_prompt_label)
	quest_tracker = QuestTracker.new()
	quest_tracker.setup(actor, self)
	quest_tracker.quest_finished.connect(show_quest_complete)
	add_child(quest_tracker)
	_tide_label = _label(QUEST_FONT_SIZE)
	_tide_label.name = "TidalHorologium"
	_tide_label.anchor_left = 1.0
	_tide_label.anchor_right = 1.0
	_tide_label.anchor_top = TIDE_DIAL_TOP
	_tide_label.anchor_bottom = TIDE_DIAL_TOP
	_tide_label.offset_right = -MARGIN
	_tide_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_tide_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tide_label.modulate = TIDE_DIAL_COLOR
	_tide_label.visible = false
	add_child(_tide_label)
	if actor != null:
		actor.action_queue.flow_cancelled.connect(_on_flow_cancelled)
		actor.action_queue.flow_link_pulsed.connect(_on_flow_link_pulsed)
		if actor.input != null:
			actor.input.binder_requested.connect(toggle_binder)
			actor.input.atlas_requested.connect(toggle_atlas)
			actor.input.options_requested.connect(toggle_options)
			actor.input.dev_tools_requested.connect(toggle_dev_tools)
			actor.input.quest_book_requested.connect(toggle_quest_book)
	add_to_group(GROUP)
	CombatDirector.current.glimmer_opened.connect(_on_glimmer_opened)
	CombatDirector.current.bravery_countered.connect(_on_bravery_countered)


func _exit_tree() -> void:
	clear_pin()
	if PartyProgress.current != null and PartyProgress.current.card_awarded.is_connected(_on_card_awarded):
		PartyProgress.current.card_awarded.disconnect(_on_card_awarded)
	var director: CombatDirector = CombatDirector.current
	if director != null and director.glimmer_opened.is_connected(_on_glimmer_opened):
		director.glimmer_opened.disconnect(_on_glimmer_opened)
		director.bravery_countered.disconnect(_on_bravery_countered)



## A card just came into the binder: a deck card gets its "A NEW CARD!" reveal on this screen.
func _on_card_awarded(copy_key: StringName) -> void:
	if not ArsenalCatalog.INK_DECK.has(ScribeCardResource.copy_card_id(copy_key)):
		return
	var reveal: CardReveal = CardReveal.new()
	reveal.setup(copy_key)
	add_child(reveal)


## The newest "A NEW CARD!" reveal on this screen, or null.
func card_reveal() -> CardReveal:
	for child: Node in get_children():
		if child is CardReveal and not child.is_queued_for_deletion():
			return child as CardReveal
	return null


## The place this hero just walked into (15_THE_MYTHOPOETIC_LENS.md §6.2): crossing
## into another zone of the atlas unfurls that zone's rhyme on the Chime-Post
## ribbon (with `unfurl`), and a Hearth-Rite Tuck there sings it again.
func enter_place(place: String, unfurl: bool = true) -> void:
	var zone_id: StringName = MythopoeticAtlas.zone_for_place(place)
	if zone_id == &"" or cross_grimoire == null or zone_id == cross_grimoire.ribbon_zone_id:
		return
	cross_grimoire.show_rhyme_ribbon(zone_id, unfurl)

## The HUD drawn for `target` (a local player), or null.
static func for_actor(tree: SceneTree, target: ActorBase) -> PlayerHUD:
	for node: Node in tree.get_nodes_in_group(GROUP):
		var hud: PlayerHUD = node as PlayerHUD
		if hud != null and hud.actor == target:
			return hud
	return null


func _process(delta: float) -> void:
	if not is_instance_valid(actor) or actor.stats == null:
		return
	# A way-marker finds its way again on a new island.
	if not waymarker.is_empty() and waymarker.get("routed_on", &"") != CartographyBaker.active_isle(_level()):
		_route_waymarker()
	_rhyme_left = maxf(0.0, _rhyme_left - delta)
	_rhyme_label.visible = _rhyme_left > 0.0
	_rhyme_badges.visible = _rhyme_left > 0.0 and _rhyme_badges.get_child_count() > 0
	_top_panel.offset_top = MARGIN + (BANNER_CLEARANCE if get_global_rect().position.y < 1.0 else 0.0)
	_refresh_boss()
	_place_banner()
	_refresh_player()
	_refresh_quest()


## The quest tracker (the step under way) and, on Embershore near the quays once Q04 has
## opened it, the Tidal Horologium's tide line.
func _refresh_quest() -> void:
	var quests: QuestManager = QuestManager.current
	# The tracker stays up beside a talk (the talk is usually about the quest); other menus cover it.
	quest_tracker.visible = quests != null and quests.active_quest_id() != &"" and (_live_menu() == null or _live_menu() is TalkBox)
	# The diamonds step aside under the talk box and the quest book (they sit over play, not in a full-screen book).
	cross_grimoire.visible = not (_live_menu() is TalkBox or _live_menu() is QuestBook)
	var dial: bool = quests != null and (quests.has_unlock(ActOneQuests.UNLOCK_TIDAL_HOROLOGIUM) or quests.active_quest_id() == ActOneQuests.Q04)
	dial = dial and CalderaWorldState.current != null and _level() is CalderaArchipelagoWorld \
		and CartographyBaker.active_isle(_level()) == CalderaAtlas.ISLE_EMBERSHORE \
		and Vector2(actor.global_position.x - ActOnePlaces.centre(ActOnePlaces.NORTH_QUAY).x, actor.global_position.z - ActOnePlaces.centre(ActOnePlaces.NORTH_QUAY).z).length() <= TIDE_DIAL_REACH
	_tide_label.visible = dial and _live_menu() == null
	if _tide_label.visible:
		_tide_label.text = "⌛ " + CalderaWorldState.current.tide_dial_text()


## The quest tracker's text, or "" when it's hidden.
func quest_text() -> String:
	return "\n".join(quest_tracker.lines()) if quest_tracker.visible else ""


# --- Talking and quests (TalkBox, QuestBook, QuestCompleteCard) --------------------------------

## Opens the talk box with a townsperson along the bottom of this hero's view (never mid-fight).
func open_talk(npc: EverwoodNPC) -> bool:
	if _live_menu() != null or actor == null or npc == null:
		return false
	if actor.sign_flow != null and actor.sign_flow.is_in_combat:
		AudioCues.play(&"refuse")
		show_banner("NOT MID-FIGHT", "Calm things down first, then talk.", Color(1.0, 0.6, 0.45), 1.5)
		return false
	var talk: TalkBox = TalkBox.new()
	talk.setup(actor, npc, self)
	_menu = talk
	add_child(talk)
	return true


func talk_box() -> TalkBox:
	return _live_menu() as TalkBox


## B (or Share and D-Pad ↓): the quest book opens out of combat and closes again.
func toggle_quest_book() -> void:
	if quest_book() != null:
		quest_book().close()
	else:
		open_quest_book()


## Opens the quest book down the left of this hero's view. Returns whether it opened.
func open_quest_book() -> bool:
	if _live_menu() != null or actor == null:
		return false
	if actor.sign_flow != null and actor.sign_flow.is_in_combat:
		AudioCues.play(&"refuse")
		show_banner("NOT MID-FIGHT", "The quest book opens once the fight is over.", Color(1.0, 0.6, 0.45), 1.5)
		return false
	var book: QuestBook = QuestBook.new()
	book.setup(actor, self)
	_menu = book
	add_child(book)
	AudioCues.play(&"menu_move", 0.8)
	return true


func quest_book() -> QuestBook:
	return _live_menu() as QuestBook


## The "QUEST COMPLETE!" card for a quest just finished. A banner already up waits under it
## (a level's banner is dropped: the card says the level itself).
func show_quest_complete(quest_id: StringName) -> void:
	if is_instance_valid(_quest_card):
		_quest_card.dismiss()
	if _banner.visible and not _banner_title.text.begins_with("LEVEL "):
		_waiting_banners.push_front([_banner_title.text, _banner_subtitle.text, _banner_title.modulate, BANNER_AFTER_CARD_TIME])
	_banner.visible = false
	_quest_card = QuestCompleteCard.new()
	_quest_card.setup(quest_id)
	_quest_card.finished.connect(_show_waiting_banner)
	add_child(_quest_card)


func quest_complete_card() -> QuestCompleteCard:
	return _quest_card if is_instance_valid(_quest_card) and not _quest_card.is_queued_for_deletion() else null


## A film has let this player go (docs/31): the banners that waited for it come up.
func film_released() -> void:
	if quest_complete_card() == null and not _held_by_film():
		_show_waiting_banner()


func _held_by_film() -> bool:
	return is_instance_valid(actor) and actor.input != null and actor.input.cinematic_hold


## The card has gone: the banners that waited for it come up one after another.
func _show_waiting_banner() -> void:
	_quest_card = null
	if _waiting_banners.is_empty() or not is_inside_tree():
		return
	var next: Array = _waiting_banners.pop_front()
	var seconds: float = float(next[3]) if float(next[3]) > 0.0 else BANNER_AFTER_CARD_TIME
	show_banner(String(next[0]), String(next[1]), next[2] as Color, seconds)
	if not _waiting_banners.is_empty():
		get_tree().create_timer(seconds, true, false, true).timeout.connect(_show_waiting_banner)


## The Tidal Horologium's text, or "" when it's hidden.
func tide_text() -> String:
	return _tide_label.text if _tide_label.visible else ""


## Opens the Chime-Shrine's upgrade menu over this player's view.
func open_upgrade_menu() -> void:
	if _live_menu() != null:
		return
	var menu: HubUpgradeMenu = HubUpgradeMenu.new()
	menu.setup(actor)
	_menu = menu
	add_child(menu)


## Opens the Armory & Scribe Desk menu over this player's view (`row`: where its cursor starts).
func open_scribe_desk(row: int = -1) -> void:
	if _live_menu() != null:
		return
	var menu: ScribeDeskMenu = ScribeDeskMenu.new()
	menu.setup(actor, row)
	_menu = menu
	add_child(menu)


## The Grimoire Binder: a tap of Tab / View opens it out of combat and closes it again.
func toggle_binder() -> void:
	if binder_panel() != null:
		binder_panel().close()
	else:
		open_binder()


## Opens the Grimoire Binder over this player's view (never mid-fight). Returns whether it opened.
func open_binder() -> bool:
	if _live_menu() != null:
		return false
	if actor.sign_flow != null and actor.sign_flow.is_in_combat:
		AudioCues.play(&"refuse")
		show_banner("NOT MID-FIGHT", "The Grimoire Binder opens once the fight is over.", Color(1.0, 0.6, 0.45), 1.5)
		return false
	var binder: GrimoireBinderPanel = GrimoireBinderPanel.new()
	binder.setup(actor)
	_menu = binder
	add_child(binder)
	return true


## The Wayfarer's Atlas: a tap of M / R3 opens it out of combat and closes it
## again; inside the Grimoire Binder it turns to the Binder's "Atlas Map" tab.
func toggle_atlas() -> void:
	if binder_panel() != null:
		binder_panel().toggle_atlas_tab()
	elif atlas_panel() != null:
		atlas_panel().close()
	else:
		open_atlas()


## Opens the Atlas over this player's view (never mid-fight). Returns whether it opened.
func open_atlas() -> bool:
	if _live_menu() != null or actor == null:
		return false
	if actor.sign_flow != null and actor.sign_flow.is_in_combat:
		AudioCues.play(&"refuse")
		show_banner("NOT MID-FIGHT", "The Atlas unrolls once the fight is over.", Color(1.0, 0.6, 0.45), 1.5)
		return false
	var atlas: WorldMapPanel = WorldMapPanel.new()
	atlas.setup(actor, _level(), self)
	_menu = atlas
	add_child(atlas)
	return true


func atlas_panel() -> WorldMapPanel:
	return _live_menu() as WorldMapPanel


## The map panel open over this player's view (the same as atlas_panel()), or null.
func map_panel() -> WorldMapPanel:
	return atlas_panel()


## Esc or Options: opens the Options menu, or closes it; over any other menu it
## closes that menu instead (the one "back" every player knows, 13_PLAYTEST §2.1).
func toggle_options() -> void:
	var open: Control = _live_menu()
	if open is OptionsMenu:
		(open as OptionsMenu).close()
	elif open != null:
		close_menu()
	else:
		open_options()


## Opens the Options menu over this player's view (in a fight too: it's the player's pause).
func open_options() -> bool:
	if _live_menu() != null or actor == null:
		return false
	var options: OptionsMenu = OptionsMenu.new()
	options.setup(actor)
	_menu = options
	add_child(options)
	return true


func options_menu() -> OptionsMenu:
	return _live_menu() as OptionsMenu


## F1, or Share held and D-Pad ↑: the Developer Tools (13_PLAYTEST §2.13), a
## panel of their own apart from the Binder and the Options menu. Over another
## menu it closes that one and opens the tools.
func toggle_dev_tools() -> void:
	var open: Control = _live_menu()
	if open is DevAdminPanel:
		(open as DevAdminPanel).close()
		return
	if open != null:
		close_menu()
	open_dev_tools()


func open_dev_tools() -> bool:
	if _live_menu() != null or actor == null:
		return false
	var tools: DevAdminPanel = DevAdminPanel.new()
	tools.setup(actor, _level())
	_menu = tools
	add_child(tools)
	return true


func dev_tools_panel() -> DevAdminPanel:
	return _live_menu() as DevAdminPanel


## Closes whatever menu is open over this player's view.
func close_menu() -> void:
	var open: Control = _live_menu()
	if open == null:
		return
	if open.has_method(&"close"):
		open.call(&"close")
	else:
		open.queue_free()
		if actor != null and actor.input != null:
			actor.input.menu_open = false


## Sets the way-marker (13_PLAYTEST §2.5): `label` on the map, at `local` in
## island `isle`'s frame (or the level's, with no island). A firefly trail leads
## there, by way of the crossing toward that island if it's another one, and
## finds the way again whenever the party reaches a new island.
func set_waymarker(label: String, isle: StringName, local: Vector2) -> void:
	waymarker = {"label": label, "isle": isle, "local": local, "via": ""}
	_route_waymarker()


func has_waymarker() -> bool:
	return not waymarker.is_empty()


func clear_waymarker() -> void:
	waymarker = {}
	clear_pin()


func _route_waymarker() -> void:
	var level: LevelBase = _level()
	if waymarker.is_empty() or level == null:
		return
	var route: Dictionary = CartographyBaker.route_to(level, waymarker.get("isle", &""), waymarker["local"])
	waymarker["via"] = route["via"]
	waymarker["routed_on"] = CartographyBaker.active_isle(level)
	set_pin(route["target"])


## Pins a place (x, z): a firefly trail leads this hero there, until they arrive.
func set_pin(target_xz: Vector2) -> void:
	clear_pin()
	pinned_target_xz = target_xz
	if actor == null or not actor.is_inside_tree():
		return
	trail_guide = WayfarerTrailGuideFX.new()
	trail_guide.setup(actor, target_xz, WayfarerMinimapWidget.SEAT_COLORS[clampi(actor.party_slot, 0, WayfarerMinimapWidget.SEAT_COLORS.size() - 1)])
	trail_guide.arrived.connect(_on_trail_arrived)
	var holder: Node = CombatDirector.current.effects_root if is_instance_valid(CombatDirector.current.effects_root) else actor.get_parent()
	holder.add_child(trail_guide)


func clear_pin() -> void:
	pinned_target_xz = Vector2.INF
	if is_instance_valid(trail_guide):
		trail_guide.queue_free()
	trail_guide = null


func has_pin() -> bool:
	return pinned_target_xz.is_finite()


func _on_trail_arrived() -> void:
	pinned_target_xz = Vector2.INF
	trail_guide = null
	var via: String = String(waymarker.get("via", ""))
	if via != "":
		# At the crossing: the trail picks up again on the far shore.
		show_banner("THE CROSSING", "Take %s on toward %s." % [via, waymarker.get("label", "")], WayfarerMinimapWidget.SAFFRON_GOLD, 2.0)
		return
	waymarker = {}
	show_banner("ARRIVED", "The fireflies settle: you're there.", WayfarerMinimapWidget.SAFFRON_GOLD, 1.5)


func _level() -> LevelBase:
	var at: Node = get_parent()
	while at != null:
		if at is LevelBase:
			return at as LevelBase
		at = at.get_parent()
	return get_tree().current_scene as LevelBase if is_inside_tree() else null


## Opens the Reed-Light Scribery's counter over this player's view.
func open_scribery_shop() -> void:
	if _live_menu() != null:
		return
	var shop: ScriberyShopPanel = ScriberyShopPanel.new()
	shop.setup(actor)
	_menu = shop
	add_child(shop)


func binder_panel() -> GrimoireBinderPanel:
	return _live_menu() as GrimoireBinderPanel


func scribery_panel() -> ScriberyShopPanel:
	return _live_menu() as ScriberyShopPanel


## The Glimmer-Spot rhyme under the boss frame ("" when none is showing).
func rhyme_text() -> String:
	return _rhyme_label.text if _rhyme_left > 0.0 else ""


## The Sign badges under the rhyme ("◆ Iron-Root"), empty when none is showing.
func rhyme_badges() -> PackedStringArray:
	var badges: PackedStringArray = PackedStringArray()
	if _rhyme_left <= 0.0:
		return badges
	for child: Node in _rhyme_badges.get_children():
		var badge: Label = child as Label
		if badge != null and not badge.is_queued_for_deletion():
			badges.append(badge.text)
	return badges


## A foe near this player opened its Glimmer-Spot: its rhyme shows while it's
## open, if the party still needs it (a new opening replaces the last one's).
func _on_glimmer_opened(enemy: ActorBase, seconds: float, rhyme: String) -> void:
	if not is_instance_valid(actor) or enemy.global_position.distance_to(actor.global_position) > BOSS_BAR_RANGE:
		return
	_rhyme_label.text = rhyme
	_rhyme_left = seconds if rhyme != "" else 0.0
	# Each Sign that cracks it now (a four-gate boss's shifts with its gate) as a coloured badge.
	for child: Node in _rhyme_badges.get_children():
		_rhyme_badges.remove_child(child)
		child.queue_free()
	if rhyme != "" and enemy.glimmer != null:
		for scribe_sign: int in enemy.glimmer.active_weakness():
			var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(scribe_sign)
			var badge: Label = _label(SMALL_FONT_SIZE + 3)
			badge.text = "◆ %s" % seal.display_name
			badge.modulate = seal.color
			_rhyme_badges.add_child(badge)


## A Bravery Counter cracked the spot: the coaching is done.
func _on_bravery_countered(_target: ActorBase, _scribe_sign: int, _label: String) -> void:
	_rhyme_left = 0.0


## The boss's bars are up (it's in the fight, or near).
func boss_bar_visible() -> bool:
	return _top_panel.visible


## The Gale-Beam's callout under the boss frame ("" when there's none).
func callout() -> String:
	return _callout_label.text if _top_panel.visible and _callout_label.visible else ""


func upgrade_menu() -> HubUpgradeMenu:
	return _live_menu() as HubUpgradeMenu


func scribe_desk_menu() -> ScribeDeskMenu:
	return _live_menu() as ScribeDeskMenu


func _live_menu() -> Control:
	return _menu if is_instance_valid(_menu) and not _menu.is_queued_for_deletion() else null


## What pressing light does here, or "" when there's nothing to use.
func prompt_text() -> String:
	return _prompt_label.text if _prompt_label.visible else ""


## A big centred message for the whole party, like VICTORY! It stays up until
## another replaces it, or for `seconds` (real time) when that's above zero.
func show_banner(title: String, subtitle: String, color: Color, seconds: float = 0.0) -> void:
	# A banner that arrives while a film holds this player (docs/31) waits for the film's end too.
	if quest_complete_card() != null or _held_by_film():
		_waiting_banners.append([title, subtitle, color, seconds])
		return
	_banner_title.text = title
	_banner_title.modulate = color
	_banner_subtitle.text = subtitle
	_banner.visible = true
	_banner.modulate.a = 0.0
	var fade: Tween = create_tween()
	fade.set_ignore_time_scale(true)
	fade.tween_property(_banner, "modulate:a", 1.0, BANNER_FADE_TIME)
	if seconds > 0.0:
		var timer: SceneTreeTimer = get_tree().create_timer(seconds, true, false, true)
		timer.timeout.connect(_hide_banner_if.bind(title))


## Hides the banner if it still shows `title` (a newer one stays up).
## A banner's centre sits a fifth of the way down the view, or just under the
## boss frame while that shows, so neither hides the other.
func _place_banner() -> void:
	var shift: float = 0.0
	if _top_panel.visible:
		var frame_bottom: float = _top_panel.offset_top + _top_panel.size.y
		shift = maxf(0.0, frame_bottom + BANNER_GAP + _banner.size.y * 0.5 - size.y * 0.2)
	_banner.offset_top = shift
	_banner.offset_bottom = shift


func _hide_banner_if(title: String) -> void:
	if is_instance_valid(_banner) and _banner.visible and _banner_title.text == title:
		_banner.visible = false


func hide_banner() -> void:
	_banner.visible = false


## The banner's title, or "" when it's hidden.
func banner_title() -> String:
	return _banner_title.text if _banner.visible else ""


func _refresh_boss() -> void:
	var boss: BossDummy = CombatDirector.current.primary_boss() as BossDummy
	# No boss here (Bramble-Bridge), it's beaten, or it's still zones away: no bars to show.
	_top_panel.visible = boss != null and boss.stats != null and not boss.vanquished \
		and (boss.engaged or boss.global_position.distance_to(actor.global_position) <= BOSS_BAR_RANGE)
	if not _top_panel.visible:
		return
	var primer: int = CombatDirector.current.primer_on(boss)
	var title: String = boss.display_name()
	if boss.stats.is_downed:
		title += " (defeated)"
	elif boss.stats.is_knocked_down():
		title += " (KNOCKED DOWN)"
	if primer != ScribeSignResource.Sign.NONE:
		title += "  ·  %s seal" % ArsenalCatalog.current.sign_seal(primer).seal_name
	# Its level and danger before its name (13_PLAYTEST §2.14), unless the Options menu hides badges.
	if SettingsManager.badges_shown():
		var level: int = EnemyNameplate.level_of(boss)
		title = "%s  %s" % [EnemyNameplate.badge_text(level, "Boss"), title]
		_boss_label.modulate = EnemyNameplate.danger_color(level, "Boss").lerp(Color.WHITE, 0.35)
	else:
		_boss_label.modulate = Color.WHITE
	_boss_label.text = title
	_boss_health.max_value = boss.stats.stats.max_health
	_boss_health.value = boss.stats.health
	_boss_poise.max_value = boss.stats.stats.max_poise
	_boss_poise.value = boss.stats.poise
	var casting: bool = boss.is_casting()
	_cast_bar.visible = casting
	_cast_label.visible = casting
	if casting:
		_cast_label.text = "Casting %s" % boss.cast_name
	var beam: RaidTelegraphDecal = CombatDirector.current.beam_telegraph()
	_callout_label.visible = beam != null
	if beam != null:
		_callout_label.text = "RAISE SHADOW SANCTUARY!" if beam.follow_target == actor else "STAND BEHIND THE TANK!"
		_cast_bar.max_value = 1.0
		_cast_bar.value = boss.cast_progress()
	var target_id: StringName = boss.threat.current_target if boss.threat != null else &""
	if target_id == &"":
		_aggro_label.text = "Walk up to the Cairnsman to start the fight"
		_aggro_label.modulate = Color.WHITE
	elif target_id == actor.player_id:
		_aggro_label.text = "Eyes on: YOU" + ("" if actor.role() == ClassLoadoutResource.Role.TANK else "  (let the tank taunt it back)")
		_aggro_label.modulate = Color(1.0, 0.55, 0.45)
	else:
		var holder: ActorBase = CombatDirector.current.get_actor(target_id)
		_aggro_label.text = "Eyes on: %s" % (holder.display_name() if holder != null else String(target_id))
		_aggro_label.modulate = Color(0.85, 0.9, 1.0)


func _refresh_player() -> void:
	_prompt_label.visible = is_instance_valid(actor.interactable) and _live_menu() == null
	if _prompt_label.visible:
		_prompt_label.text = actor.interactable.prompt_for(actor)
	_refresh_flashes()


func _on_flow_cancelled(_from: CombatActionResource, _to: CombatActionResource) -> void:
	_flow_flash_left = FLASH_TIME
	var bonus: float = actor.action_queue.speed_scale - 1.0
	_flow_label.text = "FLOW  +%d%% speed" % roundi(bonus * 100.0) if bonus > 0.0 else "FLOW"


## A Flow-Link Pulse: the flow pop says what it gave back.
func _on_flow_link_pulsed(_from: CombatActionResource, _to_command: int) -> void:
	_flow_flash_left = FLASH_TIME
	_flow_label.text = "FLOW-LINK!  +%d stamina" % roundi(ActorBase.FLOW_LINK_STAMINA_REFUND)


## A new trail level (11 GDD §6): a short Saffron-Gold banner while the
## Wayfarer Pennant flies over the hero.
func show_milestone(level: int, granted: String) -> void:
	show_banner("LEVEL %d!" % level, granted if granted != "" else "The trail grows longer", MILESTONE_COLOR, MILESTONE_BANNER_TIME)


## What a milestone grant brings, in a line: "Hedgerow Iron Falchion · Taunt in R".
static func grant_text(grant: Dictionary) -> String:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var parts: PackedStringArray = PackedStringArray()
	var weapon: EquipmentItemResource = catalog.item(grant.get("weapon_id", &""))
	if weapon != null:
		parts.append(weapon.display_name)
	var r_card: ScribeCardResource = catalog.card(grant.get("r_card_id", &""))
	if r_card != null:
		parts.append("%s in R" % r_card.display_name)
	var ult_card: ScribeCardResource = catalog.card(grant.get("ult_card_id", &""))
	if ult_card != null:
		parts.append("%s in L+R" % ult_card.display_name)
	var under: ScribeCardResource = catalog.card(grant.get("under_card_id", &""))
	if under != null:
		parts.append("%s tucked under R" % under.display_name)
	if grant.get("unlocks_secondary_calling", false):
		parts.append("Secondary Callings open")
	return "  ·  ".join(parts)


func _refresh_flashes() -> void:
	var delta: float = get_process_delta_time()
	_flow_flash_left = maxf(0.0, _flow_flash_left - delta)
	_flow_label.modulate.a = _flow_flash_left / FLASH_TIME


static func command_name(command: int) -> String:
	match command:
		CombatActionResource.Command.LIGHT:
			return "Light"
		CombatActionResource.Command.HEAVY:
			return "Heavy"
		CombatActionResource.Command.FORWARD_HEAVY:
			return "Fwd+Heavy"
		CombatActionResource.Command.BACK_HEAVY:
			return "Back+Heavy"
		CombatActionResource.Command.DODGE:
			return "Dodge"
		CombatActionResource.Command.TRIGGER_L_SKILL:
			return "L"
		CombatActionResource.Command.TRIGGER_R_SKILL:
			return "R"
		CombatActionResource.Command.TRIGGER_R_HOLD:
			return "Hold R"
		CombatActionResource.Command.TRIGGER_BOTH_ULT:
			return "L+R"
	return "?"


func _label(size: int) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override(&"outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _bar(color: Color, height: float) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0.0, height)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back: StyleBoxFlat = StyleBoxFlat.new()
	back.bg_color = BAR_BACK
	back.set_corner_radius_all(3)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override(&"background", back)
	bar.add_theme_stylebox_override(&"fill", fill)
	return bar
