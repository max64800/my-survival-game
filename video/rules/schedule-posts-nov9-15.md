---
name: schedule-posts-nov9-15
description: How Claude schedules Max's shorts on TikTok + Instagram itself (done for 035-041 on 2026-11-08) via chrome-devtools attached to his own Chrome
metadata:
  type: reference
---

DONE 2026-11-08: videos 035-041 are scheduled on YouTube (by Max), TikTok and Instagram (by Claude). They post one a day, Nov 9-15, at 18:00 Dubai. Each has its chibi cover, its caption and 3-4 hashtags.

**What works, so next week's batch can be scheduled without Max:**
- **Browser:** user-scope chrome-devtools MCP with `--autoConnect`, and Max's Chrome has `chrome://inspect/#remote-debugging` on. Backup of the old config: `~/.claude.json.bak-2026-11-08`.
  - `upload_file` only reads files inside the workspace roots. Copy the posts into `out/posts-<dates>/` first; files in `~/Downloads` are refused.
- **TikTok** (tiktok.com/tiktokstudio/upload):
  - Upload the video through the "Select video" uid.
  - Clear the description with a JS select-all on the contenteditable plus Backspace, then `type_text` the caption.
  - Edit cover → `upload_file` on the "Upload cover" uid (find it with a verbose snapshot) → Save.
  - Schedule radio → JS clicks `[aria-label="Select date"]`, then the day button by its aria-label, e.g. "Monday, November 9th, 2026".
  - Time: `.TimePicker__column` items "18" and "00". The time zone shows (GMT+4).
  - Click the Post/Schedule button and check the Posts list says "Nov 9, 6:00 PM (GMT+4) Dubai".
  - Leave the "S3_since_launch" unsaved-draft banner alone.
- **Instagram:** Meta Business Suite is broken in his Chrome (ERR_TOO_MANY_REDIRECTS), so use instagram.com instead. Its Create → Post flow has "Schedule content".
  - Crop: "Select crop" → 9:16 (the default is square!).
  - Cover: Edit step → "Select from computer" uid, then dispatch `change` on the file input.
  - Caption: type it, then Shift+Enter twice, then the hashtags.
  - Turn OFF the Facebook share toggle. When it asks, answer "Don't share this reel"; never pick "stop all".
  - Switch on "Schedule content", pick the date, then the Hours/Minutes spinbuttons. Type 06 and 00; PM is already set.
  - Check the scheduled list at instagram.com/scheduled_content/.
- **Not possible:** Claude in Chrome caps uploads at about 10 MB, Claude desktop computer use only has read access to browsers, and Google blocks sign-in in the isolated devtools Chrome.
