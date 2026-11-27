## Nov 27 — Mac planning: abilities, quality colours, max level, the waiting perks (Claude)

**What we did.** The owner was on the MacBook while the PC chats worked on armour and dungeons, so we planned
instead of building. Claude listed every system in the game (built / half / missing) and what can be done on the
Mac vs the PC. Then the owner chose items 1-4 and decided them one by one. All choices are in
`docs/design/abilities-quality-perks-plan.md` (the PC's build list); the old texts in `skills.md`,
`progression-and-economy.md` 3.4 and `rare-finds.md` now point there.

**The owner's choices.**
- Abilities on **Q / R / T**, dragged there in the perk window, any time (a swapped-in one starts recharging). Still 3
  keys, still the same 7 abilities. Whirlwind spins, Healing Brew is thrown, Clan Banner is planted. Weapon special
  moves come later. Lantern refill moves from R to hold-L.
- Max level 91 (the whole tree, slowly). Death costs 5% of every skill level, like Valheim.
- Quality colours grey → green → blue → purple → gold, **fixed by Crafting skill** (no luck); gold gets an extra gem
  socket. The owner's own idea for non-crafters: upgrade to +3, then reforge with boss trophies back to +0 one colour
  higher (1, 2, 3, 4 trophies per step).
- Co-op "fallen friend" pick-up: yes. Cooking 75 = a 3rd food slot. Rare finds: geodes only. Running 50, Jumping 50,
  Axe 75, Spear 75 stay waiting.

**Hurdles.**
- `git pull` on the Mac failed twice ("early EOF", the download broke). A plain `git fetch` in the background worked;
  the Mac was 27 commits behind.
- Claude's first question set pointed the owner's answer the wrong way: the owner thought "Whirlwind / Brew / Banner"
  were weapon specials. Asked again with plainer words.
- Claude offered E for an ability key without checking first: E is "use", and L (its idea for the lantern refill) was
  already "put the lantern away". Lesson: grep `controls.gd` before offering keys.
- Claude first wrote its own new text for the Crafting ★100 perk into the plan; it wasn't the owner's choice, so it was
  turned into an open question instead.
- The helper's code map said "no bleeding" and "Thrifty / Quick Fix waiting"; a grep showed wear and repairs were
  already built, so those two perks were taken off the waiting list.

**Left.** Items 5-10 on the Mac list (biome boss hunt, Fungal Jungle, Iron/Steel/epic gems, yes/no on traders /
quests / weather / day-night, Steam launch list, concept pictures). Open: new text for Crafting ★100 and the
per-level "better quality odds".
