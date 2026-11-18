---
name: keep-raw-until-shorts
description: "HARD (7 Nov 2026): never delete a long-form video's raw recording until its Shorts are cut and posted; deletions go to the Trash, not rm"
metadata:
  type: feedback
---

On 7 Nov 2026 Claude permanently deleted the raw recordings of The Palm Tower (IMG_3953) and Serenia (IMG_3954) during a cleanup. Max then wanted Shorts from both, but the raws were gone from the Mac and his phone, so those Shorts were lost. Max: "we will do shorts from the next long form videos".

**Why:** Shorts need the 4K centred raw (face full height in 9:16); the published 16:9 renders are not good enough for vertical.
**How to apply:**
- Before any cleanup, ask whether Shorts from that long-form are done; keep `Raw/*.MOV`, the cleaned voice and the `public/lfNN` camera file until they are.
- After every long-form render, remind Max to plan its Shorts (about 5 per video) before anything is deleted.
- Delete by moving to the macOS Trash (Finder / `osascript` "delete"), never `rm`, unless Max says permanent.
