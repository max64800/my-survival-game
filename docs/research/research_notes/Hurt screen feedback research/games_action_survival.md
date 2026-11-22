# Hurt and Low-Health Feedback in 11 Action and Survival Games

Scope: how each game shows the player that they were hit and that they are low on health. Covers Elden Ring, Dark Souls 3, Monster Hunter World / Rise / Wilds, Zelda Breath of the Wild / Tears of the Kingdom, Minecraft, Valheim (vanilla), Enshrouded, V Rising, Grounded, Don't Starve Together, Terraria, Sea of Thieves.

Research status: this pass is THIN. Many game wiki pages returned 402/403 errors, and generic searches mostly returned mods and off-topic pages. Only Minecraft has a fully read, primary wiki page. Everything else is either a search-snippet-only source (marked "snippet") or [M] (from memory, not checked). Treat the per-game entries below as leads to verify, not as a finished catalogue.

Legend: [V] = read on the page itself; [S] = seen only in a search-result snippet, not opened; [M] = from memory, not verified.

## Key question 0: Cross-game context (what the owner's "too much" reaction matches)

### Takeaway
Full-screen red edge overlays are a widely used, widely criticised default. Several games use a more subtle approach (heart icons, a short camera tilt, a sound), so the owner's reaction is in line with what some players complain about.

### Cited Findings
- Kotaku's article calls the red/low-health screen effect "de rigueur game design for ages" and says the writer is "so very over it." It names Returnal (cracks plus red pulse), Outriders and Doom (screen muddies at low health), Gears (screen goes redscale), Uncharted and The Last of Us (colour drains), and says games with an on-screen health display make the overlay unnecessary. [V] — https://kotaku.com/enough-with-the-red-screen-of-almost-death-1846752628
- Giant Bomb's "Damage Flash" concept entry describes the common approach: a bright flash, usually red, on the screen border when the player takes damage. [S] — https://giantbomb.com/wiki/Concepts/Damage_Flash
- Modders repeatedly publish "disable red screen" and "turn off the low health filter" mods for games that ship the effect, which suggests the default is often not optional. [S] — https://forums.nexusmods.com/topic/2383764-is-there-any-mod-or-menu-setting-to-turn-off-the-low-health-filter (page returned 403; the title is what was seen)

### Inferences
- A safe default for the owner's game is: no full-screen overlay at all, or at most a very faint edge tint that only shows at very low health and can be turned off in settings.
- The stronger signals in the list (camera tilt, heart/health bar flash, sound) carry most of the "I got hit" message in the games where they are verified.

### Gaps
- Could not open the Game UI Database (gameuidatabase.com); the search page returned no usable entries.

---

## Elden Ring

### Takeaway
[S/V] The official-fan HUD wiki describes the HP gauge only as "current HP... decreases as you take damage." No screen effect is mentioned. The red "square" under the bars is a different status effect (Fia's hug), not a damage warning. Hit feedback and low-health screen behaviour are not verified.

### Cited Findings
- HP gauge described as decreasing with damage; no mention of any screen effect, low-health flash or ghost bar on the HUD page. [V] — https://eldenring.wiki.gg/wiki/HUD
- A red square debuff under the health, FP and stamina bars comes from Fia's hug and reduces max health by 5%. This is a status indicator, not a damage warning. [S] — https://www.nme.com/guides/how-to-avoid-or-remove-the-red-square-health-debuff-in-elden-ring-3175084

### Inferences
- Elden Ring's hit feedback is probably carried by the hit reaction and sound, not an overlay. Not verified.

### Gaps
- Screen effect on hit, low-health threshold, ghost bar, camera shake, and sound: NOT verified. Needs a check on a community forum or a video of a hit at low health.
- [M] I believe there is no red full-screen flash in base Elden Ring, but this is unverified.

---

## Dark Souls 3

### Takeaway
No usable source found in this pass. Searches returned only unrelated mods (a health-bar colour mod and a NAC X vignette mod, which does not name the game).

### Cited Findings
- None verified.

### Gaps
- Screen effect, HUD, camera, sound, low-health threshold, settings: all NOT verified.
- [M] Dark Souls 3's HP bar shows a lighter "ghost" section after damage. Not checked.

---

## Monster Hunter World / Rise / Wilds

### Takeaway
MH World: no source found that describes a low-health screen effect. MH Wilds: a default-on vignette exists and cannot be changed in the graphics menu, per a Prima Games tip (snippet). This is a Wilds finding and should not be assumed for World or Rise.

### Cited Findings
- Prima's MHW HUD guide: health and stamina are shown in the top-left; if health drops too low the hunter faints and returns to camp. No mention of a screen-edge warning. [S] — https://primagames.com/tips/monster-hunter-world-understanding-hud
- Prima's "How To Disable the Vignette Effect in Monster Hunter Wilds" says the vignette is enabled by default and cannot be changed in the in-game graphics menu. [S] — https://primagames.com/tips/how-to-disable-the-vignette-effect-in-monster-hunter-wilds (page returned 403; title and summary text from search snippet)

### Inferences
- The Wilds vignette is a persistent edge effect, which fits the owner's "too much" reaction. It may not be a hit or low-health effect at all; whether it reacts to health is not stated.

### Gaps
- MH World / Rise hit flash, low-health effect, camera kick, sound: NOT verified.
- Whether the Wilds vignette reacts to health: NOT verified.

---

## Zelda: Breath of the Wild / Tears of the Kingdom

### Takeaway
Only one source says anything about the low-health warning: a low-health beep exists in Zelda games. The heart-meter and visual-flash details could not be read (the Zelda Fandom page returned 402). Treat the rest as unverified.

### Cited Findings
- Destructoid says players push on "despite the annoying 'low health' beep," and that the beep appears in nearly every Zelda game. [S] — https://www.destructoid.com/?p=264248
- The Zelda Wiki's BotW page says life is restored by food, fairies, Mipha's Grace, or hot springs (health recovery, not hit feedback). [S] — https://zeldawiki.wiki/wiki/Health

### Inferences
- Zelda's low-health cue is most likely a sound and a heart-meter cue, not a screen overlay. Not verified.

### Gaps
- Heart-meter behaviour when hurt or at low health (the Zelda Fandom "Heart Meter" page returned 402).
- Screen effect, camera shake, Link's hit reaction, and whether BotW/TotK have a red screen. NOT verified.
- [M] I believe BotW has no full-screen red flash. Unverified.

---

## Minecraft (Java and Bedrock, vanilla)

### Takeaway
[V] Minecraft gives the player a clear "I got hit" signal from several small effects, with no full-screen red overlay in vanilla. The strongest signals are the damage tilt, the flashing health bar, and the hurt sound. Mods add vignettes, which suggests the vanilla game does not have one.

### Cited Findings
- Hurt flash: a mob or player turns red for 10 game ticks (0.5 seconds). [V] — https://minecraft.wiki/w/Damage
- Health bar: a white outline flashes around the health bar. Java: it flashes repeatedly for 1 second and shows pale hearts equal to the health just lost. Bedrock: it flashes once and shows no pale hearts. [V] — https://minecraft.wiki/w/Damage
- Damage tilt: on Java the screen tilts toward the attacker (defaults to the player's left if no entity hit it). On Bedrock the screen always tilts left. Turn off or adjust it in Options > Accessibility Settings > Damage Tilt (Java), or Settings > Video > Accessibility: Video > Damage Tilt (Bedrock). [V] — https://minecraft.wiki/w/Damage
- A hurt sound plays on damage. [V] — https://minecraft.wiki/w/Damage
- Mods such as Hurt Tint add a coloured vignette on every hit, and "Red Screen" style mods add a red overlay at low health (about three hearts). This implies vanilla has neither. [S] — https://modrinth.com/mod/hurt-tint ; https://www.curseforge.com/minecraft/mc-mods/redscreen
- Mojang feedback: a player requested an "old damage tilt" option, implying the tilt behaviour changed over versions. [S] — https://feedback.minecraft.net/hc/en-us/community/posts/37054295501837-Add-Option-to-Enable-Old-Damage-Tilt

### Inferences
- Minecraft's package is a good model for a subtle default: a short tilt, a short bar flash, a hurt sound, and a red model flash, all under about one second, with each one turn-off-able.
- The wiki page does not describe low-health feedback at all, so the vanilla low-health cue is not verified.

### Gaps
- Low-health heart behaviour in vanilla (I recall the heart icons shake at low health; [M], not verified on a page).
- Whether vanilla has any low-health screen effect: the wiki page does not say, and the mods imply it does not.

---

## Valheim (vanilla)

### Takeaway
[S] A Nexus forum thread (undated) says the base game gives little hit feedback beyond a short grunt, so players must watch the health bar. The players who want more feedback use BepInEx mods. This is a single, undated forum snippet and needs checking on the current version.

### Cited Findings
- Thread asking for a red screen border at low health: the base game gives little feedback beyond a short grunt when hit. [S] — https://forums.nexusmods.com/topic/456955-damage-visual-feedback (page returned 403; from search snippet of the thread)
- Mods that add the missing feedback: Wire's Damage Vignette (red edge gradient below a set health %, heartbeat, direct-hit flash only; marked deprecated) and DamageSplash (red edge flash on heavy hits; flash only on health actually lost) — both are mods, not vanilla. [S] — https://thunderstore.io/c/valheim/p/Wire/WiresDamageVignette/ ; https://thunderstore.io/c/valheim/p/Jumpingmushroom/DamageSplash/
- Valheim's official wiki "Health" page returned 402; no vanilla low-health detail was confirmed.

### Inferences
- Valheim vanilla is a good example of "almost nothing": a grunt and the bar. The owner might want something between Valheim's and Minecraft's levels.

### Gaps
- Vanilla hit flash, camera kick, low-health threshold, and heartbeat: NOT verified on a primary source.
- [M] I believe vanilla Valheim has a short camera/hit-reaction shake; unverified.

---

## Enshrouded

### Takeaway
No source found. Searches returned only mods and unrelated games.

### Cited Findings
- None verified for the game.

### Gaps
- Everything: screen effect, HUD, camera, sound, low-health threshold, settings. NOT verified. Needs the official docs or a community wiki page.

---

## V Rising

### Takeaway
No source found for a low-health vignette or hit flash. A 2022 Steam thread about removing a "Blood Key" screen effect exists, but the snippet does not say it is a health effect.

### Cited Findings
- Steam discussion asks how to remove the "Blood Key" screen effect; a commenter says people avoid it because it is uncomfortable. The snippet does not describe it as a damage or low-health effect. [S] — https://steamcommunity.com/app/1604030/discussions/0/3415431107716157265

### Gaps
- Hit feedback, low-health effect, HUD, sound, settings: NOT verified.
- The Thunderstore mod "NoBloodMoonTint" changes the blood moon tint, not health feedback. [S] — https://thunderstore.io/c/v-rising/p/Brainiac/NoBloodMooonTint/

---

## Grounded

### Takeaway
No source found. Searches returned only mods for SULFUR and Minecraft.

### Gaps
- Everything: screen effect, HUD, sound, low-health threshold, settings. NOT verified. Grounded's wiki page was not found in search.

---

## Don't Starve Together

### Takeaway
Only one lead: a Klei forum thread asks how to disable a "reddish screen ring effect when taken damage." The forum is Klei's, which makes DST the likely game, but the page returned 403 and the game name is not confirmed.

### Cited Findings
- Klei forum thread title: "how to disable reddish screen ring effect when taken damage." [S] — https://kleiforums.com/forums/topic/125188-how-to-disable-reddish-screen-ring-effect-when-taken-damage/ (page returned 403; title only)

### Gaps
- Confirm the game, the effect's size and timing, and whether there is an official setting to turn it off. Needs a Klei forum or DST wiki read from a browser.
- The DST wiki Health page (dontstarve.wiki.gg) returned 402. Not read.
- [M] DST is known for its heavy-damage and low-health screen effects, but this is unverified.

---

## Terraria

### Takeaway
No source read. The Terraria wiki returned 403.

### Gaps
- Everything: hit feedback, low-health effect, sound, settings. NOT verified.
- [M] Terraria has a short flash of the character on damage and red heart icons; neither is verified.

---

## Sea of Thieves

### Takeaway
No source found for the game. Searches returned only Minecraft, Skyrim and Factorio mods.

### Gaps
- Everything: hit feedback, low-health effect, HUD, sound, settings. NOT verified. The Sea of Thieves wiki or Rare support pages should be checked.

---

## Notes for the report writer

1. Verified (read on a page): Minecraft (full wiki Damage page); Elden Ring HUD (no screen effect mentioned); Kotaku critique of red-screen overuse; Grounded/Enshrouded/V Rising/Sea of Thieves/DST/Terraria: no game-specific source found.
2. Search-snippet only: Monster Hunter Wilds vignette (default on, not changeable in graphics menu); Valheim vanilla "little feedback beyond a grunt"; Zelda low-health beep; DST reddish-ring thread title.
3. Pages blocked (402/403): Zelda Heart Meter, Dark Souls 3 pages, Valheim Health, DST Health, Terraria Health, the Nexus and Klei forum pages, Prima MH pages (only snippets were seen).
4. Suggested next step: a browser-based pass (not WebFetch) on the blocked wiki pages, plus a YouTube search for "[game] hit at low health" to see the effect in motion. The owner's own game-feel decision matters more than any of these numbers.
