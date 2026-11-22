## Nov 22, 2026 — The Drifting Shade gets real detail, and the see-through ghosts stop tearing (Claude 3)

**What we did**
- Made a 3D page for the four dungeon ghosts with buttons to watch them attack, fade-and-jump, die into mist and spin (F643).
- The owner said the ghosts were "way too simplistic" (F642), so we're redoing them one at a time. The first one is the
  Drifting Shade (`ghost_a`). It is now an old miner's spirit with:
  - a rolled hood rim and soft creases, plus a long hood point drooping down its back;
  - a torn cape over its shoulders and a fold of robe wrapped across its chest;
  - a twisted rope belt with a knot and frayed ends;
  - a little ghost lantern whose glass glows, and a broken chain;
  - open cuffs with ragged hanging flaps and rag-wrapped mittens (no fingers, as the owner asked);
  - two crooked sewn-on patches, and torn strips and wisps curling off its misty tail.

**Hurdles and fixes**
- **The page refused .glb files.** Fix: each model is turned into a .json copy of itself, and the page reads that.
- **The ghost looked crumpled on the page.** A plain copy of a model doesn't carry its skeleton along. Fix: copy it with the skeleton tool (SkeletonUtils).
- **The "Summoning…" label never went away.** A style rule kept showing it even when it was set to hide. Fix: added a rule that really hides it.
- **The new shoulder cape first came out as a fat ring.** Fix: it is now a 2.5 cm layer laid over the body's own shape.
  - That layer then also swallowed the hood's rim. Fix: the cape now stops below the hood.
- **The hood creases looked like knife cuts.** Fix: wider, shallower dips.
- **Claude's own slip: one script edit failed twice.** The indents were one tab deeper than the file really had.
- **The see-through body tore into shreds where it folds over itself.** The extra detail made this much worse. Fix: a "depth first" pass (`src/art/ghost_depth.gdshader`):
  - an invisible copy of the ghost is drawn first, 4 mm further back;
  - this marks which surface is in front, so the real ghost paints only its outside.
  - The page and the game both use it now.
