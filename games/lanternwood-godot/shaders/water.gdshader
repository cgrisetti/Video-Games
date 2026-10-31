// Berry Rush's creek water: clear and green-gold in the shallows, deeper teal in the middle, with
// ripples drifting downstream, a little foam where it laps the banks, and the sky shining on it.
// It works out where the creek is from the same numbers as Creek (creek.gd), so the water's edge
// follows the banks exactly.
shader_type spatial;
render_mode cull_disabled, depth_draw_always;

#include "res://shaders/noise.gdshaderinc"

uniform vec3 shallow_color : source_color = vec3(0.45, 0.6, 0.42);
uniform vec3 deep_color : source_color = vec3(0.12, 0.36, 0.38);
uniform vec3 foam_color : source_color = vec3(0.93, 0.92, 0.84);
uniform float flow_speed = 0.35; // Metres a second the ripples drift downstream.
// The creek's shape (see creek.gd).
uniform float offset = -5.5;
uniform float wiggle = 2.5;
uniform float bend_rate = 0.2417;
uniform float bed_half_width = 1.1;
uniform float half_width = 2.6;
uniform float depth = 0.6;
uniform float water_level = -0.28;

varying vec3 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float along = (world.z - world.x) * 0.70710678;
	float across = (world.x + world.z) * 0.70710678;
	float lean = wiggle * bend_rate * cos(bend_rate * along);
	float from_middle = abs(across - (offset + wiggle * sin(bend_rate * along))) / sqrt(1.0 + lean * lean);
	float bed = -depth * (1.0 - smoothstep(bed_half_width, half_width, from_middle));
	float water_depth = water_level - bed; // How deep the water is here (negative: dry bank).
	vec2 flow = vec2(across * 2.4, along * 0.9 - TIME * flow_speed);
	float ripple = fbm(flow);
	float fine = fbm(flow * 2.7 + vec2(13.0, -TIME * 0.4));
	vec3 color = mix(shallow_color, deep_color, smoothstep(0.02, 0.28, water_depth));
	float foam = (1.0 - smoothstep(0.0, 0.05, water_depth)) * 0.8 + smoothstep(0.72, 0.86, fine) * 0.25 * (1.0 - smoothstep(0.05, 0.18, water_depth));
	ALBEDO = mix(color, foam_color, clamp(foam, 0.0, 1.0));
	ALPHA = smoothstep(-0.01, 0.025, water_depth) * mix(0.62, 0.9, smoothstep(0.0, 0.25, water_depth));
	ROUGHNESS = mix(0.14, 0.45, foam);
	SPECULAR = 0.35;
	float slope_x = fbm(flow + vec2(0.06, 0.0)) - ripple;
	float slope_y = fbm(flow + vec2(0.0, 0.06)) - ripple;
	NORMAL_MAP = normalize(vec3(-slope_x * 5.0, -slope_y * 5.0, 1.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.8;
}
