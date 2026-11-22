## Nov 23: saving the spiral stairs work went wrong once, then fixed

**What happened**
- Several chats change the same code files at the same time. Claude saves (commits) only its own changed lines.
- Claude's first save of the spiral-stairs work put some lines in the wrong spot in `dwarf.gd` and `pieces.gd`.
  It also took along two half-finished pieces of another chat's camera/sprint code. The saved copy would not have
  started. The files on the PC were fine the whole time.
- Why: the "only my lines" patch gave positions by line number with no surrounding lines to check against. The
  Twin Gate chat had just saved and undone a change in the same file, so the numbers pointed to the wrong lines.
  The other chat hit the same trap an hour earlier.
- Fix: a fix-up save (9467e2c0). Claude rebuilt both files from the last good saved copy plus only the spiral changes,
  applying them by exact line, bottom to top. Then it checked them against the files on the PC.
- Lesson: after a partial save, always compare the saved file with "old version + my changes" before moving on.
