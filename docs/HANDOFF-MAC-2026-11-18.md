# Handoff from the Mac (November 17-18, 2026)

Read this on the PC after `git pull --ff-only`. Everything below is saved in this repo.

## The game has a name, a story and a Steam page
- **Name: Dwarves Never Fall.** The kingdom fell, but the dwarves never fell. Research: `docs/steam/name-research.md`.
- **Story (lore):** `docs/design/lore.md`.
  - Dwarves frozen in stone wake up with no memory in the ruins of their ancestors' kingdom.
  - You find out what happened and break the curse.
  - Heroic tone; the story is told through rune memories.
  - The cause of the curse is still open.
- **Steam:** App ID **5649350** (paid game). The store page is **submitted for review** (Nov 18): Steam takes 3-5 business
  days, then it goes "Coming Soon" and wishlists open.
  - Plan and status: `docs/steam/STEAM-PAGE-PLAN.md`.
  - Texts: `docs/steam/page/texts.md`.
  - Store art (ChatGPT key art, logo, icons, all Steam sizes): `docs/steam/page/art/`.
  - Screenshots: `docs/steam/page/shots-draft-2026-11-18/`.
  - Release date shown: "Q1 2027" (planned date 15 March 2027). Tags lead with Open World Survival Craft.
  - Content survey published, including the AI disclosure.

## For the code Claude
- **Put the App ID 5649350 where GodotSteam needs it** (steam_appid.txt / project settings) and rename the game in
  `project.godot` from "Dwarf Game" to "Dwarves Never Fall".
- **Measure the real system requirements** on the PC (the autopilot FPS report). The Steam page has an *estimate*:
  - Minimum: Windows 10 64-bit, i5-8400 / Ryzen 5 2600, 8 GB, GTX 1060 6 GB / RX 580, DirectX 12, 4 GB.
  - Recommended: i7-9700 / Ryzen 5 3600, 16 GB, RTX 2060 / RX 5700.
- **New photo robot** `-- steamshots ruin=1 seed=42 shots=<folder>` (`src/debug/steamshots.gd`): store screenshots, no HUD.
  - On the Mac `is_ready_to_play()` took ~110-150 s, so the autopilot only photographed the loading screen. Check why.
- **New feedback items:**
  - F261: digging and rock should break like in Conan Exiles. The PC already did a first pass.
  - F293: debuffs when you stand in darkness.
- **The Fallen Outpost** isn't on GitHub yet; the store page has no outpost shot. Push it when ready.
- **Before release:** the store text promises regions, ruins, tiers, runes, dodge/parry, bosses, raids, darkness,
  rune memories and 4-player online co-op. Each must be in the game by launch, or the text must change.
- **Opportunity:** Steam Next Fest, February 2027. Sign-ups are open until **Jan 10, 2027**, and it needs a playable demo.

## Videos (marketing)
- 7 Shorts about building the game: `docs/marketing/video-series-049-055.md` (a copy, because the EQT Social Media repo
  can't reach GitHub right now).
- The owner's rules for these videos:
  - AI is never the hook; the game, the journey and the mistakes are.
  - Survival-game passion (Valheim, Grounded, 7 Days to Die, Conan Exiles).
  - Deep Rise appears sometimes.
- Post only after the Steam page is live. Every video ends with "Wishlist Dwarves Never Fall on Steam".

## Other Mac work this session
- `docs/art/MODEL-RULES.md` (no Play-Doh, no shimmer, clean layers, roofs, round doors).
- The Zone 1 model review: `docs/art/review-2026-11-15/`, with the photo tool in `tools/model_review/`.
