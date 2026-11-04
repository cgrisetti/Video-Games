// The heroes' storybook look (19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md §4,
// Stage 4): one material paints a whole sculpted hero (HeroMeshAtelier) and,
// with the tier's metals, their weapon. Every vertex carries what it is in its
// colour, so one draw call reads as wool, leather, brass and a speckled beard:
//   COLOR.r  crevice AO (1 open, toward 0 in the folds)
//   COLOR.g  the chamfer / curvature mask: worn, lighter edges on rims and buckles
//   COLOR.b  the material id (HeroMeshAtelier.MAT_*), decoded below in five bands:
//            < 0.1 Value 1 heritage wool, boots, breeches   (twill, rough 0.88)
//            < 0.3 the Calling's tabard, the Fellowship tunic, trim
//            < 0.5 Value 2 hewn timber, oiled leather, linen, rope (rough 0.72)
//            < 0.7 forged iron, ring-mail, brass, steel (a MatCap highlight band)
//            else  skin, the speckled woodsman beard, eyes, hair
//   COLOR.a  recessed Maker-Seal veins that glow in the active Sign
//   UV2.x    the vertex's height at rest, for the 60-30-10 vertical gradient
// The light is a two-band cel ramp, anti-aliased by its own screen-space
// derivative, whose shade is warmed by the biome's turf bounce; a Fresnel rim
// in the Fellowship's colour; Dread-Chill hoar-rime on the lowest 0.45 m and
// The Lantern's Promise's Saffron-Gold rim; and a 4x4 Bayer dither when the
// camera comes within 1.1 m.
shader_type spatial;
render_mode cull_back, specular_disabled;

// The biome's turf (WorldAtmosphereDirector sets it; a = 1 once it has).
global uniform vec4 ground_turf;

group_uniforms value_one;
uniform vec4 value_1_coat_color : source_color = vec4(0.180, 0.251, 0.169, 1.0);
uniform vec4 value_1_boot_color : source_color = vec4(0.212, 0.157, 0.118, 1.0);
uniform vec4 value_1_breeches_color : source_color = vec4(0.15, 0.13, 0.11, 1.0);
group_uniforms calling;
uniform vec4 calling_trim_color : source_color = vec4(0.769, 0.584, 0.251, 1.0);
uniform vec4 fellowship_tunic_color : source_color = vec4(0.231, 0.478, 0.278, 1.0);
uniform vec4 trim_accent_color : source_color = vec4(0.85, 0.72, 0.42, 1.0);
group_uniforms value_two;
uniform vec4 value_2_timber_leather_color : source_color = vec4(0.612, 0.447, 0.314, 1.0);
uniform vec4 value_2_linen_color : source_color = vec4(0.839, 0.780, 0.698, 1.0);
uniform vec4 rope_color : source_color = vec4(0.72, 0.62, 0.44, 1.0);
group_uniforms metals;
uniform vec4 metal_iron_color : source_color = vec4(0.353, 0.384, 0.416, 1.0);
uniform vec4 metal_brass_color : source_color = vec4(0.769, 0.584, 0.251, 1.0);
uniform vec4 metal_steel_color : source_color = vec4(0.769, 0.808, 0.831, 1.0);
uniform float equipment_metallic : hint_range(0.0, 1.0) = 0.55;
uniform float equipment_roughness : hint_range(0.0, 1.0) = 0.52;
group_uniforms face;
uniform vec4 skin_tone_color : source_color = vec4(0.86, 0.68, 0.56, 1.0);
uniform vec4 beard_primary_color : source_color = vec4(0.290, 0.196, 0.133, 1.0);
uniform vec4 beard_speckle_color : source_color = vec4(0.722, 0.753, 0.784, 1.0);
uniform float beard_speckle_ratio : hint_range(0.0, 1.0) = 0.28;
uniform vec4 eye_color : source_color = vec4(0.16, 0.11, 0.08, 1.0);
group_uniforms light_and_play;
// The cel ramp's shade band and edge.
uniform vec4 shade_color : source_color = vec4(0.40, 0.35, 0.47, 1.0);
uniform float band_edge : hint_range(-1.0, 1.0) = 0.08;
// The turf's bounce when no biome has set one (#5B8C4A meadow, linear), and how much it warms the shade.
uniform vec3 biome_turf_bounce = vec3(0.105, 0.262, 0.069);
uniform float turf_bounce_strength : hint_range(0.0, 2.0) = 0.9;
// The Fellowship's silhouette rim (StorybookMaterial's rim_color / rim_strength names, so swells can retint it).
uniform vec4 rim_color : source_color = vec4(0.322, 0.769, 0.471, 1.0);
uniform float rim_strength : hint_range(0.0, 3.0) = 0.7;
// Hit flashes and flow glows (StorybookMaterial.set_glow).
uniform vec4 glow : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// The active Scribe Sign's veins: its colour and 0 to 2.4.
uniform vec4 active_sign_color : source_color = vec4(1.0, 0.9, 0.62, 1.0);
uniform float sign_emission_strength : hint_range(0.0, 2.4) = 0.0;
// Value 3's lift on the Sign spark.
uniform float value_3_emission_mult = 1.8;
// The solo 9-frame Dread-Chill window frosts the lowest 0.45 m; The Lantern's Promise warms the rim.
uniform float dread_chill_frost : hint_range(0.0, 1.0) = 0.0;
uniform float lantern_promise_warmth : hint_range(0.0, 1.0) = 0.0;
uniform vec4 frost_color : source_color = vec4(0.80, 0.90, 0.98, 1.0);
uniform vec4 promise_color : source_color = vec4(0.98, 0.72, 0.18, 1.0);
// Closer than this, the hero dithers away so the camera never looks out through their head.
uniform float camera_fade_distance = 1.1;

varying float v_aa;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

// 3D cellular hair-strand noise: 1 where this strand cell is a speckle, about `ratio` of the cells.
float strand_speckle(vec3 p, float ratio) {
	vec3 cell = floor(p);
	vec3 local = fract(p);
	float best = 1.0;
	float pick = 0.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec3 other = vec3(float(x), float(y), 0.0);
			vec3 seed = vec3(hash13(cell + other), hash13(cell + other + 17.0), 0.5);
			float d = length((other + seed - local) * vec3(1.0, 0.35, 1.0));
			if (d < best) {
				best = d;
				pick = hash13(cell + other + 41.7);
			}
		}
	}
	return step(pick, ratio) * (1.0 - smoothstep(0.55, 0.9, best));
}

float bayer4(vec2 frag) {
	int x = int(mod(frag.x, 4.0));
	int y = int(mod(frag.y, 4.0));
	int index = x + y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[index] + 0.5) / 16.0;
}

void fragment() {
	float m = COLOR.b;
	float rest_y = UV2.x;
	vec3 base = value_1_coat_color.rgb;
	float rough = 0.88;
	float metal = 0.0;
	float twill = 0.0;
	float v_metal_glint = 0.0;
	if (m < 0.1) {
		// Value 1: heritage wool, oiled bog-leather boots, dark breeches.
		base = m < 0.04 ? value_1_coat_color.rgb : (m < 0.075 ? value_1_boot_color.rgb : value_1_breeches_color.rgb);
		twill = m < 0.04 ? 1.0 : 0.35;
		rough = m < 0.04 ? 0.88 : 0.74;
	} else if (m < 0.3) {
		// The Calling's tabard, the Fellowship tunic, trim.
		base = m < 0.19 ? calling_trim_color.rgb : (m < 0.245 ? fellowship_tunic_color.rgb : trim_accent_color.rgb);
		twill = 0.6;
		rough = 0.8;
	} else if (m < 0.5) {
		// Value 2: hewn timber and oiled leather, gambeson linen, hemp rope.
		base = m < 0.385 ? value_2_timber_leather_color.rgb : (m < 0.445 ? value_2_linen_color.rgb : rope_color.rgb);
		rough = 0.72;
		twill = m >= 0.385 ? 0.45 : 0.0;
	} else if (m < 0.7) {
		// Forged metals: iron, ring-mail, brass, steel.
		if (m < 0.56) {
			base = metal_iron_color.rgb;
		} else if (m < 0.59) {
			// Ring-mail: rows of little rings.
			vec2 rings = fract(UV * vec2(46.0, 38.0) + vec2(0.0, floor(UV.x * 46.0) * 0.5));
			float ring = smoothstep(0.18, 0.28, length(rings - 0.5)) * (1.0 - smoothstep(0.38, 0.48, length(rings - 0.5)));
			base = metal_iron_color.rgb * mix(0.55, 1.15, ring);
		} else if (m < 0.645) {
			base = metal_brass_color.rgb;
		} else {
			base = metal_steel_color.rgb;
		}
		metal = m >= 0.59 && m < 0.645 ? max(equipment_metallic, 0.6) : equipment_metallic;
		rough = equipment_roughness;
		// The anisotropic MatCap band: a stroke of light across the upper curve of the metal.
		float band = 1.0 - abs(NORMAL.y - 0.42) * 2.2;
		v_metal_glint = smoothstep(0.86, 0.92, band) * metal;
	} else {
		if (m < 0.8) {
			base = skin_tone_color.rgb;
			rough = 0.6;
		} else if (m < 0.89) {
			// The speckled woodsman beard: bark-brown strands, a share of them light ash-gray.
			vec3 strand = vec3(UV.x * 150.0, UV.y * 60.0, rest_y * 60.0);
			float speckle = strand_speckle(strand, beard_speckle_ratio);
			base = mix(beard_primary_color.rgb, beard_speckle_color.rgb, speckle);
			rough = 0.9;
		} else if (m < 0.95) {
			base = eye_color.rgb;
			rough = 0.3;
		} else {
			base = beard_primary_color.rgb * 0.8;
			rough = 0.9;
		}
	}
	// Twill: a fine diagonal weave in the normal.
	if (twill > 0.0) {
		float weave = sin((UV.x + UV.y) * 260.0) * 0.5 + sin((UV.x - UV.y) * 190.0) * 0.25;
		NORMAL = normalize(NORMAL + (TANGENT * weave + BINORMAL * weave * 0.4) * 0.07 * twill);
	}
	// The 60-30-10 vertical gradient: dark, grounded boots; the chest, face and weapon head draw the eye up.
	float v_grad = mix(0.68, 1.12, smoothstep(0.15, 1.45, rest_y));
	float ao = mix(0.5, 1.0, COLOR.r);
	vec3 albedo = base * v_grad * ao;
	// Worn chamfers: rims, buckles and timber edges catch a lighter line.
	albedo = mix(albedo, albedo * 1.35 + vec3(0.03), COLOR.g * 0.55);
	// Dread-Chill: hoar-rime creeping up the lowest 0.45 m.
	float frost = dread_chill_frost * (1.0 - smoothstep(0.05, 0.45, rest_y));
	frost *= 0.55 + 0.45 * hash13(floor(vec3(UV * 40.0, rest_y * 30.0)));
	albedo = mix(albedo, frost_color.rgb, clamp(frost, 0.0, 1.0) * 0.75);
	ALBEDO = albedo;
	ROUGHNESS = rough;
	METALLIC = metal;
	SPECULAR = 0.0;
	// The cel ramp's anti-aliasing width, handed to light().
	v_aa = clamp(length(fwidth(NORMAL)) * 0.6, 0.006, 0.08);
	// The Fellowship rim, the Lantern's Promise and the Sign spark.
	float facing = max(0.0, dot(VIEW, NORMAL));
	float rim = smoothstep(0.62, 0.88, 1.0 - facing);
	vec3 emission = rim_color.rgb * rim * rim_strength * 0.55;
	emission += promise_color.rgb * lantern_promise_warmth * (rim * 1.6 + 0.06);
	emission += active_sign_color.rgb * sign_emission_strength * COLOR.a * value_3_emission_mult;
	emission += metal_steel_color.rgb * v_metal_glint * 0.35;
	emission += frost_color.rgb * frost * 0.12;
	EMISSION = emission + glow.rgb;
	// Too close to the camera: a 4x4 Bayer dither fades the hero out.
	float distance_to_camera = length(VERTEX);
	if (distance_to_camera < camera_fade_distance) {
		float fade = smoothstep(0.3, camera_fade_distance, distance_to_camera);
		if (fade < bayer4(FRAGCOORD.xy)) {
			discard;
		}
	}
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(band_edge - v_aa, band_edge + v_aa, ndl);
	if (LIGHT_IS_DIRECTIONAL) {
		vec3 bounce = ground_turf.a > 0.5 ? ground_turf.rgb : biome_turf_bounce;
		vec3 shade = shade_color.rgb + bounce * turf_bounce_strength;
		DIFFUSE_LIGHT += mix(shade, vec3(1.0), lit * ATTENUATION) * LIGHT_COLOR / PI * (1.0 - METALLIC * 0.3);
		if (METALLIC > 0.0) {
			float spread = mix(110.0, 8.0, ROUGHNESS);
			float glint = pow(max(dot(NORMAL, normalize(LIGHT + VIEW)), 0.0), spread);
			SPECULAR_LIGHT += smoothstep(0.42, 0.5, glint) * METALLIC * lit * ATTENUATION * LIGHT_COLOR;
		}
	} else {
		DIFFUSE_LIGHT += lit * ATTENUATION * LIGHT_COLOR / PI;
	}
}
