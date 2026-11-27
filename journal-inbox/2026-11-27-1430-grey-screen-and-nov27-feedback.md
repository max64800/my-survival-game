## Nov 27: grey screen on dev ruins, and the Nov 27 feedback list

**What we did**
- Grey screen after clicking a dev ruin: the pull brought F917's new script `AbilityFx` (made on the Mac). This PC's
  list of named scripts was out of date, so main.gd and hud.gd failed to load. Fix: let Godot re-import
  (rebuilds the list). No code change. Checked with a muted `claude=dev_ruins_load ruintest=tower` run: "ready to play".
- Saved the owner's big Nov 27 play-session list in FEEDBACK.md: F918-F940 (23 items).
  Two came back: F938 (crossbow reload on R, taken by F917's abilities) and F940 (the road, after F900's brick road).
  F417 (9 FPS) bumped to said 2×.

**Hurdles**
- A new `class_name` from another computer doesn't register until Godot re-imports. If the game turns grey right
  after a pull, re-import first, before hunting for a code bug.
