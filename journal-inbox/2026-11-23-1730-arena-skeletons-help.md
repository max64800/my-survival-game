## Nov 23: arena skeletons stand, help panel, F11 reset

**What we did:** The arena skeletons now stand up and wait (they play their get-up move once, then stand still). A how-to panel is always on the right: how to reset (F10, click Reset, F10 again) plus F11 = reset at once.

**Hurdle (my mistake):** Last time I called `rig.get_up()`, which is the move for a creature that was knocked down. Skeletons lying as bones need `rig.rise()`. The help panel first sat off-screen because I anchored it with the wrong helper; fixed by anchoring it to the right edge by hand.
