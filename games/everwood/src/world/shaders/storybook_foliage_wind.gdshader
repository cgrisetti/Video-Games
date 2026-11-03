// Tree crowns, grass, ferns, flowers and reeds (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §3.4):
// crowns carry outward canopy normals baked into their meshes (so a cluster of
// leaf-puffs shades as one soft cloud), everything sways in the world wind with
// its own phase, grass and ferns lean away from heroes within 1.2 m, upper
// crowns dither out of a camera's sightline, and the Hush-Cracks grey them too.
shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://src/world/shaders/storybook_world_common.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
// Metres over which the plant bends from its root (its tip moves most).
uniform float sway_height = 6.0;
// How far it bends in the wind.
uniform float flex = 0.25;
// Lean away from heroes (grass 1, crowns 0).
uniform float brush = 0.0;
uniform bool sightline_fade = false;
// Past this distance from the camera the plant has shrunk away (0: never; ground clutter, §6.1 Ring 1).
uniform float fade_out_distance = 0.0;
// Leafy light-and-shade.
uniform float dapple = 0.14;
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.7, 1.0);
uniform float rim_strength : hint_range(0.0, 3.0) = 0.22;
uniform float rim_power : hint_range(0.5, 8.0) = 2.5;

varying vec3 v_world_pos;
varying vec3 v_color;

void vertex() {
	vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	if (fade_out_distance > 0.0) {
		VERTEX *= 1.0 - smoothstep(fade_out_distance * 0.8, fade_out_distance, length(CAMERA_POSITION_WORLD - origin));
	}
	float up = max(VERTEX.y, 0.0);
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 offset = wind_offset(origin, clamp(up / sway_height, 0.0, 1.5), flex);
	if (brush > 0.0) {
		offset += brush_offset(world, up) * brush;
	}
	VERTEX += inverse(mat3(MODEL_MATRIX)) * offset;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_color = COLOR.rgb;
}

void fragment() {
	if (sightline_fade && sightline_blocked(v_world_pos, CAMERA_POSITION_WORLD, FRAGCOORD.xy)) {
		discard;
	}
	// Vertex and instance colours are authored in sRGB, like the rest of the palette.
	vec3 color = albedo.rgb * pow(v_color, vec3(2.2));
	color *= 1.0 + dapple * (world_noise(v_world_pos.xz * 0.9 + v_world_pos.y * 0.6) - 0.5) * 2.0;
	vec3 emission = vec3(0.0);
	apply_succession(v_world_pos, color, emission, 1.0);
	ALBEDO = color;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	EMISSION = emission + rim_color.rgb * pow(1.0 - facing, rim_power) * rim_strength * color;
}

#include "res://src/actors/storybook_cel_light.gdshaderinc"
