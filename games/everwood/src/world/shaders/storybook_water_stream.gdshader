// Canals, willow pools, water-shrines and Doverslap Falls
// (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §3.4): sunlit aqua (#52B8B2) in
// the shallows deepening to teal (#1F5E6B) with the water's depth (read from the
// scene behind it), ripples scrolling along the flow, white foam on the crests
// and where the water meets a bank or a pier, and on a waterfall a falling
// white-water curtain.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque, specular_schlick_ggx;

#include "res://src/world/shaders/storybook_world_common.gdshaderinc"

uniform vec4 shallow_color : source_color = vec4(0.322, 0.722, 0.698, 0.72);
uniform vec4 deep_color : source_color = vec4(0.122, 0.369, 0.42, 0.9);
// Where the water runs, in world metres a second (a waterfall: down its face, in UV).
uniform vec2 flow = vec2(0.0, 0.5);
uniform float ripple_scale = 0.9;
uniform float foam_amount = 0.3;
// Metres of water to reach the deep colour.
uniform float depth_fade = 1.4;
uniform bool waterfall = false;
// Water painted over a solid floor (a canal on the square, a basin's top) has no
// depth to read: this fixes its depth (0 to 1) and turns the shoreline foam off. -1: read the depth.
uniform float fixed_depth = -1.0;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float scene_depth = texture(depth_tex, SCREEN_UV).r;
	vec4 behind = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, scene_depth, 1.0);
	behind.xyz /= behind.w;
	float thickness = clamp(VERTEX.z - behind.z, 0.0, 50.0);
	float deep = waterfall ? 0.35 : (fixed_depth >= 0.0 ? fixed_depth : clamp(thickness / depth_fade, 0.0, 1.0));
	vec2 along = waterfall ? UV * vec2(6.0, 2.0) - vec2(0.0, TIME * flow.y * 2.0) : v_world_pos.xz * ripple_scale - flow * TIME;
	float ripple = world_noise(along * 1.7) * 0.6 + world_noise(along * 3.9 + vec2(TIME * 0.21, -TIME * 0.17)) * 0.4;
	float crest = smoothstep(0.66, 0.86, ripple) * foam_amount;
	float shore = (waterfall || fixed_depth >= 0.0) ? 0.0 : 1.0 - smoothstep(0.0, 0.22, thickness);
	float curtain = waterfall ? smoothstep(0.35, 0.8, world_noise(vec2(UV.x * 24.0, UV.y * 3.0 - TIME * flow.y * 3.0))) : 0.0;
	float foam = clamp(crest + shore * 0.8 + curtain * 0.9, 0.0, 1.0);
	vec4 water = mix(shallow_color, deep_color, deep);
	ALBEDO = mix(water.rgb, vec3(0.96, 0.98, 1.0), foam);
	ALPHA = clamp(mix(water.a, 1.0, foam * 0.85), 0.0, 1.0);
	float dx = world_noise(along * 1.7 + vec2(0.05, 0.0)) - world_noise(along * 1.7 - vec2(0.05, 0.0));
	float dz = world_noise(along * 1.7 + vec2(0.0, 0.05)) - world_noise(along * 1.7 - vec2(0.0, 0.05));
	vec3 n = normalize(vec3(-dx * 0.8, 1.0, -dz * 0.8));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	ROUGHNESS = mix(0.12, 0.6, foam);
	SPECULAR = 0.45;
	EMISSION = vec3(0.96, 0.98, 1.0) * foam * 0.15;
}
