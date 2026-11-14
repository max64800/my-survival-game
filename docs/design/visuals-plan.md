# Visuals plan: from "toy blocks" to "old, dark, cozy dwarf cave"

*Written: November 14, 2026. Research + plan only. No game code was changed.*

Goal: make the game look less like a toy (Roblox-y) and more like Valheim: rough, moody, hand-made,
with real animations for running, jumping, swinging and fighting.

We are **not** copying Valheim. We borrow its *recipe* (simple shapes + rough low-detail textures +
strong light and fog), and use it to make our own look.

---

## 1. Why it looks like Roblox right now

Checked in the code (`src/world/terrain.gdshader`, `src/player/dwarf_model.gd`, `src/main.gd`):

| What we have now | Why it feels "toy" |
|---|---|
| Rock is a flat color + soft noise. No pictures (textures) on it. | Real rock has cracks, pebbles, grain. Smooth color = plastic. |
| The dwarf is built from perfect balls, tubes and boxes. | Perfect math shapes are the #1 "Roblox" signal. |
| Only the right arm moves (it rotates to swing). Legs never walk. | Characters that slide around look like game pieces, not people. |
| Colors are fairly bright and clean (blue tunic, orange beard). | Toy colors. Valheim uses dirty, muted colors. |
| The cave has a strong blue "fill light" everywhere (ambient 0.6). | When everything is lit, the lantern doesn't matter and nothing feels scary or cozy. |
| Light fog, no light beams, no dust in the air. | The air feels empty. Atmosphere comes from what floats in the air. |

## 2. The Valheim recipe (what we learned)

Valheim's own description of its style: *low-resolution textures and simple shapes, mixed with
modern lighting, materials and screen effects.* In simple words:

1. **Cheap stuff, expensive light.** Models are simple, textures are small and a bit pixel-y. But the
   light, shadows, fog and weather are fancy. The light does the heavy lifting.
2. **Small, rough textures.** Textures are tiny pictures (like 128×128 pixels) shown a bit "crunchy".
   That gives a hand-painted, old-school feel instead of a plastic one.
3. **Muted, earthy colors.** Browns, greys, mossy greens. Bright colors are saved for special
   things (fire, magic, ores, gems), so they pop.
4. **Thick air.** Fog, light beams through the fog, floating dust, sparks, embers.
5. **Strong dark and light.** Deep shadows; warm light (fire) against cool dark (night). That
   contrast is what makes a fire feel cozy.

For an **underground** game this recipe fits even better: the lantern is our "sun".

## 3. The plan, step by step

Each step must be playable before the next (our roadmap rule). Steps are ordered by
**biggest change for least work** first.

### Step V0: Get ready (half a day)
- **Fix the frame rate first.** The PC does only ~50 FPS (journal, Day 3). New lights and fog
  cost speed. If we add them before fixing this, the game will crawl.
- **Before/after photo setup.** Add fixed camera spots to the autopilot so every visual change gets
  the same screenshots. Then we can compare "before" and "after" side by side.
- **Pick the branch.** The newest game (monsters, jungle, water) lives on the `fungal-jungle` branch,
  not `main`. Visual work should start from the newest one.

### Step V1: Light and air (1–2 days, biggest win, no downloads needed)
Words: *ambient light* = the soft "everywhere" light. *Volumetric fog* = fog that light beams shine through.
*Color grading* = a photo filter for the whole game.

- **Darker cave.** Cut the blue everywhere-light way down, so the lantern really matters.
- **Lantern casts shadows** and lights up the fog (light beams around you). Godot has this built in
  ("volumetric fog", Forward+ only, which we use).
- **Fog pockets** in big caves and over water (Godot "FogVolume"), not one flat fog everywhere.
- **Glow crystals and mushrooms give real light** (only the nearest ones, to save speed).
- **Floating dust and spores** in the lantern light (small particle effects).
- **Color grading per biome:** Mossy = warm green-brown; Fungal Jungle = teal and purple.
  Godot supports a "color look-up picture" (LUT) for this.
- **Not using:** SDFGI (Godot's automatic bounced light). It is made for worlds that don't change.
  Our world changes every time you dig, so it would flicker and cost a lot of speed.

### Step V2: Real rock textures (2–3 days)
Word: *triplanar* = painting a picture onto a shape from 3 sides (top, front, side), so it works on
any shape. Our dig-anywhere terrain has no "wrapping paper" layout, so this is the standard way
(the Voxel Tools docs say the same).

- Replace the flat colors with **small textures**: moss, stone, dirt, copper ore, border rock,
  plus jungle ones later. Each texture also gets a **bump map** (normal map) so cracks catch the light.
- Our shader already knows which 4 materials blend at each spot. We just swap "color" for "picture".
  Stored as one **texture array** (a stack of pictures), which is the fast way.
- **Valheim crunch:** shrink textures to 128–256 pixels, use slightly "crunchy" filtering.
  Optional: a known Godot trick called "sub-texel dithering" that keeps them crunchy but not blurry.
- **Moss on top, rock on the sides:** the shader puts moss/dirt on floors and bare rock on walls,
  automatically, by checking which way the surface faces.
- **Where textures come from:** ambientCG and Poly Haven (both CC0 = free for anything, even
  selling). We shrink them and push their colors toward our palette so they look hand-made, not
  photo-real. Later we can paint our own.
- Try the rock with **smooth shading** instead of today's flat facets. Facets + flat color = toy.
  Smooth + texture = rock. We'll compare screenshots and keep the better one.

### Step V3: Better shapes for the world (2–4 days)
- Crystals, mushrooms, rocks, stalactites: **lumpy, uneven, never perfectly round**.
  Two ways: (a) CC0 nature packs from Quaternius, recolored to our palette;
  (b) our code makes shapes and then "wobbles" the corners with noise, so no two are the same.
- Add **small clutter** (pebbles, bones, roots, old mine beams) near cave floors. Small things
  everywhere make a world feel real.
- Same texture style (small, rough) on all props, so everything belongs together.

### Step V4: The dwarf, and real animations (4–7 days)
Words: *rig* = a hidden skeleton inside a 3D model that bends it. *Retarget* = moving animations
from one skeleton onto another.

**The best free source we found: Quaternius (CC0).**
- **Universal Animation Library 1 & 2:** 250+ animations on one shared skeleton. Walk in 8
  directions, jog, sprint, jump, crouch, crawl, swim, sit, death, push, melee sword combos
  (3- and 4-hit), farming, fishing, emotes. Made to work in Godot. The free "Standard" version
  has about 60–70% of the animations; the full version is "pay what you want" (from ~$15–20).
- **Universal Base Characters + Modular Fantasy Outfits:** bodies and clothes on the *same*
  skeleton, so all those animations work on them right away.

**Plan for our dwarf:**
1. Start from a Quaternius base body. Make it a dwarf: shorter legs, wider body, big hands.
2. Add our own beard, helmet, belt and boots (our own design, so the dwarf is *ours*).
3. Plug in the animations with Godot's built-in retargeting (it has a "Humanoid" skeleton preset).
4. Build the **animation brain** (Godot "AnimationTree"):
   - **Legs:** idle → walk → run → sprint, blended by speed. Jump, fall, land.
   - **Upper body (separate layer):** swing pickaxe, attack, block, hold lantern, aim crossbow.
     Separate layers mean you can **swing while walking**.
   - **One-shots:** get hit, fall over, eat, drink.
5. **The dig happens on the hit frame.** The swing animation sends "hit now!" at the exact
   moment the pick touches the rock (we already have a `swing_impact` signal for this).
6. **Co-op ready:** only the *state* travels over the internet ("running, speed 4, swinging").
   Each computer plays the animation itself. Cheap and smooth.

**A pickaxe swing:** the packs have sword chops and farming (hoe) swings, which can stand in.
A real "mining swing" may need to be made: either we edit one in Blender (free 3D program) or
pay an animator.

**Monsters and animals:** Quaternius also has CC0 monster and animal packs. Check each one's
license page before using. Our own monster designs come first; packs are just a starting point.

### Step V5: Juice (ongoing)
- Dig debris: little rock chunks with the rock's texture fly out and bounce.
- Sparks when the pick hits ore, dust puff on landing, footstep dust.
- Lantern sways when you walk. Camera bob and small shakes on big hits.
- Water: proper wet, dark, reflective look.

## 4. Where to get things (and what to avoid)

| Source | What | License | Use it? |
|---|---|---|---|
| **Quaternius** (quaternius.com) | Animations (250+), base bodies, fantasy outfits, nature, monsters | CC0 | ✅ **Main source** |
| **ambientCG** | Rock, dirt, moss, wood, metal textures | CC0 | ✅ |
| **Poly Haven** | Textures, rocks, some models | CC0 | ✅ |
| **OpenGameArt** | Mixed bag | Each item different | ⚠️ Only items marked CC0 |
| **Mixamo** (Adobe) | Huge animation library | Free, but **not** CC0. Raw files can't be shared on their own. Unclear outside Unity. | ❌ Our GitHub repo is **public**, so the files would be "shared". Too risky. |
| **Synty** (POLYGON packs) | Paid low-poly packs | Paid licence, edited files can't be shared, Godot "not supported" | ❌ Same public-repo problem, and their look is very recognizable. |
| **AI 3D makers** (Meshy, Tripo) | Generate models from text | Free tiers can't be sold or need credit; paid tiers OK | ⚠️ Maybe for rough ideas. Steam requires us to say so on the store page if players see AI-made art. |
| **Hire an artist** (later) | A one-of-a-kind dwarf on the same skeleton | We own it | ⭐ Best for the final hero dwarf, once the game is fun |

**Important rule found during research:** because our GitHub repo is public, **anything in it is
"shared with the world"**. CC0 is fine. Paid or "don't redistribute" assets can never go in the repo.
Every asset goes in `CREDITS.md` the day it is added (existing rule).

## 5. Our style rules (the "style bible")

1. **Palette:** earthy and muted (brown, grey, moss, rust). Bright colors only for light, fire,
   ores, gems, magic and danger.
2. **Textures:** small (128–256 px), rough, a bit crunchy. Same style on terrain, props and characters.
3. **Shapes:** simple, chunky and **uneven**. No perfect balls or tubes for natural things.
4. **Light:** the lantern is the sun. Warm light against cool darkness. Darkness is allowed.
5. **Air:** always something in it (dust, spores, mist).
6. **Dwarves:** short, wide, heavy. Big beard, big hands, big boots. They should look strong and old.

## 6. Speed budget

The look must not cost fun. Target: **60 FPS or more** on the gaming PC (3060 Ti) with 4 players.
- At most ~8 lights casting shadows at once (lanterns first, then nearest crystals).
- Volumetric fog at medium quality. A settings menu later can turn it down.
- Measure FPS with the autopilot after every step.

## 7. Questions for the owner

Same as the other docs: ★ is the default. Say the number and letter to change it (for example "V2B").

- **V1. Dwarf model:** (A) ★ start from the free Quaternius body + our own beard/helmet/clothes, (B) hire an artist now, (C) AI-made model to start.
- **V2. Spend ~$15–35** on the full Quaternius packs (more animations, source files)? (A) ★ yes, (B) free versions only.
- **V3. Rock look:** (A) ★ try smooth + textures and compare with screenshots, (B) keep the flat facets.
- **V4. How dark:** (A) ★ really dark outside the lantern (survival, cozy-scary), (B) medium, always see a bit.
- **V5. Camera:** visuals look very different first-person vs third-person. Keep the current camera? (A) ★ yes, (B) let's talk.

## 8. Sources

- Quaternius Universal Animation Library: https://quaternius.com/packs/universalanimationlibrary.html
- Quaternius Universal Animation Library 2: https://quaternius.com/packs/universalanimationlibrary2.html
- Quaternius Universal Base Characters: https://quaternius.com/packs/universalbasecharacters.html
- Quaternius Modular Character Outfits – Fantasy: https://quaternius.com/packs/modularcharacteroutfitsfantasy.html
- Godot docs, retargeting 3D skeletons: https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.html
- Godot docs, volumetric fog: https://docs.godotengine.org/en/4.4/tutorials/3d/volumetric_fog.html
- Voxel Tools, smooth terrain texturing: https://voxel-tools.readthedocs.io/en/latest/smooth_terrain/
- Poly Haven license FAQ: https://docs.polyhaven.com/en/faq
- Sub-texel dithering shader: https://godotshaders.com/shader/sub-texel-dithering-for-low-res-textures-and-pixel-art/
- Valheim graphics discussion: https://screenrant.com/valheim-good-graphics-lighting-low-resolution-textures/
- Mixamo licensing FAQ (forum): https://community.adobe.com/t5/mixamo-discussions/mixamo-faq-licensing-royalties-ownership-eula-and-tos/td-p/13234775
- Synty FAQ: https://syntystore.com/community/faq
- Steam AI disclosure update (Jan 2026): https://www.pcgamer.com/software/ai/steam-updates-ai-disclosure-form-to-specify-that-its-focused-on-ai-generated-content-that-is-consumed-by-players-not-efficiency-tools-used-behind-the-scenes/
