# Handover: Mac Claude → PC Claude (Nov 22, 2026, evening): owner's notes + TikTok research

The Mac changed **no game code**. It sorted the owner's phone notes and 35 TikToks into the to-do list
(`FEEDBACK.md`, items **F682-F694**, all near the top of "Open"). The PC chats from the earlier handovers keep their jobs.

## 0. Do this first
1. `git status`. Your own unsaved files: commit and push only those. Other chats' files: leave them, tell the owner.
   Then `git pull --ff-only`.
2. Read each item in `FEEDBACK.md` by number (Grep `F682.` etc.), not the whole file.

## 1. The new to-do list (owner's ideas, Nov 22)
Ready to build (owner asked for them):
- **F682** Red flash at the screen edges when you lose health; green / orange / blue edges for status effects.
- **F683** 3D hitbox viewer: the dwarf's, every creature's body and every weapon's hit shape (Foreman's pickaxe: only the tip hurts).
  Goes with F518 (owner can't see the miners attack).
- **F684** Bronze: tin ore + copper, a metal between copper and iron (Zone 1 is big).
- **F685** Paths through the caves leading to dead ends, dungeons and ruins (goes with F237, places to discover).
- **F686** Long "sharp teeth" stalactites growing out of the ceiling rock; decoration, never fall. Placement rule applies.
- **F687** Slide, double jump (skill unlock), Conan-Exiles-style climbing (we already have climbing: improve it), a bit of wall running.
- **F688** Walk speeds up into run smoothly (not a jump in speed).
- **F689** Dash: tap = short, hold = longer. Build on the existing dodge (Ctrl, `src/player/controls.gd`).
- **F694** Many more free sounds (breaking, chopping, upgrading, hits, spin moves, furniture, parry). The CC0 sources are listed in the item.
  Check each pack's licence file, CC0 only, log in `CREDITS.md`.

Waiting for the owner first (ask before building):
- **F690** Bushes/grass ideas from an outdoor Unity jungle video: pick which (grass clumps along paths, coloured distance fog, crystal-lit plants).
- **F691** "Learn Godot fast": plan = read the official Godot docs + GodotPrompter skill for each new system. Nothing to build.
- **F692** AnyMove (Apache 2.0): makes creature animations from a typed move ("roar") using **our own Blender creatures**.
  Owner chose the **free route**: swap its paid video step (MiniMax on fal.ai) for Wan on the PC; skip its picture-to-3D step.
  Check the PC's graphics card memory first. Pay (~$1-3) only after asking the owner.
- **F693** Test TRELLIS (several pictures → one 3D model) as a **shape guide only** (model rule 1: never the final model).

## 2. Suggested order (owner can change it)
1. F682 hit flash + F688 smooth walk-to-run + F689 hold-to-dash (small, felt every second of play).
2. F694 sounds (big, easy win for hits, parry, chopping, furniture).
3. F683 hitbox viewer (helps fix fights, F518).
4. F684 bronze, F686 teeth stalactites, F685 cave paths.
5. F687 new moves (biggest job: one move at a time, each playable before the next).
6. Discussion items F690-F693 when the owner has time.

## 3. Things to know
- The Mac was a day behind and first used numbers F519-F529 by mistake; they were renumbered to F682-F692. If you see
  F519-F529 mentioned in an old note about these ideas, it means F682-F692.
- The TikTok research and what we won't use: journal-inbox entries from Nov 22 (18:00-18:45).
