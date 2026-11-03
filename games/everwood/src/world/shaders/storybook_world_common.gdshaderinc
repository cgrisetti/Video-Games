// What every world shader shares (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §3):
// the atelier's craft textures (ProceduralTextureAtelier, set as global
// parameters by the WorldAtmosphereDirector), the heroes' positions for the
// camera sightline fade and the grass brush, the open Hush-Cracks and the
// Reclamation Blooms of Ecological Succession, and the wind.

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

// Ecological Succession on a surface: greyed toward slate inside an open crack's
// hush (with a hairline rim), and a golden-emerald wave where one was just sealed.
void apply_succession(vec3 world_pos, inout vec3 albedo, inout vec3 emission, float strength) {
	vec4 cracks[4] = vec4[4](hush_crack_0, hush_crack_1, hush_crack_2, hush_crack_3);
	vec4 blooms[4] = vec4[4](bloom_0, bloom_1, bloom_2, bloom_3);
	for (int i = 0; i < 4; i++) {
		if (cracks[i].w > 0.0) {
			float d = length(world_pos.xz - cracks[i].xz);
			float hush = (1.0 - smoothstep(cracks[i].w * 0.65, cracks[i].w, d)) * strength;
			float grey = luminance(albedo);
			albedo = mix(albedo, mix(vec3(grey), HUSH_TINT * (grey / 0.47), 0.6), hush * 0.45);
			float rim = (1.0 - smoothstep(0.0, 0.35, abs(d - cracks[i].w * 0.92))) * step(0.6, world_noise(world_pos.xz * 3.0));
			albedo = mix(albedo, albedo * 0.72, rim * 0.6 * strength);
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

// Wind sway for a vertex `height` metres up a plant, at a world spot.
vec3 wind_offset(vec3 world_origin, float height, float flex) {
	vec2 dir = normalize(world_wind.xz + vec2(0.0001));
	float phase = dot(world_origin.xz, vec2(0.17, 0.23));
	float sway = sin(TIME * 1.7 + phase) * 0.6 + sin(TIME * 2.9 + phase * 1.3) * 0.25;
	float bend = flex * world_wind.w * height * height;
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
