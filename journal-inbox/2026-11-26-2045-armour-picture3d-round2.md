## 2026-11-26 — F914 armour picture-to-3D test, round 2 (Claude)

**What we did**
- The owner looked at round 1 ("a bit better, needs adjusting") and chose "mix both". Round 2 does all of it:
  - The plated legs (thigh plates + tall greaves) are back. The hand-built copper file already had them, so the try-on tool and the page export only needed to wear the legs too.
  - Narrower skirt: below the belt the chest piece is squeezed in (sides to 80%, front-to-back to 86%).
  - Sharper: the game copy has 4x the faces (chest 20k, helmet 16k) and 4x the picture size (4096 / 2048). The big change is that the colour bake now reads the 4 ChatGPT pictures directly. Before, each point got one colour (points 3-4 mm apart), and that blurred the pictures.
  - Hand-built detail: three riveted plates on the back (it was plain and blurry), plus a rolled rim with rivets round the skirt hem and the neck.
  - No shirt showing: the hand-built leather undercoat stays wherever the plate doesn't cover it. While the picture chest is worn, the shirt turns dark padding brown (`DwarfRig._pad_shirt_under`).
- Comparison page updated (same link) and checked in headless Chrome.
- Licence check: **the Hunyuan3D licence does not cover the EU, UK or South Korea, and that includes what it makes.** The pieces are marked "TEST ONLY, not cleared to ship" in CREDITS.md.

**Mistakes and hurdles**
- The back plates first came out as long spikes. Each plate feels for the surface with level rays, and near the top some rays hit the shoulder pads that stick far out, so the plate stretched to reach them. Found by turning things off one at a time (the leg check vs. the back plates). Fix: ignore hits more than 3 cm farther out than the plate's middle.
- The hem rim and the back of the neck came out white in the game. The built parts' "how much each picture counts" layer was never filled in, and a new colour layer in Blender starts white = "all 4 pictures count fully", so they showed the pictures' white background. Fix: fill it with zeros.
- Shirt still showed under the arms after keeping more leather: the white was the shirt sleeve, which the leather doesn't cover. Fix: darken the shirt while the chest piece is worn.
- My page check first showed someone else's page: another chat's server was already on port 8765. Used a free port.
- The page export doesn't carry the dark shirt paint, so a light patch by the throat still shows on the page (the game is fine).
