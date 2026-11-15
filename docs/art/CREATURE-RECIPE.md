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
7. **The shell is round** from head to tail and covers the body, like a dome, not a flat lid.
8. **Every stone looks worn and different:** its own shade (some warmer, some cooler, some darker), scratches, chipped
   and lighter worn edges, darker grime. Never all one smooth colour.

### Legs
9. **Armour segments overlap like shingles.** Each segment's lip covers the start of the next one, so you never see a
   joint.
10. **One claw per leg.**
11. **It stands on its legs.** The claw lies **flat on the ground** like a toe: its underside rests on the ground, and it
    ends in a point. The claw is never a stilt it balances on.
12. **The body underneath is shingled too** (overlapping belly bands).

### Face
13. **Small and tucked in, never puffy.** No big cheeks.
14. **No nose. The mouth is barely visible:** a thin, mostly-sunk frown line.
15. **Eyes are clean painted balls:** cream white, a brown iris with a dark outer ring, a black pupil and one white
    shine. A heavy lid and the brow come down over the top of the iris for the grumpy look. Nothing stacked on the
    eye that can poke through.
16. **Brows make a V:** lower on the nose side.
17. **Fangs/tusks have detail:** a thick root that grows out of the face, a blade edge, growth rings near the root,
    darker at the root and pale at the tip, ending in ONE clean sharp point (no blob, no curl-back).
18. **Feelers grow out of the body**, from the gaps above the brows, with their root blended into the skin. Never
    stuck on the outside.

### Glowing parts
19. **Glowing parts are detailed:** the amber is a cut gem (flat facets with bright edges), with cloudy depths and tiny
    bubbles inside, not one flat colour.
20. **Glowing parts hum:** a slow breath of light in and out (about one breath every 3.5 seconds). They blaze when
    the creature charges.

## Part 2: how we do it (for Claude)

The beetle is the worked example: `tools/asset_forge/builds/monster_rock_beetle.py` (shape) and
`tools/asset_forge/sculpt_test_beetle.py` (sculpt, paint and bake), using `tools/asset_forge/creature_sculpt.py`.

| Rule | How |
|---|---|
| 3, 4 | `creature_fit.py` (outline match per view against a turnaround picture) and `creature_compare.py` (picture next to model, same angle). `creature_closeup.py` close-ups of the face, feet and glowing part every round. |
| 5 | **Sculpt and bake.** `melt()` (voxel remesh + smooth) turns glued pieces into one skin, `carve_*()` adds sculpted detail, `game_copy()` makes a light copy, `bake()` puts the paint and detail on it as pictures (colour + normal map). |
| 6 | Cushion plates: the dome is split into patches (nearest seed); each patch grows a little **past** its edge (`GAP = -0.014`) so neighbours press together; the cushion profile rounds each edge down into a V-canyon; moss is its own melted layer in the canyons (`carve_moss`). |
| 7 | The dome is a superellipsoid (`FULL = 0.86`), rounder than an ellipsoid, egg-shaped from above (`TAPER`). |
| 8 | `island_kd()` before melting + `tint_islands()` after: each stone gets its own shade (±13% light, some warm, some blue-grey). `paint_material(..., tint_attr="tint", scratches=0.8, grime=0.35, edge=0.5)`: scratches are thin pale lines (noise contour lines, masked into short pieces) that are also cut in as bump, so the baked normal map has the grooves. |
| 9 | `barrel()`: an 8-sided faceted segment that flares into a lip at its far end; the next segment starts inside that lip. |
| 10, 11 | One claw per leg as a loft lying along the ground: ring centre height = `GROUND + h`, so the underside is flat on the ground all the way; root tucked into the last segment; the ankle sits ~6 cm above the ground. |
| 12 | Belly bands (`belly_band{i}`): each flares at its back edge over the next. |
| 13, 14 | A compact head loft (half-width ≤ 0.22 for a ~1 m creature), a small muzzle blob; the mouth is a 5 mm tube along a frown, half-sunk, dark brown and matte (roughness 0.9). |
| 15 | The eyeball is one smooth sphere. `eye_attrs()` stores, per point, how straight it faces the look direction; `paint_eye()` paints white, iris (33°), dark ring, pupil (15°) and shine (6.5°) and it is baked onto the ball. Lid = a sphere cap cut with ONE clean plane (`bisect_plane`, never deleting vertices: that leaves a saw-tooth), solidified inward so it sinks into the eye with no gap. A torus of skin round the eye is the socket. |
| 16 | Brow outline shifted `y + 0.3 * x` (inner end lower); both brows use the same seed and tilt (mirror images), sunk only 2 cm, so they sit evenly on the lids. |
| 17 | `fang()`: a custom loft with parallel-transported frames (no twist), teardrop cross-section (blade ridge on the inner edge), two growth-ring grooves at 10% and 19%, radius `(1 - t) ** 0.8`, ending in one tip vertex. `gradient_attr()` + `paint_material(root=...)` darkens the root. |
| 18 | A face-skin "forehead" blob and a socket blob fill the gap above each brow; the feeler's first segment starts inside the socket; the melt joins them into the head. |
| 19 | The gem: points spread over the bulging dome (min. 0.16 rad apart, each a little in or out) + the window's rim sunk 3%, wrapped by `bmesh.ops.convex_hull`, the bottom faces removed: perfectly flat facets. Painted with `glow_paint(..., facets=0.45, cloud=0.35, bubbles=0.85, creases=0.6)` on a dense copy, baked onto the flat gem. |
| 20 | `monster_model.gd animate()`: `emission = base x (0.7 + 0.3 sin(1.8 t))`, x2.6 while angry. The creature page does the same for materials named `glow*`. |

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
