## 2026-11-28 — Brassgate Vault step 3: the three new traps (F975)

**What we did**
- Two new stone trap models, built in Blender by script (`tools/asset_forge/builds/dungeon_stonehold.py`):
  - `trap_crossbow_wall_stone`: a stone wall with a one-stone-tall guard slot. Inside it, a crossbow (wooden stock, iron bow, string) and a bolt that flies out.
  - `trap_push_wall_stone`: a stone wall with one big 2 m deep block in it and a dark gap all round it. The gap is the clue.
  - Both pass the model check.
- **Tripwire crossbow (Guard Corridor):** the old wire now fires the crossbow. It does 30 damage, more than a dart, but with no poison. `MineTraps.is_crossbow` tells the two apart.
- **Spike-hole chests (Treasury Corridor):** the two chests' spike floors have `on_open`.
  - Walking over them is now safe. Opening the chest unshot stabs you.
  - When a player opens a chest, `main.gd` asks the host (`ask_use`, which runs `request_use` → `_fire_spikes` with the opener) and everyone sees it, so it stays co-op ready.
  - Shooting the chest first still sets the spikes off harmlessly.
- **Push walls + coin chute:**
  - The Coin Chute's north half (x 44–50) has no floor now. It is an open chute 4 m down onto spikes, a new map space `chute_pit`.
  - Three push walls on the south wall shove you north into it.
  - `deadly = ["no_pit_yet"]` is finally `["chute_pit"]`.
- Four new tests in `tests/test_brassgate.gd`: crossbow, chests, push walls, and "only the chute kills".

**Mistakes and hurdles**
- **Claude:** the crossbow bolt's tip cone first pointed backwards (−90° instead of 90°). Blender's y is the game's −z, which is easy to flip. Caught it before building.
- **Claude:** the first bolt fins were a messy three-fin loop. Swapped for two simple crossed fins.
- Blender printed one "No mesh data to join" warning on the push wall. The export was still fine (both parts there) and the model check passed.
- **Design snag:** the walkway beside the chute is only 2 m wide, so you can't walk around the push walls. The way past is timing: set one off, jump back, then slip by while the block slides home (it can't fire again for a second after it's back).
- **Design snag:** the old chest spikes fire when you *stand* on them. The treasury floors cover most of the 4 m corridor, so with the old rule, walking past would have been a trap too. Fixed with the `on_open` flag.
