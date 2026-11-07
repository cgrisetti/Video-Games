// The storybook sky (docs/13_PLAYTEST_KAIZEN_UPDATE_PROMPT.md §2.6): the
// procedural sky's gradient (its colour names, so WorldAtmosphereDirector's
// easing still sets them), a sun with a soft glow, two layers of painterly
// clouds (rounded cumulus lit from the sun's side with a silver rim, and a high
// thin layer of streaky cirrus) drifting with the wind, and three hazy layers of
// distant mountain ridgelines round the whole horizon: the rim of the drowned
// caldera, farther ridges paler and bluer.
// The clouds are drawn at half resolution; the light-probe (cubemap) pass draws
// only the gradient and the ridges, so the world's ambient light stays steady.
shader_type sky;
render_mode use_half_res_pass;

uniform vec4 sky_top_color : source_color = vec4(0.36, 0.56, 0.84, 1.0);
uniform vec4 sky_horizon_color : source_color = vec4(0.82, 0.86, 0.86, 1.0);
uniform vec4 ground_horizon_color : source_color = vec4(0.62, 0.7, 0.72, 1.0);
uniform vec4 ground_bottom_color : source_color = vec4(0.2, 0.32, 0.36, 1.0);
uniform float sky_curve : hint_range(0.05, 1.0) = 0.42;
uniform float sun_glow : hint_range(0.0, 2.0) = 0.55;
uniform vec4 cloud_light : source_color = vec4(1.0, 0.98, 0.93, 1.0);
uniform vec4 cloud_shade : source_color = vec4(0.6, 0.65, 0.78, 1.0);
// How much of the sky the cumulus covers, and how fast they drift (sky widths a second).
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.46;
uniform float cloud_speed = 0.0035;
uniform vec2 wind_direction = vec2(0.8, 0.6);
uniform float cirrus_amount : hint_range(0.0, 1.0) = 0.35;
// The ridgelines: the nearest layer's colour and peak height (as a share of straight up), the farthest's colour.
uniform vec4 ridge_near_color : source_color = vec4(0.33, 0.42, 0.45, 1.0);
uniform vec4 ridge_far_color : source_color = vec4(0.6, 0.68, 0.76, 1.0);
uniform float ridge_height : hint_range(0.0, 0.2) = 0.062;
uniform float ridge_seed = 7.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p, int octaves) {
	float sum = 0.0;
	float amp = 0.5;
	for (int i = 0; i < octaves; i++) {
		sum += amp * value_noise(p);
		p = p * 2.03 + vec2(17.1, 9.2);
		amp *= 0.5;
	}
	return sum;
}

// The sky's gradient above the horizon and the sea-coloured ground below it.
vec3 gradient(vec3 dir) {
	if (dir.y >= 0.0) {
		float t = pow(clamp(dir.y, 0.0, 1.0), sky_curve);
		return mix(sky_horizon_color.rgb, sky_top_color.rgb, t);
	}
	return mix(ground_horizon_color.rgb, ground_bottom_color.rgb, smoothstep(0.0, 0.35, -dir.y));
}

// A ridge layer's height (as dir.y) toward an azimuth: rounded, ridged hills.
float ridge(float azimuth, float frequency, float seed) {
	vec2 p = vec2(azimuth * frequency, seed);
	float broad = fbm(p, 4);
	float sharp = 1.0 - abs(value_noise(p * 2.7 + 3.1) * 2.0 - 1.0);
	return broad * 0.75 + sharp * 0.25;
}

// The three ridge layers over the gradient, far to near.
vec3 with_ridges(vec3 dir, vec3 base) {
	if (dir.y < -0.02 || dir.y > ridge_height * 1.4) {
		return base;
	}
	float azimuth = atan(dir.x, dir.z) / 6.2831853 + 0.5;
	vec3 color = base;
	for (int layer = 0; layer < 3; layer++) {
		float share = float(layer) / 2.0;
		float frequency = mix(9.0, 22.0, share);
		float top = ridge_height * mix(1.0, 0.55, share) * (0.35 + ridge(azimuth, frequency, ridge_seed + float(layer) * 31.7));
		if (dir.y < top) {
			// Farther layers are paler, bluer and hazier; each darkens a little toward its foot.
			vec3 tint = mix(ridge_far_color.rgb, ridge_near_color.rgb, 1.0 - share);
			tint = mix(tint, sky_horizon_color.rgb, 0.18 + 0.32 * share);
			float foot = smoothstep(top, top - 0.03, dir.y);
			color = tint * mix(1.0, 0.86, foot);
		}
	}
	return color;
}

// The clouds toward a direction: colour, and how much they cover (alpha).
vec4 clouds(vec3 dir, vec3 sun) {
	if (dir.y <= 0.0) {
		return vec4(0.0);
	}
	vec2 drift = normalize(wind_direction + vec2(0.0001)) * TIME * cloud_speed;
	// The cloud deck seen as a plane overhead: far near the horizon, close straight up.
	vec2 p = dir.xz / max(dir.y, 0.04) * 0.55 + drift;
	float n = fbm(p * 1.6, 5);
	float lift = 1.0 - cloud_cover;
	float density = smoothstep(lift, lift + 0.22, n);
	// Lit from the sun's side: compare the density a little toward the sun.
	vec2 toward = normalize(sun.xz + vec2(0.0001)) * 0.07;
	float near_sun = smoothstep(lift, lift + 0.22, fbm((p + toward) * 1.6, 5));
	float lit = clamp(0.62 + (density - near_sun) * 2.4, 0.0, 1.0);
	vec3 color = mix(cloud_shade.rgb, cloud_light.rgb, lit);
	// A silver rim where thin cloud crosses the sun.
	float sun_close = pow(max(dot(dir, sun), 0.0), 18.0);
	color += cloud_light.rgb * sun_close * (1.0 - density) * 1.4;
	// High streaky cirrus.
	vec2 q = dir.xz / max(dir.y, 0.06) * 0.16 + drift * 2.2;
	float streak = fbm(vec2(q.x * 3.2, q.y * 0.6), 4);
	float cirrus = smoothstep(0.58, 0.82, streak) * cirrus_amount * (1.0 - density);
	color = mix(color, cloud_light.rgb, cirrus * (1.0 - density));
	float alpha = max(density, cirrus * 0.7);
	// Fade into the haze at the horizon.
	alpha *= smoothstep(0.015, 0.16, dir.y);
	return vec4(color, alpha);
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 sun = LIGHT0_ENABLED ? normalize(LIGHT0_DIRECTION) : normalize(vec3(0.3, 0.6, -0.5));
	vec3 base = gradient(dir);
	if (AT_CUBEMAP_PASS) {
		COLOR = with_ridges(dir, base);
	} else if (AT_HALF_RES_PASS) {
		vec4 c = clouds(dir, sun);
		COLOR = c.rgb;
		ALPHA = c.a;
	} else {
		// The sun and its glow, then the clouds, then the ridges in front of them.
		float facing = max(dot(dir, sun), 0.0);
		vec3 sun_color = LIGHT0_ENABLED ? LIGHT0_COLOR * LIGHT0_ENERGY : vec3(1.0);
		base += sun_color * (pow(facing, 900.0) * 6.0 + pow(facing, 12.0) * 0.18 * sun_glow) * step(0.0, dir.y + 0.02);
		vec4 c = HALF_RES_COLOR;
		base = mix(base, c.rgb, clamp(c.a, 0.0, 1.0));
		COLOR = with_ridges(dir, base);
	}
}
