## Nov 22 — Trot walk, stuck upgrade panel, "planks from wood first" note (Claude 2)

**What we did**
- **F613 stuck panel:** the "Upgrade and repair gear" panel sometimes sat alone on screen with no way to close it. Cause: when a craft finished or was stopped after the bench window was closed, the window redrew itself anyway, and the redraw switched the upgrade panel back on. Now it only shows while the bench window is open. Test added.
- **F614 wood → planks:** the bench quietly turns wood into planks when you craft a shield with no planks. That's by design, but it looked like a bug. The recipe now says it in amber: "⚒ First makes 6 Rootwood Plank from 3 Rootwood", then "⚒ then the Wooden Shield". The missing planks show amber (will be made) instead of red. Test added.
- **🔁 F577 moonwalking:** the owner still felt the dwarf slide when walking. I measured the feet. The slow walk animation's steps are so short that at 4 m/s the planted foot slid back at only ~15% of his speed; it would need to play 6× faster to grip. Different approach (owner's pick): plain walking now plays the trot (feet grip ~96%), Shift plays the sprint (faster legs; it already leans 13° further forward than the trot, so no extra lean was needed). Movement speed unchanged.

**Hurdles and mistakes**
- The rtk hook rewrote one of my commands and the auto-mode check blocked it; running it again worked.
- My first guess for the trot speed (2.0×) overshot: the feet moved back faster than the dwarf (114%). Measured again and settled on 1.75×.
- test_dwarf_fist (great-axe swing "Spin" fists/handle room) fails. I checked with my change undone: it fails the same way, so it comes from other work in progress, not from this change. Left for whoever owns it.
