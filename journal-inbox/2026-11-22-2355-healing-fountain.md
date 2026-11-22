## 2026-11-22 — F782: a new dungeon healing fountain (not in the game yet) + F706 TRELLIS test

**What we did**
- The owner doesn't like the mushroom fountain (`decor/mushroom_fountain.glb`, the "Healing basin" in Mossgate, Lampwick, Mossprop and Pell).
- ChatGPT made 4 ideas. The owner picked design 1: a stone dwarf face pours glowing green water into a round stone basin, with mine timbers, copper straps, roots and moss. ChatGPT then drew it from the front, side, back and top. Both pictures are in `assets/concepts/healing-fountain/` and logged in CREDITS.
- F706 test: those 4 views went into the free TRELLIS website, which made a rough 3D shape (`journey/3d/trellis_f706/`). It was used only as a shape guide (model rule 1). A local low-memory TRELLIS build for 8 GB cards exists, but it is a multi-GB install, so I used the website.
- Built the real model by script: `tools/asset_forge/builds/healing_fountain.py` makes `journey/3d/v2_hand_built/decor/healing_fountain.glb`. It is 1.2 m (the old one is 0.95 m) and passes the model checks.
- 3D page with the old fountain, the TRELLIS shape and the new one side by side, loaded still: https://claude.ai/artifact/UTL6zpSW5gxJSSvhRQbBps

**Mistakes and hurdles**
- Render round 1 was 1.39 m wide. The roots looked like splayed sticks, the face didn't read, and the water and moss were too bright. Fix: a lighter face stone with bigger features, roots that hug the posts, flatter darker moss, and copper plates moved up.
- The model checker found shimmer at the mouth: the dark spout cylinder's end was in the same place as the stone face. Fix: I made the cylinder shorter and moved it back.
- ChatGPT: `wait_for` timed out twice. Checking the images with a script worked better. The second image has the same alt text as the first, so take the last big image.
- On the page, the TRELLIS model looked black and sideways. It has no "metal" setting, and the default is full metal, which looks black without reflections. Fix: the page sets metal 0 and turns it 90°.
- The new water looked pale white on the page. Fix: a deeper, greener water colour in the build script.
- Artifact pages don't serve `.glb` files. Packing the models as `.json` failed too: the page's safety rules block the hidden `data:` links inside them. Fix: each model goes up as a base64 `.txt` file, and the page unpacks it with `loader.parse`.
- After those failed loads, Chrome blocked 3D drawing for the artifact site ("context lost, blocked"), and then the Chrome connection dropped. So the final live page was only checked on the local copy before the `.txt` change. If the page shows blank boxes, restart Chrome.
- F780 was already taken by another chat (spiral stairs), so the fountain became F782. FEEDBACK and CREDITS also held other chats' unsaved edits, so I committed only my own lines.
