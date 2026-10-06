// Small noise helpers shared by Lanternwood's shaders.

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// Smooth value noise, 0 to 1.
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x), mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

// A few layers of noise, from broad to fine, 0 to 1.
float fbm(vec2 p) {
	float total = 0.0;
	float amount = 0.5;
	for (int i = 0; i < 4; i++) {
		total += amount * value_noise(p);
		p = p * 2.03 + vec2(17.1, 9.4);
		amount *= 0.5;
	}
	return total / 0.9375;
}

// The wind: a slow, gusty sway that rolls across the world.
float wind_at(vec3 world, float time) {
	float gust = value_noise(world.xz * 0.05 + vec2(time * 0.12, time * 0.05));
	return (sin(time * 1.6 + world.x * 0.35 + world.z * 0.22) * 0.6 + sin(time * 3.1 + world.x * 0.9 + world.z * 1.3) * 0.25) * (0.4 + gust);
}
