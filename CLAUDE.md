# Project rules for Claude

Underground dwarf survival game (3D, up to 4-player Steam co-op), built in **Godot 4.7.2** with GDScript.
Full design: `docs/superpowers/specs/2026-11-14-dwarf-survival-game-design.md`.
Code layout, recorder details, how to run robots: `docs/CLAUDE-REFERENCE.md` (read only the part you need).

## The owner's two rules
1. **Journal everything.** After every work session, write an entry: what we did, every mistake and hurdle (including Claude's own),
   and how it was fixed. Write it as your **own new file** `journal-inbox/<YYYY-MM-DD-HHMM>-<topic>.md` (never edit `JOURNAL.md`
   directly, other chats share it), commit it with your work, then run `python3 tools/journal/merge_inbox.py`.
2. **5th-grade explanations.** The owner does not code. Explain everything simply: short sentences, everyday comparisons, define any tech word the first time.

## Working rules
- Build in the roadmap order. Each step must be playable before the next starts.
- Keep gameplay actions "co-op ready": request → host approves → everyone updates.
- Only use assets licensed for commercial use (prefer CC0). Log every asset in `CREDITS.md`.
- **Art style rule (owner):** every model (stations, gear, outfits, building pieces, materials) is made in the same style as the workbenches: hand-painted, chunky, no perfect boxes or circles, every part touching. Each building material gets its own design, not a reskin. Make ChatGPT pictures whenever they help, no need to ask.
- **Model rules (owner): read the needed section of `docs/art/MODEL-RULES.md` before making or changing any model.** In short:
  0. **Armor picture-to-3D test (owner OK Nov 26):** one exception to rule 1 below, for the copper armor only; read
     `docs/art/PICTURE-TO-3D-RULES.md` first. The owner decides afterwards whether rule 1 changes.
  1. No Play-Doh: every model is built in Blender by script: hand-built, or a free CC0 pack model reshaped and
     repainted to our style (never picture-to-3D as the final model).
  2. No shimmer: no two surfaces in the same place (join them or keep 1 cm apart).
  3. Building pieces in clean layers (backing, material, trim, decor), nothing poking out, calm colours.
  4. Roofs: Stonehold flat only; Shack and Hearthbrick sloped only; sloped roof pieces are thin and open underneath.
  5. Round doors only.
  Every rule has an automatic check; a model isn't done until they pass. When a rule changes, delete the old text that disagrees.
- **Ruin rules (owner, Nov 23):** before making or changing any ruin, blueprint or tower, read `docs/design/RUIN-RULES.md`
  (every lesson from every ruin so far, each with its check).
- **Placement rule (owner, Nov 17):** nothing the world grows (stone columns, rocks, crystals, roots, plants) may stand
  inside something built (ruins, towers, buildings, places) or on its paths and stairs. Every new placement keeps
  clear of them and gets an automatic test (like `test_columns_keep_out_of_the_tower`).
- Never copy names, characters, art, maps, or music from other games.
- The GitHub repo is public: never commit personal paths, usernames, keys, or Steam credentials.
- Use Voxel Tools and GodotSteam **GDExtension** editions with the official Godot build (never the module builds).
- Use the `godot` MCP to run the game and read errors; use GodotPrompter skills for Godot patterns.

## GodotPrompter
- Before building a **new** Godot system, check for a matching `godot-prompter:*` skill and follow it (also helpers/subagents).
  Not needed for changes inside a system the project already has.
- **Every game run Claude starts is muted:** `--audio-driver Dummy` before `--path` (the owner is often using the PC).
- **Test games are marked (owner, Nov 19):** add `claude=<what_you_test>` after `--` (e.g. `-- claude=waterfalls seed=42`).
  The game then shows an orange frame + "CLAUDE TEST" label and taskbar name, so the owner knows not to play it.
  Close every test game when you're done. Test worlds save to `user://claude_test_saves` (named "🤖 TEST…");
  delete that folder after testing (the game also deletes ones older than a day). Never touch `user://saves`.
- **New chat banner (owner, Nov 19):** when the owner should start a new chat (chat is getting long, or the task changed),
  make the **very first line** of the message `# 🛑 START A NEW CHAT 🛑`, the **second line** the model as a big
  heading (owner, Nov 21: "I nearly missed it"): `# 👉 FIRST TYPE: /model sonnet` (or opus; see "Saving tokens"),
  then one short line saying why. Repeat the same `# 👉 FIRST TYPE: /model …` heading right above the prompt block.
  Never write the model as plain or bold text, and never only at the end (Claude can't switch a chat's model itself;
  the owner types it before pasting). The status line also shows how full the chat is (yellow 80k, red 150k = NEW CHAT).
  **Always add a ready-to-paste prompt for the new chat** (owner, Nov 19) in one copyable code block: who the new
  Claude is, the task, which feedback numbers and files to start from, what is already done, and what the owner chose.
  Follow the **Handoff prompt recipe** in `docs/CLAUDE-REFERENCE.md` (short, exact `file:function` spots, next step first).

## Videos (Shorts about the game)
- Editing the dwarf Shorts: `video/README.md` (pipeline, owner's video rules in `video/rules/`, scripts in `video/scripts/`).

## Other chats share this to-do list (owner, Nov 23)
Several Claude chats work in this folder at once. Twice a list was wrong because another chat had already fixed items
(F806, F807, F808 were done while a to-do list still showed them as open).
- **Before you give a to-do list, pick an item, or start a fix:** `git pull`, then check what others did: `git log --oneline -40`,
  Grep the item's F-number in `git log --oneline -300`, `journal-inbox/`, `FEEDBACK.md` and `FEEDBACK-done.md`.
  Also look at other chats still running (ListAgents). If it was done, or someone is on it, say so and pick another.
- **Claim it when you start:** add a short line on the item in `FEEDBACK.md`: `🛠 in progress (<chat topic>, <date>)`.
  Commit that line right away so other chats see it.
- **Update it when you stop,** even if you didn't finish: what you did, what you tried that didn't work, what is left.
  Done = cross out and move to `FEEDBACK-done.md` (as in the Feedback rules). Remove the 🛠 line when you hand the item back.

## Feedback and play sessions
- **Play recordings (owner, Nov 20):** `Videos\Dwarf Game Recordings\` are the owner's videos for social media. Never count
  them or mention them at the start of a chat. Read a session's report and snapshots only when the owner says "check my last session".
- **Feedback lists:** `FEEDBACK.md` = open items, "Things that keep coming back", "Claude noticed…" and Patterns.
  `FEEDBACK-done.md` = every fixed item, unchanged, never deleted. New item: pull, then take the next free F-number.
  Before adding, **Grep both files by keyword** (never read them whole): a match → bump its "Said" count; a fixed item that
  comes back → 🔁, move it into "Things that keep coming back" with what was tried, tell the owner, try a different approach.
  When fixed: cross it out with date + what changed and move it to `FEEDBACK-done.md`. Keep the Patterns table current.
- **Play test while Claude tests (owner, Nov 22):** as soon as a change is in the game and only tests/commit remain, say so in a big heading `# 🎮 GO PLAY TEST THIS NOW 🎮` with exactly what to try and where, then "I'm still running tests". Don't wait for the full suite.
- **Fixing rule (owner):** problems the owner *mentioned* get fixed. Problems Claude found that the owner didn't mention:
  ask first (they wait under "Claude noticed, waiting for your OK").
- **Questions are multiple choice (owner, Nov 25):** every question to the owner goes through the AskUserQuestion
  tool (clickable choices, recommended one first), never as plain text in the message.

## Saving tokens (owner, Nov 16; token check Nov 21)
Nov 21 check: 60% of all tokens = Claude re-reading the chat on every step, so **short chats matter most**.
- **Short chats:** at 150k tokens (red status line) finish the current step, then give the new chat banner + prompt.
  Also start a new chat for every new task. Chats are capped at 200k (1M is off in `.claude/settings.json`).
  Do big reading in helpers so the main chat stays small.
- **Read only the part you need (owner, Nov 21):** everything opened stays in the chat and is re-read every step.
  - **Code map first:** `docs/CODE-MAP.md` lists every file and function with line numbers (rebuilt at every chat start).
    Grep it (never read it whole), then read ~60 lines around that line.
  - **Never read a whole code file over 300 lines.** Grep for the name, then read only that part (offset/limit).
  - **"Where does X happen?" hunts go to a Haiku helper** that answers with `file:line` + one line each, not file dumps.
- **Model per task (owner, Nov 21).** Default is Opus. Pick the model for every new-chat prompt:
  - **Opusplan** (`/model opusplan`: Opus plans, Sonnet does the work): jobs that start with design, then a lot of routine work.
  - **Opus:** new systems, design/planning, new 3D models and art rounds, grand ruins, a bug that one try didn't fix.
  - **Sonnet:** following a written plan, clear feedback fixes, small tweaks, tests, placing pieces, docs/journal/feedback
    upkeep, page tweaks, video editing. If Sonnet fails twice on something, say so and suggest `/model opus`.
  - **Helpers are always Haiku** (forced in settings). Give them narrow search/read jobs.
- **No marketing, SEO, blog or other non-game skills in this project** (owner, Nov 21); they're switched off in
  `.claude/settings.json`, along with the claude.ai connectors (Canva, Drive, Docs). Never turn them back on here.
  The Shorts' own writing skills in `.claude/skills/` stay.
- **Keep the 1-hour cache** (`promptCacheTtl: 1h`): the owner often steps away to play-test, and a 5-minute cache
  would reload the whole chat after every break.
- RTK shrinks terminal output (installed on the Mac and the PC). If a result is empty or garbled, re-run with `rtk bypass <cmd>`.
- Default thinking is medium, also for big jobs (owner, Nov 16: "just try with medium, you pick ultrathink too often").
  Only suggest ultrathink for a problem medium has already failed on twice. Helpers use effort low.
- Never read big files whole. `JOURNAL.md`: append new entries at the end without reading it (Grep or the last ~40 lines for
  format). Design specs, `MODEL-RULES.md`, `CREATURE-STYLE.md`: Grep the heading, read only that section.
- Pictures cost a lot: look at the fewest screenshots that answer the question (usually 1–3), use crops/zoom, not full sets.
- Run single tests (`only=name`) while fixing; run the suite once at the end. Always through `tools/run_tests.sh`
  (prints only FAILs + summary). A plain run is **quick** (owner, Nov 26): it skips checks that took 10 s+ last time
  (world-growing, ruin rebuilds). Add `full=1` only after ruin, cave or world-making work. Every other game/Godot/Blender run goes through `python3 tools/quiet_run.py <command>`
  (drops shutdown chatter, folds repeats). `QUIET=0` / `verbose=1` only when the short output isn't enough.
- Blender/model work: at most 2 render-review rounds before asking the owner.
