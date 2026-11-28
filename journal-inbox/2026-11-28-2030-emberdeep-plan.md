## Nov 28 — F982: Dungeon 10, Emberdeep Forge, planned

**What we did:** The owner asked to plan dungeon 10. Plan only, nothing built yet. The owner picked everything from
multiple-choice questions, and the choices went into `docs/design/zone1-dungeons/2026-11-28-emberdeep-decisions.md`.
- **Owner's picks:** sooty but solid brick (whole, blackened, the deep furnace still glows); skeletons plus a NEW
  Slag Thrower (a skeleton smith that lobs hot slag, reusing the Rune Caller's throw); the boss, the Forge Foreman,
  with a Molten Pour (he pulls the furnace chain, glowing metal runs into floor grooves, you jump onto raised anvil
  blocks, then hit him while he is tired); all six planned forge traps (rolling anvil, molten channel, swinging
  crucible, tipping braziers, swinging anvils, push wall into slag); the press and ore carts are kept for #11/#12;
  the way out is the old ore lift up to the barred gate at the entrance.
- **The map:** 70 spaces on the 2 m grid over 3 levels going DOWN, 92 x 72 m. Four build steps, each playable.

**Hurdles and mistakes:**
- **The map kept running out of room.** My first tries kept each level in its own patch of ground (no room under
  another room), and the stairs kept landing inside other rooms. Fix: I checked the older dungeons with a small
  script and found Hald and Brassgate already put rooms under rooms, with 3 m of rock between. So I set the levels
  10 m apart (0, -10, -20) instead of the plan's 8 m: then a room up to 7 m tall fits under another one. After that
  the map fitted, and the script found no two spaces crashing.
- **The plan's recipe was out of date:** the room list said a copper weapon, but `DungeonList` says Bronze Mace.
  DungeonList wins; the decisions file says so.
- **The Slag Thrower depends on Orrin step 2** (the rune bolt isn't built yet), so its throw is build step 3 here.
- A shell command was stopped once by the safety check because RTK changed it; running it again as given worked.
