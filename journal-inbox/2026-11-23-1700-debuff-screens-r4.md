## 2026-11-23: Debuff screens, round 4 (F799 frost, F802 blood)

**What we did**
- Your notes: burning is good, but frost and blood all looked the same. Frost should not reach as far, but be much
  thicker in the corners, with more kinds of snowflakes. Blood should have many more splats, big and small, near the
  corners, some thrown in from outside the screen, and the round ones should splat, fade and splat again.
- Frost: it reaches less far now (about half as far at 5 stacks), and the corners count as "deeper", so they fill up
  thick. There's a new snowflake drawing: six arms, 0 to 3 side branches, sometimes a flat six-sided plate in the
  middle, sometimes little round plates on the arm tips. Each flake gets its own mix. Two sizes of flakes sit among
  the ferns, and the small fern bursts are mostly single spears instead of little crosses.
- Blood: three sizes of splats (big, middle, small) instead of one. Each spot near a corner is far more likely to get
  one. A splat's starting point may sit just outside the screen, so its streak flies in from the edge. Three kinds:
  thrown paint (blob plus a long thinning streak with strings and drops), a spiky round splat, and a spray of drops.
  The round ones run on a timer: pop in, stay, fade, and splat again in a new spot nearby.

**Mistakes and hurdles**
- The first round 4 try had frost that was still thin in the corners and big splats that were too small to read.
  Fixed by making corners count even more as "close to the edge" and by making the big splats bigger.
- My script for the feedback notes stopped on its own safety check: FEEDBACK.md has Windows line endings (a hidden
  mark at the end of each line), so "does the line end with…" said no. Fixed by ignoring that hidden mark.
- Other chats had files staged (ready to commit) at the same time, so I set those aside, committed only my files,
  and put theirs back.

**Checked**
- The real game compiles the shader and draws it (screenshot of 5-stack frost). The 9 edge-flash checks pass.
- 3D page updated (version 5): https://claude.ai/artifact/XeK5MmvZbu45PtX5JbPxsw
