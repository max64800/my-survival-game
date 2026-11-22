# Hurt and Low-Health Feedback in Notable Games (Other Notable Set)

Status: partial. About 15 tool calls. Search quality was poor (most generic queries returned Minecraft/Valheim mod pages), and several wiki pages returned HTTP 402 (Left 4 Dead wiki page, Gears wiki page), so some items come only from search snippets. Items marked [M] are from memory and are NOT verified in this session. Items marked [Snippet] come from a search summary, not a full page read.

Legend for each game: screen effect on hit, HUD, camera, character, sound, rumble, low-health threshold, settings to reduce.

## Key Question 1: How big and how subtle is each game's hurt and low-health effect?

### Takeaway
Only a few of the requested games could be verified. The clearest verified pattern is that low-health red or grey screen effects are a common, optional-feeling layer. Several big games (The Last of Us Part II, God of War 2018) expose a separate "Full Screen Effects" or Immersion-style toggle, which suggests the screen effect is treated as optional by the studios themselves. Most other entries are memory-only and need checking.

### Cited Findings

#### The Last of Us Part II (Naughty Dog) [Verified, full page read]
- Screen effects toggle: "Full Screen Effects" — "Enables screen effects that indicate player status." Source: [Naughty Dog, TLOU2 Accessibility Features Detailed](https://www.naughtydog.com/blog/THE_LAST_OF_US_PART_II_ACCESSIBILITY_FEATURES_DETAILED)
- Directional hit marker: "Damage Indicators" — "Enables HUD spikes in the direction damage was taken." Same source.
- HUD flash toggle: "HUD Flashing" — "Enables flashing HUD animations." Same source.
- Camera shake: "Camera Shake" — slider 1 to 10. Same source.
- Audio: "Combat Audio Cues" (incoming melee attacks, arrow impaling), with a separate 0-100 volume slider. The page lists NO option for low-health audio cues. Same source.
- Vibration: "Combat Vibration Cues" (incoming melee attacks, aiming at enemy, landing shots). Same source.
- Low-health threshold, heartbeat sound, and exact screen look: NOT found in the page read. Gap.
- Note: the search summary also mentioned a "Difficulty" tuning lever for incoming damage (regional PlayStation accessibility page, [Snippet](https://www.playstation.com/en-us/games/the-last-of-us-part-ii/accessibility/)).

#### God of War (2018) [Partly verified]
- Low-health look: "a glowing red vignette" when low on health. Source: [GameSpot, God of War PS4 Immersive Mode](https://www.gamespot.com/articles/god-of-war-ps4s-immersive-mode-is-the-best-way-to-/1100-6458376/) (one article; not a Santa Monica source).
- HUD control: Players can toggle Compass, Enemy Health Bars, Boss Health Bars, Enemy Off-Screen Indicators, Combat HUD, and Gameplay Notifications. "Immersion Mode" strips almost all HUD. Source: [GameSpot](https://www.gamespot.com/articles/god-of-war-ps4s-immersive-mode-is-the-best-way-to-/1100-6458376/); [WCCFtech, GoW difficulty and HUD-free Immersion Mode](https://wccftech.com/god-of-war-difficulty-settings-hud/amp/) [Snippet].
- Ragnarok carried forward the dynamic HUD where most HUD is hidden during normal play. Source: [GameRant](https://gamerant.com/god-of-war-ragnarok-dynamic-hud-disappear-immersion-combat-hogwarts-legacy-design/) [Snippet].
- Not verified: vignette size, pulse, threshold, heartbeat, flinch, rumble. Gap.

#### Diablo IV (Blizzard) [Beta-era only, Snippet]
- Beta report: a screen-wide effect at low health, and a heartbeat sound with no option to turn off either, in the beta. The Escapist hoped for an accessibility option by launch. Source: [The Escapist](https://escapistmagazine.com/?p=139219) [Snippet; the search summary gave only the beta-era claim; the URL is the one returned].
- Launch status: NOT confirmed. Gap. Check Blizzard patch notes.
- Related but different: Blizzard has an accessibility option to turn off enemy glow (not the hurt effect). Source: [PC Gamer](https://www.pcgamer.com/you-can-turn-off-enemy-glow-in-diablo-4) [Snippet].

#### Left 4 Dead 2 (Valve) [Snippet from fan wiki]
- Black-and-white effect: triggered by "final incapacitation" (going down twice without a heal). Effect: grayscale view, audible heartbeat, brighter red outlines on item glows. Source: [Left 4 Dead fandom wiki, File:Black_and_white_vision.jpg](https://left4dead.fandom.com/wiki/File:Black_and_white_vision.jpg) [Snippet; the article page itself returned HTTP 402; this is community-sourced, not Valve documentation].
- Community mods change the effect (red-tint, removal of adrenaline redness). Source: [Steam Workshop, Left 4 Dead 2 comments](https://steamcommunity.com/sharedfiles/filedetails/comments/3409138833) [Snippet]. Not an official option.
- Normal low-health effect (below the grayscale state): NOT verified. Gap.

#### Gears of War series (Crimson Omen) [Snippet, partial]
- Original games: Crimson Omen is a center-screen cog that grows and becomes more defined as damage builds; full cog means "down but not out." Source: [Gears of War Wiki, Crimson Omen](https://gearsofwar.fandom.com/wiki/Crimson_Omen) [Snippet; page returned HTTP 402; summary from search].
- Gears 5: one source says the Omen became an "Inverse" version that reddens on the outside of the screen instead of the center. Source: [allthings.how, E-Day downed mechanics](https://allthings.how/gears-of-war-e-day-how-being-downed-revives-and-executions-work/) [Snippet; sources disagree on exact version details].
- E-Day: a red cog-shaped Omen fills the middle of the screen when Marcus is downed. Same source [Snippet].
- Not verified: opacity, pulse, sound. Gap.

#### Deep Rock Galactic (Ghost Ship) [No verified data]
- The DRG wiki Damage page does NOT document any on-screen damage or low-health display. Source: [DRG wiki, Damage](https://deeprockgalactic.wiki.gg/wiki/Damage) [Fetched].
- Wiki says player afflictions can show as an icon and sometimes a HUD overlay at bottom centre. Source: [DRG wiki HUD](https://deeprockgalactic.wiki.gg/wiki/HUD) [Snippet].
- [M] DRG is known for a red-ish damage vignette and a health bar on the HUD. Not verified.

#### Hades / Hades II (Supergiant) [No verified data for the hurt screen]
- Screen shake can be turned off under Options > Accessibility in Hades II. Source: search summary attributed this to a Kotaku guide, but the only Kotaku URL returned was [a god-mode article](https://kotaku.com/hades-2-early-access-god-mode-autofire-timer-1851461987), which may not be the source. A [Game8 guide](https://game8.co/games/Hades-2/archives/453553) also lists Screen Shake as a setting to turn off. Attribution uncertain; treat as [Snippet].
- Original Hades: "No screen shake effect or it is included but it can be disabled." Source: [Family Gaming Database, Hades accessibility](https://www.familygamingdatabase.com/accessibility/Hades) [Snippet].
- No low-health screen effect, flash setting, or heartbeat found in any source. Gap. Hades is known for hit flash on the character and camera shake [M].
- The [caniplaythat.com](https://caniplaythat.com) search returned nothing for Hades. Gap.

#### Not searched (memory only) [M]
- Call of Duty (modern): screen goes red and grey at low health, then regen; "blood jam" wording comes from the owner's brief; unsure of exact settings. Needs verification.
- Halo: shields recharge; damage shows as blue shield overlay and edge flash [M]. Not verified.
- Dead Space: spine health meter (diegetic, on Isaac's suit) [M]. Strong known example; verify with a source.
- Fortnite / Apex Legends: directional damage indicator [M]. Verify.
- Vermintide 2 / Darktide, Chivalry 2 / Mordhau, Kingdom Come: Deliverance, Lethal Company: not searched. Memory is too weak to state effects; mark all as gaps.
- Hades II low-health state: not checked.

### Inferences
- Several big studios (Naughty Dog, Sony's GoW HUD) already offer separate toggles for the full-screen effect, the HUD, and the flashing. The owner's "too much" reaction matches that these toggles exist.
- Naughty Dog's list shows the split pattern to copy: screen effects on/off, direction marker on/off, HUD flashing on/off, camera shake slider, audio cue slider, vibration on/off. No low-health audio toggle exists there, so the heartbeat is likely part of the screen effect or a fixed sound.
- A directional hit marker (TLOU2 "Damage Indicators") gives the "I got hurt, from there" information without covering the screen edge.

### Gaps
- Exact screen size, opacity, and timing for GoW 2018, TLOU2, Diablo IV at launch, L4D2 (normal state), Gears Omen, DRG, Hades I/II: not verified.
- Low-health thresholds (percentage) for almost all games: not found.
- Haptic and flinch details for most games: not found.
- caniplaythat.com entries: not reached (no search result). Need a direct fetch of each game's page.
- Game UI Database (gameuidatabase.com): not reached. Its per-game pages would show the real effect. Search did not return the right pages.
- Several requested games (Halo, CoD, Dead Space, Fortnite, Apex, Vermintide, Darktide, Chivalry 2, KCD, Lethal Company, Ragnarok, Hades II) have no verified data.

## Key Question 2: What do players and critics say about these effects?

### Takeaway
A verified critique exists: a Kotaku piece calls the red low-health screen "annoying" and says it adds no information when a HUD health bar is already visible, and that it can make healing harder by blurring enemies.

### Cited Findings
- The article names Returnal, Outriders, Doom, Gears, Uncharted, The Last of Us, Tomb Raider, Quantum Break, Call of Duty, and Battlefield as games with a low-health screen effect. The effect is described as cracks mimicking a damaged visor plus a red pulse; Outriders blurs; Gears turns grey-red; Uncharted and TLOU drain colour. Source: [Kotaku, "Enough With the Red Screen of Almost Death"](https://kotaku.com/enough-with-the-red-screen-of-almost-death-1846752628) [Fetched].
- The author says the effect raises tension and warns of death, but adds frustration. In Doom and Outriders, healing comes from killing enemies, and low health makes enemies harder to see, which the author calls "an ouroboros of failure." Source: same [Kotaku](https://kotaku.com/enough-with-the-red-screen-of-almost-death-1846752628) [Fetched].
- The author calls the criticism a minor quibble and says the effect feels like overkill in games where you die often. Source: same [Kotaku](https://kotaku.com/enough-with-the-red-screen-of-almost-death-1846752628) [Fetched].
- The article cites a 2016 Game Maker's Toolkit video for the origin of the effect (recharging shields in Halo). Source: same [Kotaku](https://kotaku.com/enough-with-the-red-screen-of-almost-death-1846752628) [Fetched].
- The Escapist (Diablo IV beta) criticized the lack of an option to turn off the screen effect and heartbeat. Source: [The Escapist](https://escapistmagazine.com/?p=139219) [Snippet].

### Inferences
- The strongest critique is "it duplicates a health bar and can hide enemies." This matches the owner's "too much" reaction to a full-screen-edge overlay.
- A common fix in the sources is a toggle, not removal.

### Gaps
- No caniplaythat or Reddit threads reached. Owner's "red screen", "damage indicator", "blood on screen" searches not done.
- No developer quotes found on low-health design.

## Key Question 3: Non-screen feedback (sound, camera, character, rumble)

### Takeaway
Verified sound and vibration options exist in TLOU2 (combat audio and vibration cues, no low-health cue). Camera shake and flashing have sliders or toggles in TLOU2 and Hades (shake only). Other games: gaps.

### Cited Findings
- TLOU2: Camera Shake 1-10 slider; HUD Flashing toggle; Combat Vibration Cues toggle. Source: [Naughty Dog blog](https://www.naughtydog.com/blog/THE_LAST_OF_US_PART_II_ACCESSIBILITY_FEATURES_DETAILED) [Fetched].
- Hades: screen shake can be disabled. Source: [Family Gaming Database](https://www.familygamingdatabase.com/accessibility/Hades) [Snippet].
- L4D2: heartbeat plus grayscale in final incapacitation. Source: [L4D fandom](https://left4dead.fandom.com/wiki/File:Black_and_white_vision.jpg) [Snippet].

### Inferences
- A safe design pattern: keep sound and vibration optional, and give each its own slider or toggle.

### Gaps
- Character flinch, flash, and grunt sounds for all games: not verified.
- Tinnitus or muffle effects: not verified for any game in this set.

## Suggested next steps (for the lead)
1. Fetch the Game UI Database pages directly (search for each game title on gameuidatabase.com).
2. Fetch caniplaythat.com entries for Hades II, TLOU2, GoW 2018, Diablo IV, Gears, Dead Space, Halo.
3. Search Reddit with exact phrases: "low health screen effect" plus game name, and "damage indicator" plus game name.
4. Retry the Left 4 Dead wiki and Gears wiki pages later (HTTP 402 at fetch time).
