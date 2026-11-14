# Auto-recorder (Windows + OBS)

Records the Dwarf Game with OBS every time the game window opens
(Godot's F5, or an exported build). No button to press.

- **Turn on:** double-click `Turn On Auto-Recording.bat` (once; it then starts with Windows).
- **Turn off:** double-click `Turn Off Auto-Recording.bat`.
- **Videos:** `Videos\Dwarf Game Recordings`, named by date and time (e.g. `2026-11-14 21-30-05.mp4`).
- **What's recorded:** only the game window and the game's own sound (no mic, no Discord, no music).
- **Not recorded:** Claude's robot runs (autopilot, netcheck, headless tests).
- **Log:** `%LOCALAPPDATA%\DwarfGameRecorder\recorder.log` (look here if a video is missing).

How it works: `auto_record.ps1` checks for the game window every 2 seconds. When it appears,
it starts OBS hidden in the tray, already using a separate OBS setup called "Dwarf Game"
(your own OBS scenes aren't touched), and tells OBS to record through OBS's built-in
WebSocket remote control. The WebSocket password is read from OBS's own settings on the PC.
When the game closes, it stops recording, closes OBS, and puts OBS back on your normal setup.
If OBS was already open, it uses that OBS and leaves it open.

Testing: `powershell -ExecutionPolicy Bypass -File auto_record.ps1 -Once -IncludeRobots`
records one run (robots included), then quits.
