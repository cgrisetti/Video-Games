// The storybook cel lighting (07_EXPEDITION_HUD_AND_ART_GDD.md §4.2): two crisp
// bands of sunlight (lit, or a warm shade that is never muddy), and for metal
// (weapon tiers, 11 GDD §5.1) a crisp glint band where the sun catches it.
// storybook_cel.gdshaderinc and the Terrain3D landblock shader include this.

// The shaded band: what the sun's light becomes on the far side and in shadow.
uniform vec4 shade_color : source_color = vec4(0.38, 0.33, 0.46, 1.0);
uniform float band_edge : hint_range(-1.0, 1.0) = 0.1;
uniform float band_softness : hint_range(0.001, 0.5) = 0.04;
// How metallic the surface is (0 wood and cloth, up to 0.9 relic bronze), and how broad its glint is.
uniform float metal : hint_range(0.0, 1.0) = 0.0;
uniform float sheen_roughness : hint_range(0.05, 1.0) = 0.85;

void light() {
	float lit = smoothstep(band_edge - band_softness, band_edge + band_softness, dot(NORMAL, LIGHT));
	if (LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += mix(shade_color.rgb, vec3(1.0), lit * ATTENUATION) * LIGHT_COLOR / PI * (1.0 - metal * 0.35);
		if (metal > 0.0) {
			float spread = mix(96.0, 6.0, sheen_roughness);
			float glint = pow(max(dot(NORMAL, normalize(LIGHT + VIEW)), 0.0), spread);
			SPECULAR_LIGHT += smoothstep(0.42, 0.5, glint) * metal * lit * ATTENUATION * LIGHT_COLOR;
		}
	} else {
		DIFFUSE_LIGHT += lit * ATTENUATION * LIGHT_COLOR / PI;
	}
}
