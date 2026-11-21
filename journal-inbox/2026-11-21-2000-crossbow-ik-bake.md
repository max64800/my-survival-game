# Crossbow moves, round 2: built by "arm math" (chat 18, dwarf-animations)

**What we did:** The owner said the crossbow aimed to the left, and in reload the bow sat in his belly and his left hand did not reach it. We stopped copying moves from another skeleton and wrote `tools/asset_forge/crossbow_ik_bake.gd`. It places the bow in front of his chest and moves both arms to the right spots (IK = "the hand goes where you tell it, the elbow follows"). It bakes Aim, Shoot and Reload into `assets/anim/crossbow_kaykit.res`. Aim and Shoot point straight ahead. Reload lowers the bow in front, the left hand goes to the bolt groove, then the string, then it lifts to aim.

**Mistakes and hurdles (including Claude's):**
- First version used the normal human arm lengths. The dwarf's arms are squashed by DwarfProportions (about 26 cm total), so the hand missed by 41 cm. Fix: measure the live arm bones.
- Turning the animation tree off also turns the dwarf squashing off, so my first measurements were wrong. Fix: measure with the tree on.
- Reading the bow position in a headless run gave an old value. Fix: compute it from hand pose x grip.
- The left hand could not reach a fore-end 30 cm out. Fix: hold the bow closer to the chest and move the hand spots near the stock. Worst miss now 4.4 cm (aim) and 10.7 cm (reload).
- The bow tilted 40 degrees up, then my fix (38) overshot to 20 down. 25 gave a level bow.
- The preview tool crashes now and then (exit 3221225477): run one camera per call.
- Old KayKit bake (`crossbow_kaykit_bake.gd`) is now replaced by the IK bake; kept for history.
- c/Reload1H no longer exists; it is still listed in GRIPS but unused.

**Left to do:** owner to play-test; re-record the Dwarf Moves page.
