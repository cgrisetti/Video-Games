// The characters' clothes, hair and fur: soft colour with a fine texture made in code, and a glow
// round the edges where light catches the fibres (so they stand out from the greenery).
// `weave` picks the texture: 0 felt (soft blotches), 1 knitted wool (little rows of stitches),
// 2 hair and fur (strands running down the piece), 3 leather (smooth, with creases and a sheen).
shader_type spatial;

#include "res://shaders/noise.gdshaderinc"

uniform vec3 cloth_color : source_color = vec3(0.78, 0.15, 0.11);
uniform vec3 shade_color : source_color = vec3(0.0); // If set, the texture's dips lean toward this.
uniform int weave : hint_range(0, 3) = 0;
uniform float scale = 1.0; // Bigger for a finer texture.
uniform float fuzz : hint_range(0.0, 1.0) = 0.45; // How much the edges glow.
uniform float softness : hint_range(0.0, 1.0) = 0.9; // Roughness.
uniform float translucency : hint_range(0.0, 1.0) = 0.0; // Light through thin hair and ears.

varying vec3 local_position;
varying vec3 local_normal;

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
}

// The texture's height at a spot on the piece, 0 to 1, from two directions blended by which way the
// surface faces, so it wraps round rounded shapes without stretching.
float pattern(vec3 p) {
	vec3 blend = abs(local_normal);
	blend /= blend.x + blend.y + blend.z;
	vec2 front = p.xy;
	vec2 side = p.zy;
	vec2 top = p.xz;
	if (weave == 1) {
		// Knit: rows of little V stitches.
		float rows = 48.0 * scale;
		float stitch_front = abs(fract(front.x * rows * 0.5) - 0.5) * 0.9 + fract(front.y * rows);
		float stitch_side = abs(fract(side.x * rows * 0.5) - 0.5) * 0.9 + fract(side.y * rows);
		float knit = mix(stitch_front, stitch_side, blend.x);
		return clamp(0.55 + 0.2 * sin(knit * 6.2832) + 0.25 * fbm(front * 14.0 * scale), 0.0, 1.0);
	}
	if (weave == 2) {
		// Strands: streaks running down the piece, finer than they are long.
		float around = atan(p.x, p.z) * 9.0 * scale;
		return fbm(vec2(around * 3.0, p.y * 6.0 * scale)) * 0.7 + value_noise(vec2(around * 9.0, p.y * 2.0)) * 0.3;
	}
	float broad = fbm(front * 9.0 * scale) * blend.z + fbm(side * 9.0 * scale) * blend.x + fbm(top * 9.0 * scale) * blend.y;
	if (weave == 3) {
		// Leather: smooth, with a few creases.
		float creases = smoothstep(0.42, 0.5, value_noise(front * 22.0 * scale)) * (1.0 - smoothstep(0.5, 0.58, value_noise(front * 22.0 * scale)));
		return broad * 0.6 + 0.4 - creases * 0.5;
	}
	// Felt: soft blotches and a fine fuzz.
	return broad * 0.75 + value_noise(front * 60.0 * scale + side * 40.0 * scale) * 0.25;
}

void fragment() {
	float height = pattern(local_position);
	vec3 dip = shade_color == vec3(0.0) ? cloth_color * 0.62 : shade_color;
	ALBEDO = mix(dip, cloth_color * 1.06, height);
	ROUGHNESS = weave == 3 ? softness * 0.7 : softness;
	SPECULAR = weave == 3 ? 0.45 : 0.25;
	// The texture catches the light: tilt the surface along its slope.
	float step_size = 0.004 / scale;
	float slope_x = pattern(local_position + vec3(step_size, 0.0, 0.0)) - height;
	float slope_y = pattern(local_position + vec3(0.0, step_size, 0.0)) - height;
	NORMAL_MAP = normalize(vec3(-slope_x * 4.0, -slope_y * 4.0, 1.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = weave == 3 ? 0.35 : 0.7;
	RIM = fuzz;
	RIM_TINT = 0.75;
	BACKLIGHT = cloth_color * translucency;
}
