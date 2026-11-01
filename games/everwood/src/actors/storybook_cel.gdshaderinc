// The storybook cel look shared by actors and props (07_EXPEDITION_HUD_AND_ART_GDD.md
// §4.2): two crisp bands of sunlight (lit, or a warm shade that is never muddy),
// a Fresnel rim light round the silhouette, tinted per material (by role on a
// hero, a soft warm light on scenery), and a glow for hit flashes and tells.
// storybook_cel.gdshader and storybook_cel_double.gdshader include this.

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.94, 0.8, 1.0);
uniform float rim_strength : hint_range(0.0, 3.0) = 0.25;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
// The shaded band: what the sun's light becomes on the far side and in shadow.
uniform vec4 shade_color : source_color = vec4(0.38, 0.33, 0.46, 1.0);
uniform float band_edge : hint_range(-1.0, 1.0) = 0.1;
uniform float band_softness : hint_range(0.001, 0.5) = 0.04;
// Hit flashes, flow glows and wind-up tells (StorybookMaterial.set_glow).
uniform vec4 glow : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	EMISSION = rim_color.rgb * pow(1.0 - facing, rim_power) * rim_strength + glow.rgb;
}

void light() {
	float lit = smoothstep(band_edge - band_softness, band_edge + band_softness, dot(NORMAL, LIGHT));
	if (LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += mix(shade_color.rgb, vec3(1.0), lit * ATTENUATION) * LIGHT_COLOR / PI;
	} else {
		DIFFUSE_LIGHT += lit * ATTENUATION * LIGHT_COLOR / PI;
	}
}
