## Nov 23, 23:00 (PC): stamina numbers, a full belly, Gutweed Tea, right-click to eat (F823, F824, F827)

**What we did**
- **F823:** the stamina bar now shows its number ("110 / 110") in the middle, like the health bar.
- **F824:** when your food slots (or your drink slot) are full, the game says "You're full" and you keep the food.
  Before, a new meal pushed out the oldest one. Eating the same dish again still works (it just restarts its timer).
  The host keeps its own list of what each player ate (`PlayerState.meals`), so this works in co-op too.
  Dying clears the list.
- New drink **Gutweed Tea** (campfire: 2 moss + 1 water bucket, unlocked once you've held moss): it empties every
  food and drink slot. It's the "laxative" the owner asked for. Its picture is the Glowcap Tea picture tinted green
  for now (a stand-in).
- **F827:** right-click a food or drink in the open bag and you eat it. The host does the eating (`ask_eat` →
  `request_eat`). The old hotbar eating code moved into one shared helper `_eat()`, so both ways follow the same rules.
- F825 (new bag layout) and F826 (Valheim-style equip time) are still open: they're big, so they need their own chat.

**Mistakes and hurdles**
- My Python helper moved the eating code into a new function but left it 2 tabs deep instead of 1. I caught it
  by reading it back and fixed it with one `sed`.
- An old test (`test_food_speeds_up_healing_to_the_cap`) ate 3 foods in a row and expected the 3rd to push one out.
  With the new rule the 3rd is refused, so the test now empties the slots first.
- The tests first failed to start (`FileNotFoundError`): the `GODOT` path wasn't set in that shell. Exporting it fixed it.
- 2 crafting tests fail because the carry-weight chat changed the stack sizes (stone 100 → 50). That isn't from this
  work, so I told that chat instead of changing its code.
