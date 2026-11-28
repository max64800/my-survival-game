## 2026-11-28 — F417 part 2: are big ruins slow to draw? (No.)

**What we did**
- The plan was to merge each big ruin's ~1,000 building pieces into a few big shapes, because LOW FPS lines showed
  about 3,200 draw calls (a draw call = one "paint this" order to the graphics card) and 4.4 million triangles.
- First we measured with the existing robot (`ruintest=brickcrown` / `minehead` + `shots=… perf`), ruin filling the screen:
  - Brickcrown Keep: 8.8 ms a frame (about 113 FPS). Hiding every ruin piece: 6.2 ms.
  - Mine-head Works: 7.9 ms a frame (about 127 FPS). Hiding every ruin piece: 5.6 ms.
  - So merging could save at most about 2.5 ms. The owner chose: skip the merge.
- The "3,200 draw calls" lines turned out to be one-off hiccup frames (one was 1,082 ms long) where drawing took only
  2.8 ms on the computer + 8.4 ms on the graphics card.

**Mistakes and hurdles**
- The freeze log lied a little. Its "game code" number came from Godot's `TIME_PROCESS`, which is the *slowest frame of
  the whole last second*, updated once a second, not the frame being logged. So the 0.6 s hiccup said "game code 38 ms"
  and looked like a graphics problem. A small timer in the robot showed 630 ms between "game code starts" and
  "drawing starts". Fix: `FreezeWatch` now times each frame itself (physics_frame / process_frame / frame_pre_draw /
  frame_post_draw signals). SLOW FRAME says game code, physics and "handing the picture to the graphics card", plus how many
  new graphics-card programs (pipelines) were made that frame. LOW FPS says "slowest this second" honestly.
- First guess for the hiccup: shader (pipeline) compiling. The counters are running totals, so the first try printed
  "77 mesh" on every slow frame. After changing it to count per frame, the hiccup frame showed 0 new pipelines, which ruled that guess out.
- The 0.6 s hiccup is the dev test worlds' instant chest rebuild (`instant_ruins`, set only for RuinTests worlds),
  which never happens in a real world. Left alone.
- Pushing the claim commit to GitHub was blocked by the permission check; commits stay local (the other chats share the folder).

**Still open**
- While a ruin is first built in a new world, a few frames still take about 57 ms (FPS ~30 for a second). Not chased.
- Owner: play; if FPS drops, the new log lines now say which part was slow.
