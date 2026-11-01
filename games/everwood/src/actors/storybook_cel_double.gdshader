// Storybook cel shading for surfaces seen from both sides, like the ramps and
// bridge decks built face by face (see storybook_cel.gdshaderinc).
shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://src/actors/storybook_cel.gdshaderinc"
