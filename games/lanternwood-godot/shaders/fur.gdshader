// The fox's fur: the markings painted into its skin (orange coat, cream chest and cheeks, dark
// stockings and ear tips, a white tail tip), with soft, fine fur texture, a gentle glow round the
// edges, and a little light through thin parts like the ears. The texture is worked out from where
// each point sits on the standing fox (kept in the mesh's UVs), so it stays put on the skin as it
// moves, and it's laid on from three sides at once, so it never smears into stripes on a flank.
shader_type spatial;

#include "res://shaders/noise.gdshaderinc"

uniform float fur_scale = 90.0; // Bigger for finer fur.
uniform float fuzz : hint_range(0.0, 1.0) = 0.4;
uniform float translucency : hint_range(0.0, 1.0) = 0.15;
// Fades the fox out with a fine stipple when it's in front of the gnome. Stippling keeps it drawn
// solid, so its far legs don't show through its body the way a see-through fade would.
instance uniform float fade : hint_range(0.0, 1.0) = 0.0;

varying vec3 rest;

void vertex() {
	rest = vec3(UV.x, UV.y, UV2.x);
}

// Fine fur seen from one side: short streaks running along p.y, over finer speckle.
float side_fur(vec2 p) {
	float streaks = value_noise(vec2(p.x * fur_scale * 1.8, p.y * fur_scale * 0.5));
	float fine = value_noise(p * fur_scale * 0.9 + 7.3);
	return streaks * 0.6 + fine * 0.4;
}

float fur(vec3 p, vec3 facing) {
	vec3 blend = pow(abs(facing), vec3(4.0));
	blend /= blend.x + blend.y + blend.z + 0.0001;
	// Flanks (facing x): streaks along the body. Back and belly (facing y): along the body too.
	// Front and back (facing z): running down.
	return side_fur(vec2(p.y, p.z)) * blend.x + side_fur(vec2(p.x, p.z)) * blend.y + side_fur(vec2(p.x, p.y)) * blend.z;
}

void fragment() {
	vec3 facing = normalize(cross(dFdx(rest), dFdy(rest)));
	float height = fur(rest, facing);
	vec3 base = COLOR.rgb;
	ALBEDO = base * mix(0.86, 1.05, height);
	ROUGHNESS = 0.95;
	SPECULAR = 0.12;
	NORMAL_MAP = normalize(vec3((height - 0.5) * 0.35, (height - 0.5) * 0.2, 1.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.3;
	RIM = fuzz;
	RIM_TINT = 0.85;
	BACKLIGHT = base * translucency;
	ALPHA = 1.0 - fade;
	ALPHA_HASH_SCALE = 1.0;
}
