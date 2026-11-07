// The painter's hand (docs/24_PAINTED_WORLD_PASS.md §2): what turns flat,
// clean colour into a lived-in storybook painting.
//   sb_brush   a stroke field in world space (-1..1): the cel shade's edge
//              wanders along it, like gouache laid on by hand, never a clean
//              computer terminator (storybook_cel_light.gdshaderinc reads v_brush)
//   sb_weather a flat colour, lived in: broad sun-faded and grimy blotches, fine
//              flecks, darker creases where the surface turns sharply, and
//              moss on faces that look up
// Every shader that includes it writes v_brush in fragment(), from the world position.
#ifndef STORYBOOK_BRUSH_INC
#define STORYBOOK_BRUSH_INC
#define STORYBOOK_BRUSH

varying float v_brush;

float sb_hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// Smooth value noise, 0..1.
float sb_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(sb_hash(i), sb_hash(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(sb_hash(i + vec3(0.0, 1.0, 0.0)), sb_hash(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(sb_hash(i + vec3(0.0, 0.0, 1.0)), sb_hash(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(sb_hash(i + vec3(0.0, 1.0, 1.0)), sb_hash(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}

// Strokes about 40 cm long and 12 cm wide, laid on the diagonal, with a finer
// scumble over them: -1..1.
float sb_brush(vec3 world) {
	vec3 p = vec3(world.x + world.z * 0.6, world.y * 1.4, world.z - world.x * 0.6);
	float stroke = sb_noise(p * vec3(2.4, 7.5, 7.5));
	float scumble = sb_noise(p * 9.0 + 17.0);
	return (stroke * 0.7 + scumble * 0.3) * 2.0 - 1.0;
}

// A flat colour, lived in. `wear` 0..1 scales the blotches and flecks, `moss` 0..1
// greens the faces that look up, `crease` is how sharply the surface turns here
// (length(fwidth(normal))), darkening edges and joins like soot and handling.
vec3 sb_weather(vec3 color, vec3 world, vec3 world_normal, float wear, float moss, float crease) {
	float broad = sb_noise(world * 0.55 + 3.0);
	float mid = sb_noise(world * 2.1 + 9.0);
	float fleck = sb_noise(world * 11.0);
	// Sun-faded patches lift and warm the colour; grime sinks and greys it.
	vec3 faded = mix(color, color * vec3(1.08, 1.06, 0.98) + vec3(0.015, 0.012, 0.0), smoothstep(0.55, 0.85, broad));
	vec3 grimed = mix(faded, faded * vec3(0.78, 0.76, 0.74), smoothstep(0.5, 0.9, 1.0 - broad) * 0.7);
	vec3 weathered = grimed * (0.9 + 0.2 * mid) * (0.94 + 0.12 * fleck);
	vec3 aged = mix(color, weathered, wear);
	// Handled, sooty edges where the surface turns.
	aged *= 1.0 - clamp(crease * 6.0, 0.0, 0.28) * wear;
	// Moss on the tops, broken up.
	float up = smoothstep(0.55, 0.9, world_normal.y);
	float patch = smoothstep(0.45, 0.75, sb_noise(world * 1.3 + 5.0) * 0.7 + fleck * 0.3);
	vec3 moss_tone = vec3(0.075, 0.16, 0.05) * (0.8 + 0.4 * mid);
	return mix(aged, moss_tone, up * patch * moss);
}
#endif
