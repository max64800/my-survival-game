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

- **F25, the dwarf doesn't look dwarvish (said 2×).** 1st time: "short and wide". Claude 3 made a rigged dwarf, a bit better. 2nd time: "legs and arms should be shorter". Next try (Claude 3): short legs (about 1/3 of the height), short thick arms, barrel chest, wide shoulders, big hands, boots and head.

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
| Pictures / looks | F17, F22, F24, F25, F26 | **The dwarf's look keeps coming up (F25 said twice)** |

---

## Open (still to do)

*(Nov 14, after your first real play session. You chose: merge everything into main; start kit = rocks + roots + 1 crystal; 25–50 chunks; copper very rare.)*

- [ ] **F9. The world feels empty: it needs enemies, abandoned/destroyed structures, and columns.** Enemies + ruins already exist on the later branches. Merging brings them in. Columns are new. *From: you. Said: 1×*
- [ ] **F23. Real equipment slots** for pickaxe, lantern, clothes, etc. (not just the hotbar). *From: you. Said: 1×*
- [ ] **F24. The beard isn't attached to the face.** → Claude 3 (looks). *From: you. Said: 1×*
- [ ] **F25. The dwarf doesn't look dwarvish.** Should be short and WIDE, with shorter legs and arms, not a "small guy". → Claude 3. *From: you. Said: 2×* (Nov 14: "short and wide"; later: "better now, but legs and arms should be shorter")
- [ ] **F26. The long things hanging from the ceiling look like icicles,** the same width top to bottom. Real stalactites: wide at the top, getting thinner, a rounded tip, smaller ones around them. (They're actually roots, so roots should look like roots too.) → Claude 3. *From: you. Said: 1×*
- [ ] **F19. Caves are too round.** Make them a 50-50 mix: some smooth and round, some sharp and rocky. *From: you. Said: 1×*
- [ ] **F20. More tunnels, like Minecraft:** lots of passages crisscrossing, branching, and leading off in every direction. *From: you. Said: 1×*
- [ ] **F21. Columns should look better, like great dwarf halls**: carved pillars with a base, a shaft and a top. Not just blocks. (Same wish as the columns in F9.) *From: you. Said: 1×*

**Claude noticed, waiting for your OK** (not fixed until you say so):
- [ ] **C1. The game runs at only ~50 FPS on your RTX 3060 Ti.** It should be much higher, so something is slowing it down. (Found Nov 14 on the first PC run.)

## Done

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
