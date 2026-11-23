class_name DwarfFeel
## THE KNOBS: how the camera and the sprint feel (F469, F766, F775).
## Every number here is a first guess, made to be changed. Change one, save, play: nothing else needs touching.
## m = meters (the dwarf is about 1.35 m tall), s = seconds.

# ---------------------------------------------------------------- camera
## Where the camera looks: this high above his feet. Chest height (F469: "made for humans, not dwarfs"; 1.5 → 1.0 → 0.9).
const CAM_AIM_HEIGHT := 0.9
## How far behind him the camera starts (the mouse wheel still zooms). Was 3.4.
const CAM_DISTANCE := 3.0
## Looking straight down pulls the camera this much farther out (1.15 = 15% farther) ...
const CAM_LOOK_DOWN_STRETCH := 1.15
## ... and looking straight up brings it this much closer (0.75 = 25% closer), so the ceiling doesn't fill the screen.
const CAM_LOOK_UP_SQUEEZE := 0.75
## Rock in the way: the camera jumps in at once (never inside rock), then glides back out this fast (bigger = faster).
const CAM_RETURN_SPEED := 4.0
## Rock between the camera and the dwarf fades to a see-through speckle inside a tube this thick (m). 0 = off.
const CAM_FADE_RADIUS := 0.45
## A built piece between the camera and the dwarf gets a see-through circle round him (F807). How strong (0 = off, 1 = full) ...
const CAM_BUILD_FADE := 1.0
## ... and it fades in and out this fast (1 = the whole way in one second).
const CAM_BUILD_FADE_SPEED := 4.0
## The circle: how clear right round him (1 = all gone) ...
const CAM_CIRCLE_MIDDLE := 0.95
## ... how clear out at the screen's corners (0 = solid) ...
const CAM_CIRCLE_CORNERS := 0.3
## ... and how far out it goes before reaching the corner look (in screen heights: 0.5 = half the screen's height).
const CAM_CIRCLE_SIZE := 0.75
## A piece this close (m) to the line from the camera to him counts as "in the way"; then every piece on screen
## nearer than him gets the circle.
const CAM_CIRCLE_TUBE := 0.5

# ---------------------------------------------------------------- sprint (hold Shift)
## Seconds to go from walking to full sprint speed (F775: "about 0.3-0.6 s"). Heavy legs need a moment.
const SPRINT_RAMP_TIME := 0.45
## Seconds to slow from sprint back to walking speed when you let go of Shift.
const SPRINT_SLOW_TIME := 0.3
## How fast you can turn while sprinting, in turns per second (walking turns instantly). Lower = wider curves.
const SPRINT_TURN_SPEED := 0.6
## Let go of every key while sprinting: he skids to a stop. Bigger = shorter skid. (12 ≈ a skid of about 1 m.)
const SPRINT_STOP_GRIP := 12.0
## The view widens this many degrees at full sprint (the normal view is 72). Small, so tunnels don't look stretched.
const SPRINT_WIDER_VIEW := 4.0
## Sprinting stops while you still have enough energy left for this many dodges, so a dodge is always there.
const SPRINT_KEEPS_DODGES := 1.0
## After sprinting stopped to save that dodge: get this much extra energy back before you can sprint again
## (without it, Shift would sprint-stop-sprint every other moment).
const SPRINT_CATCH_BREATH := 10.0
## Dust thrown up behind his heels at each sprinting step (the kind changes with the floor: see Fx.RUN_KICK).
## How many puffs per step, and how big each puff is (m).
const SPRINT_DUST_AMOUNT := 6
const SPRINT_DUST_SIZE := 0.4
## Sprint this far up to speed (0..1) before the dust starts.
const SPRINT_DUST_FROM := 0.6
## Walking: a faint puff at each step (owner, Nov 22). Puffs, size (m), and how solid it starts (0 = invisible, 0.5 = sprint).
const WALK_DUST_AMOUNT := 2
const WALK_DUST_SIZE := 0.28
const WALK_DUST_SEE := 0.2
