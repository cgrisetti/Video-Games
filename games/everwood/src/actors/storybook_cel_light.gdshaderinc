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

#ifdef STORYBOOK_FOLIAGE_LIGHT
// The leaf ramp's three bands (linear: #78B84A, #488236, #234B28) and the backlight (18 GDD §4.1).
const vec3 LEAF_SUNLIT = vec3(0.188, 0.479, 0.068);
const vec3 LEAF_MID = vec3(0.065, 0.223, 0.037);
const vec3 LEAF_SHADE = vec3(0.017, 0.070, 0.021);
const vec3 LEAF_BACKLIGHT = vec3(0.45, 0.62, 0.18);
#endif

void light() {
	float lit = smoothstep(band_edge - band_softness, band_edge + band_softness, dot(NORMAL, LIGHT));
#ifdef STORYBOOK_CLOUD_POS
	// A world shader's rolling cloud shadows take part of the sun (18 GDD §4.4).
	float cloud = cloud_shadow(STORYBOOK_CLOUD_POS.xz, TIME) * (cloud_shadow_params.x > 0.0 ? cloud_shadow_params.x : 0.22);
#else
	float cloud = 0.0;
#endif
	if (LIGHT_IS_DIRECTIONAL) {
#ifdef STORYBOOK_FOLIAGE_LIGHT
		// Leaves (18 GDD §4.1): a three-band ramp, sunlit #78B84A, mid #488236 and
		// shade #234B28, worn as each band's shift from the sunlit one so every kit
		// keeps its own greens; and the sun's warm BACKLIGHT through leaves seen against it.
		float ndl = dot(NORMAL, LIGHT);
		float sunlit = smoothstep(0.32 - band_softness, 0.32 + band_softness, ndl) * ATTENUATION * (1.0 - cloud);
		float middle = smoothstep(-0.28 - band_softness, -0.28 + band_softness, ndl);
		vec3 ramp = mix(mix(LEAF_SHADE / LEAF_SUNLIT, LEAF_MID / LEAF_SUNLIT, middle), vec3(1.0), sunlit);
		vec3 cel = mix(shade_color.rgb, vec3(1.0), lit * ATTENUATION * (1.0 - cloud));
		DIFFUSE_LIGHT += mix(cel, max(ramp, shade_color.rgb * 0.45), leaf_ramp) * LIGHT_COLOR / PI;
		float through = pow(clamp(dot(VIEW, -LIGHT), 0.0, 1.0), 3.0) * (1.0 - cloud);
		DIFFUSE_LIGHT += LEAF_BACKLIGHT * through * backlight * ATTENUATION * LIGHT_COLOR / PI;
#else
		DIFFUSE_LIGHT += mix(shade_color.rgb, vec3(1.0), lit * ATTENUATION * (1.0 - cloud)) * LIGHT_COLOR / PI * (1.0 - metal * 0.35);
#endif
		if (metal > 0.0) {
			float spread = mix(96.0, 6.0, sheen_roughness);
			float glint = pow(max(dot(NORMAL, normalize(LIGHT + VIEW)), 0.0), spread);
			SPECULAR_LIGHT += smoothstep(0.42, 0.5, glint) * metal * lit * ATTENUATION * LIGHT_COLOR;
		}
	} else {
		DIFFUSE_LIGHT += lit * ATTENUATION * LIGHT_COLOR / PI;
	}
}
