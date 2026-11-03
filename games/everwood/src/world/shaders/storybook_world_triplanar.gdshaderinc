// The body of the world triplanar shader (storybook_world_triplanar.gdshader and
// its two-sided twin, storybook_world_triplanar_double.gdshader).

#include "res://src/world/shaders/storybook_world_common.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
// ProceduralTextureAtelier.Set (-1: the plain colour, no texture).
uniform float craft_layer = 0.0;
// Tiles per metre.
uniform float triplanar_scale = 0.5;
uniform float normal_strength = 0.6;
// The colour keeps its value: the texture is divided by its average, so a
// builder's palette colour reads the same, only crafted. Off: the craft's own colours times the tint.
uniform bool keep_tint_value = true;
// How much of the craft texture's own colour shows through the tint (0: only its light and shade).
uniform float texture_chroma : hint_range(0.0, 1.0) = 0.4;
// Moss (or heather) on faces looking up, 0 to 1.
uniform float moss_amount = 0.0;
uniform vec4 moss_color : source_color = vec4(0.29, 0.451, 0.243, 1.0);
// Project in the mesh's own space (parts that move, like a turning wheel).
uniform bool use_object_space = false;
uniform bool sightline_fade = false;
uniform float succession_strength = 1.0;
uniform vec4 rim_color : source_color = vec4(1.0, 0.92, 0.78, 1.0);
uniform float rim_strength : hint_range(0.0, 3.0) = 0.18;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform vec4 glow : source_color = vec4(0.0, 0.0, 0.0, 1.0);

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec3 v_tex_pos;
varying vec3 v_tex_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_tex_pos = use_object_space ? VERTEX : v_world_pos;
	v_tex_normal = use_object_space ? NORMAL : v_world_normal;
}

void fragment() {
	if (sightline_fade && sightline_blocked(v_world_pos, CAMERA_POSITION_WORLD, FRAGCOORD.xy)) {
		discard;
	}
	vec3 color = albedo.rgb;
	vec3 n = normalize(v_world_normal);
	if (craft_layer >= 0.0 && atelier_ready > 0.5) {
		vec3 tex_n = normalize(v_tex_normal);
		vec3 w = triplanar_weights(tex_n);
		vec3 craft = craft_sample(atelier_albedo, v_tex_pos, w, craft_layer, triplanar_scale).rgb;
		vec3 ratio = craft / craft_average(craft_layer);
		ratio = mix(vec3(luminance(ratio)), ratio, texture_chroma);
		color *= keep_tint_value ? ratio : craft;
		vec3 bent = craft_normal(v_tex_pos, tex_n, w, craft_layer, triplanar_scale, normal_strength);
		n = use_object_space ? normalize((MODEL_MATRIX * vec4(bent, 0.0)).xyz) : bent;
	}
	float moss = smoothstep(0.65, 0.9, n.y) * smoothstep(0.3, 0.7, world_noise(v_world_pos.xz * 0.45 + v_world_pos.y)) * moss_amount;
	color = mix(color, moss_color.rgb * (0.85 + 0.3 * world_noise(v_world_pos.xz * 3.1)), moss);
	vec3 emission = glow.rgb;
	apply_succession(v_world_pos, color, emission, succession_strength);
	ALBEDO = color;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	EMISSION = emission + rim_color.rgb * pow(1.0 - facing, rim_power) * rim_strength;
}

#include "res://src/actors/storybook_cel_light.gdshaderinc"
