// Raid telegraph floor marker. One standard look for every boss mechanic:
// a solid rim, a faint body, and a disc that fills from the centre to the rim
// as the cast completes. Gold soaks add stripes that flow inward ("stack here").
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.86, 0.08, 0.12, 1.0);
uniform float fill : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float soak = 0.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float rim = smoothstep(0.88, 0.95, r);
	float body = 0.16;
	float filled = step(r, fill) * 0.32;
	float front = smoothstep(fill - 0.05, fill, r) * step(r, fill) * 0.45;
	float stripes = soak * step(0.55, fract(r * 5.0 + TIME * 1.4)) * 0.22;
	float alpha = clamp(body + rim * 0.85 + filled + front + stripes + flash, 0.0, 1.0);
	ALBEDO = tint.rgb * (1.0 + flash * 1.5);
	ALPHA = alpha * fade;
}
