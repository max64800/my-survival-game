# Teaching the player: research and plan

*Written: November 24, 2026 (research chat on the Mac). Status: **research + proposal**. The owner has not yet picked which ideas become F-items.*

**Owner's goal:** teach through sound, light, shape and colour, not text. Let players explore on their own and point them
to *places* (ruins, dungeons, landmarks), never to *chores* ("mine 10 copper").

**Short answer:** sit halfway between Valheim (freedom) and Subnautica (signals point you somewhere). The
**ruins are our story line**: see a ruin → rebuild it → it teaches something → it points to the next ruin. No survival
game does this.

## 1. How the best games teach (the toolbox)

| # | Rule | Everyday picture | Our use underground |
|---|---|---|---|
| 1 | **Do first, explain after.** Text gets skipped; doing is remembered. | Learning to ride a bike, not reading about it. | Wake-up room is all rock, so you learn to break things (F333, done). |
| 2 | **Light pulls people.** The eye goes to the brightest, warmest spot. | Moth to a lamp. | Ruins and dungeon doors get their own light, visible down a tunnel. |
| 3 | **Hide, then reveal ("triangle rule", Zelda BotW).** Rocks and bends block the view, then show something. | Peeking round a corner. | Tunnel bends that open onto a ruin or a glowing crystal. |
| 4 | **Landmarks seen from far away.** Tall, odd-shaped things people steer toward. | A church tower in a town. | Towers, big crystals, waterfalls. |
| 5 | **One colour = one meaning, always.** Use several *gentle* clues, not one loud "yellow paint". | Traffic lights. | e.g. cold blue arch = dungeon. Green edge = poison (done). |
| 6 | **Sound tells you before your eyes.** | Hearing a dripping tap. | Dripping = water, clink = ore, hum = ruin, cold breath = dungeon. |
| 7 | **New thing in a safe spot, then test it in a risky one.** | Swimming in the shallow end first. | First poison monster alone, near the cure; poison in big fights later. |
| 8 | **Hints only when needed, then gone, kept in a book.** (Valheim's raven) | A sticky note that files itself. | A book of past "learned" cards. |

## 2. What other survival games do

| Game | How it teaches | Good | Bad | Take it? |
|---|---|---|---|---|
| Valheim | Raven tips on first discovery; bosses are the goals | Feels like your own adventure | Many new players get lost | ✅ discovery hints, places as goals |
| Subnautica | Radio and beacons send you places; scanning teaches recipes | Points to *somewhere*, never "do X" | Signals can be vague, scanner easy to miss | ✅✅ closest to our goal |
| Conan Exiles | "Journey" checklist with rewards | Clear for solo players | Hand-holding, spoils surprises | ❌ |
| 7 Days to Die | Short starter quests, then free | Fast start | Plain chore list | ⚠️ only "keep the start short" |
| Grounded | Robot gives story quests | Always clear | You follow, not explore | ❌ |
| Enshrouded | Story is the tutorial | Smooth start | Linear | ⚠️ partly |

## 3. Our game today (checked in the code, Nov 23)

### Good already
- World teaches the start: all-rock wake-up room (F333), dripping stalactite for water (F140), watchtower as first goal (F254).
- Rebuilding Chest shows pictures of the two ways and only what is missing (F560, F411/F431); missing pieces are amber ghosts (`src/ui/blueprint_preview.gd`).
- Status effects use colour: screen-edge green/orange/frost (`src/ui/screen_edge_flash.gd`), badges (`src/ui/ailment_badges.gd`), stun stars.
- "Recipe/Blueprint learned" cards with picture and where to make it (`src/ui/learned_cards.gd`, F580).
- Map with floor markers and up/down arrows (`src/ui/map_panel.gd`).

### Needs adjusting
- Build hammer lessons are text steps (`src/build/build_lessons.gd`): shorter, key picture + ghost where to place.
- First-steps line (`src/ui/hud.gd` `_update_first_steps`) is a checklist like Conan's: swap lines for world clues over time.
- Many text hints (bag hint, toasts, tooltips, rune hint). Keep text for names and numbers only.
- Learned cards vanish: no book to reread them.

### Missing
1. **Sound clues** (none yet; F792/F794 say sound isn't built).
2. **Sign of where to dig** (owner's F108): ore glints in lantern light, rare ore its own colour, cracks pointing to things.
3. **Pull toward faraway ruins and dungeons**: signature light and sound per place.
4. **Clear path to better gear** (owner's F103): a rebuilt ruin shows a weapon rack; its blueprint unlocks the smithy.
5. **Safe first meeting with each danger / status effect.**

## 4. The ruins as the teacher (our unique idea)
- Every ruin is seen from far away: own light colour and sound.
- A rebuilt ruin **wakes up**: lights come on, a sound plays, and a beam or lit path points to the next ruin (reward + signpost, no text).
- The rebuilt ruin is the lesson: forge ruin → forge, outpost → defence, brewhall → food.
- A nearby dungeon is the test of what the ruin taught.

## 5. Proposed to-do items (biggest win first)
1. Rebuilt ruin wakes up and points to the next ruin.
2. Sound clues: ore, water, ruins, danger.
3. Ore glints in lantern light (fixes F108).
4. Each dungeon entrance has its own look (light + arch shape).
5. Safe first meeting with each status effect.
6. Book of past hints / learned cards.
7. Shrink text hints to names and numbers.

## Sources
- GDC: "This is a Talk About Tutorials, Press A to Skip" — https://www.youtube.com/watch?v=VM1pV_6IE34
- Teaching the Player: Don't Use Words — https://www.gamedeveloper.com/design/teaching-the-player-don-t-use-words
- The Best Tutorial Is the One You Do Not Notice — https://onemanmmo.com/the-best-tutorial-is-the-one-you-do-not-notice/
- GMTK: How Nintendo Solved Zelda's Open World Problem — https://gmtk.substack.com/p/how-nintendo-solved-zeldas-open-world
- Realism and Legibility in Open World Level Design — https://gamedeveloper.com/design/realism-and-legibility-in-open-world-level-design
- Yellow paint debate — https://en.wikipedia.org/wiki/Yellow_paint_debate
- Control director on avoiding yellow paint — https://www.gamedeveloper.com/design/control-resonant-director-lays-out-case-for-avoiding-excessive-yellow-paint-
- Hodent, The Gamer's Brain Part 2 (GDC) — https://gdcvault.com/play/1022951/contactUs
- Valheim tips (Hugin) — https://www.gamesradar.com/valheim-tips-beginners-guide
- Subnautica tips — https://kotaku.com/tips-for-playing-subnautica-1823164825
- Subnautica newbie feedback — https://forums.unknownworlds.com/discussion/155958/original-subnautica-feedback-from-a-newbie-who-completed-11-runs
- Conan Exiles Journey feedback — https://forums.funcom.com/t/journey-revamp-feedback-first-impressions/221709?page=2
- Enshrouded review — https://www.windowscentral.com/gaming/enshrouded-early-access-review-thoughts-on-this-pc-survival-games-promising-present-and-shrouded-future

*Limits:* no hard player-retention studies were found; the comparison is from design talks, reviews and forums.
