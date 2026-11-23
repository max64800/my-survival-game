## Nov 23: screen-edge effects only showed in the top-left corner (F815)

**What the owner saw:** low health (red edges, blood) and poison/burn/chill looks only covered a box in the top-left of the screen.

**Cause:** the effect layer (`ScreenEdgeFlash`) was told "fill the screen" with `set_anchors_preset`, which sets the anchors but leaves the size at 0. A size-0 box never stretched with the window, so the effect was clipped to a small corner. I measured it: size (0, 0) in a 2000x1100 window.

**Hurdle (mine):** my first low-health test run showed nothing at all, and I could not tell why until I printed the box size. Measuring first saved guessing.

**Fix:** `set_anchors_and_offsets_preset(PRESET_FULL_RECT)`. Now the size is the full window and follows resizing. New test in `tests/test_edge_flash.gd`. The `arenatest lowhp` robot run shows red edges and blood over the whole screen.
