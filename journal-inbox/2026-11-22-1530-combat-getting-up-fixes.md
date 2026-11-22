# Combat: enemies hard to hit while down, attacks during get-up, boss tune-up (F665–F672)

## What we did

Play-tested Dungeon 3 and Dungeon 4, found 8 new combat bugs, fixed all 8.

**F665 — Hit arc fails when standing over a fallen enemy**  
When you stand directly on top of a knocked-down skeleton, the flat (horizontal) direction from you to the monster is nearly zero-length.  Calling `normalized()` on a near-zero vector gives nonsense, so the arc check rejected every hit.  Fix: skip the arc check when `flat.length() ≤ 0.3 m` — if you're that close, any swing hits (`dwarf_fight.gd:_impact`).  This also fixed the spear-teleport: the third hit landed, the boss got the physics snap from restoring collision, and that looked like a teleport.

**F666 — Monsters face the wrong way and attack while getting up**  
`get_up()` sets `knocked_down = false`, which lets the CHASE state run `_face(target)` and `_start_attack` on the very same frame, before the rise animation finishes.  Visible as a sudden direction snap and hits landing mid-get-up.  Fix: added a `rig._busy_kind == "rise"` guard in `_start_attack` (so the host never sends the tell during the animation) and a matching still-stand check in CHASE state (holds position and skips `_face` while rising).

**F667 — Bone Rot (small skeletons) die in one or two hits**  
HP was 26.  A knock + finisher was enough.  Raised to 60 — they now take a few blows and get back up at least once.

**F668 — Two Dungeon 4 second-floor guards wake early**  
They stand in the open `great_cave` room (Y 0–16), which the player enters at the dungeon door.  Climbing the first ladder puts the player within their 11 m `rise_near` trigger while still below the second floor.  Fix: added `second_floor_hall` to `dungeon_map.gd` covering their landing area (X 23–32, Z 23–29, Y 4–10).  Their `dungeon_room` becomes `second_floor_hall`, so proximity only triggers once the player reaches the second floor.

**F669 — Prop Warden Plank Sweep has no visible red halo**  
`_red_outline` was being called correctly (confirmed in code), but `grow_amount = 0.025` (2.5 cm) was barely visible on the boss's larger mesh.  Raised to 0.05 (5 cm).

**F670 — Untelegraphed second Axe Chop**  
The Axe Chop had no `rest` period.  After a 1.6 s recover window the boss could immediately pick it again, producing a double-chop with no gap.  Added `rest = 5.0` s to Axe Chop.

**F671 — Shield Charge never hits**  
The beetle-charge fix (F111) reduced all lunge hit-reach to `size*0.6+0.8 = 1.4 m` at impact.  The Shield Charge travels at 11.1 m/s and overshoots the player every time.  Fixed with a new `lunge_reach` field: added `lunge_reach = 3.0` to the Shield Charge data, and `send_tell` now uses `atk.lunge_reach` when present instead of the global formula.

**F672 — Parry star (glint) on unblockable boss attacks**  
`_glint_later` fired for every attack including `parry="shield"` ones.  The PickGlint star is the parry cue — showing it on unblockable attacks was misleading.  Fix: `creature_rig.attack()` skips `_glint_later` when `red=true` (both the charge-enter and normal-swing paths).

## Mistakes and hurdles

- The arc check in `dwarf_fight.gd` had **three** identical lines (monsters, furniture, friendly-fire).  Edit rejected with "2 matches, replace_all is false."  Had to use surrounding context to target only the monster line (line 331).
- F-number collision: FEEDBACK-done.md already has an F659 (the ghost fade-and-jump, an older fix).  The previous session also logged F659 for the skeleton knockdown.  Next number picked was F665 to clear the ambiguity zone (F660–664 were already used elsewhere in FEEDBACK.md).
- The `second_floor_hall` room needed careful bounds: X 23–32 to include both guard positions (27.0 and 28.8), Z 23–29 to stay south of the great cave opening, Y floor=4 so the room only starts at the top of the ladder.

## Files changed

- `src/combat/dwarf_fight.gd` — arc skip when flat ≤ 0.3 m
- `src/combat/creature_rig.gd` — skip glint for red attacks (2 spots)
- `src/combat/monster.gd` — rising guard in `_start_attack`; still-stand in CHASE while rising; `grow_amount` 0.025 → 0.05
- `src/combat/monsters.gd` — Bone Rot hp 26 → 60; Axe Chop rest=5; Shield Charge lunge_reach=3
- `src/combat/monster_manager.gd` — `send_tell` uses `lunge_reach` when present
- `src/world/dungeon_map.gd` — added `second_floor_hall` room
- `FEEDBACK.md` — added F665–F672 (all marked fixed)
