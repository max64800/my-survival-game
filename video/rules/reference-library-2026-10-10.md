---
name: reference-library-2026-10-10
description: Max's 13 liked TikToks (2026-10-10): karan.mp4_ caption spec (serif + one script word, zig-zag stack, blur-in, staggered dim-out, setup line behind head), background-swap moments, 10 ways to amp graphic transitions
metadata:
  type: user
---

13 TikToks Max loves (sent 2026-10-10). Only #1, #2, #3, #5, #11 and part of #13 are talking-heads; the rest are monitor recordings of motion pieces. Studied frame by frame (scratch: ref6).
- **#1 @kienobimedia:** a serif + sans title stack, words building at chest height; a light-leak bloom resets into a scrolling SFX timeline strip above his head; green/teal grade.
- **#2 @mr_pynk:** small lowercase mono captions plus a huge bold payoff word with a tiny lead-in line ("so here's / HOW IT WORKS"); a payoff word matted behind the mic and hand; layout switches every 1-2 s; white light-leak and lime colour-block wipes.
- **#3 @snipp.co:** quiet-luxury paper cards with window-blind shadows; blur-in giant numbers ("90%"); bold sans + script payoff pairing; a red circle behind a cut-out person; beige poster cards with type behind and in front of the person.
- **#4 @webloved:** comic-site ink/cloud mask reveals; a red-sun through-line; a strict black/white/red palette.
- **#5 @karan.mp4_ — THE CAPTION REFERENCE (Max loves these captions):** frosted glass pills (Raw → Motion → Captions → SFX) as a stepper with a thin tether line to the speaker; burnt orange / chocolate / cream palette.
- **#6 @thefusionlabfx:** Apple-style chained UI morphs (tile → dive into a button → map → converter); rotating word under a fixed logo; 3D rolling counter.
- **#7 @motionlovee:** a light-streak through-line; prompt → bezier curve → streak tunnel → cube → LED ring → counter → logo.
- **#8 @kxjouanim:** heavy motion-blur product swaps inside one persistent card; a flip to a dark page; luxury monochrome.
- **#9, #10, #13 @drillup.io:** UI micro-interactions with cursors; a swoosh ribbon carrying cards; card-to-fullscreen expansion; fly-through logos; #13 is a dense black/gold world (likely too much for Max).
- **#11 @brooke_wrightmode:** two-tier captions (small subtitle + bold keyword headline above), meme PIPs, cream screenshot cards, a pill CTA.
- **#12 @rikibosso:** a persistent soft glow blob behind every element; a sentence collapses into a pill that becomes the next element.

CAPTION SPEC (from #5, built as "stack" captions in editor/motion):
- **Fonts:** book serif (roman, white) for every word; ONE word/phrase per screen in a formal connected script (Great Vibes / Pinyon), the emotional payoff, about 1.5-1.7× the serif size.
- **Layout:** 2-6 words in 2-3 lines with tight leading, never all centred. Two patterns:
  - zig-zag stack: small serif line / huge script / small serif line indented right, words spaced apart;
  - split: the setup line sits high (touching or behind the top of the head, as a staircase), the payoff script sits lower at chest height.
  - Caption text is never on the face.
- **Shadow:** soft dark glow (rgba(0,0,0,0.55), 8-12 px blur, 2-3 px down).
- **In:** word by word ON the spoken word: blur 12 → 0, opacity 0 → 1, scale 1.06 → 1, a slight over-bright bloom, 0.15-0.2 s. The script word takes about 0.25 s with blur about 18. No sliding.
- **Out:** in reading order; the earliest line dims to about 50% grey for about 0.15 s, then vanishes with blur; the next line 0.2-0.4 s later; the payoff holds longest. The new group starts only after the old one is gone.
- **Behind the person:** the high setup line may sit behind his head (layer order: background → captions → person matte). The payoff stays in front of the chest.
- **Density:** about 1 group every 1.5-2.5 s, at most 6 words.

BACKGROUND SWAP: the best ones replace the background only for 1-3 s payoff moments (flat warm colour field, a big shape like a red circle or glow blob, plus big type behind the person), then go back to the real room. Bonus: the cut-out can slide down out of frame to leave a colour field.

AMPING UP GRAPHIC TRANSITIONS (~20%, keep the format):
1. Blur-bloom crossfades instead of plain fades.
2. A card expands past the frame edges and becomes the next scene.
3. Dive / zoom into a UI element.
4. One persistent glow or dot through-line behind everything.
5. A swoosh ribbon carrier.
6. Directional motion-blur slide or 3D flip inside one persistent frame.
7. Roll only the changing word or number.
8. A glass-pill stepper / timeline strip.
9. A light-leak or invert flash on 2-3 big beats only.
10. Collapse text into a pill or dot that opens into the next element.

Max's rule for every new video: change about 20%, not 80%. Keep the format, evolve it. Related: [[keep-morph-and-zoom-punches]], [[motion-flow-rules]], [[editing-taste-profile]].
