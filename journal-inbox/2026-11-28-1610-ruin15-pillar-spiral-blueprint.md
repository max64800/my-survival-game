## Nov 28 — F942 steps 2–4: Ruin 15, the Pillar Spiral, as a real blueprint

**What we did:** The owner OK'd the Pillar Spiral's block-shape page ("I love it"). This chat built the real blueprint,
its design test and its ruin page.
- **The blueprint** (`BlueprintLibrary._pillar_spiral()`, id `pillar_spiral`; it can only be learned by rebuilding its ruin).
  - The rock column stands in the middle of a stone 12-sided Ring Hall (22 m across).
  - Four houses wind round the column, each one a storey higher than the one before: the Lamp House, Store House and
    Bunk House, and the Bell Tower with a wooden storey, a railed deck and the Eyrie lookout under a spire.
  - A wooden stair winds round the column, one flight on each side.
  - Also: the Arch Bridge to the Kiln House on a rock lump, the wooden Shrine Bridge to the Rock Shrine on a high shelf,
    and a stone plinth and grand stair in front of the round main door.
  - Materials go stone at the bottom, brick in the middle, wood on top. 1,164 pieces.
  - Helper code for the cave's own ground and the column: `pillar_rock`, `ps_column`, `_ps_ground`.
  - `_big_ring_layer` got a `middle` switch so the ring's middle can stay open where the column is.
- **Design test** (`tests/test_pillar_spiral_design.gd`, 8 checks, all pass). It checks that:
  - the ruin is sound
  - you can walk through it, with a free 2 m block at every stair's foot and top
  - every door has a floor level with its sill
  - brackets keep off windows
  - there are no ladders or ramps
  - the ring meets the plinth and the Arch Bridge flush
  - no piece pokes into the column
  - the materials are right and the spire is the top piece
- **Ruin page** (`tools/ruins/make_pillar_spiral_page.py` + `pillar_spiral_page.html`). It is built from the real
  blueprint, with the cave ground and the rock column drawn in. In the ruin view:
  - the left flight of the stair has fallen
  - the spire leans and one kiln chimney is broken
  - roofs have holes, and ceiling rubble lies on the terrace

  Claude photographed it in headless Edge before showing it, then published it as an artifact for the owner's OK.

**Mistakes and hurdles:**
- The spire was planned in wood, but the `roof_spire` piece only comes in clay brick. Fixed: the Eyrie's spire is brick.
- Gentle (26°) roofs with two rows overlapped the walls under them. The gables of the second row need a half wall,
  not a full wall. Fixed in `_ps_roof`.
- The test for "the bridge meets the ring flush" first grabbed the bridge pier's footing slab instead of the deck.
  Fixed: it only looks at slabs at deck height.
- The first "nothing inside the column" test used each piece's straight (unturned) box. For pieces turned round the
  ring, that box reaches too far, so it flagged good pieces. Fixed: it now samples each piece's real turned footprint.
- A shell script with nested quotes broke; Claude wrote it to a file and ran that instead.
- Headless Edge wrote no screenshot when given a relative path; absolute paths work. Port 8947 was already taken by an
  older server, so the page was served on 8949.
- On the page, the column's top (where it widens into the ceiling) rendered almost black. A lighter, two-sided rock
  colour helped. It is still dark, which reads as rock going up into the dark ceiling.
- The Eyrie is 6-sided, not 8 as on the shape page: the game's round shapes come in 6 and 12 sides. There is no bell
  yet, because the game has no bell piece.
- Another chat had left unfinished Brickcrown work (Nov 25) in the same two files. Claude committed only its own
  Pillar Spiral lines and left the rest untouched.
- An earlier chat hook blocked one command, and the F942 notes were first put under F943 by mistake. Both were fixed.

**Next:** the owner checks the page. Then step 5 puts the ruin in the world, after the owner answers whether to grow a
rock column just for this ruin or use a thinner pillar.
