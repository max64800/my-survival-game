---
name: after-edit-cover-prompt-and-caption
description: "Hand-off = exactly 2 items: GPT cover prompt (chibi grid style) + ONE caption under 100 chars for all 3 platforms; no per-platform copy"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d7dfd16-5b7a-4349-92f3-cd3a865c551f
  modified: 2026-10-07T17:07:00.870Z
---

**TIMING (Max, 2026-10-18, REPLACES the 2026-10-16 'at render start' rule):** give the GPT cover prompt + the ONE caption in the SAME message as the finished video's link ("when you're giving me the link to the video instead of earlier, because I can't see" them when they come mid-render). Never send them earlier.

**ONE caption only (Max, 2026-10-16, repeated after I wrote separate YouTube/Instagram/TikTok copy for 019):** "I just need one for all three under 100 characters. Don't need to create more than that." Never write per-platform titles, descriptions or hashtag blocks. Hand over exactly 2 things: the cover prompt and one caption under 100 characters.

**HARD RULE (Max, 2026-10-21, after I wrote a photo-real cover prompt for 024):** "you wrote the wrong thing". EVERY cover prompt is written around the previous cover he tags in ChatGPT:
- use EXACTLY the same chibi character from the tagged image;
- use EXACTLY the same art style as the tagged image;
- change only the pose (and the props and headline that fit the new video).

Never write photo-real, never describe a new character, never invent a new style. This holds even when the video edit style changes (for example kit11). The cover style is separate from the edit style.

Every time a video edit is finished, end with two ready-to-paste items, without being asked:
1. A GPT image prompt for the cover: chibi style matching his existing covers (attach `thumbnail-references/masters/_master-max.png` + an existing cover), bold title at the top with one yellow word, happy/confident chibi, Dubai shown positively, safe zone (title and face inside the middle 75% of the height), no fades/gradients, and no Dubai landmarks (see [[gpt-prompts-no-dubai-landmarks]]).
   Exact grid style to match (Max, 2026-10-07, after a warm "painterly" cover broke the grid's consistency):
   - flat cel-shaded cartoon, thick dark outlines, sticker-like chibi, bright saturated DAYTIME colours, clean simple background;
   - character: spiky brown hair, big brown eyes, WHITE tee, jeans (the 018 "Laziest Hard Worker" cover shows the white tee), a big waist-up close-up centred in the lower two-thirds;
   - FORMAT 9:16 vertical (1080x1920), NOT 4:5. The headline sits in the upper-middle band (~25-45% from the top) so it survives the Instagram grid crop (middle 3:4); 2 lines of huge condensed all-caps with a thick black outline (line 1 white, line 2 yellow, or a yellow keyword), filling the full width;
   - no subtitle pills, no emoji, no extra text.
   Always tell him to attach 2-3 existing covers as style references.
   **Prompt pattern that works (2026-10-16, after a 019 prompt came back soft 3D/Pixar with navy text):** open with "Use the attached [cover] as the exact style template, copy its art style 1:1 ... NOT 3D, NOT Pixar", then list ONLY what changes (scene, headline words, props). Never write "3D", "cream/soft blue" or a custom colour scheme. Give a one-line fallback ("Too 3D. Redo it flatter, with thick black outlines exactly like the reference.").
2. ONE caption/description used on all three platforms, **under 100 characters** (YouTube limit, Max 2026-10-08): 1-2 emoji, includes the search phrase (e.g. "Palm Jumeirah in Dubai"), ends with a genuine question. Since 2026-10-22: add 3-4 niche hashtags AFTER the <100-char caption (e.g. #claudeai #vibecoding #aitools #dubaiexpat, chosen per video; the hashtags don't count toward the 100). Count the characters before handing it over. No separate titles or descriptions.

**Why:** Max asked for this to become a rule on 2026-10-03; he posts every video to Instagram, TikTok and YouTube and makes the covers in GPT.

**How to apply:** include both at the end of the hand-off message for every finished edit (plain or animated), in code blocks so they're easy to copy.
