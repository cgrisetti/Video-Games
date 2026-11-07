## The title screen's checks (docs/22_TITLE_SCREEN_AND_TALES.md), run last by
## tools/smoke_test.gd in a scratch tales folder (never the family's saves):
##   - the game opens on the title; game options on the command line skip it
##   - names are tidied, suggested and given their own save file
##   - the title: the Everwood wordmark, New Game / Continue / Quit, the
##     living picture with the Level 1 youth, Continue off with no tales
##   - New Game refuses an empty name, then begins a fresh Level 1 tale in a
##     new save file holding the hero's name; Continue lists the tales newest
##     first (and the family's older save, by its own name) and plays the one chosen
##   - the first hero on the host's screen wears the tale's name
extends RefCounted

const SCRATCH_FOLDER: String = "user://smoke_title_saves/"
const SCRATCH_FAMILY: String = "user://smoke_title_family.cfg"
const TITLE_SCENE: String = "res://scenes/title/title_screen.tscn"

var tree: SceneTree
var check: Callable


func run(scene_tree: SceneTree, checker: Callable, restore_save: String) -> void:
	tree = scene_tree
	check = checker
	_check_nameplate()
	_clear_scratch()
	SaveSlots.folder = SCRATCH_FOLDER
	SaveSlots.family_save = SCRATCH_FAMILY
	TitleScreen.start_game_on_begin = false
	_check_names()
	tree.change_scene_to_file(TITLE_SCENE)
	await _frames(20)
	var title: TitleScreen = tree.current_scene as TitleScreen
	check.call(title != null, "the title screen loads")
	if title != null:
		_check_title(title)
		await _check_new_game(title)
		await _check_continue(title)
	TitleScreen.start_game_on_begin = true
	SaveSlots.folder = SaveSlots.SLOT_FOLDER
	SaveSlots.family_save = PartyProgress.SAVE_PATH
	PartyProgress.current.use_save_file(restore_save)
	_clear_scratch()


func _frames(count: int) -> void:
	for i: int in count:
		await tree.process_frame


func _clear_scratch() -> void:
	for file_name: String in DirAccess.get_files_at(SCRATCH_FOLDER):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_FOLDER + file_name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_FOLDER))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_FAMILY))


func _check_nameplate() -> void:
	var level: LevelBase = tree.current_scene as LevelBase
	var p1: ActorBase = level.actors.get(&"1_0") as ActorBase if level != null else null
	if p1 == null:
		check.call(false, "a level with Player 1 to name (none was found)")
		return
	var before: String = PartyProgress.current.hero_name
	var plain: String = p1.display_name()
	PartyProgress.current.hero_name = "Wren"
	var named: String = p1.display_name()
	PartyProgress.current.hero_name = before
	check.call(named == "P1 · Wren" and plain.begins_with("P1 · ") and plain != named,
		"the first hero on the host's screen wears the tale's name (%s, without a name %s)" % [named, plain])


func _check_names() -> void:
	check.call(ProjectSettings.get_setting("application/run/main_scene") == TITLE_SCENE and TitleScreen.wants_title(PackedStringArray())
		and not TitleScreen.wants_title(PackedStringArray(["--save=user://x.cfg"])) and not TitleScreen.wants_title(PackedStringArray(["--instance=hub"])),
		"the game opens on the title screen; game options after -- (--save=, --instance= ...) go straight to the game")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var first: String = SaveSlots.suggest_name(rng)
	var second: String = SaveSlots.suggest_name(rng, first)
	check.call(SaveSlots.clean_name("  W@ren 99 ") == "Wren" and SaveSlots.clean_name("Mary-Kate O'Hollis Longname") == "Mary-Kate O'Holl"
		and SaveSlots.clean_name("   ") == "" and first != "" and second != first,
		"hero names are tidied (letters, spaces, hyphens, apostrophes, %d at most) and suggested (%s, then %s)" % [SaveSlots.MAX_NAME_LENGTH, first, second])
	var path: String = SaveSlots.new_slot_path("Mary Kate")
	check.call(path.begins_with(SCRATCH_FOLDER) and path.get_file().begins_with("mary_kate_") and path.ends_with(".cfg") and SaveSlots.list().is_empty(),
		"each tale gets its own save file in the tales folder (%s), and there are none yet" % path.get_file())


func _check_title(title: TitleScreen) -> void:
	var labels: PackedStringArray = PackedStringArray()
	for item: Node in title.menu.get_children():
		labels.append(str(item.get_meta(&"label", "")))
	check.call(title.wordmark != null and EverwoodWordmark.TITLE == "EVERWOOD" and "|".join(labels) == "New Game|Continue|Quit"
		and (title.menu.get_child(1) as Button).disabled,
		"the title shows the Everwood wordmark over New Game, Continue and Quit; Continue waits until there's a tale (%s)" % ", ".join(labels))
	var diorama: TitleDiorama = title.diorama
	check.call(diorama != null and diorama.camera.current and diorama.skeleton != null and diorama.skeleton.get_bone_count() == HeroRigBuilder.BONE_COUNT
		and diorama.skeleton.scale.is_equal_approx(Vector3.ONE * HeroAppearanceResource.YOUTH_SKELETON_SCALE) and diorama.find_child("TheCrown", true, false) != null,
		"behind it, the living picture: the Level 1 youth on the orchard knoll above The Sound, and The Crown across the water")


func _check_new_game(title: TitleScreen) -> void:
	title.open_new_game()
	await _frames(2)
	check.call(title.new_game_panel.visible and not title.menu.visible and title.name_field.has_focus(),
		"New Game opens a page asking for the hero's name, the name field ready to type in")
	title.name_field.text = "   "
	title.begin_new_tale()
	check.call(title.name_note.text != "" and SaveSlots.list().is_empty(), "...and won't begin without a name")
	var begun: Array[String] = []
	title.tale_begun.connect(func(path: String) -> void: begun.append(path))
	title.name_field.text = "Wren"
	var girl_pick: Button = title.new_game_panel.find_child("PickGirl", true, false) as Button
	if girl_pick != null:
		girl_pick.button_pressed = true
	var knoll_girl: bool = title.diorama.youth_style == HeroAppearanceResource.YOUTH_GIRL
	title.begin_new_tale()
	var path: String = PartyProgress.current.save_path
	var file: ConfigFile = ConfigFile.new()
	var read: Error = file.load(path)
	check.call(begun.size() == 1 and begun[0] == path and path.begins_with(SCRATCH_FOLDER) and read == OK and str(file.get_value("hero", "name", "")) == "Wren"
		and PartyProgress.current.hero_name == "Wren" and PartyProgress.current.trail_level() == 1 and PartyProgress.current.chimes == 0
		and not PartyProgress.current.endgame_kits_for_testing,
		"Begin the Tale starts a fresh Level 1 tale for Wren in a new save file (%s)" % path.get_file())
	check.call(girl_pick != null and knoll_girl and PartyProgress.current.hero_style == HeroAppearanceResource.YOUTH_GIRL
		and str(file.get_value("hero", "style", "")) == "girl",
		"New Game asks boy or girl: choosing The Girl shows her on the knoll and the tale remembers her (docs/26 §7)")
	PartyProgress.current.hero_style = HeroAppearanceResource.YOUTH_BOY


func _check_continue(title: TitleScreen) -> void:
	# An older tale, and the family's save from before names.
	var older: String = SaveSlots.new_slot_path("Bram")
	var bram: ConfigFile = ConfigFile.new()
	bram.set_value("hero", "name", "Bram")
	bram.set_value("hero", "last_played", int(Time.get_unix_time_from_system()) - 7200)
	bram.set_value("trail", "xp", 230)
	bram.set_value("party", "chimes", 45)
	bram.save(older)
	var family: ConfigFile = ConfigFile.new()
	family.set_value("trail", "xp", 1050)
	family.set_value("party", "chimes", 376)
	family.save(SCRATCH_FAMILY)
	title.close_panels()
	title.refresh()
	var tales: Array[Dictionary] = SaveSlots.list()
	var names: PackedStringArray = PackedStringArray()
	for tale: Dictionary in tales:
		names.append(str(tale["name"]))
	check.call(not (title.menu.get_child(1) as Button).disabled and names.size() == 3 and names[2] == "Bram" and names.has("Wren")
		and names.has(SaveSlots.FAMILY_TALE_NAME),
		"Continue lists every tale, newest played first, the family's older save by its own name (%s)" % ", ".join(names))
	var bram_tale: Dictionary = {}
	for tale: Dictionary in tales:
		if tale["name"] == "Bram":
			bram_tale = tale
	check.call(int(bram_tale.get("level", 0)) == 4 and TitleScreen.tale_detail(bram_tale) == "Level 4 · 45 Chimes · played 2 hours ago",
		"...each with its level, Chimes and when it was last played (%s)" % TitleScreen.tale_detail(bram_tale))
	title.open_continue()
	await _frames(2)
	check.call(title.continue_panel.visible and title.tale_list.get_child_count() == 3 and (title.tale_list.get_child(0) as Button).has_focus(),
		"Continue opens the list with the newest tale ready to pick")
	title.continue_tale(older)
	check.call(PartyProgress.current.save_path == older and PartyProgress.current.hero_name == "Bram" and PartyProgress.current.trail_level() == 4
		and PartyProgress.current.chimes == 45,
		"choosing a tale plays its save: Bram at Level 4 with 45 Chimes")
	title.close_panels()
	check.call(title.menu.visible and not title.continue_panel.visible, "Back returns to the menu")
