// Architecture, bridges, walls, rocks and stations (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §3.2):
// the atelier's craft textures projected from three sides (no stretching on
// code-built boxes and cylinders), the two storybook cel bands with a warm
// shade, moss or heather on upward faces, a Fresnel rim, the Hush-Cracks'
// greying and the Reclamation Bloom, and the camera sightline dither-fade for
// roofs, arches and upper trunks that would come between a camera and its hero.
shader_type spatial;
render_mode cull_back, specular_disabled;

#include "res://src/world/shaders/storybook_world_triplanar.gdshaderinc"
