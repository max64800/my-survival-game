## Nov 25: Ghosts can't be pushed, a missed jump is made later, Hald walks round tombs (F901, F902, F873 4th time)

**What the owner said:** "Make sure I cannot knock away ghosts ... if I shoot them from far away, a lot of them stop
teleporting ... I hit them twice, they teleport, and my third combo just knocks them away when they're behind me.
For the boss, if I'm standing behind a tomb, he is trying to hit me through the tomb. He just needs to go around it."

**What we did**
- **No push (F901):** `Monster.knock()` now does nothing for a ghost. Every push in the game (hits, the finisher, the
  shield bash, the spear, traps) goes through that one spot, so one line covers all of them.
- **Owed jump (F873, 4th time):** a ghost jumps behind you after each quarter of its health. The spot behind you has
  to be open floor. If you stood in a narrow doorway or corridor (where you often shoot from), there was no open spot
  and that quarter's jump was simply lost. Now the ghost remembers it "owes" a jump and looks again 3 times a second
  while it chases you, until a spot opens up. It also tries two more spots, a little ahead of beside you.
- **Round the tomb (F902):** a ghost now looks 1.6 m ahead. If a tomb or pillar is in the way, it turns left or right
  (and sticks to that side, so it doesn't wobble in front of the tomb) until the way is open. It also won't start a
  swing if stone stands between it and you.
- Three new tests: no blow pushes a ghost; a jump it couldn't make is made later; it steps round a tomb and won't
  swing through it.

**Mistakes and hurdles**
- My first edit script stopped halfway: one piece of text it looked for had different tabs than I thought. The first
  two files were changed and the third wasn't. I checked which parts had landed before trying again.
- I wrote `for h in [0.7, 1.2]` without saying `h` is a number. Godot refused to load the whole ghost file, and for a
  minute that broke every test (other chats' too). Fixed by writing `for h: float in ...`. Lesson again: check that a
  file loads right after every edit.

## Same session: every creature's own death sound (F903) and real death traps in the Tomb of Hald (F904)

**What the owner said:** "Fix the enemy dying, it doesn't match anyone" (I asked: it was the sound) and "add a few
spikes and fake floor please, we don't have a full death trap anywhere" (they picked the Tomb of Hald, instant death).

**What we did**
- **Death sounds:** only bats and snails had their own (F881); everything else died with one dull thump. A new script
  (`tools/art/make_death_sounds.py`) mixes sounds already in the game (all from CC0 recordings) into four new ones:
  a beetle's shell cracking and a hiss running out, a spider's short hiss and curling legs, a skeleton falling into
  a heap of bones, and a ghost's slow breath sinking away. Ghosts and skeletons get theirs automatically (by the
  "ghost" and "rises" marks in the creature list), so new ones won't fall back to the thump. A test checks that no
  creature still uses it.
- **Death traps:** the tomb's plan had "the collapsing steps come next" and "the cracked slabs: next" written in it,
  but they were never made, so nothing there could kill you. Now four loose stone slabs give way the moment you stand on
  them: one over a new spike pit in the Hall of Candles, one over a new pit in the Hall of Names, and two cracked slabs
  on the Bridge of Oaths over the chasm (on opposite sides, so there's always a safe way across). They reuse Mossgate's
  breaking floor, but in stone with a stone crack sound (Hald is a stone tomb, F856).

**Mistakes and hurdles**
- The first rebuild of the tomb moved half the junk and ceiling holes, because the new traps used up the same dice as
  the rest of the tomb. I gave the traps their own dice, so everything else stays where it was.
- My new ghost tests passed alone but failed in the full run with "material is null". Cause: when a test cleaned up,
  the ghost's see-through paint was freed along with its body, and the dummy renderer's error showed up in the
  *next* test. The game already removes that paint first; now the test cleanup does too.
- Twice more I forgot to tell Godot a variable's type (`fakes := ...filter()`), and the test file didn't load. Fixed
  with `: Array`.
