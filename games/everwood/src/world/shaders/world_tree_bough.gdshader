// One bough of the World-Tree (docs/20 Part II §1.2, "the tree answers each
// trial"): leafy green until its trial is done, then `bloom` eases to 1 and
// it blossoms in its Sign's colour (Amber west, Sea-Azure north,
// Twilight-Violet east; the heart-leaves are Saffron from the start), glowing
// enough to read from North Quay. One parameter per bough is the whole
// progress display. Vertex colours (the leaf cloud's dark-to-light) arrive raw.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 leaf_color : source_color = vec4(0.36, 0.56, 0.28, 1.0);
uniform vec4 bloom_color : source_color = vec4(0.92, 0.6, 0.18, 1.0);
uniform float bloom : hint_range(0.0, 1.0) = 0.0;
uniform float glow = 0.9;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void fragment() {
	vec3 shade = pow(COLOR.rgb, vec3(2.2));
	vec3 leaf = leaf_color.rgb * shade * 1.6;
	float cluster = step(0.5, hash(floor(world_pos * 1.4)));
	float blossom = bloom * mix(0.6, 1.0, cluster);
	ALBEDO = mix(leaf, bloom_color.rgb * mix(0.85, 1.1, shade.r), blossom);
	EMISSION = bloom_color.rgb * bloom * glow * (0.35 + 0.65 * cluster);
	ROUGHNESS = 0.85;
}
