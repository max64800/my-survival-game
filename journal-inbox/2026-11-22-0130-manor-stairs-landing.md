## Nov 22: the manor test house's stairs get a proper landing (F615)

**What we did.** On the Hearth Manor pieces page, the little test house has outside stairs up to its balcony.
The owner tried to walk them in their head and saw the problem: the stairs are 2 m wide, but the balcony
was only 1 m deep, so half of the stairs' top step led into thin air. They drew where the floor should go.

The fix: in front of the upper door, the 1 m half floor became a full 2 m floor (a landing). It has a railing
along its front, a short 1 m railing on its side where it steps back to the 1 m balcony, and a brick pillar
under its outer corner so it doesn't float. Now the whole width of the stairs lands on floor, and you can step
off and walk to the door. The page is republished.

So the real manor doesn't repeat this, the grand-ruin checklist (`docs/design/GRAND-RUIN-RECIPE.md`) got a new
line: stairs up to a balcony must land on floor as wide as the stairs.

**Hurdles.**
- The first republish was refused because the page's scene file had not been read in this chat (after a chat
  summary). Reading it first showed it was our own older version, then the publish went through.
- Another chat had added F616 to `FEEDBACK.md` without saving it yet. To commit only our change (F615 moved out),
  Claude staged a copy of the saved file with just the F615 line removed, leaving the other chat's line alone.
