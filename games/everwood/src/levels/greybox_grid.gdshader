// Greybox floor: a 1 m grid with a bolder line every 5 m, in world space,
// so distances (dodge length, telegraph radius) read at a glance.
shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.40, 0.41, 0.44);
uniform vec3 minor_color : source_color = vec3(0.33, 0.34, 0.37);
uniform vec3 major_color : source_color = vec3(0.24, 0.25, 0.28);

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float grid_line(vec2 p, float spacing, float width) {
	vec2 cell = abs(fract(p / spacing - 0.5) - 0.5) * spacing;
	vec2 aa = fwidth(p) * width;
	vec2 line = 1.0 - smoothstep(vec2(0.0), aa, cell);
	return max(line.x, line.y);
}

void fragment() {
	vec2 p = world_position.xz;
	vec3 color = mix(base_color, minor_color, grid_line(p, 1.0, 1.0));
	color = mix(color, major_color, grid_line(p, 5.0, 1.8));
	ALBEDO = color;
	ROUGHNESS = 0.92;
}
