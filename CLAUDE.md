# Project rules for Claude

Underground dwarf survival game (3D, up to 4-player Steam co-op), built in **Godot 4.7.2** with GDScript.
Full design: `docs/superpowers/specs/2026-11-14-dwarf-survival-game-design.md`.
Code layout, recorder details, how to run robots: `docs/CLAUDE-REFERENCE.md` (read only the part you need).

## The owner's two rules
1. **Journal everything.** After every work session, add an entry to `JOURNAL.md`: what we did, every mistake and hurdle (including Claude's own), and how it was fixed.
2. **5th-grade explanations.** The owner does not code. Explain everything simply: short sentences, everyday comparisons, define any tech word the first time.

## Working rules
- Build in the roadmap order. Each step must be playable before the next starts.
- Keep gameplay actions "co-op ready": request → host approves → everyone updates.
- Only use assets licensed for commercial use (prefer CC0). Log every asset in `CREDITS.md`.
- **Art style rule (owner):** every model (stations, gear, outfits, building pieces, materials) is made in the same style as the workbenches: hand-painted, chunky, no perfect boxes or circles, every part touching. Each building material gets its own design, not a reskin. Make ChatGPT pictures whenever they help, no need to ask.
- **Model rules (owner): read the needed section of `docs/art/MODEL-RULES.md` before making or changing any model.** In short:
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
- **Every game run Claude starts is muted:** `--audio-driver Dummy` before `--path` (the owner is often using the PC).

## Feedback and play sessions
- **Start of a chat on the PC:** only count the session folders in `Videos\Dwarf Game Recordings\` without `reviewed.txt`
  and tell the owner the number in one line. Read reports and snapshots only when the owner says "check my last session".
- **Feedback lists:** `FEEDBACK.md` = open items, "Things that keep coming back", "Claude noticed…" and Patterns.
  `FEEDBACK-done.md` = every fixed item, unchanged, never deleted. New item: pull, then take the next free F-number.
  Before adding, **Grep both files by keyword** (never read them whole): a match → bump its "Said" count; a fixed item that
  comes back → 🔁, move it into "Things that keep coming back" with what was tried, tell the owner, try a different approach.
  When fixed: cross it out with date + what changed and move it to `FEEDBACK-done.md`. Keep the Patterns table current.
- **Fixing rule (owner):** problems the owner *mentioned* get fixed. Problems Claude found that the owner didn't mention:
  ask first, one yes/no each (they wait under "Claude noticed, waiting for your OK").

## Saving tokens (owner, Nov 16)
- RTK shrinks terminal output (installed on the Mac and the PC). If a result is empty or garbled, re-run with `rtk bypass <cmd>`.
- Default thinking is medium, also for big jobs (owner, Nov 16: "just try with medium, you pick ultrathink too often").
  Only suggest ultrathink for a problem medium has already failed on twice. Helpers (Agent tool) use effort low for
  searching/reading, medium for normal work.
- Never read big files whole. `JOURNAL.md`: append new entries at the end without reading it (Grep or the last ~40 lines for
  format). Design specs, `MODEL-RULES.md`, `CREATURE-STYLE.md`: Grep the heading, read only that section.
- Pictures cost a lot: look at the fewest screenshots that answer the question (usually 1–3), use crops/zoom, not full sets.
- Run single tests (`only=name`) while fixing; run the full suite once at the end. Show only the failing lines of output.
- Blender/model work: at most 2 render-review rounds before asking the owner.
- One chat per task: start a new chat (or /compact) when switching tasks.
