## Nov 26 — Quick test runs (the suite took over 2 hours)

**What we did:** The owner asked why the tests run 30+ minutes. The full run today took **2 h 9 min** for 1,111 checks.
Most of that is checks that grow a whole test world (cave layouts, keep-clear, start rooms) or rebuild a whole ruin
piece by piece (each ruin's file is 2–3 minutes; there are 16 ruin test files now). They all run one after another.
Owner's pick: "Quick + full".
- `tests/run_tests.gd` now writes how long each check took to `user://test_times.json` (on that computer only).
- A plain run skips every check that took 10 s or more last time, and says how many it skipped. `full=1` runs all.
  `only=` / `fn=` always run what they pick. No test file changed.
- CLAUDE.md and CLAUDE-REFERENCE.md: chats run the plain (quick) run at the end, `full=1` only after ruin, cave or
  world-making work. The PC's times file was filled from the Nov 19 run and today's slow list (72 slow checks known).

**Mistakes and hurdles:**
- One edit (saving the times at the end) silently didn't land because of a `\n` mismatch in the patch script; caught
  when the times file didn't appear, then fixed by hand.
- The 20 s "slow" lines only add up to 27 of the 129 minutes, so most time is in checks under 20 s. The next plain
  run times every check, so the quick runs get quicker by themselves.
