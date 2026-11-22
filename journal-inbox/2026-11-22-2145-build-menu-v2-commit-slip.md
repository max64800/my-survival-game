## Nov 22 (PC, evening): build menu v2, a slip while saving (F709)

- Mistake: I checked which lines in FEEDBACK.md / FEEDBACK-done.md were mine, then ran the full test suite (53 min).
  In that time another chat marked F711-F715 done and added F716, and my commit took their lines along with mine.
  Nothing was lost (it's their finished bookkeeping), but it's against the shared-files rule.
  Lesson: run `git diff --numstat` on shared files right before committing, not before a long wait.
- The full suite had 29 failures, all from another chat's half-finished F9 hitbox work (`src/combat/hit_shapes.gd`
  doesn't compile yet, so `main.gd` can't load). Every build-menu test passes when run on its own.
