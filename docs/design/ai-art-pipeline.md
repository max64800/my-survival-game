# AI art pipeline: from "ChatGPT picture" to "thing you can place in the game"

*Written: November 14, 2026. Research + plan only. No game code was changed.*
*Goes with `visuals-plan.md` (the style rules in its section 5 apply to everything here).*

> **Decision (same day):** the owner chose **free tools only** (no $20/month). Built and tested:
> Blender + TripoSR on the PC + the free TRELLIS.2 website, all driven by one script.
> How to use it: `tools/asset_forge/README.md`. The paid-tool parts below are kept for reference.
> Art direction: **between Valheim and Grounded** (the ChatGPT style prompt in the README says this in our own words).

The owner's idea: ask ChatGPT for pictures of a thing (say, a workbench) from all sides,
then turn those pictures into a real 3D object you can place in the cave.

**Short answer: yes, this works today, and it is a real, common way to make game objects.**
But the pictures are only step 1. A middle step is needed: an "image → 3D" tool that turns the
pictures into a 3D model. And a cleanup step is needed after it, so the model fits our style
and doesn't slow the game down.

Words used below:
- **3D model / mesh** = the shape of an object, made of many small flat triangles ("polygons").
- **Texture** = the picture painted onto the shape (its colors, cracks, wood grain).
- **Turnaround sheet** = one picture showing the same object from the front, side and back.
- **GLB** = the file type for 3D models that Godot reads best (a "zip" of shape + textures).
- **API** = a way for a program (like Claude) to use a website's service directly, without clicking.
- **Blender** = a free 3D program. Claude can control it with scripts.

---

## 1. The pipeline (the owner's idea, made complete)

```
 1. ChatGPT picture     →  2. Turnaround sheet   →  3. Image → 3D tool   →  4. Cleanup        →  5. Into Godot
 (pick the design)         (front/side/back)        (Meshy, Tripo…)          (Blender script)      (placeable object)
```

### Step 1: Make the design picture (ChatGPT / OpenAI image model)
- Ask for **one object, plain grey or see-through background, soft even light, no shadows on the
  ground, whole object visible**. The 3D tool needs a "clean photo of a toy on a table", not a scene.
- Ask for **3–4 versions**, the owner picks the best. This is where AI is cheapest and most fun:
  trying 10 workbench ideas takes minutes.
- **Keep our style the same every time** with two tricks:
  1. A fixed **style prompt** pasted into every request (written from our style bible), for example:
     *"chunky low-poly game prop, slightly uneven hand-made shapes, muted earthy colors (brown,
     grey, moss green, rust), small hand-painted textures, dwarven, sturdy and old, plain light-grey
     background, front three-quarter view, even soft light."*
  2. A **style reference picture**: once we have 2–3 objects we love, we upload them with every new
     request ("make it look like these"). OpenAI's image models accept several input pictures.
- **Never** write "in the style of Valheim" (or any game). Our rule: never copy other games. We
  describe the *look in our own words* instead.

### Step 2: Make the turnaround (front, side, back)
- Feed the chosen picture back in: *"Same object, exact same design, shown from front, left side,
  back and right side, side by side, same scale, plain background."*
- Honest warning: AI pictures **drift** between views (a drawer on the front might vanish on the
  side). Check the views match before step 3. If they don't, use only the single best picture.
- Good news: the newest 3D tools often do fine from **one** picture for simple objects. The extra
  views help most for things whose back is different from their front (a furnace with a chimney,
  a character). Rule of thumb from the tool makers: start with one picture; add views only if the
  back comes out melted.

### Step 3: Turn pictures into a 3D model (the "image → 3D" tool)
This is the missing piece in the owner's idea. ChatGPT itself does **not** make 3D models. Separate
tools do. The main choices (November 2026):

| Tool | What it's good at | Cost (approx., check before buying) | Selling the game? |
|---|---|---|---|
| **Meshy** (meshy.ai) | Best all-rounder for props. Has a **low-poly mode** (fewer triangles, fits our chunky look), multi-picture input, free auto-rigging, an API. | Free: 100 credits/mo. Pro ≈ $20/mo for 1,000 credits ≈ 40 models. | Free plan = CC BY (must credit Meshy). **Paid plans: we own it.** |
| **Tripo** (tripo3d.ai) | Fast, strong on characters, 4-view input (front/left/back/right). | Pro ≈ $16–20/mo. | Free plan: not for selling. **Paid: yes.** |
| **Rodin / Hyper3D** | Highest quality, cleanest shapes. | Premium price. | Paid: yes. |
| **TRELLIS.2** (Microsoft, free) | Runs on our own PC, MIT licence (free for anything). | Free, but needs a strong graphics card. Our 3060 Ti (8 GB) only manages "low memory" mode, slower and lower detail. Fiddly to install. | Yes. |
| **Hunyuan3D** (Tencent, free) | Good free model, multi-view. | Free. | ⚠️ **Its licence does not allow use in the EU, UK or South Korea.** Only usable if we live elsewhere. |

**Recommendation: Meshy Pro for one month as a test** (≈ $20). It has the low-poly mode we need,
we own what we make, and it has an API so Claude can run it from a script.

### Step 4: Cleanup (the step most people skip, and why AI models often look "off" in games)
AI-made 3D models usually have these problems. All of them can be fixed by a **Blender script
that Claude writes once and runs on every model**, no clicking needed:

| Problem | Why it matters | Fix (automatic) |
|---|---|---|
| Way too many triangles (often 50,000–500,000) | Slows the game, especially with 4 players and many objects | Use low-poly mode, then shrink to a budget: small item ≈ 1–3k, station ≈ 3–8k triangles |
| Big, sharp, realistic textures (2K–4K) | Clashes with our "small, crunchy" style | Shrink to 256 px, push colors toward our palette |
| Shadows and shine **painted into** the texture | Our lantern light can't change them, so the object looks pasted-in | Ask for "flat even light" in step 1; darken/flatten in cleanup |
| Wrong size and wrong "floor point" | A workbench the size of a house, or floating | Script scales to real meters (workbench ≈ 1.6 m wide) and puts the base at the floor |
| Funny shapes underneath / inside | Mostly harmless, but wasteful | Remove hidden bits |

Claude can drive Blender two ways: (a) a plain Blender script run from the command line (simple,
reliable), or (b) the "Blender MCP" helper, which lets Claude look at and edit models live. Start
with (a).

### Step 5: Put it in Godot as a real, placeable thing
1. Save the cleaned model as `assets/models/stations/workbench.glb`. Godot imports it automatically.
2. Make a small Godot scene around it: the model + a **simple invisible box for collisions** (so you
   bump into it; never use the detailed shape for this, it's slow) + an "interact" spot.
3. Add it to the station/item data (the progression doc wants one data file per station).
4. Placing it goes through the building system (Step 4 of the roadmap: ghost preview → request →
   host approves → everyone sees it). The model is just "what it looks like"; the rules are the same
   for a box or a beautiful AI workbench. **So art can be swapped in any time without breaking co-op.**
5. Log it in `CREDITS.md` ("Made by us with OpenAI image + Meshy, paid plan, date").
6. Autopilot screenshot → owner looks → keep or redo.

### Can this be one button?
Mostly yes. Claude can write a small tool (`tools/asset_forge/`) that does steps 1–5 from one line:
`forge workbench "a sturdy dwarven workbench with a vice and hanging tools"`.
It would call the OpenAI and Meshy APIs, run the Blender cleanup, drop the file into the game and take
a screenshot. **The owner still picks the design in step 1 and approves the screenshot at the end.**
Needs: an OpenAI API key and a Meshy API key, stored on the PC only (never in the public repo).

---

## 2. Other ways to use AI for our art (some are better than the owner's idea for some things)

| Way | Best for | Why |
|---|---|---|
| **A. Full AI 3D** (the pipeline above) | Organic, lumpy things: mushrooms, crystals, rocks, statues, ruins, monsters, decorations | AI is great at "messy natural shapes" that are slow to build by hand |
| **B. AI textures on simple shapes** | Box-like things: **workbench, chests, doors, walls, beams, planks, building pieces** | A workbench is mostly boxes. Claude builds the clean low-poly shape (in Blender or Godot), and ChatGPT makes the **wood / stone / metal textures**. Cleaner, lighter, more matching than AI 3D. Building pieces *must* line up on a grid, which AI 3D can't do well. |
| **C. AI pictures for rock textures** | The dig-anywhere terrain (visuals plan step V2) | Ask for "seamless tileable mossy cave rock texture, hand-painted, 256 px". Could replace or mix with the free ambientCG textures. |
| **D. AI pictures as icons** | Inventory icons, recipe pages, HUD, map symbols | Easiest win of all: 2D in, 2D out. No 3D step. Great for consistency too: one style prompt for every icon. |
| **E. AI concept art only** | The dwarf, bosses, biome mood | Use pictures to *decide* the look, then build the real thing with the free Quaternius body/animations or a hired artist (visuals plan). |
| **F. AI 3D + auto-rig for monsters** | Animals and monsters | Meshy/Tripo can add a skeleton automatically. Works for simple creatures; still needs animations (Quaternius packs or retargeting). Characters are where AI 3D struggles most. |

**Our best mix:** B for the workbench and all building pieces, A for natural props and decorations,
C and D for textures and icons, E for the dwarf. Not one method for everything.

---

## 3. Rules and risks

- **Steam:** since January 2026, Steam asks us to say on the store page if players see AI-made art
  ("pre-generated AI content"). Allowed, just disclosed. Some players dislike AI art, so we keep
  a list of which assets are AI-made (in `CREDITS.md`) and can swap them later.
- **Selling:** use **paid** plans for anything that ships. Free plans on Meshy/Tripo are "credit the
  tool" or "not for selling". OpenAI's terms say we own what we make (third-party summaries agree;
  OpenAI's terms page blocked our reader, so the owner should read it once before we rely on it).
- **Copyright gap:** in the US, pure AI pictures may not be protected by copyright. In plain words:
  we may use them, but we might not be able to stop others from copying them. Fine for props; one
  more reason to make the dwarf and the logo with a human artist.
- **Public repo:** AI assets we make on a paid plan are ours, so they can go in the repo. **API keys
  never go in the repo.**
- **Don't make it look like another game:** never name other games or artists in prompts.
- **Style drift** is the big practical risk: 30 AI objects made on 30 days can look like 30
  different games. The fixed style prompt, the reference pictures and the automatic cleanup (same
  texture size, same palette) are what keep everything matching.

---

## 4. Suggested first test (about 1 day, ≈ $20)

Do the **workbench three ways** and put them side by side in the cave with the autopilot camera:
1. **Full AI 3D:** ChatGPT picture → Meshy low-poly → Blender cleanup.
2. **AI textures on a Claude-built shape** (way B).
3. **Today's code shapes** (for comparison).

Plus one **mushroom** made with full AI 3D (to test the "natural shapes" case), and **5 inventory
icons** (way D). The owner looks at the screenshots and picks. Then we write the real tool.

Do it **after visuals step V1 (light)**: an object can't be judged in the wrong light.

## 5. Questions for the owner

★ = default (used if you say nothing). Answer with number + letter, e.g. "AI2B".

- **AI1. Paid tools:** (A) ★ Meshy Pro for one month (≈ $20) + your ChatGPT, (B) free only (TRELLIS.2 on our PC; slower, rougher, more setup), (C) no AI 3D, AI only for textures and icons.
- **AI2. Where do you live?** Only matters for Hunyuan3D (not allowed in the EU, UK, South Korea). (A) ★ we skip Hunyuan3D either way, (B) tell Claude, it may unlock a free option.
- **AI3. ChatGPT app or API?** (A) ★ start with the ChatGPT app (you make the pictures, drop them in a folder, Claude does the rest), (B) get an OpenAI API key so Claude can make the pictures itself (pay per picture, a few cents each).
- **AI4. How much AI art in the final game?** (A) ★ props, decorations, textures, icons yes; the dwarf and the logo made by a human, (B) AI wherever it looks good, (C) AI only for prototypes, replace everything before release.

## 6. Sources

- Meshy credits and licences (official): https://docs.meshy.ai/pricing
- Meshy low-poly mode: https://www.meshy.ai/tutorials/make-low-poly-3d-models
- Meshy API models / deprecations: https://docs.meshy.ai/en/api/models
- Tripo pricing summaries: https://toolradar.com/tools/tripo-ai/pricing , https://www.costbench.com/software/ai-3d-generation/tripo-ai/free-plan/
- Tool comparisons (vendor-written, treat as rough): https://wavect.io/blog/ai-3d-model-generators-game-development-2026/ , https://vsquad.art/blog/articles/best-ai-3d-generators/ , https://www.meshy.ai/blog/best-ai-tools-for-3d-game-assets
- Multi-view input tips (Rodin Gen-2): https://runware.ai/docs/models/hyper3d-rodin-gen-2/guides/image-and-text-to-3d
- Hunyuan3D licence (territory clause): https://huggingface.co/tencent/Hunyuan3D-2/blob/main/LICENSE
- TRELLIS.2 low-memory notes: https://trellis2.app/blog/trellis-2-low-vram
- OpenAI image generation guide: https://developers.openai.com/api/docs/guides/image-generation
- OpenAI transparent backgrounds: https://x.com/OpenAIDevs/status/2090536933571330440
- OpenAI output ownership (summary): https://conductatlas.com/platform/openai/terms-of-use-row/output-ownership-and-content-license/
- Blender MCP: https://mcpservers.org/servers/ahujasid/blender-mcp
- Cleanup problems with AI models: https://sloyd.ai/blog/7-best-practices-for-ai-generated-3d-models-in-game-development
- Steam AI disclosure (Jan 2026): https://www.pcgamer.com/software/ai/steam-updates-ai-disclosure-form-to-specify-that-its-focused-on-ai-generated-content-that-is-consumed-by-players-not-efficiency-tools-used-behind-the-scenes/
