# Carry weight (F793) — decisions

Owner, Nov 23 (grill in the carry weight chat). Code: `src/items/item_weights.gd` (all numbers live there).

| Decision | Choice | Why | Revisit when |
|---|---|---|---|
| Slowdown shape | Two steps: free up to "heavy", then a gentle growing slowdown (100% → 75%), then OVERLOADED past the max | You see it coming before you're stuck | play tests say it feels sticky |
| Limits | Heavy at 200, OVERLOADED at 300 (stone = 1) | Rock trips need planning, light loot barely counts | carts / pack animals arrive |
| Worn gear | Counts half | Armor has a cost without crushing hauls | heavy metal armor tiers arrive |
| Overloaded | ~40% walk speed, no sprint, no dodge roll, no jump; red warning | You can still limp home or drop things | — |
| Raising the limit | Leather Satchel +60; Deep Pockets perk +25 per rank (3 ranks = +75); food/drink buffs via the `carry` buff key; better backpacks later (`PACK_BONUS` table) | Owner picked all four | new backpacks are made |
| HUD | Bag window: "Weight 142 / 200"; main screen shows nothing until heavy, then a yellow "Heavy", red "OVERLOADED" next to the stamina bar | Clean screen | — |
| Weights | "Dwarf-heavy" table: rock 1, ore 1.5, bars 2, crystals 0.5, wood 0.5, fiber 0.1, food 0.2, drinks 0.5, ammo 0.1, pages 0, tools 4, weapons 5 (two-handed 8), shields 6, armor 1–8, stations 10, chests 8 | Owner picked the recommended table | numbers feel off in play |
| Pickup when overloaded | Still allowed | Nothing gets lost on the floor | — |
| Stack sizes | By kind, round numbers: rock/ore/wood/fiber 50, bars/crystals 30, food 20, drinks 10, ammo/coins 100; items that already set a stack keep it | Bag fills AND gets heavy; easy sums | — |
| Who owns the numbers | Host owns the inventory (already sent to each player); the weight table is code, same on every PC; each player's own dwarf slows itself | Co-op ready, nothing new to sync | carts (shared loads) |

## Open / deferred
- Deep Pockets: owner said "+50"; the perk has 3 ranks, so it is **+25 per rank** (+75 at full). Easy to change.
- Old saves with stacks over the new size are split into free slots when loaded; if the bag is full the big stack stays (nothing deleted).
- Carts / wheelbarrows: not built yet. They will carry a separate load that doesn't count on the dwarf.
