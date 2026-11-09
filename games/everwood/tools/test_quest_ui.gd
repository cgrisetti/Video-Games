## The quest screens (docs/29 §10), run by tools/test_act_one.gd on Embershore right after
## Act I starts, on the first hero:
##   1  the quest tracker says the quest, the step and where it is (with "You're here!" inside it)
##   2  the talk box: light on Alf-Wright opens it along the bottom; the words write out and
##      stay up (nothing fades on a timer); Tell me more / What do I do? / Goodbye; "What do
##      I do?" says the step and lights the firefly trail; hearing the last line counts for
##      the quest, and the tracker cheers "Done!" as the next step comes in
##   3  a two-hander's lines show the right speaker (Tenar-Moss beside Nokes)
##   4  the quest book: seals for done / under way / to come, the story, the steps and
##      what it gives; a quest still to come stays a surprise; "Show me the way" lights the
##      trail and closes the book; B opens and closes it
##   5  finishing a quest puts up "QUEST COMPLETE!" with what's next, and the next quest's
##      banner waits until the card has gone
## Afterwards the ledger is reset and Act I started afresh for the quest checks.
extends RefCounted

var check: Callable
var level: CalderaArchipelagoWorld
var tree: SceneTree
var director: ActOneDirector
var quests: QuestManager
var hero: ActorBase
var hud: PlayerHUD


func run(live_level: CalderaArchipelagoWorld, checker: Callable, scene_tree: SceneTree, act_one: ActOneDirector, hero_actor: ActorBase) -> void:
	level = live_level
	check = checker
	tree = scene_tree
	director = act_one
	quests = QuestManager.current
	hero = hero_actor
	hud = PlayerHUD.for_actor(tree, hero)
	if hud == null or hero == null:
		check.call(false, "a hero with a HUD for the quest screens")
		return
	await _check_tracker()
	await _check_talk()
	_check_two_hander()
	await _check_book()
	await _check_complete()
	# Leave things as Act I's checks expect them: no menus, no trail, a fresh Q01.
	if hud.quest_complete_card() != null:
		hud.quest_complete_card().dismiss()
	hud.close_menu()
	hud.clear_waymarker()
	hud.hide_banner()
	quests.reset_for_testing()
	quests.start_act_one()
	await _frames(2)


func _check_tracker() -> void:
	_place_party(ActOnePlaces.centre(ActOnePlaces.HEARTHSTEAD_MARKET))
	await _frames(4)
	var lines: PackedStringArray = hud.quest_tracker.lines()
	var step: QuestStepResource = quests.active_step()
	var shows: bool = hud.quest_tracker.visible and lines.size() == 5 and lines[0] == "QUEST 1 OF 5" and lines[1] == "Lee-Shore Awakening" \
		and step != null and lines[2] == step.text
	var where: String = hud.quest_tracker.where_text()
	var place: String = ActOnePlaces.display_name(step.place_id) if step != null else "?"
	var points: bool = where.begins_with(place) and (where.contains(" m · ") or where.contains("close by") or where.contains("You're here!"))
	check.call(shows and points, "the quest tracker shows QUEST 1 OF 5, Lee-Shore Awakening and the step under way, and where it is (\"%s\")" % where)


func _check_talk() -> void:
	var alf: EverwoodNPC = director.alf
	_place_party(alf.global_position + Vector3(1.6, 0.0, 0.8))
	await _frames(3)
	var lines: PackedStringArray = alf.current_lines()
	alf.interact(hero)
	var talk: TalkBox = hud.talk_box()
	if talk == null:
		check.call(false, "light on Master Alf-Wright opens the talk box")
		return
	var opened: bool = talk.speaker() == "Master Alf-Wright" and talk.page_words() == lines[0] and talk.is_typing() and hero.input.menu_open \
		and talk.choices() == PackedStringArray(["Tell me more", "What do I do?", "Goodbye"]) and hud.quest_tracker.visible
	# The words write out, then stay up: nothing takes them down on a timer.
	await _seconds(9.0)
	var stays: bool = hud.talk_box() == talk and not talk.is_typing() and talk.page_words() == lines[0]
	check.call(opened and stays,
		"the talk box: light on Alf-Wright opens it with his name, the words write out and are still up 9 s later; Tell me more / What do I do? / Goodbye")
	# Light while writing finishes the words; light again is "Tell me more".
	talk.accept()
	var second: bool = talk.line_index == 1 and talk.is_typing()
	talk.accept()
	var finished_early: bool = not talk.is_typing() and talk.line_index == 1
	talk.choose(TalkBox.Choice.WHAT)
	var told: bool = talk.page_words().begins_with("Here's what to do: Speak to Master Alf-Wright") and hud.has_waymarker()
	talk.choose(TalkBox.Choice.MORE)
	var back: bool = talk.line_index == 1
	check.call(second and finished_early and told and back,
		"light finishes the writing, then reads on; What do I do? says the step in words and lights the firefly trail; Tell me more goes back to where the talk was")
	var step_before: String = quests.active_step().text
	while not talk.is_last_line():
		talk.next_line()
	await _frames(2)
	var heard: bool = talk.heard_everything and quests.is_on_step(ActOneQuests.Q01, &"calm_hounds") and talk.choices()[0] == "Say that again"
	var cheered: bool = hud.quest_tracker.cheer_text == step_before and hud.quest_tracker.lines()[2] == quests.active_step().text
	talk.choose(TalkBox.Choice.BYE)
	await _frames(2)
	var closed: bool = hud.talk_box() == null and not hero.input.menu_open
	check.call(heard and cheered and closed,
		"hearing Alf-Wright's last line counts for the quest (Say that again is offered), the tracker cheers \"Done!\" as the hounds come in, and Goodbye closes the talk")
	hud.clear_waymarker()


func _check_two_hander() -> void:
	var parsed: PackedStringArray = EverwoodNPC.parse_line("TENAR-MOSS: You'll chop nothing, Reeve.", "Reeve Nokes")
	var plain: PackedStringArray = EverwoodNPC.parse_line("Root, leaf, flower, seed.", "Dame Tenar-Moss")
	check.call(parsed == PackedStringArray(["Tenar-Moss", "You'll chop nothing, Reeve."]) and plain[0] == "Dame Tenar-Moss"
		and director.nokes.talk_partner("Tenar-Moss") == director.tenar and director.nokes.talk_partner("Reeve Nokes") == null,
		"a two-hander shows who speaks: \"TENAR-MOSS: ...\" is Dame Tenar-Moss beside Reeve Nokes")


func _check_book() -> void:
	hero.input.quest_book_requested.emit()
	var book: QuestBook = hud.quest_book()
	if book == null:
		check.call(false, "B opens the quest book")
		return
	await _frames(2)
	var seals: bool = book.seal_of(0) == QuestGlyph.Mark.NOW and book.seal_of(1) == QuestGlyph.Mark.LATER and book.selected == 0 and hero.input.menu_open
	var detail: String = book.detail_text()
	var reads: bool = detail.contains("Lee-Shore Awakening") and detail.contains("From Master Alf-Wright") and detail.contains(QuestKit.story(quests.active_quest())) \
		and detail.contains("Speak to Master Alf-Wright") and detail.contains(quests.active_step().text) and detail.contains("+400 XP") \
		and detail.contains("The Calming Seal card") and not detail.contains("Bring the colour home") and book.way_text().contains("Show me the way")
	book.select(1)
	var surprise: bool = book.detail_text().begins_with("? ? ?") and not book.way_text().contains("Show me the way!")
	book.select(0)
	check.call(seals and reads and surprise,
		"the quest book: Q01's star and the others' \"?\", Alf-Wright's quest with its story, the step done ticked and the one under way lit, +400 XP and the Calming Seal; the next quest stays a surprise")
	var shown: bool = book.show_the_way()
	await _frames(2)
	var trail: bool = shown and hud.quest_book() == null and hud.has_waymarker() and hud.banner_title() == "FOLLOW THE FIREFLIES" and not hero.input.menu_open
	hero.input.quest_book_requested.emit()
	var again: bool = hud.quest_book() != null
	hero.input.quest_book_requested.emit()
	await _frames(1)
	check.call(trail and again and hud.quest_book() == null,
		"Show me the way lights the firefly trail to the step and closes the book; B opens and closes it")
	hud.clear_waymarker()
	hud.hide_banner()


func _check_complete() -> void:
	quests.jump_to(ActOneQuests.Q02)
	await _frames(2)
	var card: QuestCompleteCard = hud.quest_complete_card()
	var shows: bool = card != null and card.quest_id == ActOneQuests.Q01 and card.next_text().contains("The Blighted Cider-Boughs") \
		and card.next_text().contains("at the orchard gate.") and not card.next_text().contains("at The Orchard Gate") and hud.banner_title() == "" and not hero.input.menu_open
	if card != null:
		card.dismiss()
	await _frames(2)
	var banner_after: bool = hud.banner_title() == "THE BLIGHTED CIDER-BOUGHS"
	_place_party(ActOnePlaces.centre(ActOnePlaces.ORCHARD_GATE))
	await _frames(3)
	var here: bool = hud.quest_tracker.where_text().contains("You're here!") and hud.quest_tracker.lines()[1] == "The Blighted Cider-Boughs"
	check.call(shows and banner_after and here,
		"finishing Q01 puts up QUEST COMPLETE! with what's next (The Blighted Cider-Boughs, at the orchard gate, said once); its banner waits for the card; at the gate the tracker says \"You're here!\"")


## Stands the whole party round a spot on the ground (as tools/test_act_one.gd does).
func _place_party(at: Vector3) -> void:
	var seat: int = 0
	for actor: ActorBase in level.party_in_order():
		if not actor.is_multiplayer_authority():
			continue
		var spot: Vector3 = at + Vector3((float(seat % 4) - 1.5) * 1.6, 0.0, 0.0)
		level.streamer.ensure_ground_at(spot)
		spot.y = level.streamer.height_at(spot.x, spot.z) + 0.2
		actor.place_at(Transform3D(Basis.IDENTITY, spot))
		seat += 1


func _frames(count: int) -> void:
	for index: int in count:
		await tree.physics_frame


func _seconds(seconds: float) -> void:
	await _frames(int(ceil(seconds * 60.0)))
