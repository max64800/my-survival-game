# Auto-recorder + play-session reports (Windows + OBS)

Every time the owner plays the Dwarf Game, it gets recorded and Claude writes a report.
No button to press.

- **Turn on:** double-click `Turn On Auto-Recording.bat` (once; it then starts with Windows).
- **Turn off:** double-click `Turn Off Auto-Recording.bat`.
- **Desktop icons:** `powershell -ExecutionPolicy Bypass -File tools\make_desktop_shortcuts.ps1`
  makes "Dwarf Game" (starts the game) and "Dwarf Game Sessions" (opens the sessions folder).

## What happens when you play

1. You start the game (desktop icon, Godot's F5, or an exported build).
2. `auto_record.ps1` notices the window (it checks every 2 seconds), starts OBS hidden in the tray
   in its own "Dwarf Game" setup, and records **only the game window and the game's sound**.
3. You close the game. Recording stops, OBS closes, and a session folder is made:
   `Videos\Dwarf Game Recordings\<date time>\`
4. `session_report.ps1` then:
   - pops up **"How was it?"**: type a few words or press Skip (it closes itself after 15 minutes),
   - takes up to 60 snapshots from the video (`snapshots\t0130.jpg` = 1 min 30 s in),
   - runs Claude **read-only** with `analysis_prompt.md` to write `report.md`,
   - shows a "report ready" bubble near the clock.

| File in a session folder | What it is |
|---|---|
| `video.mp4` | The recording |
| `game-log.txt` | Everything the game printed (errors, warnings) |
| `session.json` | Start/end time, minutes, git branch + commit played |
| `feedback.txt` | What you typed |
| `snapshots\` | Pictures from the video |
| `report.md` | Claude's analysis: what you said vs. what it saw, bugs with proof, FPS |
| `reviewed.txt` | Written by Claude once the session was gone through with you |

## Rules

- **Only people's games are recorded.** A game started from a terminal or script (that's how Claude
  runs it), or with `autopilot` / `netcheck` / `--headless`, is skipped.
- The background Claude can only **read**. Fixes happen in a normal chat: things you mentioned get fixed;
  things Claude noticed that you didn't mention, it asks about first.
- Sessions under 30 seconds with no feedback get no report (accidental starts).
- If OBS is already open, the recorder uses it and leaves it open.

**Log:** `%LOCALAPPDATA%\DwarfGameRecorder\recorder.log` (look here if something is missing).

## Testing

- `powershell -ExecutionPolicy Bypass -File auto_record.ps1 -Once -IncludeRobots` records one run (robots included), then quits.
- `powershell -STA -ExecutionPolicy Bypass -File session_report.ps1 -SessionDir "<folder>" [-NoPopup] [-NoClaude]` re-runs a report.
