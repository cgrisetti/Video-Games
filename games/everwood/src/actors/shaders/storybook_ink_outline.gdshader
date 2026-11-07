// The storybook ink line (docs/26_CHARACTER_DESIGN_LANGUAGE.md §5): a thin warm-umber
// contour round every person's silhouette and big overlaps, about ink_width
// pixels wide at any distance, never black and never thick. It is the hero
// material's next pass: the same skinned surface drawn again, back faces only,
// pushed out along its normal in screen space.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled, ambient_light_disabled, fog_disabled;

uniform vec4 ink_color : source_color = vec4(0.17, 0.11, 0.08, 1.0);
// The line's width in pixels on a 1080-line screen (thinner in a smaller split-screen view).
uniform float ink_width = 1.7;
// The hero's own near-camera fade (storybook_hero_atelier's camera_fade_distance): no line where the hero is gone.
uniform float camera_fade_distance = 1.1;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 view_normal = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 push = (PROJECTION_MATRIX * vec4(view_normal, 0.0)).xy;
	float length_push = length(push);
	if (length_push > 0.0001) {
		push /= length_push;
	}
	float pixels = ink_width * VIEWPORT_SIZE.y / 1080.0;
	clip.xy += push * pixels * 2.0 / VIEWPORT_SIZE * clip.w;
	POSITION = clip;
}

void fragment() {
	if (length(VERTEX) < camera_fade_distance) {
		discard;
	}
	ALBEDO = ink_color.rgb;
}
