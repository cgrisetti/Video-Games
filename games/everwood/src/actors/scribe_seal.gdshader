// A Scribe Card's floor seal (and the emblem on its vellum card): two rings
// with turning rune ticks around a Scribe Sign's geometric figure. It blooms out
// in the first quarter of its life and fades in the last part.
//   glyph 0 ring only · 1 gear (Iron-Root) · 2 star (Rime-Gale) · 3 sun (Warm-Hearth) · 4 moon (Star-Tide)
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0);
// 0..1 over the seal's life.
uniform float progress = 0.0;
uniform int glyph = 0;
uniform float intensity = 1.5;
// 1 holds the seal fully drawn (the card's emblem); 0 lets it bloom and fade.
uniform float hold = 0.0;


float line(float value, float center, float width) {
	return smoothstep(width, 0.0, abs(value - center));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float bloom = mix(smoothstep(0.0, 0.25, progress), 1.0, hold);
	float fade = mix(1.0 - smoothstep(0.65, 1.0, progress), 1.0, hold);
	float scale = mix(0.45, 1.0, bloom);
	vec2 q = p / scale;
	float r = length(q);
	float a = atan(q.y, q.x);
	float spin = progress * 1.5;
	float shape = line(r, 0.93, 0.035) + line(r, 0.78, 0.022);
	// Rune ticks turning between the rings.
	shape += step(0.81, r) * step(r, 0.9) * step(0.55, fract((a / TAU + spin * 0.1) * 24.0)) * 0.7;
	float figure = 0.0;
	if (glyph == 1) {
		float teeth = step(0.5, fract((a / TAU + spin * 0.05) * 12.0));
		figure = line(r, 0.44 + teeth * 0.09, 0.035) + line(r, 0.18, 0.03);
	} else if (glyph == 2) {
		float star = 0.28 + 0.3 * pow(0.5 + 0.5 * cos(6.0 * a), 5.0);
		figure = line(r, star, 0.035) + line(r, 0.12, 0.03);
	} else if (glyph == 3) {
		float rays = step(0.82, cos(16.0 * a)) * step(0.36, r) * step(r, 0.62);
		figure = line(r, 0.27, 0.035) + rays * 0.8;
	} else if (glyph == 4) {
		float disc = smoothstep(0.43, 0.4, r);
		float bite = smoothstep(0.37, 0.34, length(q - vec2(0.17, 0.05)));
		figure = clamp(disc - bite, 0.0, 1.0) * 0.75;
	}
	float alpha = clamp(shape + figure, 0.0, 1.0) * fade * step(r, 1.0);
	ALBEDO = tint.rgb * intensity;
	ALPHA = alpha * tint.a;
}
