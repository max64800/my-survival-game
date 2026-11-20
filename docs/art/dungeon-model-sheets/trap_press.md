# Great press (`trap_press`)

*No concept picture: ChatGPT refused this one (Nov 20). Look: the carpenter's vise station (`carpenters_vise.glb`) made huge, with the ore cart's forge iron ([ore_cart.jpg](ore_cart.jpg)).*

**Dungeons:** ⭐ The Hammerfall Works (Press Hall).
**What it does:** a giant screw press slams its platen down onto a stone bed you must cross. **Clue:** the screw creaks and turns before each press. **Safe way:** cross when it's rising.

## Size (2 m grid)
- **4 × 4 m footprint**, 6 m tall. Platen 3.6 × 3.6 m, 0.5 m thick; drops 2.2 m.

## Parts and what moves
| Part name | What it is | Moves? |
|---|---|---|
| `frame` | timber and iron frame, stone bed | stays |
| `screw` | the big wooden screw + spokes | **turns** round y (2 turns per press) and moves down with the platen |
| `platen` | the iron platen | **drops** 2.2 m in 0.4 s, rises in 4 s |

## Start from
- `carpenters_vise.py` (the screw and the handle) scaled up; frame logs from `dungeon_rootwood.py`; bed from `stonehold_v2.py`.

## Colours
- Forge: dark iron, soot-stained brick and stone, brass only as small trim; molten metal = the existing glow colour.
- Wood: root-wood bark and planks (Shack `shackbark`, `shackplank`, `shacklogend`), rope picture, dark iron.

## MODEL-RULES checks that matter
- **Rule 1:** built by script; side-by-side picture with this concept before it's done.
- **Rule 2 (no shimmer):** moving parts keep at least 1 cm clear of the fixed parts in every position (check the start and the end pose).
- **FLOAT:** every part touches the rest (chain links touch each other, rivets touch plates).
- No pistons, no motors (owner): only the screw drives it.

## Picture vs. this sheet
The picture is concept art for the look only. Sizes, parts and doors follow this sheet (whole 2 m squares, the existing round door).
