## Nov 26: Bronze armour gets its own look (F697 step 7)

**What we did**
- Made 2 ChatGPT pictures of the dwarf in bronze; the owner picked Option B (engraved knot patterns, warmer gold).
- Made an armour sheet (helm, mail, greaves, boots) and a texture sheet (knot bands, medallion, hammered plate),
  cut them into icons and kit textures (`tools/art/cut_bronze_armour_icons.py`, `tools/art/cut_bronze_textures.py`).
- First built all 4 pieces by hand in Blender (`items_gear.py`, commit 8692b1ad). They passed every check.
- The owner then said: "don't hand build it, use the healing-fountain method, it worked from the first try."
  So: cut each piece out of the sheet (rembg, the commercial-OK model), sent it to the free TRELLIS.2 website
  from a script (gradio_client), and reworked the result in `tools/asset_forge/builds/bronze_armour_trellis.py`
  (size, front, metal look, fewer triangles, drop crumbs). The helm came out well on the first try.
- MODEL-RULES rule 1 now names the bronze armour as the owner's second exception (after the fountain).

**Mistakes and hurdles**
- Rotated knee and toe domes landed on the floor: `dome()` bakes its position into the mesh, so turning the object
  turned it around the world centre. Fix: turn the mesh about its own spot.
- First commit failed: 4 journey `.glb` files are gitignored. Committed without them.
- Claude ran `rm` after a python step that had failed (python can't read `/c/...` paths), which deleted the
  saved website key. Had to read it again. Use `C:/` paths for Windows python.
- Claude wrongly told the owner they were already signed in to Hugging Face; the login page showed they weren't.
- The website's upload box sits inside a frame from another site, so the browser tool couldn't put files in it.
  Switched to the gradio_client script with a free read key (kept on the PC only, never in the repo).
- Blender's decimate stalls at about 26k triangles on TRELLIS models (paint seams block it). Next time ask
  TRELLIS itself for fewer triangles and a 2048 texture (`extract_glb(15000, 2048)`), which also makes the paint sharper.
- The free daily website time ran out after the helm (each piece asks for 2 minutes of GPU). Mail, greaves and
  boots wait for the next day; their cut-out pictures are ready in `journey/3d/trellis_bronze/`.
- Lesson: Claude should have asked "hand-built or the fountain way?" before building, since the fountain way worked so well.

**Left**
- Mail, greaves, boots through TRELLIS (script: start_session, preprocess_image, image_to_3d with seed 0 and "1024",
  extract_glb), then add their turn/height in `PIECES` and run the build script; remove them from `items_gear.py` BUILD.
- The worn bronze set on the dwarf.
