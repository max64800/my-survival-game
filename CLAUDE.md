# Project rules for Claude

Underground dwarf survival game (3D, up to 4-player Steam co-op), built in **Godot 4.7.2** with GDScript.
Full design: `docs/superpowers/specs/2026-11-14-dwarf-survival-game-design.md`

## The owner's two rules
1. **Journal everything.** After every work session, add an entry to `JOURNAL.md`: what we did, every mistake and hurdle (including Claude's own), and how it was fixed.
2. **5th-grade explanations.** The owner does not code. Explain everything simply: short sentences, everyday comparisons, define any tech word the first time.

## Working rules
- Build in the roadmap order. Each step must be playable before the next starts.
- Keep gameplay actions "co-op ready": request → host approves → everyone updates.
- Only use assets licensed for commercial use (prefer CC0). Log every asset in `CREDITS.md`.
- **Art style rule (owner):** every model (stations, gear, outfits, building pieces, materials) is made in the same style as the workbenches: hand-painted, chunky, no perfect boxes or circles, every part touching. Each building material gets its own design, not a reskin. Make ChatGPT pictures whenever they help, no need to ask.
- **Model rules (owner): read `docs/art/MODEL-RULES.md` before making or changing any model.** In short:
  1. No Play-Doh: every model is hand-built in Blender by script (never picture-to-3D as the final model).
  2. No shimmer: no two surfaces in the same place (join them or keep 1 cm apart).
  3. Building pieces in clean layers (backing, material, trim, decor), nothing poking out, calm colours.
  4. Roofs: Stonehold flat only; Shack and Hearthbrick sloped only; sloped roof pieces are thin and open underneath.
  5. Round doors only.
  Every rule has an automatic check; a model isn't done until they pass. When a rule changes, delete the old text that disagrees.
- Never copy names, characters, art, maps, or music from other games.
- The GitHub repo is public: never commit personal paths, usernames, keys, or Steam credentials.
- Use Voxel Tools and GodotSteam **GDExtension** editions with the official Godot build (never the module builds).
- Use the `godot` MCP to run the game and read errors; use GodotPrompter skills for Godot patterns.

## How the code is laid out
- `src/world/`: Cave Maker (seed → SDF + materials), World (Voxel Tools terrain, digging), Glow Placer/Field, terrain shader, `mat.gd` (materials + hardness).
- `src/net/game_authority.gd`: the referee. Every world change is `request_*` (approve) → `_do_*` (everyone applies). Keep it that way for co-op.
- `src/player/`: Dwarf (movement, camera, swing), placeholder model, lantern, controls, fx.
- `src/items/`: item list, inventory, drops. `src/ui/hud.gd`: everything on screen.
- `src/debug/autopilot.gd`: scripted play run with screenshots.
- Design docs for later steps: `docs/design/` (start with its README).
- Making or remaking creatures: follow `docs/art/CREATURE-STYLE.md` and `docs/art/MODEL-RULES.md`: hand-built in Blender by script (`tools/asset_forge/creature_kit.py`, `build_creatures.py`), matching the approved pictures in `assets/concepts/creatures/`. Never picture-to-3D.

## Play sessions (Windows PC)
- Every time the owner plays (desktop icon or Godot F5), `tools/recorder/` records it with OBS and makes a folder in
  `Videos\Dwarf Game Recordings\<date time>\`: `video.mp4`, `game-log.txt`, `session.json`, `feedback.txt` (what the owner typed),
  `snapshots\tMMSS.jpg`, and `report.md` (a background read-only Claude's analysis, per `tools/recorder/analysis_prompt.md`).
- **At the start of a chat on the PC, or when the owner says "check my last session":** list session folders that have no
  `reviewed.txt`, read each `report.md` (and look at the snapshots it cites), then tell the owner simply what was found.
- **Master feedback list: `FEEDBACK.md`.** Every piece of feedback the owner gives (in any chat) gets an item (F1, F2…).
  Fixed items are ~~crossed out~~ with date + what changed, **never deleted**. If the owner raises something that matches an
  existing item (open or fixed), bump its "Said" count instead of adding a new one. A fixed item that comes back gets 🔁 and
  goes in "Things that keep coming back" with what was tried each time; tell the owner and try a different approach.
  Keep the "Patterns" table current. Claude-found problems wait under "Claude noticed, waiting for your OK" until approved.
- The feedback pop-up is off (owner gives feedback in chat). `session_report.ps1 -AskFeedback` turns it back on.
- **Fixing rule (from the owner):** problems the owner *mentioned* in feedback get fixed. Problems Claude found that the owner
  did *not* mention: ask first, one yes/no each. After handling a session, write `reviewed.txt` in its folder (date + what was done).
- Runs Claude starts (from a terminal/script, or with `autopilot`/`netcheck`) are never recorded; only games a person starts.

## Token saver: RTK (added 2026-11-16, owner's request)
RTK shrinks terminal output before Claude reads it, so sessions use fewer tokens. It's set up on the Mac; the owner wants it on the Windows PC too.
- **At the start of the next chat on the Windows PC:** run `rtk --version`. If it's missing, install it with `winget install rtk-ai.rtk` (don't add auto-confirm flags), then run `rtk init -g --dry-run`, read what it will change, and only then run `rtk init -g`. Restart Claude Code afterwards and check it works with `rtk gain`.
- If the Windows version can't add its Claude Code hook, stop and tell the owner simply (no workarounds).
- Once it's working, tell the owner in one line, add a JOURNAL.md entry, and delete this "next chat" bullet.

## Keep test runs silent
- The owner is often using the PC while Claude tests. **Every game run Claude starts must be muted:** add
  `--audio-driver Dummy` before `--path`, e.g. `godot --audio-driver Dummy --path . -- autopilot seed=42`.

## Checking work
- Auto-checks: `tools/run_tests.sh` (Mac) / `tools\run_tests.bat` (Windows). Set `GODOT` to the Godot program. Add `only=name` to run one file. Every new system gets a `tests/test_*.gd`.
- Autopilot: `godot --path . -- autopilot seed=42 shots=<folder>`. Prints a report (load time, items dug, FPS) and saves screenshots. Look at the screenshots before saying something looks right.
- `godot --path . -- seed=1234` starts a specific cave.
