// A shaft of warm sunlight rising from the golden raspberry, soft at its edges and fading as it
// climbs, shimmering gently, so you can see where it is from anywhere in the field, over the trees.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://shaders/noise.gdshaderinc"

uniform vec3 beam_color : source_color = vec3(1.0, 0.74, 0.28);
uniform float strength = 1.1;

void fragment() {
	// How high up the beam this is: 0 at the berry, 1 at the top. (A cylinder's UV runs from the
	// top, 0, to the bottom, 1.)
	float up = 1.0 - UV.y;
	// Soft at the edges, where the beam is seen side-on...
	float edge = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), 1.4);
	// ...brightest low down, fading as it climbs, and softened right at its foot.
	float fade = pow(1.0 - up, 1.3) * smoothstep(0.0, 0.04, up);
	float shimmer = 0.7 + 0.3 * value_noise(vec2(UV.x * 12.0, UV.y * 6.0 - TIME * 0.6));
	ALBEDO = beam_color;
	ALPHA = clamp(edge * fade * shimmer * strength, 0.0, 1.0);
}
