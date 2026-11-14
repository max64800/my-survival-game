# Creature style guide: make monsters look like the Forge workbench

**Read this before making or remaking any creature.** (Owner's request, November 14, 2026.)

## The problem

The Forge **workbench** looks great. The **Rock Snail, Cave Bat and Rock Beetles** look plain. The reason is
mostly *how* they were made, not the description:

- **Workbench:** a real 3D model with **hand-painted textures** (made with the asset forge, `tools/asset_forge/`).
- **Monsters:** built in code (`src/combat/monster_model.gd`) from balls, tubes and cones, with one
  computer pattern stretched over the whole body.

**So: rebuild the creatures the same way as the workbench** (ChatGPT picture → asset forge → Blender
cleanup), using the rules below. Keep the code-built bodies only as a fallback.

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

## Step 2: turn the pictures into models

Follow `tools/asset_forge/README.md`: "forge this as a big prop called rock_snail" and so on.
- Snail, small beetle and bat: `--kind prop` (about 1 m). Great Rock Beetle: `--kind big` (3.5 m).
- Save them as `assets/models/creatures/<monster_id>.glb`, matching the ids in `src/combat/monsters.gd`.

## Step 3: make them move (important)

A forged model is one solid statue with no skeleton, so legs and wings can't move by themselves. Pick one,
in this order:
1. **Split into parts in Blender** (body, shell, head, each wing, legs as one or two groups). The game then
   moves the parts like it does today: bob, tilt, wing flaps, a little leg shuffle. This is the quickest, and it
   looks fine for stylized creatures.
2. **Rig and animate in Blender** (bones, walk/attack/hurt clips) for the best result. It takes more work per
   creature.

Whichever way: keep the code's attack warning (eyes flash before a hit) and the monster's collision size.

## Done when

- [ ] Next to the workbench in the art preview, the creature looks like it came from the same game.
- [ ] Its outline reads clearly as a black shape.
- [ ] 2–3 colours; darker belly, lighter back; painted shading.
- [ ] Face has big eyes with a pupil and a highlight.
- [ ] Its weak spot or special part is easy to see.
- [ ] It moves (parts or bones) and still warns before attacking.
- [ ] Logged in `CREDITS.md` (our own ChatGPT pictures + the forge tools) and in `JOURNAL.md`.
