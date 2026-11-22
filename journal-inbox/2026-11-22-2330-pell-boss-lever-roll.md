## Nov 22 (night): Old Pell's boss room, the floating lever (4th time), the roll, beetle charges, the rope pile

**What we did**
- **F732, the roll:** you can't be hurt from the first frame of the dodge roll to 0.40 s (before it was only 0.05 to 0.30 s, too short to feel). Only getting back up is open. New test.
- **F734, beetle charges** (you said mid-chat: "beetles no longer ragdoll u, and don't dmg u"): the game judged the charge hit at the very *end* of the run. By then the beetle had already shot 2-5 m past you, so it always "missed". Now the hit lands the moment the beetle runs into you. A test stands a dwarf still in front of both beetles and checks he gets hurt and knocked down.
- **F731, Old Pell's boss fight:** the Last Dig is 18 x 18 m now (was 14 x 16), with 2 Hollow Miners instead of 3. Skeletons (and every stuck dungeon creature) now only "jump home" when no player can see them or their home. Otherwise they keep walking. That was the teleport you saw when you ran into the mine and back.
- **F729 🔁, the lift lever (said 4 times):** found the real reason it always floated. The lift stands in the middle of the room, and its shaft's walls only start 4 m up, so there was no wall near the lift to hang a lever on. The lever now sits on its own wooden post (new model, lift_post) that goes from the floor up into the shaft's wall. Its spot is worked out from the shaft's hole by the script, not typed by hand. The new test checks there is something solid right behind *both* levers in the dungeon.
- **F730, the wood-and-rope pile:** the ropes were loose round rings. Now each rope follows the outline of the log pile (a rounded triangle) and presses a little into the wood.
- **test_poison_jabs_build_up:** the test was wrong, not the game. Since F594 a parry stuns the spider outright, and stunned monsters' hits miss, so its 5th jab missed. The test now clears the stun.

**Mistakes and hurdles (including Claude's)**
- **Hand edits in a generated file.** Old Pell's map file is made by a script (make_pell.py), but earlier fixes (F648, F650) typed new spots straight into the file. They were guesses: the lever ended up 2 m from any wall. The lift platform was moved *out of its shaft*, so it would have ridden up into solid rock. Fix: all changes went back into the script, and the file is rebuilt from it.
- **The script itself was broken:** a later change added a "pell_passage" (a path-finding-only space with no walls) to the map, and the script crashed on it. That is likely why people hand-edited. Fixed: the script skips it. The junk test also counted that passage as open floor; fixed the same way.
- **First idea for the lever (Claude):** I was about to move the lift shaft to the room's wall. Then I found the top level's gate needs exactly 4 m of shared wall, so moving the shaft would break the gate. I chose the post instead.
- **Blender pictures landed in the wrong folder:** building the post with a relative output path saved its two preview pictures in `C:\assets\models\dungeon\` (outside the game folder). The safety check stopped Claude deleting it. The owner can delete that folder.
- **A pickaxe decor bumped a wall torch** after the room grew. The script's own rule check caught it; moved 2 m along the wall.

**Found but not ours (other chats' recent changes, tests not updated yet):** test_dwarf.test_your_own_stun_meter (the stun now knocks you down for 1.2 s instead of the old stun), test_dwarf_fist (spin swing fists), two bat tests in test_monsters, and test_pell's dart plate test (fails on the old map too).
