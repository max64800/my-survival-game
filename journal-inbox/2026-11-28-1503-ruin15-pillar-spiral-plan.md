## Nov 28 — Ruin 15 plan: the Pillar Spiral (F942)

**What we did**
- Claimed F942 (next free number) after checking git log, FEEDBACK files and other running chats: nobody else was on a new ruin.
- Read the grand-ruin recipe, the ruin rules and the cave/tower memories, then gave the owner 3 ideas. The owner picked
  the **Pillar Spiral** with **stone + brick + wood** (the first ruin using all three).
- Wrote `docs/design/ruin15/PILLAR-SPIRAL-PLAN.md`: a stone Ring Hall round a giant rock pillar, wooden stairs that wind
  up round the pillar, four houses each a storey taller (Lamp, Store, Bunk, Bell Tower with the Eyrie and best chest),
  an Arch Bridge to a Kiln House on a rock lump, and a Shrine Bridge to a Rock Shrine dug into the cave wall.
- Made the simple block page `docs/design/ruin15/pillar_spiral_shapes.html` (copied from the Sinkhole Ring page),
  photographed it in headless Edge on port 8947, and published it for the owner's OK.

**Mistakes and hurdles**
- Adding the page's body with a shell "heredoc" (a way to paste a long text into a file) broke on the apostrophes in
  the text, so nothing was written. Fix: wrote the body as its own file with the Write tool, then joined the two parts.
- First photos: some name tags sat on top of each other (Bell Tower over Lamp House, Store House over Rock Shrine).
  Moved them.
- The "Close on the spiral" camera first hid the stairs behind the Bell Tower, then (moved to the back) ended up inside
  the cave wall. Fix: it now looks down from above-right with the ceiling hidden, so the stairs show between the houses.

**Owner's verdict:** "I love it" — shapes OK'd.

**Left to do:** the real blueprint (plan "Steps" 2-5). Open question for the build chat:
a natural rock column this big may be rare (grow one, or a thinner pillar).
