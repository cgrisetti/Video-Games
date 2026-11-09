// The kin's storybook look (docs/30_KIN_DESIGN_LANGUAGE.md §5): one material paints a
// whole sculpted kin (KinSculptor), in the heroes' painted light (storybook_hero_atelier)
// and wearing the same ink line as its next pass. Every vertex carries what it is:
//   COLOR.r  crevice AO (1 open, toward 0 in folds and under plates)
//   COLOR.g  worn edges and tips (lighter fur tips, chipped shell rims, polished horn)
//   COLOR.b  the material id (KinSculptor.MAT_*), in these bands:
//            < 0.105 fur (the kin's coat, then its accent: mane, ruff, bristles)
//            < 0.205 hide (smooth skin, then the paler belly)
//            < 0.305 bark, then moss
//            < 0.395 horn (tusks, claws, antler tips), then bramble thorn
//            < 0.485 shell (chitin plates, a carapace), then barnacles
//            < 0.615 plough-iron, rust, brass
//            < 0.665 stone
//            < 0.755 cloth (rags, sacking), then sea-fret mist (dithers away near the ground)
//            < 0.805 sap
//            < 0.855 ember (a coal's glow)
//            < 0.92  petals (a grey bud until it blooms), then leaves
//            else    a painted eye, then a spirit's glowing eye
//   COLOR.a  the striking part: it glows in its blow's Sign through the wind-up
//   UV2.x    the vertex's height at rest (figure_height normalises it)
// Eyes carry their own frame in UV (-1..1 across and up), for the iris, the pupil,
// the catchlight and a blinking lid. The Un-Inked (Act I's grey kin) are washed to
// paper grey with blank paper eyes; un_inked falling from 1 to 0 floods their colour
// back in ragged watercolour patches with a wet, dark edge (the calm, docs/28 §3.5),
// and bloom opens the dog-roses.
shader_type spatial;
render_mode cull_back;

#include "res://src/actors/storybook_brush.gdshaderinc"

const float KIN_RIM_LINE = 0.18;
const float KIN_RIM_BACKLIGHT = 1.0;
const float KIN_HALF_OFFSET = 0.32;
const float KIN_HALF_SHARE = 0.55;
const float KIN_BRUSH_WANDER = 0.12;

global uniform vec4 ground_turf;

group_uniforms palette;
uniform vec4 main_color : source_color = vec4(0.5, 0.42, 0.34, 1.0);
uniform vec4 accent_color : source_color = vec4(0.32, 0.24, 0.18, 1.0);
uniform vec4 eye_color : source_color = vec4(1.0, 0.75, 0.35, 1.0);
uniform vec4 bark_color : source_color = vec4(0.36, 0.29, 0.22, 1.0);
uniform vec4 moss_color : source_color = vec4(0.30, 0.42, 0.18, 1.0);
uniform vec4 horn_color : source_color = vec4(0.88, 0.82, 0.68, 1.0);
uniform vec4 thorn_color : source_color = vec4(0.40, 0.22, 0.16, 1.0);
uniform vec4 barnacle_color : source_color = vec4(0.86, 0.84, 0.76, 1.0);
uniform vec4 iron_color : source_color = vec4(0.27, 0.27, 0.28, 1.0);
uniform vec4 rust_color : source_color = vec4(0.55, 0.28, 0.15, 1.0);
uniform vec4 brass_color : source_color = vec4(0.78, 0.6, 0.28, 1.0);
uniform vec4 stone_color : source_color = vec4(0.55, 0.54, 0.5, 1.0);
uniform vec4 mist_color : source_color = vec4(0.78, 0.86, 0.9, 1.0);
uniform vec4 sap_color : source_color = vec4(0.62, 0.5, 0.32, 1.0);
uniform vec4 ember_color : source_color = vec4(1.0, 0.52, 0.18, 1.0);
uniform vec4 petal_color : source_color = vec4(0.95, 0.62, 0.72, 1.0);
uniform vec4 bud_color : source_color = vec4(0.42, 0.5, 0.3, 1.0);
uniform vec4 leaf_color : source_color = vec4(0.34, 0.5, 0.24, 1.0);
uniform vec4 pupil_color : source_color = vec4(0.07, 0.05, 0.04, 1.0);
uniform vec4 sclera_color : source_color = vec4(0.94, 0.9, 0.82, 1.0);
group_uniforms figure;
// The kin's height at its sculpted size (UV2.x / figure_height runs 0 at the feet to 1 at the top).
uniform float figure_height = 1.0;
// Sea-fret dissolves into dithered wisps below this share of the height.
uniform float mist_fade_height = 0.22;
// How much the ember glows and flickers.
uniform float ember_strength = 1.2;
group_uniforms story;
// The Un-Inked grey (1 all grey, 0 its own colours), and how far its dog-roses have opened.
uniform float un_inked : hint_range(0.0, 1.0) = 0.0;
uniform float bloom : hint_range(0.0, 1.0) = 0.0;
uniform vec4 paper_color : source_color = vec4(0.82, 0.8, 0.76, 1.0);
// 0 open, 1 shut (KinFigure blinks it).
uniform float eye_blink : hint_range(0.0, 1.0) = 0.0;
group_uniforms light_and_play;
uniform vec4 shade_color : source_color = vec4(0.40, 0.35, 0.47, 1.0);
uniform float band_edge : hint_range(-1.0, 1.0) = 0.08;
uniform vec3 biome_turf_bounce = vec3(0.105, 0.262, 0.069);
uniform float turf_bounce_strength : hint_range(0.0, 2.0) = 0.9;
uniform vec4 rim_color : source_color = vec4(0.95, 0.82, 0.6, 1.0);
uniform float rim_strength : hint_range(0.0, 3.0) = 0.5;
// Hit flashes and tells (StorybookMaterial.set_glow).
uniform vec4 glow : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// The striking part's Sign through the wind-up.
uniform vec4 active_sign_color : source_color = vec4(1.0, 0.9, 0.62, 1.0);
uniform float sign_emission_strength : hint_range(0.0, 3.0) = 0.0;
uniform float camera_fade_distance = 1.1;

varying vec3 v_obj;
varying vec3 v_obj_n;
// x fur's fuzz, y hide's warm scatter, z a sheen (shell, sap, horn), w an eye's catchlight.
varying vec4 v_mat;
varying float v_aa;

float k_hash(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float k_noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = k_hash(vec3(i, 0.0));
	float b = k_hash(vec3(i + vec2(1.0, 0.0), 0.0));
	float c = k_hash(vec3(i + vec2(0.0, 1.0), 0.0));
	float d = k_hash(vec3(i + vec2(1.0, 1.0), 0.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float bayer4(vec2 frag) {
	int x = int(mod(frag.x, 4.0));
	int y = int(mod(frag.y, 4.0));
	int index = x + y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[index] + 0.5) / 16.0;
}

void vertex() {
	v_obj = VERTEX;
	v_obj_n = NORMAL;
}

void fragment() {
	float m = COLOR.b;
	float h = clamp(UV2.x / max(figure_height, 0.01), 0.0, 1.2);
	vec3 base = main_color.rgb;
	float rough = 0.88;
	float metal = 0.0;
	vec2 nudge = vec2(0.0);
	vec4 mat = vec4(0.0);
	vec3 emission = vec3(0.0);
	float upness = clamp(v_obj_n.y, -1.0, 1.0);
	// Fine detail fades out where it would shimmer (the scale of a UV metre on screen).
	float uv_px = length(fwidth(UV));
	bool eye = false;
	if (m < 0.105) {
		// Fur: strokes running along the body, darker roots in the folds, lighter tips on the
		// edges, countershaded (darker along the back, paler underneath) as animals are.
		base = m < 0.055 ? main_color.rgb : accent_color.rgb;
		float strokes = k_noise2(vec2(UV.x * 34.0, UV.y * 5.0));
		float clumps = k_noise2(vec2(UV.x * 9.0, UV.y * 2.2) + 11.0);
		float fade = 1.0 - smoothstep(0.02, 0.08, uv_px);
		base *= mix(1.0, 0.86 + 0.24 * strokes, fade) * (0.92 + 0.14 * clumps);
		base *= mix(1.08, 0.86, smoothstep(-0.4, 0.8, upness));
		base = mix(base, base * 1.18 + vec3(0.02), COLOR.g * 0.6);
		nudge += vec2((strokes - 0.5) * 0.35 * fade, (clumps - 0.5) * 0.2);
		rough = 0.95;
		mat.x = 1.0;
	} else if (m < 0.205) {
		// Hide: smooth, painted, mottled with darker blotches; the belly paler and warmer.
		base = m < 0.155 ? main_color.rgb : mix(main_color.rgb, vec3(0.92, 0.86, 0.72), 0.55);
		float mottle = sb_noise(v_obj * 9.0);
		float warts = smoothstep(0.62, 0.7, sb_noise(v_obj * 26.0 + 3.0));
		base *= 0.9 + 0.16 * mottle;
		base = mix(base, base * 0.72, warts * 0.5 * (1.0 - smoothstep(0.02, 0.06, uv_px)));
		base *= mix(1.06, 0.9, smoothstep(-0.4, 0.8, upness));
		rough = 0.7;
		mat.y = 1.0;
	} else if (m < 0.305) {
		if (m < 0.26) {
			// Bark: deep fibrous ridges running along the piece, grey lichen flecks on the crests.
			base = bark_color.rgb;
			float ridge = k_noise2(vec2(UV.x * 16.0, UV.y * 1.6));
			float crevice = smoothstep(0.3, 0.6, ridge);
			base *= mix(0.62, 1.12, crevice);
			float lichen = smoothstep(0.72, 0.8, sb_noise(v_obj * 11.0 + 5.0)) * crevice;
			base = mix(base, base * vec3(0.92, 1.04, 0.86) + vec3(0.03, 0.04, 0.02), lichen * 0.45);
			nudge += vec2((ridge - 0.5) * 0.7, 0.0);
			rough = 0.95;
		} else {
			// Moss: two greens, a soft fuzz, tiny light flecks where it catches the sun.
			base = moss_color.rgb * (0.82 + 0.3 * sb_noise(v_obj * 18.0));
			base = mix(base, base * vec3(1.2, 1.25, 0.9), step(0.88, k_hash(floor(v_obj * 120.0))) * 0.6);
			rough = 1.0;
			mat.x = 1.0;
		}
	} else if (m < 0.395) {
		if (m < 0.355) {
			// Horn and claw: ivory with growth bands, darker at the root, polished at the tip.
			base = horn_color.rgb;
			float bands = 0.5 + 0.5 * sin(UV.y * 90.0);
			base *= mix(1.0, 0.92 + 0.1 * bands, 1.0 - smoothstep(0.01, 0.05, uv_px));
			base = mix(base * 0.62, base, smoothstep(0.2, 0.8, COLOR.r));
			rough = 0.5;
			mat.z = 0.35 * COLOR.g;
		} else {
			// Bramble thorn: red-brown, its point bleached.
			base = mix(thorn_color.rgb, thorn_color.rgb * 1.6 + vec3(0.12, 0.1, 0.06), COLOR.g);
			rough = 0.6;
		}
	} else if (m < 0.485) {
		if (m < 0.44) {
			// Shell: lacquered plates, a pale chipped rim, a little sheen.
			base = accent_color.rgb * (0.9 + 0.14 * sb_noise(v_obj * 7.0));
			base = mix(base, base * 1.35 + vec3(0.04), COLOR.g * 0.6);
			rough = 0.5;
			mat.z = 0.3;
		} else {
			// Barnacles: chalky cones, ringed, their mouths dark.
			base = barnacle_color.rgb * (0.88 + 0.2 * sb_noise(v_obj * 40.0));
			base = mix(base * 0.35, base, smoothstep(0.25, 0.75, COLOR.r));
			rough = 0.95;
		}
	} else if (m < 0.615) {
		// Plough-iron: hammered and pitted, rust blooming out of the seams; brass worn bright.
		vec3 iron = iron_color.rgb;
		float bloom_rust = smoothstep(0.42, 0.78, sb_noise(v_obj * 5.0) * 0.7 + (1.0 - COLOR.r) * 0.6);
		if (m < 0.53) {
			base = mix(iron, rust_color.rgb, bloom_rust * 0.55);
			metal = 0.22;
		} else if (m < 0.57) {
			base = mix(rust_color.rgb, rust_color.rgb * 0.6, sb_noise(v_obj * 22.0));
			metal = 0.1;
		} else {
			base = brass_color.rgb;
			base = mix(base * 0.55, base, smoothstep(0.3, 0.8, COLOR.r));
			metal = 0.6;
		}
		float pits = smoothstep(0.7, 0.76, sb_noise(v_obj * 38.0));
		base *= 1.0 - pits * 0.3 * (1.0 - smoothstep(0.02, 0.06, uv_px));
		base = mix(base, base * 1.3 + vec3(0.03), COLOR.g * 0.5);
		rough = m < 0.57 ? 0.7 : 0.45;
	} else if (m < 0.665) {
		// Stone: granite grains, lichen crusts on the tops.
		base = stone_color.rgb * (0.86 + 0.22 * sb_noise(v_obj * 14.0)) * (0.95 + 0.1 * k_hash(floor(v_obj * 90.0)));
		float lichen = smoothstep(0.55, 0.7, sb_noise(v_obj * 4.0 + 2.0)) * smoothstep(0.1, 0.7, upness);
		base = mix(base, vec3(0.7, 0.68, 0.44), lichen * 0.5);
		rough = 0.95;
	} else if (m < 0.755) {
		if (m < 0.71) {
			// Cloth: rags and sacking, a coarse weave, the hem darker and frayed.
			base = accent_color.rgb;
			vec2 uv = UV * 8.0;
			float weave = sin((uv.x + uv.y) * 110.0) * sin((uv.x - uv.y) * 110.0);
			weave *= 1.0 - smoothstep(0.35, 1.2, uv_px * 8.0 * 110.0 / 6.2832);
			nudge += vec2(weave, weave * 0.6) * 0.12;
			base *= 0.9 + 0.12 * sb_noise(v_obj * vec3(9.0, 2.2, 9.0));
			base *= mix(0.78, 1.0, smoothstep(0.0, 0.25, h));
			rough = 0.95;
			mat.x = 0.5;
		} else {
			// Sea-fret: cool, deeper in its folds and toward the hem, thinning to wisps near the ground.
			float drift = sb_noise(v_obj * vec3(4.0, 1.2, 4.0) + vec3(0.0, TIME * 0.15, 0.0));
			base = mix(mist_color.rgb * 0.5, mist_color.rgb * 0.88, smoothstep(0.3, 0.9, COLOR.r));
			base *= (0.88 + 0.16 * drift) * mix(0.72, 1.0, smoothstep(0.0, 0.6, h));
			emission += mist_color.rgb * 0.04;
			float wisp = smoothstep(0.0, mist_fade_height, h + (sb_noise(v_obj * vec3(6.0, 2.0, 6.0) + vec3(0.0, TIME * 0.4, 0.0)) - 0.5) * 0.12);
			if (wisp < 0.999 && wisp < bayer4(FRAGCOORD.xy)) {
				discard;
			}
			rough = 0.9;
		}
	} else if (m < 0.805) {
		// Sap: thick and glossy, its amber core glowing up from inside.
		float depth = sb_noise(v_obj * 3.0 + vec3(0.0, TIME * 0.05, 0.0));
		float edge = 1.0 - max(0.0, dot(VIEW, NORMAL));
		base = sap_color.rgb * (0.5 + 0.3 * depth);
		emission += accent_color.rgb * (0.04 + 0.2 * depth * smoothstep(0.2, 0.9, edge)) * (1.0 - COLOR.g * 0.5);
		rough = 0.45;
		mat.z = 0.16;
	} else if (m < 0.855) {
		// Ember: a live coal, flickering.
		float flicker = 0.75 + 0.25 * sin(TIME * 7.0 + v_obj.x * 13.0 + v_obj.y * 9.0) * sb_noise(v_obj * 9.0 + vec3(TIME * 0.8));
		base = ember_color.rgb * 0.6;
		emission += ember_color.rgb * ember_strength * flicker;
		rough = 0.9;
	} else if (m < 0.92) {
		if (m < 0.89) {
			// Petals: a grey-green bud until the calm opens it pink, paler at the edge.
			base = mix(bud_color.rgb, petal_color.rgb, bloom);
			base = mix(base, base * 1.2 + vec3(0.06), COLOR.g * 0.6);
			rough = 0.8;
			mat.y = 0.5;
		} else {
			// Leaves: a green with its midrib.
			base = leaf_color.rgb * (0.85 + 0.25 * sb_noise(v_obj * 12.0));
			rough = 0.8;
		}
	} else {
		// Eyes (docs/30 §4): big and clear, a coloured iris, a dark pupil, one catchlight,
		// and a lid that blinks. A spirit's eye glows; an Un-Inked eye is blank paper.
		eye = true;
		vec2 e = UV;
		float r = length(e);
		float blank = smoothstep(0.35, 0.65, un_inked);
		float pupil_r = mix(0.38, 0.12, blank);
		if (m < 0.96) {
			base = mix(sclera_color.rgb, eye_color.rgb, 1.0 - smoothstep(0.74, 0.8, r));
			base = mix(base, paper_color.rgb, blank);
			base = mix(base, pupil_color.rgb, 1.0 - smoothstep(pupil_r - 0.04, pupil_r, r));
			rough = 0.2;
			mat.w = 1.0;
		} else {
			vec3 lit = mix(eye_color.rgb * 1.3, vec3(1.0, 0.98, 0.9), smoothstep(0.55, 0.0, r) * 0.6);
			lit = mix(lit, paper_color.rgb, blank);
			base = lit * 0.4;
			emission += lit * mix(1.4, 0.5, blank) * (1.0 - smoothstep(0.7, 1.0, r) * 0.6);
			base = mix(base, pupil_color.rgb, (1.0 - smoothstep(pupil_r * 0.5 - 0.04, pupil_r * 0.5, r)) * (1.0 - blank));
			rough = 0.3;
		}
		// The lid comes down from the top as it blinks, with an inked lash line on its edge.
		float lid = 1.05 - eye_blink * 2.2;
		if (e.y > lid) {
			base = main_color.rgb * 0.8;
			emission = vec3(0.0);
			mat = vec4(0.0);
		} else if (e.y > lid - 0.22) {
			base = vec3(0.13, 0.08, 0.06);
			emission *= 0.2;
			mat.w = 0.0;
		}
	}
	// The Un-Inked: washed to paper grey, the colour coming back in ragged watercolour
	// patches as un_inked falls, each patch's edge wet and dark.
	if (un_inked > 0.001 && !eye) {
		float n = sb_noise(v_obj * 2.6) * 0.65 + sb_noise(v_obj * 9.0) * 0.35;
		float threshold = 0.08 + n * 0.84;
		float grey = smoothstep(threshold - 0.05, threshold + 0.05, un_inked);
		float luma = dot(base, vec3(0.3, 0.55, 0.15));
		// Grey, but its values kept: a dark coat stays a darker grey than a pale bib.
		vec3 paper = mix(vec3(luma) * vec3(1.02, 1.0, 0.97), paper_color.rgb * 0.62, 0.22);
		base = mix(base, paper, grey * 0.9);
		float wet = (1.0 - smoothstep(0.0, 0.06, abs(un_inked - threshold))) * step(0.02, un_inked) * step(un_inked, 0.98);
		base *= 1.0 - wet * 0.35;
		// Dried-paint cracks across the grey.
		float crack = 1.0 - smoothstep(0.0, 0.035, abs(sb_noise(v_obj * 6.0 + 1.7) - 0.5));
		base *= 1.0 - crack * grey * 0.22;
		emission *= mix(1.0, 0.45, grey);
	}
	NORMAL = normalize(NORMAL + TANGENT * nudge.x + BINORMAL * nudge.y);
	// The vertical gradient: grounded feet, the head and back drawing the eye up.
	float v_grad = mix(0.74, 1.1, smoothstep(0.05, 0.85, h));
	float ao = mix(0.48, 1.0, COLOR.r);
	ALBEDO = base * v_grad * ao;
	ROUGHNESS = metal > 0.0 ? rough : max(rough, 0.6);
	METALLIC = metal;
	SPECULAR = metal > 0.0 ? 0.5 : 0.0;
	v_brush = sb_brush((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz * 1.8);
	v_mat = mat;
	v_aa = clamp(length(fwidth(NORMAL)) * 0.6, 0.006, 0.08);
	float facing = max(0.0, dot(VIEW, NORMAL));
	float rim = smoothstep(0.62, 0.88, 1.0 - facing);
	emission += rim_color.rgb * rim * rim_strength * KIN_RIM_LINE;
	emission += active_sign_color.rgb * sign_emission_strength * COLOR.a;
	if (mat.w > 0.5) {
		vec3 bounce = reflect(-VIEW, NORMAL);
		emission += vec3(1.0) * smoothstep(0.95, 0.985, dot(bounce, normalize(vec3(-0.35, 0.55, 0.75)))) * 1.4;
	}
	EMISSION = emission + glow.rgb;
	float distance_to_camera = length(VERTEX);
	if (distance_to_camera < camera_fade_distance) {
		if (smoothstep(0.3, camera_fade_distance, distance_to_camera) < bayer4(FRAGCOORD.xy)) {
			discard;
		}
	}
}

void light() {
	float ndl = dot(NORMAL, LIGHT) + v_brush * KIN_BRUSH_WANDER;
	float half_light = smoothstep(band_edge - KIN_HALF_OFFSET - v_aa * 2.0, band_edge - KIN_HALF_OFFSET + v_aa * 2.0, ndl);
	float lit = mix(half_light * KIN_HALF_SHARE, 1.0, smoothstep(band_edge - v_aa, band_edge + v_aa, ndl));
	if (LIGHT_IS_DIRECTIONAL) {
		float edge_on = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		DIFFUSE_LIGHT += rim_color.rgb * edge_on * smoothstep(-0.1, 0.7, dot(LIGHT, -VIEW)) * rim_strength * KIN_RIM_BACKLIGHT * ATTENUATION * LIGHT_COLOR / PI;
		vec3 bounce = ground_turf.a > 0.5 ? ground_turf.rgb : biome_turf_bounce;
		vec3 shade = shade_color.rgb + bounce * turf_bounce_strength;
		DIFFUSE_LIGHT += mix(shade, vec3(1.0), lit * ATTENUATION) * LIGHT_COLOR / PI * (1.0 - METALLIC * 0.3);
		float reflect_dot = dot(reflect(-LIGHT, NORMAL), VIEW);
		// Fur and moss: a soft fuzz on the edge turned to the light.
		if (v_mat.x > 0.0) {
			float fuzz = pow(1.0 - max(0.0, dot(NORMAL, VIEW)), 2.2) * 0.12 * v_mat.x;
			DIFFUSE_LIGHT += vec3(1.0, 0.95, 0.85) * fuzz * clamp(ndl + 0.35, 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;
		}
		// Hide and petals: light warming through the terminator.
		if (v_mat.y > 0.0) {
			float scatter = smoothstep(-0.18, 0.2, ndl) * (1.0 - smoothstep(0.0, 0.35, ndl));
			DIFFUSE_LIGHT += vec3(0.85, 0.45, 0.35) * scatter * 0.3 * v_mat.y * ATTENUATION * LIGHT_COLOR / PI;
		}
		// Shell, sap and polished horn: a soft sheen.
		if (v_mat.z > 0.0) {
			SPECULAR_LIGHT += smoothstep(0.86, 0.96, reflect_dot) * v_mat.z * lit * ATTENUATION * LIGHT_COLOR * 0.3;
		}
		if (METALLIC > 0.0) {
			SPECULAR_LIGHT += smoothstep(0.9, 0.96, reflect_dot) * METALLIC * lit * ATTENUATION * LIGHT_COLOR * 0.35;
		}
		if (v_mat.w > 0.5) {
			SPECULAR_LIGHT += smoothstep(0.95, 0.985, reflect_dot) * 1.4 * ATTENUATION * LIGHT_COLOR;
		}
	} else {
		DIFFUSE_LIGHT += lit * ATTENUATION * LIGHT_COLOR / PI;
	}
}
