## Nov 22 — Why "falling through the ground" instead of a loading screen (F687), and a wood-model to-do (F686)

**What we did:** The owner started a new game and instead of the loading screen saw their dwarf just floating in a
black, starry void — and said they were "falling through the ground" and had to close the game.
- Checked the real play session's log (`user://watch.txt` and the matching rotated `godot.log`, found by timestamp —
  Godot keeps one log file per run in `logs/`, and only the one that says "PLAYER GAME (not a robot)" is the owner's
  real session, not one of the several test robots that were also running on the same PC at the time).
- That log was full of `SCRIPT ERROR: Compile Error: Failed to compile depended scripts.` for nearly every file in
  the game (`main.gd`, `dwarf.gd`, the HUD, the cave builder...), tracing back to one real error:
  `src/combat/dwarf_fight.gd:331`, `Cannot infer the type of "eff_reach" variable because the value doesn't have a
  set type.` That one broken line made Godot refuse to compile `main.gd` itself. The game still tried to start with
  half its pieces missing — no HUD, no player model, nothing solid underfoot — which is exactly what an empty void
  with a floating dwarf looks like.
- That line belonged to another Claude window's in-progress (uncommitted) edit on this same shared PC — not
  something broken by us. By the time we looked, that other window had already fixed it (added `: float` to the
  variable), just hadn't committed it yet, so we left that file alone (not ours to commit) and only logged what
  happened.
- Also added the owner's wood-model note to the to-do list: the wood 3D model is too simple and needs a real art
  pass, like the workbenches got.
- Logged both as F686 (open) and F687 (closed, since the fix already landed) in `FEEDBACK.md`, with a note that if
  this happens again it means two Claude windows are mid-edit on the same file — not a new bug to chase.

**Mistakes and hurdles:**
- None on our side this time — the actual breakage was another Claude session's in-progress edit, not ours; the fix
  had already landed in the working tree by the time we investigated, we just confirmed it and documented it.

**Files changed:** `FEEDBACK.md`.
