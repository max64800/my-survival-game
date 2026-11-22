# Working faster and safer on a Godot 4.x game with an AI coding agent

Research date: 2026-11-22. Scope: practices for a Godot 4.7 GDScript co-op survival game built mostly by Claude Code. Already covered in `docs/research/coop-and-saves.md` (not re-researched here): host leaving, world save ownership, mid-game join, lag hiding, desync, Steam relay/NAT, bandwidth, atomic saves, backups, save versioning, Steam Cloud, checksums, autosave timing. That note's headings are C1-C9 and D1-D9. What it does NOT cover, and what this note adds: MCP tools, testing tools and CI, scene-file (.tscn) pitfalls, architecture, export and Steam release checks, and how Claude Code works best.

Note on sources: search results were used as summaries. Where a finding relies on a single blog or a search summary, that is said below. No page was fetched in full.

## 1. AI agents and Godot: MCP servers and tools

### Takeaway
Several open-source Godot MCP servers exist. They differ mainly in whether they can see the editor, the running game, or both. Before relying on one for visual checks, confirm what its screenshot tool actually captures.

### Cited Findings
- PurpleJelly's Godot-MCP (itch.io) has an editor plugin for live scene-tree edits, screenshots, debugger and profiler tools; file-based tools work without the plugin; it advertises 84 tools — [PurpleJelly Godot-MCP](https://purplejelly.itch.io/godot-mcp)
- yanhuifair/Godot-MCP lists the most detailed debugger tools (step, continue, stack traces, local variables) and reads both the editor scene tree and the running game's tree — [yanhuifair/Godot-MCP](https://github.com/yanhuifair/Godot-MCP)
- fernforestgames/mcp-server-godot-editor: its screenshot tool captures the running game, not the editor viewport; it talks to the game process through Godot's EngineDebugger — [fernforestgames/mcp-server-godot-editor](https://github.com/fernforestgames/mcp-server-godot-editor)
- letsagents/godot-mcp reports runtime errors, scene tree, node properties and screenshots, built on Godot's built-in debug protocol with one EditorPlugin and no project.godot edits — [letsagents/godot-mcp](https://github.com/letsagents/godot-mcp)
- satelliteoflove/godot-mcp offers scene editing, input injection, deterministic playtesting and live game state via a WebSocket addon — [satelliteoflove/godot-mcp](https://github.com/satelliteoflove/godot-mcp)
- GDAI MCP claims Godot 4.2+ compatibility and includes game and editor screenshots plus debugger output; Godot Peek MCP covers editor viewports or the running game, saving screenshots to /tmp — [GDAI MCP](https://gdaimcp.com/), [Godot Peek MCP (aibase)](https://mcp.aibase.com/server/1639703120785449603)
- The search summary did not verify maintenance status, code quality or licences of any of these servers.

### Inferences
- Action: when choosing or keeping our `godot` MCP, check its README for "editor viewport" vs "running game" screenshots. For 3D page or scene checks we need the one that matches what the owner sees.
- Action: keep the debugger and error-reading tools as the main way Claude sees runtime errors (the project already relies on this). Treat MCP screenshots as a supplement, not a test.
- Action: the MCP is only a window. Tests still need to be headless and scripted (section 2), so an agent's "it looks fine" is never the only check.

### Gaps
- No source compared MCP servers for reliability, speed or safety on Windows. Nothing found on known failure modes of MCP game tools (for example, stuck editor sessions or stale scene trees).

## 2. Automated testing and CI in Godot 4

### Takeaway
gdUnit4 is the framework with the most current CI support found (official GitHub Action, headless mode, JUnit/HTML reports). GUT was not found in any search, so no evidence either way. Our custom `tests/run_tests.gd` is a valid choice if it keeps clear exit codes and per-test output.

### Cited Findings
- gdUnit4 v7 runs tests headless by default. The official action gained a `headless` input in v1.4.0 that skips the virtual display it used to always start. Per the action docs, v6 refused headless runs with exit code 103 unless `--ignoreHeadlessMode` was passed — [gdUnit4-action](https://github.com/MikeSchulze/gdUnit4-action), [action.yml](https://github.com/godot-gdunit-labs/gdUnit4-action/blob/master/action.yml), [v1.4.0 release](https://github.com/godot-gdunit-labs/gdUnit4-action/releases/tag/v1.4.0)
- gdUnit4 master (v7.0.0) is listed as compatible with Godot 4.7 and 4.8 dev builds — [gdUnit4 README](https://github.com/godot-gdunit-labs/gdUnit4/blob/master/README.md?plain=1)
- A Rubbley project issue (one team's opinion, not an authoritative comparison) recommends gdUnit4 for agent-built work, citing JUnit/HTML reports, clear exit codes and GDScript + C# support. It pairs gdUnit4 with plain `godot --headless` in GitHub Actions and suggests `xvfb-run` for input-dependent tests — [Rubbley issue #31](https://github.com/snackpackgames/Rubbley/issues/31)
- Godot 4 headless CI pattern (community sources): run `godot --headless --export ...`; one Android workflow generates the `.godot/` asset cache first, because headless runs can crash without it ("pre-heat") — [godot-ci Docker setup](https://github.com/nicolanore/godot-ci), [Godot Android CI article](https://thedigitalspell.com/godot-github-actions-2/)
- For CI, `solarlabyrinth/action-setup-godot` installs the Godot binary and export templates on Ubuntu runners (Godot 4+ only) — [action-setup-godot](https://github.com/marketplace/actions/action-setup-godot)
- Export templates on Linux are expected at `~/.local/share/godot/export_templates/<version>.stable`; CI must place them there — [abarichello/godot-ci](https://github.com/abarichello/godot-ci) (note: this is a Godot 4.4-era guide, check the version)
- Some CI templates say `export_presets.cfg` must not be in `.gitignore` and preset names must match exactly — [abarichello/godot-ci](https://github.com/abarichello/godot-ci)

### Inferences
- Action: keep `tests/run_tests.gd` for now (it already prints only FAILs and a summary). Try gdUnit4 on one or two test files as a trial before deciding; do not migrate everything at once.
- Action: add one GitHub Actions workflow that: installs Godot 4.7.2 headless, runs the import step once (to build `.godot/`), then runs the test runner and fails the job on any FAIL. This catches breakage from several Claude sessions pushing at once.
- Action: commit `export_presets.cfg` (it is needed for CI exports) and make sure the test runner returns a non-zero exit code on failure. Check this once by making a test fail on purpose.
- Action: `xvfb-run` is only needed for tests that read input or draw. Keep pure-logic tests headless.
- Action (for the owner's "bot playtesting"): a headless run with a fixed seed is the base for deterministic tests. Replays and bot playtests were not researched (see Gaps).

### Gaps
- No GUT evidence found (no docs, no CI setup). Cannot compare GUT vs gdUnit4 on evidence.
- Screenshot/visual regression testing in Godot: not researched.
- Bot playtesting, input replay, and deterministic seed patterns in Godot: not researched.
- Test runtime budget for a large voxel world: not researched.

## 3. Scene files (.tscn) and UIDs: traps for an AI agent

### Takeaway
A `.tscn` scene file is plain text, but Godot writes random-looking IDs (UIDs) into it. Two branches that touch the same scene conflict on those IDs. The safest pattern is to commit `.uid` files, resolve conflicts by taking one side, and let Godot re-check the scene by opening the project.

### Cited Findings
- Godot gives each resource in a scene a random ID; two branches editing the same scene can end up with different IDs. Community project page calls these "Evil Twin Conflicts" when `.uid`/`.import` metadata is not committed — [GitHub Discussion #11574](https://github.com/godotengine/godot-proposals/discussions/11574)
- Godot's 4.4 UID design: a central UID registry would conflict constantly in version control, so UIDs live beside each file or inside `.tscn`/`.tres`; conflicts are meant to be resolved by taking one file — [UID changes coming to Godot 4.4](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/)
- Godot's 4.4 dev notes say `.uid` files should be committed, like `.import` files — [MEXC repost of release notes](https://www.mexc.com/news/120179) (secondary source)
- A community guide suggests `.gitattributes` with `*.uid merge=ours` (or `theirs`), then fixing `uid://` references to match the kept side — [Bugnet guide](https://bugnet.io/blog/fix-godot-resource-uid-conflict-after-merge) (secondary, unverified)
- Duplicate UIDs: a Godot bug report (#102490) describes removing the `uid=` attribute from the `gd_scene` header and clearing `.godot/` as a user workaround; no official fix — [godot issue #102490](https://github.com/godotengine/godot/issues/102490)
- `gdmerge` is a third-party semantic 3-way merge driver for `.tscn`/`.tres`; maturity and safety not verified — [gdmerge](https://github.com/hyprtuna/gdmerge)

### Inferences
- Action: never hand-edit `.tscn` files to fix a UID. After any merge conflict in a `.tscn`/`.tres`, keep one side, then open the project in Godot once and save, so Godot rewrites the references.
- Action: check that every `.uid` file is committed. Add this to the commit checklist for Claude sessions.
- Action: the `.gitattributes` merge rule is a possible time-saver, but it is a secondary source. Test it on a scratch branch before adding it to the repo.
- Action: because several Claude sessions share one folder, ask each session to commit only its own files (the repo's existing rule). This reduces the chance of two sessions editing the same scene.

### Gaps
- No official Godot merge tool found. The duplicate-UID workaround comes from one bug report, not from Godot.

## 4. Architecture that stays maintainable

### Takeaway
Not researched in this pass. No source was gathered on autoloads, resources, scene composition or file-size limits. The only evidence here is the static-typing finding in section 8.

### Cited Findings
- None gathered for this section.

### Inferences
- The project already has a rule to read code in parts (code map, offset/limit). That is a workaround for huge files, not a design fix. A separate architecture pass is needed before splitting thousand-line scripts.

### Gaps
- Scene composition vs. autoload use, resource-based data (`Resource` subclasses for items and recipes), signal/event-bus patterns, and how to split very large scripts: not researched. Recommend a separate search with the `godot-prompter` architecture and event-bus skills as the starting point (those skills exist in this environment; they were not read here).

## 5. Co-op networking in Godot 4 (beyond the saves/desync notes)

### Takeaway
Godot's official recipe for co-op is MultiplayerSpawner for "this node exists on every peer" and MultiplayerSynchronizer for "this value keeps changing". With GodotSteam, the lobby owner is the server (peer ID 1) and is the default authority for all nodes. The Steam path needs Steam IDs, not IP addresses.

### Cited Findings
- Spawner handles creating and removing nodes on all peers; synchronizer handles ongoing property updates such as position and health. Community tutorials agree; the official docs were not reached in search — [Godot 4 Multiplayer Tutorial (2026)](https://generalistprogrammer.com/tutorials/godot-4-multiplayer-tutorial), [uhiyama-lab notes](https://uhiyama-lab.com/en/notes/godot/multiplayer-spawner-synchronizer/)
- Spawning should originate on the authority peer; the spawner replicates only nodes from its authority's tree under `spawn_path`; one spawner per container is advised — [Godot Forum thread](https://forum.godotengine.org/t/leveraging-godots-multiplayer-spawner-synchroniser-appropriately/69058), [Bugnet fix article](https://bugnet.io/blog/fix-godot-multiplayer-spawner-replication-out-of-sync)
- Short-lived objects (bullets) may not need a synchronizer: set initial data in the spawn function and let each client move the object by its velocity — [Andrew Davis, Godot Multiplayer tips](https://jonandrewdavis.com/drafts/draft-of-godot-network-tips/)
- Replication can be set per property (position sent often, health only on change) — [uhiyama-lab notes](https://uhiyama-lab.com/en/notes/godot/multiplayer-spawner-synchronizer/)
- Object decoding is off by default in the spawner/synchronizer path; dictionaries and complex data need care — [Godot Forum thread](https://forum.godotengine.org/t/leveraging-godots-multiplayer-spawner-synchroniser-appropriately/69058)
- With SteamMultiplayerPeer, connections use Steam IDs; the player who creates the lobby is the server and default authority — [GodotSteam MultiplayerPeer tutorial](https://godotsteam.com/tutorials/multiplayer_peer/); the tutorial itself says it is only a starting point
- A third-party write-up reports the plugin records the peer ID a client sends without checking it. Single unverified source; check the GodotSteam issue tracker before trusting peer IDs for authority — [Axeghost write-up](https://axeghost.offprint.app/a/3mzhxoqpnh423-any-networked-co-player-can-act-as-the-server-in-a-godotsteam-game) (secondary)
- Alternative Steam transport: expressobits/steam-multiplayer-peer (Steam Sockets, GDExtension). Its author has paused development and suggests GodotSteam — [expressobits](https://github.com/expressobits/steam-multiplayer-peer)

### Inferences
- Action: our host-authoritative rule matches Godot's default. Write a rule: the server checks every client request (who is asking, is the action allowed) before anything changes. Never trust a peer ID or position sent by a client without a check.
- Action: use one MultiplayerSpawner per group (dropped items, dug stations, creatures). Give spawned objects their start data in the spawn function. Use a synchronizer only for values that really change over time.
- Action: keep big RPC payloads small and typed. Do not send raw dictionaries unless the decode setting is checked on both sides.
- Action: keep a small local test setup (two game windows on one PC, or host + client both running with `claude=` marks) so each co-op change is tested before the owner plays it.

### Gaps
- Official Godot docs for MultiplayerSpawner/Synchronizer were not reached in search; all evidence above is from community pages.
- GodotSteam official docs (GodotSteam-Docs repo) were not fetched; lobby API details are unverified here.
- Steam Networking bandwidth limits and relay behaviour are covered by `coop-and-saves.md` (C7, C8), not repeated.

## 6. Export, Steam release and player crash logs

### Takeaway
A build can work on the developer's PC and fail on a clean machine. Test the exported build on a machine without Godot installed, and run export and upload by hand before automating them.

### Cited Findings
- Godot 4 Steam postmortem (one developer, port from itch.io): the build ran on their machine but failed on a clean Windows VM; they recommend testing on a machine without Godot; they ran the export and Steam upload script by hand before automating — [I Shipped a Godot Game to Steam](https://gamineai.com/blog/i-shipped-a-godot-game-to-steam-full-postmortem) (single blog, not verified)
- Headless export in CI: `godot --headless --export "<preset>" <path>`; export templates must match the Godot version; preset names must match the CI script — [godot-ci Docker setup](https://github.com/nicolanore/godot-ci), [abarichello/godot-ci](https://github.com/abarichello/godot-ci)
- Godot 4.7 stable release: June 2026; 4.7.2 is the latest patch listed. Breaking changes flagged in the 4.7 beta notes: SoftBody3D default mass changed to 1 kg under Jolt, and Area3D reports overlaps with SoftBody3D under Jolt — [Godot 4.7 release page](https://godotengine.org/releases/4.7/), [Godot 4.7 beta 1 snapshot](https://godotengine.org/article/dev-snapshot-godot-4-7-beta-1/), [Godot 4.7 summary (godotlearning)](https://godotlearning.com/blog/godot-4-7-whats-new)
- Godot 4.7 also adds device IDs to keyboard/mouse/joypad input events, so code can tell them apart — [Godot 4.7 summary (godotawesome)](https://godotawesome.com/godot-4-7-features/)

### Inferences
- Action: before the first Steam build, write a short release checklist: export via command line, copy to a clean Windows machine (or VM) with no Godot and no dev tools, start a host and a client, and confirm save and join work.
- Action: if the game uses soft bodies or Area3D overlaps, re-check after moving to 4.7 (the breaking notes above). Confirm whether the project uses them before acting.
- Action: device IDs in 4.7 can help the Steam Deck / controller work later; no action yet.

### Gaps
- Steam Deck verification steps (Valve's review process, Deck-specific controls): not researched.
- Crash log collection from players (Steam error reporting, Sentry or similar, Godot's own crash output): not researched.
- Steam depots and build branch setup: not researched.
- Godot export template download and install steps for 4.7 specifically: not verified (the templates found were for 4.4 or older).

## 7. Claude Code working habits for this project

### Takeaway
CLAUDE.md is guidance, not enforcement. Hard rules (no personal paths in commits, no test-game left running) should be enforced by a hook or permission, not only by text. Subagents start with empty context, so each brief must carry the rules it needs.

### Cited Findings
- Official guidance: CLAUDE.md is guidance Claude can decide not to apply; hard constraints belong in permissions or hooks — [Claude Code best practices](https://code.claude.com/docs/en/best-practices), [SmartScope guide](https://smartscope.blog/en/generative-ai/claude/claude-code-best-practices-advanced-2026/)
- Community guides suggest a root CLAUDE.md of roughly 100–200 lines; subdirectory CLAUDE.md files load only when Claude works there — [rosmur best practices](https://rosmur.github.io/claudecode-best-practices/), [Steering Claude Code](https://claude.com/resources/articles/steering-claude-code-skills-hooks-rules-subagents-and-more) (the 2,000-token figure is from a community guide, not an official limit)
- Each subagent has its own context window and does not see the conversation or files already read; restate key constraints in its prompt — [crystl.dev subagents](https://crystl.dev/blog/claude-code-subagents-best-practices/)
- Fan-out does not save context unless the returned output is limited to a defined shape — [crystl.dev](https://crystl.dev/blog/claude-code-subagents-best-practices/), [Claude Code best practices](https://code.claude.com/docs/en/best-practices)
- `/context` shows what fills the window; a progress file plus `/clear` is a community workflow for long tasks — [vld-bc.com](https://vld-bc.com/blog/cli-agents-part2-claude-code-best-practices), [rosmur](https://rosmur.github.io/claudecode-best-practices/)

### Inferences
- Action: move the hard rules into a hook: for example, a pre-commit check that rejects personal paths, usernames, and `.env`-like files; and a check that no test game (`claude=` marker) is left running at session end.
- Action: keep the project CLAUDE.md within the size the owner already uses; split game-area rules into subfolder CLAUDE.md files.
- Action: for helper briefs, always list the exact files, the single question, and the return shape (for example `file:line` plus one line each).

### Gaps
- No measured numbers for how much a hook or subfolder file saves. Blog figures (for example "93% savings") were not verified and are not used here.

## 8. Static typing and GDScript speed

### Takeaway
Typed GDScript is the documented default: the Godot docs say it can speed up code, and typed code catches errors earlier. Speed gains are mixed in independent tests, so measure any hot loop before and after typing it.

### Cited Findings
- Godot 4.2 docs: typed GDScript uses optimized opcodes when types are known at compile time; prefer typed global-scope methods — [Static typing in GDScript (stable docs)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html), [godot-docs 4.2 source](https://github.com/godotengine/godot-docs/blob/4.2/tutorials/scripting/gdscript/static_typing.rst)
- A University of Twente bachelor thesis found static-typing effects vary, with significant slowdowns in some edge cases (inner-typed declarations) — [Twente thesis (PDF)](https://essay.utwente.nl/107857/1/Goryachkin_BA_EEMCS.pdf)
- A DEV Community article claims 28–59% gains on hot paths but cites no verifiable source — [DEV Community](https://dev.to/ziva/static-typing-in-gdscript-the-30-minutes-that-saved-me-30-hours-1m8k) (not used as evidence)

### Inferences
- Action: require static types on all new function signatures and variables (catches AI-written mistakes early; the editor warns on type errors). Do not rewrite old working code just for speed.
- Action: for hot per-frame code (voxel meshing, creatures), measure with the Godot profiler before and after typing.

### Gaps
- No reliable benchmark for our kind of code. The "28–59%" figure is unverified.

## 9. Postmortems and shipped-game lessons

### Takeaway
Searches did not reach first-hand Brotato, Dome Keeper, Cassette Beasts, Halls of Torment or Road to Vostok postmortems. The only useful Godot postmortem found is a single Steam-release blog, summarised in section 6.

### Cited Findings
- Dome Keeper started as a Ludum Dare 48 jam entry and was later rebuilt in Godot for a Steam release — [Dome Keeper (Wikipedia)](https://en.wikipedia.org/wiki/Dome_Keeper) (summary-level only)
- Brotato and Dome Keeper are cited as large Godot Steam titles; review figures come from an SEO listicle and are not verified — [Games Made with Godot (2026)](https://godotawesome.com/games-made-with-godot/)

### Inferences
- Action: search again for the developer talks or blog postmortems (for example GDC or the studios' own blogs) if the owner wants shipped-game lessons. Not done here.

### Gaps
- No first-hand postmortems from Brotato, Dome Keeper, Cassette Beasts, Halls of Torment or Road to Vostok were retrieved.

## Top actions from this note (ordered by value)
1. Add a headless CI workflow: import, run tests, fail on FAIL, commit `export_presets.cfg` and all `.uid` files.
2. Write a "clean machine" Steam release checklist before the first Steam build.
3. Put the hard rules (no personal paths, `.env` files, test games left running) into a hook.
4. Trial gdUnit4 on one or two test files; keep the custom runner until the trial is judged.
5. Use the "resolve `.tscn` conflicts by taking one side, then open in Godot" rule and never hand-edit UIDs.
6. Co-op: one spawner per group, sync only what changes, server checks every client request.
7. Check the MCP's screenshot source (editor viewport vs game) before using it for visual checks.
8. Separate research needed: architecture (autoloads, resources, script splitting), bot playtesting and replays, screenshot regression, Steam Deck verification, crash logs, and official Godot/GodotSteam docs.
