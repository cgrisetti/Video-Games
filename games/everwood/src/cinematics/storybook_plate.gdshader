// The opening film's storybook page (docs/31): one plate, framed by the timeline's pan and
// zoom, with the shot's effects drawn over it in the plate's own space, and the page's
// hand-overs (a page turn, the dissolve into the live world). PrologueFilm and
// PrologueRecap set every uniform from the timeline each frame.
//
// The grey tide drains colour through hush_drain(), the very function the world's blight
// uses (storybook_world_common.gdshaderinc), so the film's grey is the game's grey.
shader_type canvas_item;

#include "res://src/world/shaders/hush_drain.gdshaderinc"

uniform sampler2D plate : source_color, filter_linear, repeat_disable;
// Width over height: the plate's and the rect it's drawn in.
uniform float plate_aspect = 1.7778;
uniform float rect_aspect = 1.7778;
// The framing: the plate point at the rect's centre, and the zoom (1: the plate just covers the rect).
uniform vec2 center = vec2(0.5);
uniform float zoom = 1.0;
// popup_rise: the page is drawn this far below its place (a fraction of the plate's height).
uniform float lift = 0.0;
uniform float opacity = 1.0;
uniform vec4 parchment : source_color = vec4(0.957, 0.937, 0.902, 1.0);
uniform vec4 ink : source_color = vec4(0.169, 0.141, 0.125, 1.0);
// fade_from_parchment: 1 a blank page, 0 the picture.
uniform float blank = 0.0;
// glow_pulse: the gold, and how strong it breathes now.
uniform vec4 glow_color : source_color = vec4(0.949, 0.718, 0.286, 1.0);
uniform float glow = 0.0;
// tint_spread: the colour, where it starts (plate fraction) and how far it has spread (plate heights).
uniform vec4 tint_color : source_color = vec4(0.549, 0.322, 0.851, 1.0);
uniform vec2 tint_origin = vec2(0.5);
uniform float tint_radius = 0.0;
// water_rise: the sea's surface on the plate, and how far above it the sea has climbed now.
uniform float sea_line = 0.555;
uniform float sea_rise = 0.0;
// grey_drain_sweep: everything right of this x (plate fraction) is grey; above 1.5, none.
uniform vec4 hush_color : source_color = vec4(0.431, 0.471, 0.502, 1.0);
uniform float hush_edge = 2.0;
// mist_creep: mist left of this x (plate fraction); below -0.5, none.
uniform vec4 mist_color : source_color = vec4(0.431, 0.471, 0.502, 1.0);
uniform float mist_edge = -1.0;
// windmill_sail_spin: the hub (plate fraction; x below -1, none), the turn (radians), the sails'
// reach (plate heights), the tower's half width below the hub, and a rect (x0, y0, x1, y1) kept still.
uniform vec2 sail_pivot = vec2(-10.0);
uniform float sail_angle = 0.0;
uniform float sail_radius = 0.14;
uniform float sail_tower_half = 0.035;
uniform vec4 sail_keep = vec4(0.0);
// page_dissolve_to_3d: 0 the page, 1 gone into the live world.
uniform float dissolve = 0.0;
// page_turn: 0 flat, 1 turned away (it lifts from the right edge).
uniform float turn = 0.0;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x), mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	return noise(p) * 0.55 + noise(p * 2.3) * 0.3 + noise(p * 5.1) * 0.15;
}

// The plate point drawn at a rect UV: the plate covers the rect at zoom 1, cropped to its aspect.
vec2 framing(vec2 uv) {
	vec2 window = rect_aspect >= plate_aspect ? vec2(1.0, plate_aspect / rect_aspect) : vec2(rect_aspect / plate_aspect, 1.0);
	return center + (uv - 0.5) * window / max(zoom, 0.001);
}

vec3 sample_plate(vec2 p) {
	return texture(plate, clamp(p, vec2(0.0), vec2(1.0))).rgb;
}

// A plate point turned about `pivot` by `a` radians (in true proportions, not plate fractions).
vec2 turned(vec2 p, vec2 pivot, float a) {
	vec2 d = (p - pivot) * vec2(plate_aspect, 1.0);
	float c = cos(a);
	float s = sin(a);
	d = vec2(c * d.x - s * d.y, s * d.x + c * d.y);
	return pivot + d / vec2(plate_aspect, 1.0);
}

// Whether a plate pixel is part of the windmill's sails: cream cloth or a brown spar, near the hub,
// never the tower under it nor the kept rect (the windmill's name).
bool is_sail(vec2 p, vec3 c) {
	if (sail_keep.z > sail_keep.x && p.x > sail_keep.x && p.x < sail_keep.z && p.y > sail_keep.y && p.y < sail_keep.w) {
		return false;
	}
	if (abs(p.x - sail_pivot.x) * plate_aspect < sail_tower_half && p.y > sail_pivot.y + 0.012) {
		return false;
	}
	if (length((p - sail_pivot) * vec2(plate_aspect, 1.0)) > sail_radius) {
		return false;
	}
	float lum = hush_luminance(c);
	float sat = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
	bool cloth = lum > 0.84 && sat < 0.14;
	bool spar = lum < 0.42 && c.r - c.b > 0.12;
	return cloth || spar;
}

// The windmill's sails turned by sail_angle: a baked sail pixel shows the gap 45 degrees round
// (the plate without its own sails), and the turned sails are drawn over it.
vec3 sails(vec2 p, vec3 base) {
	if (sail_pivot.x < -1.0 || length((p - sail_pivot) * vec2(plate_aspect, 1.0)) > sail_radius) {
		return base;
	}
	vec3 under = is_sail(p, base) ? sample_plate(turned(p, sail_pivot, 0.7854)) : base;
	vec2 from = turned(p, sail_pivot, -sail_angle);
	vec3 sail = sample_plate(from);
	return is_sail(from, sail) ? sail : under;
}

// water_rise: the sea climbs `sea_rise` up the page from its own surface, over the arches:
// the water under the new line takes the colour of the sea just below the old one, with a
// line of foam on top.
vec3 sea_over(vec2 p, vec3 c) {
	float top = sea_line - sea_rise;
	if (sea_rise <= 0.0 || p.y < top - 0.006 || p.y > sea_line + 0.01) {
		return c;
	}
	// A soft sample of the sea under the old surface, so its ripples and marks don't streak upward.
	vec3 water = (sample_plate(vec2(p.x, sea_line + 0.03)) + sample_plate(vec2(p.x, sea_line + 0.05)) + sample_plate(vec2(p.x, sea_line + 0.07))
		+ sample_plate(vec2(p.x - 0.006, sea_line + 0.05)) + sample_plate(vec2(p.x + 0.006, sea_line + 0.05))) * 0.2;
	float under = smoothstep(top - 0.003, top + 0.003, p.y);
	float foam = 1.0 - smoothstep(0.0, 0.005, abs(p.y - top));
	return mix(mix(c, mix(c, water, 0.65), under), vec3(0.93, 0.96, 0.95), foam * 0.8);
}

void fragment() {
	vec2 p = framing(UV);
	p.y -= lift;
	bool off_page = p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0;
	vec3 c = sea_over(p, sails(p, sample_plate(p)));
	if (glow > 0.0) {
		// The gold breathes brightest where the page is already gold (the sap's veins).
		float gold = 1.0 - smoothstep(0.12, 0.45, distance(c, glow_color.rgb));
		c += glow_color.rgb * glow * (0.12 + 0.5 * gold);
	}
	if (tint_radius > 0.0) {
		float d = length((p - tint_origin) * vec2(plate_aspect, 1.0));
		float edge = tint_radius * (0.85 + 0.3 * fbm(p * 9.0));
		float inside = 1.0 - smoothstep(edge - 0.06, edge, d);
		vec3 violet = tint_color.rgb * (hush_luminance(c) / max(hush_luminance(tint_color.rgb), 0.001));
		c = mix(c, violet, inside * 0.7);
	}
	if (hush_edge < 1.5) {
		float ragged = hush_edge + (fbm(vec2(p.y * 7.0, 3.1)) - 0.5) * 0.06;
		c = hush_drain(c, hush_color.rgb, HUSH_DRAIN_SHARE * smoothstep(ragged - 0.02, ragged + 0.02, p.x));
	}
	if (mist_edge > -0.5) {
		float wisp = mist_edge + (fbm(p * vec2(4.0, 9.0) + vec2(TIME * 0.05, 0.0)) - 0.5) * 0.12;
		float fog = (1.0 - smoothstep(wisp - 0.1, wisp, p.x)) * smoothstep(0.25, 0.75, p.y);
		c = mix(c, mix(mist_color.rgb, vec3(0.9), 0.35), fog * 0.78);
	}
	if (off_page) {
		c = parchment.rgb;
	}
	c = mix(c, parchment.rgb, blank);
	float alpha = opacity;
	if (dissolve > 0.0) {
		// Watercolour holes open across the page, each with a dark wet rim, until it's gone.
		float n = fbm(UV * vec2(rect_aspect, 1.0) * 5.0);
		float threshold = dissolve * 1.25 - 0.1;
		alpha *= smoothstep(threshold, threshold + 0.03, n);
		c = mix(c, ink.rgb, (1.0 - smoothstep(0.0, 0.05, n - threshold)) * 0.85 * step(0.001, dissolve));
	}
	if (turn > 0.0) {
		// The page lifts from the right: past the fold it's gone (a soft shadow on the page under
		// it), and just before the fold its curled back shows.
		float fold = 1.0 - turn * 1.15;
		float past = UV.x - fold;
		if (past > 0.0) {
			c = ink.rgb;
			alpha *= 0.3 * (1.0 - clamp(past / 0.06, 0.0, 1.0)) * (1.0 - turn);
		} else {
			float curl = 1.0 - clamp(-past / 0.05, 0.0, 1.0);
			c = mix(c, parchment.rgb * (0.78 + 0.2 * curl), curl);
		}
	}
	COLOR = vec4(c, alpha);
}
