// The Sound (docs/20 Part I): one sea round the live island, its swell drawn
// from analytic waves, with the three currents running round The Crown
// (Iron Current west in rust, Gale Current north in sea-white, Tide Current
// east in violet). Each fades to a glassy calm once its Beacon is lit, and the
// Star-Tide's violet bleed off The Crown's east shore clears at the Ebb.
// `mist` is a seam's sea-fog. Colours from the raw vertex stream are converted;
// uniforms with source_color already are.
//
// The water reads the ground under it (docs/27 §4): over a shelving beach it
// pales to the shore colour, a line of surf breaks and fades a few metres out,
// and foam laps where it meets sand, rock, a pier or a sea stack.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, specular_schlick_ggx, cull_disabled;

#include "res://src/world/shaders/storybook_world_common.gdshaderinc"

uniform vec4 deep_color : source_color = vec4(0.13, 0.31, 0.38, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.27, 0.5, 0.52, 1.0);
uniform vec2 crown_center = vec2(0.0, 0.0);
uniform float ring_inner = 470.0;
uniform float ring_outer = 760.0;
uniform float iron_wild : hint_range(0.0, 1.0) = 1.0;
uniform float gale_wild : hint_range(0.0, 1.0) = 1.0;
uniform float tide_wild : hint_range(0.0, 1.0) = 1.0;
uniform vec4 iron_color : source_color = vec4(0.85, 0.45, 0.2, 1.0);
uniform vec4 gale_color : source_color = vec4(0.86, 0.95, 1.0, 1.0);
uniform vec4 tide_color : source_color = vec4(0.6, 0.36, 0.92, 1.0);
uniform float star_tide : hint_range(0.0, 1.0) = 1.0;
uniform float mist : hint_range(0.0, 1.0) = 0.0;
uniform vec4 mist_color : source_color = vec4(0.84, 0.86, 0.85, 1.0);
// The shallows: the colour the water pales to over a beach, and the depth it's fully deep by.
uniform vec4 shore_color : source_color = vec4(0.46, 0.74, 0.7, 1.0);
uniform float shallow_fade = 3.5;
// Surf: how far out from the shore the lines of surf break, and how much foam.
uniform float surf_reach = 2.6;
uniform float surf_amount : hint_range(0.0, 1.0) = 0.85;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float swell(vec2 p, float t, float rough) {
	return sin(p.x * 0.05 + t * 0.8) * 0.5 + sin(p.y * 0.07 - t * 0.6) * 0.5
		+ sin((p.x + p.y) * 0.11 + t * 1.3) * 0.25 * rough + sin((p.x - p.y) * 0.23 - t * 1.7) * 0.18 * rough;
}

void fragment() {
	vec2 p = world_pos.xz;
	float t = TIME;
	// How much water lies over the ground behind this pixel.
	float scene_depth = texture(depth_tex, SCREEN_UV).r;
	vec4 behind = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, scene_depth, 1.0);
	behind.xyz /= behind.w;
	float thickness = clamp(VERTEX.z - behind.z, 0.0, 60.0);
	vec2 d = p - crown_center;
	float r = length(d);
	// 0 north (-Z), +PI/2 east (+X), -PI/2 west.
	float ang = atan(d.x, -d.y);
	float north = pow(max(0.0, cos(ang)), 3.0);
	float east = pow(max(0.0, sin(ang)), 3.0);
	float west = pow(max(0.0, -sin(ang)), 3.0);
	float band = smoothstep(ring_inner, ring_inner + 80.0, r) * (1.0 - smoothstep(ring_outer - 90.0, ring_outer, r));
	float wild = clamp(north * gale_wild + east * tide_wild + west * iron_wild, 0.0, 1.0) * band;
	float rough = 1.0 + 1.6 * wild;
	float e = 0.7;
	float h0 = swell(p, t, rough);
	float hx = swell(p + vec2(e, 0.0), t, rough);
	float hz = swell(p + vec2(0.0, e), t, rough);
	vec3 n = normalize(vec3((h0 - hx) * rough, e * 3.0, (h0 - hz) * rough));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	vec3 col = mix(shallow_color.rgb, deep_color.rgb, 0.65 + 0.35 * sin(p.x * 0.0031) * sin(p.y * 0.0042));
	// The currents: flowing dashes round the ring, clockwise seen from above.
	float flow = fract(ang * 1.909 - t * 0.05 + sin(r * 0.03) * 0.08);
	float dash = smoothstep(0.0, 0.06, flow) * (1.0 - smoothstep(0.3, 0.42, flow));
	float lanes = 1.0 - smoothstep(0.08, 0.22, abs(fract(r * 0.018) - 0.5));
	float ribbon = dash * lanes * band;
	vec3 tint = iron_color.rgb * west * iron_wild + gale_color.rgb * north * gale_wild + tide_color.rgb * east * tide_wild;
	col = mix(col, tint, clamp(ribbon * 0.75, 0.0, 0.75) * step(0.001, wild));
	// A faint calm line where a current has been stilled.
	vec3 calm = iron_color.rgb * west * (1.0 - iron_wild) + gale_color.rgb * north * (1.0 - gale_wild) + tide_color.rgb * east * (1.0 - tide_wild);
	col = mix(col, calm, ribbon * 0.12);
	// The Star-Tide: the sap the old kingdom drained bleeds violet off The Crown's east shore.
	float bleed = star_tide * east * (1.0 - smoothstep(380.0, 900.0, r)) * smoothstep(300.0, 420.0, r);
	col = mix(col, tide_color.rgb * 0.55, bleed * 0.35);
	// The shallows pale over the beach, and the surf breaks in lines that fade out to sea.
	float shallow = 1.0 - smoothstep(0.0, shallow_fade, thickness);
	col = mix(col, shore_color.rgb, shallow * 0.75);
	float grain = world_noise(p * 0.35 + vec2(t * 0.07, -t * 0.05));
	float lines = 0.5 + 0.5 * sin(thickness * 5.5 - t * 1.7 + grain * 3.0);
	float surf = (1.0 - smoothstep(0.0, surf_reach, thickness)) * smoothstep(0.35, 0.75, lines);
	float lap = 1.0 - smoothstep(0.0, 0.3, thickness);
	float foam = clamp((surf * 0.8 + lap) * surf_amount * (0.7 + 0.3 * grain), 0.0, 1.0);
	col = mix(col, vec3(0.95, 0.97, 0.98), foam);
	col = mix(col, mist_color.rgb, mist * 0.85);
	ALBEDO = col;
	ALPHA = mix(1.0, 0.88, shallow * (1.0 - foam));
	ROUGHNESS = mix(mix(0.12, 0.3, wild), 0.6, foam);
	SPECULAR = 0.6;
	EMISSION = vec3(0.95, 0.97, 0.98) * foam * 0.08;
}
