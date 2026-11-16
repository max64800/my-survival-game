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
