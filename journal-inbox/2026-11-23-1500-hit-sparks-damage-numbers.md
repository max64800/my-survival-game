## Nov 23: hit sparks (F717) and damage numbers (F788)

**What we did:** When you hit a creature, little bits now fly out from the exact spot you touched it. Each creature throws its own kind of bits: rock critters throw sparks and grit, skeletons throw bone-white bits, ghosts puff blue wisps, spiders splash green goo, everything else splashes red. Crits throw more and add a bright flash. Damage numbers now pop big in a split second, then shrink and fade while floating up. Big hits are bigger; crits are even bigger, red, with a "!".

**Hurdles:**
- My first tests said the bits were "not in the tree". Particles must be added to the world before you can ask where they are. Fixed the test.
- Test runs failed at first because Godot isn't on this PC's path. Used the full path.
- `combat` test has one failure ("a brand-new tool shows its bar too"). It is in the durability bar code, not my files, so I left it for its owner.

**Not done:** bursts when the dwarf gets hit.
