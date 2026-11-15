# The 3D journey: before and after

Kept on purpose for the videos and the dev journal. The game itself only uses `assets/models/`.

| Folder | What | How it was made | Verdict |
|---|---|---|---|
| `v1_ai_triposr/` | 179 models (stations, items, tools) | ChatGPT icon picture → TripoSR (free AI, ~20 s each) → Blender cleanup | Right shapes from the front, but soft and blobby. Owner: "looks like it has been made of Play-Doh and squished." |
| `v2_hand_built/` | Rebuilt by hand, one by one | Claude writes a Blender script per model from chunky parts (stone blocks, planks, beams, metal bands, rivets, gems) + hand-painted tiling textures made with ChatGPT | Crisp, chunky, hand-painted: the Valheim + Grounded look |

Each `v2_hand_built/` model has a preview `.png` (and the `_concept.png` picture it was built from, where there is one). The models themselves are in `assets/models/` (a local `.glb` copy here is not saved to GitHub).
Overview sheets of v1: `v1_ai_triposr/overview_stations.png`, `overview_items.png`.
The owner's screenshot that started the switch: `v1_ai_triposr/gem_bench_owner_screenshot.png`.

Build scripts for v2 live in `tools/asset_forge/builds/<name>.py` (shared parts: `tools/asset_forge/kit.py`).
