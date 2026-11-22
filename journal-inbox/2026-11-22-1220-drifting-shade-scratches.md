## Nov 22, 2026: The Drifting Shade gets its scratch marks (Claude 3)

**What we did**
- The owner asked for scratch marks, big and small, all round the Drifting Shade (the first ghost).
- In the end they are long, thin, pitch-black slashes. Some are alone and some come in claw-like sets of three.
  Most are on his front (the side you face), with more on the shoulders, the arms and the lower robe.
- Each scratch is cut into the clay and also painted black through the model's "guide" colours
  (blue 0.35 = scratch, blue over 0.5 = eyes). Both the game shader (`src/art/ghost.gdshader`) and the 3D page paint that black.
- The owner: "Okay, I like it. Keep it now." The Drifting Shade is done.

**Mistakes and hurdles**
- **The scratches were invisible twice.** The cuts were thinner than the model's 9 mm building grid. At the end, the
  model is also smoothed to fewer faces, and that filled the thin grooves back in, like sanding wood.
  Fix: deeper cuts, more faces kept (70,000), and painting the scratch colour into the model so it can't be sanded away.
- **The first visible try was wrong:** the scratches were wide, glowing and mostly on his back. The owner wanted them long,
  thin, pitch black and on the front. I changed the sizes, the colour, and where they are placed.
- **To add more marks without moving the ones the owner liked,** the new spots go at the end of the list, so the random
  picks for the old ones stay the same.
- **The page file got too big** (19 MB, the limit is 16). Binary files aren't allowed on the page, so the model's data
  is now split into two text files, and the page joins them back together.
- **A Python edit wrote a literal "\n"** instead of a line break into `ghost_body.py` (heredoc escaping), which broke the
  script. Caught by a syntax check and fixed before the build.
- The detailed ghost model is now 14 MB (it was 5 MB). To watch: check the game doesn't slow down with several ghosts.

**Next:** F658 (each ghost its own mace move, the boss a 3-hit combo or the 4th move), F659 (the fade-and-jump
breaks into little flying dots instead of low-poly mist balls), then the Wrathful and Bearded Shades as detailed as this one.
