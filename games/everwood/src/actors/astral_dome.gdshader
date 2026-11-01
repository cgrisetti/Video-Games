// A Star-Inked Vellum card's starfield dome: twinkling points of light on a
// translucent hemisphere, brightest at its rim.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.75, 0.6, 1.0, 1.0);
uniform float strength = 1.0;
const vec2 STAR_GRID = vec2(48.0, 24.0);

float hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(UV * STAR_GRID);
	vec2 local = fract(UV * STAR_GRID) - 0.5;
	float seed = hash(cell);
	float star = step(0.8, seed) * smoothstep(0.2, 0.0, length(local));
	float twinkle = 0.55 + 0.45 * sin(TIME * 6.0 + seed * 40.0);
	float rim = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.5) * 0.35;
	ALBEDO = mix(tint.rgb, vec3(1.0), star * 0.5) * 2.0;
	ALPHA = clamp(star * twinkle + rim, 0.0, 1.0) * strength * tint.a;
}
