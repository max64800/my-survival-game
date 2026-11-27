## 2026-11-27: Bronze armour round 5, shoulder spikes (F914)

**What we did:** The owner liked round 4 ("This is great") and asked for spikes on the shoulders like the helmet horns, a little thicker.
- The helmet horn maker became one shared tool (`horn_tube()` in `copper_plate_armor.py`). The helmet horns and the new shoulder spikes both use it.
- Each bronze shoulder cap now has a horn-spike, 2.6 cm thick at the base (the helmet horns are 1.9 cm), with a knot ring where it leaves the cap. It is its own piece, `armor_chest_spike`, and the game wears it automatically.
- To keep the spike from bending when the arm moves, it copies the "bones" (which body parts pull on it) of the exact cap spot it stands on. That way it rides the cap like it is glued on.
- Copper is unchanged. The fit test passes. The page is updated to v34 (bronze is now 7 parts).

**Hurdles:**
- First try: the spikes were straight cones pointing out and a bit up. They didn't look like the helmet's curled horns. I changed the curve so they go out over the arm and then curl up. That was round 2 of 2 render reviews.
- The page publish failed once because I passed only the data files without the page itself (`file_path`). I re-sent it with the page.
