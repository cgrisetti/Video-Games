# Drop-in models

Everwood draws everything from code-built shapes until you give it real art. Put a `.glb` file here, named after what it replaces, and the game uses it instead:

| File | Replaces |
|---|---|
| `shield_tank.glb`, `directional_flow_dps.glb`, `soul_tether_healer.glb` | a hero's body (the Shield-Sworn, Wayfarer, Lantern-Bearer puppet) |
| `light_sword.glb`, `heavy_axe.glb`, `scribe_staff.glb`, `hunter_bow.glb` | a weapon in the hand (Falchion, Broad-Axe, Rowan Way-Staff, Yew Longbow) |
| `ironwood_plate.glb`, `ranger_leather.glb`, `hearth_linen.glb` | armor, on an actor drawn without a puppet |
| `raid_boss_dummy.glb` | The Cairnsman of Doverslap |
| `bramble_scuttler.glb`, `bog_imp.glb` | the woodland minions |

Use only freely licensed models (CC0 packs such as KayKit or Quaternius are ideal), and keep the licence file next to the model. Open the project in the Godot editor once (or run `godot --headless --path . --import`) so Godot imports the new file. Models face -Z, stand on y = 0, and are about 1.8 m tall for a hero.
