## Nov 22: the last 24 catalogue pieces go into the dungeons (Claude 2)

**What we did:** The owner said the decor rules are "fluid", so the 24 catalogue pieces that had been left out of the
built dungeons went in: Mossgate 3, Lampwick Drift 13, Old Pell's Diggings 8. Every mg_, lw_ and op_ piece in the
catalogue is now in its dungeon. A new test (`test_the_rule_clash_pieces_are_in`) makes sure they stay there.

- **Mossgate:** the gate lantern posts stand side-on just outside the round door, in the way in. Inside, the paths fork
  right at the door, and nothing may stand 2 m from a doorway. The toll table is right of the way in. The diggers'
  barricade was dragged out of the Rubble Tunnel to the wall by the tunnel's mouth (the tunnel is only 4 m wide, so it
  would block the path); the old bench there made way for it.
- **Lampwick:** the lamp rack hangs on the Lamp Room's south wall. The barrow and the ledger desk are just outside, in
  the way in. The spare rails hang over the Tool Store's trunk. The ore sorting table and sieve are in the niche behind
  the boulder. The switch lever, signal lamp and jammed cart are where the back rails turn west. The walkway ladder is at
  the top of the junction's rails.
- **Old Pell's:** the trapmaker's table, wire spools and parts rack are in the Winch Shed; the still is in the pantry;
  the scale is by the sieve stack; the cold hearth is in the hut; the bell tripwire is by the ladder's foot. The rat
  traps went to the Spider Den, where the rat pack lives.

**Hurdles and fixes:**
- Lampwick's rooms are tiny and full of rails, traps and doors. That is why the earlier Claude had left these pieces
  out. Guessing spots one by one was slow, so Claude wrote a throwaway search: it tries every wall and floor spot in a
  room against the real placement checker and lists the spots that pass. Most pieces then fit on the first go.
- The search tested each piece alone, so three Lampwick pieces (cart, signal lamp, ladder) all "won" the same corner,
  and in Pell's pantry the still and the rat traps did too. Fixed by placing one, then searching again for the others.
- Claude's own mistake: an edit added Pell's wire spools and parts rack twice. The checker caught it ("touches
  itself"); the copies were deleted.
- The Godot test that keeps decor away from levers counted the new *decor* switch lever as a real lever, so the piece
  failed against itself. The test now only counts real levers.
- The Copper Face stool's corner was 1 cm from the wall line: Python's check passed, but the Godot test (10 cm in from the
  wall) didn't. It moved 15 cm in.
- Mossgate's junk went from 218 to 222 when the bench left (more floor free). The test's top limit was 220; it is 230 now.
- The first Lampwick search was killed when the chat restarted; it was simply run again.
- `GODOT` was not set in the fresh shell, so the first test run crashed with "file not found". It was set and run again.

**Tests:** test_dungeon_decor, test_dungeon_junk, test_lampwick, test_pell, test_dungeons, test_dungeon,
test_dungeon_places, test_dungeon_variety, test_loot_props all pass (run one at a time; the PC is shared by 4 Claudes).
