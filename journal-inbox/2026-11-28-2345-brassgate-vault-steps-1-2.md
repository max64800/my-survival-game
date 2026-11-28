## Nov 28, 2026: Dungeon 7, the Brassgate Vault (F975), steps 1 and 2

**What we did**
- The owner had three other Claudes busy (early-game fixes, the no-armour dwarf, the last ruin), so this chat started
  the next dungeon. Owner's picks (multiple choice): lost miners up top + ghosts in the old mint below, the Vault
  Captain (a big armoured lost miner with a big shield) as the boss holding the Vault Key, three new traps (push wall +
  coin chute, tripwire crossbow, spike-hole chests), and a grand + brass look. Pendulum blades weren't picked, so the
  Pendulum Hall became the Swinging Hall with the Barrows' swinging boulders.
- Step 1: the map (`DungeonMap.BRASSGATE`: toll halls at 0 m, the mint 8 m down, two stairs), the plan maker
  `tools/dungeons/make_brassgate.py` (built on Hald's), the blueprint (1752 pieces, 19 creatures, 10 chests),
  the reused traps (dart plate, coin-press crushers, swinging boulders, hidden boulder, portcullis, cracked wall, loose
  stone), the Strongroom's Vault Key door, the barred way-out gate + lever, the recipe stand (the Captain's scroll:
  bronze axe), and "Dungeon 7, Brassgate Vault" in the dev menu. Tests: `tests/test_brassgate.gd`.
- Step 2: the Vault Captain got his own model (`kaykit_miners.py`, "vault_captain"): brass-painted armour, a red guard's
  coat, a brass helm with a crest and nose guard, and a tall oak shield faced with brass plates and a lock-face boss.
  His shield still blocks from the front, but now he lowers it after every swing and after his charge
  (`shield_drops`, `CreatureRig.lower_shield`), so you hit him then or from the side.

**Mistakes and hurdles**
- The ghosts died the moment they appeared in the stair tests. Cause: I set the map's "deadly rooms" list to empty,
  and an empty list means "every room under 0 m kills" (`DungeonBuild.deadly_space`). Fix: a name no room has
  ("no_pit_yet") until the Coin Chute's spike pit comes in step 3.
- The Captain had the Prop Warden's Rally Slam (raise fallen miners), but the Vault says no raising. Took it out.
- Twice a long Python script inside a bash heredoc broke ("unexpected EOF"). Fix: write the script to a file first.
- Two older tests fail that aren't from this work: `test_skeleton_miners` still expects the Pit Boss to have one
  attack (F679 gave him a second), and `test_ghost`'s mace-jump check fails with another chat's unfinished ghost.gd.

**Left:** step 3 (tripwire crossbow, spike-hole chests, push wall + coin chute) and step 4 (brass polish, coins, junk).
