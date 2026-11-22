# Hurt-screen feedback across games: catalogue (partial, research pass 1)

**Read this first:** this pass is thin. About 14 tool calls, search results were often off-target, and most games on the list could NOT be verified. Sourced entries are marked [V] (verified from a cited page). Entries from memory are marked [M] (unsourced, must be checked in game before use). Gaps are listed per section. Numbers come only from the Valheim mod pages and the Unity/Minecraft mod pages, which are mods, not the vanilla games.

## Per-game table (what is verified)

| Game | Hit on screen | Low-HP state | Source status |
|---|---|---|---|
| Gears of War (series) | Crimson Omen cog appears centre-screen once damaged; gets sharper as damage builds | Downed stage: full Crimson Omen with skull shown; one more hit kills; health regens if you stay clear | [V] fan wiki (fetch failed, snippet only) |
| Dead Space | Health meter is on Isaac's spine (diegetic), not a screen HUD bar | Red flashing on the spine meter (per a search snippet, not confirmed in a fetched page) | [V] meter location only; colours/thresholds NOT verified |
| Returnal, Outriders, Doom, Gears, Uncharted, The Last of Us, Tomb Raider, Quantum Break, CoD, Battlefield | Criticised by one writer (see Section 2) | Red pulse, cracks, blur, desaturate, "redscale" | [V] Kotaku critique (names games only, no numbers) |
| Halo Infinite | Shield bar at top of HUD | Shield bar flashes red when depleted + low-pitched warning tone; shields regen after about 5 s without damage | [V] support.halowaypoint.com |
| Halo: Reach | Depleted-shield indicator shows word "Warning" | Health bar flashes continuously when below yellow | [V] halopedia snippet |
| Halo CE / Halo 2 | Overshield adds red then green layers over blue shield bar | n/a | [V] halopedia snippet |
| Zelda (general) | n/a | Low-health beep; starts at a % of max HP (confirmed for Ocarina of Time only); can be turned off | [V] zeldauniverse / zeldaspeedruns snippets. BotW threshold NOT verified |
| Monster Hunter Wilds | Monster heartbeat line bottom-left (monster, not player) | n/a for player | [V] snippet. Player HP feedback NOT found |
| Valheim (vanilla) | Conflicting: one request says vanilla has little feedback beyond an "ough" sound; another says no screen-edge flash | Not found in vanilla | [V] conflicting sources; treat as unknown |
| Minecraft (vanilla) | Not checked | Not checked | [M] Vanilla: red tint flash on screen when hurt, hearts flash; not verified here |
| Elden Ring | Red-square debuff under HP bar = Fia's hug, -5% max HP (a status, not a low-HP cue) | No low-HP screen effect found | [V] wiki snippets. No low-HP effect confirmed or ruled out |
| Bloodborne | "Red health" bar: lost HP drains, you can regain only the last hit's loss | Not verified | [V] Fextralife-style snippet |
| Dark Souls / Bloodborne (screen flash) | Not found | Not found | Gap |
| Deep Rock Galactic | Status effects show icons at bottom centre; some add a HUD overlay | Low-health effect NOT found | [V] fandom stub; incomplete |
| Diablo 4 / Last Epoch | Red screen + heartbeat at low HP mentioned in a search title | Not verified | Gap (title only) |

## Section 1: On a hit, what happens on screen (size, colour, direction)

### Takeaway
Most sources describe hit feedback as a short edge-only flash or an indicator, not a full-screen wash. A direction indicator (Giant Bomb "Damage Flash") tells the player where the hit came from.

### Cited Findings
- A damage flash is "a bright, usually red border effect" that tells players they are taking damage and from which direction — [Giant Bomb concept page](https://giantbomb.com/wiki/Concepts/Damage_Flash) (snippet only, not fetched)
- Wire's Damage Vignette (Valheim mod, deprecated): red screen-edge flash on direct hits; flash opacity default **0.20**, flash duration default **0.60 s**; both adjustable — [Thunderstore](https://thunderstore.io/c/valheim/p/Wire/WiresDamageVignette/)
- Valheim DamageSplash mod: red screen-edge bloom on heavy hits to the player — [Thunderstore](https://thunderstore.io/c/valheim/p/Jumpingmushroom/DamageSplash/)
- A UX write-up notes Overwatch shows a larger indicator for a larger hit — [Medium UX analysis](https://medium.com/@jasper.stephenson/a-ux-analysis-of-first-person-shooter-damage-indicators-59ac9d41caf8) (snippet)
- Battlefield-style palette shift: colour drains to grey and edges vignette more as damage builds (described as progressive) — same Medium source (snippet)
- Unity "UI Damage" asset: directional indicators, screen flash that can persist while dying, camera shake on hit — [Unity Asset Store](https://assetstore.unity.com/packages/slug/164249) (vendor listing, not game evidence)
- Gears Crimson Omen: the one persistent on-screen hit cue, scaling with damage rather than a one-off flash — [Gears fan wiki](https://gearsofwar.fandom.com/wiki/Crimson_Omen)
- Halo Infinite shield bar flashes red on depletion (HUD bar, not screen) — [Halo Waypoint support](https://support.halowaypoint.com/hc/en-us/articles/24284987877524-Shields-in-Halo-Infinite)

### Inferences
- A thin, short edge flash (~0.2 opacity, ~0.6 s) is a common, small default. That is much smaller than the full-edge overlay the owner called "too much."
- A HUD-bar flash (Halo) gives the same warning without touching the picture at all.

### Gaps
- No camera-shake numbers, flinch timing, or sound details for any AAA game above.
- Not verified: Elden Ring, Monster Hunter, Souls, Minecraft, Terraria, Sea of Thieves, Enshrouded, Grounded, V Rising, Don't Starve, Diablo IV, Hades, God of War, TLOU, Apex, Fortnite, Left 4 Dead, Kingdom Come, Mordhau/Chivalry 2, Vermintide/Darktide, Lethal Company. Searches returned nothing usable for these.

## Section 2: At low health, what happens (threshold, screen, HUD, music, heartbeat)

### Takeaway
The "red screen of almost-death" is very common, and one critic calls it overused and sometimes counterproductive. The strongest concrete numbers come from Valheim mods, not from the official games.

### Cited Findings
- Kotaku (Ari Notis): the red low-health screen is "de rigueur game design for ages." Effects criticised: Returnal's cracked-visor cracks and pulsing red; Outriders/Doom blur; Gears/Uncharted/TLOU desaturation or "redscale" — [Kotaku](https://kotaku.com/enough-with-the-red-screen-of-almost-death-1846752628) (undated in fetch). Core complaint: in games where you heal by killing, the low-HP screen hides enemies, so you cannot heal and die ("an ouroboros of failure"). Redundant when the HP bar is already on screen. No alternatives proposed.
- Valheim "Low Health Indicator" mod: heartbeat when HP ≤ **25** and all food is gone; several styles including a red screen halo; threshold and food rule are configurable — [Thunderstore](https://thunderstore.io/c/valheim/p/YouDied/Low_Health_Indicator/)
- Wire's Damage Vignette: red vignette starts below **65%** HP by default and strengthens as HP falls — [Thunderstore](https://thunderstore.io/c/valheim/p/Wire/WiresDamageVignette/)
- Damage Overlay mod (Minecraft): red vignette that gets stronger as HP drops — [Modrinth](https://modrinth.com/project/ZAWdXmwe)
- A FAB gameplay-ability listing describes a vignette that appears under **25%** HP and fades after recovering above **30%** (hysteresis so it doesn't flicker) — [FAB listing](https://www.fab.com/listings/d664542a-4149-4530-b123-55c6b251b2ea?lang=fr) (vendor, not game)
- Zelda low-HP beep: starts at a percentage of max HP (Ocarina of Time, per a speedrun wiki); not necessarily critical — [Zelda speedruns](https://zeldaspeedruns.com/oot/generalknowledge/damage-health). Beep can be turned off per TechRadar tip list — [TechRadar](https://www.techradar.com/au/how-to/the-legend-of-zelda-breath-of-the-wild-tips-and-tricks)
- Halo: Reach health bar flashes continuously below yellow; word "Warning" on depleted shields — [Halopedia](https://www.halopedia.org/Heads-up_display) (snippet)
- TV Tropes Life Meter: heartbeat sound plays more often the lower the HP (general, not a specific game) — [TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/Main/LifeMeter) (snippet)

### Inferences
- Common threshold numbers across mods cluster at 25% (heartbeat/pulse) and 30–65% (faint vignette starts). A gentle version starts around 25–30% and is very faint.
- Hysteresis (fade out only above ~30% after going under 25%) is a cheap fix for flicker.

### Gaps
- No vanilla numbers from any official game for low-HP thresholds (except Zelda OoT, which is a percentage with no value given).
- No desaturation amounts, fade times, or opacity values from official games.

## Section 3: Camera, character, sound, rumble

### Takeaway
Almost nothing about camera kick, flinch, sound or rumble was verified in this pass. These need a second research pass, ideally with GDC talks and Game Developer articles.

### Cited Findings
- Valheim "No Damage Flash" mod exists, implying vanilla has a damage flash some players wanted removed (inferred from mod name only) — [Thunderstore](https://thunderstore.io/c/valheim/p/VentureValheim/No_Damage_Flash/required)
- Valheim "ough" sound is the only vanilla hit feedback described by a 2020 player request — [Nexus Mods forum](https://forums.nexusmods.com/topic/456955-damage-visual-feedback) (snippet; contradicted by the Valheim status note above)
- Dead Space: UI made so the player "is not just looking at it," the camera keeps Isaac in shot; the spine meter is "relatively subtle" because the eye stays on screen centre — [Dead Space 2 diegetic UI](https://www.hudsandguis.com/home/2012/08/22/dead-space-2-diegetic-interface-design) (fetched; no thresholds), [GameDeveloper](https://gamedeveloper.com/design/video-designing-i-dead-space-i-s-immersive-user-interface) (fetched; no numbers). Full talk: GDC 2013, Dino Ignacio, "Crafting Destruction" — [GDC Vault](https://gdcvault.com/play/1018819/Crafting-Destruction-The-Evolution-of) (not fetched; likely paywall or video)

### Inferences
- Diegetic health (Dead Space) avoids a screen effect entirely and may suit a game where the owner wants to avoid "too much." Worth checking the GDC talk.

### Gaps
- No verified sound design, camera shake, flinch, stagger, or controller-rumble numbers for any game.
- Dead Space GDC talk not read. Gears wiki page returned HTTP 402 on fetch.

## Suggested next steps (for the next pass, not done)
1. Fetch Giant Bomb "Damage Flash" and the Gears wiki via a different route.
2. Look for Game UI Database (gameuidatabase.com) pages for Dead Space, Returnal, Hades, Deep Rock Galactic, Elden Ring. The search tool did not return that site.
3. Check Valheim vanilla damage flash directly in game (quick in-game test).
4. Search GDC talks on hit feedback ("juice", "feedback on damage", "camera shake") and the Dead Space GDC talk.
5. For a dwarf game: a faint edge flash (~0.2 opacity, ~0.6 s) plus a HUD heart/bar flash, with the low-HP pulse starting at ~25% and fading out above ~30%, is a candidate. This is an inference, not a sourced recommendation.
