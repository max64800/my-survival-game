# Claude reference (read only the part you need)

Moved out of `CLAUDE.md` on Nov 16, 2026 to save tokens. The rules are still in `CLAUDE.md`; this page is the "how".

## How the code is laid out
- `src/world/`: Cave Maker (seed → SDF + materials), World (Voxel Tools terrain, digging), Glow Placer/Field, terrain shader, `mat.gd` (materials + hardness).
- `src/net/game_authority.gd`: the referee. Every world change is `request_*` (approve) → `_do_*`/`_ev_*` (everyone applies). Keep it that way for co-op.
- `src/build/`: pieces catalog (`pieces.gd`), builder (placing, collapse, rubble, blueprint sites), piece looks, build mode.
- `src/player/`: Dwarf (movement, camera, swing), model/rig, lantern, controls, fx, placing preview.
- `src/items/`: item list, recipes, inventory, drops. `src/ui/`: HUD, menus, crafting and build panels.
- `src/progress/`: XP, perks, Next-steps goals. `src/combat/`: monsters, fights.
- `src/debug/`: robots (`autopilot`, `buildcheck`, `kitcheck`, `netcheck`...), scripted runs with screenshots.
- Design docs: `docs/design/` (start with its README). Zone 1 pacing: `docs/design/zone1-progression.md`.
- Creatures: `docs/art/CREATURE-STYLE.md` + `docs/art/MODEL-RULES.md`; hand-built in Blender by script
  (`tools/asset_forge/creature_kit.py`, `build_creatures.py`), matching `assets/concepts/creatures/`. Never picture-to-3D.
- Model checks: `tools/model_check/` (Blender: floating parts, shimmer, outline, roofs, build script);
  piece pictures for the build menu: `python tools/model_check/make_piece_icons.py`.

## Play-session recordings (Windows PC)
- Every time the owner plays (desktop icon or Godot F5), `tools/recorder/` records it with OBS into
  `Videos\Dwarf Game Recordings\<date time>\`: `video.mp4`, `game-log.txt`, `session.json`, `feedback.txt`,
  `snapshots\tMMSS.jpg`, and `report.md` (a background read-only Claude on Sonnet, per `tools/recorder/analysis_prompt.md`).
- The feedback pop-up is off (owner gives feedback in chat). `session_report.ps1 -AskFeedback` turns it back on.
- Runs Claude starts (terminal/script, `autopilot`/`netcheck`) are never recorded; only games a person starts.
- After handling a session, write `reviewed.txt` in its folder (date + what was done).

## Running the game and checks
- Auto-checks: `tools/run_tests.sh` (Mac) / `tools\run_tests.bat` (Windows). Set `GODOT` to the Godot program.
  `only=name` runs one file. Every new system gets a `tests/test_*.gd`.
  Plain run = quick: skips checks that took 10 s+ last time (times kept in `user://test_times.json`, per computer);
  `full=1` runs everything. Prints only FAILs, slow tests (>20 s) and the summary; `verbose=1` shows every PASS, `QUIET=0` the raw output.
- Any other run: `python3 tools/quiet_run.py <godot> --headless --audio-driver Dummy --path . -- claude=<test> ...`
  (game prints folded into "(x17)", Godot's end-of-run "leaked at exit" lines dropped, long output cut to first 40 + last 80).
- Autopilot: `godot --audio-driver Dummy --path . -- autopilot seed=42 shots=<folder>`: a report (load time, items dug, FPS) + screenshots.
- `godot --audio-driver Dummy --path . -- seed=1234` starts a specific cave. Robots: `-- buildcheck part=house|edges`, `-- kitcheck`.
- Budget hook: `.claude/settings.json` runs `tools/claude-budget/check.py` before every step (keep it as it is).

## Handoff prompt recipe (owner, Nov 21)
The new chat knows nothing, and every word of the prompt is re-read on every step, so make it **short and exact**
(aim for 150–300 words). A good prompt lets the new Claude start working with 2–3 small reads, not a hunt.
Fill these, in this order, one short line each:
1. **Who + model:** "You are a Claude on the dwarf game (PC). Model: Sonnet." (the `# 👉 FIRST TYPE: /model …` heading goes above the block)
2. **Task:** one sentence, the goal in the owner's words, plus F-numbers.
3. **Next step first:** the very next thing to do, as a numbered list (max 5 steps).
4. **Exact places:** `file:function` (and the CODE-MAP line) for every spot to change, e.g.
   `src/world/loot_props.gd: ask_loot()`. Never "look around the loot code".
5. **Done:** commit hashes + one line each. "Don't redo / don't re-read X."
6. **Owner chose:** decisions and taste notes the owner gave in this chat (quotes are best).
7. **Waiting for the owner:** open questions, so the new chat asks instead of guessing.
8. **Watch out:** traps found this chat (failing test from another chat, shared files to stage by hunk, etc.).
Leave out: the story of how we got here (that's in JOURNAL.md), rules already in CLAUDE.md, whole file dumps.
