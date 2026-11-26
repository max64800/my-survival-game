## 2026-11-26 — Speed run (F337) started on the Mac, moved to the PC

**What we did**
- Claimed F337 (with F266, F417, F384, F750, F777), checked that no other chat was on them.
- A helper wrote the missing speed research: `docs/research/reports/2026-11-26-performance.md`
  (visibility ranges, occlusion culling, Jolt physics, animation cost, threads, finding slow frames).
- Looked at the speed robot (`src/debug/perfcheck.gd`): it already has fight, hitch, warm-up and spawn-cost modes.
  Missing: standing inside a dungeon (`maker.dungeons` + `DungeonMap.to_world`), a big player base (F777), and loading timing.

**Hurdles**
- The first robot run sat doing nothing: the game didn't start. Claude didn't check the game log until a few
  minutes later (lesson: read the log right after launching, not after waiting).
- Cause: `main` on GitHub doesn't compile. `ruin_minehead.gd:373` and `ruin_cliff_galleries.gd:398` set `ground_y`,
  which only exists in the Brickcrown chat's unsaved `ruin_tower.gd` on the PC (commit c9ca9b74 says so).
- The task was written for the PC, but this chat ran on the Mac. Owner chose: move the speed run to the PC
  (real numbers there), and let the Brickcrown chat save its work first.

**Left to do:** everything from step 3 (measuring) on, on the PC.
