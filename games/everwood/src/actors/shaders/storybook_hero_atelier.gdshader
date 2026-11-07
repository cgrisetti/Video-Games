// The heroes' storybook look (19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md §4,
// Stage 4; 19B_HERO_MATERIAL_FIDELITY_FACIAL_SCULPT_AND_GAIT_POLISH.md): one
// material paints a whole sculpted hero (HeroMeshAtelier) and, with the tier's
// metals, their weapon. Every vertex carries what it is in its colour:
//   COLOR.r  crevice AO (1 open, toward 0 in the folds and under each armour layer's lip)
//   COLOR.g  the chamfer / curvature mask: worn, lighter edges on rims and buckles
//   COLOR.b  the material id (HeroMeshAtelier.MAT_*), decoded below in five bands:
//            < 0.3   woven cloth: heritage wool, slate breeches, tabard, tunic,
//                    trim, linen, hemp rope (a twill weave and a velvet fuzz rim)
//            < 0.42  adze-hewn timber and Iron-Wood bark (grain 14:1, growth
//                    rings, planed facets)
//            < 0.5   oiled leather and dark bog-leather (pebbled hide, matte in
//                    the creases, burnished on worn edges, saddle-stitched seams)
//            < 0.7   forged iron, ring-mail, brass, steel (planished hammer
//                    facets, a sun glint, a sky band, forge-soot in the cavities)
//            else    skin, the face's portrait zones, the speckled woodsman beard,
//                    brows and lashes, sclera, iris and pupil (a corneal catchlight)
//   COLOR.a  recessed Maker-Seal veins that glow in the active Sign
//   UV2.x    the vertex's height at rest, for the 60-30-10 vertical gradient
// On the face, UV holds the malar flush and the forehead's warmth, UV2.y the
// jaw's cool shadow. The light is a two-band cel ramp, anti-aliased by its own
// screen-space derivative, whose shade is warmed by the biome's turf bounce;
// cloth adds a fuzz rim, skin a sub-dermal scatter band at the terminator; a
// Fresnel rim in the Fellowship's colour; Dread-Chill hoar-rime on the lowest
// 0.45 m and The Lantern's Promise's Saffron-Gold rim; and a 4x4 Bayer dither
// when the camera comes within 1.1 m.
shader_type spatial;
render_mode cull_back;

// The painter's hand (docs/24_PAINTED_WORLD_PASS.md §2): the shade's edge wanders along brush strokes.
#include "res://src/actors/storybook_brush.gdshaderinc"

// The Fellowship rim's emissive line (it was 0.55 of rim_strength) and its sun backlight.
const float HERO_RIM_LINE = 0.18;
const float HERO_RIM_BACKLIGHT = 1.2;
// The painted ramp (as storybook_cel_light.gdshaderinc): the half-light's offset and share, the strokes' wander.
const float HERO_HALF_OFFSET = 0.32;
const float HERO_HALF_SHARE = 0.55;
const float HERO_BRUSH_WANDER = 0.12;
// Cloth's velvet fuzz, kept to a whisper so shirts never glow (it was full fuzz_strength).
const float HERO_FUZZ_SHARE = 0.35;


// The biome's turf (WorldAtmosphereDirector sets it; a = 1 once it has).
global uniform vec4 ground_turf;

group_uniforms value_one;
uniform vec4 value_1_coat_color : source_color = vec4(0.180, 0.251, 0.169, 1.0);
uniform vec4 value_1_boot_color : source_color = vec4(0.212, 0.157, 0.118, 1.0);
uniform vec4 value_1_breeches_color : source_color = vec4(0.227, 0.247, 0.278, 1.0);
group_uniforms calling;
uniform vec4 calling_trim_color : source_color = vec4(0.769, 0.584, 0.251, 1.0);
uniform vec4 fellowship_tunic_color : source_color = vec4(0.231, 0.478, 0.278, 1.0);
uniform vec4 trim_accent_color : source_color = vec4(0.85, 0.72, 0.42, 1.0);
group_uniforms value_two;
uniform vec4 value_2_timber_leather_color : source_color = vec4(0.612, 0.447, 0.314, 1.0);
uniform vec4 value_2_linen_color : source_color = vec4(0.839, 0.780, 0.698, 1.0);
uniform vec4 rope_color : source_color = vec4(0.72, 0.62, 0.44, 1.0);
uniform vec4 leather_color : source_color = vec4(0.627, 0.416, 0.290, 1.0);
uniform vec4 bark_color : source_color = vec4(0.40, 0.29, 0.20, 1.0);
group_uniforms metals;
uniform vec4 metal_iron_color : source_color = vec4(0.353, 0.384, 0.416, 1.0);
uniform vec4 metal_brass_color : source_color = vec4(0.769, 0.584, 0.251, 1.0);
uniform vec4 metal_steel_color : source_color = vec4(0.769, 0.808, 0.831, 1.0);
uniform float equipment_metallic : hint_range(0.0, 1.0) = 0.55;
uniform float equipment_roughness : hint_range(0.0, 1.0) = 0.52;
// Forge-soot in the rivets' and rings' cavities (#2B3036).
uniform vec4 soot_color : source_color = vec4(0.169, 0.188, 0.212, 1.0);
group_uniforms micro_surfaces;
// Woven cloth: the twill's normal strength and its fuzz rim.
uniform float weave_strength = 0.28;
// How many weave repeats a metre of UV holds over the brief's 110 (UVs here are in metres, so threads come out about a centimetre).
uniform float weave_density = 6.0;
uniform float fuzz_strength = 0.22;
uniform vec4 fuzz_color : source_color = vec4(0.96, 0.92, 0.80, 1.0);
// Timber: the grain's normal strength.
uniform float grain_strength = 0.24;
// Metal: planished hammer facets, cells a metre, and how far each tilts.
uniform float facet_cells = 32.0;
uniform float facet_strength = 0.16;
group_uniforms face;
uniform vec4 skin_tone_color : source_color = vec4(0.86, 0.68, 0.56, 1.0);
// The face's portrait zones: a wind-kissed malar flush (#D97964, 32%), the jaw's cool undertone (#9E8272).
uniform vec4 malar_color : source_color = vec4(0.851, 0.475, 0.392, 1.0);
uniform float malar_mix = 0.32;
uniform vec4 cool_undertone_color : source_color = vec4(0.620, 0.510, 0.447, 1.0);
// The sub-dermal terminator band's blood-coral (#E26D52).
uniform vec4 scatter_color : source_color = vec4(0.886, 0.427, 0.322, 1.0);
uniform float scatter_strength = 0.45;
uniform vec4 beard_primary_color : source_color = vec4(0.290, 0.196, 0.133, 1.0);
uniform vec4 beard_speckle_color : source_color = vec4(0.722, 0.753, 0.784, 1.0);
uniform float beard_speckle_ratio : hint_range(0.0, 1.0) = 0.28;
uniform vec4 sclera_color : source_color = vec4(0.957, 0.937, 0.902, 1.0);
uniform vec4 iris_color : source_color = vec4(0.369, 0.278, 0.157, 1.0);
uniform vec4 eye_color : source_color = vec4(0.08, 0.06, 0.05, 1.0);
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
// What the light needs to know: x cloth, y skin, z the leather's burnish, w an eye.
varying vec4 v_mat;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash13(vec3(i, 0.0));
	float b = hash13(vec3(i + vec2(1.0, 0.0), 0.0));
	float c = hash13(vec3(i + vec2(0.0, 1.0), 0.0));
	float d = hash13(vec3(i + vec2(1.0, 1.0), 0.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// 3D Voronoi: the nearest cell's random tilt (xy, -1 to 1) and the distance to it (z).
vec3 voronoi_tilt(vec3 p) {
	vec3 cell = floor(p);
	vec3 local = fract(p);
	float best = 8.0;
	vec2 tilt = vec2(0.0);
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec3 other = vec3(float(x), float(y), 0.0);
			vec3 seed = vec3(hash13(cell + other), hash13(cell + other + 17.0), 0.5);
			float d = length(other + seed - local);
			if (d < best) {
				best = d;
				tilt = vec2(hash13(cell + other + 41.7), hash13(cell + other + 73.1)) * 2.0 - 1.0;
			}
		}
	}
	return vec3(tilt, best);
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
	float glint = 0.0;
	// A nudge to the normal along the surface's tangent (x) and binormal (y).
	vec2 nudge = vec2(0.0);
	vec4 mat = vec4(0.0);
	if (m < 0.3) {
		// Woven cloth: heritage wool, slate breeches, the tabard, the tunic, trim, linen, rope.
		if (m < 0.04) {
			base = value_1_coat_color.rgb;
		} else if (m < 0.10) {
			base = value_1_breeches_color.rgb;
		} else if (m < 0.18) {
			base = calling_trim_color.rgb;
		} else if (m < 0.215) {
			base = fellowship_tunic_color.rgb;
		} else if (m < 0.25) {
			base = trim_accent_color.rgb;
		} else if (m < 0.28) {
			base = value_2_linen_color.rgb;
		} else {
			base = rope_color.rgb;
		}
		// A diagonal twill weave: the threads tilt the normal and lift or sink the colour 6%,
		// fading out where a thread grows smaller than a pixel so it never shimmers.
		vec2 uv = UV * weave_density;
		float weave = sin((uv.x + uv.y) * 110.0) * sin((uv.x - uv.y) * 110.0);
		weave *= 1.0 - smoothstep(0.35, 1.2, length(fwidth(uv)) * 110.0 / 6.2832);
		nudge += vec2(weave, weave * 0.6) * weave_strength;
		base *= 1.0 + weave * 0.06;
		rough = m < 0.10 ? 0.9 : 0.82;
		mat.x = 1.0;
	} else if (m < 0.42) {
		// Adze-hewn timber and Iron-Wood bark: fibres stretched 14:1 along the piece, growth rings, planed facets.
		base = m < 0.37 ? value_2_timber_leather_color.rgb : bark_color.rgb;
		float fibre = value_noise(vec2(UV.x * 84.0, UV.y * 6.0));
		float rings = 0.5 + 0.5 * sin(UV.x * 42.0 + fibre * 9.0 + UV.y * 2.0);
		float adze = floor(value_noise(vec2(UV.x * 9.0, UV.y * 3.0)) * 6.0) / 6.0;
		float grain = clamp(fibre * 0.55 + rings * 0.45, 0.0, 1.0);
		// Warm ochre to umber, 12% either way.
		base *= mix(vec3(0.88, 0.85, 0.82), vec3(1.12, 1.1, 1.04), grain) * mix(0.95, 1.05, adze);
		nudge += vec2((grain - 0.5) * 2.0 * grain_strength, (adze - 0.5) * 0.18);
		rough = 0.68;
	} else if (m < 0.5) {
		// Oiled leather: a pebbled hide, matte in its creases, burnished to a waxy sheen on worn edges.
		base = m < 0.46 ? leather_color.rgb : value_1_boot_color.rgb;
		vec3 pebble = voronoi_tilt(vec3(UV * 260.0, rest_y * 40.0));
		float pebble_fade = 1.0 - smoothstep(0.4, 1.2, length(fwidth(UV)) * 260.0);
		nudge += pebble.xy * 0.1 * smoothstep(0.1, 0.45, pebble.z) * pebble_fade;
		float crease = 1.0 - smoothstep(0.55, 0.7, COLOR.r);
		float burnish = smoothstep(0.35, 0.75, COLOR.g) * (1.0 - crease);
		rough = mix(0.78, 0.28, burnish);
		base = mix(base, base * 1.1 + vec3(0.025, 0.015, 0.0), burnish);
		// Saddle stitching: a dashed row of ticks every 15 mm along the seams.
		float seam = smoothstep(0.45, 0.6, COLOR.g) * (1.0 - smoothstep(0.88, 0.98, COLOR.g));
		float tick = step(0.55, fract(UV.y / 0.015)) * seam * (1.0 - smoothstep(0.4, 1.0, fwidth(UV.y) / 0.015));
		nudge.y += tick * 0.3;
		base *= 1.0 - tick * 0.18;
		mat.z = 0.65 * burnish;
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
		// Planished hammer facets: each Voronoi cell tilts the normal its own way.
		vec3 facet = voronoi_tilt(vec3(UV * facet_cells, rest_y * facet_cells));
		nudge += facet.xy * facet_strength;
		// Forge-soot patina darkens the cavities.
		base = mix(base, soot_color.rgb, (1.0 - smoothstep(0.4, 0.65, COLOR.r)) * 0.7);
		// The sky-horizon band: a stroke of light across the upper curve of the metal.
		float band = 1.0 - abs(NORMAL.y - 0.42) * 2.2;
		glint = smoothstep(0.86, 0.92, band) * metal;
	} else {
		mat.y = 1.0;
		if (m < 0.75) {
			base = skin_tone_color.rgb;
			rough = 0.56;
		} else if (m < 0.79) {
			// The face's portrait zones: a warm golden-ochre forehead, the malar flush over the
			// nose, cheeks and ear tips, a cool undertone under the eyes and along the jaw.
			base = skin_tone_color.rgb;
			base *= mix(vec3(1.0), vec3(1.06, 1.03, 0.94), clamp(UV.y, 0.0, 1.0));
			base = mix(base, malar_color.rgb, clamp(UV.x, 0.0, 1.0) * malar_mix);
			base = mix(base, cool_undertone_color.rgb, clamp(UV2.y, 0.0, 1.0) * 0.28);
			rough = 0.56;
		} else if (m < 0.84) {
			// The speckled woodsman beard: bark-brown strands, a share of them light ash-gray.
			vec3 strand = vec3(UV.x * 150.0, UV.y * 60.0, rest_y * 60.0);
			float speckle = strand_speckle(strand, beard_speckle_ratio);
			base = mix(beard_primary_color.rgb, beard_speckle_color.rgb, speckle);
			rough = 0.9;
			mat.y = 0.0;
		} else if (m < 0.88) {
			// Brows, lashes and hair.
			base = beard_primary_color.rgb * 0.7;
			rough = 0.9;
			mat.y = 0.0;
		} else if (m < 0.92) {
			base = sclera_color.rgb;
			rough = 0.25;
			mat.y = 0.0;
		} else if (m < 0.955) {
			base = iris_color.rgb;
			rough = 0.2;
			mat = vec4(0.0, 0.0, 0.0, 1.0);
		} else {
			base = eye_color.rgb;
			rough = 0.15;
			mat = vec4(0.0, 0.0, 0.0, 1.0);
		}
	}
	NORMAL = normalize(NORMAL + TANGENT * nudge.x + BINORMAL * nudge.y);
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
	// Matte, like painted cloth and skin (docs/24 §2): only metal reflects the sky; the rest
	// keeps its own sheens (fuzz, scatter, burnish) in light() and never goes plastic.
	ROUGHNESS = metal > 0.0 ? rough : max(rough, 0.85);
	METALLIC = metal;
	SPECULAR = metal > 0.0 ? 0.5 : 0.0;
	v_brush = sb_brush((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz * 1.8);
	v_mat = mat;
	// The cel ramp's anti-aliasing width, handed to light().
	v_aa = clamp(length(fwidth(NORMAL)) * 0.6, 0.006, 0.08);
	// The Fellowship rim, the Lantern's Promise and the Sign spark.
	float facing = max(0.0, dot(VIEW, NORMAL));
	float rim = smoothstep(0.62, 0.88, 1.0 - facing);
	// The Fellowship rim stays as a thin line for split-screen readability (Gate 5); the rest of it is a backlight in light().
	vec3 emission = rim_color.rgb * rim * rim_strength * HERO_RIM_LINE;
	emission += promise_color.rgb * lantern_promise_warmth * (rim * 1.6 + 0.06);
	emission += active_sign_color.rgb * sign_emission_strength * COLOR.a * value_3_emission_mult;
	emission += metal_steel_color.rgb * glint * 0.35;
	emission += frost_color.rgb * frost * 0.12;
	// The corneal catchlight: a spark that finds the camera from any angle.
	if (mat.w > 0.5) {
		vec3 bounce = reflect(-VIEW, NORMAL);
		emission += vec3(1.0) * smoothstep(0.95, 0.985, dot(bounce, normalize(vec3(-0.35, 0.55, 0.75)))) * 1.6;
	}
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
	float ndl = dot(NORMAL, LIGHT) + v_brush * HERO_BRUSH_WANDER;
	float half_light = smoothstep(band_edge - HERO_HALF_OFFSET - v_aa * 2.0, band_edge - HERO_HALF_OFFSET + v_aa * 2.0, ndl);
	float lit = mix(half_light * HERO_HALF_SHARE, 1.0, smoothstep(band_edge - v_aa, band_edge + v_aa, ndl));
	if (LIGHT_IS_DIRECTIONAL) {
		// A warm backlight on the silhouette in the Fellowship's colour, only with the sun behind.
		float edge_on = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		DIFFUSE_LIGHT += rim_color.rgb * edge_on * smoothstep(-0.1, 0.7, dot(LIGHT, -VIEW)) * rim_strength * HERO_RIM_BACKLIGHT * ATTENUATION * LIGHT_COLOR / PI;
		vec3 bounce = ground_turf.a > 0.5 ? ground_turf.rgb : biome_turf_bounce;
		vec3 shade = shade_color.rgb + bounce * turf_bounce_strength;
		DIFFUSE_LIGHT += mix(shade, vec3(1.0), lit * ATTENUATION) * LIGHT_COLOR / PI * (1.0 - METALLIC * 0.3);
		float reflect_dot = dot(reflect(-LIGHT, NORMAL), VIEW);
		// Cloth: a velvet fuzz of fibres along the light-facing edge.
		if (v_mat.x > 0.5) {
			float fuzz = pow(1.0 - max(0.0, dot(NORMAL, VIEW)), 2.2) * fuzz_strength * HERO_FUZZ_SHARE;
			DIFFUSE_LIGHT += fuzz_color.rgb * fuzz * clamp(ndl + 0.35, 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;
		}
		// Skin: light wraps warmly through the terminator (nose, ears, cheeks).
		if (v_mat.y > 0.5) {
			float scatter = smoothstep(-0.18, 0.20, ndl) * (1.0 - smoothstep(0.0, 0.35, ndl));
			DIFFUSE_LIGHT += scatter_color.rgb * scatter * scatter_strength * ATTENUATION * LIGHT_COLOR / PI;
		}
		// Metal: a crisp primary sun glint.
		if (METALLIC > 0.0) {
			SPECULAR_LIGHT += smoothstep(0.86, 0.92, reflect_dot) * METALLIC * lit * ATTENUATION * LIGHT_COLOR;
		}
		// Burnished leather: a waxy sheen on the worn edges.
		if (v_mat.z > 0.0) {
			SPECULAR_LIGHT += smoothstep(0.72, 0.9, reflect_dot) * v_mat.z * lit * ATTENUATION * LIGHT_COLOR * 0.5;
		}
		// Eyes: the sun's own corneal catchlight spark.
		if (v_mat.w > 0.5) {
			SPECULAR_LIGHT += smoothstep(0.95, 0.985, reflect_dot) * 1.6 * ATTENUATION * LIGHT_COLOR;
		}
	} else {
		DIFFUSE_LIGHT += lit * ATTENUATION * LIGHT_COLOR / PI;
	}
}
