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

## Checking work
- Auto-checks: `tools/run_tests.sh` (Mac) / `tools\run_tests.bat` (Windows). Set `GODOT` to the Godot program. Add `only=name` to run one file. Every new system gets a `tests/test_*.gd`.
- Autopilot: `godot --path . -- autopilot seed=42 shots=<folder>`. Prints a report (load time, items dug, FPS) and saves screenshots. Look at the screenshots before saying something looks right.
- `godot --path . -- seed=1234` starts a specific cave.
