# Great crusher (`trap_crusher_great`)

*No concept picture: ChatGPT refused this one (Nov 20). Look: the stone crusher sheet made twice as wide, the locked door's stone ([door_locked_round.jpg](door_locked_round.jpg)) and thin brass trim.*

**Dungeons:** Vigil of Orrin Stonejaw (Crusher Steps); Brassgate's vault style (brass trim).
**What it does:** a bigger crusher that kills outright, over stairs. **Clue:** stains on the steps, the chains' rattle. **Safe way:** time it; it's slow to rise.

## Size (2 m grid)
- **4 m wide × 2 m deep**, top beam at 5 m; the weight 4 × 1.8 × 1.2 m, slams down 2.4 m onto the stairs.

## Parts and what moves
| Part name | What it is | Moves? |
|---|---|---|
| `frame` | stone pillars and a big lintel with brass trim | stays |
| `weight` | iron-faced block + 4 chains | **drops** 2.4 m in 0.3 s, rises in 5 s |

## Start from
- The `trap_crusher_stone` sheet, twice as wide; the weight's underside follows the stair steps (stepped).

## Colours
- Stone: Stonehold cut stone (4 grey tones, dark mortar), dark iron bands.
- Brass trim: thin bands only (1 in 8 rule).

## MODEL-RULES checks that matter
- **Rule 1:** built by script; side-by-side picture with this concept before it's done.
- **Rule 2 (no shimmer):** moving parts keep at least 1 cm clear of the fixed parts in every position (check the start and the end pose).
- **FLOAT:** every part touches the rest (chain links touch each other, rivets touch plates).
- The stepped underside stays 2 cm above each step when down.

## Picture vs. this sheet
The picture is concept art for the look only. Sizes, parts and doors follow this sheet (whole 2 m squares, the existing round door).
