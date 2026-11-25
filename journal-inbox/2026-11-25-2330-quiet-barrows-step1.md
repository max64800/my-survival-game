## 2026-11-25: The Quiet Barrows, step 1 (F906)

**What we did**
- The owner chose dungeon 6. It has ghosts and spiders. The boss is a rune ghost, the Barrow Keeper, and he holds the Barrow Key. Each of its 3 levels looks older than the one above.
- The map (`DungeonMap.BARROWS`) has 3 levels, at 0, -8 and -16 m:
  - Two stair flights wind round an old shaft.
  - A chasm with a stone bridge.
  - The King's Barrow, and behind a locked gate, the King's Grave.
  - The Air Shaft has a ladder all the way up to an exit ledge over the front door.
- New generator `tools/dungeons/make_barrows.py`, built from make_hald.py. Its old 2-level rules (stair tops, doorways, decor, junk) now work for 3 levels.
- Reused traps:
  - falling stones and bear jaws
  - a spiked chest and a dart plate
  - a hidden boulder and two swinging boulders
  - spear walls and chasm spikes
  - a healing basin and a recipe stand
- Wall wear goes up per level: 10% broken on level 1, 30% on level 2, 35% on level 3. Ceiling holes go up too.
- New monsters: the Barrow Warden (a strong ghost) and the Barrow Keeper (the boss). For now he fights with the ghost boss's mace moves. His rune bolts come in step 2.
- A "Dungeon 6, The Quiet Barrows" button in the Dev menu, and a new test, `tests/test_barrows.gd`.

**Mistakes and hurdles**
- The decor check rejected many pieces: lamp alcoves on walk lines, loculus walls too near doorways, and a spider standing on a bone pile. Fixed by moving each piece. All the lamp alcoves were removed.
- My own test said a floor slab "closed" the ladder hole. It was only the ledge's own ceiling, above where you step off. The test was wrong, not the dungeon, so I fixed the test.
- Another chat is changing the dungeon recipes from copper to bronze in the same files (items.gd). Brickcrown's chat has lines in main.gd and cave_maker.gd too. I committed only my own lines and left theirs alone.

**Left:** step 2, the rune bolts. Step 3, the rolling boulder and the soft heap. Step 4, the roots, earth and moss polish.
