# Menu overhaul (F187, owner Nov 16)

Owner: "we need an entire overhaul to make them really good, easy to understand." Biggest pains: **messy layout**
and **too many clicks**.

## Decisions (owner's answers)
- **Look: "dwarf workshop".** Dark oak frames with iron corner brackets, dark stone-brown insides, warm amber/gold
  text, gold buttons, chunky hand-painted. The owner OK'd the 4 mock-ups: build the menus to look like them.
- **All menus, one at a time, in this order:** 1. bag + crafting + upgrades (+ chests), 2. start + Escape/pause +
  settings, 3. build menu + blueprint book, 4. map + skills.
- **Fewer clicks (bag):** Shift+Click = quick move (bag ↔ chest, bag ↔ hotbar); Right-click = take half a stack
  (split), so quick-equip moves to double-click; recipes as picture **cards**: click a card, the picked recipe
  shows big at the bottom with have/need ingredients (missing in red), ×1 ×5 All and one big **Craft** button.
  (Drag and drop was NOT picked.)
- No long explanation text anywhere (F179). One short hint bar at the bottom of the bag screen.

## Pictures (in `assets/concepts/ui/`, made in the owner's ChatGPT chat "Create game UI mockup")
- `menu_bag_crafting_v1.png`: Upgrade gear (left) · Bag with equipment column and the hotbar row (middle) ·
  Crafting with icon tabs, recipe cards and the big selected-recipe box (right). One row, centred, same height.
- `menu_start_pause_v1.png`: worlds list as cards (Play + trash), big New World / Join Friend, small Settings / Quit;
  Paused panel (Resume, Settings, Invite Friends, Save & Quit to Menu, Quit Game) + Settings panel with sliders.
- `menu_build_blueprint_v1.png`: build bar along the bottom (category tabs with icons, piece cards with cost,
  material switcher, key hint row); blueprint book (list left page, big picture + materials + Place right page).
- `menu_map_skills_v1.png`: parchment map with legend, floor switcher, zoom; three skill-tree columns with round
  perk nodes, perk points at top, hover card with Learn.
- `ui_kit_sheet_v1.png`: the pieces to cut out (magenta background): panel frame, panel with title plaque, slot,
  slot selected, gold button (normal/hover/pressed), dark button, tab + tab selected, divider, slider track + knob,
  recipe card, tooltip box.

## How to build it
1. **Cut the kit** (`tools/ui_kit/cut_ui_kit.py`): magenta → see-through, crop each piece into
   `assets/ui/kit/*.png`. Then **one** shared script `src/ui/ui_kit.gd` that hands out `StyleBoxTexture`s
   (9-slice: set the texture margins so corners/brackets never stretch) plus fonts/colours, so every menu uses the
   same pieces. Change the old flat `StyleBoxFlat` look in each panel to these.
2. **Bag + crafting + upgrades** first (hud.gd bag part, craft_panel.gd, box_panel.gd). Keep `_layout_panels`
   (one row, centred) and the co-op requests (`ask_swap`, `ask_transfer`, `ask_craft`, `ask_upgrade`). New host
   requests needed: split a stack (`request_split`), quick move to hotbar.
3. Then start/pause, build/blueprint, map/skills, each with an OK from the owner before the next.
4. Tests: kit loads, each piece has the 9-slice margins, shift-click/split requests, card select → Craft.
5. Credits: the kit and mock-ups are our own ChatGPT pictures (log in CREDITS.md like the icons).
