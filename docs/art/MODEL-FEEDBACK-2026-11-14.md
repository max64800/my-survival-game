# Model feedback, Nov 14 (the owner's 29 notes on stations, gear and building pieces)

The owner looked at every station, weapon, outfit and building piece and gave 29 notes.
Each one is an item in `FEEDBACK.md` (F34 to F62). This file groups them, says what is really wrong,
and how to fix it. Nothing is fixed yet.

## The new rule (the owner said "make it a rule")

**Every model is made in the same style as the workbenches** (the Forge workbench is the bar to beat):
a real 3D model with hand-painted textures, chunky hand-made shapes, never perfect boxes or circles.
**If a ChatGPT picture would help, make one, no need to ask.** (Also written in `CLAUDE.md`.)
How the workbench was made: see `docs/art/CREATURE-STYLE.md` (ChatGPT picture → asset forge → Blender → game).

## The 5 kinds of problem (most notes are one of these)

| # | Problem | Notes | One fix for all |
|---|---|---|---|
| A | **Floating / not touching.** Parts hang in the air or don't touch the part next to them. | 2, 9, 10, 13, 28, 29 | An automatic "contact" check: every part must touch another part or the ground. `tools/asset_forge/` already has a `contact` step; run it on every model and fail the check on any gap. |
| B | **Too perfect.** Perfect circles, perfect boxes, clean edges. | 5, 16, 23, 29 | Bevel and dent every edge, wobble the outline, add chips and scratches. Stone = chipped flakes, wood = uneven planks. |
| C | **Flat colour.** One shade everywhere (soup, water, the blue under the grindstone). | 6, 7, 9 | A painted gradient: darker deep down / in the middle, lighter at the edges, plus a few highlights (bubbles, ripples, shine). |
| D | **Loose rope.** Wraps that sag, stick out or leave gaps. | 19, 21, 22, 23 | Rope wraps tight, side by side, no gaps, ends tucked under (not sticking out). |
| E | **Too simple / reskins.** Shapes too blocky, or a new material is just the same shape in a new colour. | 3, 24, 25, 27 | Remake in the workbench style; each better material gets its own, slightly fancier design. |

## Every note

### Stations
| F | # | What | The owner said | What to do | Kind |
|---|---|---|---|---|---|
| F34 | 1 | Bellows | "needs a lot of work" (picture 1) | Remake. From the picture: the top board floats above the leather bag, the handles float beside it, the nozzle isn't joined to anything. Real bellows: two boards hinged at the back, leather pleats joining them all round, handles growing out of the boards, a nozzle fixed to the front. | A, E |
| F35 | 2 | Campfire | "floating still a bit" | Sink it into the ground so stones and logs sit on the floor. | A |
| F36 | 3 | Carpentry table | "needs more stuff on it" | Add clutter: planks, a saw, a mallet, shavings, a square, pegs. | E |
| F37 | 4 | Chest | "still a very wide base, I want it to match" (picture 2) | In the picture the bottom box is wider than the lid. Make the box and the lid the same width and depth. | E |
| F38 | 5 | Chopping block | "doesn't look like an axe in the middle; the round things on top stick out and are perfect circles" | Make the axe clearly an axe (a proper head, wedge-shaped blade, sunk into the wood at an angle). Tree rings: paint them on the top, flat, uneven, not raised perfect circles. | B |
| F39 | 6 | Cooking pot | "nice, but the soup looks identical everywhere" | Soup texture with a gradient (darker in the middle, lighter at the rim), bits of food, bubbles, a greasy shine. | C |
| F40 | 7 | Copper drip basin | "water is one shade of everything" | Water: deep dark in the middle, lighter at the edges, ripple rings where the drip lands, a highlight. | C |
| F41 | 9 | Grindstone | "good, but the 2 wooden blocks on the sides aren't attached; the blue bottom needs a darker complex gradient" | Join the side blocks to the frame (or a proper axle through them). Water trough: darker, deeper gradient. | A, C |
| F42 | 10 | Ore Crate (fills up) | "gems are floating there" | The gems in the rising ore pile must sit on the pile at every fill level. (This is the F33 pile.) | A |
| F43 | 12 | Rune slab | "okay, but the top-left frame is missing?" (picture 3) | The frame line around the edge has a gap at the top left. Close it (or make every gap clearly look like a chip, on purpose). | – |
| F44 | 13 | Stone saw | "floating a bit, not attached to anything" | Put the saw on a stand / bench, or have it rest on the stone it cuts. | A |
| F45 | 14 | Tanning rack | "good; lean it a bit with supports, like Valheim" | Tilt the frame back ~15-20° with two props behind it. | – |
| F46 | 15 | Tool rack | "great; can it hang on the wall instead of standing?" | Make it a wall piece: a flat back board, hangs flat on the wall (like the other wall pieces, wall shield etc.). | – |
| F47 | 16 | Training dummy | "good besides the head; use a not-perfect square" | A lumpy sack head, roughly square, a bit squashed, tied at the neck. | B |

**Fine as they are:** copper chest (8, "great"), rope ladder (11, "good").

### Weapons and tools
| F | # | What | The owner said | What to do | Kind |
|---|---|---|---|---|---|
| F48 | 17 | Bolts | "feathers are not the best texture; tips can be different crystal colours" | Better feather texture (real vanes, a split, a soft edge). Tips = crystal shards, a different colour per bolt type. | E |
| F49 | 18 | Building hammer | "weird triangles sticking out; just iron plates on the sides, no pointy things, it's for building not combat" | Remove the spikes. Iron plates on both sides of the head, with rivets. | – |
| F50 | 19 | Crossbow | "rope at the end isn't tight" | The bowstring must be pulled straight between the two tips. | D |
| F51 | 20 | Shield (back) | "the handle is just 2 wooden sticks; think Spartans: one big forearm part and a handle near the edge" | A wide forearm strap (leather with a metal band) in the middle, plus a hand grip near the rim. | E |
| F52 | 21 | Copper spear | "tighter rope" | Tight binding where the head meets the shaft. | D |
| F53 | 22 | Copper sword | "tight rope all through the handle, no gaps" | Wrap the whole grip, turns side by side, no gaps. | D |
| F54 | 23 | Stone tools | "too perfect; chip them more. The stone sword is a good example, but it has rope sticking out" | Knapped-flint look: flake scars, uneven edges, on every stone tool. Stone sword: tuck in the loose rope end. | B, D |

### Outfits, materials and building pieces
| F | # | What | The owner said | What to do | Kind |
|---|---|---|---|---|---|
| F55 | 24 | All outfits | "too blocky, too simple; this is where we'd need GPT images" | Remake every outfit from ChatGPT pictures in the workbench style: layers, seams, straps, buckles, fur trim. | E |
| F56 | 25 | Materials (the material items) | "would need to be done too" | Remake the material items (bars, planks, leather, ore…) in the same style. | E |
| F57 | 26 | Doorway | "should be round like a hobbit door; white stuff on the sides when I turn, same with stone" | Round doorway (arched top, round door). The white edges: something shows through at the seams (likely a texture edge or gap between faces). Find the cause and fix it for every material. | – |
| F58 | 26 | White flicker on edges ("clipping white stuff") | "when I turn it has white stuff on the sides" | Same bug as F57's second half; listed on its own because it hits many pieces. Likely: textures bleeding at the edge, or two faces in the same spot fighting. | – |
| F59 | 27 | Arch (clay brick, copper) | "weird stuff too, same with copper" | Same white-edge bug; check every arch material. | – |
| F60 | 27 | Each material its own design | "each material should not be a reskin but a different design, each slightly more complicated and better looking" | Wood → stone → clay brick → copper: each tier gets its own shape and details (e.g. copper gets rivets and bands, brick gets mortar lines). | E |
| F61 | 28 | Barrel | "rings don't touch each other" | Close the gaps: the hoops and staves must touch, no air between. | A |
| F62 | 29 | Beams (and half bricks) | "the halves don't touch; a beam can't be 2 bricks; nothing should be a perfect rectangle: a curve, scratches, texture" | A beam is one long solid piece. Halves of a piece must touch. Every piece: uneven edges, a slight curve, scratches, grain. | A, B, E |

## Suggested order (biggest win first)
1. **The white edges (F57-F59).** A bug, not a look; it shows on lots of pieces.
2. **Everything floating or not touching (kind A, 8 notes).** Add the automatic contact check first, so it can't come back.
3. **Quick model fixes** (hammer, crossbow string, tight ropes, chest width, rune frame, dummy head, tanning lean, tool rack on the wall).
4. **Gradients** (soup, water, grindstone trough).
5. **Big remakes with ChatGPT pictures:** bellows, outfits, materials, one design per building material, round hobbit door.
