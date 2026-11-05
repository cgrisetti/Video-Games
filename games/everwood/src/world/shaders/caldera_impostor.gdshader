// A far island across The Sound (docs/20 Part I: one landmark silhouette per
// isle, all visible from North Quay): its coarse ground and landmark in their
// own colours, eased toward the horizon's colour with distance by hand (the
// world fog would swallow them at 2 km), and into a seam's sea-fog by `mist`.
// Vertex colours arrive raw, so they're converted to linear here.
shader_type spatial;
render_mode fog_disabled, diffuse_lambert, specular_disabled;

uniform vec4 horizon_color : source_color = vec4(0.72, 0.78, 0.84, 1.0);
uniform float aerial_start = 300.0;
uniform float aerial_full = 4200.0;
uniform float aerial_max : hint_range(0.0, 1.0) = 0.6;
uniform float mist : hint_range(0.0, 1.0) = 0.0;

varying float view_distance;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	view_distance = length(world - CAMERA_POSITION_WORLD);
}

void fragment() {
	vec3 base = pow(COLOR.rgb, vec3(2.2));
	float aerial = clamp((view_distance - aerial_start) / (aerial_full - aerial_start), 0.0, 1.0) * aerial_max;
	float fade = max(aerial, mist);
	ALBEDO = mix(base, horizon_color.rgb, fade);
	EMISSION = horizon_color.rgb * fade * 0.4;
	ROUGHNESS = 1.0;
}
