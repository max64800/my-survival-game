# Bag window + equip time (F825, F826) — decisions

Mock-up: `docs/design/mockups/2026-11-23-bag-window.png` (owner then asked: bigger gear slots, no dwarf outline, Q to throw)

| Decision | Choice | Why | Revisit when |
|---|---|---|---|
| Left side of the bag | A separate "Gear" panel: head, chest, legs, feet (left column), lantern, backpack (right column), 80 px slots with the item's name beside each. No dwarf outline for now | Owner F825: "make the gear and icons bigger with no dwarf siluet for now" | more wear slots (rings, cloak), or the outline comes back |
| Weapons, shield, pickaxe | Valheim style: they stay in their hotbar/bag slot; right-click puts one on and marks it "worn" (gold E). One worn per kind. F still draws the worn weapon (+ shield). Picking an unworn one on the hotbar starts putting it on | Owner picked it; "a shield goes on with a right-click" | two-weapon sets wanted |
| Worn mark storage | A `worn = true` key inside the slot's dictionary, so it moves with the item; cleared when the item leaves the dwarf (thrown, stored, dropped) | Survives swaps/sorting without index bookkeeping | — |
| Old weapon/shield/pickaxe equip slots | Kept as hidden indices (so save files and index maths don't shift); anything in them moves to the bag with the worn mark on load (`Inventory.hand_slots_out`) | Old saves keep working | a save-format bump |
| Equip time | Weapons, tools, shield, lantern, backpack 0.5 s; armour (head/chest/legs/feet) 1.5 s; taking off is instant (`EquipTime`) | Owner picked "short + armour slower" | play test says too slow/fast |
| While equipping | You walk at 30% speed, no running; a hit cancels it; hands are empty until done | Owner: "move very very slowly and will be cancelled if u get hit" | — |
| Co-op | The ring runs on the player's own computer (that's where hits land); when it's full the host is asked, checks, and does the change; the new bag goes back to the player | request → host approves → everyone updates; hits are only known on the player's machine | cheating matters (host would then also time it) |
| Q to throw | Q over a bag/hotbar slot throws the whole slot in front of you. The drop keeps the item's own data (wear, upgrades, gems) when picked back up, also through a save. It doesn't fly back into your bag until you've walked away from it once | Owner F825 | throwing half a stack wanted |
| Wide panels | Gear + bag + crafting shrink together when they're wider than the screen | 1600-wide windows cut the crafting panel off | — |

## Open / deferred
- Crafting panel (right) keeps the existing craft list; a full crafting redesign is not part of F825.
