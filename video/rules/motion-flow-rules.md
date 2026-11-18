---
name: motion-flow-rules
description: "How to make Max's animations FLOW into each other (studied 2026-10-07 from 4 code-made motion references); rules for planning every animated edit"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d7dfd16-5b7a-4349-92f3-cd3a865c551f
  modified: 2026-10-07T11:30:06.361Z
---

Max wants animations that flow and transition into each other, not separate graphics popping in and out. Studied frame by frame on 2026-10-07:
- @motionlovee 7693519537072901398
- @benkaluza.lab 7690355593890123030
- @ivanxuugarcia 7691379990612430112
- plus @vizibilonline (see [[editing-taste-profile]])

All were made with Claude Opus 5.5 / HyperFrames.

**What they do:**
- **motionlovee "5.5 is ridiculous at motion":**
  - A dot grows into a ring, which bursts into the Claude asterisk, then a bloom flash.
  - "CLAUDE" in heavy grotesk on orange, then the letters scatter into dots, and the dots become a data plot.
  - On blue: a circle morphs to triangle, star, square.
  - A dot grid becomes curvy tiles with an orange sweep, then a 3D wireframe sphere/torus.
  - Fast colour-flash kinetic words (EASE / IN / NEVER marquee / LINEAR with motion blur).
  - It ends on the same asterisk and "CLAUDE" it started with (a bookend).
- **benkaluza.lab:**
  - One point of light draws the whole story (the evolution of humans) as long-exposure trails that stay in 3D space.
  - The camera follows the light. Haze, wet-floor reflections, warm-to-cool colour shift.
  - The single moving light is the through-line.
- **ivanxuugarcia (agency services reel):**
  - A 3D rotating text ring collapses to a lime line, and the line expands into the next screen.
  - Each service is a colour-block scene (blue web, red social, lime branding, dark marketing) with the same layout: bold title top-left, italic serif subtitle, one central object.
  - The central object morphs (circle → squircle → star → flower).
  - Particles dissolve and re-form into letters ("IA"), then "TODO / EN UNO", a white flash, then the name assembles from particles as the end card.

**Rules for every animated edit:**
1. **Hand-off, never pop.** Each graphic is born from the previous one (it shrinks to a dot, collapses to a line, morphs shape, or bursts into particles that re-form). At least one element must survive every transition.
2. **One through-line object per video**: a dot, a light streak or a shape that travels between beats and becomes each next element.
3. **Transition vocabulary**:
   - collapse-to-line → expand;
   - shape morph;
   - particle dissolve → re-form into text;
   - colour-field wipe under a staying object;
   - motion-blurred whip of type;
   - bloom flash.
4. **Colour-block scenes** for full-screen cutaways. Each beat gets its own bold background, with a consistent layout (title top-left in heavy sans + italic serif subtitle).
5. **Rhythm:**
   - about 1.5-2.5 s per beat;
   - quicker colour-flash type near the climax;
   - then a calm settle;
   - fast ease-out moves with long soft settles, plus motion blur on anything fast.
6. **Bookend** the start and end with the same symbol/logo, e.g. an EQT mark that assembles from particles at the end.

**Why:** Max loved all four for "smooth flowing" motion. His edits so far (Spider-Man, gym) still pop elements in and out independently.

**How to apply:** when planning an edit in editor/motion (Edit.tsx / kit2.tsx), design the hand-offs between beats first, then the beats themselves. The engine needs these primitives built:
- morph between shapes/cards (element B starts from A's final bounds);
- collapse-to-line / expand;
- particle dissolve / re-form to text;
- colour-field wipe;
- a letter-assemble logo outro.

Built 2026-10-07 for the Palm skit (IMG_3815): editor/motion/src/kit3.tsx.
- PalmDraw: light-drawn outline that collapses to a dot.
- Dot: the through-line.
- Flow: full-screen colour scenes with diagonal colour-field wipes, a persistent face bubble, objects that shrink into EQT logo layers, a dock, the layers locking into the real logo, then the bubble growing back to full screen.
EQT logo assets are in "EQT Logos/". The mark splits into 3 real layers in editor/motion/public/eqt/layer-{top,mid,bot}.png, which is useful for assemble-the-logo outros.

Max's notes on the Palm skit v1 (2026-10-07):
- **Never code-draw illustrations of real places or objects** (the Palm drawing "doesn't look like a palm", and the palm behind the broker pins too). If a place is needed, ask him for a screenshot or reference.
- **The face bubble must be centred on his face the whole time.** Track the face per frame with YuNet (editor/cut.py FACE_MODEL), smooth it, and scale so the whole head fits (~0.32).
- **Don't build the logo piece by piece during the beats** (it "doesn't make sense"). Show the logo only at the end, and always show the website **EQT.ae** with it.
- **Close intra-line pauses.** Listen for silences over 0.3 s inside the cut ("…dominate the Palm [pause] but there's only one").
- He dislikes how he says "millionaire". Use alternative takes he recorded ("IPO businessman").

References Max sent 2026-10-08 (studied frame by frame):
- **@rifqieh carousel "Best Claude Code skills for animation"** lists these repos (candidates to install; ask Max first):
  - CloudAI-X/threejs-skills: 3D scenes, camera, lighting, particles, GLTF
  - greensock/gsap-skills: official GSAP timelines, text reveals, ScrollTrigger
  - zanwei/design-dna: extract and reuse a visual style
  - lottiefiles/motion-design-skill: Lottie/SVG motion, keyframes
  - AThevon/genjutsu: "award-winning UI", premium animation, creative direction
- **@motionlovee "5.5 is ridiculous at motion" part 2.** Same laptop-on-glossy-table look as before.
  - A red dot becomes a laser line, which sweeps into the next scene.
  - Shaded 3D wave terrain; a "+308% → +312%" counter with a bar chart and ring.
  - A particle flow field, then a ring of dots.
  - A blue UI modal whose toggle flips; orange blobs morphing.
  - Bookend on the logo.
- **@practicalyai (talking head + real screens).** Over-the-shoulder phone/laptop B-roll of the real UI, his finger pointing at the screen, and one-word captions. Authentic proof instead of rebuilt UI.
- **@nathanhodgson.ai "AI vs video editors"** (closest to Max's split layout):
  - The speaker sits in the bottom ~60% (purple studio); the top is a light cream-gradient panel holding clean UI cards: a timeline, a tool grid where tools lock with padlocks, a "6+ → 225+ creative tools" counter with a growing thumbnail grid, 3D wireframe layers, a "WORKS WITH" logo row, a product card with a FREE badge, and a URL bar typing the link.
  - Small one-word captions in grey boxes.
- **Colton Dean (IG) "How to have Claude edit videos" (HyperFrames)**, very premium and subtle:
  - The face stays full-frame. Small frosted-glass cards sit in the top third with step labels ("01 Install it", "02 Cut it").
  - A duration counter drops 3:23 → 3:18 → 1:10 while clip blocks get X'd out for retakes; a waveform for dead space; a prompt box typing; a SKILL.md card.
  - Ends with a "Comment AI" comment box. Small, quiet captions.
- **@ngorzc (Indonesian service ad, Claude-made):**
  - Cream editorial layout with a serif "Deadline" and timer chips.
  - A calculator row of chips multiplying (20 × 25k × 1.5 × 1.4 = total) with the sum counting up. Great for real-estate maths (price × fees, rent × months).
  - Stat tiles in colour blocks (100%, 4.9/5).

Takeaways to apply:
- Frosted-glass small step cards over the face (subtle beats loud).
- Equation-chip calculators for any money talk.
- Counters with growing grids.
- Over-the-shoulder real-screen B-roll for authenticity.
- A URL bar typing **EQT.ae** at the end.

Clarified 2026-10-08 (coffee video IMG_3822): when Max asks for "smooth transitions linking between each other" he means between the MOTION GRAPHICS, not cut transitions between shots.
- Built kit4 `Morph` (editor/motion/src/kit4.tsx): ONE frosted card that glides between states (position/size/radius/colour/flip) while content crossfades: counter → pill → equation → grid → dot → ticket → flip into a review → red line → strike chips → counter → toggle.
- He asked for no face bubble for most of the video. Keep him full screen.
- Render at 60 fps (composition "Edit60") for smoother motion.


**Update 2026-10-12:** the EQT logo / EQT.ae end card is ONLY for the 1-2 weekly EQT videos, not every video (see [[content-direction]], [[motion-taste-rules]]).
