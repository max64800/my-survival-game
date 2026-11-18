---
name: editing-taste-profile
description: "Max's video-editing taste learned from 18 TikToks he loves (2026-10-05): kinetic 3D typography, layout switching, rebuilt UI cards, counters, craft transitions; favourite is johnbucog_ \"Creating UI Animation with AI\""
metadata:
  node_type: memory
  type: user
  originSessionId: 9d7dfd16-5b7a-4349-92f3-cd3a865c551f
  modified: 2026-10-05T16:57:44.178Z
---

Learned from 18 reference TikToks Max sent on 2026-10-05 (AI/dev-tool explainers + transition/effect tutorials + CapCut templates). His favourite: johnbucog_ "Creating UI Animation with AI" (tiktok.com/@johnbucog_).

What he likes:
- Typography as the lead visual: words flying in 3D space around the speaker (tilted, different depths, motion blur, words on curved/arc paths), two-font contrast (clean white bold sans + red/accent display or yellow italic serif for keywords), one-word/short-phrase captions near mid-frame with emphasised keywords.
- The visual changes every 1-2 s even with the face on screen: layout switching (split screen visual-top/head-bottom, head in rounded or arched card, circular face bubble PiP over full-screen content, full-bleed punch-in, full-screen insert).
- Rebuilt, clean UI cards (chat boxes, toggles, terminals, browser frames, phone mockups) floating in with soft shadows and a slight 3D tilt that settles flat; slow push-ins on details.
- Proof made visual: animated counters/odometers (stars, $), badges that slam in ("FREE"), crossed-out competitors.
- Craft transitions as cut punctuation (6-8 frames): RGB-split glitch, whip blur, strip/tile reveals, light-leak flash, person-cutout mask wipe.
- Depth hooks: text behind the subject (already built: editor/matte.py), floating card walls.
- Premium restrained palettes per video (cream + terracotta, black + gold glow, light grey); a clear CTA end card (comment box typing a keyword).
- Dislikes: rotating/spinning 3D props (see [[animation-ambition]]).

Max's own words (2026-10-05): "one to two seconds, something has to change" — our edits are missing (1) more zoom-ins/zoom-outs and jump cuts at that pace, and (2) background sound effects (whoosh, pop, click, swoosh, impact) synced to every visual event: a cut, a zoom, an image/sticker landing, text slamming in. Every animation must come with an SFX.

Build priority agreed from the analysis: 3D kinetic words + motion blur + curved text paths; two-font caption system; circular face PiP over floating UI cards; layout switcher; counters; glitch/whip transitions; CTA end card. Don't copy other brands' logos/mascots; build original equivalents.

Ratings of 50 similar videos (2026-10-05). The 8-9s and why:
- Gradual split screen: content on top melts into the speaker below through a soft gradient, never a hard line (john.tagudin, 9 and 8).
- Things always drifting up and down and changing: torn-paper strips, cut-out photos, a book popping in, name tags (aliabdaal, 9).
- Hooks: an object bursting out of a monitor, the background blurring as big yellow two-line words slam in (sebastienjefferies Canva, hook 9). A wall of testimonial/tweet cards flying up behind the speaker, white sans plus red serif title, then a countdown-ring timer above the head (buildwithai.club, hook 8).
- Editorial premium: magazine-style layouts, boxed mono captions, giant words over a blurred close-up (rpn second half, 8).
- Also 8: rebuilt UI toggles and charts (brockmesarich), cream UI cards and % counters (tylermommsen), head-bottom split with many layouts (jackroberts), neon card frames around the speaker (roydmedia), 3D glowing books (aliabdaal).

Hard NOs (1-3):
- AI-generated visuals or "AI slop" (Higgsfield etc.) and paid production; he wants AUTHENTICITY: just him plus code-built add-ons.
- Green screen.
- Bad or ugly captions.
- Trends or effects that depend on special filming (not buildable in code).
- Pure typography with no speaker.
- Plain news-style edits (4).

Feedback on Spider-Man v3 full edit (2026-10-05, rated 9/10; engine: editor/motion/src/Edit.tsx + work/IMG_3787/plan_v3.py):
- LOVED: zoom-in/zoom-out rhythm, the synthesised sound effects (editor/sfx.py), the top-panel cards (e.g. "days since release 60" counter), the slow gradual soft split.
- HATES: blurred background around him ("looks cheap") — never blur the wall/background.
- Bugs he spotted: white/cream lines on the frame edges when the camera scale dropped below 1.0 — always keep the video scale ≥ 1.02.
- Captions: a bit higher than y≈1545, and vary the style here and there (now: serif italic / yellow marker swipe / white tag rotating per key word).
- Full-screen "paper" cutaway: the face circle was zoomed too tight; show the whole head. The circle-wipe transition felt odd; it now slides up like a sheet of paper.

Reference Max loved end to end (2026-10-06): @calsaistudio "Turn Claude into your motion graphics editor" (tiktok.com/@calsaistudio/video/7692519013607312660), a Dubai personal brand, edited in code (HyperFrames + FFmpeg). "Quiet luxury" minimal style, a good fit for EQT real-estate videos:
- ONE word at a time on the chest, white Inter medium (not heavy), key words in white italic serif. No yellow, no stickers.
- Cold-open hook: she's mid-action in side profile (sipping coffee), then turns to the camera. Two angles (wide side profile + front medium) plus punch-ins; about 25 cuts in 75 s.
- Real-life B-roll every 5-8 s for 1-2 s (Dubai towers, viewings, events, car, behind-the-scenes); captions continue over it. Authentic proof of the life and work.
- 2 full-screen typographic interstitials: off-white, small black Inter sentence, words fade grey→black as she says them, slides in with motion blur, then thin architectural grid lines draw in around it.
- CTA: dark-glass comment pill with avatar typing a keyword ("GROW") and a blue send button, then a preview of the guide/document (lead magnet).

Reference Max loved for its "smooth animations" (2026-10-06): @vizibilonline "Motion design by OPUS 5.5, 1 prompt" (vt.tiktok.com/ZSbXbBD8J, 359K views, 19 s). A code-made motion graphic, filmed off a laptop screen with a phone in one continuous shot. Why it feels smooth:
- NO hard cuts. Each element morphs into the next (prompt bar → toggle pill → light streak → word → dot → line → icon → CTA → logo).
- Whip transitions are heavy directional motion blur, not cuts. The virtual camera pushes into a UI element, then whips off.
- Dark UI with indigo/blue glow blooms behind the active word or selection. Teal light-trail streaks write words in.
- One thing on screen at a time, centre stage; fast ease-out moves and long gentle settles.
- Rebuilt UI micro-interactions: typing in a prompt box, a dropdown opening with a glow on the chosen item, a segmented toggle sliding its selection.
- Ending: an icon with a particle burst, "TRY CLAUDE" sliding out of the icon, then logo letters scatter in and assemble.
- The phone-filming-the-laptop trick makes code animation feel real/organic.
Build ideas: morph transitions, whip-blur transitions, glow bloom, light trail, letter-assemble EQT logo outro.

Gym video (IMG_3799, 2026-10-06): v1 rated "decent" but "very very similar to the Spider-Man" + "3 RULES" behind his head was too covered. He wants VARIETY from video to video: don't reuse the same look (cream split + white cards + yellow 3-word captions) every time. Rotate styles. v2 used kit2 (editor/motion/src/kit2.tsx): dark glass + glow, full-screen paper slates, a rules "stage" with the speaker in a bubble, light trails, whip-blur transitions, one-word serif captions. Avoid behind-the-head words when his head sits high or the background is busy; put the word in front with a glow (glowword).
Max's verdict on gym v1 vs v2 (2026-10-06, notes for future videos only; don't re-edit the gym video):
- Captions: he prefers v1's 3-word chunk captions (Inter + serif/marker/tag key word) over v2's one-word-at-a-time captions.
- Layout: he likes v2's "less face": more full-screen visuals (slates, the rules stage) and less talking-head time.
- Bug: v2's round face bubble (kit2 Stage PiP) was off-centre and cut about 20% of his face. Next time centre the bubble on the face centre (head.json cx, plus the middle of the face rather than head top + 280) and pull back enough to show the whole head.

More "smooth flowing motion" references Max loved (2026-10-07). All are 15 s code-made motion graphics (Claude Opus 5.5, some with HyperFrames):
- @motionlovee: tiktok.com/@motionlovee/video/7693519537072901398 (183K views)
- @benkaluza.lab: tiktok.com/@benkaluza.lab/video/7690355593890123030 (23K)
- @ivanxuugarcia: tiktok.com/@ivanxuugarcia/video/7691379990612430112 (79K, Claude x HyperFrames)
His ask for future edits: make the animations FLOW into each other. Transitions should connect one element/scene to the next (morphs, continuous motion, elements handing off) instead of separate graphics popping in and out. Same direction as the @vizibilonline note above. Studied 2026-10-07: see [[motion-flow-rules]].
