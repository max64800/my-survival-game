# Nov 24: sound library pages + free replacement candidates (Mac chat)

**What we did**
- Made a "Sound Library" page (claude.ai artifact) with all 119 game sounds so the owner could vote Keep / Not sure / Replace. Picks saved in `docs/audio/sound-picks-2026-11-24.md`.
- Researched where game devs get free sounds. Picked **Freesound.org, CC0 filter only** (free for anything, no credit needed, OK in a public repo).
- Downloaded 133 CC0 candidates (preview mp3s) for 27 sound slots and made a second review page ("Dwarf Game Sound Candidates") with an "▶ Old" button per slot for comparison. Candidate files stay outside the repo until the owner picks.

**Hurdles**
- Sonniss GDC bundle (pro quality) blocks automatic downloads (403) and its licence forbids publishing the raw sound files. Our GitHub repo is public, so Sonniss can't go in it. Asked the owner whether to keep Sonniss sounds outside git instead.
- First Freesound search gave thin or silly results for some slots (a chicken scream for "stone place", a cola can for "wood build", cat hisses for beetles). Dropped those by hand and searched again with better words.

**Next**
- Owner votes on the candidates page and pastes picks. Then: download full-quality originals, convert to .ogg, add each to `CREDITS.md` with its Freesound link, wire into `src/sfx.gd`.
