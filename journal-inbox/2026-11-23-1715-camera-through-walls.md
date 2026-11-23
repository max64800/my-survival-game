## Nov 23 — The camera passes through built walls and ceilings (F807 round 2)

**What we did**
- The owner liked the see-through doorway and asked for "the same on the walls and the ceiling". In a small tower
  room the walls pushed the camera so close that the dwarf looked bigger (owner: "did my dwarf become bigger?").
- `CameraRoom.see_through` now lets the camera pass through every built piece except floors and stairs lower than
  his chest (you'd look up from under the floor). The pieces it passes fade (CameraFade, from round 1). Rock still
  pushes the camera in, as before.
- Logged the owner's notes for the Twin Gate chat: F811 (every staircase needs a free block after it; a triangle
  after round stairs; make it a blueprint rule with a check), F804 said again (diagonal stair railings still float).

**Mistakes and hurdles**
- Several chats were working at once and the owner got lost about who does what. This chat kept to the camera only,
  and left the Twin Gate railings, chest, doors and stairs to the Twin Gate stairs chat.
- The old test said "a wall still stops the camera"; that's now on purpose not true, so the test checks a floor
  below him instead.
