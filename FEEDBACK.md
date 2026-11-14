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

*Nothing yet.* (When the same problem shows up twice, it goes here with what we tried each time.)

## Patterns (what kind of things you notice most)

| Area | Items | Notes |
|---|---|---|
| Seeing in the dark (light) | F1, F12 | The lantern comes up a lot: brightness, then refilling |
| Moving around (walking, jumping, climbing) | F2, F3 | |
| Making the game / tools | F4, F5, F6, F7, F16 | |
| Sound | F8, F15 | |
| The start of the game (first 5 minutes) | F10, F11 | |
| A world that feels alive (enemies, ruins) | F9 | |
| Digging feel + resources | F13, F14 | |
| Pictures / looks | F17, F18, F19, F20 | Claudes 2 and 3. Biggest wish: less "Roblox", more Valheim/Grounded |

---

## Open (still to do)

*(Nov 14, after your first real play session. You chose: merge everything into main; start kit = rocks + roots + 1 crystal; 25–50 chunks; copper very rare.)*

- [ ] **F9. The world feels empty: it needs enemies, abandoned/destroyed structures, and columns.** Enemies + ruins already exist on the later branches. Merging brings them in. Columns are new. *From: you. Said: 1×*
- [ ] **F10. Don't start in a big cave.** Start in a small room with a tiny hole where something glows on the other side. Dig through, run down a tunnel, then reach the big cave. *From: you. Said: 1×*
- [ ] **F11. Start with nothing.** Pick up loose rocks (plus roots + 1 crystal). Tab shows the bag **and simple crafting**. Craft a pickaxe and a lantern, then dig out. *From: you. Said: 1×*
- [ ] **F12. Refilling the lantern is impossible right now.** *From: you. Said: 1×*
- [ ] **F13. A broken block should burst into lots of pieces (25–50, random)** that all fly to you, but still only give 1 rock/copper/etc. *From: you. Said: 1×*
- [ ] **F14. Copper is too common.** Make it very rare (about 1/6 as much). *From: you. Said: 1×*
- [ ] **F15. A menu to mute/unmute the sound** (and change the volume). *From: you. Said: 1×*
- [ ] **F16. Merge all the steps (up to the Fungal Jungle) into main**, so the desktop icon plays the full game. *From: you. Said: 1×*
- [ ] **F17. There are no pictures for resources/items.** → Claude 2 (pictures from ChatGPT) and Claude 3 (how the game looks) are on this. Claude 1 makes sure their pictures plug in. *From: you. Said: 1×*
- [ ] **F18. The game looks too "Roblox-y".** Make it look more like Valheim (and Grounded if possible): real textures, better colours and shapes, not super realistic. → First pass done Nov 14 on the `visuals` branch: hand-painted rock textures, a darker cave with fog and floating dust, painted grain on every object. Waiting for you to try it. *From: you. Said: 1×*
- [ ] **F19. I want animations: running, jumping, swinging…** → First pass done Nov 14 on the `visuals` branch: a real 3D dwarf with idle, walk, jog, sprint, jump, pickaxe swing, sword attacks and a dodge roll. Waiting for you to try it. *From: you. Said: 1×*
- [ ] **F20. The dwarf doesn't look like a dwarf: dwarves are short, fat and wide.** → Fixed on the `visuals` branch (much shorter legs, 45% wider, bigger chest, head, hands and feet). Waiting for you to say if it's dwarfy enough. *From: you. Said: 1×*

**Claude noticed, waiting for your OK** (not fixed until you say so):
- [ ] **C1. The game runs at only ~50 FPS on your RTX 3060 Ti.** It should be much higher, so something is slowing it down. (Found Nov 14 on the first PC run.)

## Done

- [x] ~~**F8. Mute only Claude's tests. When I play, I want sound.**~~ Fixed Nov 14. Muting was already only for Claude's test runs. The real problem was that Step 1 had **no sounds at all** (they'd only been built on the Step 6 branch). Now Step 1 has 11 sounds from Kenney's free packs: pickaxe swing, digging (soft for moss/dirt, hard for stone), rock breaking, a "clink" on rock that's too hard, crystals, footsteps, pickups, lantern refill, and bag open/close. *From: you. Said: 1×*

- [x] ~~**F1. The lantern is too dim.**~~ Fixed Nov 14. The dwarf's own body *and* the lantern's glass box were blocking the light, like holding a flashlight behind your back. Now neither blocks it, and the light reaches further. *From: Claude (test session), you said yes. Said: 1×*
- [x] ~~**F2. The dwarf gets stuck on small ledges and bumps.**~~ Fixed Nov 14. The dwarf now steps up anything up to 50 cm tall by itself, like stairs. Taller walls still need a jump. *From: Claude (test session), you said yes. Said: 1×*
- [x] ~~**F3. Add a jump.**~~ Fixed Nov 14. Space already jumped, but on bumpy cave floors it often didn't work, because the game wasn't sure the dwarf was standing. Now a jump works for a moment after you walk off an edge, and if you press it just before you land. It's a bit higher too (about 1.5 m). *From: you. Said: 1×*
- [x] ~~**F4. Record the game every time I play, automatically.**~~ Done Nov 14 (OBS auto-recorder). *From: you. Said: 1×*
- [x] ~~**F5. Put the game on my desktop.**~~ Done Nov 14 ("Dwarf Game" icon, plus a "Dwarf Game Sessions" folder icon). *From: you. Said: 1×*
- [x] ~~**F6. Mute the game while Claude is testing.**~~ Done Nov 14. Every Claude now runs the game silent. *From: you. Said: 1×*
- [x] ~~**F7. No feedback pop-up; I'll say it in chat.**~~ Done Nov 14. The box is off. Claude still checks every session by itself. *From: you. Said: 1×*
