// The continuous landscape (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §3.3), on
// Mode B's vertex-coloured Landblock meshes (the Terrain3D shader does the same).
// The painted colour field stays the ground's value; the atelier's turf,
// flagstone, loam and granite add their detail where the colour says they
// belong (granite on any slope steeper than about 32°), the ground's value is
// held in the mid-tones so telegraph rings always read, and open Hush-Cracks
// grey the turf while a sealed one sweeps its Reclamation Bloom outward.
//
// Phase 18 (18 GDD §3, §4.4, §5): road edges fray per pixel into a loam verge,
// steep banks show scree and cliffs show horizontal strata over a dark toe
// (the vertex alpha: 1 minus the toe), cloud shadows roll over it, and the
// First-Quiet's blight drains it toward ashen slate-indigo.
//
// docs/26: the Caldera's roads are drawn here per pixel from the island's laid
// roads (IslandBuilder.road_textures(): segments, a 16 m lookup grid and its
// index list), not from the vertex colours, so their edges are smooth curves
// whatever the triangles. Cobbled roads are small irregular setts laid along the
// road, each its own size and tint, the outer ones missing into the turf;
// earthen footpaths are packed earth and pebbles. A level without road data
// (road_grid.w = 0) draws the roads its vertex colours paint, as before.
shader_type spatial;
render_mode cull_back, specular_disabled;

#define STORYBOOK_CLOUD_POS v_world_pos
#define STORYBOOK_DRAWN_ROADS
#include "res://src/world/shaders/storybook_world_common.gdshaderinc"
#include "res://src/actors/storybook_brush.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform float detail_strength = 0.85;
uniform float normal_strength = 0.5;
// The ground's value is held between these, in linear light (about 33% to 58% on screen):
// a rich mid-ground under the meadow, still light enough for telegraph rings (docs/24 §4).
uniform float min_value = 0.08;
uniform float max_value = 0.3;

// The laid roads (docs/26). road_grid: the lookup grid's origin (x, z), cell size, and 1 when there are roads.
uniform sampler2D road_segs : filter_nearest, repeat_disable;
uniform sampler2D road_cells : filter_nearest, repeat_disable;
uniform sampler2D road_index : filter_nearest, repeat_disable;
uniform vec4 road_grid = vec4(0.0);
uniform ivec2 road_dims = ivec2(0);
// A sett's size (metres), and how far past the road's edge the trodden verge reaches.
uniform float sett_size = 0.2;
uniform float verge_width = 0.9;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec3 v_painted;
varying float v_toe;
// The worked land's tilth (docs/32 §4): xy the rows' direction times how strongly they show, z their spacing
// in metres, w their tone (-1 a dark furrow between pale ridges, +1 a green row of crop on bare soil).
varying vec4 v_tilth;

// A hash without sine (stable for the large cell indices along a long road).
vec2 road_hash2(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

// The road nearest `p`: x how far past its edge (negative inside), y the distance
// along it, z the signed distance across it, w its half width; `kind` 0 cobbled,
// 1 earthen; `dir` its direction. x is 1e4 where there's no road.
vec4 road_at(vec2 p, out float kind, out vec2 dir) {
	vec4 best = vec4(1.0e4, 0.0, 0.0, 1.0);
	kind = 0.0;
	dir = vec2(1.0, 0.0);
	if (road_grid.w < 0.5) {
		return best;
	}
	ivec2 cell = ivec2(floor((p - road_grid.xy) / road_grid.z));
	if (cell.x < 0 || cell.y < 0 || cell.x >= road_dims.x || cell.y >= road_dims.y) {
		return best;
	}
	vec2 listed = texelFetch(road_cells, cell, 0).xy;
	int start = int(listed.x + 0.5);
	int count = min(int(listed.y + 0.5), 48);
	for (int k = 0; k < count; k++) {
		int flat_index = start + k;
		int seg = int(texelFetch(road_index, ivec2(flat_index % 1024, flat_index / 1024), 0).r + 0.5);
		ivec2 at = ivec2((seg % 256) * 2, seg / 256);
		vec4 ab = texelFetch(road_segs, at, 0);
		vec4 extra = texelFetch(road_segs, at + ivec2(1, 0), 0);
		vec2 d = ab.zw - ab.xy;
		float len2 = max(dot(d, d), 1.0e-4);
		float t = clamp(dot(p - ab.xy, d) / len2, 0.0, 1.0);
		float edge = length(p - (ab.xy + d * t)) - extra.x;
		if (edge < best.x) {
			float len = sqrt(len2);
			vec2 unit = d / len;
			best = vec4(edge, extra.y + t * len, unit.x * (p.y - ab.y) - unit.y * (p.x - ab.x), extra.x);
			kind = extra.z;
			dir = unit;
		}
	}
	return best;
}

// Irregular setts in road space (`uv`: along, across, in sett sizes): x the
// stone's crown (0 in a joint, 1 on top), y and z the sett's own two random
// values, w its centre's distance across the road (in setts).
vec4 setts(vec2 uv, out vec2 to_centre) {
	vec2 cell = floor(uv);
	vec2 f = fract(uv);
	float d1 = 8.0;
	float d2 = 8.0;
	vec2 best_cell = cell;
	vec2 best_pt = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 o = vec2(float(x), float(y));
			vec2 pt = o + 0.12 + 0.76 * road_hash2(cell + o) - f;
			float dd = dot(pt, pt);
			if (dd < d1) {
				d2 = d1;
				d1 = dd;
				best_cell = cell + o;
				best_pt = pt;
			} else if (dd < d2) {
				d2 = dd;
			}
		}
	}
	vec2 r = road_hash2(best_cell + vec2(17.3, 5.1));
	to_centre = best_pt;
	float joint = sqrt(d2) - sqrt(d1);
	return vec4(smoothstep(0.04, 0.3, joint), r.x, r.y, (uv.y + best_pt.y));
}

// The road over the ground: cobbles or earth, the frayed edge, the trodden verge.
vec3 paint_road(vec3 ground, vec4 road, float kind, vec2 dir, vec3 world_pos, float sett_pixels, inout vec3 n) {
	vec2 p = world_pos.xz;
	float fray = world_noise(p * 0.9) * 0.65 + world_noise(p * 2.7 + vec2(17.0, 3.0)) * 0.35 - 0.5;
	float edge = road.x + fray * (kind > 0.5 ? 0.45 : 0.3);
	float bed = 1.0 - smoothstep(-0.12, 0.12, edge);
	// The trodden verge: a little darker and cooler, never yellow.
	float verge = (1.0 - smoothstep(0.0, verge_width, edge)) * (1.0 - bed);
	vec3 trodden = mix(ground, ground * vec3(0.86, 0.9, 0.86), 0.7);
	vec3 color = mix(ground, trodden, verge);
	vec3 base_tone = vec3(0.2, 0.18, 0.15);
	vec3 earth = vec3(0.24, 0.19, 0.13) * (0.9 + 0.2 * world_noise(p * 1.7));
	vec3 tangent = vec3(dir.x, 0.0, dir.y);
	vec3 across = vec3(-dir.y, 0.0, dir.x);
	if (kind > 0.5) {
		// An earthen footpath: packed earth, two worn ruts, pebbles, grass creeping in at the middle of a narrow one.
		vec2 grain = road_hash2(floor(p * 14.0));
		float pebble = step(0.93, grain.x) * (0.5 + 0.5 * grain.y);
		float rut = smoothstep(0.35, 0.0, abs(abs(road.z) / road.w - 0.55));
		vec3 path = earth * (1.0 - rut * 0.12) * (1.0 + pebble * 0.45);
		float middle = (1.0 - smoothstep(0.15, 0.4, abs(road.z))) * smoothstep(0.55, 0.8, world_noise(p * 1.3)) * step(road.w, 1.2);
		path = mix(path, ground * 0.9, middle);
		return mix(color, path, bed);
	}
	// Cobbles: setts laid along the road, each its own tint and size; the outer ones go missing into the turf.
	vec2 uv = vec2(road.y * 0.85, road.z) / sett_size;
	vec2 to_centre;
	vec4 sett = setts(uv, to_centre);
	// Weathered granite greys, warm sandstones, a pale limestone, a mossy one: each sett its own, lighter or darker.
	vec3 tints[6] = vec3[6](vec3(1.0, 0.98, 0.95), vec3(1.25, 1.1, 0.86), vec3(0.82, 0.84, 0.88), vec3(1.45, 1.38, 1.22), vec3(0.88, 0.95, 0.72), vec3(1.12, 0.98, 0.84));
	vec3 stone = base_tone * tints[int(sett.y * 5.99)] * (0.7 + 0.6 * sett.z);
	// Rounded crowns: dark toward the joint, a sunlit top.
	stone *= 0.55 + 0.6 * sqrt(sett.x);
	vec3 joint = mix(earth * 0.7, ground * 0.75, step(0.82, sett.z));
	vec3 laid = mix(joint, stone, sett.x);
	// Setts near the edge drop out at random, so the road ends in whole stones and turf between them.
	float centre_edge = abs(sett.w) * sett_size - road.w;
	float present = 1.0 - smoothstep(-0.05, 0.05, centre_edge + 0.55 * sett.z - 0.35 + fray * 0.3);
	// Far off, a sett is under a few pixels: fade the pattern to its average.
	float detail = 1.0 - smoothstep(0.25, 0.6, sett_pixels);
	laid = mix(base_tone * 0.95, laid, detail);
	float road_w = max(bed * present, bed * (1.0 - detail));
	// Each sett's crown leans its normal away from its centre.
	vec3 lean = (tangent * to_centre.x + across * to_centre.y) * sett.x * 0.9 * detail * road_w;
	n = normalize(n - lean);
	vec3 between = mix(earth * 0.85, ground * 0.8, 0.5);
	return mix(mix(color, between, bed * (1.0 - present) * detail), laid, road_w);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_painted = COLOR.rgb;
	v_toe = clamp(1.0 - COLOR.a, 0.0, 1.0);
	v_tilth = vec4(UV, UV2);
}

void fragment() {
	vec3 n = normalize(v_world_normal);
	// The painted field is authored in sRGB, like Terrain3D's colour maps.
	vec3 bent;
	vec3 color = storybook_ground(v_painted, albedo.rgb * pow(v_painted, vec3(2.2)), n, v_world_pos, v_toe, detail_strength, normal_strength, bent);
	n = bent;
	float value = luminance(color);
	color *= clamp(value, min_value, max_value) / max(value, 0.001);
	// The worked land's rows, drawn per pixel so a furrow is a furrow whatever the triangles (docs/32 §4).
	float till = length(v_tilth.xy);
	vec2 row_dir = v_tilth.xy / max(till, 0.0001);
	float row_space = max(v_tilth.z, 0.2);
	float across_rows = dot(v_world_pos.xz, vec2(-row_dir.y, row_dir.x));
	// How many rows one pixel covers (taken outside the branch: derivatives need every pixel of the quad).
	float rows_per_pixel = length(vec2(dFdx(across_rows), dFdy(across_rows))) / row_space;
	if (till > 0.02) {
		float tone = v_tilth.w;
		float shown = clamp(till, 0.0, 1.0);
		float near = 1.0 - smoothstep(0.16, 0.45, rows_per_pixel);
		// Far off, where a row is under a pixel, the field is its rows' average: a furrowed field a little
		// darker, a rowed one half leaf. Nothing else is worked out there.
		vec3 leaf = vec3(0.045, 0.1, 0.03);
		vec3 far = tone > 0.0 ? mix(color * 0.92, leaf, 0.5 * shown * tone) : color * mix(1.0, 0.9, shown * -tone);
		if (near <= 0.001) {
			color = far;
		} else {
			float phase = across_rows * 6.2831853 / row_space + world_noise(v_world_pos.xz * 0.12) * 1.4;
			float ridge = smoothstep(-0.55, 0.55, sin(phase));
			vec3 worked;
			if (tone > 0.0) {
				// Rows: leaf on the ridge, bare soil between.
				worked = mix(color * 0.92, leaf * (0.8 + 0.5 * world_noise(v_world_pos.xz * 2.3)), ridge * shown * tone);
			} else {
				// Furrows: a dark drain between pale, crumbled ridges.
				float clod = world_noise(v_world_pos.xz * 3.1);
				vec3 furrowed = color * mix(mix(1.0, 0.7, shown), mix(1.0, 1.1, shown), ridge) * (1.0 + (clod - 0.5) * 0.24 * shown);
				worked = mix(color, furrowed, -tone);
			}
			color = mix(far, worked, near);
			// Each ridge leans its normal away from its crest, so the low sun rakes the furrows.
			vec3 lean = vec3(-row_dir.y, 0.0, row_dir.x) * cos(phase) * 0.42 * shown * near * (tone > 0.0 ? 0.45 : abs(tone));
			n = normalize(n - lean);
		}
	}
	float road_kind;
	vec2 road_dir;
	vec4 road = road_at(v_world_pos.xz, road_kind, road_dir);
	// How much of a sett one pixel covers, taken outside the branch (derivatives need every pixel of the
	// quad): the mean of the two screen axes, so the long, foreshortened one doesn't blur near setts away.
	float sett_pixels = sqrt(length(dFdx(v_world_pos.xz)) * length(dFdy(v_world_pos.xz))) / sett_size;
	if (road.x < verge_width + 0.6) {
		// The road keeps its own, wider range of values, so each sett can be lighter or darker than the next.
		color = paint_road(color, road, road_kind, road_dir, v_world_pos, sett_pixels, n);
	}
	vec3 emission = vec3(0.0);
	apply_succession(v_world_pos, color, emission, 1.0);
	v_brush = sb_brush(v_world_pos * 0.6);
	ALBEDO = color;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	EMISSION = emission;
}

#include "res://src/actors/storybook_cel_light.gdshaderinc"
