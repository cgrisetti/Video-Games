// The ground: meadow grass with soft light and dark patches, and the paths worn into it.
// Where the paths are comes from a mask the Glen draws (red: worn path, green: shade by the hedges).
shader_type spatial;

#include "res://shaders/noise.gdshaderinc"

uniform sampler2D path_mask : filter_linear;
uniform vec2 mask_origin = vec2(-60.0, -60.0); // The world x, z of the mask's top-left corner...
uniform float mask_size = 120.0; // ...and how many metres it covers.
uniform vec3 grass_light : source_color = vec3(0.42, 0.56, 0.2);
uniform vec3 grass_dark : source_color = vec3(0.2, 0.34, 0.12);
uniform vec3 dirt_light : source_color = vec3(0.64, 0.52, 0.36);
uniform vec3 dirt_dark : source_color = vec3(0.42, 0.32, 0.22);

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 xz = world_position.xz;
	vec4 mask = texture(path_mask, (xz - mask_origin) / mask_size);
	float patch = fbm(xz * 0.08);
	float fine = fbm(xz * 1.7);
	vec3 grass = mix(grass_dark, grass_light, smoothstep(0.25, 0.75, patch) * 0.8 + fine * 0.2);
	grass = mix(grass, grass * vec3(1.1, 1.0, 0.7), smoothstep(0.6, 0.8, fbm(xz * 0.03 + 7.0)) * 0.5); // Dry, golden patches.
	// The worn path: packed earth with pebbles, its edge broken up so it isn't a clean line.
	float worn = smoothstep(0.35, 0.65, mask.r + (fine - 0.5) * 0.35);
	float pebbles = smoothstep(0.82, 0.9, value_noise(xz * 14.0)) * smoothstep(0.4, 0.7, fbm(xz * 0.9)) * worn;
	vec3 dirt = mix(dirt_dark, dirt_light, fbm(xz * 0.6) * 0.7 + fine * 0.3);
	dirt = mix(dirt, vec3(0.66, 0.6, 0.52), pebbles * 0.35);
	vec3 color = mix(grass, dirt, worn);
	color *= 1.0 - mask.g * 0.45; // Shade at the foot of the hedges.
	ALBEDO = color;
	ROUGHNESS = mix(0.95, 0.85, worn);
	SPECULAR = 0.2;
	float tilt = fine - fbm(xz * 1.7 + vec2(0.04, 0.0));
	NORMAL_MAP = normalize(vec3(0.5 + tilt * 4.0, 0.5, 1.0)) * 0.5 + 0.5;
}
