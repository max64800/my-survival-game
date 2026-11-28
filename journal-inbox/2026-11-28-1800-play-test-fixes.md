## Nov 28 — Play-test fixes F945–F965 (snail bodies, last hits, cave trees, shields, leather, tea)

**What we did:** We worked through the owner's Nov 28 play-test list and wrote down every new item, so none of it gets lost (F952–F974).
- **F945:** the last hit on a boulder or a root tree now gives 2× what one normal hit gives, as a small reward for finishing the job (owner picked "about 2× one hit").
- **F946–F950:** these were fixed and moved to the done list (see their lines in `FEEDBACK-done.md`).
- **F948:** root trees in the cave no longer hang in the air. `src/art/root_pillars.gd` now checks the ground under 12 points around the foot of the tree. If the inner ring has no floor under it, the tree is not placed. The foot is checked again up to 3 times.
- **F957:** a cleared cave now waits 10 minutes from your *last* kill before snails come back. Before, the timer started when the snails came. If one of your stations is within 45 m, the wait is 30 minutes (`src/combat/monster_manager.gd`).
- **F958:** the Wooden Shield is made at the Workbench again.
- **F960:** finished leather waits in front of the Tanning Rack, not inside it.
- **F963:** new **Moss Tea**: 2 moss plus a skin of pool water, made at the campfire. You know it from the start. It gives 5 sips of +40, and you keep the waterskin (owner's pick).
- **F964:** bats now drop a fang 75% of the time (it was 40%).
- **F965:** the Crystal Torch is now in the Tools tab.
- Each fix has a test (test_authority, test_monsters, test_armoury_bench, test_menu, test_cave_floor).

**Mistakes and hurdles:**
- **F948:** the first tries still left trees hanging. The test measured from a different height than the game used when it placed the tree. A lower starting point could also reach in under a rock overhang. The fix was to measure from the same spot in both, and to check the foot again in a loop.
- Two of the cave-tree tests (seed 2024) fail even with Claude's change switched off. The cause is another chat's change to the cave maker, so Claude left them alone.
- **Claude's helper script** that saves only its own lines of a shared file failed when given patterns with special symbols (`\|`, `\.`). It needs plain words.
- Godot could not work out the type of two new variables (`flat`, `had`). That one mistake made *every* monster test fail with "monsters is Nil". The fix was to write the types out (`var had: bool = ...`).
- The boulder test expected 7 but got 14, because the test dwarf holds a pickaxe (2× per hit). Claude fixed the test, not the game.
- The first Moss Tea test didn't load, because it called a check that doesn't exist. Claude switched to the real `Recipes.is_unlocked`.
- Two commits ended up with the same name ("Claim F957…"), because the first commit's message was hidden from Claude. This is harmless.

**Still open:**
- **Sounds:** F944, F951, F934 and F937 are waiting for a sound-round chat.
- **Other fixes:** F952–F956, F959, F961, F962, F967 and F968.
- **Map talk:** F969–F974 (navigation, ruins side by side, world size, one place per cave, tutorial dungeon) are to be talked through with the owner before any cave change.
