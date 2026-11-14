# Asset forge: ChatGPT picture → 3D model in the game

Free tools only. See `docs/design/ai-art-pipeline.md` for the why.

```
ChatGPT picture  →  3D model (TRELLIS.2 website or TripoSR on the PC)  →  Blender cleanup  →  assets/models/<kind>s/<name>.glb
```

## 1. Make the picture in ChatGPT

Copy this whole block into ChatGPT, then replace the last line with your object.

> Game asset concept for a 3D survival game about dwarves living underground.
> Style: chunky, slightly exaggerated stylized shapes with bold readable silhouettes (thick legs,
> oversized bolts and handles, a little bit cartoony and charming), but worn, rough and hand-made:
> chipped edges, dents, scratches, hand-painted texture with visible brush strokes. Earthy colors:
> warm browns, stone greys, moss green, rust and dull iron, with a small accent of warm glow
> (amber or orange) only where something gives light. Sturdy, heavy and old, built by dwarves.
> Picture rules: ONE object only, centered, the whole object visible with some space around it,
> front three-quarter view from slightly above, plain light-grey background, soft even light,
> no strong shadows, no ground, no text, no people.
> Object: **a dwarven workbench with a vice, a few hanging tools and a thick stone top**

Tips:
- Ask for 3–4 versions and pick one. Then: "Same object, keep the design exactly, make it again" to fix small things.
- Once you love 2–3 results, upload them with each new request: "Match the style of these pictures exactly."
- Never name another game or artist in a prompt.
- Simple, solid shapes turn into 3D better than thin, see-through or very detailed ones (chains, ropes, cloth fringes come out melted).

## 2. Turn it into a model

Put the picture anywhere (e.g. `Downloads`) and ask Claude: "forge this as a station called workbench". Claude runs:

```
<AI3D_HOME>/venv-web/Scripts/python tools/asset_forge/forge.py picture.png --name workbench --kind station
```

| Option | Meaning |
|---|---|
| `--kind item / prop / station / big` | Size and detail budget: 0.4 m / 1 m / 1.6 m / 3.5 m wide |
| `--engine trellis` (default) | Free TRELLIS.2 website: best quality. **Daily limit:** without an account only ~2 minutes of website computer time a day (not even one full model); a free Hugging Face token in `HF_TOKEN` gives more |
| `--engine triposr` | TripoSR on this PC: ~20 seconds, unlimited. Shapes OK, colors come out paler than the picture |
| `--rotate-z 90` | Turn it to face forward |
| `--raw model.glb` | Skip step 1, just clean an existing model (also give `--engine` it came from) |

Results: the model in `assets/models/<kind>s/`, plus a preview picture and the raw files in `<AI3D_HOME>/work/`.

## One-time setup (done on the gaming PC, November 14, 2026)

- **Blender 5.3** (free): `winget install BlenderFoundation.Blender`.
- **`AI3D_HOME`** (default `~/ai3d`, outside OneDrive and outside this repo, ~10 GB):
  - `venv/`: Python 3.12 + PyTorch (CUDA 12.8) + TripoSR's needs. Runs TripoSR.
  - `venv-web/`: small Python 3.12 with `gradio_client`, `rembg`, `onnxruntime`. Runs `forge.py`.
    (Two setups because the website client and TripoSR need different versions of one shared library.)
  - `TripoSR/`: copy of github.com/VAST-AI-Research/TripoSR (MIT) with three local changes:
    1. `tsr/models/isosurface.py`: falls back to scikit-image (the original part needs a C++/CUDA compiler).
    2. `requirements.txt`: unpinned old versions; `transformers<5` (version 5 renamed parts and breaks loading).
    3. `run.py`: background cutter set to `isnet-general-use` (see below).
- Optional: free Hugging Face account → token → set `HF_TOKEN`.

**Background-cutter trap:** new `rembg` versions use BRIA RMBG by default, which is **not free for
games we sell**. The TRELLIS website also uses BRIA unless the picture already has a see-through
background. So both our steps name `isnet-general-use` (Apache-2.0) on purpose, and `forge.py`
cuts the background out on this PC before sending anything to the website.

**What the cleanup does to each model:** welds split corners, removes crumbs, stands it up, scales it
to meters with its base at the floor, cuts triangles to the budget, bakes corner colors into a small
texture (Godot ignores corner colors), shrinks and mutes textures, makes it matte, exports `.glb`, renders
a preview.

Licences: TRELLIS.2 and TripoSR are MIT (fine to sell). Log every forged asset in `CREDITS.md`
and mark it as AI-made (Steam asks).
