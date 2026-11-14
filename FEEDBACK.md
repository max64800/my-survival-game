# Master feedback list

Every piece of feedback you give goes here, **even after it's fixed**.
Fixed items get ~~crossed out~~, never deleted, so we can see the whole history.

**How to read it**
- `[ ]` = still to do. `[x]` + ~~crossed out~~ = done (with the date and what changed).
- **Said** = how many times you've brought it up. If something comes back after it was "fixed",
  it gets a 🔁, moves back to the top, and goes in **Things that keep coming back** below,
  because that means the fix didn't really work.
- **From:** *you* = you said it. *Claude* = Claude spotted it in a play session and you said "yes, fix it".

---

## Things that keep coming back 🔁

- **F25, the dwarf doesn't look dwarvish (said 2×).** 1st time: "short and wide". Claude 3 made a rigged dwarf, a bit better. 2nd time: "legs and arms should be shorter". 2nd try (Claude 3): thick short bones, broad shoulders, barrel chest. 3rd time: "looks like a bulky guy". Next try: stout and round, not muscular. About 4 heads tall, a round belly, stubby legs, arms reaching the hips at most.

## Patterns (what kind of things you notice most)

| Area | Items | Notes |
|---|---|---|
| Seeing in the dark (light) | F1, F12 | The lantern comes up a lot: brightness, then refilling |
| Moving around (walking, jumping, climbing) | F2, F3 | |
| Controls + camera | F18, F23 | |
| Making the game / tools | F4, F5, F6, F7, F16 | |
| Sound | F8, F15 | |
| The start of the game (first 5 minutes) | F10, F11 | |
| A world that feels alive (enemies, ruins) | F9, F21 | Columns asked for twice (F9, F21) |
| Cave shapes (round vs sharp, tunnels) | F19, F20 | |
| Digging feel + resources | F13, F14 | |
| Pictures / looks | F17, F22, F24, F25, F26, F27, F28 | **The dwarf's look keeps coming up (F25 said 3 times)** |

---

## Open (still to do)

*(Nov 14, after your first real play session. You chose: merge everything into main; start kit = rocks + roots + 1 crystal; 25–50 chunks; copper very rare.)*

- [ ] **F23. Real equipment slots** for pickaxe, lantern, clothes, etc. (not just the hotbar). *From: you. Said: 1×*
- [ ] **F24. The beard isn't attached to the face.** → Claude 3: fixed on the `visuals` branch. The pack's little beard stays small on the face, and a real full beard now grows from the jaw down over the chest. Waiting for you to look. *From: you. Said: 1×*
- [ ] **F25. The dwarf doesn't look dwarvish.** Should be short and WIDE, with shorter legs and arms, not a "small guy". → Claude 3, on the `visuals` branch: stubby legs (measured: 34% of the height, about a third), short arms that end at the hips, a round belly (not muscles), a big head and big hands and boots. Waiting for you to look. *From: you. Said: 3×* (Nov 14: "short and wide"; later: "legs and arms should be shorter"; then: "looks like a bulky guy: shorter legs, shorter arms, maybe fat")
- [ ] **F26. The long things hanging from the ceiling look like icicles,** the same width top to bottom. Real stalactites: wide at the top, getting thinner, a rounded tip, smaller ones around them. (They're actually roots, so roots should look like roots too.) → Claude 3, on the `visuals` branch: roots are now twisted, knobbly wood that forks into thin strands, and real stone stalactite clusters hang from the ceilings. Waiting for you to look. *From: you. Said: 1×*
- [ ] **F27. The game looks too "Roblox-y".** Make it look more like Valheim (Grounded if possible): real textures, better colours and shapes, not super realistic. → Claude 3, on the `visuals` branch: hand-painted rock, darker cave with fog and floating dust, painted grain on every object, fire, lantern, effects, cave clutter. Waiting for you to try it. *From: you. Said: 1×*
- [ ] **F28. Animations: running, jumping, swinging…** → Claude 3, on the `visuals` branch: a real 3D dwarf with idle, walk, jog, sprint, jump + landing, a mining swing, axe chop, sword attacks, dodge roll, block, shield, crossbow aim/shoot/reload, getting hit, knock-back, eating, throwing, getting up; friends see it all in co-op. *From: you. Said: 1×*

**Claude noticed, waiting for your OK** (not fixed until you say so):

## Done

- [x] ~~**C1. The game only runs at ~50 FPS on the RTX 3060 Ti.**~~ Explained + sped up Nov 14. Claude 3 measured it: the ~50-60 is just the frame cap. Your screen is 60 Hz and "vsync" holds the game to it. Without the cap it runs ~200-300 FPS. Speed-ups along the way: glowing things are now found through a grid instead of checking every one (Claude 3), and the block-breaking burst reuses its shapes (Claude 1). A few small hitches remain, from the cave re-building itself after digging. *From: Claude (first PC run). Said: 1×*
- [x] ~~**F21. Columns should look better, like great dwarf halls, not just blocks.**~~ Done Nov 14. Carved columns: a stepped base, an 8-sided shaft with 2 bands that narrows toward the top, and a wide stepped top. Broken ones snap off with a jagged top, and their fallen pieces and rubble lie around them. *From: you. Said: 1×*
- [x] ~~**F20. More tunnels, like Minecraft.**~~ Done Nov 14. About 3x the tunnels: more loops, more dead ends, and 16 twisty side passages per area that branch, cross, climb and dip. *From: you. Said: 1×*
- [x] ~~**F19. Caves too round: make a 50-50 mix of smooth and sharp/rocky.**~~ Done Nov 14. Big patches of the cave are either smooth and round, or sharp and angular like broken stone. Measured: 49.6% rocky. *From: you. Said: 1×*
- [x] ~~**F9. The world feels empty: enemies, abandoned structures, columns.**~~ Done Nov 14. The merge brought monsters, 3 bosses, ruins, camps and shrines. Ruins now have carved columns (mostly broken) and crumbling block walls, and 1-2 rows of great columns stand in every big cavern (9 in cave 42). *From: you. Said: 1×*
- [x] ~~**F22. Holding a pickaxe when I have nothing.**~~ Fixed Nov 14. Any non-tool (empty hand, rocks, food) used to fall back to drawing a pickaxe. Now an empty hand holds nothing. *From: you. Said: 1×*
- [x] ~~**F17. Pictures for items.**~~ Done Nov 14. Claude 2 made 170 item pictures, and Claude 1 shows them in the hotbar and bag (the old colored square only if a picture is missing). *From: you. Said: 1×*
- [x] ~~**F15. A menu to mute/unmute and change the volume.**~~ Done Nov 14. On the pause screen (Esc): a Sound slider and a Mute switch, remembered next time. *From: you. Said: 1×*
- [x] ~~**F14. Copper is too common.**~~ Fixed Nov 14. Measured: copper went from 8% of the cave wall rock down to 1.3% (1/6, as you chose). Jungle silver is unchanged. *From: you. Said: 1×*
- [x] ~~**F13. A broken block should burst into lots of pieces.**~~ Done Nov 14. 25-50 little bits pop out, tumble, then fly into you. Still 1 item, like before. *From: you. Said: 1×*
- [x] ~~**F12. Refilling the lantern was impossible.**~~ Fixed Nov 14. Two reasons: most crystals grew too high to reach, and R failed silently (for example when the lantern was nearly full). Now every cavern has crystals at dwarf height, R always says what's wrong, and rootwood works as fuel too. *From: you. Said: 1×*
- [x] ~~**F11. Start with nothing: pick up rocks, craft a pickaxe and a lantern.**~~ Done Nov 14. 6 loose rocks, 1 crystal and 3 thin roots (pull them by hand) in the room. Tab: Stone Pickaxe (3 stone + 2 rootwood) and Lantern (2 stone + 1 rootwood + 1 crystal). A hint line tells you each next step. *From: you. Said: 1×*
- [x] ~~**F10. Start in a small room with a glowing hole, dig through, run a tunnel, reach the cave.**~~ Done Nov 14. A small sealed room, a soft dirt wall with a glowing crack (light leaking through), and a 15-20 m tunnel to the first big cavern. Tested on 6 different caves. *From: you. Said: 1×*
- [x] ~~**F18. The mouse wheel should zoom the camera, not change the hotbar. Hotbar = keys 1-9.**~~ Done Nov 14. The wheel zooms smoothly from 1.4 m to 8 m behind the dwarf, and the hotbar now has 9 slots (keys 1-9). *From: you. Said: 1×*
- [x] ~~**F16. Merge all the steps (up to the Fungal Jungle) into main.**~~ Done Nov 14. The desktop icon now plays everything: crafting, survival, building, monsters, ruins, bosses, the Fungal Jungle. 214 auto-checks pass, and the autopilot played through all of it. *From: you. Said: 1×*
- [x] ~~**F8. Mute only Claude's tests. When I play, I want sound.**~~ Fixed Nov 14. Muting was already only for Claude's test runs. The real problem was that Step 1 had **no sounds at all** (they'd only been built on the Step 6 branch). Now Step 1 has 11 sounds from Kenney's free packs: pickaxe swing, digging (soft for moss/dirt, hard for stone), rock breaking, a "clink" on rock that's too hard, crystals, footsteps, pickups, lantern refill, and bag open/close. *From: you. Said: 1×*

- [x] ~~**F1. The lantern is too dim.**~~ Fixed Nov 14. The dwarf's own body *and* the lantern's glass box were blocking the light, like holding a flashlight behind your back. Now neither blocks it, and the light reaches further. *From: Claude (test session), you said yes. Said: 1×*
- [x] ~~**F2. The dwarf gets stuck on small ledges and bumps.**~~ Fixed Nov 14. The dwarf now steps up anything up to 50 cm tall by itself, like stairs. Taller walls still need a jump. *From: Claude (test session), you said yes. Said: 1×*
- [x] ~~**F3. Add a jump.**~~ Fixed Nov 14. Space already jumped, but on bumpy cave floors it often didn't work, because the game wasn't sure the dwarf was standing. Now a jump works for a moment after you walk off an edge, and if you press it just before you land. It's a bit higher too (about 1.5 m). *From: you. Said: 1×*
- [x] ~~**F4. Record the game every time I play, automatically.**~~ Done Nov 14 (OBS auto-recorder). *From: you. Said: 1×*
- [x] ~~**F5. Put the game on my desktop.**~~ Done Nov 14 ("Dwarf Game" icon, plus a "Dwarf Game Sessions" folder icon). *From: you. Said: 1×*
- [x] ~~**F6. Mute the game while Claude is testing.**~~ Done Nov 14. Every Claude now runs the game silent. *From: you. Said: 1×*
- [x] ~~**F7. No feedback pop-up; I'll say it in chat.**~~ Done Nov 14. The box is off. Claude still checks every session by itself. *From: you. Said: 1×*
