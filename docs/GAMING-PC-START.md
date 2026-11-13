# Starting on the gaming PC

A checklist for the first session on the gaming PC after the MacBook night shift (Nov 14, 2026).

## 1. Get the new work (2 minutes)

Open a terminal in the game folder and type:

```
git status
git pull --ff-only
```

`git status` should say "nothing to commit". If it lists changed files, **stop and tell Claude** before pulling.

## 2. Open the game in Godot

1. Start Godot 4.7.2 (the official one).
2. Import / open the game folder (the one with `project.godot`).
3. The first time, Godot spends a minute "importing". That's normal.
4. Press **F5** (Play). The main scene is already set.

If Godot says the Voxel add-on is missing: the Windows file is
`addons/zylann.voxel/bin/libvoxel.windows.editor.x86_64.dll`. Tell Claude.

## 3. Play for 10 minutes (Step 1 test)

| Key | What it does |
|---|---|
| W A S D | walk |
| Shift | run |
| Space | jump |
| Mouse | look around |
| Left click (hold) | swing the pickaxe |
| 1-8 / mouse wheel | pick a hotbar slot |
| R | refill the lantern with a glow crystal |
| Tab | open the bag |
| F3 | show/hide frame rate |
| F12 | screenshot |
| Esc | pause |

Things to try:
- Dig down into the moss (1 hit), then into stone (3 hits), then copper (orange, 5 hits).
- Walk until you find the purple-veined border rock at the edge. It should refuse to break.
- Break a blue crystal on a wall, then press **R**.
- Find the second big cavern (follow tunnels, or dig straight there).

Then tell Claude:
- Does digging feel good? Too slow, too fast?
- Too dark? Too bright?
- The **FPS** number top-right: what does it usually show? (60+ is great.)
- Anything that looked broken.

## 4. Tests Claude can run on the PC

```
set GODOT=C:\path\to\Godot_v4.7.2-stable_win64_console.exe
tools\run_tests.bat
```

The autopilot plays by itself, takes screenshots, and prints a report:

```
"%GODOT%" --path . -- autopilot seed=42 shots=C:\temp\shots
```

On the MacBook (M3), the autopilot report said: loads in about 3–8 seconds, about 50 FPS at 1600×900.

## 5. Still to do in Step 1 on the PC

- [ ] Play test + feedback (above).
- [ ] Pick the art pack: Claude tries 2 free CC0 packs and shows screenshots (the dwarf is shapes for now).
- [ ] Check the frame rate on the PC and tune lights / view distance.
- [ ] Add sounds (CC0): pickaxe hits, rock breaking, pickup pop, lantern refill.
