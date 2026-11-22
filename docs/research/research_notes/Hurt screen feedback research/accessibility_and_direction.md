# Accessibility rules for hurt/damage feedback, and directional damage indicators

Scope: small indie team, 3D third-person medieval dwarf survival game, melee monsters, up to 4-player co-op. Screen effects should be subtle.
Research budget used: about 16 tool calls. Sources were read directly where noted. Several items are gaps (see the Gaps lists).

---

## Key Question 1: Accessibility rules for flashes, red flashes, shake, blur, colour, and options

### Takeaway
Treat any full-screen flash as a seizure risk. Keep flashes under 3 per second, keep any flashing area well under 20-25% of the screen, avoid sudden red flashes, and never let red-only or colour-only cues carry the hurt signal. Shake, blur, and FOV effects need an on/off or 0-100% setting.

### Cited Findings

**Xbox Accessibility Guideline 118 (Photosensitivity), read from the live page (Microsoft Learn, updated 2026-11-14)**
- "All games should be tested for photosensitive seizure triggers, regardless of whether the game includes intentional flashing." — [XAG 118](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118)
- Approx. 1 in 4,000 people can have a seizure from certain visual images; the guideline says that eliminating such content "is preferred over splash-screen warnings." — [XAG 118](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118)
- Luminance flash definition: "A flash is defined as a 10% change in luminance (where 100% is the maximum luminance of a white screen). The darker luminance value should be below 0.8." — [XAG 118](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118)
- Luminance failure criteria: flashes "too frequently (approximately more than three per second)"; flashes that "take up a certain amount of the screen (approximately 20 percent or more)"; "Lower intensity flashing can also cause a failure if it's continued for an extended period of time." — [XAG 118](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118)
- **Red flash definition:** applies when either extreme of the flash is saturated red, defined as R/(R+G+B) >= 0.8. A red flash is defined when the change in (R-G-B) × 320 is greater than 20. Red flashes need a lower luminance change to fail. Same frequency (about 3/s) and area (about 20%) failure criteria. Fixes listed: "Desaturate the red coloring." — [XAG 118](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118)
- Spatial pattern failure: alternating high-contrast bands where the contrast difference is greater than 10% and the pattern covers about 20% or more of the screen. — [XAG 118](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118)
- Tools listed by XAG 118: Harding FPA test (Cambridge Research Systems), at https://www.hardingfpa.com/ — [XAG 118](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118)

**Game Accessibility Guidelines (flicker page), read from the live page**
- Duration: "Any sequence of flashing images that lasts for more than 5 seconds" is a failure. — [GA Guidelines: Avoid flickering images and repetitive patterns](https://gameaccessibilityguidelines.com/avoid-flickering-images-and-repetitive-patterns/)
- Frequency: "More than three flashes in a single second, covering 25%+ of the screen." — same page
- Moving patterns: "Moving repeated patterns or uniform text, covering 25%+ of the screen." Static patterns: "Static repeated patterns or uniform text, covering 40%+ of the screen." — same page
- Brightness/colour: "an instantaneous high change in brightness/contrast (including fast cuts), or to/from the colour red." — same page
- Note: the GA page says "investigate providing an option to disable them" for these effects. — same page

**WCAG 2.2 Success Criterion 2.3.1 (Three Flashes or Below Threshold), read from the W3C Understanding page**
- Pass condition (quoted): "there are no more than three general flashes and / or no more than three red flashes within any one-second period" OR the content "occupies no more than a total of .006 steradians within any 10 degree visual field on the screen." — [WCAG 2.2 Understanding 2.3.1](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html)
- The W3C page gives the 10-degree rule as "(25% of any 10 degree visual field on the screen)" and uses a 341 x 256 pixel rectangle as a reference size. — same page
- General flash: "a pair of opposing changes in relative luminance of 10% or more of the maximum relative luminance (1.0)", where "the relative luminance of the darker image is below 0.80." — same page
- Red flash: "any pair of opposing transitions involving a saturated red." — same page
- WCAG 2.3.1 is Level A. WCAG 2.3.2 (Level AAA) bans flashing above three per second regardless of size or brightness (from secondary search summary; not read directly).

**Xbox Accessibility Guideline 117 (Visual Distractions and Motion Settings), read from the live page**
- Goal: players should be able to customise "field of view, camera movement and sensitivity, and other visual settings related to camera or screen movement." — [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117)
- Implementation: "Avoid the use of camera shake, camera bobbing effects, motion blur, mouse blur, and more or provide an option to turn off these behaviors." — [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117)
- Example from the page: "In Halo Infinite, players can individually set the intensity or amount of radial blur, screen shake, full screen effects, and speed lines across a sliding scale from zero to 100%." — [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117)
- Other examples on the page: Cyberpunk 2077 "additive camera motions" adjustable; Elder Scrolls Online head bob as a sliding scale; Halo Infinite FOV; Assassin's Creed Valhalla "Close Camera" option; Sea of Thieves auto-centre delay and speed.
- Also: "Avoid any repetitive side-to-side or up-and-down on-screen movement, except that which is core to game play." — [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117)

**Colour-only cues (Xbox and GA)**
- Xbox guidance (from the search summary of XAG 103 and the GA site): "aim to have no cue depend on color alone. When color reliance is unavoidable, let the player pick the colors used for individual game elements." — [XAG 103 (devdocs)](https://devdocs.xbox.com/gaming/accessibility/xbox-accessibility-guidelines/103) (quote taken from search snippet; not fully read)
- GA Basic rule: "Ensure no essential information is conveyed by a fixed colour alone." — [GA: ensure no essential information is conveyed by a fixed colour alone](https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-fixed-colour-alone/) (quote from search snippet; the page was not fully read)
- Equivalent web rule: WCAG 1.4.1 Use of Color (Level A) (from search summary; not read directly).

**Background movement (GA)**
- GA page on background movement: "Background animation can distract greatly from elements that are important to gameplay." It gives no numbers and does not mention hurt effects. — [GA: Provide an option to turn off / hide background movement](https://gameaccessibilityguidelines.com/provide-an-option-to-turn-off-hide-background-movement)

**Player reports on shake (not authoritative, but shows real demand)**
- An Overwatch 2 forum thread says the "reduced screen shake" option seemed to affect only the shake from taking damage. — [Blizzard forum thread](https://us.forums.blizzard.com/en/overwatch/t/overwatch-2-accessibility-and-screen-shake/671231/31)
- Indie developers in itch.io threads report motion sickness from shake and add a slider so shake can be set to 0. — itch.io threads (search results only; not read in full)

### Inferences
- The strictest common numbers to design against are: no more than 3 flashes per second, no flash covering about 20% or more of the screen, no flash longer than 5 seconds, and no red full-screen flash. A single hurt flash that is a short, low-contrast tint of the screen is most likely safe, but it should be tested in Harding FPA or a similar tool anyway.
- Sources disagree on the area: XAG 118 says about 20%; GA says 25% for moving patterns and 40% for static ones; WCAG uses a 10-degree field rule. Pick the lowest (20%) as the team limit.
- A red vignette that pulses on each hit is a "flash" to any test tool if its brightness changes quickly. Make hurt tints fade in and out slowly (well over 1/3 second per on/off cycle) and never repeat faster than 3 times per second.
- Tools to add: a "Hurt screen effect" slider (0-100%, Halo style), "Screen shake" slider (0 = off), "Camera effects off" toggle (no shake, no blur, no head bob), and a non-colour hurt cue (icon, sound, controller rumble).

### Gaps
- Could not read the GA "provide visual feedback in addition to audio and haptic cues" page (returned 404). Need a different URL or search to confirm its wording.
- Could not find a Can I Play That review that lists damage or screen-shake settings. The search results were mostly itch.io posts.
- Did not look up AbleGamers, Includification, or the Ofcom/ITU photosensitivity guidance.
- Did not check Harding FPA's own published threshold text; the numbers above come from XAG, GA, and W3C.
- Did not confirm the exact names of hurt/damage toggles in specific games. Only Halo Infinite (radial blur, screen shake, full-screen effects, speed lines), Gears 5 ("Disable Camera Shake"), Jedi: Fallen Order and It Takes Two (camera shake toggles), Battlefield 2042 ("camera shake amount"), and Cyberpunk 2077 ("additive camera motions") are sourced, and only through the XAG 117 page or a secondary search summary.

---

## Key Question 2: Which games offer hurt/shake/low-health toggles and what they are called

### Takeaway
Naming is not standard. The most-cited example (Halo Infinite) uses a 0-100% slider per effect. Most games use "camera shake" or "screen shake" as the setting name. The GA and XAG guidance asks for a way to turn these off, not for a particular name.

### Cited Findings
- Halo Infinite: separate 0-100% sliders for "radial blur, screen shake, full screen effects, and speed lines." — [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117)
- Gears 5: "Disable Camera Shake" option (from XAG 117 summary, secondary). — [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117) (cited in the search summary, not verified on the page)
- Jedi: Fallen Order and It Takes Two: camera shake on/off toggles. Battlefield 2042: "camera shake amount" setting. — [XAG 117 summary](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117) (secondary)
- South of Midnight (per Xbox GAAD post): settings for field of view, "environmental screen shake," chromatic aberration, head bob, weapon bob. — [Xbox news GAAD 2025](https://news.xbox.com/en-us/2025/05/15/global-accessibility-awareness-day-2025-xbox/) (secondary, from search summary)
- Overwatch 2: "reduced screen shake" and damage FX options, as reported by a forum poster. — [Blizzard forum](https://us.forums.blizzard.com/en/overwatch/t/overwatch-2-accessibility-and-screen-shake/671231/31)
- Cyberpunk 2077: "additive camera motions" set to "full" (adjustable). — [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117)

### Inferences
- A safe name for our game: "Screen shake" (slider 0-100%), "Hurt screen flash" (slider or on/off), "Camera effects" (on/off, covers shake and blur), and "Low health warning" (on/off, with a non-colour cue).

### Gaps
- Did not confirm damage-flash or low-health toggle names for Dark Souls, Monster Hunter, God of War, Vermintide, For Honor, Shadow of Mordor, or Ghost of Tsushima. No source found.

---

## Key Question 3: Directional damage indicators (shooters vs melee/third-person)

### Takeaway
Shooters use screen-edge flashes or HUD arcs that point at the attacker, because the camera often faces away from the attacker. In melee third-person games, the camera usually faces the enemy, so direction arrows add little for front attacks. The better use is an arrow or flash only for attackers off-screen. Melee games mostly rely on telegraphs (wind-up animations and sounds) instead.

### Cited Findings

**Shooters**
- Halo 3 UI design doc: Halo 2's full-screen flash was replaced with "a directional gradient," plus small red arrows around the crosshair that point toward shooters and grenade throwers. Rear-attacker arrows were tuned to avoid pointing straight behind. Blue marks shield damage, red marks health damage. — [Halopedia / Halo HUD references (Halo 3 UI doc summary)](https://www.halopedia.org/HUD) (secondary; the underlying Halo 3 UI doc was not read directly). Also [UI/UX Director Halo HUD page](https://david-candland.squarespace.com/halohud) (not read).
- Halo 4 used semicircles and arrows; Halo 5 used semicircles that turn green on friendly fire (secondary, same sources).
- Call of Duty: "red flashes at the screen edges that show both that damage occurred and where it came from" (secondary search summary). Exact CoD arc math not found. — [Giant Bomb: Damage Flash](https://giantbomb.com/wiki/Concepts/Damage_Flash) (not read in full)
- Shooter indicators are "useful but imprecise, since a point on a circle takes attention to read." — [Medium: UX analysis of FPS damage indicators](https://medium.com/@jasper.stephenson/a-ux-analysis-of-first-person-shooter-damage-indicators-59ac9d41caf8) (search summary; not read in full)
- Overwatch uses hit size to show strength (secondary). — same search summary.

**Melee / third-person**
- Signals and Light essay "How do enemy attacks work with the CAMERA?":
  - Off-screen attacks have three approaches: Bayonetta (2009) "enemies who are off-screen cannot attack"; partly camera-sensitive games where "the enemies are still ALLOWED to attack from off-screen, but it's just less likely to happen"; camera-insensitive games like Returnal (2021), where the player cannot control enemy positions. — [Signals and Light](https://signalsandlight.substack.com/p/how-do-enemy-attacks-work-with-the)
  - Directional indicator: "a directional indicator that tells the player where an attack is coming from when it's off-screen." Used in shooters' HUD and in God of War Ragnarok (2022). — same
  - Critique: "an arrow is nowhere near as informative as seeing the actual attacking entity"; it "doesn't tell the player what kind of attack it is or even how far away the attacker is." — same
  - Debate: indicators "can just be a form of accessibility for players who want less of a challenge"; they may be needed "in chaotic games." Author's conclusion: "There is no EASY solution to this problem." — same
  - Alternatives named: audio cues ("skilled players... should be able to control their camera and listen for audio cues"); multi-stage visual telegraphs; warnings put directly on the player character; enemy grouping so enemies rarely go off-screen (DOOM Eternal 2020, Lies of P 2023). — same
- Spidey-sense-style icons: Dragon Age: The Veilguard shows a Batman Arkham/Spider-Man-style alert above Rook's head before incoming enemy attacks (Kotaku, search summary). Spider-Man Remastered forum says the sense "sometimes does not show when an attack or projectile is incoming." — [Kotaku](https://kotaku.com/dragon-age-veilguard-warrior-combat-trailer-rook-davrin-1851630999/7); [Steam discussion](https://steamcommunity.com/app/1817070/discussions/0/3431200155176907440) (both search summaries only)
- Dark Souls 3 "Anatomy of an Enemy Attack" (Game Developer) describes attack animation phases for clarity. — [Game Developer](https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3) (search snippet only; not read in full)

### Inferences
- For our third-person melee game (camera faces the enemy), a "hurt direction" arrow on screen for front attacks would mostly repeat what the player can already see. It adds clutter and works against the "subtle" goal.
- Better: show the hit direction only when the attacker is off-screen (arrow at the screen edge, small, fades after about 1 second). Pair it with a sound cue from the attacker's direction. Use attack telegraphs (wind-up animation, enemy glow or grunt) as the main warning in melee.
- In co-op, the same arrow rule applies to teammates: no hurt effect on the local screen when a teammate is hit. Show teammate damage on that teammate's nameplate or portrait instead.
- Keep every indicator colour-independent: shape (arrow vs. circle), position, and sound must carry the same information as colour.

### Gaps
- Did not verify exact indicator behaviour for Dark Souls, Monster Hunter, Assassin's Creed, Shadow of Mordor, Ghost of Tsushima, For Honor, or Vermintide (no reliable source found in the search results).
- Did not find CoD's damage-direction implementation details (no primary source).
- No playtest or user-study data on whether arrows help or hurt in melee games was found.

---

## Key Question 4: Co-op considerations (teammate hurt display)

### Takeaway
Show teammate damage with small, local UI (portrait or nameplate pulse, a short sound cue) rather than screen-wide effects. Keep the full-screen hurt effect for the player who is hit only.

### Cited Findings
- No source found that directly gives co-op hurt display guidance. The XAG 117 guidance on "moving, blinking, scrolling, or flashing content" says "a mechanism to entirely disable this content" and "a mechanism to pause or hide this content." — [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117). This supports making teammate-hurt pulses optional.
- The GA background-movement guidance: "Background animation can distract greatly from elements that are important to gameplay." — [GA](https://gameaccessibilityguidelines.com/provide-an-option-to-turn-off-hide-background-movement)

### Inferences
- Teammate hurt pulses should follow the same flash limits as the player's own screen (no more than 3/s, no red flash).
- Add an option to hide teammate-hurt pulses for players sensitive to motion or clutter.

### Gaps
- No source on co-op-specific hurt UI (e.g. Left 4 Dead, Vermintide, Deep Rock Galactic) was found in this session. Recommend a follow-up search if this matters.

---

## Recommended rules for the team (from the sources above, for the report writer)

1. No full-screen flash faster than 3 per second. No flash covering about 20% or more of the screen. No flash longer than 5 seconds. Keep the screen tint slow (fade in and out over at least 1/3 second).
2. No red full-screen flash. Hurt tint should be a low-saturation warm colour, not saturated red (XAG 118 red-flash rule: R/(R+G+B) >= 0.8).
3. Hurt cues must not depend on colour alone: add a sound, a controller rumble, and an icon or shape change.
4. Settings: "Screen shake" slider 0-100%, "Hurt screen tint" slider 0-100% or on/off, "Camera effects off" toggle (shake, blur, head bob), FOV slider.
5. Melee direction: show a small off-screen arrow only when the attacker is off-screen. No on-screen arrows for front attacks. Main warning is the attacker's telegraph.
6. Co-op: teammate hurt shown on the teammate's portrait or nameplate only. Optional toggle to hide it.
7. Test every hurt effect in Harding FPA (or equivalent) before release, per XAG 118.

## Source list (URLs)
- XAG 118 Photosensitivity: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118
- XAG 117 Visual distractions and motion: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117
- XAG 103 (search snippet only): https://devdocs.xbox.com/gaming/accessibility/xbox-accessibility-guidelines/103
- GA flicker page: https://gameaccessibilityguidelines.com/avoid-flickering-images-and-repetitive-patterns/
- GA colour page: https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-fixed-colour-alone/
- GA background movement: https://gameaccessibilityguidelines.com/provide-an-option-to-turn-off-hide-background-movement
- WCAG 2.2 Understanding 2.3.1: https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html
- Harding FPA: https://www.hardingfpa.com/
- Signals and Light (off-screen attacks): https://signalsandlight.substack.com/p/how-do-enemy-attacks-work-with-the
- Halopedia HUD: https://www.halopedia.org/HUD
- Medium FPS damage indicator UX analysis: https://medium.com/@jasper.stephenson/a-ux-analysis-of-first-person-shooter-damage-indicators-59ac9d41caf8
- Game Developer, Dark Souls 3 enemy attack anatomy: https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3
- Blizzard forum on screen shake: https://us.forums.blizzard.com/en/overwatch/t/overwatch-2-accessibility-and-screen-shake/671231/31
- Kotaku, Dragon Age Veilguard alert: https://kotaku.com/dragon-age-veilguard-warrior-combat-trailer-rook-davrin-1851630999/7
