## Nov 22, 2026: the skeleton miners stop looking like toys (F616)

**What the owner said:** the skeletons looked chunky and blocky ("Roblox / bad Minecraft") and didn't match our
hand-built props and buildings. Keep the dark colours and black eyes. Wanted a drastic change.

**What we did (5 rounds on a 3D page, then into the game):**
- New `slim()` step in `tools/asset_forge/builds/kaykit_miners.py`. It squeezes the KayKit body toward its bones:
  thin arm and leg bones (thinnest in the middle, knobby at the joints), small fists, flat narrow boots, a slimmer belt
  and body. The bones themselves don't move, so every pack animation still fits.
- Smaller heads per creature (`head_k`): Tunnel Rat 0.8, Lost Miner 0.82, Foreman 0.86.
- A vase body (`WAIST`): shoulders stay, the waist gets very thin, the hips widen again.
- Cloaks removed, except the Tunnel Rat's poncho (owner: "definitely needs to be there").
- The Foreman's moustache now sits right on the top of his beard (the owner marked the gaps in red).
- Installed: all 3 Rats, 3 Lost Miners and the Foreman. Skeleton tests 17/17.

**Mistakes and hurdles:**
- The first compare renders showed the models from behind. Fixed: camera on the -Y side.
- In side-by-side renders, the second model borrowed the first one's move (Blender names them Idle / Idle.001, and
  Blender 5 also needs the action *slot*). Fixed: each model picks its own action and sets `action_slot`.
- Fists first shrank toward the wrist, so the Foreman's fist slid off his pick handle. Fixed: shrink round the fist's middle.
  Feet shrinking toward the ankle would have made them float, so they only shrink sideways and lengthwise.
- Round 1 was too subtle; the owner wanted "drastic". Made it much stronger.
- The first waist try did almost nothing: the middle back bone carries almost none of the belly. Fixed: squeeze by
  height (most at belly height) instead of by bone.
- The Chrome browser timed out, so I couldn't screenshot the 3D page myself; I said so to the owner.
- `run_tests.sh` couldn't find Godot (`godot` isn't a command on the PC). Its path is the winget install:
  `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_...\Godot_v4.7.2-stable_win64_console.exe`.
- The build leaves a `_tex/` folder of scratch pictures inside `assets/models/creatures/`; deleted it (the pictures
  are packed inside the .glb files).

- The Prop Warden (moss boss) uses the same script. The owner said yes, so he got the same slim body and head_k 0.86.
  In the front picture his axe looked missing; a size check showed it was there, just pointing at the camera.

**Still open:** the Foreman's
left fist doesn't fully close round the handle, his beard is a flat board, and his belly piece is still big.
