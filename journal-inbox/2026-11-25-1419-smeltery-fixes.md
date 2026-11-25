## Nov 25: Smeltery play-test fixes (F866, F867, F864; F725 and F865 handed back)

**What we did**
- **F866, the Smeltery's back against the rock.** It used to pick its spot from a grid only, and on seed 42 just 12 of the
  48 test points behind its back were rock. Now it also tries spots slid back toward the cave wall (up to 44 m, in
  2 m steps, stopping when rock blocks the way), and missing rock behind it costs twice as much. Seed 42 now has 40 of 48,
  seed 7 has 48, seed 1234 has 43. A new test check wants at least 36.
- **F867, the lonely tower.** The owner meant the right-hand 6-sided watch turret, not the round chimney tower on the left
  (Claude asked). It moved 2.4 m so one whole side sits on the vaults' right wall. It got a door from the terrace into its
  upper room, and the balcony railings that were in the way went. Ruin plan remade: 1029 pieces, 0 rule problems. Ladder robot 5 of 5.
- **F864, junk gone after a rebuild.** Since F596 a rebuild cleared all of a ruin's junk. The owner chose "keep whole things":
  now only broken mess goes (rubble, bones, rags, dropped gear, smashed/tipped/fallen things, table litter). Crates, kegs,
  sacks, carts, benches and racks stay, unless the rebuilt building would stand on them (each piece's box is checked).
  Same rule for the searchable ones. The spilt bolt crate still goes (F581).

**Mistakes and hurdles**
- The Smeltery's own 4 props (ingot cart, coal scuttle...) never actually vanished: debug prints showed them still there.
  They sit inside the vaults, which the rebuild closes in, so the rooms are dark. It took two debug pictures to see that.
- The first picture run failed with "Can't save PNG": the shots folder must exist before the game starts.
- The blueprint dump script prints "Music not declared" errors (autoloads don't load in -s mode) but still writes the
  file. Claude checked the dump for the new door before trusting it.
- The tower rebuild test failed twice with a slow step (160 ms) and a texture error, then passed twice. Seven Godot copies
  from other chats were running at once, so it was machine load, not the change.
- The tower test's old check "no junk drawn" passed for the wrong reason: the test world never made a junk list (0 of 0).
- **F725 not fixed.** The game does load the new brick triangle models, and their icons match the square floor, so it is not an
  old model. The buildcheck robot ignored `family=clay_brick` and the dwarf blocked the picture. Handed back with notes.
- **F865 skipped.** Someone's roof-tile work (hbtile) has sat uncommitted in the hearthbrick scripts since Nov 20.
