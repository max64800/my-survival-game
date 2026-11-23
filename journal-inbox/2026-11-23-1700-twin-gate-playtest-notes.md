## Nov 23: Twin Gate play test notes logged (F783 and F781 came back, F803-F809 new)

**What happened:** the owner play-tested the Twin Gate fixes. The wall-walk camera is fixed (F784), but both
towers' stairs are still blocked (F783 came back), climbing still jitters per step (F781 came back), you fall through
the stairs going down (F803), and the stone stair railings float (F804). New wishes: the camera near doors jumps and
zooms in and out while standing (F806, big priority), buildings between camera and dwarf turn see-through (F807),
doors close by themselves and double doors open together (F808), and double-door leaves should match (F809).
Also: the dwarf sometimes keeps sprinting without Shift (F805).

**Mistakes and hurdles (Claude's)**
- The new `test_walk_through` check passed while the game was still blocked. A check on paper isn't enough: the next
  try must walk a robot dwarf through the real rebuilt gate.
- Commit mix-up 1: a no-context patch (`git apply --unidiff-zero`) put one dwarf.gd line in the wrong place and pulled
  in another chat's unfinished code. Undone in a fix-up commit. The other chat hit the same trap.
- Commit mix-up 2: another chat had files staged, and a plain `git commit` took them under Claude's message. Undone
  right away with `git reset --soft HEAD~1` (not pushed, their staging kept). Then committed through a separate
  scratch index (`GIT_INDEX_FILE`), which never touches what other chats have staged.
- Lesson: in this shared folder, commit only through a scratch index: build each file's new version from HEAD plus
  your own lines, never with -U0 patches.
- The first full test run printed nothing (the game likely stopped early). The re-run was cut off when the chat
  restarted, so the full suite still has to be run.
