// Storybook cel shading tinted by vertex colour, for the Landblock terrain, HLOD
// proxies and instanced clutter (see storybook_cel.gdshaderinc).
shader_type spatial;
render_mode cull_back, specular_disabled;

#define USE_VERTEX_COLOR
#include "res://src/actors/storybook_cel.gdshaderinc"
