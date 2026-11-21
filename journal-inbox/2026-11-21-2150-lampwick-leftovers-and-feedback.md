## Nov 21 (evening): Lampwick's leftover decor, and 32 notes from the tower-rebuild play (Claude 2)

**What we did**
- Lampwick Drift got its leftover catalogue pieces: the skeleton with his note and his last meal, the overturned
  table (all in the Miners' Rest, since the Copper Face is full), a second skull spike by the Bat Gallery's door and
  the smashed barrel in the Foreman's Office. The floor cage and a second burnt lantern post fit nowhere, so they stay out.
- Mossprop decor waits: Claude 1 still had unsaved Mossprop changes (edited 18 minutes earlier), so we didn't touch it.
- The owner's tower-rebuild play gave 32 notes, written down as F550-F581 (5 of them came back again: crafting one at a
  time, the tower's price, the rebuild menu, the glowing vines, creatures not reacting from another room). Split between
  Claude 2 (building, crafting, resources, world) and Claude 3 (fights, creatures, HUD, animation, hurt sound).

**Mistakes and hurdles**
- The long search for free decor spots was cut off when the chat restarted; run it again in the background.
- The skull spike took three nudges: the Python check and the game's test disagree by a few centimetres (the game wants
  10 cm from every wall, Python only checks it touches nothing).
- The helper sent to read the play log looked at the wrong file: the game starts a new log at every run, and other
  Claudes' test runs push the player's log aside within minutes. The real one was the 2.9 MB file renamed at 21:28.
  Lesson: look for the biggest log with "LOW FPS" lines, not for "godot.log".
- What the log showed: at the tower the graphics card took ~60 ms a frame (16 FPS) and some frames took up to 1.8 s;
  at 21:22 something's position became "not a number" and printed 8,000 warnings in 20 seconds (likely the bat that
  teleported).
