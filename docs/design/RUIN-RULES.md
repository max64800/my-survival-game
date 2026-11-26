# Ruin rules: every lesson from every ruin so far (owner, Nov 23, 2026)

The owner: "take all of the feedback from all of the ruins we've already created and create rules to follow when we
create the next ruins... so we don't make any of those mistakes ever again."
Gathered from FEEDBACK.md, FEEDBACK-done.md and JOURNAL.md (Watchtower, Fallen Outpost, Brewhall, Lantern Spire,
Hearth Manor, Prow Hall, Cliff Watch, Twin Gate, Delver's Hut, Shack/Hearthbrick pieces), Nov 14-23.

**Read this before making or changing any ruin, blueprint or tower.** It sits next to:
- `GRAND-RUIN-RECIPE.md`: how a ruin should LOOK (layered, castle, round towers). Its checklist points here.
- `BLUEPRINT-RECIPE.md`: the steps for making a blueprint.
- `docs/art/MODEL-RULES.md`: how each building piece is modelled.
- `WALK-THROUGH-RULES.md`: the table of walk-through lessons (rows 1-8). Every new walk lesson still gets a row there.

Each rule says why (the F-number or the ruin where it went wrong) and what checks it. **A rule with "no check yet" is a
rule we still break by accident:** when you touch that area, add the check.
New lesson? Add it to the right section here **and** add a check that would have caught it.

---

## 1. Stairs
1. **Straight or corner stairs in ruins.** Spiral stairs only in a tower of 4×4 cells or more, going in and out onto
   open floor, with a flat landing at the top. (F626, F713, F716: spirals in the Manor and Twin Gate couldn't be
   climbed.) Check: `test_dwarf_walks_up_every_tower_flight`, `test_spiral_stairs`.
2. **A whole free block at both ends of every flight:** a free 2 m floor tile past its foot and past its top; a free
   triangle after round-stage stairs. Too tight? **Move the stairs.** Never squeeze in a half railing or a smaller
   piece (a half railing doesn't exist; the rebuild chest refused to start). (F811) Check: `test_stairs_free_block`.
3. **A stair never starts against a wall or in a corner.** Its foot is on open floor, reachable from the front.
   (Outpost Nov 17, F393.) Check: `test_stairs_free_block`. Still open: the Watchtower Cabin's stairs.
4. **A stair lands on floor as wide as the stair** (2 m), never a 1 m balcony; the balcony reaches past the stair top
   so you can step off and walk to the door. (F615, Hearth Manor.) Check: `test_hearth_manor_stairs_lead_onto_floor`,
   `test_prow_hall_stairs_lead_onto_floor`.
5. **Corner stairs come out SIDEWAYS** (in at the front, out at their left side, near the back), not straight ahead.
   Never assume where a stair comes out: look it up. (F783, Claude's mistake.) Check: `test_walk_through`.
6. **Leave head room over a stair:** a whole free floor tile above a corner stair's foot, or the dwarf's head hits the
   hole's edge on step 2. (Twin Gate, Nov 22.) Never a floor over a flight: every stair top has its stair hole (F821,
   Prow Hall: a tower stair ran up under the next floor). Check: `test_dwarf_walks_up_every_tower_flight`,
   `stairs_under_a_ceiling` (in `test_prow_hall_play_test_fixes` and `test_play_test_fixes_in_the_ruin`).
7. **Flights meet the floor above exactly:** floors are 2.25 m apart. The stairs stand straight on the floor and their
   slope climbs the last 25 cm, so there's no lip and no drop. (F303, F803.) Check: `test_stairs_down` (up AND down).
8. **Steps about 25 cm high** (8 steps for a 2 m rise), never 33 cm. (F711.)
9. **Stairs are open underneath** (a slanted slab, no solid wedge), so you can walk or put a chest under them.
   (F169.) Check: `test_open_stairs`.
10. **The stair's bump shape is one smooth slope**, not one bump per step, or the dwarf and the camera jitter.
    (F781 🔁 said 3×.) Check: `test_stairs_down`, `test_spiral_stairs`.
11. **Stair railings sit at the stairs' own height and touch them**, never floating; stone stairs get a stone railing.
    (F804, F712.) No check yet for floating railings.
12. **Every stair piece touches its neighbour** (no step board floating 5 cm up). Check: model check FLOAT.
13. **A storey taller than one stair (2 m): the second flight goes straight on** where the first ends, the same way.
    No landing block, no pillars, no ceiling or floor under it. Both sides closed: a triangle (sloped) wall beside each
    flight, a normal wall under the top one (the owner's Prow Hall rebuild; `_stacked_stairs` in the blueprint library).
    Old saves: the rebuild takes down an old landing under the new flights. (F838.) Check: `test_stacked_stairs`.

## 2. Railings, walls and ways through
1. **Nothing stands across a stair's way in or way out:** no railing, wall, battlement, bench or crate. (F783, Prow
   Hall's 5 rule breaks.) Check: `test_walk_through.test_stairs_ways_in_and_out_are_open`.
2. **A stair hole inside a room gets railings only on its deep half**, never fencing the floor you step off onto.
   (F783 round 3.) Check: `test_every_tower_flight_and_door_can_be_reached`.
3. **Walk it from the ground floor, not flight by flight:** every flight's foot and top and both sides of every upper
   door must be reachable from the ground (a flood fill with the dwarf's own body). (F783.) Check:
   `test_every_tower_flight_and_door_can_be_reached` (`src/debug/reach_map.gd`); robot walk `-- ruintest=<ruin> walk`.
4. **A check on paper isn't proof.** Walk the real ruin with the robot dwarf, and photograph every stair hole from
   inside the open space, not from behind a wall. (F783: the paper check passed while the game was blocked.)
5. **Railing checks test at waist height** (railings are 1 m tall), use each piece's true outline (not a box), and
   every check has a self-test that puts the old bad piece back and must catch it. (Nov 23.) Check:
   `test_the_door_check_finds_the_old_twin_gate_railing`.
6. **A wall that collapses loses everything that stood on it** (battlements, railings). (Outpost: 7 floating battlements.)
   No check yet.
7. **Yard walls end on a real wall or tower**, never on a fence or in the air. (Twin Gate back gaps.) No check yet.
8. **Worn or collapsed wall tops collide as their broken top**, so you can jump the low part. (F715.) Check:
   `test_broken_walls_collide_as_their_broken_top`.
9. **Both ends of every railing stand on its floor:** a ring tower's deck has its edge railings only, never a 2 m
   railing where a 0.6 m battlement corner was (it pokes out past the deck). (F820, Prow Hall towers.) Check:
   `railing_ends_poking_out` (in `test_prow_hall_play_test_fixes`, `test_play_test_fixes_in_the_ruin`).
10. **Battlements only on open roofs, and only on stone:** never under a floor (inside a room), and never a stone
    merlon on a wood deck; when a wooden version keeps a stone top, its battlements turn wood with the deck. (F822,
    Prow Hall keep roof.) Check: `merlons_indoors` (same tests).

## 3. Doors and gates
1. **Round doors and doorways only**, one round doorway per style. (F75, model rule 5.)
2. **Every door has about 1 m of clear floor on both sides**, and stairs arrive AT the door, not beside it with a
   railing in between. (F783.) Check: `test_walk_through.test_doors_have_room_on_both_sides`.
3. **Nothing hangs over a door** (no brackets, beams or banners). (Hearth Manor test house.) No check yet.
4. **A ruin's main door gets 10 m of open, level ground in front** when the spot is picked. (Lantern Spire: the door
   faced solid rock.) Check: `RuinSpire.door_is_open` (copy it for every ruin).
5. **Doors swing away from whoever opens them; a double door opens both leaves together, both swing the same way,
   and the ring side faces out.** (F160, F808, F810.)
6. **Both leaves of a double door match** (same bands and rings, the back face too). (F809.) No check yet.
7. **Never mirror a model with a -1 scale:** it turns its light inside out and the leaf renders black. Make a real
   mirrored copy. (F813.)
8. **The round doorway's arch meets the wall above it with no slits** (F814, open), and its ends don't shimmer
   (F76). Check: `buildcheck part=edges`.
9. **Every door has steps up to it**, or a floor level with its sill: never a door standing up in a wall with no way
   to step in. (Owner's Mine-head play test, Nov 26: the ore shed doors.) No check yet.
10. **No ramp, chute or stair ever leads to a window.** It looks like a way in and isn't. (Mine-head ore chutes, Nov 26.)
    No check yet.
11. **A ladder's top ends level with the floor you step onto**, never poking above it or stopping under it. (Mine-head
    shaft ladders, Nov 26.) No check yet.

## 4. Mirrored and round parts
1. **A mirrored tower mirrors everything:** its stairs (and their foot spot), its railing gaps, its doors. Check each
   mirrored half on its own. (F783: the right tower copied the left one's mistake; its stairs started behind a
   0.7 m gap.) Check: `test_every_tower_flight_and_door_can_be_reached`.
2. **Everything sits on the 2 m grid.** A 12-sided ring meets the grid flush on its flat square sides only: join walls,
   walkways and stairs there. (F301, F305: a tower moved 73 cm and walkways didn't line up.) Check:
   `test_blueprint_library.test_every_piece_is_real_and_inside_the_box`, `test_no_two_pieces_overlap`.

## 5. In the cave: where a ruin stands
1. **Use a cave that's already there.** The world grows its caves as normal; the ruin then FINDS a natural cave big
   enough and carves only a little so it fits. Never grow a new cave round a fort and scatter placed rocks round it.
   (F657, said 2×; owner's choice Nov 23: find a cave that fits, Twin Gate first then every ruin, remove all the placed
   rocks.) **Twin Gate done (layout 18, Nov 23):** `RuinTwinGate.pick` scores each spot also on the cave's own rock
   just behind its back (`back_rock`) and a way in with no drop (`front_state`; the yard is dug out 10 m), and new
   worlds grow no rock round it (`RuinTwinGate.natural`). Old worlds keep their grown rock (their ruin stands there).
   **Prow Hall done (layout 19, Nov 23):** the same (`RuinProwHall.natural`, `back_rock` behind the keep,
   `front_state` before the prow doors); its lone tower stands on the cave floor now (no rock lump in any world).
   A new cave rule = a new layout number, so built ruins never move. Still to do: every other ruin.
   Check: `test_spot_keeps_clear_of_what_the_world_grows` (back in rock on 3 seeds, way in) and
   `test_rebuild_the_twin_gate_in_stone` / `test_rebuild_the_prow_hall_in_stone` ("no placed rock round it").
   Weigh the back rock strongly (Prow Hall `BACK_MISS` 1.5): at 0.6 one seed put the keep's back in open air.
2. **Built into the cave, not on a flat floor:** use 3+ of: a back set into a rock wall, parts on different ground
   levels, a bridge over a dip, stairs cut into a slope, cave rock through a broken floor. Use the shapes the cave
   already has. (F657, GRAND-RUIN-RECIPE "Built into the cave".) Check: `test_cave_shape` (Twin Gate, Prow Hall).
3. **Nothing the world grows stands inside a ruin or on its paths and stairs:** no stone columns, crystals, plants,
   pebbles, dripstone or hanging roots, in new AND saved worlds. (Owner placement rule, F268 said 3×, F263, F267.)
   Check: `test_spot_keeps_clear_of_what_the_world_grows` (every ruin), `test_keep_clear`.
4. **Spot search:** look at several caverns (5, not 1) and skip spots with a column under the ruin. If no cavern is
   free, take the best one and move its columns out. Test on 3 worlds (seeds), not one. Keep the search fast (a
   distance map, under a second). (Manor, Prow Hall, Twin Gate.) Check: `test_spot_is_found_quickly`, the spot tests.
5. **Ruin tests need a rock loader (VoxelViewer) at the spot**, or nothing grows and the test lies. (Prow Hall.)
6. **The rebuild digs only air next to pieces**, never inside the ruin's own rock lump or wall. (Prow Hall, Twin Gate.)
   And test that what should be dug IS dug: the Prow Hall's dip under the bridge was never dug (a lump check cut it
   off), so its rubble lay buried. (Nov 23.) Check: `test_cave_shape` ("it digs the dip under the bridge").
7. **Every rubble pile lies on a floor or foundation**, never over a hole. (Watchtower.) Check: the rubble-on-floor test.
8. **Loose parts hang only from flat roof** (stalactites). (Manor.)
9. **The courtyard stays flat and open:** rock lumps go to a corner. (F714.)

## 6. Inside: decor, chests, light
1. **Every prop is on a floor, not in a wall, not in a doorway, not by the stairs, not on a walk line, not touching
   another.** Banners fit the room height. (Twin Gate rule checker: 21 breaks on its first run.) Check: the ruin rule
   checker; `test_ruin_junk_keeps_off_the_ruin`, `test_ruin_junk_keeps_off_the_way_in`.
2. **No chest on stairs or the stair hole:** one floor tile along, against the wall, facing the room. (F611, F359.)
   Check: `test_no_ruin_chest_stands_on_the_stairs`.
3. **The walk path from the door to the stairs and the roof stays clear.** (F264.)
4. **Light from the start:** crystal torches on the inside walls; a ruin cavern needs light. (Watchtower, Outpost.)
5. **Plants and pebbles make room for chests; treasure lies beside the chest, never on it.** (F376.) Check:
   `test_treasure_by_the_chest_never_on_it`.
6. **Ruin loot is rare finds only** (recipe pages, gems, map clues). No free materials, no copper weapons or armour
   this early (copper tools are fine). (F102, F554.) Check: `test_ruin_pages_are_food_or_tools`.
7. **A ruin's own blueprint is learned by rebuilding it**, and the card says where it came from. (F580; F637, open:
   never findable as a page.)

## 7. Rebuilding a ruin
1. **A Rebuilding Chest stands beside the door** (never buried, never on steps); putting materials in starts the
   rebuild by itself. It shows "Still to put in" with pictures, and disappears when the ruin stands. (F350, F631, F578.)
2. **Rebuild only what is broken:** worn walls stay and aren't charged. The price is 30% of new pieces, counted against
   what a first cave really holds (~100-120 planks). Work the price out before sorting pieces so menu and chest agree.
   Every piece (trims too) has a price. (F432, F557 said 3×.)
3. **Starting a rebuild clears all its junk, inside AND outside.** (F596, F581.) Check:
   `test_rebuilt_ruin_drops_all_its_junk`.
4. **The rebuild never stops for good on one blocked piece:** it digs rock where the next piece goes, takes old stairs
   down first, and waits 1 s between tries (not every frame). (F713, F565.) Check: `test_tower_rebuild_play`.
5. **Measure the frame time at a rebuilt ruin before guessing a fix.** (F565: the Twin Gate ran at 7 FPS.)
6. **Show both wood and stone** in the chest's text and pictures. (F689, F560.)
7. **A placed ruin gets its strength worked out at once.** Placing a ruin adds all its pieces in one batch; before
   F819 the strength check only ran if something was taken down, so every ruin piece had strength 0, and a tower whose
   only missing piece was high up (nothing new below it) waited forever ("something is in the way"). Now `end_batch`
   works the strength out after adding too. Check: `test_placed_ruin_has_its_strength`.

## 8. Old saves
1. **A blueprint change also fixes worlds already built:** a load-time fix takes the old pieces out and puts the new
   ones in, only where nothing is in the way, and also takes pieces that stand close by. (F713, F783, F811.) Check:
   `test_rebuild_the_twin_gate_in_stone` (builds the old way, loads, checks it's fixed).
2. **After any blueprint change, make every ruin's JSON again** before testing (Manor, Brewhall, Kiln, Outpost, Spire,
   Watchtower, Twin Gate, Prow Hall). A stale JSON builds pieces that no longer fit. (Manor, Twin Gate; Prow Hall
   Nov 23: after the taller floors (F710) the old JSON kept 205 pieces at the old heights: missing floors, double
   stairs, battlements inside rooms, F819 to F822.) Check: `test_blueprint_matches_its_ruin`.
3. **Say in the note when a change only reaches new worlds** (cave shape, tower inside), so the owner knows.

## 9. Looks and models (short; the full rules are in GRAND-RUIN-RECIPE and MODEL-RULES)
1. **Showpiece builds, never plain round or square towers:** layered (up, out, up, out), castle rings from squares
   and triangles, many heights. (F656, GRAND-RUIN-RECIPE.)
2. **Roofs:** Stonehold flat only; Shack and Hearthbrick sloped only; sloped roofs thin and open underneath; no odd
   pyramid caps. (F79, F626.) Check: `test_model_rules`.
3. **Every material has its own design**, never a reskin; Hearthbrick warm red bricks, no grey Shack planks. (F60, F74, F78.)
4. **No shimmer, no floating, every part touching:** no two surfaces in the same place; walls reach the roof; floors
   have rim beams; diagonal pieces end in points along the square's sides. (F165, F158, MODEL-RULES rule 2.) Check:
   model checks SHIMMER, FLOAT, OUTLINE (and look close: the checker once missed a tiny patch).
5. **Storeys tall enough for the hall:** a big hall's storeys 1.5-2× the normal height. (F710, done Nov 23: the Prow Hall's hall and prow are 4.5 m.)
6. **Brackets never sit on a window's glass** (owner, Nov 25: "it doesn't make sense"): a balcony's brackets go on
   plain wall or on the seam beside a window, never over the opening. (F845, Smeltery.) Builder:
   `BlueprintLibrary._brackets_off_windows()` slides them to the seam. Check: `test_brackets_keep_off_windows`
   (`tests/test_smeltery_design.gd`); use `BlueprintLibrary.bracket_on_glass()` for every new blueprint.

## 10. The camera inside buildings
1. **The camera only bumps into big solid pieces** (walls, floors, roofs, stairs, rock); thin pieces (railings,
   battlements, posts, lamps) never push it. A new solid piece goes on the `SOLID` list in
   `src/player/camera_room.gd`. (F784.) Check: `test_camera_room`.
2. **Pieces between the camera and the dwarf get the see-through circle** (F807, works). Nothing to do for a new
   piece if it uses a normal model paint or `prop.gdshader`; a new shader needs the `see_cut` include. Check:
   `test_camera_fade`.

## 11. How to work on a ruin (Claude's own mistakes)
1. **The order:** plan on the 2 m grid → rule checks → 3D page (photograph it yourself, at most 2 rounds) → build in
   game → robot walk → owner play test. Never say "fixed" for the owner; wait for the play test.
2. **Tests:** run on 3 worlds; a suspiciously fast "ALL PASSED" may hide "Failed to load script" (check the output).
3. **Never hand-edit a generated file** (ruin JSON, dungeon map): change the script and make it again.
4. **Measure the robot's heights from the feet, not the head.**
5. **3D pages:** stay under the size limits (split big files), use glTF text, not .glb links; use a free port.
6. **Shared files:** other chats work here too. Commit only your own lines (a scratch index from HEAD plus your
   changes), check the file list before committing, and never overwrite another chat's journal or feedback lines.
