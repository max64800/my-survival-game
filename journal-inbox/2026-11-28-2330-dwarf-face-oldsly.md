## Nov 28, 2026: new dwarf face 3, the old sly one (F737)

**What we did**
- The owner asked for an old dwarf with white hair who looks sneaky and very smart. We made our own dwarf, not a copy of any TV character.
- ChatGPT drew 3 ideas. The owner picked A: both sides of the head shaved, a white crest on top that runs into one long braid down his back, dark soot paint round the eyes, and a thin beard that ends in one braid with a copper ring.
- Claude built him in Blender by script, as face "oldsly" in `tools/asset_forge/builds/dwarf_head.py`. New parts: shaved sides with a pale stubble speckle, combed crest locks (`build_crest`), sly brows (one raised, one low and flat), a crooked half-smile with a dimple, deep old-age wrinkles, a thinner face, soot round the eyes, and softer ink lines on the white hair.
- The whole dwarf is `assets/characters/dwarf/dwarf_body_oldsly.glb`. `dwarf_rig.gd` knows the name, so a test run can use `face=oldsly`.
- A new 3D page lets the owner turn him round and watch him run: https://claude.ai/artifact/X6VE4ga9UNcDUwhxKscmPK

**Mistakes and hurdles (and fixes)**
- The ChatGPT upload failed on the "Add files" button. The real upload button is "Add photos & files" inside that menu.
- Waiting for ChatGPT's "Generated image 2" never finished, because each new picture is also called "Generated image 1". Fix: take the last picture with that name.
- The review tool crashed (the picture sizes didn't match) because Claude's front/side reference picture was the wrong size. Fix: lay it out on the same 1774 x 887 canvas as the topknot picture.
- Round 1: the soot was too faint, the dark lines on the white hair looked like dirt, a white ball stuck out under the chin, and the raised brow sat too high. Round 2 fixed all four: stronger soot, softer hair lines, no chin ball when the beard has a braid, and a lower brow.
- Small things left for the owner to judge: the moustache hides most of the half-smile, the brows look a bit fuzzy, and the side beard near the ears is lumpy.

**Next:** the owner's look at face 3, then face 4 (wild black mane, hooked nose, 1 braid), then the face picker when you start a new world or join one.
