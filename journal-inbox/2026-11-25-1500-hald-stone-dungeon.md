## 2026-11-25: The Tomb of Hald becomes a dark stone dungeon (F856-F860, F862, F863)

**What we did.** After the owner's Nov 25 play test, the Tomb of Hald got its own stone and iron versions of the models it
had borrowed from the wooden mines. The wooden dungeons (Mossgate, Lampwick, Pell's, Mossprop) keep theirs.
- New build script `tools/asset_forge/builds/dungeon_stonehold.py` with five Hald-only models: a stone entrance
  (the Stonehold round door between two stone pillars, a three-stone lintel, carved marks), an iron way-out gate, an
  iron and stone lever (its "handle" still turns about the same pivot), a stone cracked wall (stones knocked out, a
  broken one jammed in, chips on the floor; it falls apart in pieces when hit) and a stone spike floor round the
  hoard chest (flagstones with bored holes and iron rings, the same spikes).
- The portcullis lost its rust-brown tint (it read as wood): plain dark iron now.
- Each new model has its own collision boxes (F847) and the game knows what each one does (gate, lever, breakable wall,
  chest spikes). `make_hald.py` uses the new names.
- F860 🔁, darker: this time light, not junk. A "tomb" mood inside Hald (Ambience: the soft room light 0.06, was 0.4,
  cold grey), 30 torches instead of 48, each dimmer (0.9, was 1.6) and shorter (6.5 m, was 9). Set on the Hald map
  (`mood`, `torch_energy`, `torch_range`), so the other dungeons stay as they were.
- `dungeoncheck` robot: `views=hald` (three Hald rooms) and `dark` (no work light) for before/after pictures.
- Tests: `test_stone_and_iron_not_wood`, `test_the_tomb_is_dark` in tests/test_hald.gd.

**Mistakes and hurdles.**
- The portcullis "looked wooden" because of one rust-brown colour tint on dark iron. Removing the tint fixed it.
- The cracked wall's crack lines looked like grey sticks. A thinner, darker try didn't help, so after the second
  picture round they were removed: the knocked-out and bulging stones show the crack instead.
- The model checker found a few shimmer spots (two surfaces in the same place: pillar feet, carved marks, gate bars
  on the rim) and one floating chip. Fixed by moving each part a few millimetres.
- Halving the torches made the plan maker crash: with fewer torches a piece of junk tried a spot with no floor height
  (a stair group). Fixed: it falls back to that level's floor, and the old filter still keeps junk off stairs.
- The first "after" picture was taken too early: the room mood fades in over a few seconds. The robot now waits 4 s.
- `git pull` was blocked by other chats' unsaved files. No stash: worked on, then pulled before pushing. Shared files
  (`dungeon_build.gd`, `mine_traps.gd`, `CREDITS.md`) also held other chats' unsaved work, so only this chat's lines
  were committed.
