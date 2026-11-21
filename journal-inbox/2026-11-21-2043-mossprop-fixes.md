## Nov 21: Mossprop Workings, fixing the first play (F526, F539-F548)

**What we did.** The owner played dungeon 4 for the first time and left 11 notes. All are fixed:
- **The Prop Warden (F547, F548):** his shield now shows, held up in front while he walks and stands guard (a small
  bone helper, `ShieldArm`, holds his left arm in the "Block" pose on top of his other moves). He got his own Shield
  Charge, so he no longer fights like the Pit Boss. Health down to 300. His Plank Sweep now comes at random.
- **Lost Miners (F526):** a short leap in, no chop after it (the owner's pick).
- **Cave feel (F539):** about 100 stalactites in clumps, 70 rock lumps on the walls and the roof edge, and 14 rock shelves
  with moss hanging off. They are all "grown" by the dungeon's Python maker, which keeps them clear of anything built,
  of the rope slide, and of 2 m head room over every floor. A new test checks this using each model's real size.
- **Miners moved (F540, F542):** down to the rats, and in front of the boulder.
- **Ladders (F541, F546):** every ladder now ends level with the floor you step onto (the game now knows each
  ladder's own height, so big ladders work). The upper ladder got a walk-round on deck 2 so you reach its front, and two
  rows of wall spikes on its right with a gap between them. They sleep until you come near, then stab for good.
- **Trap floors (F543):** 6 rotten boards on level 2 and 3 on level 1, never two in a row, always one safe way along.
- **Spear wall (F544):** an old stone wall boxes in its back.
- **Invisible wall (F545):** the mine arch had one big solid box over its whole shape. Now only its two posts and the beam
  are solid.

**Mistakes and hurdles.**
- **Claude:** the shell here turns `\\` into `\` inside "heredoc" scripts (text pasted straight into a command), and one
  with a backslash at a line end broke completely. Fix: write the patch script to a file first, then run it.
- **Claude:** almost used the cave's `boulder_*` rocks as decoration. The game turns every `cave/boulder_*` model into a
  breakable boulder, so the cave would have filled with things you can mine. Used the `grock_*` and `shelf_*` rocks.
- **Claude:** the first walk-round to the ladder was too narrow (0.45 m of space for a 0.72 m wide dwarf). Fixed by adding
  two deck squares and taking away two rail pieces.
- **Claude:** the new cave test found one big rock poking into a floor's head room. The Python check treated each rock
  as a square that never turns, but the rocks are turned and tilted, so their corners reach further. Fix: the check
  now uses 1.42× the width (the diagonal of a square) plus 30 cm.
