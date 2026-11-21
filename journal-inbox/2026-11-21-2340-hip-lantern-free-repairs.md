## Nov 21: Hip Lantern and free repairs (Claude 3, F562 + F568)

**What we did.**
- Claude asked the owner 4 questions first. The owner picked every suggested answer: an early hip hook, the menu
  stays at the Workbench/Anvil, upgrade prices stay the same, and Thrifty now makes gear wear slower.
- **F562 Hip Lantern.** A new lantern made at the Workbench (2 stone, 1 rootwood, 1 blue crystal, 2 leather,
  2 rope). It hangs from an iron S-hook and a leather belt loop on the dwarf's left hip, so both hands are free for a
  shield or a two-hander. It gives a bit less light (13 m) than the hand lantern (16 m), so the Back Lantern is still
  worth making. The hook and the item are hand-built in Blender (`items_gear.py hip_hook`) and pass the model checks.
  The lantern follows a new "hip" spot on the dwarf's pelvis bone. Lantern tooltips now say where each one sits.
- **F568 free repairs.** Repairing costs nothing now. The "Upgrade and repair gear" panel next to the bag at a
  Workbench or Anvil got a big "Repair all (free)" button. Looking at a bench now says
  "E: craft, upgrade, repair (free)", so the panel isn't missed. Thrifty: 10% less wear per rank (counted, not
  random). Crafting ★25: 10% cheaper upgrades.
- New picture tool: `tools/model_check/hip_lantern_shot.gd` (the dwarf with the Hip Lantern, front and side).

**Mistakes and hurdles (Claude's own).**
- The recipe first meant to use up your old lantern. But things you wear can't be used up in a recipe, so you would
  have had to take the lantern off first. Changed it: the Hip Lantern is made from scratch like a lantern, plus
  leather and rope.
- The first test put the lantern under the dwarf's feet: the hip bone only gets its real place after a few frames.
  Fixed: on the hip the lantern finds the belt again every frame (this also makes it follow the hips).
- The hook didn't show in the test at first. Godot hadn't imported the new model yet, and the test lantern kept
  moving itself back to the hand (there's no player in a test). Imported it and paused the lantern's own update in
  the test.
- First picture: the belt loop stuck out behind the trousers. Moved it 4 cm closer and level with the side.
- Two script text edits broke on a "\n" in the text (it turned into a real line break). Redone with the editor.
- The new icon is a cut-out of the Blender picture, not a ChatGPT-painted icon like the others.
