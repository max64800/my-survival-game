# Zone 1 model review (November 15, 2026, Mac)

Owner asked: "go through every finished product, rotate them, take screenshots, outline the issues".
**All 360 Zone 1 models** were photographed from 4 sides (front, right, back, from above) and checked
against `docs/art/MODEL-RULES.md` and the owner's notes in `FEEDBACK.md`.
Result: **147 major, 149 minor, 64 ok.**

- Photo sheets: `sheets/` (`sheets/index.txt` says which models are on which sheet). Every row = one model + size in metres.
- Every model's verdict, problems and fix suggestion: `review.json`.
- Re-take the photos any time with `tools/model_review/` (works on any computer with Chrome).
- Limits: the photos are small, so fine textures and shimmer can't be judged here; check those in the game.
  "maybe" in a note means a guess.

## Owner's own notes in this round
- **Tanning rack:** the lacing ropes still stop short of the hide; the hide floats in the frame (F45/F35 rope problem, comes back).
- **Silver sword:** too wide and not sharp (blade is a flat slab with a blunt tip). Silver is a later zone, but fix it with the weapons pass.

## Patterns (fix these as rules, not one model at a time)
1. **Two styles side by side.** Many pieces are still the OLD plain/plastic style next to new painted ones: about 25 food,
   gem, crystal and creature-part items (bellcap, bug_meat, snail_meat, critter_meat, coal, moss, firecap, gems, wings,
   bat_fang...), mushroom/fungus decor, firefly_jar, grain_sacks, banners, bat_trophy, and building pieces outside the new
   kit: half floors, small floors, narrow walls, wide windows, ramps, ladders, mine props, arches, shelf.
2. **Reskins (one shape, new colour)** — owner rejected these (F60): 3 mushrooms, 4 crystals, 7 gems, 4 runes, 5 dish
   bowls, 2 drink cups, crossbows, wing items (duplicates), boots, columns (Shack and Hearthbrick columns are white
   marble), beams, banners, ladders, mine props (identical), wall shield, wall sconce, stone rug.
3. **Harsh colours (Rule 3):** every Stonehold piece and most stone decor mix white, black and brown blocks
   (stone bed/table/stool/throne/chest/lantern, campfire ring). Hearthbrick mixes pale cream stone with red brick
   everywhere and is blotchy. Soft furnishings are candy-pastel.
4. **Floating / loose parts (Rule: every part touching):** tanning rack ropes, timber stack and plank stack rope loops,
   rune symbols floating in front of rune stones, waterskin straps passing through the bag, planter soil sticking out,
   glow trellis leaves in the air, grip wraps with gaps on two-handed weapons.
5. **Pieces poking out / past the grid (Rule 3):** foundations 2.11–2.14 m wide (grid is 2 m), triangle pieces with
   stair-stepped edges or edge stones past the triangle, wedge bricks jutting into arched openings, yellow-green bits on
   Stonehold edges, little feet under ceiling panels and the flat roof.
6. **Roof rules (Rule 4, F79):** 8 Stonehold sloped roof pieces and 2 Stonehold gables exist and must go; they are also
   filled wedges. Hearthbrick roof tiles look like round logs; inner corners (both angles, Shack and Hearthbrick) have a log
   lying in the valley and tiles crossing; Shack outer corner has holes along the ridge.
7. **Doors (Rule 5, F75):** second doorway kind (arch_doorway) in every style; plank arch_doorway and copper door are square.
8. **Wall items stand on floor posts:** banners, bat trophy, crossed pickaxes, fossil/horn plaques, map board, rune
   shield, peg rack, wall torch should hang on walls with a flat back (like the tool rack, F46).
9. **Outfits are blocks (F55):** boots, cap, greaves, trousers, tunic, mail, plate, helms read as stools, crates or
   tombstones. Biggest block of work; wait for the outfit pictures.
10. **Copper doesn't read as copper:** copper sword, greaves, mail, crossbow, chest look like dark rock or wood;
    every copper weapon has a black slot cut under the head.
11. **Weapons:** two-handed axes and maces are as tall as the dwarf (1.33–1.40 m); axe heads are paper-thin with no edge;
    stone mace head has no lashing.
12. **Physically impossible:** a 10 cm thick stone ladder, a 2.9 m thin stone brace, a stone bench with thin stone legs.

## Stations (4 major, 14 minor, 12 ok)

| Model | | Problems | Fix |
|---|---|---|---|
| bed | 🔴 | Still just a thin flat grey slab for a mattress: no pillow, no blanket (F34 asked for mattress, pillow, cover) · Mattress colour is a flat grey-brown, looks like stone | Add a thick lumpy mattress, a pillow and a folded fur/wool blanket with warm colours. |
| campfire | 🔴 | Ring stones are near-perfect cubes · Stones are white next to black next to brown (breaks the calm-colour rule) · No flames visible; logs barely show | Use rounded, chipped grey-brown river stones in one colour family and add visible flame/ember shapes on the logs. |
| chest_copper | 🔴 | No visible copper at all: corners are dark brown lumpy blocks, body is plain wood · Reads as a slightly different wooden chest, not the copper tier | Add bright copper corner caps, straps, rivets and lock plate so it clearly reads as copper. |
| tanning_rack | 🔴 | Confirmed: the lacing ropes stop short and do not reach the hide; hide floats in the middle · Hide is a flat blob with no stretch marks or lace holes | Stretch the hide almost to the frame and run each rope from the frame to a hole in the hide edge. |
| anvil | 🟡 | Horn is still a thin straight spike/pyramid (owner F34 said horn looks like a pyramid) | Make the horn a thick curved cone that tapers smoothly from the body, chunkier and rounded. |
| bellows | 🟡 | Leather pleats look like a stack of wooden discs (wood-coloured, perfectly round), not soft leather · Handle loops are flat perfect rings stuck to the side | Make the pleats darker leather with folds that pinch toward the hinge; give the handles a carved grip shape. |
| chest_small | 🟡 | Plank ends stick out past the corners like a log cabin, edges look stepped · Lid line hard to see; reads as a crate more than a chest | Cut planks flush at the corners under the straps and give the lid a clear rounded/overhanging shape. |
| chest_stone | 🟡 | Open box with no lid · Black iron corner bars stick up past the stone rim and down past the base | Trim the corner bars to the box height and add a stone or wood lid. |
| chisel_rack | 🟡 | Chisels are plain round dowels with no metal tips · Loose pebbles sit away from the model on the ground | Give each chisel a metal blade tip and a handle; drop or tuck the stray pebbles against the base. |
| chopping_block | 🟡 | Roots are evenly spaced straight cones, look like stool legs or spider legs | Make roots uneven, curved and flowing into the trunk at different sizes. |
| copper_drip_basin | 🟡 | Water still reads as a pale flat disc with a white centre, more like ice than water · Tiny cup on the side pillar looks tacked on | Darker blue-green water with depth gradient; join the side cup into the overflow spout clearly. |
| crate_ore_fill | 🟡 | Maybe: has its own stone tray rim, which would show as a stone box inside the wooden ore crate · Crystals are small and pale | Check it in-game inside crate_ore; if the rim shows, remove it and keep only the heap. |
| crystal_sconce | 🟡 | Crystal is a perfect hexagonal prism with a pyramid top, pure white · Stray green blob at the bottom left of the back plate (like the old rune slab green bits) | Make an uneven crystal cluster with a tint; remove or blend the green bit. |
| glow_lamp | 🟡 | Post just stands between two loose rocks, could tip over; not clearly fixed · Lantern top is a plain black cage (F34 wanted more detail on torch top and rope) | Sink the post into a rock pile or a footed base; add detail to the lantern cap. |
| grindstone | 🟡 | Wheel is a near-perfect circle; otherwise attached and readable. | Chip the wheel edge a little. |
| rune_slab | 🟡 | Back is a much darker stone than the front and sides, looks like a different material | Use the same stone colour all around. |
| stone_saw | 🟡 | Maybe: the saw blade is at the top of the frame above the stone, not in a cut in the stone (F65 picture) · Stone block is an almost perfect box | Lower the blade into a visible slot in the stone; chip the stone block's edges. |
| training_dummy | 🟡 | Sack head is low-poly and faceted; body is grey lumpy sack. | Smoother stitched sack with painted texture. |

**OK:** carpenters_vise, cooking_pot, crate_ore, drip_bucket, farm_plot, gem_bench, kiln, masonry_table, rope_ladder, smelter, tool_rack, workbench

## Decor (20 major, 28 minor, 20 ok)

| Model | | Problems | Fix |
|---|---|---|---|
| banner_anvil | 🔴 | Old plain style: flat smooth cloth, flat single colour · Anvil emblem is a 3D white triangle + box that sticks far out sideways (seen in side view) · Banner on a floor stake instead of hanging | Paint the emblem onto the cloth (or stitch it flat), add cloth folds/fraying, hang from a wall or ceiling bar. |
| banner_landscape | 🔴 | Same as banner_anvil: flat cloth, emblem triangles poke far out of the cloth in side view · Abstract triangles do not read as a landscape | Paint a mountain/cave picture flat on the cloth with folds; same fix as banner_anvil. |
| bat_trophy | 🔴 | Bat is a faceted ball with flat pink triangle wings, old low-poly style · Wings stick out past the board edges · Wall trophy stands on a floor stake | Rebuild the bat in the creature style (match the game's bat), sized to the board, make it a wall piece. |
| crossed_pickaxes | 🔴 | Pickaxe heads are straight flat black bars, do not read as pickaxes · Heads stick out above the board · Wall plaque on a floor stake | Curved pointed pick heads within the board outline; make it a wall piece. |
| firefly_jar | 🔴 | Solid cream-coloured smooth jar: no glass, no fireflies visible · Old smooth style, flat single colour | See-through glass jar with glowing dots inside, cork and string tie. |
| glow_trellis | 🔴 | Lattice only fills the lower half; leaves at the top float in empty air · Leaves are not joined by any vine stems | Run lattice to the top and grow a vine stem through it that every leaf attaches to. |
| hanging_herbs | 🔴 | Herb bundles are smooth pastel cones (purple, pink, mint) that look like paper umbrellas, not herbs · Odd candy colours · Small extra block halfway up the side post (side view) | Leafy dried bundles in greens/browns tied with string; remove or explain the side block. |
| hearth_bed | 🔴 | Pastel candy-stripe blanket on a dark lumpy brown layer that looks like rubble · Arch bricks on the headboard have gaps and look loose · Mint-green posts clash with red brick | Warm woven blanket in brick-family colours, solid mattress, arch bricks touching each other. |
| hearth_fireplace | 🔴 | Bricks are strict alternating red and pale stripes (too stripey/blotchy, same as owner's Hearthbrick note) · Opening is filled with bricks from the front; the back shows a black hole, so it may be facing the wrong way · No fire, logs or hearth floor | Calm brick colours, open firebox on the front side with logs and embers. |
| hearth_planter | 🔴 | Dark soil disc sticks out past both sides of the planter (side view) · Mushrooms sit on the stone top, not in soil · Green blobs stuck on the front face | Sink the soil inside the box with a rim, plant mushrooms in it, attach the leaves to stems. |
| horn_plaque | 🔴 | Horn is a perfect pure-white cone sticking straight out · Horn tip shows as a white disc through the back of the board · Wall plaque on a floor stake | Curved, ridged horn in bone colours, mounted to the front only, wall piece. |
| mushroom_fountain | 🔴 | Ring stones are cubes in white, black and brown (breaks the calm-colour rule) · Mushroom is a smooth plain shape (old style) · Water streams are thin lines | Rounded stones in one colour family, textured mushroom with gills, thicker falling water. |
| mushroom_planter | 🔴 | Round soil disc pokes out past the box sides (side view) · Planter mixes plain old style with new crate style | Fill soil inside the box walls; texture the mushrooms. |
| mushroom_stool | 🔴 | Smooth low-poly mushroom with no texture: old Play-Doh style · Flat single colours | Rebuild in the kit style: gills, cap spots painted, chunky stem with grain. |
| stone_bed | 🔴 | Base is a checkerboard of white, black and brown blocks (breaks calm-colour rule) · Flat salmon mattress on a dark lumpy brown layer that looks like rubble | Stone in one grey family with few accents, padded mattress with fur blanket. |
| stone_chest | 🔴 | Stone blocks mix white, black and brown · Wooden lid is puffy and pillow-shaped (soft, Play-Doh look) | One stone colour family; a flat or gently curved plank lid with iron bands. |
| stone_stool | 🔴 | Legs mix white, black and brown stone · Seat cushion is a smooth flat salmon slab | Matching stone legs; textured leather/fur cushion. |
| stone_table | 🔴 | Legs mix white, black and brown; middle leg has a broken white patch with black chunks (texture glitch) · Top slabs are uneven heights and not aligned to the legs | Same-colour legs, one solid top or flush slabs resting on the legs. |
| stone_throne | 🔴 | Back posts mismatch (one black, one brown); pale stone block perched on top · Mix of black, white, brown and orange | One stone family, matching posts, carved headrest joined to the back. |
| timber_stack | 🔴 | Rope loops are big loose circles that do not touch the stack (classic loose-rope problem) · Planks are perfect boxes | Wrap the rope tight around the stack; vary plank sizes and edges. |
| brazier | 🟡 | Bowl is a perfect smooth black cone, flat colour · Thin wooden legs under a fire bowl (would burn) · Coals are flat pale chips, no glow/flame | Iron bowl with rim dents and rivets on iron legs, heaped glowing coals. |
| candle_cluster | 🟡 | Candles are perfect white cylinders with no flames · Hardly any wax drips | Uneven candle heights with melted tops, drips onto the base, small flames. |
| chandelier | 🟡 | A chandelier standing on a floor pole (reads as a maypole); chandeliers hang · Candles are thin white sticks | Hang it from a chain (ceiling piece) or rename to a standing candelabra with thicker candles. |
| cheese_shelf | 🟡 | Cheese wheels are perfect smooth pale cylinders · Maybe: cheese wheels poke through the right side board (3/4 view) | Uneven wheels with rind colour and a cut wedge; keep them inside the shelf. |
| crystal_lamp_post | 🟡 | Crystal is a perfect white hexagonal prism | Uneven tinted crystal cluster. |
| firewood_rack | 🟡 | Logs are identical octagons in a perfect grid · Maybe: log ends overlap the side posts in the front view | Vary log size, shape and bark; keep logs inside the frame. |
| fossil_plaque | 🟡 | Wall plaque on a floor stake | Make it a wall piece (flat back) like the tool rack. |
| grain_sacks | 🟡 | Sacks are faceted low-poly white lumps (old style, Play-Doh look) · Flat off-white colour | Burlap sacks with weave texture, folds, tied necks and a darker tan colour. |
| hearth_chair | 🟡 | Very dark green, almost black, with a flat salmon cushion: odd colour mix · Back is a perfect rounded rectangle | Lighter painted wood, cushion with folds, uneven back shape. |
| hearth_dresser | 🟡 | Plates are perfect flat white discs · Near-black green body with a bright orange top clashes; back is a flat dark slab | Plates with rims and patterns, calmer body colour matching Hearthbrick wood. |
| hearth_pot_rack | 🟡 | Dark green block on top looks unrelated · Frying pan is a flat black disc | Wooden or iron top bar matching the posts; give the pan a rim and handle shape. |
| hearth_rug | 🟡 | Perfect concentric circles like a target, pale pastel colours | Braided oval rug with uneven rings in warm reds/browns. |
| hearth_table | 🟡 | Dark green top on a brick column clashes · Column bricks mix red and pale (blotchy) | Wood top in Hearthbrick wood colour; calm brick colours. |
| keg | 🟡 | Metal hoops stand proud of the keg like separate rings (F61 issue) · Body is almost a straight cylinder, no bulge | Bulge the staves and wrap the hoops flush on the surface. |
| map_board | 🟡 | Map is a blank cream sheet with three lines · Wall board on a floor stake | Paint a real map (tunnels, marks), pins, curled corners; wall piece. |
| potted_fungus | 🟡 | Smooth candy-pink cap on a plain white stem (old style, odd colour) | Textured cap in a cave colour, gills, bent stem. |
| rune_shield | 🟡 | Wall shield on a floor stake | Make it a wall piece. |
| shack_bed | 🟡 | Mattress is a grey stone-looking slab · Pastel candy-stripe blanket (pink/blue/cream) clashes with the Shack's browns | Straw/wool mattress in tan, blanket in earthy colours. |
| shack_nightstand | 🟡 | Body is a perfect cube | Uneven planks, a drawer or open shelf, wobble the outline. |
| shack_peg_rack | 🟡 | Wall peg rack on a floor stake; the post runs through the middle of the hanging cloth · Cloth is a flat stiff sheet | Wall piece; cloth hangs from a peg with folds. |
| shack_rug | 🟡 | Flat pastel peach/cream rectangle, no weave texture | Woven rug texture in earthy colours, uneven edges. |
| stepping_stones | 🟡 | Stones are near-perfect round discs | Irregular flat stones. |
| stone_lantern | 🟡 | One leg is black and the other grey (mismatched) · Light panels are flat cream squares | Match the legs; make the light panel glow or show a candle. |
| stone_rug | 🟡 | Reskin of shack_rug (same shape and zigzag, grey border) · Flat pastel colours | Own design for the Stonehold rug (e.g. fur hide or geometric runes). |
| stone_wall_shelf | 🟡 | Back is a checkerboard of brown, cream, grey and black blocks · Mugs are plain black | Calm stone colours; mugs in pewter/clay. |
| stone_weapon_plaque | 🟡 | Black accent stones stand out; back shows a dark hole/missing stone | Fill the back gap; tone down the black stones. |
| tavern_table | 🟡 | Rope ring around the legs is a perfect circle that floats outside the legs, not tied to them | Tie the rope tight around each leg or replace with wooden stretchers. |
| wall_torch | 🟡 | Wall torch stands on a floor pole · No flame on the torch | Wall piece with flat back plate; add a flame. |

**OK:** beam_1m, beam_2m, beam_2m_26, beam_2m_45, brace_corner, crate_stack, hanging_basket, hanging_lantern, mine_cart, mossy_bench, ore_basket, pole_1m, pole_2m, rail_track, rope_fence, shack_bench, shack_shelf, shack_stool, shack_table, signpost

## Building pieces (68 major, 57 minor, 19 ok)

| Model | | Problems | Fix |
|---|---|---|---|
| arch__clay_brick | 🔴 | Not a real curved arch: square opening with tilted brick blocks jammed into the two top corners · Tilted corner bricks stick out at odd angles and look glued on (F59 said arches would be a curve of wedge stones) · Looks like the OLD plain style, not the Zone 1 Hearthbrick kit | Rebuild as a true curve of wedge bricks meeting edge to edge, same kit as the round doorway |
| arch__cut_stone | 🔴 | Same square-with-tilted-corner-blocks shape as the clay arch, not a curve · Corner stones angled and poking into the opening · Back face is much greyer than the front (two different colours on one piece) | Rebuild as a curved ring of wedge stones; one calm grey family front and back |
| arch__plank_root | 🔴 | Wooden 'arch' is a box beam with tilted plank chunks stuck in the corners; looks random and unsupported · Black iron bands are perfect straight strips; whole piece reads as old plain style | Make it a log lintel with two curved knee braces pegged/lashed into posts, like the Shack doorway |
| arch_doorway__clay_brick | 🔴 | Second doorway kind (there is also doorway__clay_brick): breaks round-doors-only rule F75 · Sides are cream/white stone with red bricks only around the arch: white+red mix, not warm reds · Arch bricks are stair-stepped (jagged), not a smooth curve; white keystone pokes up above the top · Side view is a dark plain slab | Delete this piece; keep only one round doorway per style |
| arch_doorway__cut_stone | 🔴 | Second doorway kind (F75) · Black, white and brown stones all mixed: the 'too drastic' colours of F73 · Arch stones are loose tilted boxes with gaps; keystone with an X sits above the outline · Small yellow bits poke out of the right edge; side view shows a flat grey untextured strip (backing showing) · Shimmer-prone doorway (F76 confirmed by layout) | Delete; keep one round Stonehold doorway in calm greys |
| arch_doorway__plank_root | 🔴 | Second doorway kind and the opening is SQUARE (breaks round-doors-only) · Tilted plank chunks stuck across the top corners look random and floating | Delete; keep one round Shack doorway |
| battlement__cut_stone | 🔴 | Black, white, brown and red-brown stones in one short wall (F73 too drastic) · Reddish wood-looking ledge between layers clashes · Small yellow-green bits stick out at the bottom edge (maybe moss, reads as poking) | Repaint in one calm grey family with ~1 in 8 warm stones |
| battlement_corner__cut_stone | 🔴 | Stack of four separate blocks in stripes: cream, brown, cream, black (very drastic) · Looks like stacked boxes, not a built stone corner | Rebuild as interlocking grey corner stones matching the battlement wall |
| ceiling_panel__clay_brick | 🔴 | Very blotchy bricks: yellow, dark brown and red mixed (F74) · Has little feet underneath like a floor; a ceiling panel should not have legs | Calm warm reds; reuse a clean floor kit without the feet, or with beams underneath |
| ceiling_panel__cut_stone | 🔴 | White, black and brown tiles (F73) · Small feet underneath like a floor | Calm grey tiles; underside beams instead of feet |
| column__clay_brick | 🔴 | column is plain white/grey marble stone, no clay brick at all; identical to the plank_root version (reskin of nothing) · Hearthbrick column should be warm red brick | Build a red brick column with brick courses and a terracotta cap |
| column__plank_root | 🔴 | Shack column is white marble stone, not wood · Identical to column__clay_brick | Make a rough log post with rope bands and a stone footing, like the Shack foundation legs |
| column_base__clay_brick | 🔴 | White stone, no brick: wrong material for Hearthbrick · Perfect circle on perfect square | Red brick plinth |
| column_base__plank_root | 🔴 | White stone base for the wooden Shack: wrong material, reskin of clay base | Use the flat stone footing from the Shack foundation legs, or a log stump base |
| column_capital__clay_brick | 🔴 | White stone capital, no brick: wrong material | Brick/terracotta capital |
| column_capital__plank_root | 🔴 | White stone capital on a wooden style: wrong material | Wooden cap block / log crosspiece with rope |
| column_shaft__clay_brick | 🔴 | White stone, perfect cylinder: no clay brick, identical to plank_root shaft | Red brick shaft |
| column_shaft__plank_root | 🔴 | White stone shaft for the wooden Shack: wrong material | Log shaft with bark and rope bands |
| door__copper_ingot | 🔴 | SQUARE door: breaks round-doors-only rule (F75) · Planks use a rusty brick-like texture, does not read as copper · Thicker (0.27 m) than the other doors (0.16 m) | Remove or rebuild as a round door with copper plates over wood |
| doorway__clay_brick | 🔴 | Checkerboard of white stone and red brick on the sides: harsh white/red mix · White keystone stands above the top line · Two Hearthbrick doorway kinds exist (with arch_doorway) (F75); shimmer reported on this one (F76) | Warm red bricks with a few accents; one round doorway only; keep keystone inside the outline |
| doorway__cut_stone | 🔴 | Drastic white/black/brown blocks (F73). · Arch wedge stones sit loose and tilted; the curve is jagged. · Small yellow-green bits poke out of the sides. | Calm greys; even ring of wedge stones cut to the round opening; nothing past the outline. |
| doorway__plank_root | 🔴 | Square log frame with an arch of loose white stone blocks inside: stones in a wooden Shack, colour clash · Arch stones are separate tilted boxes with gaps, look stuck on, not touching each other cleanly · Lower stones on the sides reach the floor unevenly | Make the round opening from bent planks or log segments; drop the white stones |
| flat_roof__cut_stone | 🔴 | White, black and brown slabs (F73) · Wooden feet/pegs underneath, like the floor piece (a roof on legs?) | Calm grey slabs; flat underside or beams; correct piece type (flat roof is allowed) |
| floor__clay_brick | 🔴 | Blotchy yellow, dark and red bricks (F74 confirmed) · Little feet under the floor | Closer warm reds, ~1 in 8 accents |
| floor__cut_stone | 🔴 | Black, white, brown tiles in big blocks (F73 confirmed) | Calm greys with a few warm stones |
| floor__plank_root | 🔴 | Grey planks in the Shack floor (F78 confirmed) · Round log ends poke out past the edge underneath | All planks warm brown; log ends inside the outline |
| floor_half__clay_brick | 🔴 | Old plain style: neat thin bricks on a big pale beige box base; does not match the full floor · Pale backing visible on all sides (Rule 3: backing must be dark and hidden) | Rebuild as a half-size copy of the new floor__clay_brick |
| floor_half__cut_stone | 🔴 | Old plain style: four flat grey tiles on a beige box; doesn't match the full Stonehold floor · Pale untextured sides | Rebuild as half of the new floor__cut_stone (same layers and depth) |
| floor_triangle__clay_brick | 🔴 | Thick cream/white stone border around a small red brick centre: white+red mix, unlike the full brick floor · Border looks like a separate frame; F77 'bricks past the edge' maybe now hidden by this border rather than fixed | Cut red bricks to the triangle edge, thin brick edging, no white border |
| floor_triangle__cut_stone | 🔴 | Black, white and brown stones (F73) · Stones look jumbled and overlapping at the corners (maybe poking past edge) | Calm greys, stones cut to the triangle |
| floor_triangle__plank_root | 🔴 | Planks are stair-stepped along the long edge instead of cut to the triangle (Rule 3) · A grey stone/dark block sits at one corner, poking out · Size 1.81 x 1.53 m doesn't match the other triangles (2.00 x 1.73) | Cut planks at the triangle angle; match 2.00 x 1.73 m |
| foundation__clay_brick | 🔴 | Cream/white corner bricks plus red bricks: harsh mix (F74) · Arched holes on every side show a flat grey backing panel inside · Top is a messy cut-up brick pattern (F80 confirmed) | Warm red brick foundation, solid or dark-filled arches, clean top course |
| foundation__cut_stone | 🔴 | Black, white, brown, cream stones (F73) · Side views show plain untextured beige blocks (backing/frame visible as a strange colour) · 2.12 m wide: sticks past the 2 m grid (maybe overlaps neighbours) | Calm greys, textured all round, keep inside 2 m |
| foundation_half__clay_brick | 🔴 | Same white+red mix and arch holes as the full foundation · Side view: a red brick strip between plain white stone columns looks pasted on | Match fixed full foundation |
| foundation_half__cut_stone | 🔴 | Black/white/brown stones (F73) · Side view shows flat untextured beige panels (backing showing) · 2.12 m wide past grid | Calm greys, texture all faces, fit inside outline |
| foundation_steps__cut_stone | 🔴 | Steps alternate black and white: zebra stripes, very drastic · Side view shows plain untextured beige blocks | One calm grey family, textured sides |
| foundation_triangle__clay_brick | 🔴 | White stone corner blocks and white rim with red bricks: harsh mix · Rim stones overhang past the brick walls; 2.11 x 1.88 m is bigger than the 2.00 x 1.73 triangle · Arched holes show grey backing | Cut to the triangle outline; warm reds; dark or filled openings |
| foundation_triangle__cut_stone | 🔴 | Black/white/brown stones (F73) · 2.11 x 1.88 m: pokes past the triangle; top rim stones stick out at corners | Calm greys; keep inside outline |
| foundation_triangle__plank_root | 🔴 | Grey planks in deck · Planks stair-step along the long edge, not cut to the triangle | Cut planks at the angle; warm brown only |
| gable_26__cut_stone | 🔴 | Stonehold must not have gables (Rule 4, F79) · Wooden plank coping and flat untextured side face | Remove from Stonehold build menu and models |
| gable_45__cut_stone | 🔴 | Stonehold must not have gables (Rule 4) · Flat untextured side | Remove |
| half_wall__cut_stone | 🔴 | Colours too drastic: white, near-black and dark brown blocks side by side (confirms F73) · Small green/yellow slivers poke out under the bottom edge (moss bits past the outline) · Side/end face is a flat plain beige slab with no stone texture (old style) | Calm greys with 1 in 8 warm stones; remove the poking moss bits; give the end faces real stones. |
| ladder__clay_brick | 🔴 | Same plain ladder as the other two, just painted brick-red: a reskin (F60) · A wooden ladder textured like brick makes no sense; perfectly straight rungs and rails (old plain style) | Give Hearthbrick its own ladder (e.g. wood ladder with terracotta/limestone brackets) or share one wooden ladder for all styles. |
| ladder__cut_stone | 🔴 | Reskin of the same ladder, textured as pale stone · A 10 cm thick stone ladder with thin stone rungs is physically impossible · Pegs/nails stick out of the side rails in the side view | Make it a wood ladder with iron/stone fittings, or iron rungs set in a stone frame, in the Stonehold kit style. |
| mine_prop__clay_brick | 🔴 | Identical to the cut_stone and plank_root mine props (not even recoloured): no Hearthbrick design at all · Plain straight boxes (old plain style); black diagonal straps look like flat stickers | Either one shared wooden mine prop for all styles, or a brick/limestone version in the Hearthbrick kit. |
| mine_prop__cut_stone | 🔴 | Identical copy of the other mine props, all wood, no stone at all · Plain perfect boxes, old style | Stone-footed timber prop with copper bands in the Stonehold kit, or merge into one shared piece. |
| pillar__cut_stone | 🔴 | Stack of mismatched blocks: grey-brown cap, black block, white, a brown band, black again: very drastic colours · Reads as random blocks piled up rather than a column | Calm grey drums of similar size with one copper band; drop the black and brown blocks. |
| railing__clay_brick | 🔴 | Jagged wedge bricks stick into the three arched openings (messy, poking past the arch outline) · Brick colours blotchy | Cut a clean wedge-brick arch (like the F59 arch fix) and calm the reds. |
| roof_26__cut_stone | 🔴 | Stonehold must have flat roofs only: this sloped roof should not exist (F79) · It is a filled stepped block, not a thin panel; black gaps between steps | Delete it and remove it from the build menu for cut_stone. |
| roof_26_inner__clay_brick | 🔴 | Tiles look like logs and cross over each other along the valley (confirms F80) · Valley is covered by a log lying on top instead of tiles dipping into a gutter | Cut tiles cleanly to the valley line on both sides and use a sunken valley channel, no log. |
| roof_26_inner__cut_stone | 🔴 | Sloped roof corner for Stonehold breaks the flat-roof rule · Filled solid block, not a thin open panel | Delete it and remove it from the cut_stone menu. |
| roof_26_outer__cut_stone | 🔴 | Sloped roof corner for Stonehold breaks the flat-roof rule · Filled pyramid, not a thin panel | Delete it and remove it from the cut_stone menu. |
| roof_26_outer__plank_root | 🔴 | Shingle rows stop in steps along the hip log, leaving gaps/holes along the ridge (confirms F80) · Patchy checkerboard shingle colours | Cut shingles to the hip line on both faces so they meet under the hip log with no gaps. |
| roof_26_ridge__cut_stone | 🔴 | Sloped ridge for Stonehold breaks the flat-roof rule · Filled block with a wooden ridge cap | Delete it and remove it from the cut_stone menu. |
| roof_45__cut_stone | 🔴 | Sloped roof for Stonehold breaks the flat-roof rule · Filled 2 m stepped wedge with black gaps, not a thin panel | Delete it and remove it from the cut_stone menu. |
| roof_45_inner__clay_brick | 🔴 | Tiles look like logs and cross each other along the valley (same as F80 on the 26-degree one) · A log lies on top of the valley | Cut tiles to the valley line; sunken valley, no log. |
| roof_45_ridge__cut_stone | 🔴 | Sloped ridge for Stonehold breaks the flat-roof rule · Filled solid block with a wooden cap | Delete it and remove it from the cut_stone menu. |
| sloped_wall__cut_stone | 🔴 | Drastic white/black/brown stones (F73); plain grey side face. | Calm greys; textured sides. |
| small_floor__clay_brick | 🔴 | Old style: bricks on a big pale beige box whose plain sides show. | Rebuild like the new Hearthbrick floor, cut to 1x1 m, no pale box. |
| small_floor__cut_stone | 🔴 | Old plain style: a flat untextured beige box with four stone tiles inset on top · Sides are flat single-colour (one side grey, one beige); perfect box | Rebuild as real stone slabs with chipped edges, matching the Stonehold floor. |
| stairs__cut_stone | 🔴 | Very drastic colours: black bottom tread, black blocks, white and brown blocks (F73) · Side faces are flat untextured beige panels (old style) | Calm grey stones, textured sides, no black tread. |
| wall__cut_stone | 🔴 | Drastic colours: black, dark brown, white and beige blocks mixed (confirms F73) · Tiny yellow-green bits poke out of the mortar lines | Calm greys with a few warm stones; remove the poking bits. |
| wall_narrow__clay_brick | 🔴 | Old style: no limestone corner stones like wall__clay_brick, so two side by side won't match · Side face is mostly flat untextured grey; top shows a messy cut-brick pattern | Rebuild from the same kit as wall__clay_brick (limestone quoins, brick to the edge). |
| wall_narrow__plank_root | 🔴 | Old style: a framed plank panel with no corner logs or rope like wall__plank_root · Will not line up visually next to the full Shack wall | Rebuild with the Shack kit: log posts, rope ties, vertical planks. |
| window_wall__clay_brick | 🔴 | Jagged wedge bricks around the arch poke into the window opening (messy outline) · Sill pokes past the wall outline in the side view (maybe) · Bricks blotchy | Clean wedge-brick arch cut to the opening; keep the sill inside the outline. |
| window_wall__cut_stone | 🔴 | Drastic colours: black, brown and white blocks (F73) · Yellow-green slivers poke out of the left and right edges | Calm greys, remove the poking bits. |
| window_wide__clay_brick | 🔴 | Old style: wooden box frame in brick, no limestone quoins like wall__clay_brick / window_wall__clay_brick · Side face flat untextured grey; top shows pale cut-brick mess | Rebuild from the Hearthbrick kit (limestone quoins, lintel, sill). |
| window_wide__plank_root | 🔴 | Old style: plain vertical planks with square frame, no logs or rope like wall__plank_root / window_wall__plank_root | Rebuild with the Shack kit: log posts, rope, plank infill. |
| banner__copper_ingot | 🟡 | Exactly the same model as banner__plank_root (no copper look at all, a pure duplicate) · Cloth is a perfectly flat sheet, one flat bright red; very saturated next to calm building colours | Give copper banner copper rod/finials and trim, add a slight cloth sag and darker red shading |
| banner__plank_root | 🟡 | Cloth is a perfectly flat sheet in one loud red · Identical to the copper banner | Add a gentle wave/sag and a hand-painted pattern; wooden rod with rope ties |
| beam__clay_brick | 🟡 | Same model as beam__cut_stone (reskin), a straight box timber · Perfect rectangle shape (F62 asked for no perfect rectangles) | Give each family its own beam: Hearthbrick timber with brick-red end caps or brick lintel look |
| beam__cut_stone | 🟡 | Wooden box beam identical to the clay_brick one: no Stonehold design · Perfect rectangle | Make a stone or copper-banded Stonehold beam |
| beam_half__clay_brick | 🟡 | Same box timber as cut_stone half beam (reskin) · Perfect rectangle, end caps look like separate blocks | Match whatever new Hearthbrick beam design is chosen |
| beam_half__cut_stone | 🟡 | Wooden box beam in Stonehold, identical to clay_brick half (reskin) | Match new Stonehold beam design |
| bench__cut_stone | 🟡 | Thin stone slab on thin stone legs with a thin stone stretcher bar: stone that thin would snap (not believable) · Plain straight-edged, old style | Make it chunky: thick slab on two block legs, no stretcher |
| bench__plank_root | 🟡 | Very plain, straight perfect boards; looks like the old simple style next to the new Shack kit (no rope, no logs) | Add log legs, pegs or rope lashings like the Shack foundation |
| brace__cut_stone | 🟡 | 2.9 m long thin stone stick on a diagonal: physically impossible, stone would snap · Brown wood end caps on a stone brace look odd | Make the Stonehold brace a wooden or copper-strapped timber, or a stone corbel |
| ceiling_panel__plank_root | 🟡 | Some planks noticeably paler/greyer than others · Round log ends poke out at the edges underneath | Keep all planks warm brown; keep log ends inside the outline |
| column__cut_stone | 🟡 | Perfectly round shaft with even ribs; brown stone tone differs from Stonehold walls' greys · Same shape as the other two columns (only recoloured) | Make it chunkier/uneven; match Stonehold palette |
| column_shaft__cut_stone | 🟡 | Perfect cylinder with evenly spaced ribs (too perfect) | Add wobble and uneven ribs |
| crate__plank_root | 🟡 | Light grey/white slits show between the front and back planks (backing seen through gaps, Rule 3 says backing must be dark) · Black iron corner posts are perfectly straight | Make the backing dark or close the plank gaps |
| door__cut_stone | 🟡 | Basically the Shack door in a darker brown (reskin, F60) | Give the Stonehold door its own look: heavier planks with copper bands/studs and a stone-grey frame |
| floor_half__plank_root | 🟡 | Different from the full Shack floor: no nails, no log bearers, one dark plank stripe; two half floors next to a full one won't match | Copy the full floor's plank/nail/log layout at half size |
| foundation_half__plank_root | 🟡 | A grey plank in the deck (like F78) | Warm brown planks only |
| foundation_steps__clay_brick | 🟡 | Cream/white stone treads on red brick: white+red mix | Brick or terracotta tread caps in warm tones |
| foundation_steps__plank_root | 🟡 | 2.14 m wide, past the 2 m grid · Open stairs are nice; legs on stone footings fine | Trim to 2.0 m |
| gable_26__clay_brick | 🟡 | Pale stone coping on top extends past the bottom-left corner of the outline (pokes out) · Some yellow/dark bricks (F74) | Keep coping inside outline; calmer bricks; consider terracotta coping |
| gable_26__plank_root | 🟡 | Some grey planks in the infill · Triangle frame is fine, but infill planks look like flat stripes | Warm brown planks only |
| gable_45__clay_brick | 🟡 | Round vent hole has jagged, uneven brick edges (maybe intended) · Pale coping pokes past the outline at the bottom | Neater round vent ring; coping inside the outline |
| gable_45__plank_root | 🟡 | Alternating grey and orange planks make loud stripes (grey planks again) | Warm brown planks only |
| half_wall__clay_brick | 🟡 | Cream/white zig-zag corner bricks at both ends against dark red: white+red mix · Side face plain stone | Use darker brick or terracotta quoins, ~1 in 8 accents |
| half_wall__plank_root | 🟡 | Round log ends at the bottom corners poke below and past the piece outline · One plank has a pale grey edge strip in the middle of the panel | Trim the bottom log ends to the outline and recolour the grey plank warm brown. |
| ladder__plank_root | 🟡 | Too perfect: straight square rails and rungs, no wobble or lashing like the Shack wall/railing (old plain style) · Peg heads stick out of the rail sides | Rough log rails with rope-lashed rungs to match the Shack kit. |
| mine_prop__plank_root | 🟡 | Perfect square beams with no wobble, rope or log look like the new Shack kit · Black diagonal straps look painted on, not like iron that holds anything | Rough log posts and lintel with rope lashing/iron cleats that wrap the joint. |
| pillar__clay_brick | 🟡 | Brick colours blotchy with yellow/dark bricks (F74) · Bricks look slightly uneven past the outline just under the top cap (maybe) | Warmer, closer reds; trim bricks inside the cap outline. |
| railing__cut_stone | 🟡 | Frame is a perfect rectangle with a thin flat top rail; balusters look very regular | Add wobble/chips to the frame and vary the balusters a little. |
| ramp__clay_brick | 🟡 | A filled wedge with a red cobble texture and raised strips: no real bricks, old plain style · Back face is a flat dark slab | Build the slope from laid bricks with limestone edging, like the Hearthbrick stairs. |
| ramp__cut_stone | 🟡 | Filled textured wedge (old plain style); back face much darker than the top (colour jump) · Wooden tread strips on a stone ramp may look out of place | Lay real stone slabs on the slope and keep one calm grey tone all round. |
| ramp__plank_root | 🟡 | Filled wooden wedge with flat plank texture; no log frame or rope like the Shack kit | Plank deck on log stringers, open or log-faced at the sides. |
| roof_26__clay_brick | 🟡 | Half-round tiles at this size read as rows of round logs (owner: tiles never logs) | Make tiles tapered, overlapping S-curves with visible ends, not full cylinders. |
| roof_26__plank_root | 🟡 | Shingles patchy: dark and light squares like a checkerboard | Smaller colour variation between shingles, random not blocky. |
| roof_26_inner__plank_root | 🟡 | A log lies on top of the valley (an inner corner should dip, not have a beam on top) · Shingles patchy light/dark squares | Replace the top log with shingles meeting in a valley; even out shingle colours. |
| roof_26_outer__clay_brick | 🟡 | Tiles read as logs; tile rows end in a jagged stair-step under the hip log · Small spike finial on the top end looks odd | Cut tiles to the hip line and use a proper ridge-tile hip cap. |
| roof_45__clay_brick | 🟡 | Same log-looking round tiles as the 26-degree version | Tapered S-curve tiles. |
| roof_45__plank_root | 🟡 | Patchy shingle colours; some long dark crack lines across the shingles | Even out shingle colours and drop the long crack lines. |
| roof_45_inner__plank_root | 🟡 | A log lies on top of the valley instead of a dip · Patchy shingle colours | Shingles meeting in a valley, no top log. |
| roof_45_outer__clay_brick | 🟡 | Log-looking tiles end in a jagged stair-step under the hip log · Spike finial on top | Cut tiles to the hip and use hip-cap tiles. |
| roof_45_outer__plank_root | 🟡 | Shingle rows step along the hip log; maybe small gaps like F80 · Patchy shingle colours | Cut shingles to the hip line on both faces, check from above for holes. |
| rug__plank_root | 🟡 | Perfect flat rectangle with plain nested rectangles of flat colour · Fringe tassels are tiny dots, only visible on the short ends | Uneven edges, a woven/fur pattern and a slight wrinkle; thicker tassels. |
| shelf__plank_root | 🟡 | Plain box bookcase with perfect boxes and cylinders (old plain style, no logs/rope like the Shack kit) · Back is a flat very dark slab | Rough planks on log uprights with rope or pegs; more varied clutter. |
| sloped_wall__clay_brick | 🟡 | Bricks blotchy with yellow and very dark bricks (F74) · Brick grid very regular | Closer warm reds; slight brick wobble. |
| sloped_wall__plank_root | 🟡 | One grey plank (F78). | All warm planks. |
| small_floor__plank_root | 🟡 | One plank noticeably darker; very clean box planks | Even the plank colour and add wobble. |
| stairs__clay_brick | 🟡 | Solid filled block; bricks blotchy · Pale limestone treads and side contrast strongly with the dark bricks (maybe fine as trim) | Calmer reds; keep limestone only as tread nosing. |
| stairs__plank_root | 🟡 | Grey treads alternate with orange ones: grey planks in the Shack (same as F78) · Bottom treads overhang the log stringer in the side view (maybe not resting on it) | All warm brown treads, each sitting fully on both stringers. |
| table__cut_stone | 🟡 | Thin stone stretcher bars between the legs are physically unlikely · Black flat disc on the top is a perfect circle and odd colour | Thicker stone or wood stretchers; make the disc a chipped clay plate. |
| table__plank_root | 🟡 | Black flat disc on the top is a perfect circle and odd colour | Swap for a wooden bowl/plate with a rim. |
| wall__clay_brick | 🟡 | Bricks blotchy with yellow and very dark bricks (confirms F74) | Closer warm reds, about 1 in 8 accent bricks. |
| wall_narrow__cut_stone | 🟡 | Side faces have flat untextured beige patches · Calm colours here do not match the drastic full wall (siblings mismatch; this one is closer to the target) | Texture the side faces; use this palette for all Stonehold walls. |
| wall_sconce__copper_ingot | 🟡 | Backplate is a plain flat near-black slab (odd colour, perfect rectangle) · Same shape as the cut_stone sconce, only recoloured (reskin) | Copper backplate with rivets and a scroll bracket so it looks fancier than the stone one. |
| wall_shield__copper_ingot | 🟡 | Identical to the plank_root shield except the rim colour (reskin) · The two crossed bars are plain black straight sticks that read like an 'X' crossing it out | Copper boss and rivets, and crossed axes/swords behind it instead of bars. |
| wall_shield__plank_root | 🟡 | Crossed bars are plain black straight sticks (look like an 'X', not weapons) · Shield is a perfect circle | Crossed weapons or a wooden hanger; wobble the rim. |
| weapon_rack__plank_root | 🟡 | Spears lean at angles that maybe pass through the crossbar instead of resting in notches · Small black square hangs on the right post with no clear hook (looks floating) · Plain square beams (old plain style) | Notched crossbar holding the spears upright; hang the black item on a peg; log uprights with rope. |
| window_wall__plank_root | 🟡 | Grey plank panels/shutters beside the window (grey planks in the Shack, like F78) · Shutters lie flat on the wall; maybe flush surfaces could shimmer | Warm brown shutters held 1 cm off the wall on hinges. |
| window_wide__cut_stone | 🟡 | Does not match its siblings (plain light stone, no copper/wood trim like window_wall__cut_stone) · Side face partly untextured | Rebuild with the Stonehold kit and the calm grey palette. |

**OK:** barrel__plank_root, beam__plank_root, beam_half__plank_root, brace__clay_brick, brace__plank_root, chair__plank_root, column_base__cut_stone, column_capital__cut_stone, door__clay_brick, door__plank_root, foundation__plank_root, pillar__plank_root, railing__plank_root, roof_26_ridge__clay_brick, roof_26_ridge__plank_root, roof_45_ridge__clay_brick, roof_45_ridge__plank_root, wall__plank_root, wall_sconce__cut_stone

## Items (55 major, 50 minor, 13 ok)

| Model | | Problems | Fix |
|---|---|---|---|
| axe_2h_copper | 🔴 | 1.40 m tall: taller than the 1.35 m dwarf · Head is two thin flat plates with no thicker middle and no sharpened edge · Grip wraps are separate rings with gaps (the loose-rope problem) · Odd black slot cut into the haft under the head | Shorten to ~1.1 m, give the blades a thick middle tapering to a bright edge, wrap the grip tight, remove the slot |
| axe_2h_stone | 🔴 | 1.37 m tall: as tall as the dwarf · Stone blades look like flat paper-thin sheets, not knapped stone · Small lashing at the head seems too weak to hold two big blades · Grip wraps gappy | Shorten, make thicker wedge-shaped flint heads, bigger tight lashing |
| bat_fang | 🔴 | Old plain style: smooth untextured white cone · A brown lump sits on top of the fang and doesn't read as anything (gum? root?) · Fang is a straight cone, not curved | Remake: curved, chipped, ivory fang with a painted root end, no loose lump |
| bellcap | 🔴 | Old untextured plastic style: white smooth mushroom on a dirt disc, perfect shapes. | Hand-build in the painted style like the other mushrooms. |
| boots_copper | 🔴 | Both boots stand on one shared slab (looks like a display base) · Tube-shaped shafts and blocky soles (F55 still open) · Copper boots are the leather boots plus a band and toe caps: a reskin | Remake from a picture: separate boots, shaped shafts, real copper plates over the shin/toe |
| boots_leather | 🔴 | Straight tube shafts and blocky feet on a shared slab · Too simple, no laces, seams or folds (F55) | Remake with laces, folds, a turned cuff and separate soles |
| boots_shell | 🔴 | Same mesh as the leather boot with a pale band and shell discs: a reskin · Shell disc on each toe sticks up like a thin wheel, not attached flat | Give shell boots their own shape; shell plates should lie on the boot |
| bug_meat | 🔴 | Smooth white Play-Doh blobs with no texture · An untextured flat green shard sticks out of one end · Doesn't read as meat | Remake as painted bug flesh: segmented, glossy, with a bit of shell |
| cap_leather | 🔴 | Perfectly smooth dome on a flat ring: too simple (F55) · Tiny stray white speck on the rim in two views | Remake with panels, seams, a turned brim; remove the speck |
| coal | 🔴 | Old plain style: untextured low-poly facets · Looks grey with near-white facets, not black coal | Remake: dark glossy coal lumps with painted sheen |
| critter_meat | 🔴 | Old plain style: smooth untextured pink meat and plastic-white bone · Bone knob is a low-poly crystal shape | Remake with painted meat (fat, grain) and a knobbly bone |
| dish_cooked_snail | 🔴 | Shell is stacked perfect rings like a tiered cake, untextured · A long stick goes straight through it and sticks out far on both sides | Remake: a real spiral shell, shorter skewer, painted |
| dish_roasted_bug | 🔴 | Just a smooth cream blob on a board: doesn't look like a bug | Model a roasted bug: legs, segments, browned shell |
| drink_bellcap_juice | 🔴 | From above, the liquid is a flat white surface and a brown block of the cup wall pokes through it (overlap, may shimmer) · Same cup as glowcap tea | Fit the liquid inside the cup wall with a gap, give it colour and a gradient |
| drink_firecap_cordial | 🔴 | Old plain style: untextured flat orange body and flat pale-blue cone, plastic look | Remake as a painted clay or glass bottle with rope neck |
| drink_glowcap_tea | 🔴 | Same cup as bellcap juice with the same brown block poking through the liquid · Liquid is a flat pale colour | Fix the liquid fit; give the tea its own cup |
| firecap | 🔴 | Old plain style: untextured cap and white stalk · Spots are little white cubes sticking out of the cap | Paint the cap and stalk, make spots flat painted flecks |
| gem_blight | 🔴 | Plain untextured polyhedron, flat colour · Same shape as 7 other gems (reskins) | Paint facets with inner light, give each gem its own cut |
| gem_burrow | 🔴 | Plain untextured polyhedron · Brown colour makes it look like a rock, not a gem · Same shape as other gems | Own cut, painted facets, warmer amber tone |
| gem_cinder_wake | 🔴 | A black stone ring cuts straight through the gem (parts overlap) · White peg on top floats at the ring's top · Gem itself is untextured flat yellow | Seat the gem inside the ring with prongs; paint the gem |
| gem_ember | 🔴 | Plain untextured polyhedron, flat colour, same shape as other gems | Own cut, painted facets |
| gem_hoarfrost_pulse | 🔴 | Same ring-through-gem overlap as cinder_wake · Untextured pale gem | Seat the gem in the ring with prongs; paint it |
| gem_jolt | 🔴 | Plain untextured polyhedron, same shape as other gems · Mustard colour looks dull | Own cut, painted facets, brighter yellow |
| gem_keen | 🔴 | Plain untextured grey-white polyhedron: reads as a rock · Same shape as other gems | Own cut, painted clear facets |
| gem_leech | 🔴 | Plain untextured polyhedron, same shape as other gems | Own cut, painted facets |
| gem_rime | 🔴 | Plain untextured polyhedron, same shape as other gems | Own cut, painted facets |
| glow_gland | 🔴 | A perfect smooth green sphere with a cork: looks like a potion bottle, not a gland · Small brown chips stick out of its sides, not attached to anything | Remake as an organic glowing sac with veins; remove the stray chips |
| glowcap | 🔴 | Same mesh as firecap/hollowcap, only recoloured · White cube spots stick out of the cap · Untextured cap and stalk | Own shape per mushroom, painted, glowing cap |
| greaves_copper | 🔴 | Looks like a stool or Stonehenge: two tubes under a flat slab, not leg armour · Copper reads as dark red rock · Too simple (F55) | Remake from a picture: shaped shin plates with straps, no slab |
| greaves_shell | 🔴 | Same stool shape as copper greaves (reskin) · Stone tubes with shell spirals, doesn't read as armour | Own design with shell plates over a padded legging |
| helm_copper | 🔴 | A long stick lies across the top and pokes past the helmet's outline · Dome is a near-perfect half sphere | Remove or shorten the bar into a proper crest attached to the dome; dent the dome |
| helm_shell | 🔴 | Same bar poking past the outline · Same helmet with shell discs stuck on the sides (reskin) | Fix the bar; own design for the shell helm |
| hollowcap | 🔴 | Same mesh as firecap/glowcap, only recoloured · Spots are little cubes sticking out · Untextured | Own shape (a hollow, cupped cap?), painted |
| keeper_heartstone | 🔴 | Pink gem is an untextured smooth blob · Black rock base is nearly pure black, harsh next to pastel pink | Paint a glowing heart-shaped crystal; dark grey textured base |
| leather | 🔴 | Looks like stacked wooden boards and a log, not leather · White stitch dashes float above the top edge | Remake as folded/rolled soft hide; stitches sit on the leather |
| mace_2h_copper | 🔴 | 1.37 m: as tall as the dwarf · Head is a box with spikes; grip wraps have gaps · Black slot in the haft | Shorten to ~1.1 m, shaped head, tight wrap |
| mace_2h_stone | 🔴 | 1.33 m: as tall as the dwarf · Stone head just sits on the stick: no lashing, collar or socket holding it | Shorten; add heavy lashing joining head and haft |
| mail_copper | 🔴 | Looks like a box or barrel, not mail armour · Shoulder lumps are flat discs; copper looks like rock (F55) | Remake from a picture: rings/scales, shaped torso and shoulders |
| moss | 🔴 | Moss tufts are untextured pale-green polyhedra: look like gems or popcorn, not moss | Soft fuzzy painted tufts hugging the dirt |
| plank_root | 🔴 | Rope bands are round hoops much bigger than the square stack: they don't touch the planks (loose rope) · Planks are clean boxes | Wrap the rope tight around the stack's square shape; roughen the planks |
| plate_shell | 🔴 | Same box shape as mail_copper (reskin): looks like a stone block or tombstone, not armour | Own design: shell plates over a leather jerkin |
| root_tuber | 🔴 | Reads as a log on stick legs (like a little animal), not a tuber · Roots are straight perfect cones; sprouts are flat | Rounder knobbly tuber with curly roots and leafy sprouts |
| rune_cobalt | 🔴 | The rune symbol is a separate flat-colour stick shape floating in front of the stone (side view shows a gap) · Same stone and same symbol as the other 3 runes, only colour changes | Carve the rune into the stone and paint/glow it inside the groove; a different symbol per rune |
| rune_crimson | 🔴 | The rune symbol is a separate flat-colour stick shape floating in front of the stone (side view shows a gap) · Same stone and same symbol as the other 3 runes, only colour changes | Carve the rune into the stone and paint/glow it inside the groove; a different symbol per rune |
| rune_ochre | 🔴 | The rune symbol is a separate flat-colour stick shape floating in front of the stone (side view shows a gap) · Same stone and same symbol as the other 3 runes, only colour changes | Carve the rune into the stone and paint/glow it inside the groove; a different symbol per rune |
| rune_verdant | 🔴 | The rune symbol is a separate flat-colour stick shape floating in front of the stone (side view shows a gap) · Same stone and same symbol as the other 3 runes, only colour changes | Carve the rune into the stone and paint/glow it inside the groove; a different symbol per rune |
| shell_piece | 🔴 | Grey low-poly clump of swirls on a little stand: unreadable, doesn't look like a shell piece | Remake as one curved broken shell fragment with painted ridges |
| snail_meat | 🔴 | Smooth untextured pinkish-white Play-Doh blobs | Painted glossy snail flesh with texture |
| trousers_leather | 🔴 | Looks like a stool: two tubes under a flat slab, not trousers · Too simple (F55) | Remake from a picture: shaped legs, waist, belt |
| tunic_leather | 🔴 | Looks like a crate with shoulder lumps, not a tunic · Two white lines float on the front | Remake from a picture: shaped body, sleeves, laces; stitches on the surface |
| waterskin_clean | 🔴 | A flat ring circles the bag like Saturn's ring, passing through it: doesn't read as a strap · Cork is a square block | Make the strap a loop tied at the neck; round, tapered cork |
| waterskin_dirty | 🔴 | Same Saturn ring through the bag · Flat green shard pokes out of the bag | Same fix; show dirt with a stain, not a shard |
| waterskin_empty | 🔴 | The flat bag floats above the ring strap, not touching it | Bag lies on the ground with the strap attached at the neck |
| wing_leather | 🔴 | Old plain style: flat untextured pink panels with sticks · Same model as wingskin | Remake as painted leathery wing skin with bone struts |
| wingskin | 🔴 | Old plain style: flat untextured pink panels · Same model as wing_leather, slightly pinker | Remake, or merge with wing_leather if they are one item |
| ancient_brick | 🟡 | Pale green moss is a smooth perfect oval sitting on top like a pat of butter | Make the moss a ragged, thin patch that follows the brick surface and creeps into the cracks |
| axe_copper | 🟡 | Head is a flat plate with no wedge or edge · Black slot in the haft under the head | Thicken the head toward the eye, add a sharpened edge band, drop the slot |
| axe_stone | 🟡 | Stone head reads as a thin flat sheet from the front | Make the stone head a thicker chipped wedge |
| basalt | 🟡 | Almost pure black, faces barely readable; plainer than the newer painted materials | Lift to dark grey-blue with painted highlights on edges |
| bolt_ember | 🟡 | Fletching is one flat white shape, not 3 feathers; pale yellow tip. | Three real feathers (as F48), stronger ember colour on the tip. |
| bolt_fang | 🟡 | Fletching is one flat white shape, not 3 feathers. | Three real feathers (as F48). |
| bolt_glow | 🟡 | Fletching is one flat white oval, not three feathers with vanes (the F48 complaint) · Crystal tip is a plain flat-colour prism, no painted facets or glow | Make three real feathers with split vanes; paint the crystal tips |
| bolt_metal | 🟡 | Fletching is one flat white oval, not three feathers with vanes (the F48 complaint) | Make three real feathers with split vanes; paint the crystal tips |
| bolt_rime | 🟡 | Fletching is one flat white oval, not three feathers with vanes (the F48 complaint) · Crystal tip is a plain flat-colour prism, no painted facets or glow | Make three real feathers with split vanes; paint the crystal tips |
| bolt_stone | 🟡 | Fletching is one flat white oval, not three feathers with vanes (the F48 complaint) | Make three real feathers with split vanes; paint the crystal tips |
| bolt_thumper | 🟡 | Fletching is one flat white oval, not three feathers with vanes (the F48 complaint) · Blunt black head is a plain block; maybe fine for a blunt bolt | Make three real feathers with split vanes; paint the crystal tips |
| build_hammer | 🟡 | Head is a near-perfect box | Bevel and dent the head a little, slight taper |
| clay | 🟡 | Crumpled low-poly look, different from the smooth painted siblings · Almost the same shape and colour as dirt, easy to confuse | Make clay a smooth wet lump with finger marks, more orange-grey than dirt |
| critter_hide | 🟡 | The flat flap under the roll looks like a stiff wooden board, not soft hide · Roll end is a perfect ring | Make the flap thinner and wavy, roll end uneven |
| crossbow_copper | 🟡 | Almost no copper visible: looks like the stone crossbow (reskin) | Add copper prod/fittings so tiers look different |
| crossbow_stone | 🟡 | Same model as the copper crossbow | Give the lower tier a rougher, lashed design |
| crystal_blue | 🟡 | Same mesh as the other 3 crystals, only the colour changes · Flat pastel colour, no inner shading or glow · Small yellow-green bits at the base (like the stray green bits on the rune slab) | Vary the cluster shape per crystal, paint inner gradients, remove the green bits |
| crystal_green | 🟡 | Same mesh as the other 3 crystals, only the colour changes · Flat pastel colour, no inner shading or glow · Small yellow-green bits at the base (like the stray green bits on the rune slab) | Vary the cluster shape per crystal, paint inner gradients, remove the green bits |
| crystal_red | 🟡 | Same mesh as the other 3 crystals, only the colour changes · Flat pastel colour, no inner shading or glow · Small yellow-green bits at the base (like the stray green bits on the rune slab) | Vary the cluster shape per crystal, paint inner gradients, remove the green bits |
| crystal_white | 🟡 | Same mesh as the other 3 crystals, only the colour changes · Flat pastel colour, no inner shading or glow · Small yellow-green bits at the base (like the stray green bits on the rune slab) | Vary the cluster shape per crystal, paint inner gradients, remove the green bits |
| dirt | 🟡 | Crumpled low-poly heap, nearly identical to clay | Darker, crumblier soil with pebbles so it reads differently from clay |
| dish_bug_stew | 🟡 | Stew is one flat cream disc (the F39 flat-colour problem) · Same bowl as 3 other stews | Paint a gradient and chunks into the stew; vary the bowl |
| dish_firecap_skewer | 🟡 | Mushrooms are smooth flat-colour blobs, don't read as mushrooms | Small cap-and-stem shapes with seared marks |
| dish_glow_broth | 🟡 | Broth is a flat pale blue disc, no gradient or glow | Darker centre, lighter rim, glowing specks |
| dish_glowcap_skewer | 🟡 | Same as firecap skewer, recoloured · Blobs don't read as mushrooms | Give it its own shape |
| dish_hearth_stew | 🟡 | Stew surface is a flat tan disc · Pot is nearly pure black | Paint the stew; warm the pot to dark iron grey |
| dish_hollowcap_stew | 🟡 | Flat tan disc stew, same bowl as other stews | Gradient and chunks; vary the bowl |
| dish_miners_pie | 🟡 | Lattice strips are perfect round sticks · Crust is one plain cream colour | Flatten the lattice, add browned crust colour |
| dish_seared_critter | 🟡 | Smooth untextured meat and plastic-white bone (same old style as critter_meat) | Paint sear marks and a knobbly bone |
| dish_snail_stew | 🟡 | Flat colour stew, same bowl reused | Gradient and chunks |
| dish_tuber_mash | 🟡 | Small yellow butter cube maybe floats just above the mash | Sink the butter into the mash, make it a melting pat |
| drink_moss_ale | 🟡 | Foam is a perfect flat white disc on top | Lumpy foam that spills slightly over the rim |
| fiber | 🟡 | Strands are perfect identical cylinders · Tie looks like a wooden ring, not twine | Uneven strands, a twine knot instead of a ring |
| lantern | 🟡 | Glass is a flat light-blue panel and the flame is a tiny flat yellow shape · Body is a perfect hexagon | Glass with a warm glow gradient, a visible flame, slight wobble |
| lantern_back | 🟡 | Back board slats float beside the lantern with no strap or bracket joining them (maybe) | Add straps/brackets so the board clearly holds the lantern |
| mace_copper | 🟡 | Black slot in the haft (same as the other copper weapons) | Remove the slot |
| marble | 🟡 | Harsh black-and-white faceted crumple, old plain look · Doesn't match the smooth painted cut_marble | Smoother white-grey lump with painted veins |
| pickaxe_copper | 🟡 | Picks are thin flat plates, no thickness · Black slot in the haft | Thicker tapering pick arms, remove the slot |
| pickaxe_fang | 🟡 | Fangs are smooth untextured white spikes, plain compared with the rest | Paint ivory with cracks; curve them slightly |
| rootwood | 🟡 | Side roots are straight perfect spikes · Flat pale-green hexagon leaves stuck on top | Curved, tapering roots; small painted moss instead of hexagons |
| rope | 🟡 | Coil is a stack of separate perfect rings, not one wound rope · Loose end is a short stubby cylinder | One continuous spiral with a tapered loose end |
| rusty_scrap | 🟡 | Scraps lie flat and overlap each other on one plane; may shimmer where gear and plate meet | Pile the scraps with small gaps or real contact |
| satchel | 🟡 | Blocky box bag; side pocket is a plain block; handle a perfect arch | Softer sagging leather, stitched pocket, uneven strap |
| shield_copper | 🟡 | Mostly wood; only the boss is copper (tier not obvious) | Add copper rim or bands |
| shield_shell | 🟡 | Shells are perfect donut rings in a neat flower pattern | Irregular overlapping shell plates |
| shield_stone | 🟡 | No stone on it: wood with black iron bands, so the name doesn't match the look | Add stone facing or rename |
| spear_copper | 🟡 | 1.47 m: taller than the dwarf (maybe fine for a spear) | Check length against the dwarf in game |
| spear_stone | 🟡 | 1.46 m: taller than the dwarf (maybe fine for a spear) | Check length against the dwarf in game |
| sword_copper | 🟡 | Blade reads dark brown, not copper · 0.76 m: a little short against the 0.8-1 m target · No pommel | Brighter copper blade with an edge highlight, a bit longer, add a pommel |
| water_bucket | 🟡 | Ripple on the water is a perfect white circle | Irregular ripple ring |

**OK:** brown_rock, clay_brick, copper_ingot, copper_ore, cut_marble, cut_stone, lantern_lens, mace_stone, pickaxe_stone, recipe_page, stone, sword_stone, whetstone

