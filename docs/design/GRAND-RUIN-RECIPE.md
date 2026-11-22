# Grand ruins: how to make a ruin players can't build themselves (owner, Nov 21, 2026)

The owner, after the Old Kiln: "Right now all of our towers are either circular or squared. They're very easy shapes.
... I'm not a builder. I don't know how to build stuff like that. But I do want players to see this and say: oh my
god, I don't know how to build like that, but I absolutely love it. If I had a blueprint... This is a very unique
selling point of our game. Starting from the next one, build them this complicated and this good. If you're missing
any pieces, we can create some."

So from ruin 6 (Twin Gate) on, every ruin's whole version is a **showpiece**: the kind of building only a skilled
builder makes. The ruin is the advert; the blueprint is the prize. This file is the recipe. It adds to
`BLUEPRINT-RECIPE.md` (its rules still hold: stairs never start against a wall, no steps in corners, no window beside
a door, round doors, Hearthbrick/Shack roofs slope, Stonehold roofs flat) and `ruin-rebuild-plan.md`.

We learn the *ways of building* from the best player builds in other games (the owner's screenshots, Nov 21: big
timber-and-stone halls, castles, a tall tiered tower). We never copy a build, a name or a look: the shapes come from
our own dwarf world and our own piece kit.

## What the great builds do (and our simple ones don't)

1. **Many volumes, not one box.** A main hall, wings, a tower, a gatehouse, a lean-to: each its own block with its own
   roof, joined together. Their heights step up toward one tallest part, so the outline reads as a pyramid or a
   mountain from far away. Rule: **at least 4 volumes of at least 3 different heights**, and one clear tallest.
2. **A strong silhouette on top.** Roofs at many levels, steep spires on the towers, small roofs poking out of big ones
   (dormers), lookout rooms on top of towers, a weathervane or banner at the very top. Rule: **the roofline changes
   every 4-6 m**; no long flat ridge with nothing on it.
3. **Upper floors wider than lower ones.** Top floors jut out over the walls below on brackets (a jetty), tower tops
   overhang on corbels, balconies stick out. It is the single most "how did they do that" trick, and it throws deep
   shadows. Rule: **every grand ruin has at least one overhang on brackets.**
4. **Built on a base.** A raised stone plinth or terraces with low walls and railings, wide stair flights up to the
   main door, a lower terrace at the side. The building sits *on* something. Rule: **a terrace or plinth with a grand
   stair**, landings on open ground.
5. **Materials in bands.** Heavy stone at the bottom, then brick or timber framing higher up, a trim band (cornice)
   at every floor line and under every roof. Rule: **a visible band at every floor line**; the ground storey heavier.
6. **Rhythm and depth on every wall.** Pillars every bay, windows set back, walls that step in and out, no wall longer
   than 6 m without a break (a pillar, a buttress, a bay window, a turn). Rule: **nothing flat and long.**
7. **One grand focal point.** A big arched entrance in the middle of the main front, lit, flanked by statues, banners
   or columns; the stairs lead to it. Rule: **the eye lands on the main door first.**
8. **Symmetry, broken once.** The main front is mostly symmetrical; one tower or wing on one side breaks it on
   purpose, so it looks grown, not stamped.
9. **Towers that aren't tubes.** Square towers with corner turrets; towers that change shape as they rise (square
   base, eight sides above, round lantern on top); towers in tiers, each a bit narrower, each with its own cornice;
   a spire roof on top. Rule: **a tower changes at least twice from bottom to top.**
10. **Lived-in details.** Banners, lanterns at doors, statues, planters, crates by the door, furniture inside (the
    ruin junk and decor rules). The ruin shows them broken; the blueprint stays empty for the player to furnish.

## Shapes our grid can make (2 m pieces)
- Squares, rectangles, L, T, U and courtyards; the 12-sided ring (round towers, `_ring_*` helpers); half pieces
  (`foundation_half`, `floor_half`, `wall_narrow`: 1 m steps in the outline); triangles (`floor_triangle`,
  `foundation_triangle`); diagonal walls and railings (`wall_diagonal`, `half_wall_diagonal`, `window_diagonal`,
  `railing_diagonal`: eight-sided towers, cut corners, bay windows).
- Roofs: `roof_26` / `roof_45` slopes, ridges, inner and outer corners (hips and valleys: a square tower gets a
  pyramid roof from four outer corners; an L hall gets a valley), gables.
- Stonehold: battlements and corner battlements, flat roofs. Hearthbrick and Shack: sloped only.

## Pieces we are missing (make them when a ruin needs them; owner, Nov 21: "we can create some")
Every new piece: Blender by script in the style (MODEL-RULES.md), a game piece with a price, tests.
- **Brackets / corbels** (all 3 styles): under a floor that juts out 1 m past the wall below (jetties, balconies,
  overhanging tower tops). The key missing piece.
- **Spire roofs**: a steep pyramid cap for square towers (4 m and 6 m) and a cone for the 12-sided ring (the Kiln
  Crown's closed sister), in Shack and Hearthbrick; with a finial on top.
- **Dormer**: a small window with its own little gable roof that sits on a big roof slope.
- **Cornice / trim band**: a thin moulding that runs along a floor line or under the eaves (a wall-top piece).
- **Buttress**: a sloped pier against a wall (breaks long walls, holds tall ones).
- **Grand portal**: a wide round arch (4 m) for main entrances and gates. (The owner's rule is one round doorway per
  style: ask before making a second kind.)
- **Turret**: a small round corner tower on brackets, hanging off a square tower's corner (castle look).
- **Spiral stair** for round towers (stairs that turn 30 degrees a step).

## Checklist before the 3D page
- [ ] 4+ volumes, 3+ heights, one tallest; the roofline changes every 4-6 m.
- [ ] At least one overhang on brackets; a tower that changes shape twice.
- [ ] A terrace or plinth, a grand stair to a focal main door.
- [ ] Bands at floor lines; no flat wall longer than 6 m.
- [ ] The BLUEPRINT-RECIPE rules (stairs, steps, windows, round doors, roofs per style); everything on the grid,
      stairs meet floors, nothing floats (the blueprint checks).
- [ ] Stairs up to a balcony land on floor as wide as the stairs, with room to step off and walk to the door
      (owner, Nov 22, F615: a 1 m balcony beside a 2 m stair "doesn't really work"; make a 2 m landing there).
- [ ] Cost: a showpiece is big. Show the price on the page; the owner decides if it is too much.
- [ ] Page from `tools/ruins/kiln_page.html` (ruin / wood / original, "Mark new pieces", roof and upper floor on/off,
      decor inside the ruin). Photograph it yourself first; at most 2 photo rounds.
