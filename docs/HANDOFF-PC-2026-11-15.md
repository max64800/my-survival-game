# Handoff to the PC: what the Mac did (November 14–15, 2026) and what to build next

The Mac only planned and made pictures; it wrote no game code. Everything below is on GitHub (`main`).
Start with `git pull --ff-only`.

## 1. What was decided and drawn on the Mac

| Topic | Where to read it | Pictures |
|---|---|---|
| **Zone 1 building kit**: 3 styles, each its own design (Delver's Shack = `plank_root`, Stonehold = `cut_stone`, Hearthbrick = `clay_brick`), 55 pieces, equilateral triangles, round doors only, hollow roofs, Stonehold flat roof, copper = decor only | `docs/design/building-kit-zone1.md` | 12 reference pictures (kit sheet, finished house, "how it joins" sheet, textures × 3 styles), **only in ChatGPT** |
| **Creatures**: 12 approved concepts (snail, bat, beetle × 4 variants) | `docs/art/CREATURE-STYLE.md` | **only in ChatGPT**, chat "Creature Image Prompt" |
| **Outfits** (Leather, Copper aged v2, Shell) and **the player dwarf** (Happy body; Strong + old Smart heads swap on the same body) | `docs/design/dwarf-character-plan.md` | outfits + 6 dwarf pictures **only in ChatGPT**; heads + lineup are in the repo |
| **Owner's 33 model notes** (floating parts, too-perfect shapes, flat colour, loose rope, reskins, white edges) | `FEEDBACK.md` F34–F66, grouped in `docs/art/MODEL-FEEDBACK-2026-11-14.md` | |
| **Night batch, 32 pictures**: the 6 stations never redone, a picture for most model notes, 48 material items, decor (furniture per style, lights, storage, mine props, beams, wall trophies, fungal garden) | `docs/art/NIGHT-PICTURES-2026-11-15.md` (scores + "fix when modelling") | **in the repo**: `assets/concepts/night-2026-11-15/` |
| **Budget guard** (stops work when the weekly Claude use passes the daily line) | end of `JOURNAL.md` | |

"Only in ChatGPT" means the owner's ChatGPT Plus account, chat **"Generate Building Kit Sheet"** (building kits,
outfits, dwarf) and **"Creature Image Prompt"**. Downloading them needs the owner's OK each time (Claude in Chrome).
Save them into `assets/concepts/<topic>/` and log them in `CREDITS.md`.

## 2. Things to check first on the PC
- **Budget hook:** `.claude/settings.json` runs `python3 tools/claude-budget/check.py` before every step. On Windows,
  `python3` may not exist (or opens the Microsoft Store). If every step shows a hook error, fix it (for example
  `py -3`, or a full path to Python), and set up the status line there so the guard has numbers.
- **Unpushed models:** the game loads models from `assets/models/<folder>/<id>.glb` (`src/art/look.gd`), but GitHub has
  **no `assets/models/` folder**. If the PC has the forged workbench and other models locally, commit and push them
  first, so the Mac and the PC see the same game.

## 3. What to build next (in this order)
1. **White edges bug (F57–F59).** It shows on many building pieces when you turn the camera. It's a bug, not art,
   and it would spoil every new model.
2. **Automatic "nothing floating" check.** 8 notes were parts not touching. Add a test that loads each `.glb` and fails
   if a piece is not connected to the rest (or hangs above the ground). Then it can't come back.
3. **Building kit test slice, Delver's Shack (`plank_root`) first.** Build pieces in **Blender by script** to exact
   sizes (2 m grid, 2 m walls), not picture-to-3D. Chunky, bevelled, uneven planks, hand-painted textures, every part
   touching. One mesh per file: `assets/models/build/<piece>__plank_root.glb` (`PieceNode.forged_mesh`).
   Start with: `foundation`, `wall`, `floor`, `window_wall`, round doorway + round door, a sloped roof piece,
   `foundation_triangle` / `floor_triangle`.
   - The equilateral triangles (every side 2 m, 60° snapping) and round-only doors need changes in
     `src/build/pieces.gd` and the snapping code; the old half-square triangles and `wall_diagonal` go away.
   - Test in the game: build a small house with the robot, take screenshots, check snapping, gaps, floating
     parts and white edges. Then Stonehold, then Hearthbrick.
4. **Stations and props through the asset forge** (`tools/asset_forge/README.md`), from the night pictures. Most
   pictures show **two objects**: cut each one out on its own first (one object per picture works best). Respect the
   "fix when modelling" column. Begin with the 6 missing stations (Twin Smelter, Gem Bench, Drip Bucket, Copper Drip
   Basin, Crystal Sconce, Glow Marker) and the bellows (F34).
5. **Later:** material item models (F56), decor, creatures, then the dwarf (`dwarf-character-plan.md`).

## 4. Rules that still apply
Mute every test run (`--audio-driver Dummy`), journal every session, 5th-grade explanations, only commercial-OK
assets in `CREDITS.md`, ask before downloads, never commit personal paths or keys (the repo is public).

## The prompt for the owner to paste into Claude on the PC

```
Pull the latest main (git pull --ff-only) and read docs/HANDOFF-PC-2026-11-15.md first. It explains what the Mac
did and what to build next.

Then:
1. Do the "check first" items: make the budget hook work on Windows, and push any 3D models that exist only on
   this PC.
2. Fix the white-edges bug on building pieces (F57-F59), and add an automatic test that catches model parts
   that float or don't touch.
3. Build a test slice of the Delver's Shack building kit in Blender by script (exact sizes, chunky hand-painted
   look, every part touching, following docs/design/building-kit-zone1.md). Include the equilateral triangle
   foundation and floor, and the round door. Then build a small house in the game with the autopilot and check
   snapping, gaps, floating parts and white edges in screenshots.
4. Then forge the 6 missing stations and the bellows from the pictures in assets/concepts/night-2026-11-15/,
   one object per picture, following the "fix when modelling" notes.

Show me screenshots after each step and rate the result out of 10. If the reference pictures from ChatGPT are
needed, ask me before downloading them. Keep test runs muted and stay inside the Claude budget.
```
