# Stone crusher frame (`trap_crusher__cut_stone`, `__clay_brick`)

*No concept picture: ChatGPT refused this one (Nov 20). Look: the wood crusher `trap_crusher.glb` (same moves) in the portcullis and locked-door stone/brick ([portcullis.jpg](portcullis.jpg), [door_locked_round.jpg](door_locked_round.jpg)).*

**Dungeons:** Tomb, Barrows, Brassgate (Workers' Hall), Shieldbearers, Vigil; Pell's and Mossprop keep the wood `trap_crusher`.
**What it does:** a heavy weight slams down from the ceiling. **Clue:** dark stains below, a thin gap. **Safe way:** time it.

## Size (2 m grid)
- Same as the wood crusher: **2 × 2 m**, beam at 3.6 m; the weight slams down 1.6 m.

## Parts and what moves
| Part name | What it is | Moves? |
|---|---|---|
| `frame` | stone pillars + lintel | stays |
| `weight` | stone block + iron corner bands + chains | **drops** 1.6 m in 0.2 s, rises in 3 s; chains pay out through the lintel |

## Start from
- `dungeon_rootwood.py` `crusher()`: keep the moves and part names exactly, swap logs for `stonehold_v2.py` blocks (or brick).

## Colours
- Stone: Stonehold cut stone (4 grey tones, dark mortar), dark iron bands.
- Brick: Hearthbrick warm red-brown bricks (4 tones, dark mortar), pale limestone trim, dark iron.

## MODEL-RULES checks that matter
- **Rule 1:** built by script; side-by-side picture with this concept before it's done.
- **Rule 2 (no shimmer):** moving parts keep at least 1 cm clear of the fixed parts in every position (check the start and the end pose).
- **FLOAT:** every part touches the rest (chain links touch each other, rivets touch plates).
- Chains pass through **holes** in the lintel with 1 cm clearance (nothing passes through solid).

## Picture vs. this sheet
The picture is concept art for the look only. Sizes, parts and doors follow this sheet (whole 2 m squares, the existing round door).
