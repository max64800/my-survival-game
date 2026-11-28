## 2026-11-28 — Junk in the grand ruins (F976)

**What we did**
- Seven more ruins now have floor junk, wall decor and an old camp outside, like the first four:
  - **Cliff Galleries:** house junk.
  - **Smeltery:** forge junk, smiths' racks, a broken anvil and bellows.
  - **Pillar Spiral:** house junk, kiln bits in the Kiln House, and a broken shrine at the Rock Shrine.
  - **Manor:** house junk, kitchen shelves, a fallen chandelier, a woodpile and a wheelbarrow.
  - **Prow Hall and Twin Gate:** soldiers' junk, weapon racks, a split war drum, a fallen shield wall and a broken cart.
  - **Mine-head:** miners' junk, lamp and rope racks, a broken ore crusher, a derailed cart and a coal pile.
- Each ruin kept the furniture it already had. The junk keeps clear of that furniture, the chests, the doors, the stairs and the way in.
- Each ruin was checked in a muted, marked test game. Every piece showed up, except for one outside spot at the Smeltery that wasn't flat enough.
- The tool (`tools/ruins/ruin_junk.py`) learned a few new tricks:
  - an "area" filter, so kiln and shrine pieces stay in their own building;
  - "yard_floor", for a yard dug lower than the cave floor;
  - DBG=1 prints why spots were turned down.
- The game puts outside junk on the cave floor near the ruin's own ground height, not near zero.

**Mistakes and hurdles**
- Cliff Galleries, Smeltery and Mine-head first got **no outside junk at all**. The box I drew for "the dug yard" started past the place where the junk can hug a wall, so no spot fitted. I fixed each one by reading where the building's front edge really is and starting the box there. Lesson: draw the yard box from the foundation's front edge, not from the dig code's numbers.
- Pillar Spiral lost 9 outside pieces in the game. Its yard is dug 1 m lower, so the game thought they were floating. I added "yard_floor", and the test now accepts a foundation up to 1 m above the junk.
- My first Pillar decor landed anywhere at the right height, so kiln things ended up in the wrong house. I fixed that with the area filter.
- Twin Gate failed two tests. A wall map hung where two floors overlap (I limited it to the low floors), and it had 9 catalogue pieces when the test wants 10 (I added a spear rack).
- `only=test_ruin` matched lots of slow tests and timed out. Use `only=test_ruin_junk`.
- `git pull` refused because other chats had unsaved changes in the folder. I used `git fetch` and `git merge` instead (never stash).

**Left**
- **Brickcrown:** its game files are still not committed by its own chat (since Nov 25), so its junk waits.
- **Kiln:** it has a plan but no game version, so it has nowhere to show junk yet.
