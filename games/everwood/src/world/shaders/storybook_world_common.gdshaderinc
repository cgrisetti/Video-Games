// What every world shader shares (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §3):
// the atelier's craft textures (ProceduralTextureAtelier, set as global
// parameters by the WorldAtmosphereDirector), the heroes' positions for the
// camera sightline fade and the grass brush, the open Hush-Cracks and the
// Reclamation Blooms of Ecological Succession, and the wind.
//
// Phase 18 (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §3-5) adds the
// ground's frayed road edges and loam verge, the slope contract (scree on
// banks, stratified crag on cliffs, a dark toe at a cliff's foot), the
// First-Quiet's blight (ashen slate-indigo, a hoar-rime rim, the Frozen Wind),
// the Lantern's Promise halos that push it back, and rolling cloud shadows.

global uniform sampler2DArray atelier_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
global uniform sampler2DArray atelier_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
global uniform sampler2DArray atelier_roughness : filter_linear_mipmap, repeat_enable;
// 1 once the atelier's textures are in (before that, surfaces show their plain colour).
global uniform float atelier_ready;
// Each local hero: xyz where they stand, w 1 when there's a hero there.
global uniform vec4 hero_pos_0;
global uniform vec4 hero_pos_1;
global uniform vec4 hero_pos_2;
global uniform vec4 hero_pos_3;
// Open Hush-Cracks: xyz the crack, w its hush radius (0: none).
global uniform vec4 hush_crack_0;
global uniform vec4 hush_crack_1;
global uniform vec4 hush_crack_2;
global uniform vec4 hush_crack_3;
// Reclamation Blooms: xyz the sealed crack, w the bloom wave's radius (0: none).
global uniform vec4 bloom_0;
global uniform vec4 bloom_1;
global uniform vec4 bloom_2;
global uniform vec4 bloom_3;
// xz the wind's direction, w its strength.
global uniform vec4 world_wind;
// The Lantern's Promise (18 §5 layer 4): xyz a Lantern-Bearer or Hearth-Rite holder, w the halo's radius (0: none).
global uniform vec4 lantern_halo_0;
global uniform vec4 lantern_halo_1;
global uniform vec4 lantern_halo_2;
global uniform vec4 lantern_halo_3;
// Rolling cloud shadows (18 §4.4): x how much sun a cloud takes, y patch scale (cycles per metre), zw drift (m/s).
global uniform vec4 cloud_shadow_params;
// The blight (18 §5): rgb the ashen slate-indigo, a how much warm colour drains.
global uniform vec4 blight_ashen;
// rgb the hoar-rime veins, a the rime rim's width in metres.
global uniform vec4 blight_rime;
// x the Frozen Wind's share of the world wind, y the pressed grass's share of its height.
global uniform vec4 blight_wind;
// The biome's ground palette for the frayed road edge (rgb, linear): its turf, its road, and its trodden verge (a: the verge's AO).
global uniform vec4 ground_turf;
global uniform vec4 ground_road;
global uniform vec4 ground_verge;

const vec3 HUSH_TINT = vec3(0.431, 0.471, 0.502);
const vec3 BLOOM_GOLD = vec3(0.95, 0.78, 0.32);
const vec3 BLOOM_EMERALD = vec3(0.35, 0.72, 0.38);
// Above the hero's feet, sightline-faded parts start fading at this height (the 3.2 m contract)...
const float FADE_FLOOR = 3.2;
// ...within this distance of the line from the camera to its hero...
const float FADE_RADIUS = 2.6;
// ...down to this much of them left.
const float FADE_ALPHA = 0.18;

// The atelier's craft layers (ProceduralTextureAtelier.Set).
const float LAYER_FLAGSTONE = 0.0;
const float LAYER_BRICK = 1.0;
const float LAYER_PLASTER = 2.0;
const float LAYER_TIMBER = 3.0;
const float LAYER_SHINGLE = 4.0;
const float LAYER_TURF = 5.0;
const float LAYER_LOAM = 6.0;
const float LAYER_GRANITE = 7.0;

float world_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float world_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(world_hash(i), world_hash(i + vec2(1.0, 0.0)), u.x), mix(world_hash(i + vec2(0.0, 1.0)), world_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float luminance(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// Triplanar weights from a world normal, sharpened so faces read crisply.
vec3 triplanar_weights(vec3 n) {
	vec3 w = pow(abs(n), vec3(4.0));
	return w / max(w.x + w.y + w.z, 0.0001);
}

vec4 craft_sample(sampler2DArray maps, vec3 world_pos, vec3 w, float layer, float scale) {
	vec4 x = texture(maps, vec3(world_pos.zy * scale, layer));
	vec4 y = texture(maps, vec3(world_pos.xz * scale, layer));
	vec4 z = texture(maps, vec3(world_pos.xy * scale, layer));
	return x * w.x + y * w.y + z * w.z;
}

// A craft layer's tangent-space relief turned into a world-space normal (a UDN blend over the three projections).
vec3 craft_normal(vec3 world_pos, vec3 n, vec3 w, float layer, float scale, float strength) {
	vec3 tx = texture(atelier_normal, vec3(world_pos.zy * scale, layer)).xyz * 2.0 - 1.0;
	vec3 ty = texture(atelier_normal, vec3(world_pos.xz * scale, layer)).xyz * 2.0 - 1.0;
	vec3 tz = texture(atelier_normal, vec3(world_pos.xy * scale, layer)).xyz * 2.0 - 1.0;
	vec3 bent = n + strength * (vec3(0.0, tx.y, tx.x) * w.x + vec3(ty.x, 0.0, ty.y) * w.y + vec3(tz.x, tz.y, 0.0) * w.z);
	return normalize(bent);
}

// The layer's average colour (its smallest mip), so a texture can tint a colour without changing its value.
vec3 craft_average(float layer) {
	return max(textureLod(atelier_albedo, vec3(0.5, 0.5, layer), 12.0).rgb, vec3(0.03));
}

// The hero a camera follows: the one nearest it on the ground (its own split-screen hero).
vec4 hero_for_camera(vec3 camera) {
	vec4 heroes[4] = vec4[4](hero_pos_0, hero_pos_1, hero_pos_2, hero_pos_3);
	vec4 best = vec4(0.0);
	float best_d = 1e9;
	for (int i = 0; i < 4; i++) {
		if (heroes[i].w < 0.5) {
			continue;
		}
		float d = length(heroes[i].xz - camera.xz);
		if (d < best_d) {
			best_d = d;
			best = heroes[i];
		}
	}
	return best;
}

// A 4x4 Bayer threshold for screen-door fading.
float bayer4(vec2 frag) {
	int x = int(mod(frag.x, 4.0));
	int y = int(mod(frag.y, 4.0));
	int index = x + y * 4;
	const float pattern[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (pattern[index] + 0.5) / 16.0;
}

// The camera sightline fade: true when this fragment, high above its hero's
// feet, sits close to the line from the camera to that hero (so it should be dithered away).
bool sightline_blocked(vec3 world_pos, vec3 camera, vec2 frag) {
	vec4 hero = hero_for_camera(camera);
	if (hero.w < 0.5 || world_pos.y < hero.y + FADE_FLOOR) {
		return false;
	}
	vec3 target = hero.xyz + vec3(0.0, 1.2, 0.0);
	vec3 ray = camera - target;
	float t = clamp(dot(world_pos - target, ray) / max(dot(ray, ray), 0.0001), 0.0, 1.0);
	float d = length(world_pos - (target + ray * t));
	float fade = mix(1.0, FADE_ALPHA, 1.0 - smoothstep(FADE_RADIUS * 0.6, FADE_RADIUS, d));
	return bayer4(frag) > fade;
}

// The Lantern's Promise at a spot: 1 inside a halo, fading out over its last metre (0 outside every halo).
float lantern_warmth(vec3 world_pos) {
	vec4 halos[4] = vec4[4](lantern_halo_0, lantern_halo_1, lantern_halo_2, lantern_halo_3);
	float warmth = 0.0;
	for (int i = 0; i < 4; i++) {
		if (halos[i].w > 0.0) {
			float d = length(world_pos.xz - halos[i].xz);
			warmth = max(warmth, 1.0 - smoothstep(halos[i].w - 1.0, halos[i].w, d));
		}
	}
	return warmth;
}

// How deep in an open crack's blight a spot is (0 outside; 1 well inside), with the Lantern's Promise pushing it back.
float blight_at(vec3 world_pos) {
	vec4 cracks[4] = vec4[4](hush_crack_0, hush_crack_1, hush_crack_2, hush_crack_3);
	float hush = 0.0;
	for (int i = 0; i < 4; i++) {
		if (cracks[i].w > 0.0) {
			float d = length(world_pos.xz - cracks[i].xz);
			hush = max(hush, 1.0 - smoothstep(cracks[i].w * 0.7, cracks[i].w, d));
		}
	}
	return hush * (1.0 - lantern_warmth(world_pos));
}

// Ecological Succession on a surface: inside an open crack's blight the warm colour
// drains toward ashen slate-indigo and a rim of pale hoar-rime veins frosts its
// edge, except in a Lantern's Promise, which glows warm Saffron-Gold; a
// golden-emerald wave sweeps out where one was just sealed.
void apply_succession(vec3 world_pos, inout vec3 albedo, inout vec3 emission, float strength) {
	vec4 cracks[4] = vec4[4](hush_crack_0, hush_crack_1, hush_crack_2, hush_crack_3);
	vec4 blooms[4] = vec4[4](bloom_0, bloom_1, bloom_2, bloom_3);
	float warmth = lantern_warmth(world_pos);
	float ashen_share = blight_ashen.a > 0.0 ? blight_ashen.a : 0.85;
	vec3 ashen = blight_ashen.a > 0.0 ? blight_ashen.rgb : HUSH_TINT;
	vec3 rime = blight_rime.a > 0.0 ? blight_rime.rgb : vec3(0.72, 0.82, 0.88);
	float rime_width = blight_rime.a > 0.0 ? blight_rime.a : 2.5;
	for (int i = 0; i < 4; i++) {
		if (cracks[i].w > 0.0) {
			float d = length(world_pos.xz - cracks[i].xz);
			float inside = 1.0 - smoothstep(cracks[i].w * 0.7, cracks[i].w, d);
			float hush = inside * strength * (1.0 - warmth);
			float grey = luminance(albedo);
			// 85% of the warm colour drains, toward the ashen slate-indigo at the grey's own value.
			vec3 drained = ashen * (grey / max(luminance(ashen), 0.001));
			albedo = mix(albedo, drained, hush * ashen_share);
			// The hoar-rime rim: crystalline veins in a band just inside the hush's edge.
			float band = 1.0 - smoothstep(0.0, rime_width * 0.5, abs(d - (cracks[i].w - rime_width * 0.5)));
			float veins = smoothstep(0.62, 0.78, world_noise(world_pos.xz * 2.2 + vec2(d * 0.7, 0.0)))
				* smoothstep(0.35, 0.65, world_noise(world_pos.xz * 7.0));
			float frost = band * max(veins, 0.25) * strength * (1.0 - warmth);
			albedo = mix(albedo, rime * max(grey * 1.6, 0.35), frost * 0.75);
			emission += rime * frost * 0.05;
			// Inside the blight, a Lantern's Promise paints a warm pool of Saffron-Gold round the bearer's boots.
			emission += BLOOM_GOLD * warmth * inside * 0.09 * strength;
			albedo = mix(albedo, albedo * vec3(1.08, 1.02, 0.88), warmth * inside * strength);
		}
		if (blooms[i].w > 0.0) {
			float d = length(world_pos.xz - blooms[i].xz);
			float wave = 1.0 - smoothstep(0.0, 1.6, abs(d - blooms[i].w));
			float behind = (1.0 - smoothstep(blooms[i].w - 0.5, blooms[i].w, d)) * (1.0 - smoothstep(4.0, 24.0, blooms[i].w));
			emission += mix(BLOOM_EMERALD, BLOOM_GOLD, world_noise(world_pos.xz * 0.7)) * wave * 0.2 * strength;
			albedo = mix(albedo, albedo * vec3(1.05, 1.12, 0.95), behind * strength);
		}
	}
}

// The wind-wave crest rolling across the land at a spot, 0 to 1 (18 §4.2): a
// dual-octave world-space wave, so gusts sweep visibly over a meadow.
float wind_wave(vec2 world_xz) {
	float wave = sin(world_xz.x * 0.18 + world_xz.y * 0.12 - TIME * 2.4) * 0.65
		+ sin(world_xz.x * 0.07 - world_xz.y * 0.11 - TIME * 1.3) * 0.35;
	return smoothstep(0.25, 1.0, wave);
}

// The Frozen Wind: inside an open crack's blight plants barely stir (blight_wind.x of the world wind).
float frozen_wind_scale(vec3 world_pos) {
	float still = blight_wind.x > 0.0 ? blight_wind.x : 0.05;
	return mix(1.0, still, blight_at(world_pos));
}

// Wind sway for a vertex `height` metres up a plant, at a world spot: its own
// sway plus the rolling wind-wave, stilled by the blight.
vec3 wind_offset(vec3 world_origin, float height, float flex) {
	vec2 dir = normalize(world_wind.xz + vec2(0.0001));
	float phase = dot(world_origin.xz, vec2(0.17, 0.23));
	float sway = sin(TIME * 1.7 + phase) * 0.6 + sin(TIME * 2.9 + phase * 1.3) * 0.25;
	sway += wind_wave(world_origin.xz) * 0.9;
	float bend = flex * world_wind.w * height * height * frozen_wind_scale(world_origin);
	return vec3(dir.x, 0.0, dir.y) * sway * bend;
}

// Grass and ferns lean away from heroes within 1.2 m.
vec3 brush_offset(vec3 world_pos, float height) {
	vec4 heroes[4] = vec4[4](hero_pos_0, hero_pos_1, hero_pos_2, hero_pos_3);
	vec3 push = vec3(0.0);
	for (int i = 0; i < 4; i++) {
		if (heroes[i].w < 0.5) {
			continue;
		}
		vec2 away = world_pos.xz - heroes[i].xz;
		float d = length(away);
		float close = 1.0 - smoothstep(0.2, 1.2, d);
		push.xz += normalize(away + vec2(0.0001)) * close * height * 0.55;
		push.y -= close * height * 0.25;
	}
	return push;
}

// --- Terrain (storybook_terrain_splat.gdshader and the Terrain3D landblock shader) ---

// Which of the four terrain crafts a painted ground colour is (sRGB-ish values)
// and its slope: x turf, y flagstone road, z loam, w granite. The painted colour
// field is the one source of truth, so both terrain modes splat the same way.
vec4 terrain_class_weights(vec3 painted, vec3 n) {
	float lum = luminance(painted);
	float top = max(painted.r, max(painted.g, painted.b));
	float sat = (top - min(painted.r, min(painted.g, painted.b))) / max(top, 0.001);
	float green = smoothstep(0.0, 0.06, painted.g - max(painted.r, painted.b));
	float warm = smoothstep(0.02, 0.08, painted.r - painted.g) * (1.0 - green);
	float grey = (1.0 - smoothstep(0.08, 0.16, sat)) * (1.0 - green);
	float road = warm * smoothstep(0.36, 0.46, lum) + grey * smoothstep(0.5, 0.56, lum);
	float loam = warm * (1.0 - smoothstep(0.36, 0.46, lum));
	float crag = max(smoothstep(0.86, 0.66, n.y), grey * (1.0 - smoothstep(0.5, 0.56, lum)));
	vec4 w = vec4(max(green, 1.0 - clamp(road + loam + crag, 0.0, 1.0)), road, loam, crag);
	return w / max(w.x + w.y + w.z + w.w, 0.0001);
}

// The crafts' detail over the painted colour (each texture divided by its own
// average, so the ground keeps its value) and the ground's bent normal.
vec3 terrain_detail(vec3 world_pos, vec3 n, vec4 w, float normal_strength, out vec3 bent) {
	vec2 flat_uv = world_pos.xz;
	vec3 turf = texture(atelier_albedo, vec3(flat_uv * 0.25, LAYER_TURF)).rgb / craft_average(LAYER_TURF);
	vec3 road = texture(atelier_albedo, vec3(flat_uv * 0.33, LAYER_FLAGSTONE)).rgb / craft_average(LAYER_FLAGSTONE);
	vec3 loam = texture(atelier_albedo, vec3(flat_uv * 0.25, LAYER_LOAM)).rgb / craft_average(LAYER_LOAM);
	vec3 tw = triplanar_weights(n);
	vec3 crag = craft_sample(atelier_albedo, world_pos, tw, LAYER_GRANITE, 0.2).rgb / craft_average(LAYER_GRANITE);
	vec3 tn_turf = texture(atelier_normal, vec3(flat_uv * 0.25, LAYER_TURF)).xyz * 2.0 - 1.0;
	vec3 tn_road = texture(atelier_normal, vec3(flat_uv * 0.33, LAYER_FLAGSTONE)).xyz * 2.0 - 1.0;
	vec3 tn_loam = texture(atelier_normal, vec3(flat_uv * 0.25, LAYER_LOAM)).xyz * 2.0 - 1.0;
	vec3 flat_tn = tn_turf * w.x + tn_road * w.y + tn_loam * w.z;
	vec3 crag_n = craft_normal(world_pos, n, tw, LAYER_GRANITE, 0.2, normal_strength);
	vec3 flat_n = normalize(n + normal_strength * vec3(flat_tn.x, 0.0, flat_tn.y));
	bent = normalize(mix(flat_n, crag_n, w.w));
	return turf * w.x + road * w.y + loam * w.z + crag * w.w;
}


// --- Phase 18: the frayed road edge, the verge and the slope contract (18 §3) ---

// The road's weight once its edge is frayed: the painted road weight
// (w_vertex) nudged by the flagstones' own relief and a two-octave world noise,
// so stones poke out into the grass and turf creeps between the outer stones.
float frayed_road(float w_vertex, vec2 world_xz) {
	float stone = luminance(texture(atelier_albedo, vec3(world_xz * 0.33, LAYER_FLAGSTONE)).rgb) / max(luminance(craft_average(LAYER_FLAGSTONE)), 0.001);
	float h_stone = clamp((stone - 0.6) / 0.8, 0.0, 1.0);
	float n_fray = world_noise(world_xz * 0.85) * 0.65 + world_noise(world_xz * 2.6 + vec2(17.0, 3.0)) * 0.35 - 0.5;
	return smoothstep(0.42, 0.58, w_vertex + (h_stone - 0.5) * 0.45 + n_fray * 0.28);
}

// The slope contract's three classes from a world normal: walkable (0 to 25°), a
// steep bank (26 to 45°: loam, scree and root-ribs) and an impassable cliff (over 48°).
float bank_share(vec3 n) {
	return smoothstep(0.91, 0.87, n.y) * (1.0 - smoothstep(0.72, 0.68, n.y));
}

float cliff_share(vec3 n) {
	return smoothstep(0.72, 0.64, n.y);
}

// The whole ground look, shared by Mode B's splat shader and the Terrain3D
// shader: the painted colour (sRGB-ish `painted`, linear `base`), the crafts'
// detail, the frayed road edge and its loam verge, scree on banks, horizontal
// crag strata on cliffs, and a dark toe at a cliff's foot (`toe`, 0 to 1).
vec3 storybook_ground(vec3 painted, vec3 base, vec3 n, vec3 world_pos, float toe, float detail_strength, float normal_strength, out vec3 bent) {
	bent = n;
	vec3 color = base;
	if (atelier_ready < 0.5) {
		return color * (1.0 - toe * 0.35);
	}
	vec4 classes = terrain_class_weights(painted, n);
	float w_vertex = classes.y / max(classes.x + classes.y, 0.0001);
	float road = frayed_road(w_vertex, world_pos.xz);
	// Across the edge band the colour switches per pixel between the biome's turf and road, not along the triangles.
	float edge = smoothstep(0.03, 0.18, w_vertex) * (1.0 - smoothstep(0.82, 0.97, w_vertex)) * (1.0 - classes.w);
	if (ground_turf.a > 0.0) {
		color = mix(color, mix(ground_turf.rgb, ground_road.rgb, road), edge);
	}
	float flat_share = classes.x + classes.y;
	vec4 split = vec4(flat_share * (1.0 - road), flat_share * road, classes.z, classes.w);
	classes = mix(classes, split, edge);
	vec3 detail = terrain_detail(world_pos, n, classes, normal_strength, bent);
	color *= mix(vec3(1.0), detail, detail_strength);
	// The trodden loam-and-clover verge along the outer band, 18% darker.
	float verge = smoothstep(0.14, 0.24, w_vertex) * (1.0 - smoothstep(0.46, 0.56, w_vertex)) * (1.0 - road) * (1.0 - classes.w);
	vec3 verge_color = ground_verge.a > 0.0 ? ground_verge.rgb : vec3(0.077, 0.110, 0.040);
	float clover = smoothstep(0.55, 0.8, world_noise(world_pos.xz * 4.0));
	color = mix(color, mix(verge_color, verge_color * vec3(1.25, 1.3, 1.1), clover) * (luminance(color) / max(luminance(verge_color), 0.001)) * 0.9, verge * 0.6);
	color *= 1.0 - verge * (ground_verge.a > 0.0 ? ground_verge.a : 0.18);
	// A steep bank (26 to 45°): exposed loam, pebble scree and root-ribs.
	float bank = bank_share(n) * (1.0 - road);
	vec3 loam = texture(atelier_albedo, vec3(world_pos.xz * 0.25, LAYER_LOAM)).rgb;
	float pebbles = smoothstep(0.6, 0.75, world_noise(world_pos.xz * 5.0 + world_pos.y));
	float ribs = smoothstep(0.86, 0.95, world_noise(vec2(world_pos.y * 2.6, (world_pos.x + world_pos.z) * 0.45)));
	vec3 scree = mix(loam * 0.9, loam * 1.35 + vec3(0.03), pebbles) * (1.0 - ribs * 0.45);
	color = mix(color, scree * (luminance(base) / max(luminance(loam), 0.001)) * 0.95, bank * 0.75);
	// An impassable cliff (over 48°): horizontal sedimentary strata with dark fissure bands.
	float cliff = cliff_share(n);
	vec3 tw = triplanar_weights(n);
	vec3 crag = craft_sample(atelier_albedo, world_pos, tw, LAYER_GRANITE, 0.2).rgb;
	float layer_wave = sin(world_pos.y * 4.2 + world_noise(world_pos.xz * 0.35) * 2.0);
	float strata = mix(0.8, 1.06, smoothstep(-0.4, 0.7, layer_wave)) * (1.0 - smoothstep(-0.82, -0.94, layer_wave) * 0.45);
	color = mix(color, crag * strata * (luminance(base) / max(luminance(crag), 0.001)) * 0.92, cliff);
	bent = normalize(mix(bent, craft_normal(world_pos, n, tw, LAYER_GRANITE, 0.2, normal_strength * 1.4), cliff));
	// The cliff's dark toe: contact shadow over its lowest 0.8 m.
	color *= 1.0 - toe * 0.35;
	return color;
}

// Rolling cloud shadow at a spot, 0 to 1 (18 §4.4): broad organic patches about 35 m across, drifting with the wind.
float cloud_shadow(vec2 world_xz, float time) {
	float scale = cloud_shadow_params.y > 0.0 ? cloud_shadow_params.y : 0.028;
	vec2 drift = cloud_shadow_params.zw * time;
	vec2 p = (world_xz - drift) * scale;
	float c = world_noise(p) * 0.65 + world_noise(p * 2.1 + vec2(5.2, 1.3)) * 0.35;
	return smoothstep(0.52, 0.68, c);
}
