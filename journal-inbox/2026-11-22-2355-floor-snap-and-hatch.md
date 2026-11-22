## Nov 22 (night, PC): triangle floor snap and the floor hatch (F722-F727)

**What the owner said:** remove the floor hatch (nobody uses it, a dwarf can't fit). The triangle floor beside a
foundation snaps "midway". Add dust when building, different per material. The Clay Brick Triangle Foundation looks
like an old model. Furniture shows as a box and only turns 90°. A spawn spot should become a pad as soon as it's placed.

**What we did**
- **Floor hatch hidden (F722):** moved to the hidden "legacy" group, like the old diagonal pieces, so old saves and
  the gate building's murder holes still load.
- **Floors line up their tops (F723):** a floor or foundation placed beside another lined up their **bottoms**. A
  foundation is 1 m tall and a floor 25 cm, so the floor sat low. Now the tops line up (square and triangle pieces).
  Test: `test_floor_beside_a_foundation_is_level_with_its_top`.
- Logged for later: F724 build dust, F725 the brick triangle foundation model, F726 furniture outline + free
  turning, F727 the spawn pad.

**Hurdles**
- Still can't start the game: another chat's half-finished `src/ui/hitbox_debug.gd` (line 375) doesn't compile and
  takes `main.gd` down with it. Left alone (not my file); asked the owner.
