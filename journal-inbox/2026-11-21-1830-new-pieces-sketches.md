## Nov 21: seven new building pieces, sketched in 3D first

**What we did:** The owner wants our building kit to have every *kind* of piece a big survival builder has (kinds only,
never its names or looks). Seven are missing: corner + spiral stairs, a slanted stair railing, an upside-down slanted
wall, a thin edge strip, a roof peak cap (Shack/Hearthbrick only), a round floor hatch and an open lattice wall.
Before making real models, Claude made rough sand-coloured sketches in Blender
(`tools/asset_forge/builds/new_pieces_sketch.py`) and a 3D page (`tools/build_pieces/new_pieces_page.html`, packed by
`make_new_pieces_page.py`) showing each sketch beside real stone walls, floors, stairs and brick roofs for size.
The owner now says yes/no per piece; only yes pieces get real models. The trims, overhanging battlement and balcony
from the first plan wait until these seven are done (owner's call).

**Hurdles:**
- The `blender` command isn't on the PC's PATH; the full path under Program Files works.
- The browser helper (chrome-devtools) wouldn't connect twice. Fix: headless Edge with `--screenshot` and
  `--use-angle=swiftshader` so the 3D page still renders, plus a `?cam=` test view for close-ups.
- The page's "loading" text stayed on screen: its CSS `display: grid` beat the `hidden` flag. Added `#loading[hidden]`.
- The arch looked wrong from the station camera; a straight-on test view showed it was right (just the angle).
- First edge strip was too chunky for a "thin" strip; made it 30 cm tall and 7 cm thick.
