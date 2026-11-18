---
name: gradient-glass-style
description: "Max 2026-10-21: new house style replaces kit10 bold plate — bright Stripe-like gradient app cards, colour theory from the footage, fluid morphs, clean sans, UI mockups, smooth push-ins"
metadata:
  type: feedback
---

Max on 2026-10-21 (video 024, IMG_4087): the kit10 bold plate was "very in your face, very bright... not smooth... simple, childish". He wants "more professional, minimalistic, but still bright", smoother, and "a style of our own". His answers to the style questionnaire:

- **Look:** bright gradient app, like the Stripe / Linear / Notion sites: rounded app-style cards on soft colour gradients. No flat loud colour blocks.
- **Colour:** use colour theory from each video's own colours (his clothes, the wall, the room) so the graphics complement them. Claude picks the palette per video. 024: black shirt with gold dragonflies in a warm oak and white kitchen, so complementary indigo → blue cards with gold accents.
- **Motion:** fluid morphing. One shape turns into the next and nothing pops. Ease-out curves with no bounce; see [[motion-flow-rules]].
- **Font:** clean modern sans (Inter, semi-bold or bold). Anton is no longer the default.
- **Inside the cards:** clean UI mockups (checkout card, view counter, chart, document). Each one explains its line.
- **Density:** something on every sentence, but calm.
- **Zoom:** smooth push-ins that ease in and out, no quick punches. This replaces the punch part of [[keep-morph-and-zoom-punches]].
- **Behind-head words:** 1-2 per video when they fit, in the new sans with a gradient fill.
- **Layout and captions:** pick per video from where his head sits. Captions stay big and readable ([[culture-video-feedback]]).
- **SFX:** same mix as before.

**Verdict on 024 (Max, 2026-10-21):** "I like the edit, not a big fan of the colour palette". Keep the kit11 style: cards, morphs, glide captions, push-ins. The indigo/electric-blue band and card gradient didn't land with him. Next video, pick a different palette and show him 2-3 options as swatches or a still before building.

**Why:** he felt the old look read as childish and not smooth, and wants a recognisable, professional identity.

**How to apply:** this supersedes the look in [[bold-plate-kit10]] and the Anton parts of [[own-style-80-20]]. Keep the structural rules: one morph chain, captions low on the chest, safe zones, ≥24 px gaps, no emojis. Code: `editor/motion/src/kit11.tsx`.

**026 Palm shade map (2026-10-23):** Max picked the **Lagoon** palette (aqua #1FB5C4 → sea blue #1E7FD8, gold accents) from 3 swatch options. New `PhoneShot` layer in kit11 (`phone` prop): the real phone screen recording, never cropped, sits small inside the frame-1 card and morphs to a big centred phone over a dimmed backdrop for demo beats. New card scenes: title, week, notes, board, url, comment. Plan: `work/IMG_4120/plan_026.py`.
