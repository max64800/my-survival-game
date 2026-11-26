# Sound rounds (owner picks sounds on a review page)

1. `round.py`: searches Freesound (CC0 only, licence checked per card), downloads previews to `cand/rN/<slot>/<id>.mp3`, and writes `candsN.json`. Copy it to a scratch folder with `find.py` and edit SLOTS. It skips ids already in older cands*.json files.
2. Put the JSON into `page_template.html` (replace `const DATA=...;const KEY`, bump the localStorage key `dwarf-sound-cands-vN`, the "Round N" text and the "ROUND N" copy text) and publish it as an artifact with the mp3 files.
3. The owner pastes picks (LOVE / MAYBE / NO + notes). Install LOVEs. For a slot with no LOVE, install its MAYBEs.
4. `install.py`: edit PICKS {slot: [(file, max seconds)]}. It levels the sound, trims silence, caps the length, and writes `assets/sfx/<slot>_<n>.ogg`.
5. Add a CREDITS.md row per sound, record the picks in `docs/audio/`, add a check to `tests/test_sfx.gd`.
Past picks: `docs/audio/sound-candidate-picks-2026-11-26.md`.
