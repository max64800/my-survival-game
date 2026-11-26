# Picture-to-3D rules (armor test, owner OK Nov 26)

**Status:** a TEST. The owner allowed one exception to MODEL-RULES rule 1 ("never picture-to-3D as the final model") to see if
the GPT picture `docs/art/armor-3d-test/gpt_copper_armor_front_back.png` gives better armor than our hand-built one. If the owner
likes the result, rule 1 gets rewritten (delete the old text then). If not, the exception ends. All other MODEL-RULES still apply
(no shimmer, calm colours, nothing poking out, every rule's automatic check).

## 0. First check the PC (do this before anything else)
- `nvidia-smi`: name, VRAM, driver. Hunyuan3D 2.1 needs an NVIDIA card **Ampere or newer (RTX 30/40/50)**.
  Shape step ~10 GB VRAM, texture step ~21 GB (shape+texture together ~29 GB). Not enough VRAM = do shape only, texture in Blender (section 4).
- We already ran TripoSR on this PC (`tools/asset_forge/forge_creatures.py`, `docs/CLAUDE-REFERENCE.md`): reuse its Python/venv notes. Don't redo.
- Install Hunyuan3D in its own folder OUTSIDE the repo (models are GBs, never commit them). Easiest on Windows: ComfyUI Portable +
  `visualbruno/ComfyUI-Hunyuan3d-2-1` nodes (precompiled wheels, Python 3.12) or `ethanstoner/Hunyuan3D-2.1-Complete-Install-Guide`
  (script; pins KJNodes to commit 37a0973, do NOT "Update All"). Check downloaded model byte sizes (dit ckpt 7,366,389,768).
  Official repo: `Tencent-Hunyuan/Hunyuan3D-2.1` (Python 3.10, torch 2.5.1+cu124). Native ComfyUI only does untextured shapes.
- Read every file of anything you download (global rule: new skills/plugins/nodes = read first, never `-y`).

## 1. Prepare the pictures (this decides the result)
- ONE part per picture: helmet, chest+shoulders, gauntlets, belt+tassets, legs, boots. Each on a plain light-grey background,
  fills 70-90% of the frame, front or slight 3/4 view, near-orthographic (no wide angle), soft even light, **no cast shadows,
  no bright specular glints** (they get baked into the texture). The owner's picture is shiny: regenerate flat-lit per-part pictures
  with GPT image ("matte hammered copper, flat even studio light, no highlights"), or delight afterwards.
- Beard and hair hide the armor and fuse with it: leave them out of the armor pictures (empty helmet, chest without beard).
- Same design in every view (rivets, belt buckle, colours). Provide front + back (+ side / 3/4) per part. Hunyuan3D-2mv takes multi-view.
- Thin straps and tiny rivets come out blobby: model rivets/straps by hand in Blender or fake them in the normal map.
- Generate 3-4 seeds per part, keep the best. Look at it from every angle (a good front can hide a bad back).

## 2. Generate
- Shape per part with Hunyuan3D 2.1 (multi-view if possible). Export GLB/OBJ. Work in meters, apply scale/rotation.
- Fixes in Blender: delete floaters (Select Linked > separate loose parts), Mirror-modifier symmetry (cut in half, mirror, re-bake),
  Sculpt-fix overlaps. Keep each piece a separate object.

## 3. Clean mesh (retopology), then bake
- Keep the dense generated mesh as the HIGH poly (bake source). Make a clean LOW poly: AI retopo (Hunyuan Studio / Tripo Smart Low Poly)
  or Blender Quadriflow/Decimate; aim ~1,500-5,000 faces per armor piece (game budget: 4 players, many monsters; ask owner if unsure).
- UV: seams where nobody looks, Angle Based unwrap, check stretch display, pack with the UV-Packer add-on or Blender pack.
  One material per piece group.
- Bake in Cycles: Normal and AO, "Selected to Active", cage extrusion about 0.06 (blotches = cage missed). Bake roughness/metal
  from one tileable hammered-copper image if needed.
- Delight the colour map: paint out baked shadows/glints, or re-project from a flat-lit picture.

## 4. Texture in OUR style
- The game look is hand-painted, chunky, calm (CLAUDE.md art rule). Keep the picture's hammered-plate + rivet read, but colour it with the
  project's copper palette (look at `assets/characters/dwarf/armor_copper*` and `assets/concepts/dwarf/dwarf_copper_plate.png`). No chrome.
- If the texture step won't run (VRAM): project the flat-lit picture in Blender (Texture Paint > Project / Image Texture with UV from view),
  or hand-paint the base colour + use the baked normal map.

## 5. Fit to the dwarf and rig
- The dwarf rig and body: `assets/characters/dwarf/` (Quaternius base, see CODE-MAP for the loader/`dwarf_rig.gd`). Armor = separate skinned
  pieces on the SAME armature (never layered on a naked body without checking clipping; shrink the body parts under armor if they poke).
- Weights: put armor exactly on the body (rest pose, apply scale/rotation), select body then armor in Weight Paint, Transfer Weights
  (Nearest Face Interpolated, by name), then Limit Total 4, Normalize All, Clean. Or Data Transfer modifier (Vertex Groups), apply it.
  Armor that hangs loose (tassets, shoulder plates) needs hand painting; rigid plates can be 100% one bone. Add a Shrinkwrap only for cloth-like parts.
- Test by posing: walk, swing, mine, crouch (animations in `assets/characters/anims/`). Look for armpit dragging and plates through the body.
- Export GLB like the existing armor (`tools/asset_forge/...`, grep how `armor_copper.glb` is made) and wire it where the hand-built one is.

## 6. Show the owner
- Same camera as the owner's comparison shot (`docs/art/armor-3d-test/hand_built_vs_in_game_nov26.png`): hand-built left/right vs new,
  in game and a turntable. At most 2 render-review rounds, then ask the owner (Blender work rule).
- Log in `CREDITS.md`: Hunyuan3D is under the Tencent Hunyuan community licence, **check its territory/commercial terms (it has had
  region and user-count limits) before shipping**, and say "AI-made, disclose on Steam" like the creatures.
- Journal entry in `journal-inbox/`, FEEDBACK.md line claimed first (see CLAUDE.md). Tests for any new check; run through `tools/run_tests.sh`.

## Sources (read Nov 26)
Top 3D AI "Queen of Hearts" lesson (top3d.ai); 3DSkillUp "AI Game Character Workflow Tripo > Blender > Unity"; Tripo "how to get better
image-to-3D results"; Meshy "better results checklist"; Hunyuan3D-2.1 GitHub README; visualbruno/ComfyUI-Hunyuan3d-2-1.
