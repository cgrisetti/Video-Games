## The Caldera's roads laid over the land (docs/26_ROADS_LAID_OVER_THE_LAND.md),
## checked on all five isles once the Caldera has booted. Run by
## tools/test_caldera_isles.gd (so by the smoke test and tools/run_caldera_checks.gd):
##   1  every road is laid: routed roads wander from their straight control lines
##      and stay smooth (no bend sharper than MAX_BEND between 3 m steps), keep
##      off the water and off steep ground, and still reach their ends
##   2  the ground shader draws them: each isle has road data, the live isle's is
##      on the terrain material, and the vertices no longer paint roads
##   3  the map and the scatter read the laid roads, not the old straight lines
extends RefCounted

## The sharpest bend between two 3 m steps of a laid road (degrees).
const MAX_BEND: float = 30.0
## The steepest a road may climb, as a grade: walkable (under 40°), ramps, stairs and Rime-Firth's ridged rim included.
const MAX_GRADE: float = 0.85
## A routed road ends within this far of where it was asked to end.
const END_SLACK: float = 0.5

var check: Callable
var level: CalderaArchipelagoWorld


func run(live_level: CalderaArchipelagoWorld, checker: Callable) -> void:
	check = checker
	level = live_level
	_check_laid()
	_check_drawn()
	_check_read()


func _check_laid() -> void:
	var routed: int = 0
	var wander: float = 0.0
	var worst_bend: float = 0.0
	var worst_grade: float = 0.0
	var wet: int = 0
	var ends_ok: bool = true
	var problems: PackedStringArray = PackedStringArray()
	for id: StringName in CalderaAtlas.ISLES:
		var builder: IslandBuilder = CalderaAtlas.builder_for(id)
		var plans: Array[Dictionary] = builder.get("_road_plans")
		for index: int in builder.laid_roads.size():
			var points: PackedVector2Array = builder.laid_roads[index]["points"]
			var asked: PackedVector2Array = plans[index]["points"]
			ends_ok = ends_ok and points[0].distance_to(asked[0]) < END_SLACK and points[points.size() - 1].distance_to(asked[asked.size() - 1]) < END_SLACK
			if bool(plans[index]["route"]):
				routed += 1
				# How far the laid road strays from its straight control line, at its widest.
				var widest: float = 0.0
				for at: Vector2 in points:
					widest = maxf(widest, _distance_to_line(at, asked))
				wander = maxf(wander, widest)
			for step: int in range(1, points.size() - 1):
				var a: Vector2 = points[step] - points[step - 1]
				var b: Vector2 = points[step + 1] - points[step]
				if a.length() > 0.5 and b.length() > 0.5:
					var bend: float = rad_to_deg(absf(a.angle_to(b)))
					if bend > worst_bend:
						worst_bend = bend
			for step: int in points.size() - 1:
				var h0: float = builder.height_at(points[step].x, points[step].y)
				var h1: float = builder.height_at(points[step + 1].x, points[step + 1].y)
				var run_m: float = points[step].distance_to(points[step + 1])
				if run_m > 0.5:
					worst_grade = maxf(worst_grade, absf(h1 - h0) / run_m)
				# Under the sea anywhere but the approaches to a quay, a causeway or a cove (they're at the waterline).
				if h0 < 0.0 and points[step].distance_to(points[0]) > 40.0 and points[step].distance_to(points[points.size() - 1]) > 40.0:
					wet += 1
					if problems.size() < 3:
						problems.append("%s road %d dips under the sea at %s" % [id, index, points[step]])
	check.call(routed >= 15 and wander > 8.0 and worst_bend <= MAX_BEND and worst_grade <= MAX_GRADE and wet == 0 and ends_ok,
		"the roads are laid over the land: %d routed roads wander up to %.0f m from their straight lines, bend at most %.0f° between 3 m steps, climb at most a %.0f%% grade, keep out of the sea and still reach their ends%s"
		% [routed, wander, worst_bend, worst_grade * 100.0, "" if problems.is_empty() else ": " + "; ".join(problems)])


func _check_drawn() -> void:
	var counts: PackedStringArray = PackedStringArray()
	var all_have: bool = true
	for id: StringName in CalderaAtlas.ISLES:
		var data: Dictionary = CalderaAtlas.builder_for(id).road_textures()
		all_have = all_have and int(data["segments"]) > 0 and data["segs"] is ImageTexture
		counts.append(String(id).trim_prefix("isle_") + " " + str(data["segments"]))
	var terrain: ShaderMaterial = WorldVisualCatalog.terrain()
	var grid: Vector4 = terrain.get_shader_parameter(&"road_grid")
	var live: Dictionary = level.streamer.builder.road_textures()
	var on_material: bool = is_equal_approx(grid.w, 1.0) and terrain.get_shader_parameter(&"road_segs") == live["segs"]
	# A vertex on a road is painted as plain ground now: the shader draws the road.
	var builder: IslandBuilder = level.streamer.builder
	var road: PackedVector2Array = builder.laid_roads[0]["points"]
	var mid: Vector2 = road[road.size() / 2]
	var h: float = builder.height_at(mid.x, mid.y)
	var unpainted: bool = builder.surface_color(mid.x, mid.y, h, 1.0) == builder._ground_color(mid.x, mid.y, h, 1.0)
	var shader_code: String = (terrain.shader as Shader).code
	var drawn: bool = shader_code.contains("vec4 road_at(") and shader_code.contains("vec4 setts(")
	check.call(all_have and on_material and unpainted and drawn,
		"the ground shader draws the laid roads per pixel (smooth edges, small setts along cobbled roads, earth on footpaths): every isle has road data (%s segments), the live isle's is on the terrain material, and the vertices no longer paint roads"
		% ", ".join(counts))


## Checked on Iron-Ness: its roads are routed (Embershore's are drawn from its generator, never re-routed).
func _check_read() -> void:
	var builder: IslandBuilder = CalderaAtlas.builder_for(CalderaAtlas.ISLE_IRON_NESS)
	var plans: Array[Dictionary] = builder.get("_road_plans")
	# Find a stretch where a routed road wandered well off its straight line.
	var off_line: Vector2 = Vector2.INF
	var on_road: Vector2 = Vector2.INF
	for index: int in builder.laid_roads.size():
		if not bool(plans[index]["route"]):
			continue
		var asked: PackedVector2Array = plans[index]["points"]
		for at: Vector2 in builder.laid_roads[index]["points"]:
			var gap: float = _distance_to_line(at, asked)
			if gap > 12.0:
				on_road = at
				var nearest: Vector2 = _closest_on_line(at, asked)
				# The old straight line there, if no laid road passes near it.
				if builder.nearest_road(nearest).is_empty() or nearest.distance_to(Vector2(builder.nearest_road(nearest)["at"])) > 6.0:
					off_line = nearest
				break
		if on_road != Vector2.INF and off_line != Vector2.INF:
			break
	var layout: CalderaLayout = CalderaLayout.new(builder)
	var map_follows: bool = on_road != Vector2.INF and off_line != Vector2.INF and builder.on_path(on_road.x, on_road.y) \
		and not builder.on_path(off_line.x, off_line.y) and layout.map_feature(on_road.x, on_road.y, builder.height_at(on_road.x, on_road.y)) == WorldLayout.MapFeature.ROAD
	check.call(map_follows,
		"the Zone Map and the scatter read the laid roads: a bend of an Iron-Ness road 12 m off its old straight line is road, and the old line there is open ground")


static func _distance_to_line(at: Vector2, line: PackedVector2Array) -> float:
	return at.distance_to(_closest_on_line(at, line))


static func _closest_on_line(at: Vector2, line: PackedVector2Array) -> Vector2:
	var best: Vector2 = line[0]
	for index: int in line.size() - 1:
		var point: Vector2 = Geometry2D.get_closest_point_to_segment(at, line[index], line[index + 1])
		if at.distance_to(point) < at.distance_to(best):
			best = point
	return best
