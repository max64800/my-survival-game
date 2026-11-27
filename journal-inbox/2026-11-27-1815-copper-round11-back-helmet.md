# Copper armour round 11: back hump, braids, smaller helmet, longer page loops (F914)

**Owner's notes on round 10:** a very big bump on the back, braids still poking out, the helmet is way too big, and Walk/Run on the page restart far too fast.

**What we did:**
- **Back hump:** the "stiff" back plate was one simple curve. His back has a shape that curve can't follow, so the plate pushed itself out 6.5 cm to clear his highest spot, which made a hump. The back plate now uses a bendier smooth curve, still with no muscle dents. It now sits 2.7 cm out.
- **Braids:** the braids down his back now lie on top of the back plate, the same way the beard lies on the breastplate. The beard fix became one helper, `lay_over`, used for both.
- **Helmet:** about 14% narrower (0.2 m to 0.172 m), the top 3.5 cm lower, and a smaller flare at the bottom.
- **Page loops:** the page recorded only one step loop (1.3 to 1.9 s), so it restarted every second or so. The export now records 3 whole loops (Walk is 5.7 s).

**Mistakes and hurdles (Claude's):**
- While making the beard fix into a helper, Claude dropped the "only hair just behind the plate" limit. The beard and braids then moved 17 to 21 cm. Caught in the log and fixed (back to 6 cm).
- The page files got bigger than one upload can carry (64 MB), so the page went up in 3 publishes.

**Checks:** the armour fit test passes.
