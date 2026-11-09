// The First-Quiet's grey (18 §5; docs/31): where the hush touches, warm colour drains
// toward ashen slate-indigo at the colour's own value. The world's blight
// (storybook_world_common.gdshaderinc) and the opening film's grey tide
// (src/cinematics/storybook_plate.gdshader) both drain through this one
// function, so the grey a player meets in the orchards is the grey the film showed.

// The ashen slate-indigo (#6E7880) when nothing sets another.
const vec3 HUSH_TINT = vec3(0.431, 0.471, 0.502);
// How much of the warm colour the blight takes (the world's blight_ashen.a when unset).
const float HUSH_DRAIN_SHARE = 0.85;

float hush_luminance(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// `color` drained toward `ashen` by `amount` (0 untouched, 1 fully grey at its own value).
vec3 hush_drain(vec3 color, vec3 ashen, float amount) {
	vec3 drained = ashen * (hush_luminance(color) / max(hush_luminance(ashen), 0.001));
	return mix(color, drained, amount);
}
