# Dungeon pages (Zone 1, F237)
The three pages (small / medium / big dungeons) hold the room maps in their `D` arrays. They are also published as
pages for the owner. After changing a map:
- `node tools/dungeon_pages/gen_docs.js .` rewrites `docs/design/zone1-dungeons/02-12*.md` (01 and 00 are hand-written).
- `node tools/dungeon_pages/check.js .` checks every dungeon against the owner's rules (sizes, deadly traps, clue and
  safe way for every trap, hidden things, key/lock/mini boss, way out, all rooms reachable, no water).
