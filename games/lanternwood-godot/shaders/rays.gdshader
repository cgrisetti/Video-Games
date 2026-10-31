// The golden raspberry's rays of sunshine: a picture that always faces the camera, turning slowly
// (set its "turn" in radians), added on top of whatever's behind it so it glows.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D rays : source_color, filter_linear_mipmap;
instance uniform float turn = 0.0;

void vertex() {
	// Face the camera, keeping the node's size.
	vec3 size = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * size.x, INV_VIEW_MATRIX[1] * size.y, INV_VIEW_MATRIX[2] * size.z, MODEL_MATRIX[3]);
}

void fragment() {
	vec2 uv = UV - 0.5;
	float c = cos(turn);
	float s = sin(turn);
	uv = vec2(c * uv.x - s * uv.y, s * uv.x + c * uv.y) + 0.5;
	vec4 light = texture(rays, uv);
	ALBEDO = light.rgb;
	ALPHA = light.a;
}
