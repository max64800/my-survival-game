# The 14 dwarf Shorts (049-062): edit plan (Nov 18, 2026)

Scripts: `video/scripts/dwarf-series-049-055-plan.md` and `dwarf-series-056-062-plan.md`. Video rules:
`video/rules/dwarf-game-video-rules.md` (game and mistakes first, AI one line at most, a mistake + fix in every video,
end on "Wishlist Dwarves Never Fall on Steam"). Owner, Nov 18: **use the rough stuff** (spinning 3D model pages, early
monsters, the blobby first benches). We show the process and the journey, not perfection.

## The recordings
The 14 phone clips (front of the orange towel, filmed Nov 18 06:15-07:25) are in `Videos/Dwarf Game Shorts/raw/`,
next to the game recordings (`Videos/Dwarf Game Recordings/`). Whisper transcripts with timestamps:
`Videos/Dwarf Game Shorts/transcripts/`. Each clip holds several takes of one script; the editor's
`runs_transcribe.py` + `cut_*.py` pick the best take per line.

| Short | Clip | Length | Notes from the transcript |
|---|---|---|---|
| 049 Why I'm making it | IMG_4406 | 2:14 | ⚠ No speech found from 0:09 to 1:01: the opening ("Survival games are my favourite…", the four games, "So I'm making my own", the Claude line) may be missing or very quiet. Check; refilm the opening if it's missing. The rest is there. |
| 050 Deep Rise lesson | IMG_4408 | 2:23 | Full. |
| 051 Play-Doh shortcut | IMG_4409 | 2:16 | Full. |
| 052 The dwarf | IMG_4410 | 1:46 | Full ("I just got a small child" instead of "a small guy": funny, keep). |
| 053 Spaceship sounds | IMG_4411 | 2:09 | Full. |
| 054 Eight tries | IMG_4412 | 1:44 | Full; ad-lib "eyes glow red when it charges, a weak spot on his back" (true: keep). |
| 055 Four days | IMG_4413 | 2:09 | Full ("millions of stars"). |
| 056 The name | IMG_4414 | 1:59 | Full. |
| 057 Digging | IMG_4415 | 1:44 | Full. |
| 058 Too big | IMG_4416 | 1:17 | Full. |
| 059 34 seconds | IMG_4417 | 2:06 | Full. |
| 060 Rock Snail | IMG_4418 | 2:01 | Full. |
| 061 Small things | IMG_4419 | 1:32 | Full. |
| 062 The dark | IMG_4420 | 1:00 | Full. |

## Footage we have (sources)
- **Game recordings** (OBS, 32 sessions, Nov 14-17): Nov 14 = the first blocky cave and block monsters; Nov 15-16 =
  hand-built benches, first beetle, sounds; Nov 17 evening = the huge star cavern (then the smaller one).
- **Blobby first models** (179, picture-to-3D): `journey/3d/v1_ai_triposr/` (`overview_stations.png`,
  `overview_items.png`, `gem_bench_owner_screenshot.png`). The rebuilt ones: `journey/3d/v2_hand_built/`.
- **Monsters, early → now:** `docs/art/creatures-2026-11-15/` (first blobs), `journey/forged_creatures_2026-11-15/`,
  `docs/art/rock-beetle-v2/` (step pictures, rounds 1-8), `docs/art/rock-snail-v2/`.
- **The dwarf:** `docs/art/dwarf-round1/`, `dwarf-round2/`, and the Dwarf Body 3D page (rounds 1 → 3d, armor,
  tools with all 12 moves).
- **3D model pages to screen-record spinning** (claude.ai pages, Spin button): Dwarf Body, Rock Snail, Rock Beetle
  Shape, Dwarf Cave Creatures, Dwarf Forge Models, Monsters and Building Kit, Delver's Shack Kit, Delver's Hut,
  Stonehold Kit, Stone Watchtower, Watchtower Ruin, Fallen Outpost, Cave Plants.
- **Steam art:** `docs/steam/page/art/` (capsules, logo, key art), screenshots `docs/steam/page/shots-draft-2026-11-18/`.
- **Never** other games' footage (Valheim etc.): name them on a text card only.

## Per video: what goes behind him / full screen
Format per line: **spoken line → picture**. "Full" = cut to full-screen footage; otherwise it's the towel background
swap (`towel_key.py`) or a card.

**049 Why I'm making it** (passion)
- Survival games are my favourite → star cavern flythrough behind him (Nov 17 recording, or a new dev-fly capture).
- Valheim, Grounded… → four game names as text cards (no footage).
- None let me be a dwarf underground → our dwarf walking in the cave (full).
- It looked like Roblox / blocky monsters, flat colours → **Nov 14 recording** (block monster, dark cave) (full).
- Four days later, ceiling full of stars → **Nov 17 star cavern** (full), the before/after split.
- End → Steam main capsule + "Wishlist".

**050 Deep Rise lesson** (Deep Rise video of the batch)
- First game a week late → Deep Rise Steam page (owner's own game).
- 250 vs 1,100 → big number cards (check the forecast report numbers first).
- It's a survival game, dig, build, fight → quick cuts: digging, a bench going down, the beetle charge.
- My first monster, made of blocks → Nov 14 block monster (full).

**051 Play-Doh shortcut**
- First models looked like Play-Doh → `overview_stations.png` slow zoom (full).
- Look at this workbench, it's a blob → v1 workbench turntable / `gem_bench_owner_screenshot.png`.
- Now built with code, plank by plank → **Dwarf Forge Models page spinning** (record it), v2 workbench picture.
- Before/after split: v1 workbench | v2 workbench.

**052 The dwarf**
- Small guy / bulky guy / sausages and balls → `dwarf-round1` pictures, Dwarf Body page "Round 1" spinning.
- Pictures first, built piece by piece → the turnaround picture (`ref/body_compare.jpg` on the page).
- Real face, swinging braids, patched shorts → Dwarf Body page round 3d + the armor and tools moves (sword combo).

**053 Spaceship sounds**
- Sci-fi whoosh, microwave beep → game clip opening the bag / lantern with the OLD sounds (get the old .ogg files
  from git history and lay them over), then the new ones.
- Claude turned sounds into pictures → the spectrogram pictures from the sound work (search JOURNAL "spectrogram").
- Bat squeal = creaky door → bat model on the Cave Creatures page + the door sound.

**054 Eight tries**
- Try one, melted blob → `docs/art/creatures-2026-11-15` beetle (full).
- Too flat / leg floating / turned white → `rock-beetle-v2` step pictures in order (quick cuts).
- Try one next to try eight → split screen.
- Six legs, red eyes, glowing back → Rock Beetle page spinning + an in-game charge clip.

**055 Four days**
- Plain cave with block monsters → Nov 14 recording. Stars + light snakes → Nov 17 star cavern (full).
- 260 notes → scroll through FEEDBACK.md (sped up).
- Blobby models, spaceship lantern, white beetle → 1-second flashes of each (from 051, 053, 054).
- Not a real game yet, monsters being rebuilt → snail and bat old/new pictures.

**056 The name**
- Dwarfstone / Dwarfhold / Dwarfrune / Never Die → each name as a card with a red "TAKEN" stamp.
- Dwarves Never Fall → **the logo** (`library_logo_1280x720.png`) slam-in.
- Dig, build, fight, never fall → key art (`keyart_wide.png`) slow push.

**057 Digging**
- Felt like hitting a pillow, rock vanished → an old recording dig (Nov 14-16) (full).
- Cracks spread, shatters into chunks, every hit pays → **new capture needed**: dig with the current build (F261 work).
- Axe 2 hits, pickaxe 10 → new capture: chop a root with each, hit counter on screen.

**058 Too big**
- Huge, tall, bright → Nov 17 evening recording of the huge cavern (full).
- Too big, half empty → the same, slow pan over the empty floor.
- Back to normal size → new capture of the current first cave.

**059 34 seconds**
- Stuck screen → a loading screen from any recording, a timer counting up.
- Stopwatch on every step → the freeze-watcher log lines as on-screen text.
- Pebbles → close-up of cave floor pebbles (dev light F7 capture).
- 34 → 10 → big numbers.

**060 Rock Snail**
- Spits, lift your shield → **new capture**: snail spit + shield block in game.
- It was a blob → old snail (Cave Creatures page or `creatures-2026-11-15`).
- Built by hand, sculpted, painted → `rock-snail-v2` pictures, Rock Snail page spinning.
- One to go: the bat → the old bat.

**061 Small things**
- Spear swung like a sword → the Dwarf Body tools page (old round vs Spear clip now).
- Table almost as tall as the dwarf → old recording with the tall bench, then the smaller one.
- Table inside a wall → **new capture**: the red ghost refusing to place.
- Bonus (same theme, owner's notes Nov 17): the pickaxe that went through his head while running.

**062 The dark**
- Lantern runs out, nothing happens → new capture: lantern empty, dark cave.
- Maybe courage / monsters find you / whispers → three choice cards (comment vote).

## New captures to record (one session, muted robot or the owner playing)
1. Digging with cracks and shatter; axe vs pickaxe on a root (057).
2. The current first cave (058).
3. Snail spit + shield block (060).
4. Red ghost: a table refused in the wall (061).
5. Lantern running out (062).
6. Star cavern flythrough with dev fly (049, 055) if the Nov 17 recording isn't clean enough.
7. Screen recordings of the 3D pages spinning (Dwarf Body, Rock Snail, Rock Beetle, Forge Models, Cave Creatures).

## Order and posting
Post 049 → 062 in order, one a day, **only after the Steam page is live** (submitted Nov 18; review 3-5 working days).
Each title and caption goes to the owner for a yes before posting (README: sobergaming profile).
