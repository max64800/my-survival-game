# 2026-11-22 — Hitbox debug tool (F9 overlay)

## What we did

Owner asked for a way to see and adjust hitboxes for the dwarf and all enemy
weapons while playing, because the current values feel off.

Built `src/ui/hitbox_debug.gd` — press **F9** in-game to toggle it.

**What it shows (3-D overlay):**
- Yellow ring on the floor around each living enemy = their longest base attack reach
- Orange ring = effective reach (yellow + 0.8) — this is the actual detection radius
  the game uses. The 0.8 is a flat bonus added in `_in_reach()` in monster_manager.gd.
- Blue wireframe capsule around the dwarf = the collision shape enemies aim at
  (radius 0.36 m, height 1.35 m)

**What the panel shows:**
- All dwarf weapon base reaches (sword 1.8, spear 2.6, etc.) and their effective reach
  (base + 0.5 flat bonus added in `_impact()`)
- Every enemy creature and each of their attacks, with current reach and effective reach
- Each row has [−] [+] buttons: each click changes reach by 0.1 m
- Changes apply instantly — the 3-D rings update on the next frame, and the actual
  game detection uses the new value right away (no restart needed)
- Save button writes changes to `user://hitbox_overrides.json` so they survive
  closing the game
- Reset button puts everything back to code defaults
- "Print final values" button dumps all current numbers to Godot's Output window
  for copy-pasting to Claude

## Changes needed to support live editing

`Monsters.LIST` and `Combat.WEAPONS` were both `const`. In Godot 4.3+, `const`
dictionaries are frozen at runtime (you can't modify their contents). Changed both
to `static var` — same access pattern (`Monsters.LIST`, `Combat.WEAPONS`) but
mutable. Because monster instances store a reference to the same dict (not a copy),
modifying `Monsters.LIST["foreman"].attacks[0].reach` also updates every live
Foreman on the map instantly.

## Mistakes and hurdles

None during this build. The only thing to be careful of: `_enter_tree()` in Godot
runs before `_ready()`, so I cannot set up the ImmediateMesh in `_enter_tree()`
and then call `add_child` there — the mesh wouldn't be ready yet. Fixed by putting
both `_setup_mesh()` and the deferred `add_child` in `_ready()`.

## How the owner uses it

1. Play the game, go fight something
2. Press F9 — panel appears on the right, rings appear in the world
3. See if the orange ring (actual hit radius) looks wrong
4. Adjust with [−] [+] in the panel
5. Test: does it feel right now?
6. Happy with it? Hit Save
7. Tell Claude "save these" or click "Print final values" and paste to Claude
