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
shader_type spatial;
render_mode cull_back, specular_disabled;

#define STORYBOOK_CLOUD_POS v_world_pos
#include "res://src/world/shaders/storybook_world_common.gdshaderinc"
#include "res://src/actors/storybook_brush.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform float detail_strength = 0.85;
uniform float normal_strength = 0.5;
// The ground's value is held between these, in linear light (about 33% to 58% on screen):
// a rich mid-ground under the meadow, still light enough for telegraph rings (docs/24 §4).
uniform float min_value = 0.08;
uniform float max_value = 0.3;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec3 v_painted;
varying float v_toe;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_painted = COLOR.rgb;
	v_toe = clamp(1.0 - COLOR.a, 0.0, 1.0);
}

void fragment() {
	vec3 n = normalize(v_world_normal);
	// The painted field is authored in sRGB, like Terrain3D's colour maps.
	vec3 bent;
	vec3 color = storybook_ground(v_painted, albedo.rgb * pow(v_painted, vec3(2.2)), n, v_world_pos, v_toe, detail_strength, normal_strength, bent);
	n = bent;
	float value = luminance(color);
	color *= clamp(value, min_value, max_value) / max(value, 0.001);
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
