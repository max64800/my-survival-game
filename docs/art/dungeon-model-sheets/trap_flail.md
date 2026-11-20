# Spiked flail + scrape circle (`trap_flail`)

*No concept picture: ChatGPT refused this one (Nov 20). Look: the swinging boulder's root-wood post and iron bands
([trap_swing_boulder.jpg](trap_swing_boulder.jpg)) with the spiked ball in the bear jaws' rusty iron.*

**Dungeons:** ⭐ Hall of the Shieldbearers (Shield Bridge), Hammerfall (Belt Walk), Cinderhold (Bellows Hall).
**What it does:** a spiked ball on a chain spins round a post. Ragdoll + hurts. **Clue:** a scrape circle on the floor. **Safe way:** run past behind the ball, or shoot the chain.

## Size (2 m grid)
- Post: 0.4 m thick, 2.2 m tall. Chain 1.6 m; the ball (0.6 m with spikes) spins at 0.8 m height, so the whole circle is **4 × 4 m** (2 × 2 squares).
- Scrape circle decal: 3.6 m across.

## Parts and what moves
| Part name | What it is | Moves? |
|---|---|---|
| `post` | post, iron bands, base stones | stays |
| `spin` | the collar, chain, ball | **spins** round the post (y axis), one turn per 2.5 s |
| `chain_top` | the collar ring | the chain breaks off below it when shot |
| `scrape` | the circle decal | stays |

## Start from
- Post: `dungeon_rootwood.py` logs + `night_stations.py` `cband()` iron bands; chain `chain()`; ball: a chunky sphere with 10 cone spikes.

## Colours
- Wood: root-wood bark and planks (Shack `shackbark`, `shackplank`, `shacklogend`), rope picture, dark iron.
- Ball: dark iron, brighter spike tips.

## MODEL-RULES checks that matter
- **Rule 1:** built by script; side-by-side picture with this concept before it's done.
- **Rule 2 (no shimmer):** moving parts keep at least 1 cm clear of the fixed parts in every position (check the start and the end pose).
- **FLOAT:** every part touches the rest (chain links touch each other, rivets touch plates).
- **Placement rule:** nothing the cave grows may stand in its moving area; add a keep-out test when it's placed.
- Spikes touch the ball (FLOAT), each one a little different (no perfect sphere).

## Picture vs. this sheet
The picture is concept art for the look only. Sizes, parts and doors follow this sheet (whole 2 m squares, the existing round door).
