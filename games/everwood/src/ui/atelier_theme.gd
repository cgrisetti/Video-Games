## The living storybook atelier look for every menu (25_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md
## §3, the Everwood Menu Wireframes): dark timber under warm pages, a gilt edge,
## lime-wash ink, and the four Ink-Signs in the world doc's colours. The Options
## menu, the Grimoire Binder, the Seal Press, the Scribe Desk & Forge and the
## Reed-Light Scribery all build their pages, tabs, rows, chips and tooltip boxes
## here, so they read as one book (and one place to retune it).
class_name AtelierTheme
extends RefCounted

## The timber ground behind a menu, and the pages on it.
const BACKDROP: Color = Color(0.071, 0.051, 0.035, 0.86)
const PAGE: Color = Color("#1E1711")
const PAGE_RAISED: Color = Color("#2A2018")
const ROW: Color = Color("#1A140F")
const ROW_CHOSEN: Color = Color("#3A2C1E")
const LINE: Color = Color("#4A3A2A")
const LINE_DIM: Color = Color("#6E5D49")
## The gilt edge of a page, and the gold of the chosen row.
const GILT: Color = Color("#D9B36B")
const GOLD: Color = Color("#F2D27A")
## Lime-wash ink, muted and dim.
const INK: Color = Color("#F2ECE1")
const INK_MUTED: Color = Color("#C9BBA5")
const INK_DIM: Color = Color("#A0917C")
## A good thing, a warning, a refusal.
const GOOD: Color = Color("#9FE0A8")
const WARN: Color = Color("#F2D27A")
const BAD: Color = Color("#FFB29C")
## Ink-Drops in the well.
const INK_DROP: Color = Color("#B993F2")
const INK_DROP_EDGE: Color = Color("#E4DBFF")
## The four Ink-Signs (ScribeSignResource.Sign order after NONE): fills, then text tints that read on a page.
const SIGN_FILLS: Array[Color] = [Color("#D9822B"), Color("#38A3D1"), Color("#F2B749"), Color("#8C52D9")]
const SIGN_TEXT: Array[Color] = [Color("#E9A257"), Color("#6CC3E8"), Color("#F2C66A"), Color("#C4A3F5")]
## Material tiers 1 to 7 (the Google Doc's albedo), for ladders and tier pips.
const TIER_FILLS: Array[Color] = [Color("#7A5438"), Color("#9E6B3B"), Color("#5E666E"), Color("#8A99AD"), Color("#C9E2F2"), Color("#E5B546"), Color("#3D355E")]

const TITLE_SIZE: int = 26
const HEADING_SIZE: int = 19
const BODY_SIZE: int = 16
const SMALL_SIZE: int = 13
const RADIUS: int = 10


## A page's box: warm timber, a gilt edge, rounded corners.
static func page_style(raised: bool = false) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PAGE_RAISED if raised else PAGE
	style.border_color = GILT
	style.set_border_width_all(2)
	style.set_corner_radius_all(RADIUS + 4)
	style.set_content_margin_all(16.0)
	return style


## A row's box: plain, or chosen (a gold edge on a warmer ground).
static func row_style(chosen: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = ROW_CHOSEN if chosen else ROW
	style.border_color = GOLD if chosen else LINE
	style.set_border_width_all(2 if chosen else 1)
	style.set_corner_radius_all(RADIUS)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


## A tab's box along a page's top: the open tab joins its page.
static func tab_style(open: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PAGE_RAISED if open else PAGE
	style.border_color = GILT if open else LINE
	style.set_border_width_all(2 if open else 1)
	style.border_width_bottom = 0
	style.corner_radius_top_left = RADIUS
	style.corner_radius_top_right = RADIUS
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


## The tooltip box under the tabs (what the tab is for, what the chosen row does).
static func tooltip_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = page_style(true)
	style.set_content_margin_all(12.0)
	return style


## A small rounded chip ("NEW", "Lv 17", a Sign's name) in a colour.
static func chip_style(edge: Color, fill: Color = ROW) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	return style


## A label in the book's ink.
static func label(text: String, size: int = BODY_SIZE, color: Color = INK) -> Label:
	var made: Label = Label.new()
	made.text = text
	made.add_theme_font_size_override(&"font_size", size)
	made.add_theme_color_override(&"font_color", color)
	made.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return made


## The fill colour of a Sign (ScribeSignResource.Sign), or the gilt for none.
static func sign_fill(scribe_sign: int) -> Color:
	var index: int = scribe_sign - 1
	return SIGN_FILLS[index] if index >= 0 and index < SIGN_FILLS.size() else GILT


## The text tint of a Sign that reads on a page.
static func sign_text(scribe_sign: int) -> Color:
	var index: int = scribe_sign - 1
	return SIGN_TEXT[index] if index >= 0 and index < SIGN_TEXT.size() else INK


## A material tier's colour (1 to 7).
static func tier_fill(tier_index: int) -> Color:
	return TIER_FILLS[clampi(tier_index - 1, 0, TIER_FILLS.size() - 1)]
