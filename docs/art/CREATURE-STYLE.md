# Creature style guide: make monsters look like the Forge workbench

> **Owner, November 15, 2026: creatures are HAND-BUILT in Blender by script, never picture-to-3D.**
> The forged (TripoSR) creatures came out soft and melted ("Play-Doh"), the same problem the crafting stations had.
> Follow `docs/art/MODEL-RULES.md` (Rule 1). The approved ChatGPT pictures are the design reference only.

**Read this before making or remaking any creature.** (Owner's request, November 14, 2026.)

## The problem

The Forge **workbench** looks great. The **Rock Snail, Cave Bat and Rock Beetles** look plain. The reason is
mostly *how* they were made, not the description:

- **Workbench:** a real 3D model **hand-built in Blender by script** from the shared kit (`tools/asset_forge/kit.py`), with **hand-painted textures**.
- **Monsters:** built in code (`src/combat/monster_model.gd`) from balls, tubes and cones, with one
  computer pattern stretched over the whole body.

**So: build the creatures the same way as the workbench**: a Blender script per creature, from the shared kit plus
the creature add-on (`creature_kit.py`, moving parts), matching the approved pictures by eye. Keep the code-built
bodies only as a fallback.

## What makes the workbench work (and the monsters plain)

| | Workbench ✅ | Monsters now ❌ |
|---|---|---|
| Shapes | Chunky, soft bevelled edges, a little exaggerated (thick top, fat legs) | Plain spheres and tubes |
| Texture size | Big readable stones and wood grain, about 5–10 per surface | Tiny repeating cells or noise, like wallpaper |
| Colour | Each material its own colour: grey stone, orange wood, dark iron | One texture over everything; parts blend together |
| Light and shadow | Painted in: light tops, dark gaps, bright worn edges | None; everything equally bright |
| Detail | On purpose: moss only in cracks; hammer and vise as focal points | Random bits scattered (crystals, pebbles) |
| Faces | n/a | White dots, no expression |

## The rules for every creature

The feel we want is "polished stylized survival creatures, simple but appealing". Never copy another
game's creatures, and never name another game or artist in a prompt.

1. **Silhouette first.** It must read as a solid black shape. Exaggerate: big head, thick legs, chunky shell.
   Show grey shapes before adding colour.
2. **3 big shapes, then details.** For example head, body and shell. Small details only where the eye goes:
   the face, the weak spot, a horn tip. No random bits scattered over the body.
3. **2–3 main colours per creature.** Each part (shell, skin, legs, eyes) gets its own colour and material.
   Darker belly, lighter back.
4. **Hand-painted textures** with big strokes the size of the workbench's stones. Never small repeating
   cells or noise. Paint in the shading: dark in the gaps, light on the worn edges.
5. **Faces with life:** big eyes with a dark pupil and a white shine dot; an expressive mouth or mandibles.
   A bit cute-scary, never gross.
6. **Bugs look like real bug anatomy:** clear segments and joints; shiny shell plates with a soft painted shine.
7. **Gameplay parts must be easy to see:** the beetle's soft glowing back (weak spot), the snail's shell
   opening (where it hides), the bat's fangs.
8. **Check:** put each creature next to the workbench in the same light (the art preview) and compare
   before calling it done.

## Step 1: pictures from ChatGPT

Use the base prompt from `tools/asset_forge/README.md`, but with this creature version. Copy the whole block
and change the last line.

> Game creature concept for a 3D survival game about dwarves living underground.
> Style: polished stylized creature, chunky and slightly exaggerated shapes with a bold readable silhouette,
> appealing and a little cute-scary, never gross. Simple big forms with a few well-placed details.
> Hand-painted textures with big visible brush strokes, painted-in light and shadow (lighter on top, darker
> underneath, worn edges painted lighter). 2–3 main earthy colours, each body part clearly its own material.
> Big expressive eyes with a dark pupil and a small white highlight.
> Picture rules: ONE creature only, standing in a neutral pose, centred, the whole creature visible with space
> around it, front three-quarter view from slightly above, plain light-grey background, soft even light,
> no strong shadows, no ground, no text, no people.
> Creature: **(see below)**

Ready-made "Creature:" lines (designs from `docs/design/monsters-first-three.md`):

- **Rock Snail:** "a big slow cave snail, the size of a small pig. Its shell is a heavy spiral of grey-brown
  stone with moss growing in the cracks and a few small crystals near the top. Soft olive-green body, two long
  eye stalks with big round eyes, a calm but stubborn face."
- **Cave Bat:** "a dog-sized cave bat with big leathery wings (about 1.5 m across), a round fuzzy body in warm
  rusty brown, large ears, a small upturned nose, two little fangs and big shiny dark eyes. Wings spread,
  hovering."
- **Rock Beetle:** "a beetle the size of a cat, with a heavy stone-armoured front, one thick stone horn and
  short strong legs. Its back is soft, pale and glowing amber: the weak spot. Shiny dark legs with clear joints,
  small mandibles, big eyes."
- **Great Rock Beetle:** the same, "but the size of a cart, with a bigger horn, thicker stone plates and the
  glowing amber back cracked open between the plates."

Tips (same as the forge README):
- Ask for 3–4 versions and pick one. To fix small things: "Same creature, keep the design exactly, change …".
- Once 2 creatures look right, upload them with every new request: "Match the style of these pictures exactly."
  This keeps all creatures looking like one family.
- Also upload the **workbench picture** the first time: "Match the painting style and texture size of this."
- Image-to-3D handles solid shapes best. Avoid thin see-through wing membranes, long thin antennae and fur
  strands (ask for "solid chunky wings", "short thick antennae", "painted fur, not strands").

## Approved concepts (November 14, 2026): 3 creatures × 4 variants = 12

Made in the owner's ChatGPT (Plus account), in the chat **"Creature Image Prompt"**. The owner approved all 12.
The workbench screenshot was attached as the style reference.

| Creature | Picture to forge the 3D model from | Variants (in one 2×2 grid picture) | How variants are built |
|---|---|---|---|
| **Rock Snail** | The single snail **with the mossy mustache**, which keeps the grumpy eyelids (the grid made the face rounder) | Mossy · Frost (slate shell, ice crystals, white mustache) · Ember (iron-ore shell with glowing cracks, ginger mustache) · Spore (purple shell with glowing mushrooms, purple mustache) | One model; variants are recolored textures. Spore needs a small swap-on mushroom piece instead of crystals |
| **Cave Bat** | The single front-facing bat (wings spread, grumpy eyelids, piggy nose, two fangs) | Cave (rusty brown) · Frost (grey frosty fur, blue icy wings) · Ember (charcoal fur, glowing lava-vein wings) · Spore (purple fur, wings with glowing spots) | One model; recolored textures only |
| **Rock Beetle** | The single beetle (stone plates, one horn, glowing amber dome on its back, 6 spread-out segmented legs) | Mossy · Frost (icicle ridge, forked ice horn, cyan back) · Ember (basalt plates with lava cracks, hammer horn, amber crystals) · Spore (mushroom-cap plates, antler horn with mushrooms, violet back) | **One shared body with legs** + **4 armour sets (shell + horn)** that snap on top. Legs and walk are made once |

Variant names for the code: `mossy`, `frost`, `ember`, `spore`. Frost and Ember fit the later biomes; Spore fits the
Fungal Jungle. The **Great Rock Beetle** has no separate concept: the owner is happy with these 12, so it can be
a scaled-up Rock Beetle (pick a variant per biome).

Prompt notes that worked:
- Start every creature with "same painting style, chunky bevelled shapes, brush strokes and grumpy character feel
  as the snail" and keep it all in the one chat.
- For many-legged creatures, add "legs spread out wide and clearly separate from the body (not tucked under)".
- Ask for "solid chunky wing membranes with thick wing bones (no see-through parts)".
- For variants with new shapes, say "keep the same body, legs, pose and face; give each its OWN horn, shell
  formation and crystals".

**Done (Nov 15, Claude 3, with the owner's OK):** the 6 pictures are in `assets/concepts/creatures/`.
~~**To do on the PC:** download the 3 single pictures and the 3 grids from that ChatGPT chat in full size into
`assets/concepts/creatures/` (rock_snail.png, rock_snail_variants.png, cave_bat.png, cave_bat_variants.png,
rock_beetle.png, rock_beetle_variants.png), and log them in `CREDITS.md` as our own ChatGPT pictures.

## Step 2: build them by hand (Blender script), to match the pictures

- Start from the Nov 14 hand-built scripts (`tools/asset_forge/build_creatures.py`, `creature_kit.py`,
  `creature_textures.py`): they already have moving parts, poses (snail hiding, bat asleep, beetle charging) and
  15 individual versions. Rebuild their shapes and colours to match the approved pictures above.
- Write down what each picture shows first (body proportions, face, colours, horn/shell/wings), then check every
  step with a side-by-side picture: reference vs. model, same camera angle.
- **The 4 looks share one body:** mossy, frost, ember and spore are paint swaps plus add-ons (moss tufts, ice
  crystals, glowing cracks, little mushrooms), so they read as one family.
- One creature first (**Rock Beetle**), owner approves, then the other two.
- **Rock Beetle: hand-built Nov 15 (Claude 3), waiting for the owner's OK.** Script: `tools/asset_forge/builds/monster_rock_beetle.py`
  (`look=mossy|frost|ember|spore`); all four: `python tools/asset_forge/build_creatures.py <game>/assets/models only=rock_beetle`.
  The shell is ~25 fitted stone plates: seeds are scattered over the dome and each plate takes the patch of dome nearest its
  seed, so the plates fit like armour with thin dark cracks. Side-by-side check: `tools/asset_forge/creature_compare.py`
  (approved picture next to the model, same angle). Pictures: `docs/art/creatures-hand-built-2026-11-15/`.
  Score (Claude, honest): **6.5/10** vs the picture (the workbench ~8). Close: shape, plates, glowing back, horn, legs, face, all
  4 looks. Not yet: the plates are smoother and less chunky than the painting, the face is smaller, the legs are thinner.
  The old forged beetles are kept in `journey/forged_creatures_2026-11-15/` until the owner approves.
- Save as `assets/models/creatures/<monster_id>_<look>.glb` (the names the game loads today).

## Step 3: make them move (important)

The creature add-on keeps legs, wings, shell and eye stalks as separate named parts, each turning around its own
hinge; the game moves them (walk in tripods, wing beats, hiding). Keep the code's attack warning (eyes flash
before a hit) and the monster's collision size. Run the floating-parts check (`tools/asset_forge/islands.py`):
no loose legs.

## Rejected: how the forged versions were built (November 15, 2026, replaced by Step 2)

One command does it all: `tools/asset_forge/forge_creatures.py` (see the forge README, "Creatures").
1. `creature_sources.py` cuts each grid into its 4 variants and removes the background (12 pictures).
2. `forge.py` turns each picture into a 3D statue. **TRELLIS** (website) when a free Hugging Face key is in
   `<AI3D_HOME>/hf_token.txt`; otherwise **TripoSR** on the PC (used this time: the website allows ~2 minutes a day
   without a key, not enough for 12).
3. `creature_forge.py` (Blender): lines a camera up with the picture (outline match), paints the **face** from the
   picture (eyes with pupils, fangs), pulls the forge's colours toward the picture's, turns it to face forward,
   splits it into moving parts (snail: shell, soft body, eye stalks, peeking eyes; bat: two wings; beetle: six legs)
   and gives the eyes and glowing bits their own materials (eyes flash before an attack, glow blazes on a charge).
   Each variant is forged from its own picture, so the beetle's horns and the spore mushrooms keep their own shapes.
4. In the game (`monster_model.gd`): crystal variants wear their look (red = ember, blue = frost, green = spore,
   normal = mossy); the Great Rock Beetle is a bigger Rock Beetle. Collision sizes are unchanged.

Screenshots next to the workbench: `docs/art/creatures-2026-11-15/` (art preview: `-- seed=42 nomonsters artpreview creatures`).

**Scores (Claude, honest, vs the pictures; the workbench is about 8/10):** Cave Bat 6/10, Rock Snail 5/10,
Rock Beetle 5/10. They read as the approved designs, but TripoSR shapes are soft and blobby (the snail's mustache
is lost, beetle legs are short). **To improve:** put a free Hugging Face key in `<AI3D_HOME>/hf_token.txt` and run
the one command again: TRELLIS gives much sharper shapes and textures.

## Done when

- [ ] Next to the workbench in the art preview, the creature looks like it came from the same game. *(Close, not yet: 5–6 vs 8.)*
- [x] Its outline reads clearly as a black shape.
- [x] 2–3 colours; darker belly, lighter back; painted shading. *(From the forge, pulled toward the picture.)*
- [ ] Face has big eyes with a pupil and a highlight. *(Bats yes; snail and beetle eyes are small and soft.)*
- [x] Its weak spot or special part is easy to see. *(Glowing beetle backs, the snail's shell, the bat's fangs.)*
- [x] It moves (parts) and still warns before attacking.
- [x] Logged in `CREDITS.md` (our own ChatGPT pictures + the forge tools) and in `JOURNAL.md`.
