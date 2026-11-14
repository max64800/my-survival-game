# Armor: proposal

*Written: November 14, 2026, by Claude 3. A **proposal**: nothing here is in the game rules yet.
The owner decides; each choice has a default (★). Answer with the code, e.g. "A3 B".*

Fills gap #1 in `docs/design/README.md` ("Armor and weapon recipes"). Uses the armor rule that's
already in the combat doc (section 2.2): `damage × 100 / (100 + armor)`. 100 armor = half damage.

**What's already built:** the *look*. A dwarf wearing armor pieces shows them (helmets, chest plates
with shoulder guards, boots), in every material below. Turning the rules on is a small job once
you've answered the questions.

## 1. Three armor pieces

| Piece | Slot | Share of the armor |
|---|---|---|
| Helmet | head | 25% |
| Chest (with shoulder guards) | body | 50% |
| Boots (with shin guards) | feet | 25% |

They go in the equipment slots Claude 1 is building (feedback F23). Until then: armor in the hotbar
counts as worn (like the Spore Mask today).

## 2. Five materials, one per stage of the game

| Set | When | Full set armor | Damage taken | Made from (per full set) | Station |
|---|---|---|---|---|---|
| **Hide** | First hours | **12** | 89% | Leather 8, fiber 6 | Workbench |
| **Copper** | After the first Smelter | **30** | 77% | Copper ingot 10, leather 4 | Anvil |
| **Husk** (jungle) | Fungal Jungle | **45** | 69% | Husk plate 6, silver ingot 3, leather 3 | Anvil |
| **Silver** | After the jungle boss | **55** | 65% | Silver ingot 12, leather 4 | Anvil |
| **Ironshell** (boss set) | Old Ironshell drop | **70** | 59% | Ironshell plate 3, silver ingot 6 | Anvil |

(Iron and Steel sets come with their biomes, about 85 and 100.)

Rough check: a Rustwight hit of 15 does **13** in Hide, **12** in Copper, **9** in Ironshell. You feel
each upgrade, and armor never makes you safe on its own (the "never zero" rule).

## 3. Questions for the owner

- **A1. Pieces:** (A) ★ helmet + chest + boots, (B) add gloves (4 pieces), (C) one "armor" item (simplest).
- **A2. Heavy armor:** (A) ★ no downside, (B) metal pieces make dodge rolls cost a little more stamina (+5% each), (C) metal is slower to swim/climb in (later).
- **A3. Set bonus** for wearing all 3 of one material: (A) ★ none, keep it simple, (B) small bonus per set (Hide: +10% stamina, Copper: +5 armor, Husk: poison resist 25%, Silver: +10% light from your lantern, Ironshell: knock-downs last half as long).
- **A4. Wear and repair:** (A) ★ never wears out (same as tools, progression doc question 12), (B) slowly wears out, repair at the Anvil.
- **A5. Gems in armor** (combat doc gems): (A) ★ not yet, (B) one gem slot in the chest piece.
- **A6. Friends' armor:** (A) ★ everyone sees what you wear (already works in co-op), (B) a "hide helmet" option for people who like the bare look.

## 4. How it looks (already built)

- **Helmet:** replaces the starting iron cap. Hide = a leather cap with ear flaps; Copper = a rounded
  cap with a nose guard; Husk = a ridged shell helmet; Silver = cheek guards; Ironshell = a heavy
  dome with a face plate. (No horns: we don't copy the cliché.)
- **Chest:** a breastplate over the tunic and two shoulder guards, the beard falls over it.
- **Boots:** shin guards and heavy toe caps over the boots.
- Code: `DwarfRig._wear_armor()` in `src/player/dwarf_rig.gd`. Item ids it understands:
  `armor_<head|chest|feet>_<hide|copper|husk|silver|ironshell>`.
