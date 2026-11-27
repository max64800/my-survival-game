## Nov 27–28 — F417: the big ruins no longer freeze the game when they appear

**What we did:** The owner's game froze for about 6 seconds right after a big ruin was built (Brickcrown Keep: 1046
pieces; the Mine-head Works: 816 pieces). Each ruin was placed all in one frame.
- **Measured first** with the robot world `ruintest=brickcrown`: one frame took about 9 seconds. Of that, about 3.5 s
  went to making the piece nodes (mostly reading each kind of model and checking it for floating bits). About
  4.5–5 s went to small touch-ups that ran after *every* piece: filling gaps with beams and fitting stair lips, each
  searching the pieces nearby. The strength check at the end took another 0.3 s.
- **Fix 1, read the models early:** as soon as a ruin's plan is known, every kind of model it uses starts loading in
  the background (`RuinTower._start_loading_looks`). The "floating bits?" check for each model kind now runs on a
  helper thread (a second worker inside the computer: `PieceNode.start_checking`, `PieceMesh.islands_of`).
- **Fix 2, build a little each frame:** `RuinTower._build()` now places pieces for at most 6 ms a frame. It keeps
  them hidden until the last one is in, then shows the whole ruin at once. All 10 big ruins use it.
- **Fix 3, touch-ups once at the end:** in batch mode the Builder now notes where gap beams and stair lips may be
  needed and works them all out once, at the end, spread over frames as well (`Builder.finish_batch`). The strength
  check now settles only the new pieces instead of redoing every piece in the world (`Structure.settle_step`).
- **Fix 4, small things:** each kind of piece shares one collision shape instead of building a new one per piece.
- **Result:** Brickcrown is built over about 180 frames (about 2 s). The worst frame is about 60 ms (was 9000 ms).
  Mine-head is built over about 100 frames, worst frame about 64 ms.
- **Saving:** a ruin now takes about 2 s to build, so a save could land halfway. Autosave waits until no ruin is
  building (the node group `ruin_building`). A manual save or a save when quitting finishes the ruin first.
- **Error spam:** `main.gd` read the dwarf's position before the dwarf existed. That logged 2219 errors in one
  session; it now waits. `hit_shapes.gd` read bones of a skeleton that had just left the world; it now skips that.

**Mistakes and hurdles:**
- The owner's old logs had already been rotated away, so Claude rebuilt the freeze in a robot world to measure it.
- Claude first thought making the nodes was the whole cost. Timing each step showed the per-piece touch-ups were
  the bigger half.
- One moved function came out double-indented and broke the script. It was fixed with a small dedent.
- Several shared files (`ruin_tower.gd`, `structure.gd`) held other chats' unsaved work, so only this chat's lines
  were committed.
- Pushing the "claim F417" line was blocked by the safety check, so the claim stayed local until the main commit.

**Still open:** the ruins still draw a lot (about 3200 draw calls, 4.4 million triangles with the ruin on screen),
which is the "low FPS" half of F417. That needs pieces merged into bigger meshes. It is left for its own chat.
