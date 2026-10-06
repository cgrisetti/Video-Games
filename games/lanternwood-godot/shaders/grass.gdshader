// Grass blades: tufts that lean in the wind, glow when the sun is behind them, and part around
// the gnome's feet as it walks through.
shader_type spatial;
render_mode cull_disabled;

#include "res://shaders/noise.gdshaderinc"

uniform vec3 base_color : source_color = vec3(0.16, 0.28, 0.09);
uniform vec3 tip_color : source_color = vec3(0.55, 0.68, 0.26);
uniform vec3 dry_color : source_color = vec3(0.78, 0.72, 0.38);
uniform vec3 player_position = vec3(0.0, -100.0, 0.0); // Set by the Glen every frame.
uniform float part_radius = 0.9; // How far around the gnome the grass parts.

varying float height;
varying float dryness;

void vertex() {
	height = UV.y;
	dryness = INSTANCE_CUSTOM.r;
	vec3 root = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float bend = height * height;
	float wind = wind_at(root, TIME);
	vec3 push = vec3(wind * 0.35, 0.0, wind * 0.2);
	// Part around the gnome.
	vec3 away = root - player_position;
	away.y = 0.0;
	float near = 1.0 - smoothstep(0.0, part_radius, length(away));
	push += normalize(away + vec3(0.001, 0.0, 0.0)) * near * 0.8;
	// Push in world space, turned into the blade's own space.
	vec3 local_push = (inverse(MODEL_MATRIX) * vec4(push, 0.0)).xyz;
	VERTEX += local_push * bend;
	VERTEX.y -= length(push) * bend * 0.25;
}

void fragment() {
	vec3 tip = mix(tip_color, dry_color, dryness);
	vec3 color = mix(base_color, tip, smoothstep(0.0, 1.0, height));
	ALBEDO = color;
	ROUGHNESS = 0.8;
	SPECULAR = 0.3;
	BACKLIGHT = tip * 0.5 * height;
	// Light each blade like the ground it grows from, so the meadow reads as one soft surface.
	vec3 up = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	NORMAL = normalize(mix(FRONT_FACING ? NORMAL : -NORMAL, up, 0.7));
	AO = mix(0.35, 1.0, height);
	AO_LIGHT_AFFECT = 0.6;
}
