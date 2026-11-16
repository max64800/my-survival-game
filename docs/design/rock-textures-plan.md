# Rock textures plan (owner's picks, Nov 16, 2026; F213)

The owner: "let's work on better and variations of different textures of rock, clay and everything that caves are
made out of". Picked by multiple choice:

- **Several looks per rock:** 3-4 different paintings of each material, blended across the cave by position, so the
  same pattern never shows twice (the "many paintings, not one" rule, MODEL-RULES Rule 6).
- **ChatGPT hand-painted:** variant sheets made in ChatGPT in the same hand-painted style as the Rock Beetle and the
  stations, cut into seamless tiles (like `tools/asset_forge/derive_tex_shack.py` does for the Shack). No more photo
  textures for these.
- **Looks only:** no new rock kinds or items; digging stays the same.
- **Batch of 4, then the owner's OK:** stone, dirt, clay, moss first; ores, border rock and the jungle rocks
  (mycelium, sporestone, amberrock, silver) after.

## How it works today (to change)
- `tools/art/bake_terrain_textures.py`: one 512 px ambientCG (CC0) photo per material, run through a paint filter,
  stacked into `assets/textures/terrain/terrain_albedo.png` + `terrain_normal.png` (16 layers, one per `Mat` number).
- `src/world/terrain.gdshader`: triplanar, up to 4 materials per spot (Voxel Tools weights), big light/dark patches,
  and (Nov 16, F188) damp patches, green mould and orange wall streaks.

## Plan
1. One ChatGPT chat, one style prompt: a variant sheet per material (4 stone, 4 dirt, 4 clay, 4 moss), flat-lit,
   seamless, top-down, same palette as now (stone `STONE_TINT`, clay orange, moss green, dirt brown). Save the sheets
   in `assets/concepts/terrain/`.
2. A cutter script: cut each sheet, make every tile seamless (offset + blend the seams), 1024 px, derive a normal map
   from the painting, keep ore-vein alpha for later layers.
3. Texture array grows to 16 materials x 4 looks (or a second array for the extra looks); the shader picks the look
   per spot from world-position noise (big blobs, soft edges), so the choice is the same on every computer.
4. Check: `lookdev` wall shots (`w_wall`, `w_wall2`) before/after, three neighbouring patches clearly different,
   no visible seams or repeats; speed check (`perfcheck`) stays about the same.
5. Credits: the ChatGPT sheets are AI-made (log in `CREDITS.md`, Steam disclosure like the kit textures).
