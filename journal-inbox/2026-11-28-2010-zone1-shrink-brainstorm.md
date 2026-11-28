## Nov 28: Zone 1 smaller and easier to find your way (F969 to F974), the talk first

**What we did:** the owner asked to talk before any cave changes. We went through six play-test notes from flying over
the map: the world is too big, many caves are empty, two ruins can share a cave, some rune shrines can never be reached,
there's no way to know where to go, and an idea to make the first dungeon a tutorial. A helper mapped where every kind
of place is put in the world. Then the owner picked, in three rounds of clickable questions:
- zone 1 about 500 m wide (was 800), zone 2 stays as it is;
- one place per cave: all 12 ruins and all 12 dungeons in zone 1, each in its own cave (the 5 dungeons not built yet
  keep their cave with a camp in it for now), about 10 small camps and nests, no empty caves;
- every rune shrine open, none buried;
- Mossgate Hold, the first dungeon, beside the first cave as the tutorial;
- all four ways to find places, in this order: glows on places, signposts at forks, a compass strip, then a better map;
- old saves don't need to keep working.
The plan is in `docs/design/2026-11-28-zone1-shrink-plan.md`. No game code changed yet.

**Mistakes and hurdles:**
- Claude named the wrong "first dungeon" in a question (the Rootwood). The first one is Mossgate Hold (Nov 19).
  Caught by checking the dates in git before building, and asked again.
- Claude first said zone 1 had "about 30 places" (only counting the small rooms), so "fewer caves" sounded like 30-35.
  A proper count (named ruins, dungeons, Great Hall, Deeps, small places) gave about 50. Told the owner, who chose
  fewer small places instead.
- Found a clash: the three newer dungeons were each waiting for the next map recipe numbers (20, 21, 22). The shrink
  needs a new number too. The owner chose to switch all built dungeons on with the shrink (layout 20).
- Found why two ruins share a cave (F971): later ruins only skip the caves of some earlier ruins, and nothing keeps
  ruins apart. Also found the game already has a map screen, so the "map" idea means improving it.
