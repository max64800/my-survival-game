## 2026-11-21: hit feel research and plan (F594)

**What we did:** the owner wants hits to feel like Valheim: feel every hit, good combos stun or drop enemies, crits.
Deep research with three web helpers (Valheim, Conan Exiles + 7 Days to Die, general game-feel numbers) and one code
map of our combat. Report: `docs/research/Melee hit feedback design.md`. Plan: `docs/design/HIT-FEEL-PLAN.md`.

**Main finding:** our freeze-on-hit, shake and flash are already about right. The real gap is the stun: our meter
fills by a fixed weapon number (sword light hit = 6) against e.g. 80 for a skeleton, so it takes ~14 hits. Valheim
fills by damage and stuns at ~40% of health, so one combo does it, and a stunned enemy takes 2× damage.
Owner's picks: earned crits only (no luck), stun shown by the enemy (sway, dizzy stars; no bar), knockdowns for
normal enemies only.

**Hurdles:**
- The Valheim wikis blocked the helper (401/402 errors), so some Valheim numbers come from guides and forum posts,
  marked as such in the report.
- FEEDBACK.md had another chat's unsaved edits. Committed only the F594 line by building the staged file from the
  last commit plus that one line, so the other chat's work stays theirs.
