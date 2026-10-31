# 03_GODOT_TDD.md — Technical Design Document (Godot 4.7.2-stable)

## 1. Directory & Repository Topology
```text
project_root/
├── CLAUDE.md
├── project.godot
├── docs/
│   └── 03_GODOT_TDD.md
└── src/
    ├── autoloads/
    │   ├── network_manager.gd         # ENet host/client + Composite player_id registry
    │   ├── instance_manager.gd        # SubViewport World3D town/dungeon switcher
    │   └── combat_director.gd         # Local hit-stop & cross-class synergy resolver
    ├── resources/
    │   ├── combat_action_resource.gd  # Data-driven skill frame data & flow links
    │   └── character_stats_resource.gd# HP, Stamina, Resonance, Poise, Threat mod
    ├── components/
    │   ├── input_component.gd         # Abstracts Master, Adventurer, & Squire Gambit modes
    │   ├── action_queue_component.gd  # 2-slot KOTOR buffer & Phase D Flow-Cancel evaluator
    │   ├── stats_component.gd         # Authoritative resource & mitigation math
    │   ├── threat_component.gd        # Boss aggro table & taunt lock timer
    │   ├── hitbox_component.gd        # Area3D weapon/spell active collision
    │   ├── hurtbox_component.gd       # Area3D bone-attached damage receiver
    │   └── state_machine/
    │       ├── state_machine.gd       # Hierarchical finite state machine
    │       └── states/                # Idle, Locomotion, Attack, Guard, Dodge, Stagger
    ├── actors/
    │   ├── actor_base.gd              # Root CharacterBody3D wiring components via signals
    │   └── raid_telegraph_decal.gd    # Standardized Yoshi-P visual shader decals
    └── ui/
        └── split_screen_viewport_grid.gd # Dynamic 1-to-4 player SubViewport container