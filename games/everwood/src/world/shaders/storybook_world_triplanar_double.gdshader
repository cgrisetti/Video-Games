// The world triplanar shader, seen from both sides: ramps, bridge decks and
// other extruded profiles whose faces may wind either way (storybook_world_triplanar.gdshader).
shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://src/world/shaders/storybook_world_triplanar.gdshaderinc"
