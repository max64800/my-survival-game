## Nov 22: Hitbox shapes built (step 1: shapes only) + preview page

**What we did**
- New `src/combat/hit_shapes.gd`: every dwarf, Shade and skeleton enemy gets body bubbles (head, belly, arms,
  thighs, shins). Weapons get a box on their hurting end, live only during the swing. Animals get simple
  boxes: beetle bite = mandibles, beetle charge = as wide as the beetle with its legs, bat = the whole bat,
  snail = head bite / spit bubble, spider = front third for the bite, all of it for the pounce. The
  heavy two-handed mace slam is a flat ring on the ground.
- F9 now draws them (green = can be hurt, red = hurting right now). Fights still use the old distance check; the
  shapes take over in the next steps, after the owner has looked.
- `tools/hitbox_preview.gd` takes a picture of every weapon and every creature attack at the moment the blow lands.
  The owner gets them on one page (artifact "Dwarf Hitbox Preview").

**Mistakes and hurdles**
- The owner spotted it first: the dwarf's bubbles floated far above him. The cause: his short, round dwarf shape
  is added by a "last step" (a SkeletonModifier3D) every frame, and bones read at any other moment are the tall,
  human-sized skeleton nobody sees. Fix: read the bones only in the skeleton's `skeleton_updated` signal, after that step.
- Then the bubbles were too thin for a round dwarf (belly and head stuck out). Fix: fatter head/belly bubbles and
  a higher head bubble, only on the dwarf's own skeleton (dwarves and Shades).
- Snail/beetle/bat boxes looked too big. I first suspected padded mesh bounds and then a size tween, and changed
  both (real mesh points; boxes now grow and shrink with the creature). But measuring showed the sizes were
  already right: a box drawn around a round animal just has empty corners. The changes are kept because they're safer.
- The Prop Warden's axe box was built with his plank-shield mesh mixed in and against a hand marker that hadn't
  moved yet. Fix: keep axe and shield apart, measure in the hand socket's own space. One wrong guess (scaling by
  the skeleton size) made it worse and was undone.
- The owner spotted the spear's red box sitting beside the spear. The box was measured the moment the spear
  was picked up, before the hand had finished lining it up. A box measured a few frames later was right. Fix: the
  weapon box is measured again at the start of every swing.
- `godot` isn't on the PATH on this PC: use `GODOT=<full path> bash tools/run_tests.sh`.

- The owner looked at the page and removed the snail's Shell Slam: it had no animation of its own. The snail now
  bites up close and spits from farther away.

**Next:** the owner looks at the page → the shapes take over the damage (dwarf weapons first).
