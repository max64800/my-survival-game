## 2026-11-26: Ruin 14 planned, the Sinkhole Ring (F915)

**What we did**
- Claimed F915 in FEEDBACK.md first, so other chats would see it.
- Gave the owner 4 ideas (Sinkhole Ring, Bridge-Houses, Pillar Abbey, Stepped Shrine). The owner picked the **Sinkhole Ring**, in stone + wood.
- Wrote the plan: `docs/design/ruin14/SINKHOLE-RING-PLAN.md`. A huge 12-sided stone tower grows up out of a 9 m deep hole in the cave floor. Houses cling to the hole's walls, stairs are pinned to the rock, and two bridges cross over.
  - It's the first ruin you go **down** into. The front bridge has fallen in, so you climb down the walls, go in at the bottom, and climb up through the tower.
  - The tower changes shape 4 times: round base, square keep, a wider wooden storey that juts out, then an 8-sided lookout under a spire.
- Made the block shape page `docs/design/ruin14/sinkhole_ring_shapes.html`, copied from ruin 13's page (same look and helpers, browner wood). It has buttons to look into the pit, show the way through, and cut the pit open. Published it as an artifact.

**Mistakes and hurdles**
- A long bash heredoc with apostrophes in it broke ("unexpected EOF"), and no files got written. Fix: wrote the files with the Write tool and joined them with a small Python script.
- The chrome-devtools browser tool timed out twice. Fix: took screenshots with headless Edge instead.
- First screenshots: everything was washed orange, the pit view was too close, and names inside buildings showed through walls. Fix: whiter, softer pit lights, a lighter pit floor, cameras moved back, and inside names only show when the pit is cut open.
- My first Ledge House plan had a side door under its jutting wooden storey. That breaks "nothing hangs over a door". Fix: it has one front door only.
- I first planned a small round keep (ring R = 1). It's only 7.5 m across, too small for stairs with free floor at both ends. Fix: an 8 x 8 m square keep.

**Next:** the owner OKs the shapes, then the blueprint `_sinkhole_ring()` (plan step 2).
