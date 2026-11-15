# Hand-built model style notes (what Claude 2 learned, Nov 14, 2026)

Rules for every model made with `kit.py`. Sources at the bottom.

## Shape
1. **Silhouette first.** The outline alone should tell you what it is (a pickaxe, a chest, an ingot). Read it at icon size before adding details.
2. **Three levels of shape.**
   - *Primary*: the one or two big masses (slab, dome, blade, haft).
   - *Secondary*: parts that explain how it's built (planks, straps, bands, lashing, frames).
   - *Tertiary*: small detail (rivets, nails, chips, knots, stitches).
   Big shapes first; small details last and sparing.
3. **Chunky and a little exaggerated.** Thick hafts, oversized rivets and bolts, heavy rims. Dwarf-made = heavy.
4. **Nothing perfectly straight or identical.** Small tilts, tapers, wobble, uneven plank widths, varied shades (the kit's `wobble`, `roughen`, random variants).
5. **Consistent bevels.** Same bevel width for the same material size (planks 0.012–0.02, stone blocks 0.025, metal 0.006–0.012).
6. **Build from separate pieces** (planks, beams, straps), the way a carpenter would; it keeps edges clean and reads as hand-made.
7. **Spend triangles on the outline and the bevels**, not on flat areas. Items 0.5–3k, stations 2–9k.
8. **Everything touches.** Ropes end ON the thing they tie, chains hook into each other, parts sit on the ground (no floating, no clipping). Check the preview from two sides.
9. **Material honesty.** Stone is rough and chipped (`roughen`), worked metal is cleaner with crisp edges, wood has plank gaps and end grain, cloth is soft and lumpy, old things are dirty.

## Surface
10. **Hand-painted textures, small and repeating** (`assets/textures/kit/`), toned down to the earthy palette. Bright colour only for glow, fire, gems, magic.
11. **Darker low, lighter high**: use the darker texture variant for bottoms/feet/undersides and lighter for tops and edges (fakes ambient light).
12. **Glow is a colour, not a lamp**: glow strength 0.4–0.9; above ~1 it burns to white.

## Fire and motion (game side)
13. **Real fire is an effect, not a model**: models only mark `fire_spot_<size>`; the game plays animated particles/shaders there (Claude 3's `src/art/fire.gd`). Good stylized game fire = a few flame-shaped quads with scrolling noise (shader) + embers + a flickering light.
14. **Moving parts stay separate**: anything that should move (grindstone wheel, saw blade, bellows) should be its own named node so the game can animate it (planned: `anim_spin_*`, `anim_pump_*`).
15. Animation basics for later: anticipation (wind-up), follow-through (things settle), squash and stretch, ease in/out; small loops (bob, sway) make the world feel alive.

## Sources
- [80.lv: stylized minecart with hand-painted textures](https://80.lv/articles/how-to-make-a-stylized-game-ready-minecart-prop-using-hand-painted-textures)
- [80.lv: tips on creating stylized 3D content](https://80.lv/articles/tips-on-creating-stylized-3d-content/)
- [Stylized wagon breakdown](https://gamesartist.co.uk/stylized-wagon/)
- [Shape language (RocketBrush)](https://rocketbrush.com/blog/shape-language-in-game-character-design-how-to-make-characters-readable-and-consistent)
- [Godot Shaders: stylized fire (3D)](https://godotshaders.com/shader/stylized-fire-3d/) · [Stylized BOTW fire](https://godotshaders.com/shader/stylized-botw-fire/)
- [How to make a stylized fire shader (devlog)](https://papaya-games.itch.io/duck-in-town/devlog/95149/how-to-make-an-stylized-fire-shader)
- [80.lv: stylized fire shader in Godot](https://80.lv/articles/learn-how-to-create-stylized-fire-shader-in-godot)
