## Nov 22 (night, PC): F716 follow-up, a commit slip caught and fixed

- To keep other chats' half-done work out of the F716 commit, Claude built the commit in a private copy of
  git's "to be saved" list (the index). But other chats saved three commits while the tests ran, so the copy
  was out of date: the commit quietly **undid their newer work** (39 files instead of 21).
- Caught right away from the file count, before anything was pushed. Fix: the same 21 F716 files put on top
  of the newest commit instead (215d5264); the others' work is all back.
- Lesson: make that private copy right before committing, and check the file count before and after.
- The full test suite didn't finish on this PC (over 15 min; the cave tests take 20-40 s each). The building,
  ruin, stairs and walking tests were run one by one instead: all passed.
