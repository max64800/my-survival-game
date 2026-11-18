# Video ideas

Stories from building the game that would make good videos. Newest at the bottom. Each one: what went wrong, why,
and how it was fixed, in plain words.

## Ragdolls and the jitters (Nov 18, 2026)

The owner asked: when a creature is defeated, make it a ragdoll (go limp and fall like a real body). Tried on the
Rock Beetle. Six tries:

1. **Every part its own physics object, held on by joints** (like a puppet on strings). It worked in the numbers, but
   in the browser every leg, horn and mandible jiggled "like a million times a second". Why: each joint pulls its
   leg back toward the body, the leg bumps the floor and the other legs, the joint pulls again... all of them fighting
   each other many times a second, so they shiver instead of settling.
   - A side story: the first time, the beetle shot off at 40 m/s (about 140 km/h). Measured it: a push given in the
     very moment the body is created ignored its weight (20 kg), so it flew 20 times too fast. Fixed by giving it a
     starting speed instead of a push.
2. **One solid body that falls, and the legs relax by themselves** (eased, no joints). No more jiggle. It slumps, its
   legs spread, and killed mid-charge it flies on. But the legs swung up into the shell.
3. **Flip onto its back with the legs curled like a dead cockroach.** It worked, but the owner preferred the fall.
4. **Back to the fall, legs spread outward and a little down** (flat out from the body, under the shell's edge), and
   the eyes close. A test now checks no leg turns up into the shell.
5. **Legs flatter**, tipped down until their ends touch the floor. But a leg was one stiff piece, so it couldn't
   lie flat AND hold the body, and the shell sank into the floor (its invisible box was a bit too small).
6. **Knees**: each leg was cut in two at the knee. The upper leg reaches down to the floor, the lower leg lies flat.
   The owner drew it on a screenshot. The first cut failed: the model is made of hundreds of loose little faces, so
   "keep the lower pieces" grabbed half the leg up to the hip. Fixed by giving each face to the nearest bone.

Good video beats: the 40 m/s rocket beetle; the jiggling legs; the cockroach; why "fewer moving parts" won; the owner's drawing that showed the knee.


## The beetle that knocked the dwarf out of the world (owner, Nov 18: "save that video, it was amazing")

Recording: `Videos\Dwarf Game Recordings‚6-11-18 19-20-31` (marked KEEP). The dwarf could walk right through a Rock
Beetle (it had no body for players to bump into), and when its charge hit him he fell through the floor and out of
the map. Funny clip; then the fix (the beetle gets a solid body, and a fall out of the world puts you back on the floor).
