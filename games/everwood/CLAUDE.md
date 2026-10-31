# CLAUDE.md — Project Engineering Contract

## 1. Project Identity & Mission
Our mission is to build an authoritative, Godot 4.7+ cooperative action-RPG engineered for a 5-player family party—seamlessly uniting up to 4-player local split-screen with LAN/online multiplayer across instanced hub towns and raid dungeons—fusing Black Desert Online directional combo flow and Dark Souls stamina/hitbox weight with World of Warcraft Tank-Healer-DPS raid mechanics and Knights of the Old Republic action-queue/tactical assist accessibility.

## 2. Engine & Environment Constraints
- **Engine:** Godot 4.7.2-stable (3D, Forward+ Renderer, Jolt Physics 3D enabled).
- **Language:** Strictly GDScript 2.0 with mandatory static typing (`var x: float = 0.0`, `func foo() -> void:`).
- **Typed Collections:** Always use typed arrays and dictionaries (`Array[CombatActionResource]`, `Dictionary[StringName, int]`).
- **Zero Godot 3 Legacy Syntax:** NEVER use `KinematicBody`, `Spatial`, `yield()`, `connect("sig", self, "fn")`, or `@onready var` without an explicit type. Use `CharacterBody3D`, `Node3D`, `await`, and `signal_name.connect(_on_callable)`.

## 3. Architectural Laws (Read `docs/03_GODOT_TDD.md` Before Coding)
1. **Composition Over Inheritance:** Every actor (`Player`, `Boss`, `Companion`) is a `CharacterBody3D` composed of isolated child component nodes (`InputComponent`, `ActionQueueComponent`, `StateMachine`, `StatsComponent`, `CombatRig`, `NetworkSyncComponent`).
2. **Code-First Scene Safety:** Do NOT hand-edit complex `.tscn` sub-resource hashes or animations. Write `class_name` GDScript components that construct or validate their required child nodes cleanly, or use helper EditorScript/builder scripts when generating `.tscn` files.
3. **Composite Player Identity:** Separate Network Peer (`peer_id: int`) from Local Controller (`device_id: int`). Every player entity is uniquely addressed by `player_id: StringName = "%d_%d" % [peer_id, device_id]`. Max 4 local split-screen players per client; max 5 total party members in a raid instance.
4. **Musk Razor Guardrails:** No 30-slot hotbars, no Global Cooldowns (GCD), no free-aim single-target healing (use 4-way D-Pad Soul Tether + Ground Sanctuary decals), and no RNG dice-roll misses on physical hitbox collisions.

## 4. Verification & CLI Commands
After creating or modifying any `.gd` script, ALWAYS verify syntax and static types via headless CLI before concluding your turn:
- **Syntax & Type Check:** `godot --headless --check-only -s <path_to_script.gd>`
- **Project Boot Smoke Test:** `godot --headless --quit`
- **Workflow:** Explore -> Plan -> Implement -> Verify via CLI -> Commit atomic changes.
- **Autoload access:** `--check-only -s` compiles a script before autoloads are registered, so reach them as `NetworkManager.current` / `CombatDirector.current` (static), never by their autoload names (`Network`, `Combat`).
- **Functional Smoke Test:** `godot --headless --path . --fixed-fps 60 -s res://tools/smoke_test.gd` (see `README.md`).