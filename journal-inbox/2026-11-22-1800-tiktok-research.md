## Nov 22 (Mac): owner's phone notes + 35 TikToks sorted into the to-do list
- **Did:** read the captions of all 35 "Game Developing" TikToks (35th = the bushes link), watched the two the owner
  picked, and added the owner's notes as F695-F705 in FEEDBACK.md (hit flash, hitbox viewer, bronze, cave paths,
  teeth stalactites, slide/double jump/climb/wall run, smooth walk-to-run, hold-to-dash, bushes, Godot learning, AnyMove).
- **Found:** the owner's link (7699085693695397142) is "5 repos for Claude Code" (we already use godot-mcp). The
  picture → 3D with bones video is the one before it (7703557617578216727): AnyMove (Apache 2.0). Its bones are placed
  by hand in a file, not automatically, and its 3D step is picture-to-3D (against our model rule), but it takes our
  own Blender models. The bushes video is an outdoor Unity jungle, not a cave.
- **Hurdles:** TikTok pages wouldn't load in the web reader and the embed link no longer gives captions. Fix: read the
  caption text straight out of each page. Claude's own mistake: the first loop ran once because zsh doesn't split
  a word list in a variable; fixed by reading the links from a file. 10 of the 35 videos were the owner's own posts
  (Dubai, vibe coding), not game dev; skipped.
- **Hurdle 2:** this Mac copy was a day behind the PC. Claude's first commit used F519-F529, numbers the PC had
  already used (it is at F681), and wrote into JOURNAL.md directly (the rule changed to journal-inbox files). Fix:
  moved the commit onto the latest version, renumbered to F695-F705, wrote this as an inbox file. A Godot-made
  .uid file blocked the sync; it was moved aside (the PC's copy wins).
