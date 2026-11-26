## Nov 26: Armour picture-to-3D test, part 1: the copper chest made from the GPT picture

**What we did.** The owner loves the GPT copper armour picture more than our hand-built armour, so (as a one-time
test, rule-1 exception) Claude turned the picture into 3D. The PC's graphics card (RTX 3060 Ti, 8 GB) is too small
for Hunyuan3D 2.1, so the owner chose its free website first. Claude made a flat-lit chest sheet (front, back, both
sides) and a helmet sheet in ChatGPT, then sent the chest sheet to the website: it came back crisp (plates, buckle,
rivets, three skirt rows, 1.9 million triangles). A new Blender script, `tools/asset_forge/builds/armor_picture3d.py`,
fits it on the dwarf: arms posed down to match the sleeves, scaled round his body, pushed 1.2 cm off his skin, painted
from the picture itself, the plate tucked under his beard, and bones copied from his body so it bends with him.
The generated models stay outside the repo. The website's free daily limit ran out at the helmet, so the owner chose
the small Hunyuan3D 2 mini on the PC for the other pieces (next chat).

**Mistakes and hurdles (and fixes).**
- `git pull` was blocked by other chats' unsaved FEEDBACK edits. No stash: Claude read the needed files from
  `origin/main` and staged only its own line (built from the last saved file, not a partial patch).
- The first claim commit used a partial patch and also took another chat's sentence deletion. Fixed with a second
  commit that put the sentence back. Lesson: build the staged file from `HEAD` + your own change.
- The website script crashed saving the result (the answer is a dict, not a path). Claude found the model in the
  temp folder, so no daily quota was wasted, and fixed the script.
- Blender's Python has no PIL (picture library): painting failed. Fixed with Blender's own picture loader.
- The beard braids looked like they poked out of holes in the plate. Three tries: (1) only moved points *inside*
  a braid; (2) the plate is a thick shell, so its front face was more than 3 cm in front and got skipped; (3) Claude
  measured with rays instead of guessing and found that the braids were already on top: it was the beard's *top*,
  where it joins the chin, that the collar covered. Fixed by tucking the plate 3 cm behind the beard's front up to
  the collar, the same way the hand-built armour dents under the beard.
- Small thing left: a bit of grey shirt shows between the belt and the skirt.
