---
name: fact-check-every-statement
description: "HARD (Max 2026-11-05): before any script reaches Max, verify EVERY spoken statement (numbers, facts, comparisons, descriptions, advice) against raw data or primary sources; independent second check; report a verdict table"
metadata:
  type: feedback
---

Max (2026-11-05): "can you verify that all the statements are factually correct? please add that as a rule as well."

**Every script (long form, Shorts, ads, captions with facts), before it goes to Max:**
1. **List every spoken statement that could be true or false**, not only the numbers: dates, floors, sizes, "the highest", "round", "you can walk without going outside", "owners sell", comparisons, analogies ("the size of a big hotel room") and advice.
2. **Numbers: recompute from the raw data in a fresh script**, not from an earlier summary or the website. For DLD:
   - Check `procedure_name_en`: "Sell - Pre registration" = off plan; "Delayed Sell" = an off plan sale registered at handover (usually the developer's, at launch prices, NOT an owner resale); "Sell" = sale of a finished home. DLD does NOT say who the seller is, so never say "owners sell" or "resales" unless the data proves it.
   - Watch the size units: some early off plan rows store sq ft in `procedure_area` instead of m² (AED/sq ft under 1,000 = wrong unit).
   - Filter on the exact building name (other buildings share project names, e.g. "Palm Jumeirah Mall" rows under THE PALM TOWER).
   - Rent: recompute from the DLD rent contracts and say "on a yearly lease" (holiday home income is not in Ejari).
3. **Building and place facts: an independent second check.** A separate agent, or a fresh search that doesn't start from the sources used to write the script, verifies each claim against primary sources (developer site and press releases, operator site, CTBUH, DLD/RERA) and reputable press. Be strict on wording: if a pool isn't literally round, "it's round" is false.
4. **Verdict table in the PDF:** one row per statement with TRUE / FIXED / UNSURE, the source (link or dataset + filter), and the exact figure. Anything not TRUE gets rewritten or cut before filming. Keep a line UNSURE (yellow) only if Max must confirm it himself (e.g. what he sees on site).
5. **Re-check after every rewrite.** A rewrite that changes the wording of a fact needs that fact re-verified.

**Why:** the Palm Tower v2 check found three statements the first pass got wrong: "owners started selling in 2022" (most 2022 DLD rows were Nakheel's delayed registrations at launch prices), the 2022 price per sq ft (3,355 → 3,469 once those were removed), and the return (5.3% → 5.4% on finished home sales). Script v1 had already been shown to Max with an audit saying "CONFIRMED".

**How to apply:** part of [[script-and-plan-skills-checklist]] and [[script-self-review]]. Also follow like for like (eqt-script-doctor 11b) and [[youtube-publishing-rules]].
