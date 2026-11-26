## Nov 26: bronze mail, greaves and boots rebuilt by hand (F697 step 7)

**What we did**
- Tried to make the bronze mail on the TRELLIS website (the way the helm was made this morning). The website said
  the free daily GPU time was used up: "120 s requested vs. 128 s left, try again in 23 h". Even one piece didn't fit.
- Asked the owner (wait for tomorrow / timer / pay for PRO). The owner chose: **redo them by hand**.
- Rebuilt `mail_bronze`, `greaves_bronze`, `boots_bronze` in `tools/asset_forge/builds/items_gear.py` to match the
  ChatGPT sheet (`tools/art/sheets/bronze_armour_sheet_nov26.png`), instead of the old boxy ones:
  - mail: a round barrel chest (new `loft()` helper: stacked loops, front bulges more than the back), wide knot
    skirt, big knot medallion with a gold ring and rivets, domed shoulder plates leaning out with knot rims,
    leather straps over the shoulders with buckles, padded collar.
  - greaves: quilted padded legs, two curved shin plates (`arc_plate()` follows the leg's taper so nothing floats),
    a knot band at the top, round knee cup with a gold rim, side buckle; the two rolled tops touch.
  - boots: thick lugged sole, padded foot and shaft, rolled top, knot band, ankle strap + buckle, big domed toe cap
    with rivets.
- New paint: `tools/art/make_bronze_padding.py` makes the dark red-brown quilted padding (`bronzepad_a/b/dark`)
  and a plain dark leather (`bronzepad_plain`) from our own leather paintings.
- The helm stays the TRELLIS one. `bronze_armour_trellis.py` now only lists the helm; MODEL-RULES rule 1 and
  CREDITS now say only the helm is the TRELLIS exception.
- Checks: `check_models.py` 3/3 ok (no floating parts, no shimmer), `test_bronze` and `test_model_rules` pass.

**Mistakes and hurdles**
- TRELLIS quota: the morning's helm run had already used the day's free time. Lesson: one TRELLIS piece per day
  on the free plan, so plan a 4-piece set over 4 days or do it by hand.
- A long Python heredoc with `'''` inside broke the Bash tool ("unexpected EOF"). Fixed by writing the new code to
  a scratch file and splicing it in with a short script.
- First renders: the straps and soles came out pale grey, because the `leather_dark` painting is light tan.
  Fixed with the new plain dark leather paint.
- Kit rivets and boxes keep their spot on the object (not baked into the mesh), so turning their mesh moved them
  the wrong way. The shoulder rivets now get their tilted spot worked out first; buckles are built facing the
  right way instead of being turned.

**Left:** the owner's look at the renders, then the worn bronze set on the dwarf (`dwarf_armor.py` only knows "hide").
