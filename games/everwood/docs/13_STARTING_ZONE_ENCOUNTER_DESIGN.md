# EVERWOOD (OAKSHIRE RAIDS) — ENCOUNTER & MOB ROSTER SPECIFICATION
**Combat Mechanics & Four-Sign Synergy Integration**

## 1. Encounter Pacing & Camp Pull Math
* **Leash Spacing:** Open-field mobs maintain an $18\text{m} \text{–} 25\text{m}$ leash; camp clusters maintain $10\text{m} \text{–} 14\text{m}$ pack spacing.
* **Respawn Timer:** Dynamic $45 \text{–} 90\text{ second}$ respawn timers.
* **LoS Pull Mechanics:** Ranged add pull mechanics require the **Shield-Sworn** tank to break enemy missile trajectories using zone boulders and terrain berms.

## 2. The 6 Starting Zone Mob Families & Combat Profiles
| Family & Tier | Variants & Roles | Poise / HP Profile | Combat Behavior & Sign Counter |
| :--- | :--- | :--- | :--- |
| **1. Meadow Vermin** (Tier 1, Lvl 1–2) | • *Cider-Thief Bristleboar*<br>• *Thorn-Tail Scuttler*<br>• *Old Tusk-Crag* (Rare) | Low Poise ($15.0$), Low HP ($80$). | **100% Yellow/Neutral**; slow $1.2\text{s}$ wind-up animations designed for 1-button Gambit Assist practice. |
| **2. Weald Predators** (Tier 2, Lvl 2–3) | • *Grey-Pelt Prowler*<br>• *River-Snapper Toad*<br>• *Alpha Frost-Fang* | Medium Poise ($30.0$), Medium HP ($180$). | Red hostile aggro ($10\text{m}$ radius); linear dash telegraphs rewarded by `SIGN_RIME_GALE` (*Glacial Rupture* slow). |
| **3. Soot-Paw Outlaws** (Tier 3, Lvl 3–4) | • *Soot-Paw Cutthroat*<br>• *Quarry Sling-Shotter*<br>• *Foreman Iron-Gavel* | Mixed Poise ($45.0$), Shielded. | Grouped in 3-mob pulls (1 Heavy + 1 Melee + 1 Ranged). Teaches Tank LoS pulling and `SIGN_IRON_ROOT` (*Shatterpoint* `+45.0` poise damage). |
| **4. Blight-Thorn Briarlings** (Tier 4, Lvl 4–5) | • *Bramble-Lasher Vine*<br>• *Spore-Puff Shambler*<br>• *Bog-Hulk Tangler* | High Poise ($75.0$), Armor Bark. | Plant constructs requiring coordinated party focus to crack bark armor via heavy attacks. |
| **5. Tarnished Chime-Wights** (Tier 5, Lvl 5) | • *Risen Shield-Sworn Husk*<br>• *Hollow Scribe-Acolyte*<br>• *Barrow-Warden Knell* | Undead elites with barrier shields. | Protects dungeon gates; tests interrupt timings and `SIGN_WARM_HEARTH` (*Dawnburst* $20.0$ HP heal) party sustain. |
| **6. Ambient Wildlife & Roaming Boss** (Zone-wide) | • *Golden-Fleece Sheep*<br>• *Red Fox*<br>• *The Crag-Back Behemoth* | Boss Poise ($150.0$), Boss HP ($2,500$). | Ambient critters add life; the roaming Mini-Boss patrols outer roads with a heavy bell-stomp audio cue. |

## 3. Build Notes

The six families are built as `Bestiary` (16 fighting variants with the health and poise above), `WildMob` and `MobSpawner` (40 spawners in Oakshire Vale, 18 to 25 m leashes, 45 to 90 s respawns). The sheep and foxes are ambient critters that can't be fought. See `12_WORLD_OAKSHIRE_VALE_GDD.md` §6 for where they stand and what differs.
