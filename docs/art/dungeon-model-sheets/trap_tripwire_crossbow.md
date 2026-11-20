# Tripwire crossbow (`trap_tripwire_crossbow`, `tripwire`, `tripwire_peg`)

*No concept picture: ChatGPT refused this one (Nov 20). Use the player crossbow model in `items_tools.py` for the
look, set into the style's wall niche, and the push-wall / spear-wall pictures for the wall around it.*

**Dungeons:** Lampwick (Rail Tunnel), Pell's (Winch Shed), Tomb (Collapsed Tunnel), Brassgate (Guard Corridor), Shieldbearers (Drill Cellar), Hammerfall (Slag Cellar).
**What it does:** a hidden crossbow fires when you hit a thin wire. Hurts. **Clue:** a shiny wire at ankle height. **Safe way:** step over it, or cut it.

## Size (2 m grid)
- Crossbow niche: a 2 × 2 m wall piece with a niche 0.6 m wide, 0.4 m tall at 0.9 m up; the crossbow 0.6 m long inside it.
- `tripwire`: 2 m long (one square), 0.12 m above the floor, 1 cm thick (thick enough to see). `tripwire_peg`: 0.25 m tall iron peg.

## Parts and what moves
| Part name | What it is | Moves? |
|---|---|---|
| `frame` | wall + niche | stays |
| `crossbow` | stock, bow, string | stays; the `string` snaps forward 0.2 m when it fires |
| `bolt` | the loaded bolt | fired by the code |
| `tripwire` | the wire | breaks in two when cut (two halves fall) |

## Start from
- Crossbow: the player crossbow in `items_tools.py`, made chunkier. Wall: the style's wall from the kit.

## Colours
- Wood: root-wood bark and planks (Shack `shackbark`, `shackplank`, `shacklogend`), rope picture, dark iron.
- Stone: Stonehold cut stone (4 grey tones, dark mortar), dark iron bands.
- Wire: pale grey with a bright highlight so it glints.

## MODEL-RULES checks that matter
- **Rule 1:** built by script; side-by-side picture with this concept before it's done.
- **Rule 3 (building piece):** clean layers (backing, material, trim, decor); nothing past the outline; outer faces 0.5 cm inside it; lines up with the kit's normal piece beside it (picture of both).
- **FLOAT:** every part touches the rest (chain links touch each other, rivets touch plates).
- The wire touches both pegs/anchor (FLOAT).

## Picture vs. this sheet
The picture is concept art for the look only. Sizes, parts and doors follow this sheet (whole 2 m squares, the existing round door).
