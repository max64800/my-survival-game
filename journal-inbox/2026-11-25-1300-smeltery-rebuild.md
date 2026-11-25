## Nov 25: the Smeltery Terraces rebuilt to match the shape model (F845)

**What we did.** The owner had OK'd a richer shape model of ruin 10 ("much better"). Today Claude rebuilt the real
blueprint (`BlueprintLibrary._smeltery()`) from real Hearthbrick pieces to match it:
- a split grand stair, a wooden balcony across the hall's front on brick brackets,
- a 6-sided stair turret on the hall's front-left corner (ladder inside, railed lookout above the roof),
- a balcony wrapping round the chimney tower's front and right side, two carved stone spires on its top corners,
  and a square chimney with a cap: the tower is now about 23 m tall (the cave must be about 24 m there),
- a thinner round top and a railed deck on the furnace house, plus a small porch with a sloped roof,
- a wooden roof over the bridge and a brick pier with 4 carved columns in the dip,
- a 6-sided watch turret on the terrace's front-right corner.
1,328 pieces in brick (was 1,050). The ruin page was remade and republished.

**Owner's choice.** The shape model's tiny round turrets (under 2 m) can't be made from 2 m pieces. Claude asked; the
owner picked 6-sided turrets (3.5 m across) with ladders. The tower's corner turrets became stone spires instead.

**Mistakes and hurdles (Claude's own):**
- A long Python edit script typed straight into the terminal broke on its quote marks ("unexpected EOF"). Fixed by
  saving the script as a file first.
- The watch turret's floors were first put at the wrong heights (2.75 instead of on top of each storey's walls).
  Fixed by building it the same way as the stair turret: walls at 1.0, 3.25, 5.5 and floors 2 m above each.
- The furnace deck's inner railing sat exactly where the new furnace top's wall goes (two pieces in one spot).
  Replaced with one railing on the open side only.
- In the wooden version the new chimney fell in the strength test: wood gets weaker every storey, and 23 m is too high.
  Keeping only the top half brick still let the chimney cap fall. Now the whole tower and its wrap balcony stay brick
  in the wooden version; the rest can be wood.
- The ruin page's "what fell" rules didn't know the new parts: the bridge's roof would have floated over the fallen
  span, and the turrets counted as the tower. Gave each turret its own "how high it still stands", let the wood roof
  fall whole, and made railings go when the floor under them fell. A check found nothing floating afterwards.
- Chrome's debug link wasn't on, so the page screenshot was taken with headless Chrome instead.

**Tests:** smeltery design (both brick and wood: sound, nothing falls, every stair and door walkable) and all 19
blueprint checks pass.

**Next:** the owner looks at the page; after an OK the ruin goes in the game (chests, junk, beetles, cave shape).
