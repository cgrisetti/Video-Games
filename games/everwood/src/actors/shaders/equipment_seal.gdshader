// The one master equipment shader of the Seal-and-Tuck Grimoire
// (docs/everwood_equipment_grimoire_architecture.md Part II §3.2, §6.5).
// Layer 1 is a material tier's parametric PBR recipe (Tier 1 Orchard-Wood to
// Tier 7 Star-Glass & Ember-Iron): one mesh per piece wears all seven tiers by
// uniforms alone. Layer 2 is the Scribe Seal pressed onto the piece before
// battle: a scrolling calligraphic Deep-Ink band in the card's two inks, with
// the foil of its printing (Plain Ink flat, Gilded Leaf gold-flecked, Star-Ink
// a living star-field), and the Pocket-Pull's ignition flare on top.
//
// base_blend says how the shader sits on a mesh: 1.0 and it is the piece's own
// material (the buckler crest, the mantle band); lower and it is a next_pass
// over the hero atelier's sculpted weapon, washing the tier's tint and rim over
// it while the ink band stays crisp.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Layer 1: the material tier (Tiers 1..7).
uniform vec4 albedo_tint : source_color = vec4(0.55, 0.35, 0.17, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.88;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.15;
uniform vec4 rim_tint : source_color = vec4(0.82, 0.71, 0.55, 1.0);
uniform float normal_scale : hint_range(0.0, 2.0) = 1.0;
uniform float emissive_pulse_strength : hint_range(0.0, 2.0) = 0.0;

// Layer 2: the Scribe Seal and its Deep-Ink script.
uniform bool has_scribe_seal = false;
uniform vec4 ink_primary_color : source_color = vec4(0.58, 0.44, 0.86, 1.0);
uniform vec4 ink_secondary_color : source_color = vec4(0.88, 0.82, 1.0, 1.0);
// 0 Plain Ink, 1 Gilded Leaf, 2 Star-Ink.
uniform int foil_grade : hint_range(0, 2) = 0;
uniform float active_invocation_flare : hint_range(0.0, 3.0) = 0.0;
// Where the script band runs on the piece's UVs (its centre and width).
uniform float seal_band_center : hint_range(0.0, 1.0) = 0.25;
uniform float seal_band_width : hint_range(0.02, 1.0) = 0.14;
// 1.0: the piece's own material. Lower: a wash over the sculpt beneath (a next_pass).
uniform float base_blend : hint_range(0.0, 1.0) = 1.0;

// A crisp calligraphic band along the blade flat, the buckler face or the collar
// (no texture needed): the band's soft edges, and glyph-like ticks that scroll along it.
float procedural_deep_ink_script(vec2 uv) {
	float half_width = seal_band_width * 0.5;
	float band = smoothstep(seal_band_center - half_width, seal_band_center - half_width + 0.02, uv.y)
		* (1.0 - smoothstep(seal_band_center + half_width - 0.02, seal_band_center + half_width, uv.y));
	float scroll = uv.x + TIME * 0.05;
	float glyphs = step(0.45, sin(scroll * 48.0) * cos(uv.y * 64.0 + sin(scroll * 16.0)));
	return band * glyphs;
}

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 base_col = albedo_tint.rgb;
	float script_mask = 0.0;
	vec3 emission_accum = vec3(0.0);

	if (has_scribe_seal) {
		script_mask = procedural_deep_ink_script(UV);
		vec3 ink_col = mix(ink_primary_color.rgb, ink_secondary_color.rgb, 0.5 + 0.5 * sin(TIME * 2.5 + UV.x * 8.0));
		if (foil_grade == 1) {
			// Gilded Leaf: gold-leaf flecks in the lettering.
			float gold_fleck = step(0.85, hash21(floor(UV * 120.0)));
			ink_col = mix(ink_col, vec3(1.0, 0.86, 0.35), gold_fleck * 0.75);
		} else if (foil_grade == 2) {
			// Star-Ink: a living star-field twinkling inside the script.
			float star_twinkle = step(0.90, fract(sin(dot(UV * 160.0 + TIME * 0.2, vec2(39.346, 11.135))) * 29481.13));
			ink_col += vec3(0.9, 0.95, 1.0) * star_twinkle;
		}
		base_col = mix(base_col, ink_col, script_mask * 0.85);
		emission_accum += ink_col * script_mask * (0.85 + 0.35 * sin(TIME * 3.0) + active_invocation_flare);
	}

	// Tiers 4..7 breathe on their own; a Pocket-Pull flares every piece in its rim.
	if (emissive_pulse_strength > 0.0 || active_invocation_flare > 0.0) {
		float pulse = 0.65 + 0.35 * sin(TIME * 2.2);
		emission_accum += rim_tint.rgb * (emissive_pulse_strength * pulse + active_invocation_flare * 0.6);
	}

	// A faint hammered ripple in the surface, scaled by the tier's normal_scale (no normal map on the sculpt).
	float ripple = sin(UV.x * 90.0) * sin(UV.y * 70.0) * 0.02 * normal_scale;
	NORMAL = normalize(NORMAL + TANGENT * ripple + BINORMAL * ripple);

	ALBEDO = base_col;
	METALLIC = max(metallic, script_mask * float(foil_grade) * 0.45);
	ROUGHNESS = mix(roughness, 0.18, script_mask);
	RIM = rim_strength;
	RIM_TINT = 0.65;
	EMISSION = emission_accum;
	ALPHA = max(base_blend, script_mask * 0.95);
}
