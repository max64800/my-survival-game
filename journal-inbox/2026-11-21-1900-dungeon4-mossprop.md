## Nov 21: Dungeon 4, Mossprop Workings (a rotten timber tower to climb)

**What we did**
- Planned the 4th dungeon with the owner. They picked skeletons again (Tunnel Rats + Lost Miners), a small dungeon
  with 3 levels, a timber prop tower as the showpiece, and a new boss: **the Prop Warden** (F468: every mine its own boss).
- Map (`DungeonMap.MOSSPROP`): one tall "great cave" (16 m high) with Base Camp at the bottom, a lower walk on pillars,
  two decks at 5 m and 10 m, little rooms off the decks (prop room, store shed, vault, climbers' rest), a chasm that
  kills, and a top hall where the Warden waits. New worlds (layout 17) get it; older saves stay the same.
- Plan made by script (`tools/dungeons/make_mossprop.py` → `blueprints/dungeons/mossprop_workings.json`): 255 pieces,
  661 props, 14 creatures, 6 chests, ladders, traps (swinging boulder, spikes, crushers, darts, spears, a gate and lever).
- New models in `dungeon_rootwood.py`: rotten prop post, sagging beam, cracked brace, and the rope slide.
- **Owner said "it looks too perfect" (F536):** most posts, beams and braces are now rotten ones, some braces are
  missing, railings broken or gone, three deck floors fell through, and broken boards lie everywhere (about 570 rotten bits).
- **Owner asked for a way back down (F537):** a rope slide. E at the top post → the dwarf slides down the rope to Base Camp.
  Co-op ready: request → host checks you're at the top post → only your own dwarf slides.
- Prop Warden: a boss with a plank shield. Hits from the front do only a fifth (and show "Blocked!"); heavy swings and
  hits from behind go through. He uses the Pit Boss body for now.
- Dev menu: "Dev: Dungeon 4" button and the `dungeon4` start word for test worlds.
- Tests: `tests/test_mossprop.gd` (it appears in new worlds, the placement rule (nothing grows inside), the plan, ladders,
  only the chasm kills, the rope slide, the Warden's shield).

**Mistakes and hurdles**
- Normal-size doorways looked tiny in a 4 m opening. Fixed: every doorway is 1.5x, with narrow walls beside it. Some rooms had to grow.
- Two rooms sharing a wall each built their own copy (shimmer). Fixed: each wall edge is built once, by the taller room.
- Claude first made a 3D page for the dungeon. The owner said dungeons need no page, just "it's built, go test it". Now a memory rule.
- The rope slide first left the dwarf's feet floating. Fixed: he hangs a bit lower at the end, so his feet land 0.15 m over the floor.
- Test mistake: Claude checked a model list that doesn't exist (`MonsterModel.MODELS`), so the test file didn't compile. Removed the check.
- Test mistake: "you land in Base Camp" failed because Base Camp sits inside the big cave, so the map answered "great cave".
  The test now checks the landing spot directly.
- Claude couldn't find Godot at first (it isn't on the PATH on the PC). Its full path is in the godot MCP settings.
- The first test game crashed at start with "out of memory" while the full test suite ran at the same time (only 5 GB free).
  Retried after the tests finished.
