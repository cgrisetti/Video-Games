// Bark and weathered wood: grooves running along the piece, with moss creeping onto the tops.
shader_type spatial;

#include "res://shaders/noise.gdshaderinc"

uniform vec3 bark_color : source_color = vec3(0.35, 0.25, 0.18);
uniform float stripe_scale = 1.0; // Bigger for finer grooves.
uniform vec3 moss_color : source_color = vec3(0.3, 0.42, 0.15);
uniform float moss = 0.35;

varying vec3 world_normal;
varying vec3 world_position;

void vertex() {
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 grain = vec2(UV.x * 10.0 * stripe_scale, UV.y * 1.2 * stripe_scale);
	float grooves = fbm(grain * vec2(1.0, 0.25));
	float knots = smoothstep(0.78, 0.9, value_noise(grain * vec2(0.6, 0.4) + 3.0));
	vec3 color = bark_color * mix(0.62, 1.15, grooves) * (1.0 - knots * 0.35);
	float mossy = smoothstep(0.55, 0.85, fbm(world_position.xz * 1.5 + world_position.y * 0.7) + world_normal.y * 0.4) * moss;
	ALBEDO = mix(color, moss_color, mossy);
	ROUGHNESS = 0.9;
	SPECULAR = 0.2;
	// Grooves catch the light: tilt the surface a little across them.
	float across = fbm(grain * vec2(1.0, 0.25) + vec2(0.05, 0.0)) - grooves;
	NORMAL_MAP = normalize(vec3(0.5 - across * 6.0, 0.5, 1.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.6;
}
