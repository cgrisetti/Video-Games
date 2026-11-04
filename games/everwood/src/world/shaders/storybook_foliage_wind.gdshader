// Tree crowns, grass, ferns, flowers and reeds (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §3.4,
// 18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §4.1-4.2):
// crowns carry outward canopy normals baked into their meshes (so a cloud of
// leaf-lobes shades as one soft mass), lit in a three-band leaf ramp with a
// warm backlight where the sun shines through them; everything sways in the
// world wind with its own phase, and rolling wind-waves sweep over the
// meadows, bending grass up to 28 degrees with a gust sheen on the crest;
// grass roots take the ground's own colour; grass and ferns lean away from
// heroes within 1.2 m; upper crowns dither out of a camera's sightline; and
// inside an open Hush-Crack's blight the wind freezes, grass lies pressed
// flat and the colour drains (the Lantern's Promise holds it back).
shader_type spatial;
render_mode cull_disabled, specular_disabled;

#define STORYBOOK_CLOUD_POS v_world_pos
#define STORYBOOK_FOLIAGE_LIGHT
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
// Lush grass tufts (18 §4.2): the instance colour is the ground's own colour at
// the root (UV.y 1) and the blade ripens to `tip_color` toward its tip (UV.y 0);
// the rolling wind-wave bends it up to `wave_bend_degrees` with a sheen on the crest.
uniform bool grass_blades = false;
uniform vec4 tip_color : source_color = vec4(0.518, 0.741, 0.322, 1.0);
uniform float wave_bend_degrees = 28.0;
uniform float gust_sheen = 0.14;
// How much of the three-band leaf ramp a crown wears (18 §4.1; 0 grass and flowers).
uniform float leaf_ramp : hint_range(0.0, 1.0) = 0.0;
// How strongly the sun shines through leaves seen against it.
uniform float backlight : hint_range(0.0, 2.0) = 0.0;

// The world wind's everyday strength (WorldAtmosphereDirector.BASE_WIND.w): full bend at or above it.
const float WIND_FULL = 0.35;

varying vec3 v_world_pos;
varying vec3 v_color;
varying float v_crest;

void vertex() {
	vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	if (fade_out_distance > 0.0) {
		VERTEX *= 1.0 - smoothstep(fade_out_distance * 0.8, fade_out_distance, length(CAMERA_POSITION_WORLD - origin));
	}
	v_crest = 0.0;
	vec3 offset = vec3(0.0);
	if (grass_blades) {
		// Pressed flat by the First-Quiet inside an open crack's blight.
		float pressed = blight_wind.y > 0.0 ? blight_wind.y : 0.55;
		VERTEX.y *= mix(1.0, pressed, blight_at(origin));
		float up = max(VERTEX.y, 0.0);
		float still = frozen_wind_scale(origin);
		float strength = clamp(world_wind.w / WIND_FULL, 0.0, 1.0);
		float wave = wind_wave(origin.xz);
		float flutter = sin(TIME * 1.9 + dot(origin.xz, vec2(0.31, 0.27))) * 0.18;
		float tip_share = clamp(1.0 - UV.y, 0.0, 1.0);
		float angle = radians(wave_bend_degrees) * clamp(wave * 0.85 + flutter + 0.08, 0.0, 1.0) * strength * still * tip_share;
		vec2 dir = normalize(world_wind.xz + vec2(0.0001));
		offset = vec3(dir.x, 0.0, dir.y) * up * sin(angle) - vec3(0.0, up * (1.0 - cos(angle)), 0.0);
		v_crest = wave * strength * still;
	} else {
		float up = max(VERTEX.y, 0.0);
		offset = wind_offset(origin, clamp(up / sway_height, 0.0, 1.5), flex);
	}
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (brush > 0.0) {
		offset += brush_offset(world, max(VERTEX.y, 0.0)) * brush;
	}
	VERTEX += inverse(mat3(MODEL_MATRIX)) * offset;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_color = COLOR.rgb;
	if (grass_blades) {
		// The bottom 40% wears the ground's colour (UV.y above 0.6), ripening to the tip's.
		v_color = mix(tip_color.rgb, pow(COLOR.rgb, vec3(2.2)), smoothstep(0.2, 0.6, UV.y));
	}
}

void fragment() {
	if (sightline_fade && sightline_blocked(v_world_pos, CAMERA_POSITION_WORLD, FRAGCOORD.xy)) {
		discard;
	}
	// Vertex and instance colours are authored in sRGB, like the rest of the palette (grass is already linear).
	vec3 color = albedo.rgb * (grass_blades ? v_color : pow(v_color, vec3(2.2)));
	color *= 1.0 + dapple * (world_noise(v_world_pos.xz * 0.9 + v_world_pos.y * 0.6) - 0.5) * 2.0;
	// The gust sheen: a crest of the wind-wave catches the light as it rolls over.
	color *= 1.0 + gust_sheen * v_crest;
	vec3 emission = vec3(0.0);
	apply_succession(v_world_pos, color, emission, 1.0);
	ALBEDO = color;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	EMISSION = emission + rim_color.rgb * pow(1.0 - facing, rim_power) * rim_strength * color;
}

#include "res://src/actors/storybook_cel_light.gdshaderinc"
