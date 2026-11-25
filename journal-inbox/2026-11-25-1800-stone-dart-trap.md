## 2026-11-25: the Tomb's dart trap turns to stone and iron (F853)

**What the owner said:** "The trap that has a string and shoots the dart, it's still wooden."

**What we did**
- Built two new models by Blender script in `tools/asset_forge/builds/dungeon_stonehold.py`, the same file as the iron gate and lever:
  - `trap_tripwire_wall_stone`: a normal Stonehold stone wall. A small round hole is drilled through the stone at hip height, with an iron ring and three rivets round it, a green poison drip under it and an iron eye low down for the wire. The hole is in exactly the same spot as on the wooden wall, so the game fires the bolt the same way.
  - `tripwire_iron`: a thin rusty iron wire instead of the white string, in the same two halves so you can still cut it.
- Both models passed the model checks first try, and one render looked right.
- Taught the game the new names (`mine_traps.gd` trap kinds, `dungeon_build.gd` collision boxes). Switched `make_hald.py` to them and rebuilt the Tomb.
- The wooden versions stay for the wooden dungeons (Lampwick, Mossprop, Pell).
- `test_stone_and_iron_not_wood` now also checks that the Tomb has no wooden dart wall or string, and that the new ones work as a dart wall and a tripwire. The Tomb's existing "walk into the wire, get hit by the dart" test still passes.

**Mistakes and hurdles**
- The old "no wood in the Tomb" test only looked for "wood" or "plank" in model names. `trap_tripwire_wall.glb` has neither, so the wooden trap slipped past it. The test now names the wooden trap models one by one.
- The hole landed on a joint between two stones. Drilling every stone near the hole (not just one) fixed it, and the iron ring covers the joint.
