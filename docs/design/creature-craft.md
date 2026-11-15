# How our creatures are made (and how to make the next one)

*Written by Claude 3, November 14, 2026, after the owner asked for "more complex, more polished"
creatures with variety. This is the recipe and what was learned. See `monsters-first-three.md` for
what the creatures do in the game.*

## The pipeline

```
tools/asset_forge/creature_textures.py      makes the skin pictures (assets/textures/creatures/)
tools/asset_forge/builds/monster_<x>.py     builds one creature in Blender, piece by piece
tools/asset_forge/creature_kit.py           the creature add-on to Claude 2's kit.py
tools/asset_forge/build_creatures.py        builds every creature and every version
        → assets/models/monsters/<kind>_v<N>.glb   (the game loads these)
src/combat/monster_model.gd                 finds the moving parts and animates them
src/debug/dwarf_studio.gd -- creatures      photos of every pose;  -- variety  every version
src/debug/monster_export.gd                 3D files for the owner's viewer page
```

Rebuild everything: `python tools/asset_forge/creature_textures.py`, then
`python tools/asset_forge/build_creatures.py "<game>/assets/models/monsters"`, then a Godot import.

## Naming rules (the game finds parts by name)

| Name in Blender | What the game does with it |
|---|---|
| `leg_l0..2`, `leg_r0..2` | Insect walk (two tripods). Hinge = the hip. |
| `wing_l`, `wing_r` | Flap around the forward axis; half-fold on the upstroke. Hinge = the shoulder. |
| `fold_l`, `fold_r` | Folded wings, only shown while the bat sleeps (open wings are hidden then). |
| `soft*` | Shrinks into the shell when the snail hides. `soft_stalk*` also sway (looking around). |
| `peek*` | Only shown while hiding (the two eyes peeking out of the shell). |
| `body` | Everything else. For the snail it's the shell; it settles onto the ground when hiding. |
| material `eye*` | Flashes before an attack; turns red when a beetle charges. |
| material `vein*` | Dark normally; glows like coals while a beetle charges. |

Each piece turns around its own hinge, set with `with ck.part("leg_l0", hinge=(x, y, z)):`.

## Versions (every creature a bit different)

- Each build script takes `v=0..3`. Versions change real shapes, not just colors:
  - beetles: horn curved / bent / broken / forked, gem clusters (amber, teal, violet), moss amount
  - bats: fur colors brown / ash grey / rust / sandy, a torn ear on some
  - snails: skin slate / olive / rusty, a matching shell color, moss amount, stones, a crystal
- The game picks `seed % versions`, with the monster's uid as the seed, so all players in co-op see the
  same individual. It also scales each one by up to ±6%.

## What the real animals taught us

- **Ironclad beetles** (our "rock beetle" look): armor covered in close, rounded knobs; bigger knobs at
  the back end (one species has four distinct ones); a grainy front shield; black "paint drop" spots;
  matte and waxy. Sources: [IroncladID Zopherus](https://cerambycids.com/IroncladID/IroncladID-Zopherus.html),
  [Texas ironclad beetle (UWM)](https://uwm.edu/field-station/texas-ironclad-beetle/),
  [Phloeodes diabolicus](https://sites.google.com/view/carabidaeandzopheridae/beetles/phloeodes-diabolicus).
- **Insect walking**: the tripod gait. Front and back leg on one side and the middle leg on the other
  stay planted and push back, while the other three lift in an arc and swing forward; then they swap.
  Slightly uneven timing looks less robotic. Sources: [DrQP gait notebook](https://drqp.readthedocs.io/en/stable/notebooks/3_generating_gaits.html),
  [Project Leptan gait docs](https://project-leptan-docs.readthedocs.io/en/latest/Code/HexapodControl/Gait.html).
- **Sleeping bats** hang head-down by their feet, wings folded along the body "like a collapsed
  umbrella" or wrapped like a cloak. Sources: [Iowa DNR](https://iowadnr.gov/news-release/2016-12-08/why-do-bats-hang-upside-down),
  [Smithsonian](https://www.smithsonianmag.com/smart-news/heres-how-bats-can-land-upside-down-180957315/).
- **Snails**: skin covered in small raised bumps with grooves between; a fleshy collar (the mantle) where
  the body meets the shell, with a breathing hole on the side; the whole body pulls into the shell.

## Lessons (mistakes we don't want to repeat)

- **Each part needs its own texture.** One texture on shell and knobs makes it all mush together. Here
  the shell is waxy with drops, the knobs are rock or pebbles or mossy stones or gems, the front shield is grainy.
- **Check colors in the game's light.** A dark shell that looked fine in Blender read as black in the cave.
- **Blender's JPEGs need `glb_jpeg_fix.py`** or the model turns white in Godot (kit and creature kit run it).
- Watch triangle counts (aim ≤ 25,000 per creature). Lots of small blobs add up: use `detail=1, subsurf=0`.
- Look at front, side and back pictures; and at the game studio's pictures before calling it done.

## Update, November 15, 2026: forged from the approved pictures

The game's Rock Snail, Cave Bat and Rock Beetles now come from the owner's approved ChatGPT pictures
(`docs/art/CREATURE-STYLE.md`), forged and split by `tools/asset_forge/forge_creatures.py` →
`assets/models/creatures/<creature>_<mossy|frost|ember|spore>.glb`. The same part names apply, plus material
`glow*` (always glows a little, blazes on a charge). The hand-built models above are no longer in the game;
their build scripts stay (`build_creatures.py`) in case they're wanted again.

## Update, November 15, 2026 (evening): hand-built again, to match the pictures

The owner rejected the forged creatures (Play-Doh, F68). The Rock Beetle is rebuilt by hand (`builds/monster_rock_beetle.py`):
- **Fitted shell plates:** seed points in loose rows over a dome; every point of the dome goes to its nearest seed; each seed's
  patch becomes one plate (its outline, pulled in 1 cm for the crack, one flat cut top, a chamfered edge). Seeds over the
  glowing back and the face get no plate. This is what made it look like the picture (separate rocks looked like a rock pile).
- **4 looks, one body:** the same plates, face and legs; only paint (kit textures recoloured) and extras change (moss strips in
  the cracks, snow and ice spikes, lava cracks and amber crystals, mushrooms). The horn is the look's own (stone, forked ice,
  hammer, mushroom antler), as in the approved grid.
- **Glow in its own colour:** the game used to set every glow to white (right for forged models whose glow is in the
  picture). Hand-built ones glow in their material colour, and each glow material keeps its own copy (amber facets, lava).
- Check every change with `creature_compare.py` (picture | model, same angle) and `tools/model_check/check_models.py`.
