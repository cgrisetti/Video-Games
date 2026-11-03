// The continuous landscape (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §3.3), on
// Mode B's vertex-coloured Landblock meshes (the Terrain3D shader does the same).
// The painted colour field stays the ground's value; the atelier's turf,
// flagstone, loam and granite add their detail where the colour says they
// belong (granite on any slope steeper than about 32°), the ground's value is
// held in the mid-tones so telegraph rings always read, and open Hush-Cracks
// grey the turf while a sealed one sweeps its Reclamation Bloom outward.
shader_type spatial;
render_mode cull_back, specular_disabled;

#include "res://src/world/shaders/storybook_world_common.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform float detail_strength = 0.85;
uniform float normal_strength = 0.5;
// The ground's value is held between these, in linear light (about 35% to 68% on screen).
uniform float min_value = 0.09;
uniform float max_value = 0.42;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec3 v_painted;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_painted = COLOR.rgb;
}

void fragment() {
	vec3 n = normalize(v_world_normal);
	// The painted field is authored in sRGB, like Terrain3D's colour maps.
	vec3 color = albedo.rgb * pow(v_painted, vec3(2.2));
	if (atelier_ready > 0.5) {
		vec4 classes = terrain_class_weights(v_painted, n);
		vec3 bent;
		vec3 detail = terrain_detail(v_world_pos, n, classes, normal_strength, bent);
		color *= mix(vec3(1.0), detail, detail_strength);
		n = bent;
	}
	float value = luminance(color);
	color *= clamp(value, min_value, max_value) / max(value, 0.001);
	vec3 emission = vec3(0.0);
	apply_succession(v_world_pos, color, emission, 1.0);
	ALBEDO = color;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	EMISSION = emission;
}

#include "res://src/actors/storybook_cel_light.gdshaderinc"
