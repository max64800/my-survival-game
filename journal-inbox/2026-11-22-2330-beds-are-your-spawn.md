## Nov 22 (night, PC): your bed is your wake-up spot, one per person (F727)

**What we did**
- Every bed now remembers who it belongs to. A Bed station and the bed furniture (Rootwood Bed, Low Bed, Hammock, Bunk Bed) all count.
- Placing a bed makes it yours and your wake-up spot straight away. One per person: a new bed moves your spot there,
  and your old bed turns into a plain bed. A plain bed still works for resting, and pressing E on it makes it yours again.
- Looking at a bed says "Your bed", "Friend 1's bed" (or "Host's bed"), or "Bed · E to make it your bed".
  You can't take a friend's bed: E just says whose it is.
- If your bed is taken down, smashed or falls with a collapsing building, you get a message and wake up at the world start again.
- The owners are saved with the world, and friends who join get the list too.
- Co-op ready: E asks the host, the host decides, and one message tells every computer who owns the bed.
- New test file: `tests/test_beds.gd` (4 tests).

**Hurdles and mistakes**
- Players don't have a fixed name in the game yet: they are "Host" or "Friend 1-3" (a player number given when they join).
  So beds belong to that number. A friend who joins as Friend 1 next time gets Friend 1's bed, the same way they already
  get Friend 1's bag. Fine for now; when Steam names come in, beds should switch to those.
- Found a small old gap: a friend who left and came back got their bag back but lost their bed spot. Fixed it at the same time.
- Claude's own slip: the first test run printed "4 checks" and Claude worried the tests had crashed early. The number
  counts tests, not checks; the verbose run showed all 4 tests passing.
