// The slate-violet ring breathing round an open Hush-Crack (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md
// §5 layer 3): a soft band on the ground at `ring_radius` metres from the crack,
// pulsing slowly like a held breath. Drawn on a flat plane `plane_size` metres across.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;

uniform vec4 ring_color : source_color = vec4(0.42, 0.37, 0.6, 1.0);
uniform float ring_radius = 2.6;
uniform float ring_width = 0.32;
uniform float plane_size = 6.4;
uniform float pulse_speed = 1.6;
uniform float strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float d = length(UV - vec2(0.5)) * plane_size;
	float band = 1.0 - smoothstep(0.0, ring_width, abs(d - ring_radius));
	float breath = 0.55 + 0.45 * sin(TIME * pulse_speed);
	// A faint dark pool inside the ring, and a ragged, breathing band round it.
	float ragged = 0.75 + 0.25 * sin(atan(UV.y - 0.5, UV.x - 0.5) * 9.0 + TIME * 0.7);
	ALBEDO = ring_color.rgb * (0.7 + 0.6 * breath);
	ALPHA = clamp(band * ragged * (0.35 + 0.5 * breath) * strength, 0.0, 1.0);
}
