// Stones and boulders: speckled grey stone, with moss on the parts that face the sky.
shader_type spatial;

#include "res://shaders/noise.gdshaderinc"

uniform vec3 rock_color : source_color = vec3(0.55, 0.53, 0.5);
uniform vec3 moss_color : source_color = vec3(0.32, 0.45, 0.16);
uniform float moss = 0.6;

varying vec3 world_normal;
varying vec3 world_position;

void vertex() {
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float triplanar(vec3 p, vec3 n, float scale) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= w.x + w.y + w.z;
	return fbm(p.yz * scale) * w.x + fbm(p.xz * scale) * w.y + fbm(p.xy * scale) * w.z;
}

void fragment() {
	float stone = triplanar(world_position, world_normal, 2.5);
	float speckle = step(0.82, triplanar(world_position, world_normal, 18.0));
	vec3 color = rock_color * mix(0.7, 1.12, stone) * (1.0 - speckle * 0.25);
	float mossy = smoothstep(0.35, 0.75, world_normal.y + (triplanar(world_position, world_normal, 1.3) - 0.5) * 0.9) * moss;
	ALBEDO = mix(color, moss_color * mix(0.8, 1.15, stone), mossy);
	ROUGHNESS = mix(0.8, 0.95, mossy);
	SPECULAR = 0.3;
}
