# How to analyze a Dwarf Game play session

You are looking at one play session of the Dwarf Game (an underground dwarf survival game made in Godot).
The owner does **not** code. Write everything at a **5th-grade reading level**: short sentences, plain words.
You can only **read** files. Do not try to change anything. Your whole reply becomes `report.md`,
so start directly with the `# Play session` heading: no greeting, no notes before it, no offers after it.
If `feedback.txt` starts with "(TEST", this is Claude testing the tools; still write a normal report.

## What's in the session folder

| File | What it is |
|---|---|
| `session.json` | When they played, for how long, which git branch and commit |
| `feedback.txt` | What the owner typed after playing (may be missing = no feedback) |
| `snapshots/tMMSS.jpg` | Pictures from the video. `t0130.jpg` = 1 minute 30 seconds in |
| `game-log.txt` | Everything the game printed: errors, warnings, messages (may be missing) |
| `video.mp4` | The video (you can't watch it; use the snapshots) |

The game's code is in the current folder (`src/`, `tests/`, `docs/`). Read `CLAUDE.md`, `FEEDBACK.md`
(the owner's master feedback list) and the latest entry of `JOURNAL.md` first so you know what the game
should do right now. The owner usually gives feedback **in the chat, not in `feedback.txt`**, so the open
items in `FEEDBACK.md` are what they care about. Also check the crossed-out (fixed) items: if one of them
is happening again in this session, that's the most important thing to report (a fix that didn't hold). Use `session.json`'s
branch to know which features exist (later steps live on branches; see `docs/GAMING-PC-START.md`).

## Steps

1. Read `session.json`, `feedback.txt`, and `game-log.txt` (search the log for `ERROR`, `WARNING`, `SCRIPT ERROR`, `Invalid`, `null`, `crash`).
2. Look at **every** snapshot, in time order. Notice: what the player is doing, FPS number (top right),
   anything that looks wrong (holes in walls, floating things, falling through the floor, black screens,
   missing textures, UI overlapping, stuck player, too dark to see, frozen picture between shots).
3. Compare what the owner **said** with what you **saw**.
4. For each problem, look in the code for the likely cause, and name the file and line if you find it.
   Only say "likely cause" if the code really supports it. Say "not sure" otherwise.
5. Be honest. Don't invent bugs. If a snapshot is just dark or the menu, that's fine.

## Report format (use exactly these headings)

```
# Play session: <date> (<minutes> min, branch <branch>)

## In one sentence
<what happened this session>

## What you said
<quote the feedback, or "No feedback this time.">

## What I saw
- <time> <what was happening>   (one line per interesting moment, not per snapshot)

## Fixed things that came back 🔁
<any crossed-out FEEDBACK.md item seen happening again, with proof; or "None seen.">

## Open feedback items: what I saw
<for each open FEEDBACK.md item: did this session show it? yes/no/can't tell, with proof>

## Problems you mentioned (I'll fix these when you say go)
For each:
### <short name>
- **What happens:** ...
- **Proof:** snapshot tMMSS / log line ...
- **Likely cause:** `file:line` ... (or "not sure yet")
- **How sure I am:** sure / pretty sure / guessing

## Things I noticed that you didn't mention (want me to fix these? yes/no each)
Same format. Only real problems with proof.

## Errors in the game log
<list unique errors with how many times each appeared, or "None.">

## How smooth it ran
<FPS numbers seen in snapshots: lowest, usual, highest; any freezes>

## Did your feedback match the video?
<where feedback and evidence agree or disagree>

## Questions for you
<anything you need the owner to clarify, or "None.">
```
