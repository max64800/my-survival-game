# The creature recipe (learned on the Rock Beetle, Nov 15, 2026)

The owner asked: "save all of these rules, so when we replicate it to the other creatures, it's going to be similar."
Every creature (Rock Snail, Cave Bat, and later ones) follows this page. It sits on top of `CREATURE-STYLE.md` (what the
pictures are) and `MODEL-RULES.md` (hand-built only, no shimmer, nothing floating).

Part 1 is the owner's rules in plain words. Part 2 is how we do each one (the tools and the numbers that worked).

## Part 1: the owner's rules

### How we work
1. **One creature, one look first.** Make the mossy one great before making four.
2. **Quality over speed.** Take the time and the tools it needs.
3. **Grey shape first, then paint.** Check the shape with no colour, next to the approved picture, from the same angle.
4. **Show it in 3D** (the creature page) after every round, with a picture next to the approved one and an honest score.
5. **No simple glued-on shapes.** It must look sculpted and seamless, never like toy blocks stuck together.

### Shell and armour (stone plates)
6. **The stones touch.** No gaps and no see-through between them. Where two stones meet there is only a small rounded
   "canyon" (a dimple), with moss in it.
7. **The shell is round** from head to tail and covers the body, like a dome, not a flat lid. **Its bottom edge curves**
   (low over the legs in the middle of each side, higher at the head and tail) and the dome rounds under; never a flat cut.
   Wide and low, like a little tank. **Horns are flat-sided** (a cut stone slab), big is fine.
8. **Every stone looks worn and different:** its own shade (some warmer, some cooler, some darker), **big scratches you
   can see from far away** (it's a big creature), chipped and lighter worn edges, darker grime. Never all one smooth colour:
   a **clearly visible mix of shades** (like the stone foundation), and every creature that spawns a little different.

### Legs
9. **Armour segments overlap like shingles.** Each segment's lip covers the start of the next one, so you never see a
   joint. **No two segments alike:** each a little thicker or thinner, twisted, uneven, chipped, cracked and scratched.
   Legs are **fat** (thick segments) so it looks heavy and strong. Keep the randomness gentle: big twists make the
   overlapping lips at the knee crumple into a mess.
10. **One claw per leg.**
11. **It stands on its legs.** The foot has a flat sole; the claw comes out of the **front of the foot at sole level** and
    lies **flat on the ground** like a toe, ending in a point. Never under the foot, never a stilt it balances on.
12. **The body underneath is shingled too** (overlapping belly bands).

### Face
13. **Small and tucked in, never puffy, never smooth.** No big cheeks; the skin is rough armour (grooves, dents, pits),
    not a smooth cartoon face.
14. **No nose, no mouth.** The mandibles are the mouth.
15. **Eyes are clean painted balls:** cream white, a coloured iris with a dark outer ring (the Rock Beetle's is green),
    a black pupil and one white shine. A heavy lid and the brow come down over the top of the iris for the grumpy look.
    Nothing stacked on the eye that can poke through.
16. **Brows make a V:** lower on the nose side.
17. **Mandibles, not tusks:** pincers that grow out of the jaw, reach forward and curl in, flattened, with a few jagged
    teeth on the inner edge and one point. Not perfect: lumpy, a little different left and right, worn. The Rock
    Beetle's are grey, darker at the root.
18. **Feelers grow out of round holes** in the shell (on the beetle: the gaps between the horn and the brows), with
    a stone rim and dark skin at the bottom. Never just stuck on top of a stone.

### Glowing parts
19. **Glowing parts are detailed:** the amber is a cut gem (flat facets with bright edges), with cloudy depths and tiny
    bubbles inside, not one flat colour.
20. **Glowing parts hum:** a slow breath of light in and out (about one breath every 3.5 seconds). They blaze when
    the creature charges.

### In the game
21. **Test it in the cave**, next to the workbench, with lantern light (the art preview), not only on a grey background.
22. **It feels alive:** feelers or stalks sway, it breathes when standing, and big moves end with a little dust or stone chips.

## Part 2: how we do it (for Claude)

The beetle is the worked example: `tools/asset_forge/builds/monster_rock_beetle.py` (shape) and
`tools/asset_forge/sculpt_test_beetle.py` (sculpt, paint and bake), using `tools/asset_forge/creature_sculpt.py`.

| Rule | How |
|---|---|
| 3, 4 | `creature_fit.py` (outline match per view against a turnaround picture) and `creature_compare.py` (picture next to model, same angle). `creature_closeup.py` close-ups of the face, feet and glowing part every round. |
| 5 | **Sculpt and bake.** `melt()` (voxel remesh + smooth) turns glued pieces into one skin, `carve_*()` adds sculpted detail, `game_copy()` makes a light copy, `bake()` puts the paint and detail on it as pictures (colour + normal map). |
| 6 | Cushion plates: the dome is split into patches (nearest seed); each patch grows a little **past** its edge (`GAP = -0.014`) so neighbours press together; the cushion profile rounds each edge down into a V-canyon; moss is its own melted layer in the canyons (`carve_moss`). |
| 7 | The dome is a superellipsoid (`FULL = 0.86`), rounder than an ellipsoid, egg-shaped from above (`TAPER`). |
| 8 | `island_kd()` before melting + `tint_islands()` after: each stone gets its own shade (±13% light, some warm, some blue-grey). `paint_material(..., tint_attr="tint", scratches=1.0, scratch_width=2.2, grime=0.35, edge=0.5)`: each scratch is a pale line with a dark crease, also cut in as bump (baked into the normal map). **Painted scratches only on big parts:** on small ones (face, mandibles) the scratch lines spread into dark blotches. |
| 9 | `barrel()`: an 8-sided faceted segment that flares into a lip at its far end; the next segment starts inside that lip. Each segment gets random thickness, squash, twist, an off-centre lip and uneven facets (`wobble`); the sculpt carves dents, grooves and pits (`carve_chitin(grooves=, pits=)`) and the paint adds scratches and grime. |
| 10, 11 | One claw per leg as a loft lying along the ground: ring centre height = `GROUND + h`, so the underside is flat on the ground all the way; root tucked into the last segment; the ankle sits ~6 cm above the ground. The last 30% dips up to 1.6 cm (a hooked tip). |
| 12 | Belly bands (`belly_band{i}`): each flares at its back edge over the next. |
| 13, 14 | A compact head loft (half-width ≤ 0.22 for a ~1 m creature), no muzzle, no mouth. `carve_chitin(dents=0.0035, grooves=0.003, groove_scale=9, pits=0.002)` makes it rough armour; painted browner with grime. |
| 15 | The eyeball is one smooth sphere. `eye_attrs()` stores, per point, how straight it faces the look direction; `paint_eye(iris_out=, iris_in=, ring=)` paints white, iris (33°), dark ring, pupil (15°) and shine (6.5°) and it is baked onto the ball. Lid = a sphere cap cut with ONE clean plane (`bisect_plane`, never deleting vertices: that leaves a saw-tooth), solidified inward so it sinks into the eye with no gap. A torus of skin round the eye is the socket. |
| 16 | Brow outline shifted `y + 0.3 * x` (inner end lower); both brows use the same seed and tilt (mirror images), sunk only 2 cm, so they sit evenly on the lids. |
| 17 | `mandible()`: a custom loft with parallel-transported frames (no twist), flattened cross-section with a cutting edge, 3 random teeth on the inner edge, gentle lumps from 7 control values (not every slice: that makes rings), a slightly wobbly path, one tip vertex. Own grey material; `gradient_attr()` + `paint_material(root=...)` darkens the root. |
| 18 | A stone torus (melted into the shell) round the feeler's first segment, in the gap beside the horn, with a face-skin blob at the bottom of the hole. |
| 19 | The gem: points spread over the bulging dome (min. 0.16 rad apart, each a little in or out) + the window's rim sunk 3%, wrapped by `bmesh.ops.convex_hull`, the bottom faces removed: perfectly flat facets. Painted with `glow_paint(..., facets=0.45, cloud=0.35, bubbles=0.85, creases=0.6)` on a dense copy, baked onto the flat gem. |
| 20 | `monster_model.gd animate()`: `emission = base x (0.7 + 0.3 sin(1.8 t))`, x2.6 while angry. The creature page does the same for materials named `glow*`. |
| 7 | `rim_z(y)`: the lower edge is a curve (0.29 m in the middle of a side, ~0.4 m at the ends); `A, B, CZ = 0.47, 0.56, 0.38`. Horn: `ck.loft(..., sides=6, smooth=False)` (flat sides), ~15% bigger than round 6. |
| 21 | `godot --audio-driver Dummy --path . -- seed=42 nomonsters artpreview creatures shots=<folder>`; look at `creature_rock_beetle_closeup.png` and `creature_live_charge_closeup.png`. |
| 22 | Name a moving part `soft_stalk_*` (the game sways it, `monster_model.gd animate()`); `sculpt_test_beetle.py` keeps legs and stalks as separate parts turning at their hinges. Charge end: stone chips + dust (`monster.gd _creature_fx`). |

### Mistakes to avoid (each one happened on the beetle)
- Colours picked by eye are sRGB: convert with `lin()` before putting them in a shader, or everything turns pale.
- A loft's end cap closes the tube: a socket ring made as a capped tube puts a disc **in front of the eye**. Use a torus.
- A lid cap aimed forward covers the iris (the "red smudges"): aim it up and back, and check the iris is visible.
- A Bezier whose last point turns back makes a crumpled tip: let the curve end going forward into the point.
- Tubes along a curve that points straight up/down twist into a "droplet" unless the side direction is fixed (`up=`).
- Thinning a sculpt for the game copy (decimate) can fold triangles over on thin parts like eyelids; a folded triangle
  bakes the inside of the part (dark speckled shards). For faces use `game_copy(..., remesh=0.007)` (an even remesh).
- The dark layer under the shell plates must stop behind the face and the amber: the sculpt grows its moss up to 7.5 cm,
  right through the lids and the gem.
- Long Python patches typed straight into the terminal break on quotes: write them to a script file first.
- **Every export with JPEG pictures must run `glb_jpeg_fix.fix()`** (Blender 5.3 puts a colour profile in each JPEG and
  Godot 4.7 can't read it: the model loads WHITE). The bake script once skipped it (F164); `tests/test_model_pictures.gd`
  now catches that. Test where a problem is before guessing: load the file in Godot and read the error.
- Godot only re-imports a model when its contents change: to force it, delete its files in `.godot/imported/`.

## Part 3: the looks (variants)

1. **One body for all looks.** The same plates, legs, face, eyes, mandibles and moving parts; a look changes only the
   paint, the horn, and its add-ons. (The owner's green eyes stay on every look.)
2. **Each look reads at a glance** (from the approved variants picture): Rock Beetle frost = dark slate stones with
   snow on their tops and in the cracks, ice crystals, a forked ice horn, a cyan back; ember = basalt stones with
   glowing lava in the cracks, orange crystals, a hammer horn, an orange-red back; spore = purple fungus stones, small
   glowing mushrooms, an antler horn of old wood with mushrooms, a violet back.
3. **Add-ons grow out of the stones:** their feet sunk into a plate, never on the amber window, never floating. Big
   enough to see from a few metres away (crystals 18-26 cm, mushroom caps 7-10 cm across on a ~1.3 m beetle).
4. **Anything that glows is named `glow_*`** (the lava, the crystals, the mushroom caps), so the game makes it glow,
   hum and blaze on a charge.

How: `monster_rock_beetle.py look=<look>` builds the horn and add-ons (`crystal_cluster()`, `mushroom()`, `on_shell()`);
`sculpt_test_beetle.py <grey.glb> <out> look=<look>` paints from its `PALETTE` (stone, moss/snow/lava layer, amber,
legs, belly, face) and `EXTRA_PAINT` (ice, crystals, wood, mushrooms). Snow on the tops: `paint_material(cap=(colour,
amount))`. Lava: the crack layer carved flat (`moss_h=0.012`) and baked as `glow_lava_baked` with its own glow.
Mistakes made: a hammer horn on a short post was buried in the front stones (the head must clear the shell top);
the first add-ons were too small to see; the first snow covered whole stones (only the tops, `normal.z > 0.55`).

## Part 4: faces, hair and beards (learned on the dwarf, round 2, Nov 16)

The worked example: `tools/asset_forge/builds/dwarf_head.py`. What carried over from the beetle and what was new:
1. **Measure the picture first, and check numbers before pictures.** `measure()` prints sizes against the picture and
   whether the eyes, ears and nose can be seen (rays from the front and side). It caught a missing face for free.
2. **Faces are clay, not glued blobs.** Melting blobs keeps them looking like balls. `Clay` blends shapes with a chosen
   fillet (soft union), scoops sockets out, and makes the mesh (surface nets). Keep every shape inside the grid.
3. **Eyes sit in scooped sockets** under the brow ridge; one lid shell per eye with an almond opening (lower lid higher =
   a smile), sunk 1.5 mm into the ball. A socket deeper than the lids fill looks like dark rings.
4. **Hair = a mass plus locks.** A clay mass gives the shape; flame locks (`lock()`: flat, swelling then pointed, grooves
   along it) lie on it like shingles with the tips lifting. Long locks pointing outward look like a sunburst.
5. **Beards lie on the body.** Every lock is built 1.2 cm off the body, then the melted skin is pushed out where it still
   touches. Braids: slanting leaf lobes from each side in turn (`braid()`); filler in front of them shows as balls.
6. **One paint, soft borders.** Give each point its colour (a `tint` attribute) instead of switching materials per face:
   switching per face makes a staircase hairline.
7. **Clipping is checked in motion, in Godot** (`dwarf_pose_dump.gd` + `dwarf_clip_check.py`). Blender bends unevenly
   stretched bones differently, so its numbers were wrong. Below the chin the beard follows the bones of the shirt it
   lies on, and nothing on the body may follow a bone that sits inside it (this skeleton's Head bone is in the chest).
8. **Hard lines, not soft shade** (owner): paint a crisp dark line where one lock meets the next and down each groove,
   from each lock's id and groove stored before melting (`hard_lines()`). Crease-depth shading was invisible once baked.
9. **Hair that swings** (`src/player/hair_swing.gd`): chains of many bones (7 per braid), each joint keeps its speed,
   drag, pulled back toward where the head carries it, at most 30 degrees bend per joint, fixed lengths, collision balls
   inside the body. On this scaled skeleton the hair bones hang from the root and are placed directly each frame (bones
   under the stretched head skew; Godot's SpringBoneSimulator3D fails for the same reason). Check it in numbers inside
   the modifier (Godot reports the human-sized pose there).
