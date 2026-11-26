## 2026-11-26: Bronze try-on page "doesn't load" (F697)

**What we did:** The owner said the round-2 bronze try-on 3D page didn't load. Fixed it and checked the live page myself.

**Hurdle (Claude's own):** the page's model file (tryon.json) keeps its mesh and pictures packed inside a "data:" link.
The page host now blocks the loader from opening "data:" links, so three.js said "Failed to load buffer" and the dwarf
never showed. My local test server doesn't block them, so the local test passed and hid the problem.

**Fix:** the page now reads tryon.json itself, unpacks the packed data in its own code, builds a GLB in memory and
hands that to `GLTFLoader.parse`. No "data:" link is opened. Checked on the live artifact: the dwarf shows with the
full bronze set (about 20 seconds to load).

**Lesson:** for big 3D pages, unpack the model in the page instead of letting the loader open "data:" links, and
always check the live page, not only the local copy.
