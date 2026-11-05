## The Cross-Grimoire HUD (07_EXPEDITION_HUD_AND_ART_GDD.md §2), bottom-centre
## in each player's split-screen cell. Since the Phase 12 Kaizen pass (K3) it is
## the four Sign-Flow diamonds and nothing wordy round them:
##
##                       ◆ ◆ ◆   pips
##                 (     ◇ L+R     )
##       health   (  ◇ L       ◇ R  )   stamina
##                 (     ◇ weapon  )
##                       o - o - >
##
## The diamonds are the same CrossGrimoireDiamondWidget the Grimoire Binder and
## the Reed-Light Scribery show at 2.2x (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md
## §6): each socket's Place-Card frames its Ink Card, the weapon diamond carries
## its tier and the live combo pips, a press flashes its diamond, a card
## without its pips sits dimmed, L glows while guarding, and R rings gold
## while a teammate's seal waits nearby to be detonated. Health and stamina are
## the two arcs that hug the cross; the Resonance pips are the gems over it.
## No names, numbers or key help in words: everything reads by shape and colour.
##
## What a power just did (11_COMBAT_ONBOARDING_AND_FEEL_GDD.md §4.2, Layer 4):
## pressing R or L+R, or a card, floats a verb over the cross ("TIMBER-CROSS!",
## "IRON-ROOT PRIMED!", "SHATTERPOINT!"). Downed or staggered says so there too.
## Lantern-Bearers keep their little D-Pad compass of Soul Tethers by the
## health arc.
##
## The Mythopoetic Lens (15_THE_MYTHOPOETIC_LENS.md §6.2) adds two things:
## - the Chime-Post ribbon: crossing into a zone, or finishing a Hearth-Rite
##   Tuck there, unfurls a couplet of the zone's nursery rhyme above the cross
##   for 7 s, its coaching words tinted by the Sign they mean ("feed him a
##   coal" in Saffron-Gold), so a parent can read it aloud from the couch;
## - the Hearth-Rite border: while the hero carries a Hearth-Rite Tuck, a
##   Saffron-Gold ember border glows round their cell.
class_name CrossGrimoireHUD
extends Control

const MARGIN: float = 12.0
## The cross is drawn at BASE_SCALE in a cell this big, and grows or shrinks with the cell.
const REFERENCE_SIZE: Vector2 = Vector2(1600.0, 900.0)
const BASE_SCALE: float = 0.95
const MIN_SCALE: float = 0.55
const MAX_SCALE: float = 1.2
## How far the cross reaches below its middle (the weapon diamond, its combo pips and the coin), in cross units.
const BOTTOM_EXTENT: float = 124.0
const HEALTH_COLOR: Color = Color(0.9, 0.24, 0.26)
const STAMINA_COLOR: Color = Color(0.98, 0.8, 0.28)
const GAUGE_BACK: Color = Color(0.06, 0.06, 0.08, 0.8)
## The health and stamina arcs: their radius round the diamonds, thickness, and
## how far each sweeps either side of the horizontal.
const GAUGE_RADIUS: float = 120.0
const GAUGE_WIDTH: float = 9.0
const GAUGE_SWEEP: float = PI * 0.33
const GOLD: Color = Color(1.0, 0.82, 0.3)
const COIN_COLOR: Color = Color(0.93, 0.72, 0.32)
const TETHER_COLOR: Color = Color(0.5, 1.0, 0.62)
const STATUS_FONT_SIZE: int = 22
const FONT_SIZE: int = 15
const SMALL_FONT_SIZE: int = 12
const OUTLINE: Color = Color(0.0, 0.0, 0.0, 0.85)
## The Resonance pip gems over the cross.
const PIP_ROW_Y: float = -128.0
const PIP_SPACING: float = 26.0
const PIP_RADIUS: float = 10.0
## A resonance jump at least this big (a reward, not a hit) makes the pip gems flash.
const REWARD_FLASH_PIPS: float = 0.4
const FLASH_TIME: float = 0.6
const COMPASS_RADIUS: float = 30.0
const COMPASS_DOT: float = 15.0
## A teammate's seal this close (and a pip in hand) rings the R diamond.
const DETONATE_PROMPT_RANGE: float = 12.0
const STATUS_Y: float = -154.0
const VERB_Y: float = -184.0
const VERB_TIME: float = 0.9
const VERB_FONT_SIZE: int = 30
const VERB_RISE: float = 26.0
const TEXT_WIDTH: float = 420.0
## The Chime-Post ribbon: how long a couplet shows, its fade, and where it sits
## (its bottom this far above the cross's centre, in cross units).
const RIBBON_TIME: float = 7.0
const RIBBON_FADE: float = 0.6
const RIBBON_RISE: float = 236.0
const RIBBON_FONT_SIZE: int = 21
const RIBBON_TITLE_SIZE: int = 14
const RIBBON_BACK: Color = Color(0.1, 0.07, 0.04, 0.74)
const RIBBON_EDGE: Color = Color(0.86, 0.68, 0.36, 0.9)
## The Hearth-Rite border's Saffron-Gold and width.
const EMBER_COLOR: Color = Color(1.0, 0.76, 0.28)
const EMBER_WIDTH: float = 5.0
const EMBER_SPARKS: int = 9

const Cmd = CombatActionResource.Command
const Diorama = ScribeCardResource.DioramaSocket

var actor: ActorBase
## The four diamonds: the whole cross.
var diorama: CrossGrimoireDiamondWidget
## Shown above the cross when something's wrong (downed, staggered).
var status_text: String = ""

var _cross: Control
var _was_guarding: bool = false
var _last_resonance: float = 0.0
var _pips_flash_left: float = 0.0
## The floating verb over the cross and how long it has left.
var _verb: String = ""
var _verb_color: Color = GOLD
var _verb_left: float = 0.0
## The zone this hero is in, for the Chime-Post ribbon (MythopoeticAtlas id).
var ribbon_zone_id: StringName = &""
var _ribbon: PanelContainer
var _ribbon_label: RichTextLabel
var _ribbon_left: float = 0.0
var _ribbon_plain: String = ""
## Which couplet each zone sings next.
var _couplet_turn: Dictionary[StringName, int] = {}
var _ember: Control
var _ember_age: float = 0.0


func setup(target_actor: ActorBase) -> void:
	actor = target_actor


func _ready() -> void:
	name = "CrossGrimoire"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cross = Control.new()
	_cross.name = "Cross"
	_cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cross.draw.connect(_draw_status)
	add_child(_cross)
	diorama = CrossGrimoireDiamondWidget.new()
	diorama.name = "Diorama"
	diorama.follow = actor
	diorama.set_display_scale(CrossGrimoireDiamondWidget.HUD_SCALE, false)
	diorama.position = -CrossGrimoireDiamondWidget.BASE_SIZE * CrossGrimoireDiamondWidget.HUD_SCALE * 0.5
	_cross.add_child(diorama)
	_build_ribbon()
	_ember = Control.new()
	_ember.name = "HearthRiteBorder"
	_ember.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ember.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ember.draw.connect(_draw_ember)
	add_child(_ember)
	if actor != null:
		actor.action_queue.action_started.connect(_on_action_started)
		actor.action_queue.buffer_changed.connect(_on_buffer_changed)
		CombatDirector.current.synergy_detonated.connect(_on_synergy_detonated)
		if actor.sign_flow != null:
			actor.sign_flow.hearth_rite_prepared.connect(_on_hearth_rite_prepared)
		_last_resonance = actor.stats.resonance_charge
		diorama.key_texts = socket_keys(actor.input)


func _exit_tree() -> void:
	var director: CombatDirector = CombatDirector.current
	if director != null and director.synergy_detonated.is_connected(_on_synergy_detonated):
		director.synergy_detonated.disconnect(_on_synergy_detonated)


## The scale the cross is drawn at in a cell of `cell_size`.
static func scale_for(cell_size: Vector2) -> float:
	var fit: float = minf(cell_size.x / REFERENCE_SIZE.x, cell_size.y / REFERENCE_SIZE.y)
	return clampf(BASE_SCALE * fit, MIN_SCALE, MAX_SCALE)


## The diamond a command lights up: L, R and L+R their sockets, every weapon
## swing (light, heavy and the directional heavies) the weapon diamond; -1 for none (a roll).
static func diamond_for_command(command: int) -> int:
	match command:
		Cmd.LIGHT, Cmd.HEAVY, Cmd.FORWARD_HEAVY, Cmd.BACK_HEAVY:
			return CrossGrimoireDiamondWidget.WEAPON
		Cmd.TRIGGER_L_SKILL:
			return Diorama.GUARD
		Cmd.TRIGGER_R_SKILL, Cmd.TRIGGER_R_HOLD:
			return Diorama.SKILL
		Cmd.TRIGGER_BOTH_ULT:
			return Diorama.ULT
	return -1


## The badge on each socket, read from the Input Map: "Q", "E", "R" on the
## keyboard (R is the ultimate's own key there), "L2", "R2", "L2+R2" on a pad.
static func socket_keys(input: InputComponent) -> Array[String]:
	var left: String = _label(input, InputComponent.ACTION_TRIGGER_L)
	var right: String = _label(input, InputComponent.ACTION_TRIGGER_R)
	if input == null or input.is_keyboard():
		return [left, right, _label(input, InputComponent.ACTION_ULT)]
	return [left, right, "%s+%s" % [left, right]]


static func _label(input: InputComponent, action: StringName) -> String:
	return input.label(action) if input != null else InputComponent.binding_label(action, InputComponent.KEYBOARD_DEVICE)


## Whether this cross carries the Soul Tether compass (a Lantern-Bearer's).
func shows_tether_compass() -> bool:
	return is_instance_valid(actor) and actor.tether != null


func _process(delta: float) -> void:
	if not is_instance_valid(actor) or actor.stats == null:
		return
	var cross_scale: float = scale_for(size)
	_cross.scale = Vector2.ONE * cross_scale
	_cross.position = Vector2(size.x * 0.5, size.y - MARGIN - BOTTOM_EXTENT * cross_scale)
	var guarding: bool = actor.stats.guarding
	if guarding and not _was_guarding:
		diorama.pulse(Diorama.GUARD)
	_was_guarding = guarding
	diorama.guard_lit = guarding
	diorama.detonate_ready = detonate_prompt()
	var charge: float = actor.stats.resonance_charge
	if charge - _last_resonance >= REWARD_FLASH_PIPS:
		_pips_flash_left = FLASH_TIME
	_last_resonance = charge
	_pips_flash_left = maxf(0.0, _pips_flash_left - delta)
	_verb_left = maxf(0.0, _verb_left - delta)
	status_text = _status()
	_cross.queue_redraw()
	_place_ribbon(delta, cross_scale)
	_ember_age += delta
	_ember.queue_redraw()


# --- The Chime-Post ribbon and the Hearth-Rite border (15 GDD §6.2) ------------------

## Sets the zone this hero is in; with `unfurl`, its next couplet shows now.
func show_rhyme_ribbon(zone_id: StringName, unfurl: bool = true) -> void:
	ribbon_zone_id = zone_id
	if unfurl:
		_unfurl()


## The couplet showing on the ribbon, as plain text ("" when none is).
func ribbon_text() -> String:
	return _ribbon_plain if _ribbon_left > 0.0 else ""


## The couplet showing, with its Sign tints (BBCode).
func ribbon_bbcode() -> String:
	return _ribbon_label.text if _ribbon_left > 0.0 else ""


## Whether the Saffron-Gold Hearth-Rite border is glowing.
func hearth_rite_border_lit() -> bool:
	return is_instance_valid(actor) and actor.sign_flow != null and actor.sign_flow.has_hearth_rite_tuck


func _unfurl() -> void:
	var zone: StewardshipZoneResource = MythopoeticAtlas.zone(ribbon_zone_id)
	if zone == null or zone.couplet_count() == 0:
		return
	var turn: int = _couplet_turn.get(ribbon_zone_id, 0)
	_couplet_turn[ribbon_zone_id] = turn + 1
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var colors: Dictionary[int, Color] = {}
	for sign_id: int in [ScribeSignResource.Sign.SIGN_IRON_ROOT, ScribeSignResource.Sign.SIGN_RIME_GALE,
			ScribeSignResource.Sign.SIGN_WARM_HEARTH, ScribeSignResource.Sign.SIGN_STAR_TIDE]:
		colors[sign_id] = catalog.sign_seal(sign_id).color.lightened(0.15)
	_ribbon_plain = zone.couplet(turn)
	_ribbon_label.text = "[center][font_size=%d]%s · %s[/font_size]\n%s[/center]" % [RIBBON_TITLE_SIZE,
		zone.display_name.to_upper(), zone.cooper_sign.to_upper(), zone.couplet_bbcode(turn, colors)]
	_ribbon_left = RIBBON_TIME
	AudioCues.play(&"chime", 1.2, -10.0)


func _on_hearth_rite_prepared(_socket: int) -> void:
	if ribbon_zone_id != &"":
		_unfurl()


func _build_ribbon() -> void:
	_ribbon = PanelContainer.new()
	_ribbon.name = "ChimePostRibbon"
	_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back: StyleBoxFlat = StyleBoxFlat.new()
	back.bg_color = RIBBON_BACK
	back.border_color = RIBBON_EDGE
	back.set_border_width_all(2)
	back.set_corner_radius_all(10)
	back.content_margin_left = 18.0
	back.content_margin_right = 18.0
	back.content_margin_top = 6.0
	back.content_margin_bottom = 8.0
	_ribbon.add_theme_stylebox_override("panel", back)
	_ribbon_label = RichTextLabel.new()
	_ribbon_label.name = "Couplet"
	_ribbon_label.bbcode_enabled = true
	_ribbon_label.fit_content = true
	_ribbon_label.scroll_active = false
	_ribbon_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_ribbon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ribbon_label.add_theme_font_size_override("normal_font_size", RIBBON_FONT_SIZE)
	_ribbon_label.add_theme_constant_override("outline_size", 6)
	_ribbon_label.add_theme_color_override("font_outline_color", OUTLINE)
	_ribbon_label.add_theme_color_override("default_color", Color(0.98, 0.94, 0.84))
	_ribbon.add_child(_ribbon_label)
	_ribbon.visible = false
	add_child(_ribbon)


func _place_ribbon(delta: float, cross_scale: float) -> void:
	_ribbon_left = maxf(0.0, _ribbon_left - delta)
	_ribbon.visible = _ribbon_left > 0.0
	if not _ribbon.visible:
		return
	_ribbon.reset_size()
	_ribbon.scale = Vector2.ONE * cross_scale
	var shown: Vector2 = _ribbon.size * cross_scale
	_ribbon.position = Vector2(size.x * 0.5 - shown.x * 0.5, _cross.position.y - RIBBON_RISE * cross_scale - shown.y)
	var fade: float = minf(1.0, minf(_ribbon_left, RIBBON_TIME - _ribbon_left) / RIBBON_FADE)
	_ribbon.modulate = Color(1.0, 1.0, 1.0, fade)


## A pulsing Saffron-Gold border with embers drifting up from its foot.
func _draw_ember() -> void:
	if not hearth_rite_border_lit():
		return
	var pulse: float = 0.6 + 0.3 * sin(_ember_age * 3.2)
	var rect: Rect2 = Rect2(Vector2.ZERO, _ember.size).grow(-EMBER_WIDTH * 0.5)
	_ember.draw_rect(rect, Color(EMBER_COLOR, pulse), false, EMBER_WIDTH)
	for index: int in EMBER_SPARKS:
		var rise: float = fmod(_ember_age * 0.35 + index * 0.37, 1.0)
		var x: float = _ember.size.x * (index + 0.5) / EMBER_SPARKS + sin(_ember_age * 2.0 + index) * 8.0
		var y: float = _ember.size.y - EMBER_WIDTH - rise * _ember.size.y * 0.12
		_ember.draw_circle(Vector2(x, y), 3.0 * (1.0 - rise), Color(EMBER_COLOR.lightened(0.2), (1.0 - rise) * pulse))


## The floating verb over the cross right now ("" when none is showing).
func verb_text() -> String:
	return _verb if _verb_left > 0.0 else ""


## Whether R would detonate a teammate's seal now: R strikes and detonates,
## you have the pip, and an enemy within 12 m carries a seal someone else stamped.
func detonate_prompt() -> bool:
	var action: CombatActionResource = actor.loadout.opener_for(Cmd.TRIGGER_R_SKILL)
	if action == null or not action.detonates or action.effect != CombatActionResource.Effect.STRIKE:
		return false
	if actor.stats.resonance_pips() < action.resonance_cost or actor.stats.is_downed:
		return false
	var director: CombatDirector = CombatDirector.current
	for enemy: ActorBase in director.enemies():
		if not enemy.is_targetable() or enemy.global_position.distance_to(actor.global_position) > DETONATE_PROMPT_RANGE:
			continue
		var applier: StringName = director.primer_applier(enemy)
		if applier != &"" and applier != actor.player_id:
			return true
	return false


func _status() -> String:
	if actor.stats.is_downed:
		return "Downed: back up in %ds" % ceili(actor.downed_time_left)
	if actor.state_machine.is_in(&"stagger"):
		return "Staggered!"
	return ""


func _on_action_started(action: CombatActionResource, _flowed: bool) -> void:
	diorama.pulse(diamond_for_command(action.command))
	var verb: String = verb_for(action)
	if verb != "":
		var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(action.primer if action.primer != ScribeSignResource.Sign.NONE else action.scribe_sign)
		_show_verb(verb, seal.color if action.scribe_sign != ScribeSignResource.Sign.NONE else GOLD.lightened(0.3))


## The word a power floats over the cross: an R or L+R flourish's first word
## ("TIMBER-CROSS!"), a priming card's Sign ("IRON-ROOT PRIMED!"), any other
## card's first word; nothing for a plain swing.
static func verb_for(action: CombatActionResource) -> String:
	if action == null or not (action.is_card() or action.uninked):
		return ""
	if action.primer != ScribeSignResource.Sign.NONE:
		return "%s PRIMED!" % ArsenalCatalog.current.sign_seal(action.primer).display_name.to_upper()
	return "%s!" % action.display_name.get_slice(" ", 0).to_upper()


func _show_verb(text: String, color: Color) -> void:
	_verb = text
	_verb_color = color
	_verb_left = VERB_TIME


## A detonation near you calls out its name ("SHATTERPOINT!").
func _on_synergy_detonated(target: ActorBase, primer: int, _cross: bool, _label: String) -> void:
	if not is_instance_valid(actor) or not is_instance_valid(target) or target.global_position.distance_to(actor.global_position) > DETONATE_PROMPT_RANGE:
		return
	var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(primer)
	_show_verb("%s!" % seal.detonation_name, seal.color)


func _on_buffer_changed(commands: Array[int]) -> void:
	if not commands.is_empty():
		diorama.pulse(diamond_for_command(commands[commands.size() - 1]))


# --- The gauges round the diamonds ---------------------------------------------

## Health and stamina as the two arcs either side of the diamonds, the pip gems
## over them, a small Chimes coin, the floating verb and status, and the Soul
## Tether compass for Lantern-Bearers.
func _draw_status() -> void:
	if not is_instance_valid(actor) or actor.stats == null:
		return
	var font: Font = ThemeDB.fallback_font
	var stats: StatsComponent = actor.stats
	# Health fills up the left arc from its foot; stamina up the right one.
	var health_ratio: float = clampf(stats.health / maxf(1.0, stats.stats.max_health), 0.0, 1.0)
	var stamina_ratio: float = clampf(stats.stamina / maxf(1.0, stats.stats.max_stamina), 0.0, 1.0)
	_gauge(PI - GAUGE_SWEEP, -1.0, health_ratio, HEALTH_COLOR)
	_gauge(GAUGE_SWEEP, 1.0, stamina_ratio, STAMINA_COLOR if not actor.sprinting else STAMINA_COLOR.lightened(0.25))
	_heart(_gauge_foot(PI - GAUGE_SWEEP, -1.0), HEALTH_COLOR)
	_bolt(_gauge_foot(GAUGE_SWEEP, 1.0), STAMINA_COLOR)
	# The Resonance pip gems, filling as they charge.
	var flash: float = _pips_flash_left / FLASH_TIME
	var full: int = stats.resonance_pips()
	var count: int = stats.stats.max_resonance_pips
	for gem: int in count:
		var center: Vector2 = Vector2((gem - (count - 1) * 0.5) * PIP_SPACING, PIP_ROW_Y)
		var fill: float = clampf(stats.resonance_charge - gem, 0.0, 1.0)
		_gem(center, PIP_RADIUS * (1.0 + flash * 0.25), fill, gem < full)
	# The party's Chimes: a small brass octagon and the count, under the stamina arc.
	var coin_center: Vector2 = _gauge_foot(GAUGE_SWEEP, 1.0) + Vector2(26.0, 6.0)
	var octagon: PackedVector2Array = PackedVector2Array()
	for corner: int in 8:
		var angle: float = PI / 8.0 + TAU * corner / 8.0
		octagon.append(coin_center + Vector2(cos(angle), sin(angle)) * 8.0)
	_cross.draw_colored_polygon(octagon, COIN_COLOR)
	_cross.draw_rect(Rect2(coin_center - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), Color(0.15, 0.1, 0.05))
	_text(font, coin_center + Vector2(12.0, 5.0), str(PartyProgress.current.chimes), SMALL_FONT_SIZE, COIN_COLOR.lightened(0.3), 60.0, HORIZONTAL_ALIGNMENT_LEFT)
	if status_text != "":
		_text(font, Vector2(-TEXT_WIDTH * 0.5, STATUS_Y), status_text, STATUS_FONT_SIZE, Color(1.0, 0.55, 0.45), TEXT_WIDTH, HORIZONTAL_ALIGNMENT_CENTER)
	if _verb_left > 0.0:
		var fade: float = clampf(_verb_left / (VERB_TIME * 0.4), 0.0, 1.0)
		var rise: float = (1.0 - _verb_left / VERB_TIME) * VERB_RISE
		_text(font, Vector2(-TEXT_WIDTH * 0.5, VERB_Y - rise), _verb, VERB_FONT_SIZE, Color(_verb_color, fade), TEXT_WIDTH, HORIZONTAL_ALIGNMENT_CENTER)
	if shows_tether_compass():
		_draw_compass(font)


## One arc gauge from its foot (`foot` radians, the lower end) sweeping up
## `side` (-1 the left arc, counter-clockwise on screen; +1 the right), filled `ratio` of the way.
func _gauge(foot: float, side: float, ratio: float, color: Color) -> void:
	var sweep: float = GAUGE_SWEEP * 2.0
	var top: float = foot - side * sweep
	_cross.draw_arc(Vector2.ZERO, GAUGE_RADIUS, foot, top, 32, GAUGE_BACK, GAUGE_WIDTH + 4.0, true)
	if ratio > 0.0:
		_cross.draw_arc(Vector2.ZERO, GAUGE_RADIUS, foot, foot - side * sweep * ratio, maxi(4, roundi(32 * ratio)), color, GAUGE_WIDTH, true)


## Just past a gauge's foot, where its icon sits.
func _gauge_foot(foot: float, side: float) -> Vector2:
	var angle: float = foot + side * 0.16
	return Vector2(cos(angle), sin(angle)) * GAUGE_RADIUS


func _heart(at: Vector2, color: Color) -> void:
	_cross.draw_circle(at + Vector2(-4.0, -3.0), 5.5, color)
	_cross.draw_circle(at + Vector2(4.0, -3.0), 5.5, color)
	_cross.draw_colored_polygon(PackedVector2Array([at + Vector2(-9.5, -1.0), at + Vector2(9.5, -1.0), at + Vector2(0.0, 10.0)]), color)


func _bolt(at: Vector2, color: Color) -> void:
	_cross.draw_colored_polygon(PackedVector2Array([at + Vector2(2.0, -11.0), at + Vector2(-6.0, 1.0), at + Vector2(0.0, 1.0),
		at + Vector2(-2.0, 11.0), at + Vector2(6.0, -2.0), at + Vector2(0.0, -2.0)]), color)


func _gem(center: Vector2, radius: float, fill: float, full: bool) -> void:
	var points: PackedVector2Array = PackedVector2Array([center + Vector2(0.0, -radius), center + Vector2(radius * 0.75, 0.0),
		center + Vector2(0.0, radius), center + Vector2(-radius * 0.75, 0.0)])
	_cross.draw_colored_polygon(points, Color(0.1, 0.1, 0.14, 0.85))
	if fill > 0.0:
		# A charging gem fills from the bottom up.
		var lit: PackedVector2Array = points
		if fill < 1.0:
			var level: float = center.y + radius - fill * radius * 2.0
			var band: PackedVector2Array = PackedVector2Array([Vector2(center.x - radius, level), Vector2(center.x + radius, level),
				Vector2(center.x + radius, center.y + radius), Vector2(center.x - radius, center.y + radius)])
			var clipped: Array[PackedVector2Array] = Geometry2D.intersect_polygons(points, band)
			lit = clipped[0] if not clipped.is_empty() else PackedVector2Array()
		if lit.size() >= 3:
			_cross.draw_colored_polygon(lit, GOLD if full else GOLD.darkened(0.25))
	var outline: PackedVector2Array = points.duplicate()
	outline.append(points[0])
	_cross.draw_polyline(outline, GOLD.lightened(0.3) if full else Color(0.6, 0.6, 0.65), 1.5)


## The Lantern-Bearer's D-Pad, left of the health arc: who each direction tethers, coloured by their health.
func _draw_compass(font: Font) -> void:
	var center: Vector2 = Vector2(-GAUGE_RADIUS - COMPASS_RADIUS - COMPASS_DOT - 16.0, 0.0)
	var allies: Array[ActorBase] = actor.tether.allies()
	var directions: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	_cross.draw_circle(center, 5.0, GOLD)
	for slot: int in directions.size():
		var dot: Vector2 = center + directions[slot] * COMPASS_RADIUS
		if slot >= allies.size():
			_cross.draw_arc(dot, COMPASS_DOT, 0.0, TAU, 20, Color(1.0, 1.0, 1.0, 0.25), 2.0)
			continue
		var ally: ActorBase = allies[slot]
		var health: float = ally.stats.health_ratio()
		var tethered: bool = ally.player_id == actor.tether.tethered_id
		_cross.draw_circle(dot, COMPASS_DOT, Color(0.08, 0.08, 0.1, 0.85))
		_cross.draw_arc(dot, COMPASS_DOT - 2.0, -PI * 0.5, -PI * 0.5 + TAU * health, 24, HEALTH_COLOR.lerp(TETHER_COLOR, health), 4.0)
		if tethered:
			_cross.draw_arc(dot, COMPASS_DOT + 3.0, 0.0, TAU, 24, TETHER_COLOR, 3.0)
		_text(font, dot + Vector2(-COMPASS_DOT, 4.0), ally.display_name().get_slice(" ", 0), SMALL_FONT_SIZE, Color.WHITE, COMPASS_DOT * 2.0,
			HORIZONTAL_ALIGNMENT_CENTER)


func _text(font: Font, at: Vector2, text: String, font_size: int, color: Color, width: float, align: HorizontalAlignment) -> void:
	_cross.draw_string_outline(font, at, text, align, width, font_size, 5, OUTLINE)
	_cross.draw_string(font, at, text, align, width, font_size, color)
