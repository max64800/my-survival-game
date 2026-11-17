# Epic caves plan (F211): research, then choices

*Written Nov 16, 2026. Research and plan only, no code yet.* Goes with F109 (rock too round), F110 (world too small)
and F189 (big natural shapes). Moss, grass and small plants (F188) stay with the cave-life Claude.

## The owner's picks (Nov 16, 2026, final)
1. **Areas:** wonders in every big cavern, with a sample of most cave types in Mossy and Fungal now (1A).
2. **Future area themes:** decide later. No themes for North, West, South, Up or Down yet.
3. **First wonder in Mossy:** the **waterfall shaft** only. (The fallen dwarf hall still comes, from pick 5.)
4. **Size:** one giant hall per area (about 120 m long, 50 m tall); wonders 40 to 60 m tall (4B).
5. **Dwarf halls:** a taste now (one fallen hall per area; Mossy's Great Hall is rebuilt into it), the whole city later (5A).
6. **Peek cracks:** real see-through slabs, about 8 per area, hiding both treasure caves and shortcuts (6A).
7. **Water:** wade at the edges, swim on top; diving later with a crafted diving helmet (7A).
8. **Split:** this plan builds the big water and F189's rock columns, arches and boulders; the cave-life Claude keeps
   plants, roots, root pillars and curtains, puddles and mist (8, as suggested).

**Build order with these picks:** 0 pictures → 1 real-shaped caves (with F110) → 2 waterfall shaft → 3 peek cracks →
4 fallen dwarf hall → 5 giant hall → more wonders later, when the owner picks them.

**Also decided (Nov 16):** old saves keep their old caves; new areas are **800 × 800 m** (F110, "the edge much
farther away").

## Progress

**Step 1, real-shaped caves: about half done, paused on Nov 16 (the owner asked to save).**

Done:
- **Two cave layouts.** Layout 1 = the old caves; old saves keep it (checked: exactly the same caves, to 4 decimals).
  Layout 2 = the new caves. A save now remembers its layout, and a friend who joins gets the host's.
  **Until step 1 is finished, new worlds still get layout 1** (`CaveMaker.LAYOUT_DEFAULT`); robots try the new caves
  with `-- layout=2`.
- **Layout 2, per area:** 800 × 800 m; 8 big caverns, 14 middle-sized halls, 40 small rooms (old: 3 + 12); 18 extra
  loop tunnels, 20 dead ends, 90 side passages.
- **Passage kinds:** round tube, canyon (tall, narrow), keyhole (slot under a tube), low passage (wide, flat ceiling),
  rift (very tall crack). **Room shapes:** dome (old), flat ceiling along a rock layer, fallen roof (tall arch over big
  fallen blocks). Rock layers tilt the same way as the flat ceilings. Just outside a big cavern the tunnel squeezes
  into a low or keyhole passage, then the cavern opens up.
- Ruins, camps and nests are spread from near to far; the Copper Deeps are 140 to 320 m from the start.
- Speed so far: planning 0.5 s. Tunnel pieces piled up inside rooms are merged; blocks use the lookup grid.

**Nov 17 (PC, taken over by the rock-textures Claude): speed, part 1 done.** Loading, from program start to
"ready to play" (seed 42, this PC): **old caves 53 s → 13.5 s, new caves 92 s → 41 s**; frame rate 183 → 310+ fps.
- The real cause, in both layouts: Voxel Tools ran 14 rock builders at once (half the cores). Every engine call from a
  script (noise, lists) goes through one shared "check-in desk", so 14 builders mostly queued: they made 24 blocks/s,
  1 builder alone makes 31, 4 builders 65. The plants' planning queued with them (3.5 s alone, 40 s in the game).
  Now `project.godot [voxel]`: a fifth of the cores, at least 3.
- Plant planning (`CaveLife._plan_everywhere`): helpers feel for floors side by side, then the room checks run in the
  old order (exactly the same plants, checked by count + checksum, both layouts). 16.2 → 11.6 s alone (layout 2).
- Rock blocks, layout 2 only: a coarse 2 m net first, every voxel only in boxes near a wall (`_coarse_sdf`); compared
  with every-voxel on 150 blocks: 0 of 614,400 voxels differ. ~25% faster.
- Crystal placing: a spacing grid instead of checking every spot (same spots, both layouts); small gain, the real cost
  is feeling for the rock (layout 2 has several times the tunnel, same density per metre).
- Rock style is kept as a number too (`_style`), so rock checks never read shared text.
- Where the 41 s go now (layout 2): rock round the start ready at 26 s, plants at 41 s (the planning still queues with
  the builders: 11.6 s alone, ~34 s in the game). Ideas left: fewer engine calls per rock check, plants near the start first.

**Tests for layout 2: done (Nov 17)** in `tests/test_cave_layout2.gd`: old caves unchanged (fingerprints, seeds 42 and 7);
the new caves have every room shape and passage kind (seed 42: 147 rooms, 18 big, 5224 tunnel pieces); every passage
kind fits a dwarf (0.36 m each side, 1.5 m tall, with up to 1.2 m sidestep) at 95%+ of spots (old tubes: 99%); and
every old check in `test_cave_maker.gd` runs in layout 2 too (its 400 m numbers now come from the map size).

Still to do:
3. **Tests for layout 2:** counts, every room reachable along its tunnels, narrow passages wide enough for the dwarf
   (72 cm), old caves unchanged (fingerprints in `tools/cave_stats.gd`, seed 42 and 7), and tests that assume 400 m
   areas.
4. **Pictures** of each new passage and room kind for the owner.
5. The owner's OK, then `LAYOUT_DEFAULT = 2`.

Question for the owner (not asked yet): the areas are 4× bigger but have the same number of ruins, camps, nests and
shrines as before. Add more?

*(Below: the research and the choices as first written.)*

---

## 1. What your 6 pictures have in common

Your pictures: a waterfall falling into a shaft, a white dripstone hall over a teal pool, a sea cave with a round hole
in the roof, a cave mouth framing a forest, the blue marble caves, a diver in a flooded cave, a lava tube, a golden lake
cave, Fingal's basalt-column cave, and a page of fantasy mine pictures.

The "wow" comes from the same five things every time:

1. **Something tiny for scale.** A person by the waterfall, a diver, one lamp. Without it, big just looks zoomed in.
2. **One strong light far away.** A beam from a hole above, a lit far end, glowing water. Everything else stays dark.
3. **Water like a mirror.** Still turquoise or golden pools double the room.
4. **One kind of rock per place.** Golden layered stone, white dripstone, blue swirled marble, black columns. Never a
   mix of everything in one room.
5. **A frame.** You look *through* an arch, a hole or a cave mouth at a bright space behind it.

Picture 6 shows a famous fantasy mine from a book and its films. We can't copy anything from it: no names, no shapes,
no layouts. We only take the feeling: rows of giant pillars fading into the dark, one beam of light, a fallen kingdom.

---

## 2. How real caves form (the big lesson)

**Real caves are shaped by water following cracks and rock layers.** That's why real passages are not round balls and
tubes:

- Along a **rock layer** you get flat ceilings and wide, low passages (look at the stacked walls in picture 1).
- Along a **crack** you get tall, narrow slots (cavers call them "rifts").
- A **stream** cutting down into the floor makes a canyon. A round tube on top of a canyon is a "keyhole" passage.
- The **biggest rooms** happen when a roof gets too wide and falls in: an arched ceiling over a hill of giant fallen
  blocks (cavers call this "breakdown").

Our caves are built from squashed balls and round tubes. So they will keep looking round (F109 has come back twice)
until they also follow layers and cracks.

| Cave type | How it forms (simple) | What makes it look real | Real example |
|---|---|---|---|
| **Waterfall shaft** (pic 1) | A stream falls down a crack and slowly dissolves a round chimney | Round shaft with up-and-down grooves and ledges, wet shiny walls, mist, a pool or rubble at the bottom, light from above | Gaping Gill, England: a 98 m drop into a hall about 130 m long |
| **Dripstone hall** (pic 2) | Every drip of water leaves a tiny bit of stone behind: millimetres per hundred years | Stalactites hang down, stalagmites stand up, columns where they meet, thin striped curtains that glow when lit from behind, "frozen waterfalls" of stone, little stepped dams round pools | Carlsbad Big Room, USA: about 33,000 m² floor (four and a half football pitches), up to 78 m tall |
| **Fallen-roof hall** | The roof gets too wide and falls in | Arched ceiling, floor is a hill of house-sized angular blocks, sometimes a hole to the sky with a forest under it | Son Doong, Vietnam: up to 200 m tall, with jungle growing inside |
| **Sea cave and arch** (pic 3) | Waves pound a crack until it opens. Two caves meeting through a cliff make an arch. A roof break makes a round hole | Tall mouth shaped like the crack, beach or water floor, smooth wet band at the waterline, round sky-hole | Benagil, Portugal |
| **Blue marble cave** (pic 3) | Lake waves carved a marble cliff over about 6,000 years | **The blue comes from the water, not the stone!** Fine glacier dust in the lake bounces blue light onto white marble. Swirled grey-white-black bands, smooth spoon-shaped scoops, rippling light | Marble Caves, Chile |
| **Flooded cave** (pic 4) | Dry caves full of dripstone got flooded when the sea rose after the Ice Age | Stalactites under water, very clear water, beams of light from roof holes | Sac Actun, Mexico: about 370 km of underwater passages |
| **Lava tube** (pic 4) | A lava river crusts over on top, keeps flowing underneath, then drains out | Long tunnel, ledges along the walls ("bathtub rings" from old lava levels), drippy "shark teeth" on the ceiling, black, red-brown and glassy colours, roof holes | Manjanggul, Korea: 7.4 km long, up to 30 m tall |
| **Basalt-column cave** (pic 5) | Thick lava cools slowly, shrinks and cracks into 6-sided columns. Later the sea cuts a cave into them | Rows of 6-sided columns like organ pipes, broken stumps as stepping stones, dark grey rock, turquoise water, booming echo | Fingal's Cave, Scotland: about 20 m tall, 75 m deep |
| **Underground lake** (pic 4) | Water gathers at the lowest point. No wind, so it is perfectly still | A perfect mirror, blue-green or golden, sometimes a "starry" ceiling of glow-worms | Lost Sea, USA; Waitomo glow-worm caves, New Zealand |

**Facts that fit our game nicely:**
- **Marble is limestone that got squeezed and heated.** So marble caves next to normal limestone caves make sense.
- **Basalt can sit right on top of limestone.** At the Giant's Causeway in Northern Ireland, the columns lie on white
  chalk.
- **Cavers really do find new caves through cracks.** They feel air blowing through a gap (a "draught"). A strong
  draught means a big cave is behind it. Then they dig, sometimes for years. In 2023 a team in Borneo followed a draught
  through a pile of fallen rocks and found a passage about 1 km long and 40 m wide. That is exactly your crack idea.
  Cavers' words: *draught* (air blowing), *choke* (fallen rocks blocking the way), *window* (a hole looking into another
  cave), *squeeze* (a gap you only just fit through), *lead* (a way on nobody has explored).

---

## 3. Fallen dwarf kingdoms: what to borrow

**Ideas many fantasy stories share (nobody owns these):** pillars carved out of the living rock (left standing when
the hall was dug), long halls of the same pillar over and over, fading into the dark. Wide stairs worn into dips by
feet. Narrow bridges over chasms with no bottom. Giant ancestor statues carved out of the wall beside a gate. Forges
with glowing channels. Light shafts. Carved runes and angular patterns. Water channels and lifts.

**What makes it look "fallen":** toppled pillars with their round pieces lying in a row, bridges that stop in mid-air,
flooded lower halls with only the pillar tops showing, dripstone growing over carvings (shows a very long time passed),
roots through cracks, dead lamps next to the one that still glows, barricades and claw marks.

**Real places to learn from:**
- **Kailasa Temple, India:** a whole temple carved *downward* out of one cliff, about 30 m tall.
- **Basilica Cistern, Istanbul:** 336 pillars in rows, standing in water. The reflection doubles their height.
- **Wieliczka salt mine, Poland:** a chapel 54 m long carved out of salt, even the chandeliers.
- **Derinkuyu, Turkey:** an underground city at least 8 levels deep, with round stone doors that roll shut.
- **Longyou Grottoes, China:** man-made caves with neat parallel chisel stripes on every wall. Great texture idea
  for dwarf-cut stone.
- **Petra, Jordan:** you walk through a narrow slot canyon 1.2 km long, then a 40 m carved front appears. The perfect
  "squeeze, then wow".
- **Bamiyan, Afghanistan:** an empty giant niche where a statue once stood. A strong "fallen" picture.

---

## 4. Tricks games use to make caves feel huge

- **Squeeze, then wow:** a low, tight passage opens into a huge hall. The squeeze makes the hall feel bigger.
- **The first view is a postcard:** you enter a big hall on a ledge partway up and see it all at once. There is always
  a walkable way down (you didn't like climbing out of tunnels that end high in a wall, F141).
- **A landmark that pulls you:** one glowing thing far away, seen from many spots: a waterfall, a forge, a statue.
- **Light leads the eye:** light the goal and the path, keep the rest dark. Warm light against cool rock.
- **Haze for depth:** far things fade into blue-grey mist, so your eyes can tell how far away they are.
- **Things for scale:** normal dwarf-size doors, steps and lamps right next to giant pillars.
- **Echo:** small rooms sound dry, big halls boom. Going from a quiet squeeze into an echoing hall makes the moment.
- **Hand-made rooms inside random caves:** games like Deep Rock Galactic and Enshrouded drop hand-designed rooms into
  random, dig-anywhere caves. Minecraft's big cave update gave each cave type its own decorations (dripstone caves,
  lush caves) and gave each underground pocket its own water level.

---

## 5. Why our caves don't feel real or epic yet

1. **One recipe everywhere:** squashed balls (big caverns about 50 to 70 m wide and 20 m tall) and round tubes. No flat
   ceilings, no slots, no canyons, no fallen-block hills.
2. **Not tall:** each area is 80 m tall, but the biggest cavern uses only about 20 to 28 m of that.
3. **No set pieces:** no shafts, waterfalls, lakes, arches or giant halls. Water today is a few dripping stalactites.
4. **One rock per area:** all of Mossy Hollows is the same grey stone.
5. **You never see the far end** of a big room (only your lantern and crystals light it), so it never feels big.
6. **Too few places (F110):** 3 big caverns and 12 small rooms per area.

---

## 6. The idea: cave kits, wonders and peek cracks

**Cave kit:** everything that makes an area look like itself: its rock shapes, rock colours, big models (dripstone,
columns, boulders), water, light, life and sounds. Each kind of area gets its own kit.

**Wonder:** a big, specially designed room built from a kit, with a landmark you see from the doorway: a waterfall
shaft, a dripstone hall, a mirror lake, a pillar hall. Every big cavern becomes a different wonder. The tunnels between
them change shape too (slots, canyons, wide low passages, keyholes), so walking between wonders feels real as well.

**Peek crack:** a thin crack in a wall that the dwarf can't fit through. Through it you see another cave, lit by
something glowing. You hear water, and air blows through it: dust drifts in, and your lantern flame leans toward it.
Dig the crack open to get in. Behind it: a cave nobody has been in (treasure, a hidden lake, a dwarf vault), or a
shortcut.

**Why the crack has to be a hand-made model:** the world is built from 1 m blocks. A real gap thinner than about 1 m
closes up (that's why the glowing crack in the start room is only light, not a real hole). The dwarf is 72 cm wide, so
a 1 m gap would be wide enough to walk through. So the plan is: the rock gets a real opening between the two caves,
and a hand-made cracked rock slab (Blender, our style) fills it. The slab's gaps are 10 to 30 cm wide, and you really
see through them. Dig the slab and it breaks apart.

**The same rule for everything thin:** the 1 m blocks make the big shapes (halls, shafts, tunnels, lake bowls).
Hand-made models make anything thinner than about 2 m: stalactites, columns, basalt hexagons, carved steps, statues,
crack slabs.

---

## 7. The choices

### Choice 1. How different areas look
- **A ⭐ Wonders everywhere, a sample of each type now.** Every big cavern is a different wonder. Mossy Hollows and the
  Fungal Jungle get one wonder of most types now, so you can see and judge each one. Later, each new area goes all-in on
  one theme. *Why: you see the variety right away, and we learn what works before building whole new areas.*
- **B One look per area only.** Mossy gets only the limestone types (waterfall shaft, dripstone, lakes, arches). Lava,
  basalt and marble wait for their own areas.
- **C Everything mixed at random** everywhere.

### Choice 2. Which theme each future area gets
The world plan has 5 areas with no theme yet. ⭐ My suggestion:

| Area | Theme | Made of |
|---|---|---|
| Mossy Hollows (middle, home) | **Classic limestone caves** | Dripstone halls, waterfall shafts, mirror lakes, arches. Friendly and green. |
| Fungal Jungle (east) | As now, plus a **giant fallen-roof hall** | A mushroom forest under a glowing "sky", like Son Doong's jungle; spore bogs. |
| North | **Blue Marble Grottoes** | Swirled blue-white marble, turquoise lakes, sea-cave arches, flooded passages. |
| West | **Ember Tubes** | Black lava tubes with ledges, basalt-column halls, glowing lava far below. Fits the iron pickaxe border: a forge area. |
| South | **Crystal Deeps** | Giant crystal beams (like Naica in Mexico, up to 12 m long), crystal chandeliers, maybe ice. *(You didn't ask for this one.)* |
| Up | **The Fallen Kingdom** | The old dwarf city: pillar halls, great stairs, bridges, statues, forges, light wells. (Already the idea in the world plan.) |
| Down | **The Abyss** | One enormous shaft, with waterfalls falling into the dark. |

Or tell me your own order.

### Choice 3. The first wonders in Mossy Hollows (pick up to 4)
1. **Waterfall shaft** (picture 1): a round shaft 40 to 60 m tall. A waterfall pours from a glowing hole at the top,
   with mist and a pool, and a ledge path winds down.
2. **Dripstone hall** (picture 2): the tallest room in Mossy, with a forest of stalagmites, columns and curtains, and a
   teal pool with little stepped dams.
3. **Mirror lake** (picture 4): a still lake that doubles the ceiling, glow-worm "stars" overhead, a small island.
4. **Arch cavern** (picture 3): natural stone arches and a round hole in the ceiling with light pouring through onto a
   sandy floor.
5. **Fallen-roof hall:** the biggest room, an arched ceiling over a hill of giant blocks you climb across.
6. **Fallen dwarf hall:** a first taste of the old kingdom (see choice 5).

⭐ **1, 2, 3 and 6.** *Why: they match your pictures 1, 2 and 4 and your dwarf-hall wish, and all fit limestone.*

### Choice 4. How big is "epic"?
- **A** Keep today's sizes, just add wonders.
- **B ⭐ One giant hall per area**, about 120 m long and 50 m tall (most of the area's height). Wonders are 40 to 60 m
  tall. Everything else stays as it is now. We'll check the game stays smooth. *Why: one jaw-drop room per area, without
  rebuilding the world map.*
- **C** Make every area taller (80 m to 120 m). That changes the map, floors and borders. Not now.

### Choice 5. Dwarf halls: when?
- **A ⭐ A taste now, the whole kingdom later.** Each area gets one fallen dwarf hall now (Mossy's Great Hall gets rebuilt
  into it): a long hall with two rows of giant pillars cut from the rock, a wide worn stair, a broken bridge over a
  chasm, two ancestor statues at the gate (our own design), one light shaft that still works, toppled pillars, and
  dripstone growing over the carvings. Later the Up area becomes the whole fallen city.
- **B** Only in the Up area, later.

### Choice 6. Peek cracks
**How they work:**
- **A ⭐ A real see-through crack:** the hand-made slab described above. You see the lit cave behind, hear it, and feel
  the air (dust drifts, your lantern flame leans). Dig it open.
- **B** A glow-only crack like the start room's. Cheaper, but you can't really see in.

**What's behind:** treasure caves (a crystal geode, a hidden lake, a dwarf vault), shortcuts between wonders, or ⭐ both.
**How many:** ⭐ about 8 per area.
*(Later, the same cracks can also fix F108, "I don't know where to dig next", which you put on hold.)*

### Choice 7. Can you go into the water?
Lakes and flooded caves need a rule:
- **A ⭐ Wade at the edges, swim on top in deep water** (slow, no fighting). Diving underwater comes later with a dwarf
  diving helmet you craft: a nice reward that opens the flooded caves.
- **B** Water is only for looking. You can't go in.
- **C** Full swimming and diving right away.

### Choice 8. Who builds what
⭐ **This plan builds** the big water (lakes, waterfalls, streams cut into the rock) and the rock parts of F189 (rock
columns, arches, boulders), because they must match each area's rock. **The cave-life Claude keeps** moss, grass,
mushrooms, roots, root pillars and root curtains, and small water (puddles, mist) from F188 to F190. OK?

---

## 8. Build order (each step playable; you OK each one before the next)

0. **Pictures first:** ChatGPT concept pictures of your picks in our chunky, hand-painted style (one per wonder, the
   dwarf hall, and a crack close-up). You approve them before anything is built.
1. **Caves shaped like real ones** (together with F110): about twice as many caverns and rooms. New passage shapes:
   slots, canyons, wide low passages and keyholes, plus round tubes. Rock layers you can see as bands and ledges on the
   walls. Wet, shiny rock near water. Fallen blocks under high ceilings. We check that the start, every special place
   and every boss can still be reached, and that every tunnel that opens high in a wall has a walkable way down (F141).
2. **The first wonder: the waterfall shaft** (picture 1): the shaft, waterfall, mist, pool, light beam, roar and echo,
   and the path down. You judge the look and feel before we make more.
3. **Dripstone hall and mirror lake:** the hand-made dripstone set (stalactites, stalagmites, columns, curtains,
   stone waterfalls, little dams) in batches of about 4 pieces, with your OK after each; then the lake water with its
   mirror and glow-worm ceiling.
4. **Peek cracks** and the sealed caves behind them.
5. **The fallen dwarf hall:** its kit (pillars, stair, bridge, statues, rubble), in small batches.
6. **The rest of the sample** (depends on choice 1): arch cavern, a marble grotto, a basalt corner, a lava tube.
7. **Later:** each new area in the roadmap gets its full kit.

Step 1 is a big rebuild of the cave maker: when we start it, type **ultrathink**.

---

## 9. Notes for Claude (how to build it)

**Pattern (GodotPrompter `procedural-generation`):** keep today's planned shapes (signed-distance rooms and worm
tunnels joined by a spanning tree, every room reachable) and add **stamps**: each room `kind` gets its own distance
function, plus a kit placed from the seed. Not used: cellular automata (a 2D grid method that makes blobby caves, the
opposite of what we want, and too slow per voxel in GDScript) and wave function collapse (tile rules; too rigid for
natural caves). Checklist items already true: seeded RNG per stream, reachability by tree, spawn checked.

- **Rooms:** add `kind` values: `shaft`, `dripstone_hall`, `lake`, `arch`, `breakdown`, `dwarf_hall`, `giant_hall`,
  `sealed` (peek-crack target). Each has its own `_room_dist` variant in `_sdf_with`:
  - shaft: vertical capsule, with up-and-down flutes (angular noise around the axis) and ledges every 4 to 6 m;
  - halls: flat ceilings snapped to the area's rock layers; breakdown: arched ceiling plus a floor of big cellular
    blocks, with `_floor_guard` keeping one walkable route;
  - canyon/keyhole tunnels: squashed capsules (narrow, tall), keyhole = a tube plus a slot under it;
  - lava tube: terraced radius by height (ledges); marble: cellular "scallop" dimples; dwarf hall: grid-aligned boxes
    with **no** rock detail (a forced-clean zone like the start room), so walls are flat.
- **Layers and cracks:** one gently tilted layer direction per area plus a few big crack planes. Tunnels prefer to run
  along layers (flat ceilings); slot passages follow cracks.
- **Height:** each area is y −64 to 16. The giant hall is up to about 55 m tall. `World.VIEW_DISTANCE` is 128 m and fog
  density 0.012 (the far end of a 120 m hall is about 24% visible): tune fog per wonder in `ambience.gd` and give each
  wonder one bright landmark. Measure FPS with `perfcheck` in the giant hall.
- **Rock materials:** `terrain.gdshader` has 16 slots and uses 11. New rocks (cream limestone and flowstone, marble,
  basalt, dwarf-cut stone, calcite) mean growing the texture array and the shader arrays to 32 (8-bit voxel indices
  allow 256). Rock bands by height in the shader (cheap). A wetness mask near water and drips.
- **Thin things are models** (`docs/art/MODEL-RULES.md` applies: hand-built in Blender, no shimmer, every part
  touching): the dripstone set, basalt columns (instanced 6-sided prisms of varied heights), crack slabs, the dwarf-hall
  kit, boulders. They hide or fall when the rock behind them is dug (`World.changed`), like the clutter does now.
- **Water:** still, flat water meshes (world doc 2.8), a mirror-like water shader (test screen-space reflections against
  a reflection probe for speed). Waterfall = scrolling ribbon mesh + mist particles + a real CC0 roar recording (no
  synth sounds). Swimming as chosen in choice 7.
- **Light:** one landmark light per wonder (shadows off unless needed), volumetric fog energy only on that light, a
  `FogVolume` for mist and light shafts. Cheaper fake beams (soft additive cone meshes) if fog costs too much.
- **Sound:** an `Area3D` with a reverb bus per wonder (Godot `Area3D` has `reverb_bus_*` settings) for the echo.
- **Peek cracks:** at plan time pick pairs (an open room, a sealed room) whose walls are 1.5 to 3 m apart, force an
  air window between them, put a slab model there, and a glow source in the sealed room so the view isn't black.
  Breaking it is `request_break_crack` → host approves → everyone removes the slab and carves (co-op rule). Draught:
  dust particles drift toward the crack; the lantern flame leans within 4 m.
- **Co-op:** everything comes from the seed. Only digging and crack-breaking are requests.
- **Checks:** every wonder reachable without digging (except sealed ones); a walkable way down from every overlook
  (F141); no floating models; model checks pass; FPS in the giant hall; world-making time.
- **Risks:** the generator is GDScript per voxel, so more shape types cost time. Use the lookup grid (already there)
  and measure. Other Claudes may be changing `cave_maker.gd` (F109 digging chunks): pull first, small commits.

---

## Sources (numbers rounded)

- Carlsbad Big Room: [NPS facts](https://www.nps.gov/cave/learn/news/upload/Interesting-Facts.pdf),
  [NPS speleothems](https://www.nps.gov/cave/learn/nature/speleothems.htm)
- Gaping Gill: [Wikipedia](https://en.wikipedia.org/wiki/Gaping_Gill)
- Son Doong: [Live Science](https://www.livescience.com/planet-earth/geology/hang-son-doong-the-worlds-biggest-cave-so-outrageous-in-size-it-fits-2-jungles-and-the-great-wall-of-vietnam)
- Marble Caves colour: [Live Science](https://www.livescience.com/planet-earth/geology/marble-caves-chiles-ethereal-turquoise-caverns-with-mineral-ice-cream-on-the-walls),
  [Explorersweb](https://explorersweb.com/natural-wonders-chiles-marble-caverns/)
- Flooded caves: [Sistema Sac Actun](https://en.wikipedia.org/wiki/Sistema_Sac_Actun), [Cenote](https://en.wikipedia.org/wiki/Cenote)
- Lava tubes: [NPS Hawaiʻi Volcanoes](https://www.nps.gov/havo/learn/nature/lava-tubes.htm),
  [USGS Bulletin 1673](https://npshistory.com/publications/geology/bul/1673/sec3a.htm), [NSS](https://caves.org/lava-tube-birth/)
- Basalt columns: [EGU blog](https://blogs.egu.eu/divisions/ts/2023/05/26/features-from-the-field-columnar-basalts-and-why-hexagons-are-natures-favourite-shape/),
  [Fingal's Cave](https://en.wikipedia.org/wiki/Fingal%27s_Cave)
- Lakes: [Lost Sea](https://en.wikipedia.org/wiki/Lost_Sea), [Waitomo](https://www.waitomo.com/waitomo-glowworm-caves)
- Crystal cave: [Naica](https://en.wikipedia.org/wiki/Cave_of_the_Crystals)
- Finding caves by draught: [Mulu, Clearwater 2023](https://mulucaves.org.uk/?p=2942),
  [Boulder choke](https://en.wikipedia.org/wiki/Boulder_choke), [Cave digging](https://en.wikipedia.org/wiki/Cave_digging)
- Game caves: [Minecraft wiki: Caves](https://minecraft.wiki/w/Caves),
  [Level design roundtable](https://www.gamedeveloper.com/design/level-design-in-a-day-an-expert-roundtable-q-a)
- Godot light shafts: [Volumetric fog docs](https://docs.godotengine.org/en/4.5/tutorials/3d/volumetric_fog.html),
  [Fog volumes](https://godotengine.org/article/fog-volumes-arrive-in-godot-4)
- Rock-cut places (Kailasa, Basilica Cistern, Wieliczka, Derinkuyu, Longyou, Petra, Bamiyan): general knowledge from
  the research helper. Check a number before it goes in public text.
