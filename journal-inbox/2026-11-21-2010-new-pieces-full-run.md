## Nov 21: new pieces, the last bits

- The full test run crashed twice partway (out of memory while loading a dungeon model in test_dungeon, before it
  reached the new tests). Every test before the crash passed, and all the building tests pass on their own.
- Claude's own hurdle: another chat's diary merge picked up my inbox entry before I committed it, so my `git add`
  named a file that was gone and quietly staged nothing but the icons. The code went in a second commit.
  Lesson: commit the inbox entry together with the work, right away.
