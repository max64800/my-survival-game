# HUD clean-up and teaching revamp (F870)

*Owner's choices, Nov 25 (PC), quiz in the tin ore chat. Built from `docs/design/player-teaching.md` and
`docs/research/players-first-hours-and-why-they-quit.md`.*

**Owner's problem:** the screen is "all over the place", too much text: controls top left, parry text in the
middle, all skills top right, Well Fed + lantern on the left.
**Owner's rule:** no yellow markers or yellow paint anywhere in the world. It's not an RPG or story game.
Most players have played games like this before.

## What the owner chose

### Screen (HUD)
1. **Controls list:** off the screen. It lives only in the settings page.
2. **Skills (top right):** hidden. A skill pops up for ~2 s only when it grows (e.g. "Mining +6" bar), then hides.
   The full list stays in the skills window (K).
3. **Parry text in the middle:** removed. Perfect parry = a bright spark star on the weapons + a ringing metal
   sound (+ a tiny slow-down). A normal block = a dull thud. No words.
4. **Well Fed on the left:** removed (the hunger dial already shows it).
5. **Lantern:** no bar. When the lantern runs out, show one very simple pop-up: "Press L to refill the lantern".
   (Check the real key in the input map; the owner said L.)
6. **"[E] Open / [E] Pick up" prompts:** keep, tiny (key + one word), right next to the thing you look at.

### Teaching
7. **No goal text on screen** ("Find copper" etc.). The world points the way instead.
   The first-steps checklist (`hud.gd` `_update_first_steps`) goes.
8. **First time you meet something new** (first crystal, first workbench, first poison, ...): a **picture card**
   (like the "Recipe learned" cards, `src/ui/learned_cards.gd`): a picture + one line, shown once.
9. **Card book:** every card seen is kept. It's a **tab in the skills window**: K opens skills, **J opens the same
   window on the Notes tab** with all the cards.
10. **Setting:** "Hints and cards: on/off" in settings, on by default.
11. **Build hammer lessons** (`src/build/build_lessons.gd`): removed. The build menu pictures and the Rebuilding
    Chest ghosts are enough.

### Guides in the world (no paint)
12. **Ore glints in lantern light:** copper and tin twinkle a little when your lantern shines on them (also F108).
13. **An old worn dirt path connects all ruins and places (POIs):** faint packed dirt with a few old stones,
    broken cart tracks and fallen torches. Easy to follow if you look, easy to leave.
    Placement rule: nothing the world grows may stand on the path (needs a keep-clear test), and the path must
    not cut through built things.

(Not picked this time: sound clues, ruins waking up when rebuilt, own light per place. Keep them for later.)

## Suggested build order (each step playable before the next)
1. HUD clean-up (1-6): mostly removing things. Quick win, play test.
2. Parry flash + sound (3) and the skill pop-up (2).
3. Picture cards for first times + the Notes tab (J) + the on/off setting (8-10); remove the build lessons and
   first-steps line (7, 11).
4. Ore glint in lantern light (12).
5. The dirt path between ruins and places (13): world generation, the biggest step.
