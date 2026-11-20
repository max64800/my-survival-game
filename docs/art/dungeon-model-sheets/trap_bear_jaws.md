# Bear jaw trap, open and shut (`trap_bear_jaws`)

![concept](trap_bear_jaws.jpg)

**Dungeons:** Lampwick (Old Copper Face), Pell's (Sorting Room), Barrows (Keeper's Corridor), Shieldbearers (Training Yard), Emberdeep (Coal Store), Cinderhold (Slag Heap).
**What it does:** iron jaws grab your leg for a few seconds. **Clue:** a rusty glint in the dust. **Safe way:** look down; a friend can pry it open.

## Size (2 m grid)
- 0.7 m across when open, 0.12 m tall; shut: jaws 0.3 m tall. Chain 0.5 m to a stake.

## Parts and what moves
| Part name | What it is | Moves? |
|---|---|---|
| `base` | the round plate, springs, stake, chain | stays |
| `jaw_l`, `jaw_r` | the two jaws | **snap shut**: each turns 90° up round its hinge (x axis, at the plate's edge), 0.08 s; open again in 1 s when pried |
| `plate` | the trigger plate | sinks 1 cm when stepped on |

## Start from
- `items_tools.py` iron parts; chain from `dungeon_rootwood.py` `chain()`.

## Colours
- Rusty dark iron with bright worn teeth tips; a dusty grey layer on top (open version) so it blends with the floor.

## MODEL-RULES checks that matter
- **Rule 1:** built by script; side-by-side picture with this concept before it's done.
- **Rule 2 (no shimmer):** moving parts keep at least 1 cm clear of the fixed parts in every position (check the start and the end pose).
- **FLOAT:** every part touches the rest (chain links touch each other, rivets touch plates).
- Shut: the teeth interlock 1 cm apart, never through each other.

## Picture vs. this sheet
The picture is concept art for the look only. Sizes, parts and doors follow this sheet (whole 2 m squares, the existing round door).
