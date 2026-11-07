// The storybook cel look shared by actors and props (07_EXPEDITION_HUD_AND_ART_GDD.md
// §4.2): two crisp bands of sunlight (storybook_cel_light.gdshaderinc), a
// Fresnel rim light round the silhouette, tinted per material (by role on a
// hero, a soft warm light on scenery), and a glow for hit flashes and tells.
// storybook_cel.gdshader, storybook_cel_double.gdshader and storybook_cel_vertex.gdshader
// (vertex-coloured: terrain, HLOD proxies, clutter) include this.

#define STORYBOOK_RIM
#include "res://src/actors/storybook_brush.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.94, 0.8, 1.0);
uniform float rim_strength : hint_range(0.0, 3.0) = 0.25;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
// Hit flashes, flow glows and wind-up tells (StorybookMaterial.set_glow).
uniform vec4 glow : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// Lived in (docs/24 §2): how weathered the flat colour is, and how much moss its tops carry.
uniform float wear : hint_range(0.0, 1.0) = 0.85;
uniform float moss_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
#ifdef USE_VERTEX_COLOR
	// Vertex and instance colours are authored in sRGB (17 GDD §2.3), like Terrain3D's colour maps.
	vec3 base = albedo.rgb * pow(COLOR.rgb, vec3(2.2));
#else
	vec3 base = albedo.rgb;
#endif
	vec3 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_brush = sb_brush(world);
	ALBEDO = sb_weather(base, world, world_normal, wear, moss_amount, length(fwidth(NORMAL)));
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = glow.rgb;
}

#include "res://src/actors/storybook_cel_light.gdshaderinc"
