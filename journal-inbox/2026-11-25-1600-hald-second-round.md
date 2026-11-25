## 2026-11-25: Tomb of Hald, the owner's second play round (all logged)

**What we did.** The owner played the stone Hald and sent 5 screenshots and a long list. Everything went into
FEEDBACK.md so nothing has to be said a third time: F871 (entrance sign too faint), F872 (ghosts walk backwards and
get stuck at doors), F873 (teleport right behind you, never into walls, attack at once), F874 (ghost hit sound is a
bell), F875 (recipe stand only works when you look at its foot). Said again: F844 (difficulty + recipe signs at the
entrance), F849 (boss too easy, 2 minions), F850 (Shield-Brother never turns his back), F851 (no parry star on ghosts).

**Mistakes and hurdles.**
- F856 came back: I only fixed the spike floor round the Embalmers' hoard. The wood the owner saw is a different
  chest: the buried chest under the loose floor stone (`floor_loose_stone.glb`, a board floor made for wooden
  Mossgate). Lesson: when the owner says "the wood under the chest", check every chest in the plan, not one.
  My test only looked for "plank"/"wood" in model names, and this one's name says "stone".
- F857 came back: the stone stash wall left gaps beside it, and the owner wants a hole in its middle to see the chest.
