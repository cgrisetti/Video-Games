## The F4 telemetry badge (10_WORLD_ARCHITECTURE.md §5, 16 §7.4): a small
## corner readout of the world's streaming and the live score, for checking
## they work:
##   Landblock (0, -1) · Active: 9 · Clutter: 15 · HLOD: 2 · Queue: 0 · Deltas: 3
##   Audio: crown_island [G_LYDIAN 110BPM] · Mood: WONDER (Var B: Violin/Harp) · State: EXPLORE · Stems: 0.0/0.0/-80.0/-80.0 dB · Voices: 4/32
## Landblock is Player 1's chunk; Active the chunks with gameplay loaded,
## Clutter those with clutter, HLOD the proxies on show, Queue the attach jobs
## waiting for frame time, Deltas the WorldStateDB entries (only on a landblock
## world; the Caldera Isles show the score line alone). The score line is
## AudioDirector.telemetry_line(). Hidden until F4 (or
## WorldGridManager.set_telemetry_visible, CalderaArchipelagoWorld.set_telemetry_visible).
class_name WorldTelemetryBadge
extends PanelContainer

const REFRESH_TIME: float = 0.2
const FONT_SIZE: int = 15
const MARGIN: float = 12.0
## Sits below the screen's banner lines at the top centre.
const TOP: float = 112.0

var grid: WorldGridManager

var _label: Label
var _refresh_left: float = 0.0


func setup(manager: WorldGridManager) -> void:
	grid = manager


func _ready() -> void:
	name = "WorldTelemetryBadge"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.08, 0.72)
	style.border_color = Color(0.55, 0.8, 0.6, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	add_theme_stylebox_override(&"panel", style)
	_label = Label.new()
	_label.name = "Readout"
	_label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	_label.add_theme_color_override(&"font_color", Color(0.85, 1.0, 0.88))
	add_child(_label)
	visible = false
	refresh()


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_TIME
		refresh()


func refresh() -> void:
	if _label == null:
		return
	_label.text = readout()
	# Snug round the text, in the top-right corner.
	reset_size()
	position = Vector2(get_viewport_rect().size.x - size.x - MARGIN, TOP)


## What the badge shows: the streaming line on a landblock world, then the score's line.
func readout() -> String:
	var lines: PackedStringArray = PackedStringArray()
	if is_instance_valid(grid):
		lines.append(text_for(grid.get_streaming_metrics()))
	if AudioDirector.current != null:
		lines.append(AudioDirector.current.telemetry_line())
	return "\n".join(lines)


## The badge's line for a metrics snapshot (WorldGridManager.get_streaming_metrics).
static func text_for(metrics: Dictionary) -> String:
	var chunk: Vector2i = metrics.get("focus_chunk", Vector2i.ZERO)
	return "Landblock (%d, %d) · Active: %d · Clutter: %d · HLOD: %d · Queue: %d · Deltas: %d" % [chunk.x, chunk.y,
		int(metrics.get("active", 0)), int(metrics.get("clutter", 0)), int(metrics.get("hlod", 0)), int(metrics.get("queue", 0)),
		int(metrics.get("deltas", 0))]
