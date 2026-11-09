## "QUEST COMPLETE!": a gilt card that springs down over the top of the hero's view when a
## quest is finished, in the living storybook atelier look. A red wax seal stamps a star
## onto it, gold sparkles burst, and it says in plain words what the quest gave
## (+XP, the level reached, every new thing) and what comes next: the next quest's
## name, its first step and where that is. It never takes the controls, the world stays in
## view below it, and it fades on its own after a few seconds (banners that arrive while
## it's up wait their turn, PlayerHUD).
class_name QuestCompleteCard
extends Control

signal finished

const SHEET: Vector2 = Vector2(1600.0, 900.0)
const CARD: Rect2 = Rect2(380.0, 70.0, 770.0, 300.0)
const SEAL_AT: Vector2 = Vector2(466.0, 170.0)
const SEAL_RADIUS: float = 58.0
## Seconds up before it fades, and the fade.
const SHOW_TIME: float = 6.5
const FADE_TIME: float = 0.6
const MIN_FIT: float = 0.45
const WAX: Color = Color("#A3322B")

var quest_id: StringName = &""

var _sheet: Control
var _card: PanelContainer
var _seal: Control
var _age: float = 0.0
var _next_line: String = ""


func setup(finished_quest: StringName) -> void:
	quest_id = finished_quest


func _ready() -> void:
	name = "QuestCompleteCard"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet = Control.new()
	_sheet.size = SHEET
	_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sheet)
	var quest: QuestDefinition = ActOneQuests.quest(quest_id)
	_card = BinderKit.panel(_card_style())
	_card.name = "Card"
	BinderKit.place(_sheet, _card, CARD.position, CARD.size.x, CARD.size.y)
	_card.pivot_offset = CARD.size * 0.5
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 170)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(margin)
	var stack: VBoxContainer = BinderKit.column(8)
	margin.add_child(stack)
	stack.add_child(BinderKit.text("QUEST COMPLETE!", BinderKit.BIG_SIZE + 12, AtelierTheme.GOLD))
	stack.add_child(BinderKit.text(quest.title if quest != null else "", BinderKit.NAME_SIZE + 2, AtelierTheme.INK))
	var gifts: HFlowContainer = HFlowContainer.new()
	gifts.add_theme_constant_override(&"h_separation", 6)
	gifts.add_theme_constant_override(&"v_separation", 6)
	gifts.custom_minimum_size = Vector2(CARD.size.x - 210.0, 0.0)
	gifts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if quest != null:
		gifts.add_child(BinderKit.chip("+%d XP" % quest.xp_reward, AtelierTheme.GOLD))
		gifts.add_child(BinderKit.chip("Level %d!" % PartyProgress.level_for_xp(PartyProgress.current.xp) if PartyProgress.current != null else "Level up!",
			AtelierTheme.GOLD))
		for gift: String in QuestKit.gifts(quest):
			gifts.add_child(BinderKit.chip("New: %s" % gift, AtelierTheme.INK_DROP, AtelierTheme.INK_DROP_EDGE))
	stack.add_child(gifts)
	_next_line = next_words(quest_id)
	var next: HBoxContainer = BinderKit.line(8)
	next.add_child(QuestGlyph.new(QuestGlyph.Mark.GO, AtelierTheme.GILT, 28.0))
	next.add_child(BinderKit.text(_next_line, AtelierTheme.BODY_SIZE + 1, AtelierTheme.GILT, CARD.size.x - 250.0))
	stack.add_child(next)
	_seal = Control.new()
	_seal.name = "WaxSeal"
	_seal.position = SEAL_AT - Vector2.ONE * (SEAL_RADIUS + 14.0)
	_seal.size = Vector2.ONE * (SEAL_RADIUS + 14.0) * 2.0
	_seal.pivot_offset = _seal.size * 0.5
	_seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seal.draw.connect(_draw_seal)
	_sheet.add_child(_seal)
	# It springs down from the top, then the seal stamps on with a burst of sparkles.
	_card.scale = Vector2.ONE * 0.7
	_card.modulate.a = 0.0
	_seal.scale = Vector2.ONE * 2.2
	_seal.modulate.a = 0.0
	var spring: Tween = create_tween()
	spring.set_ignore_time_scale(true)
	spring.tween_property(_card, ^"modulate:a", 1.0, 0.2)
	spring.parallel().tween_property(_card, ^"scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	spring.tween_property(_seal, ^"modulate:a", 1.0, 0.08)
	spring.parallel().tween_property(_seal, ^"scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	spring.tween_callback(_stamped)
	AudioCues.play(&"victory")


## What comes next, in a sentence: "Next: The Blighted Cider-Boughs. Hear out ... at The Orchard Gate."
static func next_words(finished_quest: StringName) -> String:
	var after: StringName = ActOneQuests.next_after(finished_quest)
	var quest: QuestDefinition = ActOneQuests.quest(after)
	if quest == null:
		return "That's all of Act I. What a hero you are!"
	var step: QuestStepResource = quest.step_at(0)
	if step == null:
		return "Next: %s" % quest.title
	var place: String = ActOnePlaces.display_name(step.place_id) if ActOnePlaces.has_place(step.place_id) else ""
	# "... at the orchard gate" already says where: no second "at The Orchard Gate".
	if place != "" and step.text.to_lower().contains(place.to_lower().trim_prefix("the ")):
		place = ""
	return "Next: %s. %s%s." % [quest.title, step.text, (" at %s" % place) if place != "" else ""]


func next_text() -> String:
	return _next_line


func _process(delta: float) -> void:
	_age += delta
	var fit: float = clampf(minf(size.x / SHEET.x, size.y / SHEET.y), MIN_FIT, 1.0)
	_sheet.scale = Vector2.ONE * fit
	_sheet.position = Vector2((size.x - SHEET.x * fit) * 0.5, 0.0)
	_seal.queue_redraw()
	if _age > SHOW_TIME:
		modulate.a = maxf(0.0, 1.0 - (_age - SHOW_TIME) / FADE_TIME)
		if _age > SHOW_TIME + FADE_TIME:
			dismiss()


## Takes the card down now.
func dismiss() -> void:
	if is_queued_for_deletion():
		return
	finished.emit()
	queue_free()


func _stamped() -> void:
	AudioCues.play(&"bell")
	for at: Vector2 in [SEAL_AT, CARD.position + Vector2(CARD.size.x - 80.0, 60.0), CARD.position + Vector2(CARD.size.x * 0.55, CARD.size.y - 30.0)]:
		var sparkle: CardSparkle = CardSparkle.new()
		sparkle.position = at
		_sheet.add_child(sparkle)


func _card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = AtelierTheme.page_style(true)
	style.bg_color = Color(AtelierTheme.PAGE_RAISED, 0.97)
	style.border_color = AtelierTheme.GOLD
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(24.0)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size = 18
	return style


## The red wax seal with a gold star pressed into it, and slow rays behind it.
func _draw_seal() -> void:
	var middle: Vector2 = _seal.size * 0.5
	for ray: int in 12:
		var angle: float = float(ray) / 12.0 * TAU + _age * 0.4
		var tip: Vector2 = middle + Vector2(cos(angle), sin(angle)) * (SEAL_RADIUS + 12.0)
		var side: Vector2 = Vector2(cos(angle + 0.12), sin(angle + 0.12)) * (SEAL_RADIUS * 0.7)
		var other: Vector2 = Vector2(cos(angle - 0.12), sin(angle - 0.12)) * (SEAL_RADIUS * 0.7)
		_seal.draw_colored_polygon(PackedVector2Array([middle + side, tip, middle + other]), Color(AtelierTheme.GOLD, 0.35))
	var blob: PackedVector2Array = PackedVector2Array()
	for index: int in 36:
		var angle: float = float(index) / 36.0 * TAU
		var wobble: float = 1.0 + 0.06 * sin(angle * 7.0) + 0.03 * sin(angle * 13.0)
		blob.append(middle + Vector2(cos(angle), sin(angle)) * SEAL_RADIUS * wobble)
	_seal.draw_colored_polygon(blob, WAX)
	_seal.draw_circle(middle, SEAL_RADIUS * 0.72, WAX.lightened(0.08))
	_seal.draw_arc(middle, SEAL_RADIUS * 0.72, 0.0, TAU, 40, WAX.darkened(0.3), 3.0, true)
	_seal.draw_colored_polygon(QuestGlyph.star_points(middle, SEAL_RADIUS * 0.5, SEAL_RADIUS * 0.21), AtelierTheme.GOLD)
