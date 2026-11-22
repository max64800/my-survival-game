## Nov 22 – Prow Hall: better cave rock, and mending it in wood (F656 + F657)

**What we did**
- The owner liked the Prow Hall page ("a lot better, a lot more complicated") and asked for two things: better rocks and a wood button.
- **Rocks:** the cave on the 3D page used to be loose rock balls. Now it is one rough rock surface: the floor, the dip under the bridge,
  a cliff wall behind the keep with ledges, a jagged top and boulders set into its face, and the lump under the lone tower, which now has a ledge halfway down.
  The rock only fills the space the blueprint keeps as rock, so it never pokes into a building.
- **Wood:** added the `wooden_prow_hall` blueprint. Its soundness test now checks the stone and the wooden version.
- The owner then pointed out that a full wood rebuild "fixes like 80% of the castle", but the ruin isn't 80% broken. So the page's wood button
  now shows the ruin **mended**: everything still standing stays the old stone, and only the 648 pieces that fell or broke are new wood.
  That costs 3,624 planks instead of 20,124. The page also gives the price of mending it in stone.
- `tools/dump_blueprint.gd` can now also write what one of each piece costs (a third path), so the page can price only the mended part.

**Mistakes and hurdles**
- In the all-wood version, the six middle floor triangles at the top of the keep fell down in the strength test. Wood loses 8% strength per storey up
  and 16% sideways, and the keep is 14 m tall. I first tried a post under the middle (twice, also one storey lower). That didn't help, because a post
  only carries the strength it gets from below. Fix: in the wooden version the small tower on the keep's roof stays stone,
  like the Lantern Spire's fire bowl.
- My first try at adding the posts didn't apply: my Python replace looked for plain line breaks, but the file has Windows line breaks. The Edit tool then found
  the same lines twice, so I had to give it more of the surrounding text.
- A long bash heredoc broke again ("unexpected EOF"), like last time. I wrote the pieces as files with the Write tool instead.
- A Python replace looked for two tabs of indent where the loop has one, so its check stopped it before anything changed. I fixed the text and ran it again.
- My first wood idea, the full wooden blueprint, didn't fit how the owner sees rebuilding a ruin. The page now shows the mend; the full blueprint stays
  for building it fresh somewhere else.

**Still waiting:** the owner's OK on the page before the in-game ruin and cave carving.
