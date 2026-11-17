# The player dwarf: plan (owner decisions, November 15, 2026)

## Decisions
- **Free tools only.** No Meshy/Tripo paid plans. Pictures from the owner's ChatGPT; Blender (free) for everything 3D.
- **Hand-built, the Rock Beetle way (owner, Nov 16):** built in Blender by script and sculpted and baked
  (`docs/art/CREATURE-RECIPE.md`, Model Rule 1). No picture-to-3D. The pictures are only for matching.
- **One dwarf for every player for now** (no customization yet). Concepts: three dwarves were drawn
  (happy = short, barrel-chested, braided red beard with copper rings; strong = tall, broad, long grey braided beard,
  scar; smart = young, round face, scruffy ginger beard). The owner likes all three; they may become **3 classes that
  play differently** later (tabled). Build ONE body now; the other two can be heads/beards + body sliders later.
- **First round (owner, Nov 16): the base body in underclothes + the Happy head and braided beard, animated,** on a 3D
  page for the owner's notes. Outfits (F55) and the other two heads only after the owner's OK.

## How it's built (so it animates and wears armor)
- **Keep the game's existing skeleton:** the free CC0 Quaternius humanoid skeleton the current rigged dwarf uses
  (`src/player/dwarf_rig.gd`, `assets/characters/`), with its 120+ CC0 animations (Universal Animation Library).
  First check the packs really share one skeleton (a blog says 65 joints, same names; Quaternius only says "compatible").
- **Base body** in plain underclothes (linen shirt + shorts): what you see with no armor on.
- Build the body by script in Blender to match the A-pose pictures (chunky, our painted look; melt, carve, paint, bake),
  then **move it onto the existing skeleton** by copying bone weights from the Quaternius body (Blender Data Transfer
  modifier, "nearest face interpolated"). Max 4 bone influences per vertex. Export as a child of the armature, rest pose.
- **Armor** (Leather, Copper, Shell; approved concepts in ChatGPT chat "Generate Building Kit Sheet") is modelled on that
  body in Blender, weights copied the same way. Helmets ride on the head bone. Body parts hidden under armor are
  switched off so nothing pokes through.
- Test: robot screenshots of the dwarf in each outfit walking, mining, fighting, rolling.

## Pictures to make in ChatGPT (in this order)
1. The chosen dwarf, front view, **A-pose**, underclothes, one clean single image (the 3D tools take one picture).
2. Turnaround sheet of the same dwarf: front, side, back (for checking the 3D result and fixing it in Blender).
3. Head and beard close-up: front and side.
4. Each outfit WORN on the A-pose dwarf, front and back (3 pictures: Leather, Copper, Shell), to show how the pieces sit.

## Done (November 15): the 6 pictures, in ChatGPT chat "Generate Building Kit Sheet"
Chosen body: **Happy** (short, barrel-chested, big round nose, bushy eyebrows, thick red-brown hair, bald on top,
big red beard in **three braids with copper rings**). Later classes change only the **face and beard**.
1. Front A-pose in underclothes: off-white linen shirt with rolled sleeves and laced collar, brown linen shorts with
   rolled cuffs, cloth foot wraps. **Use this one for the 3D tool.**
2. Turnaround: front, side, back, same A-pose.
3. Head sheet: front + side, calm closed-mouth smile (for animating the face), shows the 3 braids and ring positions.
4. Wearing Leather (front + back). 5. Wearing Copper, the aged version (front + back). 6. Wearing Shell (front + back).
The beard always sits over the chest armor; helmets cover the hair; trousers tuck into the boots.

Also approved earlier: the separate outfit sheets (Leather; Copper = the second, aged version; Shell).

## Done (November 15, night): the other two heads, same chat
- **Strong head** (front + side): stern square face, scar over one eyebrow, long grey-brown beard in one thick braid
  plus two side braids, dark iron rings.
- **Smart head, changed by the owner:** he is **OLD and smart**, not young. White forked beard tied with copper beads,
  wrinkled clever face, sarcastic half-smile, white hair balding on top, eye-glasses pushed up on his forehead (they came
  out as goggles). The young ginger version is rejected.
- **Check lineup:** all three in Leather on the same Happy body. The bodies match, so one skeleton and one set of armor
  fits all three; only the head mesh (face, hair, beard) swaps.


## Saved in the project (November 16, owner's OK)
`assets/concepts/dwarf/`: `dwarf_happy_apose.png` (the main reference), `dwarf_turnaround.png` (front, side, back),
`dwarf_happy_head.png`, `dwarf_strong_head.png`, `dwarf_smart_head_young.png` (rejected young version; the OLD smart head
is in `dwarf_lineup_old_smart.png` / `dwarf_lineup_latest.png`), `dwarf_wearing_leather/copper/shell.png`, three lineups.
`assets/concepts/outfits/`: `outfit_leather.png`, `outfit_copper_aged.png`, `outfit_shell.png`.

## Round 1, how to start (for the Claude doing it)
1. Read `docs/art/CREATURE-RECIPE.md` (the beetle lessons) and `docs/art/MODEL-RULES.md`.
2. Write down what `dwarf_turnaround.png` shows (proportions in heads, belly, beard, hands, feet) before building.
3. Find the game's skeleton and how the current dwarf is loaded (`src/player/dwarf_rig.gd`, `assets/characters/`); keep
   it and its animations. Measure its bone positions so the new body is built around them.
4. Build by script (`tools/asset_forge/builds/`): body, head and beard grey first; compare with
   `creature_compare.py` / `creature_closeup.py`; the owner checks the grey shape before paint.
5. Sculpt and bake like the beetle; copy bone weights from the Quaternius body (Data Transfer); test in the game,
   muted, with screenshots. Known blocker: baked pictures load white in Godot (F164); solve that first or the dwarf
   will be white in the game too.

## Round 1 done (November 16, Claude 3): the grey dwarf, animated, waiting for the owner's OK
What the picture shows (written before building): ~4.8 heads tall without the beard; a very wide barrel body (~0.44 m
across on a 1.13 m dwarf); short thick legs, knees low; a big round head, bald on top, a ring of thick red-brown hair
from the temples round the back; bushy brows, a big round nose, rosy cheeks, ears; a grin under a curling moustache; a
huge beard to the belly in three braids, each with a copper ring (side braids to the chest, the middle one to the
belly); an off-white linen shirt with short rolled sleeves, hem at the hips; baggy brown knee shorts with rolled cuffs;
cloth wraps from mid-calf over the feet; thick hairy forearms, big hands.

How it's built and put in the game:
- `tools/asset_forge/dwarf_skeleton_dump.gd` writes the game skeleton, shaped by DwarfProportions and standing at rest
  (`DwarfRig.dwarf_rest_poses()`), to JSON. `tools/asset_forge/builds/dwarf_body.py` builds every part around those
  bones (grey: plain colours), adds the skeleton, lets Blender work out the bone weights (head, face, hair, beard and
  braids ride on the head bone), max 4 bones per point, nothing on the "root" bone, then exports
  `assets/characters/dwarf/dwarf_body.glb`.
- `DwarfRig._wear_body()` hides the pack's stand-in meshes and binds each part to the shaped rest pose, so standing
  still it looks as built and all 120+ animations bend it along. **Off until the owner's OK:** start the game with
  `-- newdwarf`, or set `DwarfRig.BODY_ON = true`. Test: `test_dwarf.test_hand_built_body_fits_the_skeleton`.
- `tools/asset_forge/dwarf_anim_export.gd` records the dwarf playing 9 clips (with the shaped bones) into one .glb
  for the 3D page ("Dwarf Body"). Pictures: `docs/art/dwarf-round1/`.
- Next (after the owner's notes): sculpt, paint and bake it like the beetle (the head and beard first), then the
  outfits (F55) and the other two heads.

## Round 2 done (November 16, Claude): the head and beard, waiting for the owner's notes
Owner's round 1 notes (F183): sausages and balls, needs much more detail; the beard clips through the body; the feet are
far too long; 3 chunky fingers plus a thumb is fine. Plan: the Rock Beetle way, one area per round, head and beard first.

How it's built (`tools/asset_forge/builds/dwarf_head.py`, called by `dwarf_body.py`; ~45 s with the bake):
- Measured on `dwarf_happy_head.png` (1 px = 0.725 mm; crown at 1.19 m): head 24 cm crown to chin, 23.6 cm wide; eyes
  4.6 cm from the middle; nose ball 7 cm, tip 19 cm in front of the skull's middle; moustache 29 cm; beard 43 cm wide.
- Face = one piece of clay (`Clay`: blended ellipsoids and tubes with set fillet sizes, scooped eye sockets, turned into a
  mesh by surface nets). Lids = one shell per eye with an almond opening (smiling). Ears = rim, bowl, ridge, lobe.
- Hair = a clay mass (below the hairline, behind the temples, notches for the ears) with flame locks on it like
  shingles. Brows: 3 layers of thin strands. Moustache: 3 locks a side from under the nose. Beard: sideburns, flaring
  outer locks, locks between the braids; 3 braids (`braid()`: slanting leaf lobes, a core pinched under a copper ring,
  a flame tuft). Every lock is built 1.2 cm off the body; the melted skin is then pushed out where it still touches.
- All melted into one skin (2.2 mm), sculpted (`sculpt_face`), a 44,000-triangle game copy, colour + normal pictures
  baked (2048). Eyes and copper rings are their own baked pieces. Clay colours: one paint, each point carrying its own
  colour (skin or hair), so the hairline is soft. The real paint (rosy cheeks, hair streaks, hammered copper) is next.
- Bones: face and top of the head on the Head bone; below the chin the beard and back hair follow the shirt under them
  (blended over 0.865-0.96 m). The shirt never follows Head or neck_01 (that bone sits inside the upper chest). With the
  hand-built body the head keeps 35% of each animation's neck and head turning (`DwarfRig.BODY_HEAD_FOLLOW`).
- Checks: `fast review=<pic>` prints MEASURE lines (sizes vs the picture, eyes/ears/nose visible) and renders the
  picture-vs-model sheet; `dwarf_pose_dump.gd` + `dwarf_clip_check.py` measure clipping in every clip with Godot's own
  bending. Now: standing, walking, jumping 0-3 mm; run, mining, sword, roll 2-8 cm (the round 1 shirt's sides and
  shoulders swing into the beard: body round).
- Pictures: `docs/art/dwarf-round2/`. 3D page "Dwarf Body": round 2 and round 1 side by side, with the picture.
- Round 2b (owner's notes F191-F194, Nov 16): dark creases in the beard, hair squeezed inside the rings, the cheek gaps
  filled, a kinder brow arch, and swinging ring + tuft (swing bones "hair_braid_<m|a|b>_1..2" built in `dwarf_body.py`,
  added to the game skeleton by `DwarfRig._add_swing_bones`, moved by `src/player/hair_swing.gd`; Godot's
  SpringBoneSimulator3D can't be used: the skeleton is scaled).
- Round 2c (owner's notes: no visible shading, side braids clash, "learn how to do hair animation"): hard lines from each
  lock's seams and grooves (`hard_lines()`); side braids at 14 cm; real hair chains: "hair_braid_<m|a|b>_1..7" down each
  whole braid and (since Nov 17) one chain "hair_back_m_1..7" down the back hair, added by `DwarfRig._add_swing_bones` under the skeleton
  root (not the stretched head) and placed every frame by `HairSwing` (verlet chain, 30 degree bend limit, collision
  balls from `DwarfRig._fit_colliders`). Fast moves still push the swinging braids into round 1's shirt: body round.

## The back hair "visor": fixed by measuring (Nov 17 evening, F215, waiting for the owner's look)
The owner (with pictures, after 5 rounds): the back hair lifts off the back as a stiff slab ("visor"), the bare neck
shows under it, the tip hooks. `dwarf_clip_check.py` now prints per clip how far the back hair lifts off the back and
how many degrees it opens away from it (against the upper back's own lean). `dwarf_pose_dump.gd` options to split the
causes: `backrigid` (the back hair held exactly where it rests), `nocol` (no collision balls), `nosway`.
(The earlier analysis said the head tips 30-65 deg in fast moves: wrong, it tips 15-27 deg; the upper back leans 22-39
and the head only 6-12 deg against it. The planned "gravity + balls" fix would not have helped.) The real causes, each
tested on its own:
1. The chain folded: rays below the hanging hair hit its underside up by the neck, so its last two bones pointed up
   into the neck. The nape hair rode on its swinging end: the bare neck, the hook, and nape hair 1-8 cm inside the neck.
   Now `build_hair()` stops at the first ray that isn't lower and ends the chain at the lowest hair in the middle.
2. Drag against the world (`HairSwing`, "air"): running blew the ponytail out like a headwind. Back hair: air 0.
3. Its resting place rode on the head. Now below the head it lies on the shirt: each joint copies the bones of the
   shirt point under it (`DwarfRig._hair_on_shirt`), blended in over the neck (0.865-0.96 m, like the beard); joints
   up on the skull are pinned to the head.
4. The collision balls (one bone each; the arm ones fat) poked out of the bending shirt: up to 4 cm push. The back hair
   no longer uses them: it may never sink below where it rests on the shirt, only lift off a little when it swings.
5. Tear lines: the nearest point on a bent chain jumps between links, so hair beside a bend followed two bones on
   either side of a line. Back hair weights now go by height down the chain (`along_by_height`); the bone over the neck
   stretches along its length when the head moves against the back.
6. The hanging part had almost no locks (a bare smooth sheet): four rows of hanging locks, tips flat.
Result (worst per clip, before → after): lift off the back run 11.5 → 2.9 cm, sprint 8.2 → 3.4, mining 17.4 → 2.8,
sword 11.0 → 2.3, chopping 11.9 → 1.4, roll 21.8 → 6.9 (the swing in the roll); opening 25-41 → 5-18 deg; worst back
tear 8x → 4x. Held exactly at rest with no balls, run lifts 0.0 cm: the resting place is right, the rest is the sway.
Still open: a dark spot at the eye's outer corner seen from the side (owner's picture): probably the socket corner
left uncovered after the lids were narrowed; measure first. The braids still have the headwind and the balls (N2).

## Next session first (owner, Nov 16 evening: "we will finish tomorrow")
- F214: thicker front braids.
- F215: a real skeleton for the big ponytail down the back, like the front braids: done Nov 17 (one chain of 7, lying
  on the shirt; see "The back hair visor" above).
- Then the body round below.

## Round 3, the body: started Nov 17 night (draft, NOT in the game yet)
- Measured: `python tools/asset_forge/dwarf_turnaround_measure.py [out.png]` prints width/depth per 2.5 cm of height
  and the separate pieces (arm | body | arm, leg | leg). Torso ~0.50 m wide at the hem (0.43 m), ~0.43 at the chest,
  ~0.45 m deep, belly out most at 0.60-0.65; shorts legs ~0.23 wide, cuffs ~0.20-0.23, crotch ~0.36; wraps to ~0.18;
  feet ~0.19 wide; round 1's feet were 0.35 m long (toe bone 26 cm in front of the ankle), now ~0.24 m.
- `dwarf_body.py` now builds the body as clay (`loft()`: one smooth surface through the measured rings; `torus`,
  `body_ring` for cuffs, hem, collar, waistband; `finish()` cuts the faces down for the game). `body=<png>` renders the
  whole body front/side/back. The game's `dwarf_body.glb` still has round 1's body until a full build is run.
- Draft 2 (owner not shown yet), still wrong: the shirt reads as a can (boxy shoulders, flat bottom: needs sloping
  shoulders into the sleeves, a hem that flares and hangs uneven), folds show as small dents (need long soft creases),
  the shorts' waistband pokes out from under the shirt and a stray bar sits on the back of the seat, the feet read as
  round boots (need a flatter, longer-toed wrapped foot with visible band edges), hands are still round 1's.
- Then: weights (nothing on Head/neck_01; the shirt must not bulge with the arms), the clip check and back-hair numbers,
  the 3D page, the owner's OK, then sculpt + bake.

## Round 3, the body: draft in the game (Nov 18, waiting for the owner's look)
- Owner's OKs (Nov 18): the skeleton now matches the turnaround picture (`DwarfProportions`): shoulders ~12 cm lower
  (`clavicle` length 0.35), shoulders moved forward to hang from the middle of the body (`SHOULDER_FORWARD`), arms a
  little shorter (0.5), hands ~17 cm instead of ~47 (`HAND_SIZE` 0.36: finger joints closer, not a thinner hand bone,
  so held tools keep their size). Re-dump the skeleton (`dwarf_skeleton_dump.gd`) before any body build.
- `dwarf_body.py`: shirt a barrel (widest at the flared hem and belly), hem cut along an uneven line with side slits and
  a rolled lip; folds are `press()`ed soft dips (not tubes with big soft joins: a soft join much bigger than the fold
  digs on its own); shorts trimmed to stay 1 cm inside the shirt above the hem; legs and feet wrapped in flat `strip()`s
  with visible edges; clay hands (3 fingers + thumb); `finish()` merges the zero-size slivers the face cutting leaves.
- `body=<png>` now renders AFTER the weights with the arms lowered 65 deg (the picture's pose): judge shoulders posed.
- Head: `nose_pockets()` prints how shut-in the skin round the nose is (the dark-bake spots); review adds `_nose.png`.
- Clip check (Godot's bending, every clip): walk 2 mm, sprint 2, run 10, mining 9, jump 2; side braids by the arms
  39 mm standing, 32-37 sword/chopping; middle braid 100 mm in the roll. Back hair sways 14 cm in a dash (test limit 10).
  Tried and undone: (1) fading the arm bones out of the shirt's body (made run 10 -> 149 mm: the beard copies the shirt's
  bones, the arms are mapped to the chest for it already); (2) a "never sink below the shirt under it" floor for braid
  joints like the back hair's (tore the braids, 100x stretch). The check itself was fooled by folded/zero-size
  triangles: it now confirms "inside" by counting ray crossings.
- Owner's notes on the page (Nov 18): hips too wide, feet in the ground, forearms massive, fists tiny, a sausage; 2 fat
  fingers + thumb. Done: `HAND_SIZE` 0.43, two-finger hands, slimmer arms, narrower shorts/hem, hem at ~0.405 m; the feet
  settle to the bind pose's foot height (`DwarfProportions._rest_low`, set by `DwarfRig._wear_body`): they had sunk ~8 cm.
  Clip check: standing/sprint/roll <= 1 cm; side braids by the arms 2-5 cm in walk, run, mining, sword, chopping.
- Next: the owner's look at the 3D page; then the side braids by the arms, the roll, the back-hair sway; then sculpt + bake.

## Round 3, the body: how to start (owner, Nov 16: "do this for his entire body now")
Read the Round 2 notes above and `docs/art/CREATURE-RECIPE.md` Part 4 first. The head is done; keep `dwarf_head.py`.
1. Measure the turnaround (`dwarf_turnaround.png`) for the body like the head was: torso width and depth per height,
   shirt hem, sleeves, arms, hands (3 chunky fingers + thumb is fine), shorts, calves, wraps, and **short feet** (F183:
   far too long now).
2. Build the shirt, shorts, arms and feet as clay (`Clay` in `dwarf_head.py`), with the same sculpt-and-bake, clay colours.
   The chest front should be fairly upright under the beard (round 1's slopes forward 30 degrees and tilts the braids).
3. Weights are the real fight: the shirt's sides and shoulders must not bulge with the arms (that is what still pushes
   the beard tufts in when running) and nothing on the body follows Head or neck_01. Check every change with
   `dwarf_pose_dump.gd` + `dwarf_clip_check.py` (Godot's own bending), not with pictures.
4. The back hair lies on the shirt (copies the bones of the shirt point under each joint): rebuild the body, and it
   follows the new shirt by itself. Re-run the clip check's back-hair numbers after.
