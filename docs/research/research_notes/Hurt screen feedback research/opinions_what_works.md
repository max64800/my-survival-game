# Opinions on "you got hurt" screen effects: what annoys players, what designers say, what gets praised

Research date: 2026-11-22. Scope: red flashes, blood on screen, damage vignettes, low-health filters, camera shake on hit, directional damage indicators.
Labels used: **[Community]** = player/forum/reviewer opinion. **[Designer/Doc]** = developer, designer or accessibility-guideline statement. **[Search snippet only]** = seen in search results, page not opened.

Limits of this pass: about 16 tool calls. Several pages returned HTTP 403 (Nexus mod pages, Nexus forum thread 510322, the Medium UX article, and the Nexus thread 2383764 was readable). The original Kotaku article could not be found. No Nexus download counts could be verified.

---

## 1. What players complain about

### Takeaway
Players most often complain about (a) red or blood overlays that hide the screen, (b) a low-health filter that stays on until healing or death, (c) effects that make a bad situation harder to read, and (d) camera drift or shake that causes nausea. The most common fix requested is an option to turn the effect off or reduce it.

### Cited Findings
- Players call the red low-health screen "tiresome." A Tildes commenter (mrbig, the OP) says they "grew tired" of it and would "rather just deal with the consequences of dying," and says it is confusing in The Division 2 when a player goes down while standing. [Tildes thread on the Kotaku piece](https://tildes.net/~games/wee/enough_with_the_red_screen_of_almost_death) **[Community]**
- The "ouroboros of failure" complaint: low health makes enemies harder to see, which makes healing harder to get. The thread quotes the (unopened) Kotaku article as saying "It's an ouroboros of failure." [Tildes thread](https://tildes.net/~games/wee/enough_with_the_red_screen_of_almost_death) **[Community, quoting an article]**
- A second Tildes commenter (stu2b50) argues the death-spiral is "intuitive" and mirrors real life, which shows the debate is not one-sided. [Tildes thread](https://tildes.net/~games/wee/enough_with_the_red_screen_of_almost_death) **[Community]**
- Redundancy: critics say most games already show health on the HUD, so the red screen repeats it. [Search snippet, Kotaku coverage via search results](https://kotaku.com/1846765303) **[Community/critic]**
- Vintage Story (2020): players asked for a way to turn off the damage overlay. Reasons given: "very bad eyes"; "the sudden red flash is very harsh on sensitive eyes"; "too violent"; "unsettling when the screen flashed red without an obvious cause"; and "Blood imagery... not for them." DearFox asked for it to be made "more transparent instead of removed entirely." [Vintage Story forum 1471](https://www.vintagestory.at/forums/topic/1471-option-to-disable-damage-overlay-1122/) **[Community]**
  - Developer reply (Tyron, team lead, 26 March 2020): the team was busy with support tickets and major bugs. The only offered fix was a modding workaround: edit `final.fsh` at line 143, set the overlay to 0.9 (reduced) or 2 (none). No official toggle is mentioned, and the thread was later archived. **[Designer/Doc, developer statement]**
- Nexus forum (Skyrim-era, low-health filter): a player asked "is there any mod or menu setting to turn off the low health filter" because it made it hard to see. [Nexus forum 2383764](https://forums.nexusmods.com/topic/2383764-is-there-any-mod-or-menu-setting-to-turn-off-the-low-health-filter) **[Community]** (The thread page loaded; the exact posts were summarised by the fetch tool, so only the request is quoted.)
- Dead by Daylight: players complained that a red stun effect "was making some players sick." [Search snippet, DBD forum "Why is the pallet stun VFX going live?"](https://forums.bhvr.com/dead-by-daylight/discussion/comment/531876) **[Community, search snippet only]**
- Diablo 4 (search snippet): players called the flood of effects "Like in a Where's Waldo book." [mein-mmo](https://mein-mmo.de/en/diablo-4-players-are-annoyed-by-the-flood-of-effects-like-in-awheres-waldo-book,1162644) **[Community, search snippet only]**
- Motion sickness from camera drift at low health: a Vintage Story player (SatinLeader00, April 2022) asked for a toggle because "it can be very nauseating to watch your view pan by itself when on low health." Maelstrom said they had to stop playing once or twice and would "prefer not having to take Zofran just to play this game." [Vintage Story forum 7302](https://www.vintagestory.at/forums/topic/7302-ability-to-turn-off-camera-drift-when-low-health-for-people-who-get-motion-sick) **[Community]**
  - Outcome: a mod (Accessibility Tweaks v2.3.0, 27 April 2022) added "Camera Shake now stops involuntary mouse movement when low on health." The base game did not add an official setting in the thread. A new player in December 2025 asked for the setting again. [Vintage Story forum 7302](https://www.vintagestory.at/forums/topic/7302-ability-to-turn-off-camera-drift-when-low-health-for-people-who-get-motion-sick) **[Community / mod author]**
- Overwatch 2 (forum): one player said the screen shake in the beta was "way overkill" and "made them sick at times." Another user found that a "reduced" shake option only lowered the shake added on damage, not all shake, so "off" and "reduced" can mean different things. [Overwatch 2 forum thread](https://us.forums.blizzard.com/en/overwatch/t/overwatch-2-accessibility-and-screen-shake/671231) **[Community]**
- Mod demand (Nexus, Resident Evil Revelations 2, Witcher 3, Mass Effect LE, Skyrim, The Outer Worlds, Fallout 3, Alan Wake 2): many mod pages exist to remove or soften blood-on-screen or low-health edge effects. Examples found: [RE Revelations 2 mod 36](https://nexusmods.com/residentevilrevelations2/mods/36) (lowers edge-blood opacity, can disable vignette/noise); [Skyrim mod 471](https://www.nexusmods.com/skyrim/mods/471/) (removes screen blood on damage); [Skyrim SE mod 28093](https://www.nexusmods.com/skyrimspecialedition/mods/28093) (removes screen blood and blood on ground/weapons); [Witcher 3 mod 406](https://www.nexusmods.com/witcher3/mods/406) (removes low-health edge effect); [The Outer Worlds mod 58](https://www.nexusmods.com/theouterworlds/mods/58) (removes edge bleeding); [Mass Effect LE mod 1431](https://www.nexusmods.com/masseffectlegendaryedition/mods/1431) and [mod 1778](https://www.nexusmods.com/masseffectlegendaryedition/mods/1778) (blood drops and low-health veins). **[Community, mod pages seen in search results]**
  - Skyrim ini workaround, from a Nexus forum post in search results: `bBloodSplatterEnabled=0` in Skyrim.ini. [Nexus forum 1159726 / 510322 (search snippets)](https://forums.nexusmods.com/topic/510322-disable-blood-splatter-on-screen-effect) **[Community, search snippet only]**
- Popularity: **not verified.** The search did not return download or endorsement counts, and the Nexus pages returned HTTP 403 when fetched. The mods exist and are listed on several games' pages, but their relative download size is an open gap (see Gaps).

### Inferences
- The strongest complaints are about **duration** (the effect lingers), **stacking** (red screen plus blur plus shake plus sound), and **redundancy with a health bar**. Brief, one-off cues draw less criticism.
- Accessibility complaints (eye strain, nausea) are the most specific, most repeated, and most likely to get an official toggle.

### Gaps
- Could not get Nexus download counts or endorsements for any blood/low-health mod (pages returned 403).
- Could not open the original Kotaku article by Ari Notis; only commenters quoting it were read.
- Did not check Elden Ring, Cyberpunk, or Valheim mod pages directly.

---

## 2. Games and settings that let players turn effects off or down

### Takeaway
Big games now ship sliders (0–100%) or on/off toggles for shake, blur and motion. Blood and red-flash options are less common and often come only through mods or ini edits.

### Cited Findings
- Halo Infinite: players can set radial blur, screen shake, full screen effects and speed lines each on a 0–100% slider. [Xbox Accessibility Guideline 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117) **[Designer/Doc, quoting Microsoft's examples]**
- Cyberpunk 2077: "additive camera motions" option, adjustable (screenshot cited in XAG 117). [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117) **[Designer/Doc]**
- Diablo 4: "Screen Shake Effects" toggle under Gameplay settings. [GfinityEsports guide (search snippet)](https://www.gfinityesports.com/article/diablo-4-turn-off-screen-shake) **[Search snippet only]**
- EA Split Fiction: players can disable camera shakes from explosions or environment. [EA AbleGamers resource page (search snippet)](https://www.ea.com/able/resources/split-fiction/split-fiction) **[Search snippet only]**
- Microsoft's Xbox guideline (XAG 117) says: "Avoid the use of camera shake, camera bobbing effects, motion blur, mouse blur, and more or provide an option to turn off these behaviors." It also says players should be able to "customize game settings related to field of view, camera movement and sensitivity, and other visual settings related to camera or screen movement." [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117) **[Designer/Doc, platform guideline]**
- XAG 117 also says the option should be a "mechanism to entirely disable" moving content, and "a mechanism to pause or hide" it. [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117) **[Designer/Doc]**
- Dragon Age: The Veilguard forum has motion-sickness threads (search snippet only). [EA forum](https://forums.ea.com/discussions/dragon-age-the-veilguard-discussion-en/motion-sickness/5018929) **[Community, search snippet only]**
- Why: XAG 117 says the goal is for players "susceptible to motion sickness" and "easily distracted." The guideline notes that when visual body movement (like head bob) conflicts with a still body, "motion sickness follows." [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117) **[Designer/Doc]**

### Inferences
- A 0–100% slider per effect (as in Halo Infinite) is the most common design that satisfies both "I want it" and "I want it gone." The Vintage Story "more transparent" request points the same way.
- Blood and low-health vignette options are rarer in official settings than shake and blur options. That is why mods fill the gap.

### Gaps
- Could not verify the exact settings names in the Elden Ring, Skyrim (vanilla), Valheim, or Fallout settings menus; only mods and search snippets were read.
- No data on how many players use these sliders.

---

## 3. What players praise

### Takeaway
Players praise feedback that is **brief, directional, and tied to a real hit**. A short red flash on the edge that points toward the attacker is seen as readable. Several commenters defend red screens as a good way to show danger "anywhere on screen."

### Cited Findings
- tesseractcat (Tildes) calls the red screen "one of the best solutions" for signalling danger anywhere on screen, because audio can be missed and a health bar gets forgotten mid-game. [Tildes thread](https://tildes.net/~games/wee/enough_with_the_red_screen_of_almost_death) **[Community]**
- Nier Replicant (Tildes, Akir): a brief blue tint, smear effect and slowdown at 25% HP lasting about a second. Argued as enough "when a health meter exists." [Tildes thread](https://tildes.net/~games/wee/enough_with_the_red_screen_of_almost_death) **[Community]**
- Giant Bomb's "Damage Flash" entry: the flash "helps inform the player that they are receiving damage as well as the direction it is coming from," because "players don't feel in-game pain." [Giant Bomb](https://giantbomb.com/damage-flash/3015-3282/) **[Designer/Doc-style wiki, search snippet]**
- Giant Bomb "Vision obstruction" entry (search snippet): describes the red glow as a common damage cue. [Giant Bomb](https://www.giantbomb.com/vision-obstruction/92-2678/) **[Search snippet only]**
- Scaleform/Autodesk HUD documentation: a red semi-circle appears on hit and fades out after about one second. [Autodesk Scaleform HUD kit](https://help.autodesk.com/cloudhelp/ENU/Scaleform-Help/scaleform_help/hud_kit/hud_view/directional_hit.html) **[Designer/Doc, search snippet]**
- Medium UX analysis of FPS damage indicators (search snippet only; page returned 403): says a plain hit flash gives only vague direction and is "usually paired with a directional element"; cites Overwatch bar-size changes and Destiny 2 HUD direction. [Medium](https://medium.com/@jasper.stephenson/a-ux-analysis-of-first-person-shooter-damage-indicators-59ac9d41caf8) **[Community/UX author, snippet only]**
- Halo Infinite's sliders and Cyberpunk's additive camera option are praised in XAG 117 as good practice (see section 2). **[Designer/Doc]**

### Inferences
- The praise pattern: **short**, **directional**, **scaled by severity** (the Dead by Daylight/Skyrim complaints were about constant or stacking effects, not single flashes).
- Pairing a directional arrow with a subtle screen cue gets the "where" and "that" without covering the view.

### Gaps
- No direct player quotes praising a specific game's blood or vignette effect were found in this pass.
- Did not open the Giant Bomb pages or the Autodesk page in full (search snippets only).

---

## 4. Designer and industry views

### Takeaway
Designers agree that juice (shake, flashes, particles) makes hits feel stronger, but also that too much polish costs immersion and clarity. The best-known talks are Jonasson & Purho's "Juice It or Lose It" (pro-juice) and Folmer Kelly's "Don't Juice It or Lose It" (counterpoint). Hard numbers on how much screen to cover and for how long were not found.

### Cited Findings
- Martin Jonasson & Petri Purho, "Juice It Or Lose It": argued that making a game "juicy" makes it more fun to play. Venue is disputed in sources: GDC Europe 2012 per a Game Developer article, and "Nordic Game Jam" per a search summary. [Game Developer article "Video: Indies resist the urge to juice it or lose it"](https://gamedeveloper.com/design/video-indies-resist-the-urge-to-juice-it-or-lose-it-) **[Designer/Doc]**; GDC Vault listing: [Juice It or Lose](https://gdcvault.com/play/1016789/Juice-It-or-Lose) **[Search snippet only]**
- Folmer Kelly (Sets and Settings), "Don't Juice It or Lose It" (GDC Europe, per search results): polish makes a game "feel more alive" but "we're actually losing a level of immersion"; says developers focused too much on "eye candy." [Game Developer article](https://gamedeveloper.com/design/video-indies-resist-the-urge-to-juice-it-or-lose-it-) **[Designer/Doc]**; talk listing: [GDC Vault "Don't Juice It or Lose It"](https://gdcvault.com/play/1020861/Don-t-Juice-It-or) **[Search snippet only]**
- Jan Willem Nijman (Vlambeer), "The Art of Screenshake": recommended in secondary sources as the reference on screen shake. The transcript was **not** found; the claims about it come only from write-ups. [Game Developer Vlambeer advice article (search snippet)](https://gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games) **[Search snippet only]**
- Microsoft XAG 117 (see section 2): camera shake and motion blur should be avoidable. **[Designer/Doc]**

### Inferences
- Shake and flash effects are best treated as tuneable "juice" with a player-facing slider, not fixed.
- Kelly's immersion argument supports keeping hit feedback brief, so the world stays readable.

### Gaps
- No talk by Steve Swink ("Game Feel") or Celia Hodent ("The Gamer's Brain") was read in this pass. Their views on damage UI are **not** included here.
- No GDC talk specifically on red screen damage or blood overlay was found.
- Could not open the Nijman talk or confirm its slide claims.

---

## 5. Specific guidance on coverage and duration

### Takeaway
No firm, sourced rule for "% of screen" or "seconds" was found. Usable reference points: brief cues (around 1 second) in shipped examples; sliders that let the player choose; and never letting the effect stay on at low health without an option to turn it down.

### Cited Findings
- Scaleform HUD directional hit: fades after about one second. [Autodesk](https://help.autodesk.com/cloudhelp/ENU/Scaleform-Help/scaleform_help/hud_kit/hud_view/directional_hit.html) **[Designer/Doc]**
- Nier Replicant low-HP cue: about one second, per a commenter. [Tildes thread](https://tildes.net/~games/wee/enough_with_the_red_screen_of_almost_death) **[Community]**
- Vintage Story modding values: overlay set to 0.9 (reduced) or 2 (none). These are shader values, not percentages of the screen. [Vintage Story forum 1471](https://www.vintagestory.at/forums/topic/1471-option-to-disable-damage-overlay-1122/) **[Developer statement]**
- Players in the Tildes thread ask for "turn alpha down, adjust the thresholds, or turn it off," and say "Some titles are worse than others." [Tildes thread](https://tildes.net/~games/wee/enough_with_the_red_screen_of_almost_death) **[Community]**
- A DanBC (Tildes) suggestion: keep the effect on by default, with an off option, and a competitive setting so all players see the same thing. [Tildes thread](https://tildes.net/~games/wee/enough_with_the_red_screen_of_almost_death) **[Community]**

### Inferences
- A safe working rule from these sources: a hit flash should be short (roughly a second), on the edges, directional, and fade fully. A persistent low-health overlay should be slider-controlled, and should not cover the centre of the view.
- Blood and vignette should have an opacity slider and an off option, matching what Vintage Story players and Nexus mods request.

### Gaps
- No peer-reviewed or large-sample study of % coverage and duration was found.
- No game-specific exact percentages were verified.

---

## Summary for the owner (for the report writer)
- Community: the main complaints are a lingering red screen, stacking effects, nausea from shake/camera drift, and the redundancy with the health bar. Mods that remove blood or edge effects exist for many big games, but popularity numbers were not verified.
- Platform guidance (Xbox XAG 117): shake, bobbing and blur must be avoidable or adjustable. This is the strongest "official" support for a settings option.
- Praised: short, directional cues. Players defend a red flash as a clear danger signal when it is brief.
- Designers: "juice" helps, but Kelly argues it costs immersion. No sourced % or seconds rule was found beyond the ~1 second examples above.
- Open gaps: Nexus download counts; Kotaku original; Swink and Hodent views; Nijman talk transcript; exact settings names in Elden Ring/Skyrim/Valheim.
