## Nov 21: Hearth Manor (ruin 7), its 5 new brick pieces

**What we did.** The owner picked ruin 7: Hearth Manor, built in Hearthbrick (brick, sloped roofs). Their wish after the
Twin Gate was "more roofs and some balconies", so the plan is a big hall, two wings, a gatehouse porch, a back
kitchen and a tall corner tower with a balcony all round it, about 12 roof sections at 4 heights. Hearthbrick had no
pieces for balconies or roof windows, so first came 5 new pieces (script `tools/asset_forge/builds/hearthbrick_v2_manor.py`):
a brick **bracket** (corbel) that holds up a jutting floor, a **trim band** (cornice) and its **corner block**, a
**1 m railing** for a balcony's short ends, and a **roof window** (dormer) that sits on a steep roof. They are shown
on a 3D page, alone and on a little test house (`tools/ruins/make_manor_pieces_page.py`, `manor_pieces_page.html`).
They stay in `journey/hearthbrick_v2/glb` (not game pieces) until the owner OKs them.

**Mistakes and hurdles (Claude's own).**
- The roof window first came out 78 cm too low out of its box. Cause: its ridge's mortar strip had its points
  turned into Blender's coordinates twice (the helper already does it). Fixed by passing the points straight in.
- The little gable halves on the roof window were told to build 12 brick courses in a 58 cm wall; set to 2.
- The model checker needs the full `.glb` path for test models outside the game folder.
- The page photo was checked locally with headless Chrome (two rounds: whole page, then close-ups of the roof
  window and the brackets), both fine.
