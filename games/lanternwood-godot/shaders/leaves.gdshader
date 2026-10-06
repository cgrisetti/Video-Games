// Leaves on trees, bushes and hedges: cards cut out from a leaf texture, coloured from a darker
// inner shade to sunlit tips, swaying in the wind, and glowing softly when the sun is behind them.
shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

#include "res://shaders/noise.gdshaderinc"

uniform sampler2D leaf_texture : source_color, filter_linear_mipmap_anisotropic;
uniform vec3 tip_color : source_color = vec3(0.45, 0.62, 0.22);
uniform vec3 base_color : source_color = vec3(0.12, 0.25, 0.1);
uniform float sway = 1.0; // How much these leaves move in the wind.
uniform float translucency : hint_range(0.0, 1.0) = 0.55;
uniform float variety : hint_range(0.0, 0.5) = 0.18; // How much each card's colour differs.

varying float outer; // 0 deep inside the crown, 1 at its edge.
varying float random;

void vertex() {
	outer = COLOR.r;
	random = COLOR.g;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float wind = wind_at(world, TIME);
	float flutter = sin(TIME * 7.0 + random * 40.0 + world.y * 3.0) * 0.015;
	VERTEX += vec3(wind * 0.07, wind * 0.02, wind * 0.05) * sway * outer + flutter * sway;
}

void fragment() {
	vec4 leaf = texture(leaf_texture, UV);
	ALPHA = leaf.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	vec3 color = mix(base_color, tip_color, smoothstep(0.45, 1.0, outer));
	color *= 1.0 + (random - 0.5) * variety * 2.0;
	color = mix(color, color * vec3(1.08, 1.0, 0.82), step(0.85, random)); // A few autumn-touched cards.
	ALBEDO = color * (0.55 + 0.45 * leaf.r);
	ROUGHNESS = 0.75;
	SPECULAR = 0.25;
	BACKLIGHT = color * translucency;
	// Keep the crown's rounded shading on both sides of each card.
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
	AO = mix(0.45, 1.0, outer);
	AO_LIGHT_AFFECT = 0.4;
}
