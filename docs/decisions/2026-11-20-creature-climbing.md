# Creature climbing (walls and ceilings) — decisions

Feedback: F236 🔁 (said 3×: beetles and snails can't get out of holes), F474 (spiders climb walls), F475 (snails on
walls and ceilings, sometimes up high so you farm them by looking up). Owner's answers, Nov 20 (enemies chat 2).

| Decision | Choice | Why | Revisit when |
|---|---|---|---|
| Who climbs where | Cave Spider and Rock Snail: walls **and** ceilings. Rock Beetle: walls only (out of holes, up ledges), never ceilings. Great Rock Beetle (boss): never climbs. Bats fly (unchanged). | Fits how each animal would really move; the boss stays a floor fight | a new creature is added (give it its own rule) |
| Snail on the ceiling, how to farm it | Any hit (crossbow bolt, thrown rock, long reach) knocks it off: it falls, lands on its shell, dazed with stars for a few seconds | Rewards looking up; uses the daze stars every creature already has | the owner finds it too easy |
| Spider and walls in a fight | Ambush: some spiders wait on the ceiling and drop on you when you walk under, with a short hiss first so you can look up and dodge; chasing, they run along walls to reach you | Makes spiders scary and the caves feel alive | it feels unfair (raise the hiss time) |
| How often up high | About 1 in 4 snails and spiders are on a wall or ceiling when you find them | Enough to make you look up, the floor never feels empty | play tests say more or fewer |
| Authority (from the project rules) | Host moves every creature and decides when it falls; everyone else sees position + which surface it is on | Co-op ready rule: request → host approves → everyone updates | never |
| Rock Beetle climbing, when (Claude) | Only when it needs to: in a hole, or blocked by a ledge while chasing/returning; not for fun | Owner asked for "climb out of holes", not wall-walking beetles | owner asks for more |

## Open / deferred
- How it moves on a surface (the technique: stick-to-surface with rays, the body turned to the surface) is Claude's
  choice in the build chat; report the pattern picked and the one rejected before building.
- Placement rule: creatures up high must not sit inside built things or on paths (CLAUDE.md placement rule) — needs a test.
- Dungeon creatures keep the stay-in-your-room rule on walls too.
